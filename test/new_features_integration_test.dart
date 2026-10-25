import 'package:flutter/material.dart';
import 'package:flutter_keyboard_visibility/flutter_keyboard_visibility.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_timer_countdown/flutter_timer_countdown.dart';
import 'package:humora_mobile/core/services/download_service.dart';
import 'package:like_button/like_button.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('New Pub.dev Libraries and Features Integration Tests', () {
    test('DownloadService generates correct taskId and filename', () {
      final downloadService = DownloadService();
      downloadService.initialize();

      expect(DownloadService.getTaskId('123'), 'episode_download_123');
      expect(DownloadService.getFileName('123'), 'humora_ep_123.mp4');
      expect(downloadService.isDownloading('123'), isFalse);
      expect(downloadService.getProgress('123'), 0.0);
    });

    testWidgets('ScreenUtilInit and KeyboardDismissOnTap render and scale correctly', (WidgetTester tester) async {
      await tester.pumpWidget(
        ScreenUtilInit(
          designSize: const Size(375, 812),
          minTextAdapt: true,
          splitScreenMode: true,
          builder: (context, child) {
            return const KeyboardDismissOnTap(
              child: MaterialApp(
                home: Scaffold(
                  body: Center(
                    child: Text('ScreenUtil Test'),
                  ),
                ),
              ),
            );
          },
        ),
      );

      await tester.pumpAndSettle();
      expect(find.text('ScreenUtil Test'), findsOneWidget);
      expect(find.byType(KeyboardDismissOnTap), findsOneWidget);
    });

    testWidgets('LikeButton renders and handles tap interaction', (WidgetTester tester) async {
      bool tapped = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: LikeButton(
                size: 24,
                isLiked: false,
                likeCount: 42,
                onTap: (bool isLiked) async {
                  tapped = true;
                  return !isLiked;
                },
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();
      expect(find.byType(LikeButton), findsOneWidget);

      await tester.tap(find.byType(LikeButton));
      await tester.pump();
      expect(tapped, isTrue);
    });

    testWidgets('TimerCountdown renders auto-play countdown correctly', (WidgetTester tester) async {
      bool ended = false;
      final targetTime = DateTime.now().add(const Duration(seconds: 5));

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: TimerCountdown(
                format: CountDownTimerFormat.secondsOnly,
                endTime: targetTime,
                onEnd: () {
                  ended = true;
                },
              ),
            ),
          ),
        ),
      );

      await tester.pump();
      expect(find.byType(TimerCountdown), findsOneWidget);
      expect(ended, isFalse);
    });

    testWidgets('TimerCountdown renders modern seconds-only format without descriptions', (WidgetTester tester) async {
      bool ended = false;
      final targetTime = DateTime.now().add(const Duration(seconds: 5));

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: TimerCountdown(
                format: CountDownTimerFormat.secondsOnly,
                enableDescriptions: false,
                endTime: targetTime,
                timeTextStyle: const TextStyle(fontSize: 11),
                onEnd: () {
                  ended = true;
                },
              ),
            ),
          ),
        ),
      );

      await tester.pump();
      expect(find.byType(TimerCountdown), findsOneWidget);
      expect(find.text('Seconds'), findsNothing);
      expect(ended, isFalse);
    });
  });
}
