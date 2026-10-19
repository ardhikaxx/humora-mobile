import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../data/dummy_data.dart';
import '../../providers/auth_provider.dart';
import '../../providers/series_provider.dart';
import '../../providers/history_provider.dart';
import '../../providers/notification_provider.dart';
import '../../widgets/series_poster_card.dart';
import '../auth/login_screen.dart';
import '../notification/notification_screen.dart';
import '../subscription/subscription_plans_screen.dart';
import '../video/series_detail_screen.dart';
import '../video/video_player_screen.dart';

class HomeScreen extends StatelessWidget {
  final Function(int)? onNavigateTab;

  const HomeScreen({super.key, this.onNavigateTab});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final seriesProv = context.watch<SeriesProvider>();
    final historyProv = context.watch<HistoryProvider>();
    final notifProv = context.watch<NotificationProvider>();

    final featured = seriesProv.featuredSeries;
    final continuing = historyProv.continuingHistory;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.only(bottom: 90),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top Pill Header
              _buildTopHeader(context, auth, notifProv),

              const SizedBox(height: 12),

              // VIP Promo Yellow Banner (Hidden for active Premium user)
              if (!auth.isPremium) ...[
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: _buildVipPromoBanner(context),
                ),
                const SizedBox(height: 16),
              ],

              // Featured Hero Card
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: _buildHeroCard(context, featured),
              ),

              const SizedBox(height: 24),

              // Lanjutkan Menonton Section
              if (continuing.isNotEmpty) ...[
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Lanjutkan Menonton',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      GestureDetector(
                        onTap: () => onNavigateTab?.call(2), // Riwayat tab
                        child: const Row(
                          children: [
                            Text(
                              'Riwayat',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: AppColors.accentPurple,
                              ),
                            ),
                            SizedBox(width: 2),
                            Icon(
                              LucideIcons.chevronRight,
                              size: 16,
                              color: AppColors.accentPurple,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  height: 190,
                  child: ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    scrollDirection: Axis.horizontal,
                    itemCount: continuing.length,
                    separatorBuilder: (_, _) => const SizedBox(width: 14),
                    itemBuilder: (context, index) {
                      final item = continuing[index];
                      return _buildContinueWatchingCard(context, item);
                    },
                  ),
                ),
                const SizedBox(height: 24),
              ],

              // Video Populer Section
              _buildSectionHeader(
                title: 'Video Populer 🌶️',
                actionLabel: 'Lihat Semua',
                onActionTap: () => onNavigateTab?.call(1),
              ),
              const SizedBox(height: 12),
              SizedBox(
                height: 215,
                child: ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  scrollDirection: Axis.horizontal,
                  itemCount: seriesProv.popularSeries.length,
                  separatorBuilder: (_, _) => const SizedBox(width: 12),
                  itemBuilder: (context, index) {
                    final series = seriesProv.popularSeries[index];
                    return SeriesPosterCard(
                      series: series,
                      badgeLabel: index == 0 ? 'GRATIS' : (index == 1 ? 'BARU' : 'GRATIS'),
                    );
                  },
                ),
              ),

              const SizedBox(height: 24),

              // Terbaru di HUMORA Section
              _buildSectionHeader(
                title: 'Terbaru di HUMORA ✨',
                actionLabel: 'Lihat Semua',
                onActionTap: () => onNavigateTab?.call(1),
              ),
              const SizedBox(height: 12),
              SizedBox(
                height: 215,
                child: ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  scrollDirection: Axis.horizontal,
                  itemCount: seriesProv.newSeries.length,
                  separatorBuilder: (_, _) => const SizedBox(width: 12),
                  itemBuilder: (context, index) {
                    final series = seriesProv.newSeries[index];
                    return SeriesPosterCard(
                      series: series,
                      badgeLabel: 'BARU',
                      badgeColor: AppColors.primaryYellowDark,
                    );
                  },
                ),
              ),

              const SizedBox(height: 24),

              // Gratis untuk Kamu Section
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Gratis untuk Kamu',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'Tonton 2 video pertama tanpa langganan',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                    GestureDetector(
                      onTap: () => onNavigateTab?.call(1),
                      child: const Row(
                        children: [
                          Text(
                            'Semua',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: AppColors.accentPurple,
                            ),
                          ),
                          SizedBox(width: 2),
                          Icon(
                            LucideIcons.chevronRight,
                            size: 16,
                            color: AppColors.accentPurple,
                          ),
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
                  itemCount: seriesProv.freeSeries.length,
                  separatorBuilder: (_, _) => const SizedBox(width: 12),
                  itemBuilder: (context, index) {
                    final series = seriesProv.freeSeries[index];
                    return SeriesPosterCard(
                      series: series,
                      badgeLabel: index % 2 == 0 ? 'BARU' : 'GRATIS',
                    );
                  },
                ),
              ),

              const SizedBox(height: 24),

              // Rekomendasi Buat Kamu Section
              _buildSectionHeader(
                title: 'Rekomendasi Buat Kamu',
                actionLabel: 'Jelajahi',
                onActionTap: () => onNavigateTab?.call(1),
              ),
              const SizedBox(height: 12),
              SizedBox(
                height: 215,
                child: ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  scrollDirection: Axis.horizontal,
                  itemCount: seriesProv.recommendedSeries.length,
                  separatorBuilder: (_, _) => const SizedBox(width: 12),
                  itemBuilder: (context, index) {
                    final series = seriesProv.recommendedSeries[index];
                    return SeriesPosterCard(
                      series: series,
                      badgeLabel: index % 2 == 0 ? 'GRATIS' : 'BARU',
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTopHeader(
    BuildContext context,
    AuthProvider auth,
    NotificationProvider notif,
  ) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: AppColors.border, width: 1.2),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A000000),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          // Humora Circular Logo
          Container(
            width: 38,
            height: 38,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.primaryYellow,
            ),
            padding: const EdgeInsets.all(4),
            child: Image.asset(
              DummyData.logoHumora,
              fit: BoxFit.contain,
              errorBuilder: (_, _, _) => const Icon(
                LucideIcons.play,
                size: 20,
                color: AppColors.primaryDark,
              ),
            ),
          ),
          const SizedBox(width: 12),

          // User status text or login button
          Expanded(
            child: auth.isGuest
                ? Align(
                    alignment: Alignment.centerLeft,
                    child: GestureDetector(
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const LoginScreen(),
                          ),
                        );
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 6),
                        decoration: BoxDecoration(
                          color: AppColors.primaryYellow,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Text(
                          'Masuk',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: AppColors.primaryDark,
                          ),
                        ),
                      ),
                    ),
                  )
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Hai, ${auth.user.name.split(' ').first}',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      GestureDetector(
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => const SubscriptionPlansScreen(),
                            ),
                          );
                        },
                        child: Row(
                          children: [
                            if (auth.isPremium) ...[
                              const Icon(
                                LucideIcons.crown,
                                size: 12,
                                color: Color(0xFFD97706),
                              ),
                              const SizedBox(width: 4),
                              const Text(
                                'Humora Premium',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.accentPurple,
                                ),
                              ),
                            ] else if (auth.isExpired) ...[
                              const Icon(
                                LucideIcons.alertTriangle,
                                size: 12,
                                color: AppColors.orange,
                              ),
                              const SizedBox(width: 4),
                              const Text(
                                'Perpanjang Premium >',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.orange,
                                ),
                              ),
                            ] else ...[
                              const Text(
                                'Upgrade ke VIP',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.accentPurple,
                                ),
                              ),
                              const SizedBox(width: 2),
                              const Icon(
                                LucideIcons.chevronRight,
                                size: 13,
                                color: AppColors.accentPurple,
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
          ),

          // Bell Notification Icon
          GestureDetector(
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const NotificationScreen(),
                ),
              );
            },
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF9F6FC),
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.border, width: 1),
                  ),
                  child: const Icon(
                    LucideIcons.bell,
                    size: 18,
                    color: AppColors.textPrimary,
                  ),
                ),
                if (notif.unreadCount > 0)
                  Positioned(
                    top: 2,
                    right: 2,
                    child: Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: Color(0xFFEC4899),
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVipPromoBanner(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color(0xFFFFCC00),
            Color(0xFFFFB300),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(
            color: Color(0x1A000000),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          // Crown Icon Square
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.primaryDark,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              LucideIcons.crown,
              color: AppColors.primaryYellow,
              size: 22,
            ),
          ),
          const SizedBox(width: 12),

          // Text details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    const Text(
                      'Buka Akses Semua Video',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        color: AppColors.primaryDark,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 5, vertical: 1.5),
                      decoration: BoxDecoration(
                        color: AppColors.primaryDark,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Text(
                        'VIP',
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w800,
                          color: AppColors.primaryYellow,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                const Text(
                  'Mulai Rp19.000 • Nonton bebas t...',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF4A3400),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),

          // Langganan Button
          GestureDetector(
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const SubscriptionPlansScreen(),
                ),
              );
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
              decoration: BoxDecoration(
                color: AppColors.primaryDark,
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Langganan',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                  SizedBox(width: 4),
                  Icon(
                    LucideIcons.chevronRight,
                    size: 14,
                    color: Colors.white,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeroCard(BuildContext context, dynamic featured) {
    return Container(
      height: 250,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        boxShadow: const [
          BoxShadow(
            color: Color(0x18000000),
            blurRadius: 16,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Thumbnail
            Image.asset(
              featured.thumbnailPath,
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) => Container(
                color: AppColors.primaryPurple,
              ),
            ),

            // Gradient Overlay
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.2),
                    Colors.black.withValues(alpha: 0.3),
                    Colors.black.withValues(alpha: 0.85),
                    Colors.black.withValues(alpha: 0.95),
                  ],
                  stops: const [0.0, 0.4, 0.75, 1.0],
                ),
              ),
            ),

            // Top Badges
            Positioned(
              top: 14,
              left: 14,
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.primaryYellow,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(LucideIcons.sparkles, size: 11, color: AppColors.primaryDark),
                        SizedBox(width: 4),
                        Text(
                          'TERBARU',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            color: AppColors.primaryDark,
                            letterSpacing: 0.4,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.55),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Text(
                      '2 Video Gratis',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Bottom Content
            Positioned(
              left: 14,
              right: 14,
              bottom: 14,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    featured.title,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    featured.synopsis,
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.white.withValues(alpha: 0.85),
                      height: 1.3,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      // Tonton Sekarang Button
                      GestureDetector(
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => VideoPlayerScreen(
                                seriesId: featured.id,
                                initialEpisodeNumber: 1,
                              ),
                            ),
                          );
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 8),
                          decoration: BoxDecoration(
                            color: AppColors.primaryYellow,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                LucideIcons.play,
                                size: 14,
                                color: AppColors.primaryDark,
                              ),
                              SizedBox(width: 6),
                              Text(
                                'Tonton Sekarang',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.primaryDark,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),

                      // Detail Button
                      GestureDetector(
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => SeriesDetailScreen(
                                seriesId: featured.id,
                              ),
                            ),
                          );
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.3),
                              width: 1,
                            ),
                          ),
                          child: const Text(
                            'Detail',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContinueWatchingCard(BuildContext context, dynamic item) {
    return GestureDetector(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => VideoPlayerScreen(
              seriesId: item.seriesId,
              initialEpisodeNumber: 1,
            ),
          ),
        );
      },
      child: Container(
        width: 220,
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border, width: 1.2),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Thumbnail with play button overlay
            Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(15)),
                  child: SizedBox(
                    height: 120,
                    width: double.infinity,
                    child: Image.asset(
                      item.thumbnailPath,
                      fit: BoxFit.cover,
                      errorBuilder: (_, _, _) => Container(
                        color: AppColors.primaryPurple,
                      ),
                    ),
                  ),
                ),
                // Play Button Center
                Positioned.fill(
                  child: Center(
                    child: Container(
                      width: 38,
                      height: 38,
                      decoration: const BoxDecoration(
                        color: AppColors.primaryYellow,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        LucideIcons.play,
                        color: AppColors.primaryDark,
                        size: 20,
                      ),
                    ),
                  ),
                ),
                // Remaining time badge
                Positioned(
                  bottom: 6,
                  right: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.7),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Text(
                      'Sisa 0:49',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.seriesTitle,
                    style: const TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${item.episodeNumberText}: ${item.episodeTitle}',
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.textSecondary,
                    ),
                    maxLines: 1,
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

  Widget _buildSectionHeader({
    required String title,
    required String actionLabel,
    required VoidCallback onActionTap,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
            ),
          ),
          GestureDetector(
            onTap: onActionTap,
            child: Row(
              children: [
                Text(
                  actionLabel,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.accentPurple,
                  ),
                ),
                const SizedBox(width: 2),
                const Icon(
                  LucideIcons.chevronRight,
                  size: 16,
                  color: AppColors.accentPurple,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
