import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';
import 'package:video_player/video_player.dart';
import '../../core/network/api_config.dart';
import '../../core/network/api_service.dart';
import '../../core/theme/app_colors.dart';
import '../../data/models/episode_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/series_provider.dart';
import '../../providers/history_provider.dart';
import '../../widgets/humora_image.dart';
import '../../widgets/paywall_modal.dart';
import '../../widgets/series_poster_card.dart';
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

class _VideoPlayerScreenState extends State<VideoPlayerScreen> {
  late int _currentEpisodeNumber;
  VideoPlayerController? _videoController;
  bool _isControllerInitializing = false;
  bool _hasVideoError = false;
  bool _isPlaying = false;
  double _currentProgress = 0.0;
  Duration _currentPosition = Duration.zero;
  Duration _totalDuration = Duration.zero;
  bool _isDescriptionExpanded = false;

  @override
  void initState() {
    super.initState();
    _currentEpisodeNumber = widget.initialEpisodeNumber;
    _initializeVideoPlayer();
  }

  @override
  void dispose() {
    _syncWatchHistory();
    _videoController?.removeListener(_onVideoControllerUpdate);
    _videoController?.dispose();
    super.dispose();
  }

  void _onVideoControllerUpdate() {
    if (_videoController == null || !_videoController!.value.isInitialized) return;

    final pos = _videoController!.value.position;
    final dur = _videoController!.value.duration;

    if (dur.inMilliseconds > 0 && mounted) {
      setState(() {
        _currentPosition = pos;
        _totalDuration = dur;
        _currentProgress = (pos.inMilliseconds / dur.inMilliseconds).clamp(0.0, 1.0);
        _isPlaying = _videoController!.value.isPlaying;
      });
    }
  }

  Future<void> _initializeVideoPlayer() async {
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

    // Paywall Check: Episodes 1 & 2 are free preview. Episode 3+ requires VIP.
    if (_currentEpisodeNumber > 2 && !auth.isPremium) {
      setState(() {
        _hasVideoError = true;
      });
      WidgetsBinding.instance.addPostFrameCallback((_) {
        PaywallModal.show(context);
      });
      return;
    }

    setState(() {
      _isControllerInitializing = true;
      _hasVideoError = false;
    });

    try {
      final token = await ApiService().getToken();
      final headers = <String, String>{
        'Accept': 'video/mp4,video/*;q=0.9,*/*;q=0.8',
        if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
      };

      // Construct server stream URL
      final streamUrl = episode.streamUrl ??
          '${ApiConfig.baseUrl}/files/stream/${episode.id}';

      final oldController = _videoController;
      oldController?.removeListener(_onVideoControllerUpdate);

      final newController = VideoPlayerController.networkUrl(
        Uri.parse(streamUrl),
        httpHeaders: headers,
      );

      await newController.initialize();
      await oldController?.dispose();

      if (!mounted) {
        newController.dispose();
        return;
      }

      newController.addListener(_onVideoControllerUpdate);
      newController.play();

      setState(() {
        _videoController = newController;
        _isControllerInitializing = false;
        _isPlaying = true;
        _totalDuration = newController.value.duration;
      });

      _syncWatchHistory();
    } catch (e) {
      if (mounted) {
        setState(() {
          _isControllerInitializing = false;
          _hasVideoError = true;
        });
      }
    }
  }

  void _syncWatchHistory() {
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
  }

  void _playEpisode(int episodeNumber) {
    final auth = context.read<AuthProvider>();
    if (episodeNumber > 2 && !auth.isPremium) {
      PaywallModal.show(context);
      return;
    }

    _syncWatchHistory();

    setState(() {
      _currentEpisodeNumber = episodeNumber;
      _currentProgress = 0.0;
      _currentPosition = Duration.zero;
    });

    _initializeVideoPlayer();
  }

  void _togglePlayPause() {
    if (_videoController == null || !_videoController!.value.isInitialized) return;

    if (_videoController!.value.isPlaying) {
      _videoController!.pause();
      setState(() => _isPlaying = false);
    } else {
      _videoController!.play();
      setState(() => _isPlaying = true);
    }
  }

