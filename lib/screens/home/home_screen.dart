import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';
import 'package:showcaseview/showcaseview.dart';
import 'package:skeletonizer/skeletonizer.dart';
import '../../core/theme/app_colors.dart';
import '../../core/constants/app_assets.dart';
import '../../core/services/showcase_service.dart';
import '../../core/services/vibration_service.dart';
import '../../providers/auth_provider.dart';
import '../../providers/series_provider.dart';
import '../../providers/history_provider.dart';
import '../../providers/notification_provider.dart';
import '../../widgets/series_poster_card.dart';
import '../../widgets/humora_image.dart';
import '../../widgets/humora_empty_state.dart';
import '../../widgets/humora_mascot_refresh_indicator.dart';
import '../auth/login_screen.dart';
import '../notification/notification_screen.dart';
import '../subscription/subscription_plans_screen.dart';
import '../video/series_detail_screen.dart';
import '../video/video_player_screen.dart';

class HomeScreen extends StatefulWidget {
  final Function(int)? onNavigateTab;

  const HomeScreen({super.key, this.onNavigateTab});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final GlobalKey _keyLogo = GlobalKey();
  final GlobalKey _keyHeroCard = GlobalKey();
  final GlobalKey _keyPopular = GlobalKey();
  bool _showcaseTriggered = false;

