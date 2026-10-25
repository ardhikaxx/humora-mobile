import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';
import 'package:skeletonizer/skeletonizer.dart';
import '../../core/theme/app_colors.dart';
import '../../data/models/series_model.dart';
import '../../data/models/episode_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/series_provider.dart';
import '../../widgets/series_poster_card.dart';
import '../../widgets/humora_image.dart';
import '../../widgets/humora_empty_state.dart';
import '../../widgets/humora_mascot_refresh_indicator.dart';
import '../../widgets/paywall_modal.dart';
import '../video/series_detail_screen.dart';
import '../video/video_player_screen.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _searchController.text = context.read<SeriesProvider>().searchQuery;
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<_SearchVideoItem> _extractAllVideos(List<SeriesModel> seriesList) {
    final List<_SearchVideoItem> result = [];
    for (final s in seriesList) {
      if (s.episodes.isNotEmpty) {
        for (final ep in s.episodes) {
          result.add(_SearchVideoItem(series: s, episode: ep));
        }
      } else {
        result.add(_SearchVideoItem(series: s, episode: null));
      }
    }
    return result;
  }

  void _openVideo(BuildContext context, _SearchVideoItem item, AuthProvider auth) {
    if (item.episode != null) {
      final isLocked = !auth.canAccessEpisode(
        item.episode!.episodeNumber,
        episodeId: int.tryParse(item.episode!.id),
        seriesTotalEpisodes: item.series.totalEpisodes,
        isFreeEpisode: item.episode!.isFree,
      );
      if (isLocked) {
        PaywallModal.show(context);
        return;
      }
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => VideoPlayerScreen(
            seriesId: item.series.id,
            initialEpisodeNumber: item.episode!.episodeNumber,
          ),
        ),
      );
    } else {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => SeriesDetailScreen(seriesId: item.series.id),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final seriesProv = context.watch<SeriesProvider>();
    final seriesList = seriesProv.allSeries;

    final String query = seriesProv.searchQuery.trim();
    final String selectedCategory = seriesProv.selectedCategory;
    final bool isSearching = query.isNotEmpty || (selectedCategory != 'Semua' && selectedCategory.isNotEmpty);

    final allVideos = _extractAllVideos(seriesList);
    final matchingVideos = isSearching
        ? allVideos.where((item) => item.matches(query, selectedCategory)).toList()
        : <_SearchVideoItem>[];

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 8),

            // Fixed Search Bar Pill at Top
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Container(
                height: 52,
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(30),
                  border: Border.all(color: AppColors.border, width: 1.2),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x08000000),
                      blurRadius: 10,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    const Icon(
                      LucideIcons.search,
                      color: AppColors.accentPurple,
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextField(
                        controller: _searchController,
                        onChanged: (val) {
                          seriesProv.setSearchQuery(val);
                        },
                        decoration: const InputDecoration(
                          border: InputBorder.none,
                          hintText: 'Cari video, judul, sketsa, atau genre...',
                          hintStyle: TextStyle(
                            fontSize: 13.5,
                            color: AppColors.textMuted,
                          ),
                        ),
                      ),
                    ),
                    if (_searchController.text.isNotEmpty)
                      GestureDetector(
                        onTap: () {
                          _searchController.clear();
                          seriesProv.setSearchQuery('');
                        },
                        child: const Padding(
                          padding: EdgeInsets.all(4.0),
                          child: Icon(
                            LucideIcons.x,
                            size: 18,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),

            Expanded(
              child: HumoraMascotRefreshIndicator(
                onRefresh: () async {
                  await Future.wait([
                    seriesProv.fetchSeries(),
                    seriesProv.fetchCategories(),
                  ]);
                },
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.only(bottom: 100),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Title and Subtitle
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Cari cerita favoritmu',
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.w800,
                                color: AppColors.textPrimary,
                                letterSpacing: -0.4,
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              'Temukan berbagai video penuh canda dan cerita lucu',
                              style: TextStyle(
                                fontSize: 13,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Category Pills List
                      SizedBox(
                        height: 40,
                        child: ListView.separated(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          scrollDirection: Axis.horizontal,
                          physics: const AlwaysScrollableScrollPhysics(
                            parent: BouncingScrollPhysics(),
                          ),
                          itemCount: seriesProv.categories.length,
                          separatorBuilder: (_, _) => const SizedBox(width: 8),
                          itemBuilder: (context, index) {
                            final cat = seriesProv.categories[index];
                            final isSelected = seriesProv.selectedCategory == cat;

                            return GestureDetector(
                              onTap: () => seriesProv.setCategory(cat),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 18,
                                  vertical: 8,
                                ),
                                decoration: BoxDecoration(
                                  color: isSelected ? AppColors.primaryDark : AppColors.surface,
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color: isSelected ? AppColors.primaryDark : AppColors.border,
                                    width: 1.2,
                                  ),
                                ),
                                child: Center(
                                  child: Text(
                                    cat,
                                    style: TextStyle(
                                      fontSize: 12.5,
                                      fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                                      color: isSelected ? Colors.white : AppColors.textPrimary,
                                    ),
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 22),

                      // ==========================================
                      // 1. KATALOG LENGKAP (TETAP / FIXED DISPLAY)
                      // ==========================================
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Expanded(
                              child: Row(
                                children: [
                                  Icon(
                                    LucideIcons.clapperboard,
                                    size: 18,
                                    color: AppColors.accentPurple,
                                  ),
                                  SizedBox(width: 8),
                                  Flexible(
                                    child: Text(
                                      'Katalog Lengkap',
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
                            if (seriesList.isNotEmpty) ...[
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: AppColors.surface,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: AppColors.border, width: 1),
                                ),
                                child: Text(
                                  '${seriesList.length} Series',
                                  style: const TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Horizontal Scrollable Katalog Lengkap
                      if (seriesProv.isLoading && seriesList.isEmpty)
                        _buildKatalogSkeleton()
                      else if (seriesList.isEmpty)
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: AppColors.surface,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: AppColors.border),
                            ),
                            child: const Row(
                              children: [
                                Icon(LucideIcons.info, size: 20, color: AppColors.accentPurple),
                                SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    'Katalog belum tersedia. Tarik ke bawah untuk memuat ulang.',
                                    style: TextStyle(fontSize: 12.5, color: AppColors.textSecondary),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        )
                      else
                        SizedBox(
                          height: 145,
                          child: ListView.separated(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            scrollDirection: Axis.horizontal,
                            physics: const AlwaysScrollableScrollPhysics(
                              parent: BouncingScrollPhysics(),
                            ),
                            itemCount: seriesList.length,
                            separatorBuilder: (_, _) => const SizedBox(width: 12),
                            itemBuilder: (context, index) {
                              return SeriesPosterCard(
                                series: seriesList[index],
                              );
                            },
                          ),
                        ),

                      const SizedBox(height: 24),

                      // ============================================================
                      // 2. HASIL PENCARIAN (JIKA MENCARI) ATAU BENTO GRID (DEFAULT)
                      // ============================================================
                      if (isSearching) ...[
                        // SECTION KHUSUS HASIL PENCARIAN DIBAWAH KATALOG LENGKAP
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Row(
                                  children: [
                                    const Icon(
                                      LucideIcons.search,
                                      size: 18,
                                      color: AppColors.accentPurple,
                                    ),
                                    const SizedBox(width: 8),
                                    const Flexible(
                                      child: Text(
                                        'Hasil Pencarian',
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w800,
                                          color: AppColors.textPrimary,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: AppColors.accentPurpleSoft,
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Text(
                                        '${matchingVideos.length}',
                                        style: const TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w800,
                                          color: AppColors.accentPurple,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 8),
                              GestureDetector(
                                onTap: () {
                                  _searchController.clear();
                                  seriesProv.setSearchQuery('');
                                  seriesProv.setCategory('Semua');
                                },
                                child: const Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      LucideIcons.rotateCcw,
                                      size: 13,
                                      color: AppColors.accentPurple,
                                    ),
                                    SizedBox(width: 4),
                                    Text(
                                      'Reset',
                                      style: TextStyle(
                                        fontSize: 12.5,
                                        fontWeight: FontWeight.w700,
                                        color: AppColors.accentPurple,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (query.isNotEmpty || selectedCategory != 'Semua') ...[
                          const SizedBox(height: 6),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: Text(
                              query.isNotEmpty
                                  ? 'Menampilkan hasil untuk "$query"${selectedCategory != 'Semua' ? ' di kategori $selectedCategory' : ''}'
                                  : 'Menampilkan video kategori $selectedCategory',
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppColors.textSecondary,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                        const SizedBox(height: 14),

                        // Hasil pencarian: loading vs kosong vs list bento
                        if (seriesProv.isLoading && matchingVideos.isEmpty)
                          _buildBentoSkeleton()
                        else if (matchingVideos.isEmpty)
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                            child: HumoraEmptyState(
                              icon: LucideIcons.searchX,
                              title: 'Tidak Ada Hasil Ditemukan',
                              subtitle: query.isNotEmpty
                                  ? 'Tidak ada video yang cocok dengan kata kunci "$query". Silakan coba kata kunci lain.'
                                  : 'Tidak ada video dalam kategori "$selectedCategory".',
                              buttonText: 'Reset Pencarian',
                              buttonIcon: LucideIcons.rotateCcw,
                              onButtonPressed: () {
                                _searchController.clear();
                                seriesProv.setSearchQuery('');
                                seriesProv.setCategory('Semua');
                              },
                            ),
                          )
                        else
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: _buildBentoGrid(context, matchingVideos, auth),
                          ),
                      ] else ...[
                        // SECTION BENTO GRID VIDEO CARD DIBAWAH KATALOG LENGKAP (DEFAULT)
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Expanded(
                                child: Row(
                                  children: [
                                    Icon(
                                      LucideIcons.sparkles,
                                      size: 18,
                                      color: AppColors.primaryYellowDark,
                                    ),
                                    SizedBox(width: 8),
                                    Flexible(
                                      child: Text(
                                        'Koleksi Video Pilihan',
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
                              if (allVideos.isNotEmpty) ...[
                                const SizedBox(width: 8),
                                Text(
                                  '${allVideos.length} Video',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                        const SizedBox(height: 4),
                        const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 16),
                          child: Text(
                            'Tonton video sketsa dan komedi dengan format 16:9 terbaik',
                            style: TextStyle(
                              fontSize: 12,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ),
                        const SizedBox(height: 14),

                        if (seriesProv.isLoading && allVideos.isEmpty)
                          _buildBentoSkeleton()
                        else if (allVideos.isEmpty)
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                            child: HumoraEmptyState(
                              icon: LucideIcons.film,
                              title: 'Video Belum Tersedia',
                              subtitle: 'Belum ada video yang dapat ditampilkan saat ini. Silakan muat ulang data.',
                              buttonText: 'Muat Ulang Video',
                              buttonIcon: LucideIcons.rotateCcw,
                              onButtonPressed: () {
                                seriesProv.fetchSeries();
                                seriesProv.fetchCategories();
                              },
                            ),
                          )
                        else
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: _buildBentoGrid(context, allVideos, auth),
                          ),
                      ],
                      const SizedBox(height: 24),
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

  // ==========================================
  // BENTO GRID GENERATOR
  // ==========================================
  Widget _buildBentoGrid(
    BuildContext context,
    List<_SearchVideoItem> items,
    AuthProvider auth,
  ) {
    if (items.isEmpty) return const SizedBox.shrink();

    final List<Widget> widgets = [];
    int i = 0;
    int sectionIndex = 0;

    while (i < items.length) {
      final remaining = items.length - i;
      // Pola Bento:
      // sectionIndex % 3 == 0: 1 Card Hero 16:9 (Spotlight penuh)
      // sectionIndex % 3 == 1: 2 Card Duo 16:9 (Baris pertama 2 kolom)
      // sectionIndex % 3 == 2: 2 Card Duo 16:9 (Baris kedua 2 kolom)
      final pattern = sectionIndex % 3;

      if (pattern == 0 || remaining == 1) {
        // Hero 16:9 Card (Penuh 1 Kolom)
        widgets.add(_buildVideoBentoCard(context, items[i], auth, isHero: true));
        i += 1;
      } else {
        // Duo 16:9 Cards (2 Kolom Berdampingan)
        final first = items[i];
        final second = items[i + 1];
        widgets.add(
          Row(
            children: [
              Expanded(
                child: _buildVideoBentoCard(context, first, auth, isHero: false),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildVideoBentoCard(context, second, auth, isHero: false),
              ),
            ],
          ),
        );
        i += 2;
      }

      sectionIndex += 1;
      if (i < items.length) {
        widgets.add(const SizedBox(height: 12));
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: widgets,
    );
  }

  // ==========================================
  // BENTO VIDEO CARD (UI PERSIS KATALOG LENGKAP 16:9)
  // ==========================================
  Widget _buildVideoBentoCard(
    BuildContext context,
    _SearchVideoItem item,
    AuthProvider auth, {
    bool isHero = false,
  }) {
    final isGratis = item.isFree;
    final badgeLabel = isGratis ? 'GRATIS' : (item.series.isNew ? 'BARU' : 'PREMIUM');
    final badgeColor = isGratis ? AppColors.green : AppColors.primaryYellow;

    return GestureDetector(
      onTap: () => _openVideo(context, item, auth),
      child: AspectRatio(
        aspectRatio: 16 / 9,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            boxShadow: const [
              BoxShadow(
                color: Color(0x12000000),
                blurRadius: 10,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(18),
            child: Stack(
              fit: StackFit.expand,
              children: [
                // Full bleed thumbnail poster
                HumoraImage(
                  imagePathOrUrl: item.thumbnailPath,
                  fit: BoxFit.cover,
                ),

                // Gradient Overlay identik seperti SeriesPosterCard
                Positioned.fill(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.black.withValues(alpha: 0.35),
                          Colors.transparent,
                          Colors.black.withValues(alpha: 0.4),
                          Colors.black.withValues(alpha: 0.92),
                        ],
                        stops: const [0.0, 0.3, 0.6, 1.0],
                      ),
                    ),
                  ),
                ),

                // Top Badges Row (GRATIS/BARU badge on left & likes on right)
                Positioned(
                  top: isHero ? 8 : 6,
                  left: isHero ? 8 : 6,
                  right: isHero ? 8 : 6,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Flexible(
                        child: Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: isHero ? 6 : 5,
                            vertical: isHero ? 2.5 : 2,
                          ),
                          decoration: BoxDecoration(
                            color: badgeColor,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            badgeLabel,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: isHero ? 9.5 : 8.5,
                              fontWeight: FontWeight.w800,
                              color: isGratis ? Colors.white : AppColors.primaryDark,
                              letterSpacing: 0.3,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 4),
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: isHero ? 5 : 4,
                          vertical: isHero ? 2.5 : 2,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.55),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              LucideIcons.heart,
                              color: const Color(0xFFFF5252),
                              size: isHero ? 10 : 8.5,
                            ),
                            const SizedBox(width: 3),
                            Text(
                              item.likes,
                              style: TextStyle(
                                fontSize: isHero ? 9.5 : 8.5,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // Bottom Title & Category Info (Identik SeriesPosterCard)
                Positioned(
                  left: isHero ? 10 : 8,
                  right: isHero ? 10 : 8,
                  bottom: isHero ? 10 : 7,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          Text(
                            item.series.tag.toUpperCase(),
                            style: TextStyle(
                              fontSize: isHero ? 9 : 8,
                              fontWeight: FontWeight.w800,
                              color: AppColors.primaryYellow,
                              letterSpacing: 0.5,
                            ),
                          ),
                          const SizedBox(width: 5),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.6),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              item.duration,
                              style: TextStyle(
                                fontSize: isHero ? 8.5 : 7.5,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        item.title,
                        style: TextStyle(
                          fontSize: isHero ? 13.5 : 11,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                          height: 1.15,
                        ),
                        maxLines: isHero ? 2 : 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        item.episode != null
                            ? '${item.series.title} • Video ${item.episode!.episodeNumber}'
                            : '${item.series.totalEpisodes} Video',
                        style: TextStyle(
                          fontSize: isHero ? 11 : 9,
                          fontWeight: FontWeight.w500,
                          color: Colors.white.withValues(alpha: 0.8),
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
        ),
      ),
    );
  }

  // ==========================================
  // SKELETON LOADERS
  // ==========================================
  Widget _buildKatalogSkeleton() {
    return Skeletonizer(
      enabled: true,
      effect: const ShimmerEffect(
        baseColor: Color(0xFFEADBFA),
        highlightColor: Color(0xFFFBF9FD),
        duration: Duration(milliseconds: 1200),
      ),
      child: SizedBox(
        height: 145,
        child: ListView.separated(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          scrollDirection: Axis.horizontal,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: 4,
          separatorBuilder: (_, _) => const SizedBox(width: 12),
          itemBuilder: (_, _) => Container(
            width: 230,
            height: 120,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: AppColors.border, width: 1),
            ),
            child: Row(
              children: [
                Container(
                  width: 80,
                  height: 96,
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
                        width: double.infinity,
                        height: 14,
                        decoration: BoxDecoration(
                          color: AppColors.surfaceVariant,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        width: 70,
                        height: 10,
                        decoration: BoxDecoration(
                          color: AppColors.surfaceVariant,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Container(
                        width: 52,
                        height: 16,
                        decoration: BoxDecoration(
                          color: AppColors.surfaceVariant,
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBentoSkeleton() {
    return Skeletonizer(
      enabled: true,
      effect: const ShimmerEffect(
        baseColor: Color(0xFFEADBFA),
        highlightColor: Color(0xFFFBF9FD),
        duration: Duration(milliseconds: 1200),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Column(
          children: [
            // Big Hero Video Card (16:9)
            Container(
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.border, width: 1),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AspectRatio(
                    aspectRatio: 16 / 9,
                    child: Container(
                      decoration: const BoxDecoration(
                        color: AppColors.surfaceVariant,
                        borderRadius: BorderRadius.vertical(top: Radius.circular(19)),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 220,
                          height: 16,
                          decoration: BoxDecoration(
                            color: AppColors.surfaceVariant,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          width: 140,
                          height: 12,
                          decoration: BoxDecoration(
                            color: AppColors.surfaceVariant,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),

            // Two-column Bento Grid (16:9 each)
            Row(
              children: [
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.border, width: 1),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        AspectRatio(
                          aspectRatio: 16 / 9,
                          child: Container(
                            decoration: const BoxDecoration(
                              color: AppColors.surfaceVariant,
                              borderRadius: BorderRadius.vertical(top: Radius.circular(15)),
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(10),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                width: 90,
                                height: 12,
                                decoration: BoxDecoration(
                                  color: AppColors.surfaceVariant,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                              ),
                              const SizedBox(height: 6),
                              Container(
                                width: 50,
                                height: 10,
                                decoration: BoxDecoration(
                                  color: AppColors.surfaceVariant,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.border, width: 1),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        AspectRatio(
                          aspectRatio: 16 / 9,
                          child: Container(
                            decoration: const BoxDecoration(
                              color: AppColors.surfaceVariant,
                              borderRadius: BorderRadius.vertical(top: Radius.circular(15)),
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(10),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                width: 90,
                                height: 12,
                                decoration: BoxDecoration(
                                  color: AppColors.surfaceVariant,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                              ),
                              const SizedBox(height: 6),
                              Container(
                                width: 50,
                                height: 10,
                                decoration: BoxDecoration(
                                  color: AppColors.surfaceVariant,
                                  borderRadius: BorderRadius.circular(4),
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
          ],
        ),
      ),
    );
  }
}

// ==========================================
// SEARCH VIDEO ITEM HELPER MODEL
// ==========================================
class _SearchVideoItem {
  final SeriesModel series;
  final EpisodeModel? episode;

  const _SearchVideoItem({
    required this.series,
    this.episode,
  });

  String get title {
    if (episode != null && episode!.title.isNotEmpty) {
      return '${series.title} - ${episode!.title}';
    }
    return series.title;
  }

  String get thumbnailPath {
    if (episode != null && episode!.thumbnailPath.isNotEmpty) {
      return episode!.thumbnailPath;
    }
    return series.thumbnailPath;
  }

  String get duration => episode?.duration ?? '2m 30s';
  String get likes => episode?.likes ?? series.likes;
  String get genre => series.genre.isNotEmpty ? series.genre : series.tag;
  bool get isFree => episode?.isFree ?? series.isFreeAvailable;
  bool get isLocked => episode?.isLocked ?? false;
  String get synopsis {
    if (episode != null && episode!.synopsis.isNotEmpty) {
      return episode!.synopsis;
    }
    return series.synopsis;
  }

  bool matches(String query, String category) {
    final q = query.trim().toLowerCase();
    final c = category.trim().toLowerCase();

    final matchesQ = q.isEmpty ||
        title.toLowerCase().contains(q) ||
        series.title.toLowerCase().contains(q) ||
        series.genre.toLowerCase().contains(q) ||
        series.synopsis.toLowerCase().contains(q) ||
        (episode?.synopsis.toLowerCase().contains(q) ?? false);

    final matchesC = c.isEmpty ||
        c == 'semua' ||
        series.genre.toLowerCase().contains(c) ||
        series.tag.toLowerCase().contains(c) ||
        series.categories.any((cat) => cat.toLowerCase() == c);

    return matchesQ && matchesC;
  }
}
