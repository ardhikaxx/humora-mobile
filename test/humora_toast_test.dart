import 'package:delightful_toast/delight_toast.dart';
import 'package:delightful_toast/toast/components/toast_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:humora_mobile/widgets/humora_toast.dart';

void main() {
  setUp(() {
    HumoraToast.disableAutoDismissInTests = true;
    DelightToastBar.removeAll();
  });

  tearDown(() {
    DelightToastBar.removeAll();
    HumoraToast.disableAutoDismissInTests = false;
  });

  testWidgets(
      'HumoraToast.showSuccess renders floating toast card with success text',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () {
                HumoraToast.showSuccess(
                  context,
                  'Profil berhasil diperbarui.',
                  title: 'Profil Tersimpan',
                );
              },
              child: const Text('Show Toast'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Show Toast'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 350));

    expect(find.byType(ToastCard), findsOneWidget);
    expect(find.text('Profil Tersimpan'), findsOneWidget);
    expect(find.text('Profil berhasil diperbarui.'), findsOneWidget);

    DelightToastBar.removeAll();
    await tester.pumpAndSettle();
  });

  testWidgets('HumoraToast.showWatchlist renders Watchlist confirmation',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () {
                HumoraToast.showWatchlist(
                  context,
                  isAdded: true,
                  seriesTitle: 'Sketsa Warkop Modern',
                );
              },
              child: const Text('Add Watchlist'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Add Watchlist'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 350));

    expect(find.byType(ToastCard), findsOneWidget);
    expect(find.text('Daftar Tonton'), findsOneWidget);
    expect(
      find.text('"Sketsa Warkop Modern" berhasil ditambahkan ke Daftar Tonton.'),
      findsOneWidget,
    );

    DelightToastBar.removeAll();
    await tester.pumpAndSettle();
  });

  testWidgets('HumoraToast.showLike renders like confirmation',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () {
                HumoraToast.showLike(
                  context,
                  isLiked: true,
                  targetTitle: 'Tips Wawancara Lucu',
                  isSeries: false,
                );
              },
              child: const Text('Like Video'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Like Video'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 350));

    expect(find.byType(ToastCard), findsOneWidget);
    expect(find.text('Episode Disukai'), findsOneWidget);
    expect(
      find.text('"Tips Wawancara Lucu" disukai! Terima kasih apresiasinya.'),
      findsOneWidget,
    );

    DelightToastBar.removeAll();
    await tester.pumpAndSettle();
  });
}
