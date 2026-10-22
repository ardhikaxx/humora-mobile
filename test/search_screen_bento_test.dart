import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:humora_mobile/data/models/series_model.dart';
import 'package:humora_mobile/data/models/episode_model.dart';
import 'package:humora_mobile/providers/auth_provider.dart';
import 'package:humora_mobile/providers/series_provider.dart';
import 'package:humora_mobile/screens/search/search_screen.dart';
import 'package:humora_mobile/widgets/series_poster_card.dart';
import 'package:humora_mobile/core/services/permission_service.dart';
import 'package:humora_mobile/core/services/local_notification_service.dart';
import 'package:humora_mobile/core/services/connectivity_service.dart';
import 'package:humora_mobile/core/services/wakelock_service.dart';
import 'package:humora_mobile/core/services/vibration_service.dart';
import 'package:humora_mobile/core/services/showcase_service.dart';

class TestSearchSeriesProvider extends SeriesProvider {
  @override
  Future<void> fetchSeries() async {}

  @override
  Future<void> fetchCategories() async {}
}

void main() {
  setUpAll(() {
    TestWidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues({});
    PermissionService.disableAutoPromptForTesting = true;
    LocalNotificationService.disableInTests = true;
    ConnectivityService.disableInTests = true;
    WakelockService.disableInTests = true;
    VibrationService.disableInTests = true;
    ShowcaseService.disableInTests = true;
  });

  final dummyEpisodes1 = [
    const EpisodeModel(
      id: '1',
      seriesId: '1',
      episodeNumber: 1,
      title: 'Part 1',
      synopsis: 'Episode satu lucu',
      duration: '3m 06s',
      likes: '10 Suka',
      thumbnailPath: 'assets/logo-humora.png',
      isFree: true,
    ),
    const EpisodeModel(
      id: '2',
      seriesId: '1',
      episodeNumber: 2,
      title: 'Part 2',
      synopsis: 'Episode dua kocak',
      duration: '2m 09s',
      likes: '5 Suka',
      thumbnailPath: 'assets/logo-humora.png',
      isFree: true,
    ),
  ];

  final dummySeries = [
    SeriesModel(
      id: '1',
      slug: 'baru-jadian',
      title: 'Baru Jadian vs Lama Jadian',
      synopsis: 'Perbandingan lucu pasangan baru jadian dan lama jadian',
      genre: 'Romantis, Komedi',
      releaseYear: '2026',
      totalEpisodes: 2,
      likes: '1.2k Suka',
      thumbnailPath: 'assets/logo-humora.png',
      episodes: dummyEpisodes1,
      categories: const ['Romantis', 'Komedi'],
    ),
    const SeriesModel(
      id: '2',
      slug: 'gue-sih-gitu',
      title: 'Gue sih gitu orangnya',
      synopsis: 'Tingkah konyol orang yang merasa benar',
      genre: 'Komedi, Sketsa',
      releaseYear: '2026',
      totalEpisodes: 1,
      likes: '800 Suka',
      thumbnailPath: 'assets/logo-humora.png',
      categories: ['Komedi', 'Sketsa'],
    ),
    const SeriesModel(
      id: '3',
      slug: 'tips-kentut',
      title: 'Tips Kentut di Tempat Umum',
      synopsis: 'Tips absurd menahan kentut',
      genre: 'Komedi, Tips',
      releaseYear: '2026',
      totalEpisodes: 1,
      likes: '2.5k Suka',
      thumbnailPath: 'assets/logo-humora.png',
      categories: ['Komedi', 'Tips'],
    ),
  ];

  Widget createSearchScreen(TestSearchSeriesProvider seriesProv) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<AuthProvider>(create: (_) => AuthProvider()),
        ChangeNotifierProvider<SeriesProvider>.value(value: seriesProv),
      ],
      child: const MaterialApp(
        home: SearchScreen(),
      ),
    );
  }

  testWidgets('SearchScreen renders horizontal scrollable Katalog Lengkap and Bento Grid video cards',
      (tester) async {
    final seriesProv = TestSearchSeriesProvider();
    seriesProv.setSeriesForTesting(dummySeries);
    seriesProv.setIsLoadingForTesting(false);

    await tester.pumpWidget(createSearchScreen(seriesProv));
    await tester.pumpAndSettle();

    // Verify Katalog Lengkap Header and Series count
    expect(find.text('Katalog Lengkap'), findsOneWidget);
    expect(find.text('3 Series'), findsOneWidget);

    // Verify horizontal ListView for Katalog Lengkap exists with horizontal scroll direction
    final horizontalListFinder = find.byWidgetPredicate(
      (w) => w is ListView && w.scrollDirection == Axis.horizontal,
    );
    expect(horizontalListFinder, findsWidgets);

    // Verify SeriesPosterCard widgets are present inside the horizontal list
    expect(find.byType(SeriesPosterCard), findsWidgets);

    // Verify Bento Grid section underneath Katalog Lengkap exists in default state
    expect(find.text('Koleksi Video Pilihan'), findsOneWidget);
    expect(find.text('Tonton video sketsa dan komedi dengan format 16:9 terbaik'), findsOneWidget);

    // Verify 16:9 AspectRatio widgets exist for YouTube style cards
    final aspectRatioFinder = find.byWidgetPredicate(
      (w) => w is AspectRatio && (w.aspectRatio - (16 / 9)).abs() < 0.01,
    );
    expect(aspectRatioFinder, findsWidgets);

    // Verify YouTube style duration badges are rendered (e.g. 3m 06s, 2m 09s)
    expect(find.text('3m 06s'), findsOneWidget);
    expect(find.text('2m 09s'), findsOneWidget);
  });

  testWidgets('When user searches, Katalog Lengkap remains fixed and Hasil Pencarian displays underneath',
      (tester) async {
    final seriesProv = TestSearchSeriesProvider();
    seriesProv.setSeriesForTesting(dummySeries);
    seriesProv.setIsLoadingForTesting(false);

    await tester.pumpWidget(createSearchScreen(seriesProv));
    await tester.pumpAndSettle();

    // Type "Kentut" into the search bar
    final textFieldFinder = find.byType(TextField);
    expect(textFieldFinder, findsOneWidget);
    await tester.enterText(textFieldFinder, 'Kentut');
    await tester.pumpAndSettle();

    // CRITICAL: Katalog Lengkap MUST STILL BE VISIBLE AND FIXED AT ITS POSITION
    expect(find.text('Katalog Lengkap'), findsOneWidget);
    expect(find.text('3 Series'), findsOneWidget);
    expect(find.byType(SeriesPosterCard), findsWidgets);

    // DEDICATED SEARCH RESULTS SECTION APPEARS UNDERNEATH KATALOG LENGKAP
    expect(find.text('Hasil Pencarian'), findsOneWidget);
    expect(find.text('Menampilkan hasil untuk "Kentut"'), findsOneWidget);
    expect(find.text('Tips Kentut di Tempat Umum'), findsWidgets);

    // Verify Reset button is present
    expect(find.text('Reset'), findsOneWidget);

    // Tap Reset
    await tester.tap(find.text('Reset'));
    await tester.pumpAndSettle();

    // Should return to default Bento Grid
    expect(find.text('Koleksi Video Pilihan'), findsOneWidget);
    expect(find.text('Hasil Pencarian'), findsNothing);
  });

  testWidgets('When search yields no results, Katalog Lengkap stays fixed and empty state is shown underneath',
      (tester) async {
    final seriesProv = TestSearchSeriesProvider();
    seriesProv.setSeriesForTesting(dummySeries);
    seriesProv.setIsLoadingForTesting(false);

    await tester.pumpWidget(createSearchScreen(seriesProv));
    await tester.pumpAndSettle();

    // Type a nonexistent query
    final textFieldFinder = find.byType(TextField);
    await tester.enterText(textFieldFinder, 'NonExistentComedyXYZ');
    await tester.pumpAndSettle();

    // Katalog Lengkap remains visible
    expect(find.text('Katalog Lengkap'), findsOneWidget);

    // Hasil Pencarian section shows empty state
    expect(find.text('Hasil Pencarian'), findsOneWidget);
    expect(find.text('Tidak Ada Hasil Ditemukan'), findsOneWidget);
    expect(find.text('Reset Pencarian'), findsOneWidget);

    // Ensure visible and Tap Reset button at top or Reset Pencarian button
    await tester.tap(find.text('Reset'));
    await tester.pumpAndSettle();

    // Returns to default state
    expect(find.text('Koleksi Video Pilihan'), findsOneWidget);
  });
}
