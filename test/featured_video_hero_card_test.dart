import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:humora_mobile/data/models/episode_model.dart';
import 'package:humora_mobile/data/models/series_model.dart';
import 'package:humora_mobile/providers/auth_provider.dart';
import 'package:humora_mobile/providers/history_provider.dart';
import 'package:humora_mobile/providers/notification_provider.dart';
import 'package:humora_mobile/providers/series_provider.dart';
import 'package:humora_mobile/screens/home/home_screen.dart';
import 'package:humora_mobile/screens/video/video_player_screen.dart';

class MockFeaturedSeriesProvider extends SeriesProvider {
  List<SeriesModel> _mockList = [];
  SeriesModel? _mockFeatured;
  bool _mockLoading = false;

  @override
  bool get isLoading => _mockLoading;

  @override
  List<SeriesModel> get seriesList => _mockList;

  @override
  SeriesModel get featuredSeries =>
      _mockFeatured ?? super.featuredSeries;

  void setMockData({
    required List<SeriesModel> list,
    SeriesModel? featured,
    bool isLoading = false,
  }) {
    _mockList = list;
    _mockFeatured = featured;
    _mockLoading = isLoading;
    notifyListeners();
  }

  @override
  Future<void> fetchSeries() async {}

  @override
  Future<void> fetchCategories() async {}
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Featured Video & Hero Card Tests', () {
    test('SeriesModel correctly parses is_featured from Laravel humora-web API JSON', () {
      final jsonFromApi = {
        'id': 14,
        'title': 'Tipe Penumpang Taxi Online',
        'slug': 'tipe-penumpang-taxi-online',
        'synopsis': 'Kisah driver taxi online menghadapi aneka penumpang.',
        'release_year': '2026',
        'thumbnail_url': 'http://localhost:8000/api/v1/files/thumbnail/thumb.webp',
        'is_featured': true,
        'total_episodes': 4,
        'likes_count': 120,
        'genre': 'Komedi, Sosial',
        'episodes': [
          {
            'id': 101,
            'series_id': 14,
            'episode_number': 1,
            'title': 'Penumpang Cerewet',
            'duration': '2m 15s',
            'is_free': true,
          },
          {
            'id': 102,
            'series_id': 14,
            'episode_number': 2,
            'title': 'Sesi Curhat',
            'duration': '3m 00s',
            'is_free': true,
          },
        ],
      };

      final series = SeriesModel.fromJson(jsonFromApi);

      expect(series.id, '14');
      expect(series.title, 'Tipe Penumpang Taxi Online');
      expect(series.isFeatured, isTrue);
      expect(series.totalEpisodes, 4);
      expect(series.episodes.length, 2);
      expect(series.episodes.first.isFree, isTrue);
    });

    test('SeriesProvider selects isFeatured series as featuredSeries', () {
      final regularSeries1 = const SeriesModel(
        id: '1',
        title: 'Kos-kosan Kocak',
        synopsis: 'Cerita kosan',
        genre: 'Komedi',
        releaseYear: '2026',
        totalEpisodes: 4,
        likes: '10 Suka',
        thumbnailPath: '',
        isFeatured: false,
      );

      final featuredSeries = const SeriesModel(
        id: '14',
        title: 'Tipe Penumpang Taxi Online',
        synopsis: 'Kisah unik supir taxi',
        genre: 'Komedi',
        releaseYear: '2026',
        totalEpisodes: 4,
        likes: '50 Suka',
        thumbnailPath: '',
        isFeatured: true,
      );

      final provider = SeriesProvider();
      provider.setSeriesForTesting([regularSeries1, featuredSeries]);

      // featuredSeries should pick the one with isFeatured: true even if regularSeries1 is first in list
      expect(provider.featuredSeries.id, '14');
      expect(provider.featuredSeries.title, 'Tipe Penumpang Taxi Online');
    });

    testWidgets('HomeScreen _buildHeroCard displays the featured series with UNGGULAN badge', (tester) async {
      final mockSeriesProvider = MockFeaturedSeriesProvider();
      final mockAuthProvider = AuthProvider();
      final mockHistoryProvider = HistoryProvider();
      final mockNotificationProvider = NotificationProvider();

      final featuredVideo = const SeriesModel(
        id: '14',
        title: 'Tipe Penumpang Taxi Online',
        synopsis: 'Kisah driver taxi online menghadapi aneka watak penumpang yang unik.',
        genre: 'Komedi, Sosial',
        releaseYear: '2026',
        totalEpisodes: 4,
        likes: '1.2k Suka',
        thumbnailPath: 'assets/images/placeholder.webp',
        isFeatured: true,
        episodes: [
          EpisodeModel(
            id: '1',
            seriesId: '14',
            episodeNumber: 1,
            title: 'Ep 1',
            synopsis: 'Sinopsis Ep 1',
            duration: '2m',
            likes: '10 Suka',
            thumbnailPath: '',
            isFree: true,
          ),
          EpisodeModel(
            id: '2',
            seriesId: '14',
            episodeNumber: 2,
            title: 'Ep 2',
            synopsis: 'Sinopsis Ep 2',
            duration: '2m',
            likes: '20 Suka',
            thumbnailPath: '',
            isFree: true,
          ),
        ],
      );

      mockSeriesProvider.setMockData(
        list: [featuredVideo],
        featured: featuredVideo,
      );

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<SeriesProvider>.value(value: mockSeriesProvider),
            ChangeNotifierProvider<AuthProvider>.value(value: mockAuthProvider),
            ChangeNotifierProvider<HistoryProvider>.value(value: mockHistoryProvider),
            ChangeNotifierProvider<NotificationProvider>.value(value: mockNotificationProvider),
          ],
          child: ScreenUtilInit(
            designSize: const Size(375, 812),
            builder: (context, child) => const MaterialApp(
              home: HomeScreen(),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Check hero card contents
      expect(find.text('UNGGULAN'), findsOneWidget);
      expect(find.text('2 Video Gratis'), findsOneWidget);
      expect(find.text('Tipe Penumpang Taxi Online'), findsWidgets);
      expect(find.text('Tonton Sekarang'), findsOneWidget);
      expect(find.text('Detail'), findsOneWidget);

      // Tap "Tonton Sekarang" to verify navigation to VideoPlayerScreen
      await tester.tap(find.text('Tonton Sekarang'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.byType(VideoPlayerScreen), findsOneWidget);
    });
  });
}
