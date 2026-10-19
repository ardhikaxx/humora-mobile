import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../data/models/episode_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/series_provider.dart';
import '../../providers/history_provider.dart';
import '../../widgets/series_poster_card.dart';
import '../../widgets/paywall_modal.dart';
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
  bool _isPlaying = true;
  double _currentProgress = 0.20; // 20% played
  bool _isLiked = false;
  bool _isDescriptionExpanded = false;

  @override
  void initState() {
    super.initState();
    _currentEpisodeNumber = widget.initialEpisodeNumber;
    _updateHistory();
  }

  void _updateHistory() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final seriesProv = context.read<SeriesProvider>();
      final series = seriesProv.getSeriesById(widget.seriesId) ?? seriesProv.featuredSeries;
      final episode = series.episodes.firstWhere(
        (e) => e.episodeNumber == _currentEpisodeNumber,
        orElse: () => series.episodes.first,
      );

      context.read<HistoryProvider>().addOrUpdateProgress(
        seriesId: series.id,
        seriesTitle: series.title,
        episodeNumberText: 'Video ${episode.episodeNumber}',
        episodeTitle: episode.title,
        thumbnailPath: episode.thumbnailPath,
        progressPercent: (_currentProgress * 100).toInt(),
      );
    });
  }

  void _playEpisode(int episodeNumber) {
    final auth = context.read<AuthProvider>();
    if (episodeNumber > 2 && !auth.isPremium) {
      PaywallModal.show(context);
      return;
    }

    setState(() {
      _currentEpisodeNumber = episodeNumber;
      _currentProgress = 0.05;
      _isPlaying = true;
    });
    _updateHistory();
  }

  @override
  Widget build(BuildContext context) {
    final seriesProv = context.watch<SeriesProvider>();
    final auth = context.watch<AuthProvider>();
    final series = seriesProv.getSeriesById(widget.seriesId) ?? seriesProv.featuredSeries;

    final currentEpisode = series.episodes.firstWhere(
      (e) => e.episodeNumber == _currentEpisodeNumber,
      orElse: () => series.episodes.first,
    );

    final nextEpisode = _currentEpisodeNumber < series.episodes.length
        ? series.episodes.firstWhere(
            (e) => e.episodeNumber == _currentEpisodeNumber + 1,
            orElse: () => series.episodes.first,
          )
        : null;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.only(bottom: 40),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top Video Player Section
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
                        setState(() {
                          _isLiked = !_isLiked;
                        });
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          color: _isLiked ? const Color(0xFFFEE2E2) : AppColors.surface,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: _isLiked ? const Color(0xFFFCA5A5) : AppColors.border,
                            width: 1.2,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              LucideIcons.heart,
                              size: 16,
                              color: _isLiked ? const Color(0xFFEF4444) : AppColors.textSecondary,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              _isLiked ? '5.601 Suka' : '5.600 Suka',
                              style: TextStyle(
                                fontSize: 12.5,
                                fontWeight: FontWeight.w700,
                                color: _isLiked ? const Color(0xFFEF4444) : AppColors.textPrimary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    const Text(
                      'Ketuk untuk menyukai video ini',
                      style: TextStyle(
                        fontSize: 11,
                        color: AppColors.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),

              // Description Card
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Container(
                  width: double.infinity,
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
                        currentEpisode.synopsis,
                        maxLines: _isDescriptionExpanded ? null : 2,
                        overflow: _isDescriptionExpanded ? TextOverflow.visible : TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: 4),
                      GestureDetector(
                        onTap: () {
                          setState(() {
                            _isDescriptionExpanded = !_isDescriptionExpanded;
                          });
                        },
                        child: Text(
                          _isDescriptionExpanded ? 'Tutup selengkapnya' : 'Lihat selengkapnya',
                          style: const TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w700,
                            color: AppColors.accentPurple,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 14),

              // Lanjut Otomatis Banner
              if (nextEpisode != null)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: GestureDetector(
                    onTap: () => _playEpisode(nextEpisode.episodeNumber),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.primaryDark,
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 38,
                            height: 38,
                            decoration: BoxDecoration(
                              color: AppColors.primaryYellow,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(
                              LucideIcons.play,
                              color: AppColors.primaryDark,
                              size: 18,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'LANJUT OTOMATIS',
                                  style: TextStyle(
                                    fontSize: 9.5,
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.primaryYellow,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                                const SizedBox(height: 1),
                                Text(
                                  'Video ${nextEpisode.episodeNumber}: ${nextEpisode.title}',
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                          const Icon(
                            LucideIcons.chevronRight,
                            color: Colors.white,
                            size: 20,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              const SizedBox(height: 20),

              // Daftar Video Section
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
                          style: const TextStyle(
                            fontSize: 11,
                            color: AppColors.textSecondary,
                          ),
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
                                  child: Image.asset(
                                    ep.thumbnailPath,
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, _, _) => Container(color: AppColors.primaryPurple),
                                  ),
                                ),
                              ),
                              if (isLocked)
                                Positioned.fill(
                                  child: Center(
                                    child: Container(
                                      width: 24,
                                      height: 24,
                                      decoration: BoxDecoration(
                                        color: Colors.black.withValues(alpha: 0.7),
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(
                                        LucideIcons.lock,
                                        color: AppColors.primaryYellow,
                                        size: 13,
                                      ),
                                    ),
                                  ),
                                )
                              else if (isCurrent)
                                Positioned.fill(
                                  child: Center(
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        _buildEqualizerBar(16),
                                        const SizedBox(width: 2),
                                        _buildEqualizerBar(22),
                                        const SizedBox(width: 2),
                                        _buildEqualizerBar(14),
                                      ],
                                    ),
                                  ),
                                ),
                              Positioned(
                                bottom: 4,
                                right: 4,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                                  decoration: BoxDecoration(
                                    color: Colors.black.withValues(alpha: 0.7),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    ep.duration,
                                    style: const TextStyle(
                                      fontSize: 8.5,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(width: 12),

                          // Text Info
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
                                  ep.synopsis,
                                  style: const TextStyle(
                                    fontSize: 10.5,
                                    color: AppColors.textSecondary,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),

                          // Right Icon
                          if (isCurrent)
                            Container(
                              width: 32,
                              height: 32,
                              decoration: const BoxDecoration(
                                color: AppColors.accentPurple,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                LucideIcons.play,
                                size: 16,
                                color: Colors.white,
                              ),
                            )
                          else
                            const Icon(
                              LucideIcons.chevronRight,
                              size: 16,
                              color: AppColors.textMuted,
                            ),
                        ],
                      ),
                    ),
                  ),
                );
              }),
              const SizedBox(height: 20),

              // Rekomendasi Judul Lainnya
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Rekomendasi Judul Lainnya',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    GestureDetector(
                      onTap: () => Navigator.of(context).pop(),
                      child: const Row(
                        children: [
                          Text(
                            'Lihat Semua',
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
          // Video Mock Still
          Image.asset(
            currentEpisode.thumbnailPath,
            fit: BoxFit.cover,
            errorBuilder: (_, _, _) => Container(color: AppColors.primaryPurple),
          ),

          // Dark overlay for controls
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

          // Top Controls: Back, Title/Series, Speaker
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
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.55),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    LucideIcons.volume2,
                    color: Colors.white,
                    size: 18,
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
                // Rewind 10s
                GestureDetector(
                  onTap: () {
                    setState(() {
                      _currentProgress = (_currentProgress - 0.1).clamp(0.0, 1.0);
                    });
                  },
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
                  onTap: () {
                    setState(() {
                      _isPlaying = !_isPlaying;
                    });
                  },
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
                  onTap: () {
                    setState(() {
                      _currentProgress = (_currentProgress + 0.1).clamp(0.0, 1.0);
                    });
                  },
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

          // Bottom Bar: Current Time, Slider, Video Selanjutnya, Fullscreen
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
                    const Text(
                      '0:26 / 2:10',
                      style: TextStyle(
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
                        const SizedBox(width: 10),
                        const Icon(
                          LucideIcons.maximize2,
                          color: Colors.white,
                          size: 16,
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                // Progress Bar
                LinearProgressIndicator(
                  value: _currentProgress,
                  backgroundColor: Colors.white.withValues(alpha: 0.3),
                  valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primaryYellow),
                  minHeight: 3,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEqualizerBar(double height) {
    return Container(
      width: 3.5,
      height: height,
      decoration: BoxDecoration(
        color: AppColors.primaryYellow,
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }
}