  void _seekRelative(int seconds) {
    if (_videoController == null || !_videoController!.value.isInitialized) return;

    final newPos = _videoController!.value.position + Duration(seconds: seconds);
    final clamped = Duration(
      milliseconds: newPos.inMilliseconds.clamp(0, _totalDuration.inMilliseconds),
    );
    _videoController!.seekTo(clamped);
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

    return Scaffold(
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
                    Text(
                      'Video ${currentEpisode.episodeNumber}: ${currentEpisode.title}',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                        letterSpacing: -0.3,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Video ${currentEpisode.episodeNumber} dari ${series.totalEpisodes} • ${currentEpisode.duration} • ${series.tag}',
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                          ),
                        ),
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
                      onTap: () {
                        seriesProv.toggleEpisodeLike(currentEpisode.id);
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
                    const SizedBox(width: 10),
                    const Text(
                      'Ketuk untuk menyukai video ini',
                      style: TextStyle(fontSize: 11, color: AppColors.textMuted),
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
                          setState(() {
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

              const SizedBox(height: 24),

              // Rekomendasi Series Lainnya
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Rekomendasi Lainnya 🔥',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    GestureDetector(
                      onTap: () => Navigator.of(context).pop(),
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
                    return SeriesPosterCard(series: item);
                  },
                ),
              ),
            ],
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
      child: Stack(
        fit: StackFit.expand,
        children: [
          // 1. Real VideoPlayer or Thumbnail Still
          if (_videoController != null && _videoController!.value.isInitialized)
            Center(
              child: AspectRatio(
                aspectRatio: _videoController!.value.aspectRatio > 0
                    ? _videoController!.value.aspectRatio
                    : 16 / 9,
                child: VideoPlayer(_videoController!),
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
                child: CircularProgressIndicator(
                  color: AppColors.primaryYellow,
                  strokeWidth: 3,
                ),
              ),
            )
          else if (_hasVideoError)
            Container(
              color: Colors.black.withValues(alpha: 0.75),
              padding: const EdgeInsets.all(24),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(LucideIcons.alertCircle, color: AppColors.primaryYellow, size: 36),
                    const SizedBox(height: 8),
                    const Text(
                      'Video tidak dapat diputar',
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 13),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 10),
                    ElevatedButton(
                      onPressed: _initializeVideoPlayer,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryYellow,
                        foregroundColor: AppColors.primaryDark,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      ),
                      child: const Text('Coba Lagi', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              ),
            ),

          // 3. Dark Overlay for Video Controls
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

          // 4. Top Controls: Back, Title/Series, Speaker
          Positioned(
            top: 10,
            left: 12,
            right: 12,
            child: Row(
              children: [
                GestureDetector(
                  onTap: () => Navigator.of(context).pop(),
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
                      Text(
                        currentEpisode.title,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        '${series.title} • Video ${currentEpisode.episodeNumber}',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.white.withValues(alpha: 0.75),
                        ),
                        maxLines: 1,
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
                      setState(() {});
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

          // 5. Center Controls: Rewind 10, Play/Pause, Forward 10
          Center(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Rewind 10s
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

          // 6. Bottom Bar: Current Time, Slider, Next Video, Fullscreen
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
                    Text(
                      '${_formatDuration(_currentPosition)} / ${_formatDuration(_totalDuration)}',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
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
                // Progress Bar with seek tap
                GestureDetector(
                  onHorizontalDragUpdate: (details) {
                    final box = context.findRenderObject() as RenderBox?;
                    if (box != null && _totalDuration.inMilliseconds > 0) {
                      final tapPos = details.localPosition.dx;
                      final totalWidth = box.size.width - 24;
                      final ratio = (tapPos / totalWidth).clamp(0.0, 1.0);
                      final seekMs = (ratio * _totalDuration.inMilliseconds).toInt();
                      _videoController?.seekTo(Duration(milliseconds: seekMs));
                    }
                  },
                  child: LinearProgressIndicator(
                    value: _currentProgress,
                    backgroundColor: Colors.white.withValues(alpha: 0.3),
                    valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primaryYellow),
                    minHeight: 4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
