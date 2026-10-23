import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/services/vibration_service.dart';
import '../../data/models/episode_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/series_provider.dart';
import '../../widgets/custom_pill_app_bar.dart';
import '../../widgets/humora_image.dart';
import '../../widgets/humora_empty_state.dart';
import '../../widgets/paywall_modal.dart';
import '../../widgets/humora_toast.dart';
import 'video_player_screen.dart';

class SeriesDetailScreen extends StatefulWidget {
  final String seriesId;

  const SeriesDetailScreen({super.key, required this.seriesId});

  @override
  State<SeriesDetailScreen> createState() => _SeriesDetailScreenState();
}

class _SeriesDetailScreenState extends State<SeriesDetailScreen> {
  bool _isSynopsisExpanded = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<SeriesProvider>().fetchSeriesDetail(widget.seriesId);
    });
  }

  @override
  Widget build(BuildContext context) {
    final seriesProv = context.watch<SeriesProvider>();
    final auth = context.watch<AuthProvider>();
    final series = seriesProv.getSeriesById(widget.seriesId) ?? seriesProv.featuredSeries;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            CustomPillAppBar(
              title: series.title,
              onBackTap: () => Navigator.of(context).pop(),
            ),

            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 10),

                    // Big Video Player Preview Hero
                    _buildHeroPreview(context, series),
                    const SizedBox(height: 14),

                    // Meta: Year • Genres
                    Text(
                      '${series.releaseYear} • ${series.genre}',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 4),

                    // Series Title
                    Text(
                      series.title,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                        letterSpacing: -0.4,
                      ),
                    ),
                    const SizedBox(height: 12),

                    // 3 Badges Row
                    Row(
                      children: [
                        // Likes Pill
                        GestureDetector(
                          onTap: () async {
                            VibrationService.lightImpact();
                            final willLike = !seriesProv.isSeriesLiked(series.id);
                            final success = await seriesProv.toggleSeriesLike(series.id);
                            if (!context.mounted) return;
                            if (success) {
                              HumoraToast.showLike(
                                context,
                                isLiked: willLike,
                                targetTitle: series.title,
                                isSeries: true,
                              );
                            }
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(
                              color: seriesProv.isSeriesLiked(series.id)
                                  ? const Color(0xFFFEE2E2)
                                  : AppColors.surface,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: seriesProv.isSeriesLiked(series.id)
                                    ? const Color(0xFFFCA5A5)
                                    : AppColors.border,
                                width: 1.0,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  LucideIcons.heart,
                                  size: 13,
                                  color: seriesProv.isSeriesLiked(series.id)
                                      ? const Color(0xFFEF4444)
                                      : AppColors.textSecondary,
                                ),
                                const SizedBox(width: 5),
                                Text(
                                  seriesProv.isSeriesLiked(series.id)
                                      ? 'Disukai • ${series.likes.contains('Suka') ? series.likes : '${series.likes} Suka'}'
                                      : (series.likes.contains('Suka') ? series.likes : '${series.likes} Suka'),
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color: seriesProv.isSeriesLiked(series.id)
                                        ? const Color(0xFFDC2626)
                                        : AppColors.textPrimary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),

                        // Watchlist Pill
                        GestureDetector(
                          onTap: () {
                            VibrationService.lightImpact();
                            final isAdded = seriesProv.toggleWatchlist(series.id);
                            HumoraToast.showWatchlist(
                              context,
                              isAdded: isAdded,
                              seriesTitle: series.title,
                            );
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(
                              color: seriesProv.isSeriesInWatchlist(series.id)
                                  ? AppColors.yellowSoft
                                  : AppColors.surface,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: seriesProv.isSeriesInWatchlist(series.id)
                                    ? AppColors.primaryYellowDark
                                    : AppColors.border,
                                width: 1.0,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  seriesProv.isSeriesInWatchlist(series.id)
                                      ? LucideIcons.bookmarkCheck
                                      : LucideIcons.bookmark,
                                  size: 13,
                                  color: seriesProv.isSeriesInWatchlist(series.id)
                                      ? AppColors.primaryYellowDark
                                      : AppColors.textSecondary,
                                ),
                                const SizedBox(width: 5),
                                Text(
                                  seriesProv.isSeriesInWatchlist(series.id)
                                      ? 'Tersimpan'
                                      : 'Daftar Tonton',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color: seriesProv.isSeriesInWatchlist(series.id)
                                        ? AppColors.primaryDark
                                        : AppColors.textPrimary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),

                        // Videos Count Pill
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: AppColors.accentPurpleSoft,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(LucideIcons.film, size: 13, color: AppColors.accentPurple),
                              const SizedBox(width: 5),
                              Text(
                                '${series.totalEpisodes} Video',
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.accentPurple,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),

                        // Free Episodes Pill
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: const Color(0xFFE6F8F0),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(LucideIcons.check, size: 13, color: AppColors.green),
                              SizedBox(width: 4),
                              Text(
                                'Gratis Episode 1 & 2',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.green,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Lanjutkan Menonton Action Bar
                    _buildContinueBanner(context, series),
                    const SizedBox(height: 16),

                    // Sinopsis Cerita Card
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: AppColors.border, width: 1.2),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Row(
                            children: [
                              Icon(LucideIcons.sparkles, size: 14, color: Color(0xFFD97706)),
                              SizedBox(width: 6),
                              Text(
                                'SINOPSIS CERITA',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.textPrimary,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            series.synopsis,
                            maxLines: _isSynopsisExpanded ? null : 3,
                            overflow: _isSynopsisExpanded ? TextOverflow.visible : TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 12.5,
                              color: AppColors.textSecondary,
                              height: 1.45,
                            ),
                          ),
                          const SizedBox(height: 6),
                          GestureDetector(
                            onTap: () {
                              setState(() {
                                _isSynopsisExpanded = !_isSynopsisExpanded;
                              });
                            },
                            child: Row(
                              children: [
                                Text(
                                  _isSynopsisExpanded ? 'Tutup Selengkapnya' : 'Baca Selengkapnya',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.accentPurple,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                Icon(
                                  _isSynopsisExpanded ? LucideIcons.chevronUp : LucideIcons.chevronDown,
                                  size: 14,
                                  color: AppColors.accentPurple,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Daftar Video Section Header
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            const Text(
                              'Daftar Video',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              width: 22,
                              height: 22,
                              decoration: const BoxDecoration(
                                color: AppColors.accentPurpleSoft,
                                shape: BoxShape.circle,
                              ),
                              child: Center(
                                child: Text(
                                  '${series.episodes.length}',
                                  style: const TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.accentPurple,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        Text(
                          auth.isPremium ? 'Semua Terbuka' : 'Video 1 & 2 Gratis',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Episodes List
                    if (series.episodes.isEmpty) ...[
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        child: Container(
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: AppColors.surface,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: AppColors.border, width: 1.2),
                          ),
                          child: const HumoraEmptyState(
                            compact: true,
                            icon: LucideIcons.video,
                            title: 'Belum Ada Episode Dirilis',
                            subtitle: 'Series komedi ini sedang dipersiapkan. Episode baru akan segera diunggah ke platform.',
                          ),
                        ),
                      ),
                    ] else ...[
                      ...series.episodes.map((episode) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: _buildEpisodeCard(context, series, episode, auth),
                        );
                      }),
                    ],
                    const SizedBox(height: 30),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeroPreview(BuildContext context, dynamic series) {
    return GestureDetector(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => VideoPlayerScreen(
              seriesId: series.id,
              initialEpisodeNumber: 1,
            ),
          ),
        );
      },
      child: Container(
        height: 210,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(22),
          boxShadow: const [
            BoxShadow(
              color: Color(0x18000000),
              blurRadius: 14,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(22),
          child: Stack(
            fit: StackFit.expand,
            children: [
              HumoraImage(
                imagePathOrUrl: series.thumbnailPath,
                fit: BoxFit.cover,
              ),
              DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withValues(alpha: 0.15),
                      Colors.black.withValues(alpha: 0.3),
                      Colors.black.withValues(alpha: 0.85),
                    ],
                  ),
                ),
              ),

              // Center Yellow Play Button
              Center(
                child: Container(
                  width: 54,
                  height: 54,
                  decoration: const BoxDecoration(
                    color: AppColors.primaryYellow,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    LucideIcons.play,
                    color: AppColors.primaryDark,
                    size: 26,
                  ),
                ),
              ),

              // Bottom Badges
              Positioned(
                left: 12,
                bottom: 12,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.green,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Row(
                    children: [
                      Icon(LucideIcons.sparkles, size: 12, color: Colors.white),
                      SizedBox(width: 4),
                      Text(
                        '2 Video Gratis',
                        style: TextStyle(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Positioned(
                right: 12,
                bottom: 12,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.7),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Text(
                    '2m 10s',
                    style: TextStyle(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildContinueBanner(BuildContext context, dynamic series) {
    return GestureDetector(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => VideoPlayerScreen(
              seriesId: series.id,
              initialEpisodeNumber: 1,
            ),
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.primaryDark,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.primaryYellow,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                LucideIcons.play,
                color: AppColors.primaryDark,
                size: 20,
              ),
            ),
            const SizedBox(width: 14),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'LANJUTKAN MENONTON',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      color: AppColors.primaryYellow,
                      letterSpacing: 0.5,
                    ),
                  ),
                  SizedBox(height: 2),
                  Text(
                    'Video 1: Pake Hadiah',
                    style: TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
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
    );
  }

  Widget _buildEpisodeCard(
    BuildContext context,
    dynamic series,
    EpisodeModel episode,
    AuthProvider auth,
  ) {
    final totalEps = (series.episodes is List) ? (series.episodes as List).length : null;
    final isLocked = !auth.canAccessEpisode(
      episode.episodeNumber,
      episodeId: int.tryParse(episode.id),
      seriesTotalEpisodes: totalEps,
      isFreeEpisode: episode.isFree,
    );
    final isSelected = episode.episodeNumber == 1; // Highlighted in detail video reference

    return GestureDetector(
      onTap: () {
        if (isLocked) {
          PaywallModal.show(context);
        } else {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => VideoPlayerScreen(
                seriesId: series.id,
                initialEpisodeNumber: episode.episodeNumber,
              ),
            ),
          );
        }
      },
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: isSelected ? AppColors.accentPurple : AppColors.border,
            width: isSelected ? 1.8 : 1.2,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppColors.accentPurple.withValues(alpha: 0.08),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ]
              : null,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Thumbnail
            Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: SizedBox(
                    width: 105,
                    height: 72,
                    child: HumoraImage(
                      imagePathOrUrl: episode.thumbnailPath,
                      fit: BoxFit.cover,
                    ),
                  ),
                ),

                // Center Icon: Lock if locked, Play if unlocked
                Positioned.fill(
                  child: Center(
                    child: Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: isLocked ? Colors.black.withValues(alpha: 0.7) : AppColors.primaryYellow,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        isLocked ? LucideIcons.lock : LucideIcons.play,
                        color: isLocked ? const Color(0xFFFFCC00) : AppColors.primaryDark,
                        size: 15,
                      ),
                    ),
                  ),
                ),

                // Watched Indicator
                if (episode.isWatched && !isLocked)
                  Positioned(
                    top: 5,
                    right: 5,
                    child: Container(
                      width: 16,
                      height: 16,
                      decoration: const BoxDecoration(
                        color: AppColors.green,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(LucideIcons.check, size: 10, color: Colors.white),
                    ),
                  ),

                // Duration badge
                Positioned(
                  bottom: 5,
                  right: 5,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.7),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      episode.duration,
                      style: const TextStyle(
                        fontSize: 9.5,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(width: 12),

            // Details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Text(
                            'Video ${episode.episodeNumber}',
                            style: const TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w700,
                              color: AppColors.accentPurple,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Row(
                            children: [
                              const Icon(LucideIcons.heart, size: 10, color: Color(0xFFFF5252)),
                              const SizedBox(width: 3),
                              Text(
                                episode.likes,
                                style: const TextStyle(
                                  fontSize: 10,
                                  color: AppColors.textMuted,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      // Badge
                      if (isLocked)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.yellowSoft,
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: AppColors.primaryYellow, width: 1),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(LucideIcons.lock, size: 10, color: Color(0xFFD97706)),
                              SizedBox(width: 3),
                              Text(
                                'PREMIUM',
                                style: TextStyle(
                                  fontSize: 9,
                                  fontWeight: FontWeight.w800,
                                  color: Color(0xFFB45309),
                                ),
                              ),
                            ],
                          ),
                        )
                      else
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFFE6F8F0),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Text(
                            'GRATIS',
                            style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.w800,
                              color: AppColors.green,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(
                    episode.title,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    episode.synopsis,
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.textSecondary,
                      height: 1.3,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
