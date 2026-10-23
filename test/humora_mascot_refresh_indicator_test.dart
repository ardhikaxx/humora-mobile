import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:humora_mobile/core/services/vibration_service.dart';
import 'package:humora_mobile/widgets/humora_mascot_refresh_indicator.dart';

void main() {
  setUpAll(() {
    VibrationService.disableInTests = true;
  });

  testWidgets(
      'HumoraMascotRefreshIndicator renders child and triggers refresh callback on drag',
      (WidgetTester tester) async {
    bool refreshCalled = false;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: HumoraMascotRefreshIndicator(
            onRefresh: () async {
              refreshCalled = true;
            },
            child: ListView.builder(
              physics: const AlwaysScrollableScrollPhysics(),
              itemCount: 20,
              itemBuilder: (context, index) => ListTile(
                title: Text('Item $index'),
              ),
            ),
          ),
        ),
      ),
    );

    // Initial state: child rendered and refresh not called
    expect(find.text('Item 0'), findsOneWidget);
    expect(refreshCalled, isFalse);

    // Pull down to trigger refresh
    await tester.drag(find.text('Item 0'), const Offset(0, 300));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
    await tester.pump(const Duration(milliseconds: 350));
    await tester.pump(const Duration(milliseconds: 250));
    await tester.pumpAndSettle();

    expect(refreshCalled, isTrue);
  });
}
