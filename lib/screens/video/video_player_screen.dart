import 'dart:async';
import 'dart:io';
import 'dart:math';
import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';
import 'package:video_player/video_player.dart';
import '../../core/network/api_config.dart';
import '../../core/network/api_service.dart';
import '../../core/services/humora_cache_service.dart';
import '../../core/services/vibration_service.dart';
import '../../core/services/wakelock_service.dart';
import '../../core/theme/app_colors.dart';
import '../../data/models/episode_model.dart';
import '../../main.dart';
import '../../providers/auth_provider.dart';
import '../../providers/series_provider.dart';
import '../../providers/history_provider.dart';
import '../../widgets/humora_image.dart';
import '../../widgets/humora_empty_state.dart';
import '../../widgets/paywall_modal.dart';
import '../../widgets/series_poster_card.dart';
import '../../widgets/humora_toast.dart';
import 'series_detail_screen.dart';

class VideoPlayerScreen extends StatefulWidget {
  final String seriesId;
  final int initialEpisodeNumber;

  const VideoPlayerScreen({
    super.key,
    required this.seriesId,
    this.initialEpisodeNumber = 1,
  });

  @override
  State<VideoPlayerScreen> createState() => _VideoPlayerScreenState();
}

class _VideoPlayerScreenState extends State<VideoPlayerScreen>
    with WidgetsBindingObserver, RouteAware {
  late int _currentEpisodeNumber;
  VideoPlayerController? _videoController;
  bool _isControllerInitializing = true;
  bool _hasVideoError = false;
  bool _isPlaying = false;
  bool _showControls = true;
  Timer? _hideControlsTimer;
  double _currentProgress = 0.0;
  Duration _currentPosition = Duration.zero;
  Duration _totalDuration = Duration.zero;
  bool _isDescriptionExpanded = false;
  bool _isDisposed = false;
  bool _isPopping = false;
  bool _hasTriggeredCompletion = false;
  String _viewingSessionId = '';
  int _sessionWatchedSeconds = 0;
  Timer? _heartbeatTimer;
  Timer? _likeSyncTimer;
  Timer? _preCacheTimer;
  Timer? _currentPreCacheTimer;
  final ValueNotifier<double> _progressNotifier = ValueNotifier<double>(0.0);
  final ValueNotifier<Duration> _positionNotifier = ValueNotifier<Duration>(Duration.zero);
  final ValueNotifier<bool> _isBufferingNotifier = ValueNotifier<bool>(false);
  final ValueNotifier<double> _bufferedProgressNotifier = ValueNotifier<double>(0.0);
  int _reconnectAttempts = 0;
  bool _isScrubbing = false;
  final ApiService _apiService = ApiService();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _currentEpisodeNumber = widget.initialEpisodeNumber;
    _isControllerInitializing = true;
    _showControls = true;
    _startLikeSyncTimer();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted || _isDisposed || _isPopping) return;
      final seriesProv = context.read<SeriesProvider>();
      final series = seriesProv.getSeriesById(widget.seriesId);
      if (series == null || series.episodes.isEmpty) {
        await seriesProv.fetchSeriesDetail(widget.seriesId);
      }
      if (mounted && !_isDisposed && !_isPopping) {
        _initializeVideoPlayer();
      }
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final modalRoute = ModalRoute.of(context);
    if (modalRoute != null) {
      routeObserver.subscribe(this, modalRoute);
    }
  }

  @override
  void didPushNext() {
    // When an overlaid route (e.g. Paywall modal or details) is pushed, pause video
    _stopVideoPlaybackOnly();
  }

  @override
  void didPopNext() {
    // Returned to this screen from an overlaid route
    _isPopping = false;
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused || state == AppLifecycleState.inactive) {
      _stopVideoPlaybackOnly();
    }
  }

  @override
  void deactivate() {
    _isPopping = true;
    _stopVideo();
    super.deactivate();
  }

  @override
  void dispose() {
    _isDisposed = true;
    _isPopping = true;
    routeObserver.unsubscribe(this);
    WidgetsBinding.instance.removeObserver(this);
    _heartbeatTimer?.cancel();
    _likeSyncTimer?.cancel();
    _preCacheTimer?.cancel();
    _currentPreCacheTimer?.cancel();
    _sendViewingHeartbeat();
    _syncWatchHistory();
    _progressNotifier.dispose();
    _positionNotifier.dispose();
    _isBufferingNotifier.dispose();
    _bufferedProgressNotifier.dispose();
    _disposePlayer();
    super.dispose();
  }

  void _startLikeSyncTimer() {
    _likeSyncTimer?.cancel();
    _likeSyncTimer = Timer.periodic(const Duration(seconds: 20), (_) {
      _triggerLikeSync();
    });
    _triggerLikeSync();
  }

  void _triggerLikeSync() {
    if (!mounted || _isDisposed || _isPopping) return;
    try {
      final seriesProv = context.read<SeriesProvider>();
      final series = seriesProv.getSeriesById(widget.seriesId);
      if (series != null && series.episodes.isNotEmpty) {
        final ep = series.episodes.firstWhere(
          (e) => e.episodeNumber == _currentEpisodeNumber,
          orElse: () => series.episodes.first,
        );
        seriesProv.syncEpisodeLikeStatus(ep.id);
      }
    } catch (_) {}
  }

  /// Safely schedule state updates outside buildScope and after frame if busy
  void _safeSetState(VoidCallback fn) {
    if (!mounted || _isDisposed || _isPopping) return;
    if (SchedulerBinding.instance.schedulerPhase != SchedulerPhase.idle) {
      SchedulerBinding.instance.addPostFrameCallback((_) {
        if (mounted && !_isDisposed && !_isPopping) {
          setState(fn);
        }
      });
    } else {
      setState(fn);
    }
  }

  /// Safely stops playback when navigating away or unmounting without calling setState during build
  void _stopVideo() {
    _isPopping = true;
    _heartbeatTimer?.cancel();
    _sendViewingHeartbeat();
    _hideControlsTimer?.cancel();
    WakelockService.disable();
    if (_videoController != null) {
      try {
        _videoController!.removeListener(_onVideoControllerUpdate);
        _videoController!.pause();
      } catch (_) {}
    }
    _isPlaying = false;
    _showControls = true;
  }

  /// Pauses playback while remaining on the screen (e.g. paywall modal shown or backgrounded)
  void _stopVideoPlaybackOnly() {
    _heartbeatTimer?.cancel();
    _sendViewingHeartbeat();
    _hideControlsTimer?.cancel();
    WakelockService.disable();
    if (_videoController != null) {
      try {
        _videoController!.pause();
      } catch (_) {}
    }
    _isPlaying = false;
    _showControls = true;
    _safeSetState(() {});
  }

  /// Full clean disposal of active player controller
  void _disposePlayer() {
    _hideControlsTimer?.cancel();
    WakelockService.disable();
    if (_videoController != null) {
      try {
        _videoController!.removeListener(_onVideoControllerUpdate);
        _videoController!.pause();
        _videoController!.dispose();
      } catch (_) {}
      _videoController = null;
    }
  }

  /// Schedule auto-hiding controls after ~2 seconds of playback
  void _scheduleHideControls() {
    _hideControlsTimer?.cancel();
    if (!_hasVideoError && !_isControllerInitializing && !_isPopping && !_isDisposed) {
      _hideControlsTimer = Timer(const Duration(milliseconds: 2000), () {
        if (mounted && !_isPopping && !_isDisposed) {
          if (_videoController != null && _videoController!.value.isPlaying) {
            _safeSetState(() => _showControls = false);
          }
        }
      });
    }
  }

  /// Toggle controls visibility when user taps the video container
  void _toggleControls() {
    if (_hasVideoError || _isControllerInitializing || _isPopping || _isDisposed) return;
    _safeSetState(() {
      _showControls = !_showControls;
    });
    if (_showControls) {
      if (_isPlaying || (_videoController != null && _videoController!.value.isPlaying)) {
        _scheduleHideControls();
      }
    } else {
      _hideControlsTimer?.cancel();
    }
  }

  void _onVideoControllerUpdate() {
    if (_videoController == null || !_videoController!.value.isInitialized || !mounted || _isDisposed || _isPopping) {
      return;
    }

    final val = _videoController!.value;
    final pos = val.position;
    final dur = val.duration;

    // 1. Buffering state notifier
    if (_isBufferingNotifier.value != val.isBuffering) {
      _isBufferingNotifier.value = val.isBuffering;
    }

    // 2. Buffered ranges calculation (highest buffered head)
    if (val.buffered.isNotEmpty && dur.inMilliseconds > 0) {
      double maxBufferedMs = 0.0;
      for (final range in val.buffered) {
        final endMs = range.end.inMilliseconds.toDouble();
        if (endMs > maxBufferedMs) {
          maxBufferedMs = endMs;
        }
      }
      final bufRatio = (maxBufferedMs / dur.inMilliseconds).clamp(0.0, 1.0);
      if ((_bufferedProgressNotifier.value - bufRatio).abs() > 0.01) {
        _bufferedProgressNotifier.value = bufRatio;
      }
    }

    if (dur.inMilliseconds > 0) {
      _totalDuration = dur;
      if (!_isScrubbing) {
        _currentPosition = pos;
        final progress = (pos.inMilliseconds / dur.inMilliseconds).clamp(0.0, 1.0);
        _currentProgress = progress;

        // Efficient targeted notifier updates - prevents rebuilding entire 50-widget screen every frame!
        if ((_progressNotifier.value - progress).abs() > 0.001) {
          _progressNotifier.value = progress;
        }
        if (_positionNotifier.value.inSeconds != pos.inSeconds) {
          _positionNotifier.value = pos;
        }
      }

      // Only trigger UI setState if play/pause state changed
      if (_isPlaying != val.isPlaying) {
        _isPlaying = val.isPlaying;
        _safeSetState(() {});
      }

      // When video is actively playing and controls are visible, ensure the 2s auto-hide timer is active
      if (_isPlaying && _showControls && (_hideControlsTimer == null || !_hideControlsTimer!.isActive)) {
        _scheduleHideControls();
      }

      _checkVideoCompletion(val, pos, dur);
    }
  }

  bool _isNearOrAtEnd(VideoPlayerValue value, Duration pos, Duration dur) {
    if (dur.inMilliseconds <= 500) return false;
    if (value.isCompleted) return true;
    if (pos >= dur - const Duration(milliseconds: 300)) return true;
    if (!value.isPlaying && pos.inMilliseconds > 1000 && pos >= dur - const Duration(milliseconds: 800)) {
      return true;
    }
    return false;
  }

  void _checkVideoCompletion(VideoPlayerValue value, Duration pos, Duration dur) {
    if (_hasTriggeredCompletion) return;
    if (!_isNearOrAtEnd(value, pos, dur)) return;

    _hasTriggeredCompletion = true;
    debugPrint('HUMORA VIDEO COMPLETED: Episode $_currentEpisodeNumber');

    if (_sessionWatchedSeconds < dur.inSeconds) {
      _sessionWatchedSeconds = dur.inSeconds;
    }
    _sendViewingHeartbeat();

    // Sync progress as completed
    _syncWatchHistory();

    final seriesProv = context.read<SeriesProvider>();
    final series = seriesProv.getSeriesById(widget.seriesId) ?? seriesProv.featuredSeries;
    final nextEpNumber = _currentEpisodeNumber + 1;
    final nextEpList = series.episodes.where((e) => e.episodeNumber == nextEpNumber).toList();

    if (nextEpList.isNotEmpty) {
      final nextEp = nextEpList.first;
      final auth = context.read<AuthProvider>();

      if (!auth.canAccessEpisode(
        nextEp.episodeNumber,
        episodeId: int.tryParse(nextEp.id),
        seriesTotalEpisodes: series.episodes.length,
        isFreeEpisode: nextEp.isFree,
      )) {
        // Next video is VIP (e.g. Episode 3) and user is Free/Guest:
        // Pause playback and present the VIP subscription paywall modal
        _stopVideoPlaybackOnly();
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted && !_isPopping && !_isDisposed) {
            PaywallModal.show(context);
          }
        });
      } else {
        // Next video is accessible: auto transition to next episode
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted && !_isPopping && !_isDisposed) {
            _playEpisode(nextEp.episodeNumber);
          }
        });
      }
    } else {
      // End of series
      _stopVideoPlaybackOnly();
    }
  }

  Future<void> _initializeVideoPlayer() async {
    _hasTriggeredCompletion = false;
    final seriesProv = context.read<SeriesProvider>();
    final series = seriesProv.getSeriesById(widget.seriesId) ?? seriesProv.featuredSeries;
    final episode = series.episodes.firstWhere(
      (e) => e.episodeNumber == _currentEpisodeNumber,
      orElse: () => series.episodes.isNotEmpty ? series.episodes.first : const EpisodeModel(
        id: '1',
        seriesId: '1',
        episodeNumber: 1,
        title: 'Episode 1',
        synopsis: '',
        duration: '02:00',
        likes: '0',
        thumbnailPath: '',
      ),
    );

    final auth = context.read<AuthProvider>();

    // Paywall Check: Episode 3+ requires VIP status (or Ep 2 if series only has 2 episodes)
    if (!auth.canAccessEpisode(
      _currentEpisodeNumber,
      episodeId: int.tryParse(episode.id),
      seriesTotalEpisodes: series.episodes.length,
      isFreeEpisode: episode.isFree,
    )) {
      _safeSetState(() {
        _hasVideoError = true;
        _isControllerInitializing = false;
      });
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && !_isPopping && !_isDisposed) {
          PaywallModal.show(context);
        }
      });
      return;
    }

    _safeSetState(() {
      _isControllerInitializing = true;
      _hasVideoError = false;
    });

    _heartbeatTimer?.cancel();
    _viewingSessionId = 'mob_${DateTime.now().millisecondsSinceEpoch}_${Random().nextInt(99999)}';
    _sessionWatchedSeconds = 0;

    try {
      final token = await ApiService().getToken();
      final headers = <String, String>{
        'Accept': 'video/webm,video/mp4,video/*;q=0.9,*/*;q=0.8',
        if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
      };

      // Construct server stream URL normalized against active ApiConfig.baseUrl
      String streamUrl = '${ApiConfig.baseUrl}/files/stream/${episode.id}';
      if (episode.streamUrl != null && episode.streamUrl!.isNotEmpty) {
        final parsed = Uri.tryParse(episode.streamUrl!);
        if (parsed != null && parsed.hasScheme) {
          final baseUri = Uri.parse(ApiConfig.baseUrl);
          if (parsed.host == 'localhost' || parsed.host == '127.0.0.1') {
            // Replace unreachable localhost/127.0.0.1 on Android with active API host
            streamUrl = parsed.replace(
              scheme: baseUri.scheme,
              host: baseUri.host,
              port: baseUri.hasPort ? baseUri.port : null,
            ).toString();
          } else {
            streamUrl = episode.streamUrl!;
          }
        }
      }

      debugPrint('HUMORA VIDEO STREAM: Connecting to $streamUrl');

      final oldController = _videoController;
      oldController?.removeListener(_onVideoControllerUpdate);

      VideoPlayerController newController;
      File? localCachedFile;

      if (streamUrl.startsWith('http://') || streamUrl.startsWith('https://')) {
        localCachedFile = await HumoraCacheService.getCachedVideoFile(streamUrl);
      }

      if (localCachedFile != null) {
        debugPrint('HUMORA VIDEO STREAM: Playing from local cache (0 data usage)');
        newController = VideoPlayerController.file(
          localCachedFile,
          videoPlayerOptions: VideoPlayerOptions(mixWithOthers: true),
        );
      } else {
        newController = VideoPlayerController.networkUrl(
          Uri.parse(streamUrl),
          httpHeaders: headers,
          videoPlayerOptions: VideoPlayerOptions(mixWithOthers: true),
        );
      }

      await newController.initialize();
      await oldController?.dispose();

      if (!mounted || _isDisposed || _isPopping) {
        newController.dispose();
        return;
      }

      _reconnectAttempts = 0; // Successfully connected
      newController.addListener(_onVideoControllerUpdate);
      await newController.play();
      WakelockService.enable();

      // If user had a prior playback position, seek to it
      if (_currentPosition.inSeconds > 0 && _currentPosition < newController.value.duration - const Duration(seconds: 3)) {
        await newController.seekTo(_currentPosition);
      }

      // Dual background caching:
      // A. Cache current streaming episode in background for instant replay & 0-data seeking
      if (localCachedFile == null && (streamUrl.startsWith('http://') || streamUrl.startsWith('https://'))) {
        _schedulePreCacheCurrentEpisode(streamUrl, headers);
      }
      // B. Pre-cache next episode in background after current video is safely playing
      _schedulePreCacheNextEpisode(series, headers);

      _safeSetState(() {
        _videoController = newController;
        _isControllerInitializing = false;
        _hasVideoError = false;
        _isPlaying = true;
        _showControls = true;
        _totalDuration = newController.value.duration;
      });

      _scheduleHideControls();
      _sendViewingHeartbeat();
      _startHeartbeatTimer();
      _syncWatchHistory();
    } catch (e, st) {
      debugPrint('HUMORA VIDEO PLAYBACK ERROR: $e\n$st');
      WakelockService.disable();

      // Smart auto-reconnect on network dip (up to 2 attempts)
      if (_reconnectAttempts < 2 && mounted && !_isDisposed && !_isPopping) {
        _reconnectAttempts++;
        debugPrint('HUMORA VIDEO AUTO-RECONNECT: Attempt $_reconnectAttempts of 2 in 1.5s...');
        _safeSetState(() {
          _isControllerInitializing = true;
          _hasVideoError = false;
        });
        await Future.delayed(const Duration(milliseconds: 1500));
        if (mounted && !_isDisposed && !_isPopping) {
          _initializeVideoPlayer();
          return;
        }
      }

      if (mounted && !_isDisposed && !_isPopping) {
        _safeSetState(() {
          _isControllerInitializing = false;
          _hasVideoError = true;
        });
      }
    }
  }

  void _schedulePreCacheCurrentEpisode(String streamUrl, Map<String, String> headers) {
    _currentPreCacheTimer?.cancel();
    _currentPreCacheTimer = Timer(const Duration(seconds: 2), () async {
      if (!mounted || _isDisposed || _isPopping) return;
      try {
        final cached = await HumoraCacheService.getCachedVideoFile(streamUrl);
        if (cached == null) {
          debugPrint('HUMORA VIDEO STREAM: Background-caching current video for instant replay');
          await HumoraCacheService.downloadAndCacheFile(streamUrl, headers: headers);
          debugPrint('HUMORA VIDEO STREAM: Current video cached successfully');
        }
      } catch (_) {}
    });
  }

  void _syncWatchHistory() {
    try {
      if (!mounted) return;
      final seriesProv = context.read<SeriesProvider>();
      final series = seriesProv.getSeriesById(widget.seriesId) ?? seriesProv.featuredSeries;
      final episode = series.episodes.firstWhere(
        (e) => e.episodeNumber == _currentEpisodeNumber,
        orElse: () => series.episodes.isNotEmpty ? series.episodes.first : const EpisodeModel(
          id: '1',
          seriesId: '1',
          episodeNumber: 1,
          title: 'Episode 1',
          synopsis: '',
          duration: '02:00',
          likes: '0',
          thumbnailPath: '',
        ),
      );

      final epIdInt = int.tryParse(episode.id);
      final posSeconds = _currentPosition.inSeconds;
      final durSeconds = _totalDuration.inSeconds > 0 ? _totalDuration.inSeconds : 120;
      final percent = (_currentProgress * 100).toInt();

      context.read<HistoryProvider>().addOrUpdateProgress(
        seriesId: series.id,
        seriesTitle: series.title,
        episodeNumberText: 'Video ${episode.episodeNumber}',
        episodeTitle: episode.title,
        thumbnailPath: episode.thumbnailPath,
        progressPercent: percent,
        episodeId: epIdInt,
        lastPosition: posSeconds,
        durationSeconds: durSeconds,
      );
    } catch (_) {}
  }

  void _startHeartbeatTimer() {
    _heartbeatTimer?.cancel();
    _heartbeatTimer = Timer.periodic(const Duration(seconds: 10), (_) {
      if (!mounted || _isDisposed || _isPopping) return;
      if (_videoController != null && _videoController!.value.isPlaying) {
        _sessionWatchedSeconds += 10;
        _sendViewingHeartbeat();
      }
    });
  }

  void _schedulePreCacheNextEpisode(dynamic series, Map<String, String> headers) {
    _preCacheTimer?.cancel();
    _preCacheTimer = Timer(const Duration(seconds: 3), () async {
      if (!mounted || _isDisposed || _isPopping) return;
      try {
        final nextEpNumber = _currentEpisodeNumber + 1;
        final nextEpList = series.episodes.where((e) => e.episodeNumber == nextEpNumber).toList();
        if (nextEpList.isNotEmpty) {
          final nextEp = nextEpList.first;
          final auth = context.read<AuthProvider>();
          if (auth.canAccessEpisode(
            nextEp.episodeNumber,
            episodeId: int.tryParse(nextEp.id),
            seriesTotalEpisodes: series.episodes.length,
            isFreeEpisode: nextEp.isFree,
          )) {
            String nextStreamUrl = '${ApiConfig.baseUrl}/files/stream/${nextEp.id}';
            if (nextEp.streamUrl != null && nextEp.streamUrl!.isNotEmpty) {
              final parsed = Uri.tryParse(nextEp.streamUrl!);
              if (parsed != null && parsed.hasScheme) {
                final baseUri = Uri.parse(ApiConfig.baseUrl);
                if (parsed.host == 'localhost' || parsed.host == '127.0.0.1') {
                  nextStreamUrl = parsed.replace(
                    scheme: baseUri.scheme,
                    host: baseUri.host,
                    port: baseUri.hasPort ? baseUri.port : null,
                  ).toString();
                } else {
                  nextStreamUrl = nextEp.streamUrl!;
                }
              }
            }

            final alreadyCached = await HumoraCacheService.getCachedVideoFile(nextStreamUrl);
            if (alreadyCached == null) {
              debugPrint('HUMORA VIDEO STREAM: Pre-caching next video (Episode $nextEpNumber) in background');
              await HumoraCacheService.downloadAndCacheFile(nextStreamUrl, headers: headers);
              debugPrint('HUMORA VIDEO STREAM: Next video pre-cached successfully');
            }
          }
        }
      } catch (_) {}
    });
  }

  void _sendViewingHeartbeat() {
    try {
      if (!mounted || _viewingSessionId.isEmpty) return;
      final seriesProv = context.read<SeriesProvider>();
      final series = seriesProv.getSeriesById(widget.seriesId) ?? seriesProv.featuredSeries;
      final episode = series.episodes.firstWhere(
        (e) => e.episodeNumber == _currentEpisodeNumber,
        orElse: () => series.episodes.isNotEmpty ? series.episodes.first : const EpisodeModel(
          id: '1',
          seriesId: '1',
          episodeNumber: 1,
          title: 'Episode 1',
          synopsis: '',
          duration: '02:00',
          likes: '0',
          thumbnailPath: '',
        ),
      );

      final epId = int.tryParse(episode.id);
      if (epId == null) return;
      final seriesIdInt = int.tryParse(series.id);
      final lastPos = _currentPosition.inSeconds;
      final dur = _totalDuration.inSeconds > 0
          ? _totalDuration.inSeconds
          : (episode.durationSeconds > 0 ? episode.durationSeconds : 120);
      final progressPercent = (_currentProgress * 100).toInt();

      _apiService.trackVideoView(
        episodeId: epId,
        seriesId: seriesIdInt,
        sessionId: _viewingSessionId,
        watchedSeconds: _sessionWatchedSeconds,
        lastPosition: lastPos,
        durationSeconds: dur,
        progressPercent: progressPercent,
      ).ignore();
    } catch (_) {}
  }

  void _playEpisode(int episodeNumber) {
    VibrationService.mediumImpact();
    final seriesProv = context.read<SeriesProvider>();
    final series = seriesProv.getSeriesById(widget.seriesId) ?? seriesProv.featuredSeries;
    final targetEp = series.episodes.firstWhere(
      (e) => e.episodeNumber == episodeNumber,
      orElse: () => series.episodes.isNotEmpty ? series.episodes.first : const EpisodeModel(
        id: '1',
        seriesId: '1',
        episodeNumber: 1,
        title: 'Episode 1',
        synopsis: '',
        duration: '02:00',
        likes: '0',
        thumbnailPath: '',
      ),
    );

    final auth = context.read<AuthProvider>();
    if (!auth.canAccessEpisode(
      episodeNumber,
      episodeId: int.tryParse(targetEp.id),
      seriesTotalEpisodes: series.episodes.length,
      isFreeEpisode: targetEp.isFree,
    )) {
      _stopVideoPlaybackOnly();
      PaywallModal.show(context);
      return;
    }

    _heartbeatTimer?.cancel();
    _sendViewingHeartbeat();
    _syncWatchHistory();
    _hasTriggeredCompletion = false;
    _reconnectAttempts = 0;

    _safeSetState(() {
      _currentEpisodeNumber = episodeNumber;
      _currentProgress = 0.0;
      _currentPosition = Duration.zero;
      _showControls = true;
      _isControllerInitializing = true;
      _hasVideoError = false;
    });

    _initializeVideoPlayer();
    _triggerLikeSync();
  }

  void _togglePlayPause() {
    if (_videoController == null || !_videoController!.value.isInitialized) return;
    VibrationService.lightImpact();

    if (_videoController!.value.isPlaying) {
      _videoController!.pause();
      WakelockService.disable();
      _hideControlsTimer?.cancel();
      _heartbeatTimer?.cancel();
      _sendViewingHeartbeat();
      _safeSetState(() {
        _isPlaying = false;
        _showControls = true;
      });
    } else {
      _videoController!.play();
      WakelockService.enable();
      _safeSetState(() {
        _isPlaying = true;
        _showControls = true;
      });
      _scheduleHideControls();
      _startHeartbeatTimer();
      _sendViewingHeartbeat();
    }
  }

  void _seekRelative(int seconds) {
    if (_videoController == null || !_videoController!.value.isInitialized) return;
    VibrationService.lightImpact();

    final newPos = _videoController!.value.position + Duration(seconds: seconds);
    final clamped = Duration(
      milliseconds: newPos.inMilliseconds.clamp(0, _totalDuration.inMilliseconds),
    );
    if (clamped < _totalDuration - const Duration(seconds: 2)) {
      _hasTriggeredCompletion = false;
    }
    _videoController!.seekTo(clamped);
    _currentPosition = clamped;
    _positionNotifier.value = clamped;
    if (_totalDuration.inMilliseconds > 0) {
      _currentProgress = (_currentPosition.inMilliseconds / _totalDuration.inMilliseconds).clamp(0.0, 1.0);
      _progressNotifier.value = _currentProgress;
    }
    if (_isPlaying || (_videoController != null && _videoController!.value.isPlaying)) {
      _scheduleHideControls();
    }
  }

  String _formatDuration(Duration d) {
    final minutes = d.inMinutes.remainder(60).toString();
    final seconds = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    final seriesProv = context.watch<SeriesProvider>();
    final auth = context.watch<AuthProvider>();
    final series = seriesProv.getSeriesById(widget.seriesId) ?? seriesProv.featuredSeries;

    final currentEpisode = series.episodes.firstWhere(
      (e) => e.episodeNumber == _currentEpisodeNumber,
      orElse: () => series.episodes.isNotEmpty
          ? series.episodes.first
          : const EpisodeModel(
              id: '1',
              seriesId: '1',
              episodeNumber: 1,
              title: 'Episode 1',
              synopsis: '',
              duration: '02:00',
              likes: '0',
              thumbnailPath: '',
            ),
    );

    final nextEpisode = _currentEpisodeNumber < series.episodes.length
        ? series.episodes.firstWhere(
            (e) => e.episodeNumber == _currentEpisodeNumber + 1,
            orElse: () => series.episodes.first,
          )
        : null;

    final isEpLiked = seriesProv.isEpisodeLiked(currentEpisode.id);

    return PopScope(
      canPop: true,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) {
          _isPopping = true;
          _stopVideo();
        }
      },
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.only(bottom: 40),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Real Video Player Stream Section
                _buildVideoPlayerSection(context, series, currentEpisode, nextEpisode),

                const SizedBox(height: 16),

                // Series Navigation Pill Tag
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: GestureDetector(
                    onTap: () {
                      _stopVideoPlaybackOnly();
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => SeriesDetailScreen(seriesId: series.id),
                        ),
                      );
                    },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                    decoration: BoxDecoration(
                      color: AppColors.accentPurpleSoft,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          series.title,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: AppColors.accentPurple,
                          ),
                        ),
                        const SizedBox(width: 4),
                        const Icon(
                          LucideIcons.chevronRight,
                          size: 14,
                          color: AppColors.accentPurple,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 10),

              // Title and Badges
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AutoSizeText(
                      'Video ${currentEpisode.episodeNumber}: ${currentEpisode.title}',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                        letterSpacing: -0.3,
                      ),
                      maxLines: 2,
                      minFontSize: 15,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: AutoSizeText(
                            'Video ${currentEpisode.episodeNumber} dari ${series.totalEpisodes} • ${currentEpisode.duration} • ${series.tag}',
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.textSecondary,
                            ),
                            maxLines: 1,
                            minFontSize: 10,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: currentEpisode.isPremium && !auth.isPremium
                                ? AppColors.yellowSoft
                                : const Color(0xFFE6F8F0),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            currentEpisode.isPremium && !auth.isPremium ? 'VIP' : 'GRATIS',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              color: currentEpisode.isPremium && !auth.isPremium
                                  ? const Color(0xFFD97706)
                                  : AppColors.green,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),

              // Likes and Feedback Row
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: () async {
                        VibrationService.lightImpact();
                        final willLike = !seriesProv.isEpisodeLiked(currentEpisode.id);
                        final success = await seriesProv.toggleEpisodeLike(currentEpisode.id);
                        if (!context.mounted) return;
                        if (success) {
                          _triggerLikeSync();
                          HumoraToast.showLike(
                            context,
                            isLiked: willLike,
                            targetTitle: currentEpisode.title,
                            isSeries: false,
                          );
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          color: isEpLiked ? const Color(0xFFFEE2E2) : AppColors.surface,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: isEpLiked ? const Color(0xFFFCA5A5) : AppColors.border,
                            width: 1.2,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              LucideIcons.heart,
                              size: 16,
                              color: isEpLiked ? const Color(0xFFEF4444) : AppColors.textSecondary,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              isEpLiked ? 'Disukai' : currentEpisode.likes,
                              style: TextStyle(
                                fontSize: 12.5,
                                fontWeight: FontWeight.w700,
                                color: isEpLiked ? const Color(0xFFEF4444) : AppColors.textPrimary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Synopsis Card
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.border, width: 1.2),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        currentEpisode.synopsis.isNotEmpty
                            ? currentEpisode.synopsis
                            : 'Sketsa komedi original HUMORA dengan alur cerita jenaka dan penuh gelak tawa.',
                        style: const TextStyle(
                          fontSize: 12.5,
                          color: AppColors.textPrimary,
                          height: 1.5,
                        ),
                        maxLines: _isDescriptionExpanded ? null : 2,
                        overflow: _isDescriptionExpanded ? TextOverflow.visible : TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 6),
                      GestureDetector(
                        onTap: () {
                          _safeSetState(() {
                            _isDescriptionExpanded = !_isDescriptionExpanded;
                          });
                        },
                        child: Text(
                          _isDescriptionExpanded ? 'Tutup Deskripsi' : 'Selengkapnya...',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: AppColors.accentPurple,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Episode List Section Header
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Daftar Video',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Total ${series.episodes.length} video dalam judul ini',
                          style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.accentPurpleSoft,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        series.tag,
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: AppColors.accentPurple,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              // List of Episodes
              if (series.episodes.isEmpty) ...[
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Container(
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.border, width: 1.2),
                    ),
                    child: const HumoraEmptyState(
                      compact: true,
                      icon: LucideIcons.video,
                      title: 'Episode Belum Tersedia',
                      subtitle: 'Belum ada daftar episode video yang dirilis untuk judul series komedi ini.',
                    ),
                  ),
                ),
              ] else ...[
                ...series.episodes.map((ep) {
                  final isCurrent = ep.episodeNumber == _currentEpisodeNumber;
                  final isLocked = ep.isPremium && !auth.isPremium;

                  return Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
                    child: GestureDetector(
                      onTap: () => _playEpisode(ep.episodeNumber),
                      child: Container(
                        padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isCurrent ? AppColors.accentPurple : AppColors.border,
                          width: isCurrent ? 2.0 : 1.2,
                        ),
                        boxShadow: isCurrent
                            ? [
                                BoxShadow(
                                  color: AppColors.accentPurple.withValues(alpha: 0.08),
                                  blurRadius: 8,
                                  offset: const Offset(0, 3),
                                ),
                              ]
                            : null,
                      ),
                      child: Row(
                        children: [
                          // Thumbnail
                          Stack(
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(10),
                                child: SizedBox(
                                  width: 88,
                                  height: 60,
                                  child: HumoraImage(
                                    imagePathOrUrl: ep.thumbnailPath,
                                    fit: BoxFit.cover,
                                  ),
                                ),
                              ),
                              if (isLocked)
                                Positioned.fill(
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: Colors.black.withValues(alpha: 0.55),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: const Center(
                                      child: Icon(LucideIcons.lock, color: AppColors.primaryYellow, size: 20),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(width: 12),

                          // Metadata
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Text(
                                      'VIDEO ${ep.episodeNumber}',
                                      style: TextStyle(
                                        fontSize: 10.5,
                                        fontWeight: FontWeight.w800,
                                        color: isCurrent ? AppColors.accentPurple : AppColors.textSecondary,
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    if (isCurrent)
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                                        decoration: BoxDecoration(
                                          color: AppColors.primaryYellow,
                                          borderRadius: BorderRadius.circular(4),
                                        ),
                                        child: const Text(
                                          'DIPUTAR',
                                          style: TextStyle(
                                            fontSize: 9,
                                            fontWeight: FontWeight.w800,
                                            color: AppColors.primaryDark,
                                          ),
                                        ),
                                      )
                                    else if (isLocked)
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                                        decoration: BoxDecoration(
                                          color: AppColors.yellowSoft,
                                          borderRadius: BorderRadius.circular(4),
                                        ),
                                        child: const Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(LucideIcons.lock, size: 8, color: Color(0xFFD97706)),
                                            SizedBox(width: 2),
                                            Text(
                                              'VIP',
                                              style: TextStyle(
                                                fontSize: 8.5,
                                                fontWeight: FontWeight.w800,
                                                color: Color(0xFFB45309),
                                              ),
                                            ),
                                          ],
                                        ),
                                      )
                                    else
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFE6F8F0),
                                          borderRadius: BorderRadius.circular(4),
                                        ),
                                        child: const Text(
                                          'GRATIS',
                                          style: TextStyle(
                                            fontSize: 8.5,
                                            fontWeight: FontWeight.w800,
                                            color: AppColors.green,
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                                const SizedBox(height: 3),
                                Text(
                                  ep.title,
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.textPrimary,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  '${ep.duration} • ${ep.likes}',
                                  style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }),
              ],

              const SizedBox(height: 24),

              // Rekomendasi Series Lainnya
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          LucideIcons.flame,
                          size: 18,
                          color: Color(0xFFEF4444),
                        ),
                        SizedBox(width: 8),
                        Text(
                          'Rekomendasi Lainnya',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                    GestureDetector(
                      onTap: () {
                        _isPopping = true;
                        _stopVideo();
                        Navigator.of(context).pop();
                      },
                      child: const Row(
                        children: [
                          Text(
                            'Kembali',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: AppColors.accentPurple,
                            ),
                          ),
                          SizedBox(width: 2),
                          Icon(LucideIcons.arrowRight, size: 14, color: AppColors.accentPurple),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                height: 215,
                child: ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  scrollDirection: Axis.horizontal,
                  itemCount: seriesProv.allSeries.length,
                  separatorBuilder: (_, _) => const SizedBox(width: 12),
                  itemBuilder: (context, index) {
                    final item = seriesProv.allSeries[index];
                    return SeriesPosterCard(
                      series: item,
                      onTap: () {
                        _stopVideoPlaybackOnly();
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => SeriesDetailScreen(seriesId: item.id),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
      ),
    );
  }

  Widget _buildVideoPlayerSection(
    BuildContext context,
    dynamic series,
    EpisodeModel currentEpisode,
    EpisodeModel? nextEpisode,
  ) {
    return Container(
      height: 240,
      width: double.infinity,
      color: Colors.black,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: _toggleControls,
        child: Stack(
          fit: StackFit.expand,
          children: [
            // 1. Real VideoPlayer (isolated with RepaintBoundary for GPU optimization) or Thumbnail Still
            if (_videoController != null && _videoController!.value.isInitialized)
              RepaintBoundary(
                child: Center(
                  child: AspectRatio(
                    aspectRatio: _videoController!.value.aspectRatio > 0
                        ? _videoController!.value.aspectRatio
                        : 16 / 9,
                    child: VideoPlayer(_videoController!),
                  ),
                ),
              )
            else
              HumoraImage(
                imagePathOrUrl: currentEpisode.thumbnailPath,
                fit: BoxFit.cover,
              ),

            // 2. Loading Spinner or Error State
            if (_isControllerInitializing)
              Container(
                color: Colors.black.withValues(alpha: 0.6),
                child: const Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircularProgressIndicator(
                        color: AppColors.primaryYellow,
                        strokeWidth: 3,
                      ),
                      SizedBox(height: 10),
                      Text(
                        'Menghubungkan video...',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              )
            else if (_hasVideoError)
              Container(
                color: Colors.black.withValues(alpha: 0.85),
                padding: const EdgeInsets.all(20),
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: AppColors.primaryYellow.withValues(alpha: 0.15),
                          shape: BoxShape.circle,
                          border: Border.all(color: AppColors.primaryYellow, width: 1.5),
                        ),
                        child: const Center(
                          child: Icon(LucideIcons.videoOff, color: AppColors.primaryYellow, size: 24),
                        ),
                      ),
                      const SizedBox(height: 10),
                      const Text(
                        'Video Belum Dapat Diputar',
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 13),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 3),
                      const Text(
                        'Berkas video sedang dipersiapkan atau koneksi server mengalami gangguan.',
                        style: TextStyle(color: Colors.white70, fontSize: 11),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 12),
                      ElevatedButton.icon(
                        onPressed: _initializeVideoPlayer,
                        icon: const Icon(LucideIcons.rotateCcw, size: 13),
                        label: const Text('Muat Ulang Video', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primaryYellow,
                          foregroundColor: AppColors.primaryDark,
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

            // 2b. Modern Buffering Pill Indicator during active playback
            if (!_isControllerInitializing && !_hasVideoError)
              ValueListenableBuilder<bool>(
                valueListenable: _isBufferingNotifier,
                builder: (context, isBuffering, _) {
                  if (!isBuffering) return const SizedBox.shrink();
                  return Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.7),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.15),
                          width: 1,
                        ),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          SizedBox(
                            width: 13,
                            height: 13,
                            child: CircularProgressIndicator(
                              color: AppColors.primaryYellow,
                              strokeWidth: 2,
                            ),
                          ),
                          SizedBox(width: 8),
                          Text(
                            'Memuat video...',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),

            // 3. Mini bottom progress line when controls are hidden
            if (!_showControls && _videoController != null && _videoController!.value.isInitialized)
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: SizedBox(
                  height: 3,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      // Buffered preload track
                      ValueListenableBuilder<double>(
                        valueListenable: _bufferedProgressNotifier,
                        builder: (context, buffered, _) {
                          return LinearProgressIndicator(
                            value: buffered,
                            backgroundColor: Colors.black.withValues(alpha: 0.3),
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.white.withValues(alpha: 0.3),
                            ),
                            minHeight: 3,
                          );
                        },
                      ),
                      // Active playback progress head
                      ValueListenableBuilder<double>(
                        valueListenable: _progressNotifier,
                        builder: (context, progress, _) {
                          return LinearProgressIndicator(
                            value: progress,
                            backgroundColor: Colors.transparent,
                            valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primaryYellow),
                            minHeight: 3,
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),

            // 4. Interactive Overlay Controls (Auto-hides after ~2 seconds)
            IgnorePointer(
              ignoring: !_showControls,
              child: AnimatedOpacity(
                opacity: _showControls ? 1.0 : 0.0,
                duration: const Duration(milliseconds: 250),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    // Dark Overlay Gradient
                    DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.black.withValues(alpha: 0.65),
                            Colors.transparent,
                            Colors.black.withValues(alpha: 0.85),
                          ],
                          stops: const [0.0, 0.45, 1.0],
                        ),
                      ),
                    ),

                    // Top Controls: Back button, Title/Series, Speaker
                    Positioned(
                      top: 10,
                      left: 12,
                      right: 12,
                      child: Row(
                        children: [
                          GestureDetector(
                            onTap: () {
                              _isPopping = true;
                              _stopVideo();
                              Navigator.of(context).pop();
                            },
                            child: Container(
                              width: 36,
                              height: 36,
                              decoration: BoxDecoration(
                                color: Colors.black.withValues(alpha: 0.55),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                LucideIcons.chevronLeft,
                                color: Colors.white,
                                size: 20,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                AutoSizeText(
                                  currentEpisode.title,
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white,
                                  ),
                                  maxLines: 1,
                                  minFontSize: 11,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                AutoSizeText(
                                  '${series.title} • Video ${currentEpisode.episodeNumber}',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: Colors.white.withValues(alpha: 0.75),
                                  ),
                                  maxLines: 1,
                                  minFontSize: 9,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                          GestureDetector(
                            onTap: () {
                              if (_videoController != null && _videoController!.value.isInitialized) {
                                final vol = _videoController!.value.volume;
                                _videoController!.setVolume(vol > 0 ? 0.0 : 1.0);
                                _safeSetState(() {});
                                if (_isPlaying) _scheduleHideControls();
                              }
                            },
                            child: Container(
                              width: 36,
                              height: 36,
                              decoration: BoxDecoration(
                                color: Colors.black.withValues(alpha: 0.55),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                (_videoController?.value.volume ?? 1.0) > 0
                                    ? LucideIcons.volume2
                                    : LucideIcons.volumeX,
                                color: Colors.white,
                                size: 18,
                              ),
                            ),
                          ),

                        ],
                      ),
                    ),

                    // Center Controls: Rewind 10, Play/Pause, Forward 10
                    Center(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          GestureDetector(
                            onTap: () => _seekRelative(-10),
                            child: Container(
                              width: 42,
                              height: 42,
                              decoration: BoxDecoration(
                                color: Colors.black.withValues(alpha: 0.45),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                LucideIcons.rotateCcw,
                                color: Colors.white,
                                size: 20,
                              ),
                            ),
                          ),
                          const SizedBox(width: 24),

                          // Play / Pause Button
                          GestureDetector(
                            onTap: _togglePlayPause,
                            child: Container(
                              width: 58,
                              height: 58,
                              decoration: const BoxDecoration(
                                color: AppColors.primaryYellow,
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                _isPlaying ? LucideIcons.pause : LucideIcons.play,
                                color: AppColors.primaryDark,
                                size: 28,
                              ),
                            ),
                          ),
                          const SizedBox(width: 24),

                          // Forward 10s
                          GestureDetector(
                            onTap: () => _seekRelative(10),
                            child: Container(
                              width: 42,
                              height: 42,
                              decoration: BoxDecoration(
                                color: Colors.black.withValues(alpha: 0.45),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                LucideIcons.rotateCw,
                                color: Colors.white,
                                size: 20,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Bottom Bar: Current Time, Slider, Next Video
                    Positioned(
                      left: 12,
                      right: 12,
                      bottom: 8,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              ValueListenableBuilder<Duration>(
                                valueListenable: _positionNotifier,
                                builder: (context, pos, _) {
                                  return Text(
                                    '${_formatDuration(pos)} / ${_formatDuration(_totalDuration)}',
                                    style: const TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.white,
                                    ),
                                  );
                                },
                              ),
                              Row(
                                children: [
                                  if (nextEpisode != null)
                                    GestureDetector(
                                      onTap: () => _playEpisode(nextEpisode.episodeNumber),
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                        decoration: BoxDecoration(
                                          color: Colors.black.withValues(alpha: 0.6),
                                          borderRadius: BorderRadius.circular(6),
                                        ),
                                        child: const Row(
                                          children: [
                                            Text(
                                              'Video Selanjutnya',
                                              style: TextStyle(
                                                fontSize: 10,
                                                fontWeight: FontWeight.w700,
                                                color: AppColors.primaryYellow,
                                              ),
                                            ),
                                            SizedBox(width: 4),
                                            Icon(
                                              LucideIcons.skipForward,
                                              size: 11,
                                              color: AppColors.primaryYellow,
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          // Progress Bar with smooth seek tap & drag (throttled for zero decoder jank)
                          GestureDetector(
                            behavior: HitTestBehavior.opaque,
                            onHorizontalDragStart: (details) {
                              _isScrubbing = true;
                              _hideControlsTimer?.cancel();
                            },
                            onHorizontalDragUpdate: (details) {
                              final box = context.findRenderObject() as RenderBox?;
                              if (box != null && _totalDuration.inMilliseconds > 0) {
                                final tapPos = details.localPosition.dx;
                                final totalWidth = box.size.width - 24;
                                final ratio = (tapPos / totalWidth).clamp(0.0, 1.0);
                                final seekMs = (ratio * _totalDuration.inMilliseconds).toInt();
                                _currentPosition = Duration(milliseconds: seekMs);
                                _currentProgress = ratio;
                                _positionNotifier.value = _currentPosition;
                                _progressNotifier.value = ratio;
                              }
                            },
                            onHorizontalDragEnd: (details) {
                              _isScrubbing = false;
                              if (_videoController != null && _totalDuration.inMilliseconds > 0) {
                                _videoController!.seekTo(_currentPosition);
                                if (_currentPosition < _totalDuration - const Duration(seconds: 2)) {
                                  _hasTriggeredCompletion = false;
                                }
                              }
                              if (_isPlaying) _scheduleHideControls();
                            },
                            onTapDown: (details) {
                              final box = context.findRenderObject() as RenderBox?;
                              if (box != null && _totalDuration.inMilliseconds > 0) {
                                final tapPos = details.localPosition.dx;
                                final totalWidth = box.size.width - 24;
                                final ratio = (tapPos / totalWidth).clamp(0.0, 1.0);
                                final seekMs = (ratio * _totalDuration.inMilliseconds).toInt();
                                final newDur = Duration(milliseconds: seekMs);
                                _currentPosition = newDur;
                                _currentProgress = ratio;
                                _positionNotifier.value = newDur;
                                _progressNotifier.value = ratio;
                                _videoController?.seekTo(newDur);
                                if (newDur < _totalDuration - const Duration(seconds: 2)) {
                                  _hasTriggeredCompletion = false;
                                }
                                if (_isPlaying) _scheduleHideControls();
                              }
                            },
                            child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              child: SizedBox(
                                height: 5,
                                child: Stack(
                                  fit: StackFit.expand,
                                  children: [
                                    // Buffered preload background track
                                    ValueListenableBuilder<double>(
                                      valueListenable: _bufferedProgressNotifier,
                                      builder: (context, buffered, _) {
                                        return LinearProgressIndicator(
                                          value: buffered,
                                          backgroundColor: Colors.white.withValues(alpha: 0.2),
                                          valueColor: AlwaysStoppedAnimation<Color>(
                                            Colors.white.withValues(alpha: 0.4),
                                          ),
                                          minHeight: 5,
                                        );
                                      },
                                    ),
                                    // Active playback head
                                    ValueListenableBuilder<double>(
                                      valueListenable: _progressNotifier,
                                      builder: (context, progress, _) {
                                        return LinearProgressIndicator(
                                          value: progress,
                                          backgroundColor: Colors.transparent,
                                          valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primaryYellow),
                                          minHeight: 5,
                                        );
                                      },
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