  @override
  void initState() {
    super.initState();
    ShowcaseView.register();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkAndStartShowcase();
    });
  }

  void _checkAndStartShowcase() async {
    if (_showcaseTriggered || !mounted) return;
    final shouldShow = await ShowcaseService.shouldShowShowcase();
    if (!shouldShow || !mounted || _showcaseTriggered) return;

    final seriesProv = context.read<SeriesProvider>();
    if (seriesProv.isLoading || seriesProv.seriesList.isEmpty) return;

    _showcaseTriggered = true;
    try {
      ShowcaseView.get().startShowCase([
        _keyLogo,
        _keyHeroCard,
        _keyPopular,
      ]);
      await ShowcaseService.markShowcaseCompleted();
    } catch (_) {}
  }

  @override
  void dispose() {
    try {
      ShowcaseView.get().unregister();
    } catch (_) {}
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final seriesProv = context.watch<SeriesProvider>();
    final historyProv = context.watch<HistoryProvider>();
    final notifProv = context.watch<NotificationProvider>();

    final featured = seriesProv.featuredSeries;
    final continuing = historyProv.continuingHistory;

    if (!_showcaseTriggered && !seriesProv.isLoading && seriesProv.seriesList.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _checkAndStartShowcase();
      });
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // Fixed Floating Top Header
            _buildTopHeader(context, auth, notifProv),

            Expanded(
              child: HumoraMascotRefreshIndicator(
                onRefresh: () async {
                  await Future.wait([
                    seriesProv.fetchSeries(),
                    seriesProv.fetchCategories(),
                    historyProv.fetchHistory(),
                    notifProv.fetchNotifications(),
                  ]);
                },
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.only(bottom: 100),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 12),

              if (seriesProv.isLoading && seriesProv.seriesList.isEmpty) ...[
                _buildHomeSkeleton(context),
              ] else if (seriesProv.seriesList.isEmpty) ...[
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
                  child: HumoraEmptyState(
                    icon: LucideIcons.film,
                    title: 'Katalog Video Belum Tersedia',
                    subtitle: 'Saat ini belum ada episode sketsa komedi yang dapat ditampilkan. Silakan segarkan halaman untuk memeriksa konten baru.',
                    buttonText: 'Muat Ulang Halaman',
                    buttonIcon: LucideIcons.rotateCcw,
                    onButtonPressed: () {
                      seriesProv.fetchSeries();
                      seriesProv.fetchCategories();
                    },
                  ),
                ),
              ] else ...[
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
                  child: Showcase(
                    key: _keyHeroCard,
                    title: 'Serial Komedi Pilihan',
                    description: 'Ketuk poster ini untuk mulai menonton episode seru hari ini.',
                    tooltipBackgroundColor: AppColors.surface,
                    textColor: AppColors.textPrimary,
                    targetShapeBorder: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                    titleTextStyle: const TextStyle(fontWeight: FontWeight.w800, color: AppColors.accentPurple, fontSize: 14),
                    descTextStyle: const TextStyle(fontWeight: FontWeight.w500, color: AppColors.textSecondary, fontSize: 12),
                    child: _buildHeroCard(context, featured),
                  ),
                ),

                const SizedBox(height: 24),

              // Lanjutkan Menonton Section
              if (continuing.isNotEmpty) ...[
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Expanded(
                        child: Row(
                          children: [
                            Icon(
                              LucideIcons.history,
                              size: 18,
                              color: AppColors.accentPurple,
                            ),
                            SizedBox(width: 8),
                            Flexible(
                              child: Text(
                                'Lanjutkan Menonton',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.textPrimary,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      GestureDetector(
                        onTap: () => widget.onNavigateTab?.call(2), // Riwayat tab
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
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
              Showcase(
                key: _keyPopular,
                title: 'Koleksi Video Populer',
                description: 'Temukan video-video paling viral dan disukai oleh penonton HUMORA.',
                tooltipBackgroundColor: AppColors.surface,
                textColor: AppColors.textPrimary,
                titleTextStyle: const TextStyle(fontWeight: FontWeight.w800, color: Color(0xFFEF4444), fontSize: 14),
                descTextStyle: const TextStyle(fontWeight: FontWeight.w500, color: AppColors.textSecondary, fontSize: 12),
                child: _buildSectionHeader(
                  title: 'Video Populer',
                  icon: LucideIcons.flame,
                  iconColor: const Color(0xFFEF4444),
                  actionLabel: 'Lihat Semua',
                  onActionTap: () => widget.onNavigateTab?.call(1),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                height: 150,
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
                title: 'Terbaru di HUMORA',
                icon: LucideIcons.sparkles,
                iconColor: AppColors.accentPurple,
                actionLabel: 'Lihat Semua',
                onActionTap: () => widget.onNavigateTab?.call(1),
              ),
              const SizedBox(height: 12),
              SizedBox(
                height: 150,
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
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                LucideIcons.gift,
                                size: 18,
                                color: AppColors.green,
                              ),
                              SizedBox(width: 8),
                              Flexible(
                                child: Text(
                                  'Gratis untuk Kamu',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.textPrimary,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 2),
                          Text(
                            'Tonton 2 video pertama tanpa langganan',
                            style: TextStyle(
                              fontSize: 12,
                              color: AppColors.textSecondary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: () => widget.onNavigateTab?.call(1),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
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
                height: 150,
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
                icon: LucideIcons.compass,
                iconColor: AppColors.accentPurple,
                actionLabel: 'Jelajahi',
                onActionTap: () => widget.onNavigateTab?.call(1),
              ),
              const SizedBox(height: 12),
              SizedBox(
                height: 150,
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
            ],
          ),
        ),
      ),
    ),
  ],
),
    ),
  );
}

  Widget _buildHomeSkeleton(BuildContext context) {
    return Skeletonizer(
      enabled: true,
      effect: const ShimmerEffect(
        baseColor: Color(0xFFEADBFA),
        highlightColor: Color(0xFFFBF9FD),
        duration: Duration(milliseconds: 1200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // VIP Promo Banner Skeleton Placeholder
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Container(
              height: 68,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.border, width: 1.2),
              ),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: AppColors.surfaceVariant,
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 150,
                          height: 14,
                          decoration: BoxDecoration(
                            color: AppColors.surfaceVariant,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Container(
                          width: 200,
                          height: 10,
                          decoration: BoxDecoration(
                            color: AppColors.surfaceVariant,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    width: 90,
                    height: 32,
                    decoration: BoxDecoration(
                      color: AppColors.surfaceVariant,
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Featured Hero Card Skeleton Placeholder
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Container(
              height: 250,
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: AppColors.border, width: 1),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Top badges
                    Row(
                      children: [
                        Container(
                          width: 80,
                          height: 24,
                          decoration: BoxDecoration(
                            color: AppColors.surfaceVariant,
                            borderRadius: BorderRadius.circular(6),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          width: 90,
                          height: 24,
                          decoration: BoxDecoration(
                            color: AppColors.surfaceVariant,
                            borderRadius: BorderRadius.circular(6),
                          ),
                        ),
                      ],
                    ),
                    // Bottom title, synopsis & action buttons
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 220,
                          height: 20,
                          decoration: BoxDecoration(
                            color: AppColors.surfaceVariant,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          width: double.infinity,
                          height: 12,
                          decoration: BoxDecoration(
                            color: AppColors.surfaceVariant,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Container(
                          width: 180,
                          height: 12,
                          decoration: BoxDecoration(
                            color: AppColors.surfaceVariant,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                        const SizedBox(height: 14),
                        Row(
                          children: [
                            Container(
                              width: 140,
                              height: 38,
                              decoration: BoxDecoration(
                                color: AppColors.surfaceVariant,
                                borderRadius: BorderRadius.circular(20),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Container(
                              width: 110,
                              height: 38,
                              decoration: BoxDecoration(
                                color: AppColors.surfaceVariant,
                                borderRadius: BorderRadius.circular(20),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),

          const SizedBox(height: 24),

          // Video Populer Skeleton Section
          _buildSkeletonSectionHeader('Video Populer'),
          const SizedBox(height: 12),
          _buildSkeletonPosterList(),

          const SizedBox(height: 24),

          // Terbaru di HUMORA Skeleton Section
          _buildSkeletonSectionHeader('Terbaru di HUMORA'),
          const SizedBox(height: 12),
          _buildSkeletonPosterList(),

          const SizedBox(height: 24),

          // Gratis untuk Kamu Skeleton Section
          _buildSkeletonSectionHeader('Gratis untuk Kamu', subtitle: 'Tonton 2 video pertama tanpa langganan'),
          const SizedBox(height: 12),
          _buildSkeletonPosterList(),

          const SizedBox(height: 24),

          // Rekomendasi Buat Kamu Skeleton Section
          _buildSkeletonSectionHeader('Rekomendasi Buat Kamu'),
          const SizedBox(height: 12),
          _buildSkeletonPosterList(),
        ],
      ),
    );
  }

  Widget _buildSkeletonSectionHeader(String title, {String? subtitle}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 18,
                      height: 18,
                      decoration: const BoxDecoration(
                        color: AppColors.surfaceVariant,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      width: 130,
                      height: 16,
                      decoration: BoxDecoration(
                        color: AppColors.surfaceVariant,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ],
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 4),
                  Container(
                    width: 200,
                    height: 11,
                    decoration: BoxDecoration(
                      color: AppColors.surfaceVariant,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ],
              ],
            ),
          ),
          Container(
            width: 60,
            height: 14,
            decoration: BoxDecoration(
              color: AppColors.surfaceVariant,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSkeletonPosterList() {
    return SizedBox(
      height: 150,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        scrollDirection: Axis.horizontal,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: 4,
        separatorBuilder: (_, _) => const SizedBox(width: 12),
        itemBuilder: (_, _) => _buildSkeletonPosterCard(),
      ),
    );
  }

  Widget _buildSkeletonPosterCard() {
    return Container(
      width: 230,
      height: 120,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Top badges row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                width: 48,
                height: 18,
                decoration: BoxDecoration(
                  color: AppColors.surfaceVariant,
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
              Container(
                width: 38,
                height: 18,
                decoration: BoxDecoration(
                  color: AppColors.surfaceVariant,
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
            ],
          ),
          // Bottom info
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 110,
                height: 13,
                decoration: BoxDecoration(
                  color: AppColors.surfaceVariant,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              const SizedBox(height: 6),
              Container(
                width: 70,
                height: 10,
                decoration: BoxDecoration(
                  color: AppColors.surfaceVariant,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ],
          ),
        ],
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
          // Humora Full Rounded Logo (No Yellow Background)
          Showcase(
            key: _keyLogo,
            title: 'Selamat Datang di HUMORA!',
            description: 'Aplikasi streaming serial sketsa dan video komedi terbaik.',
            tooltipBackgroundColor: AppColors.surface,
            textColor: AppColors.textPrimary,
            targetShapeBorder: const CircleBorder(),
            titleTextStyle: const TextStyle(fontWeight: FontWeight.w800, color: AppColors.primaryYellowDark, fontSize: 14),
            descTextStyle: const TextStyle(fontWeight: FontWeight.w500, color: AppColors.textSecondary, fontSize: 12),
            child: ClipOval(
              child: Image.asset(
                AppAssets.logoHumora,
                width: 44,
                height: 44,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => const Icon(
                  LucideIcons.play,
                  size: 20,
                  color: AppColors.primaryDark,
                ),
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
                    const Flexible(
                      child: Text(
                        'Buka Akses Semua Video',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          color: AppColors.primaryDark,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
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
                  'Mulai Rp15.000 • Akses video serial',
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
              VibrationService.mediumImpact();
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
            HumoraImage(
              imagePathOrUrl: featured.thumbnailPath,
              fit: BoxFit.cover,
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
                  AutoSizeText(
                    featured.title,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                    maxLines: 1,
                    minFontSize: 16,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  AutoSizeText(
                    featured.synopsis,
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.white.withValues(alpha: 0.85),
                      height: 1.3,
                    ),
                    maxLines: 2,
                    minFontSize: 9,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 12),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Tonton Sekarang Button
                        GestureDetector(
                          onTap: () {
                            VibrationService.mediumImpact();
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
                    child: HumoraImage(
                      imagePathOrUrl: item.thumbnailPath,
                      fit: BoxFit.cover,
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
    IconData? icon,
    Color? iconColor,
    required String actionLabel,
    required VoidCallback onActionTap,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (icon != null) ...[
                  Icon(
                    icon,
                    size: 18,
                    color: iconColor ?? AppColors.accentPurple,
                  ),
                  const SizedBox(width: 8),
                ],
                Flexible(
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: onActionTap,
            child: Row(
              mainAxisSize: MainAxisSize.min,
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
