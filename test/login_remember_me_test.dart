import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:humora_mobile/screens/auth/login_screen.dart';
import 'package:humora_mobile/providers/auth_provider.dart';
import 'package:humora_mobile/data/models/user_model.dart';

class MockAuthProviderForLogin extends AuthProvider {
  bool mockLoginSuccess = true;
  String? lastIdentifier;

  @override
  Future<bool> login({
    required String identifier,
    required String password,
  }) async {
    lastIdentifier = identifier;
    if (mockLoginSuccess) {
      switchTier(UserTier.free);
      return true;
    }
    return false;
  }

  @override
  Future<void> logout() async {
    switchTier(UserTier.guest);
  }
}

void main() {
  setUpAll(() {
    TestWidgetsFlutterBinding.ensureInitialized();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('plugins.it_nomads.com/flutter_secure_storage'),
      (MethodCall methodCall) async {
        return null;
      },
    );
  });

  group('LoginScreen Remember Me & Last Used Email Tests', () {
    testWidgets('LoginScreen loads and pre-fills last used email from SharedPreferences when rememberMe is true', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      SharedPreferences.setMockInitialValues({
        LoginScreen.keyRememberMe: true,
        LoginScreen.keyRememberedEmail: 'user_terakhir@humora.id',
        LoginScreen.keyRememberedTab: 0,
      });

      final mockAuth = MockAuthProviderForLogin();

      await tester.pumpWidget(
        MaterialApp(
          home: ChangeNotifierProvider<AuthProvider>.value(
            value: mockAuth,
            child: const LoginScreen(),
          ),
        ),
      );

      // Let async SharedPreferences initialization finish
      await tester.pumpAndSettle();

      final emailFinder = find.byKey(const Key('email_input_field'));
      expect(emailFinder, findsOneWidget);

      final TextField emailField = tester.widget<TextField>(emailFinder);
      expect(emailField.controller?.text, equals('user_terakhir@humora.id'));

      // Checkbox is checked
      expect(find.byKey(const Key('remember_me_checkbox')), findsOneWidget);
      expect(find.text('Ingat saya di perangkat ini'), findsOneWidget);
    });

    testWidgets('Tapping remember me checkbox toggles state and unchecking clears saved email on login', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      SharedPreferences.setMockInitialValues({
        LoginScreen.keyRememberMe: true,
        LoginScreen.keyRememberedEmail: 'user_lama@humora.id',
        LoginScreen.keyRememberedTab: 0,
      });

      final mockAuth = MockAuthProviderForLogin();

      await tester.pumpWidget(
        MaterialApp(
          home: ChangeNotifierProvider<AuthProvider>.value(
            value: mockAuth,
            child: const LoginScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Verify initial state prefilled
      final emailFinder = find.byKey(const Key('email_input_field'));
      final TextField emailField = tester.widget<TextField>(emailFinder);
      expect(emailField.controller?.text, equals('user_lama@humora.id'));

      // Tap Remember Me checkbox to uncheck it
      final checkboxFinder = find.byKey(const Key('remember_me_checkbox'));
      await tester.ensureVisible(checkboxFinder);
      await tester.tap(checkboxFinder);
      await tester.pumpAndSettle();

      // Enter password
      final passwordFinder = find.byKey(const Key('password_input_field'));
      await tester.ensureVisible(passwordFinder);
      await tester.enterText(passwordFinder, 'password123');
      await tester.pumpAndSettle();

      // Tap submit login
      final submitFinder = find.byKey(const Key('login_submit_button'));
      await tester.ensureVisible(submitFinder);
      await tester.tap(submitFinder);
      await tester.pumpAndSettle();

      // Verify SharedPreferences has rememberMe = false and email is removed
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getBool(LoginScreen.keyRememberMe), isFalse);
      expect(prefs.getString(LoginScreen.keyRememberedEmail), isNull);
    });

    testWidgets('Successful login with remember me true persists the email in SharedPreferences', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      SharedPreferences.setMockInitialValues({}); // Empty initially

      final mockAuth = MockAuthProviderForLogin();

      await tester.pumpWidget(
        MaterialApp(
          home: ChangeNotifierProvider<AuthProvider>.value(
            value: mockAuth,
            child: const LoginScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Enter email and password
      final emailFinder = find.byKey(const Key('email_input_field'));
      await tester.ensureVisible(emailFinder);
      await tester.enterText(emailFinder, 'pengguna_baru@humora.id');

      final passwordFinder = find.byKey(const Key('password_input_field'));
      await tester.ensureVisible(passwordFinder);
      await tester.enterText(passwordFinder, 'password123');
      await tester.pumpAndSettle();

      // Tap submit
      final submitFinder = find.byKey(const Key('login_submit_button'));
      await tester.ensureVisible(submitFinder);
      await tester.tap(submitFinder);
      await tester.pumpAndSettle();

      // Verify SharedPreferences has saved email and remember flag true
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getBool(LoginScreen.keyRememberMe), isTrue);
      expect(prefs.getString(LoginScreen.keyRememberedEmail), equals('pengguna_baru@humora.id'));
    });

    testWidgets('After logout, opening LoginScreen still pre-fills the remembered last used email', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      SharedPreferences.setMockInitialValues({
        LoginScreen.keyRememberMe: true,
        LoginScreen.keyRememberedEmail: 'email_terakhir_setelah_logout@humora.id',
      });

      final mockAuth = MockAuthProviderForLogin();
      mockAuth.switchTier(UserTier.free);
      expect(mockAuth.isGuest, isFalse);

      // Perform logout
      await mockAuth.logout();
      expect(mockAuth.isGuest, isTrue);

      // Open LoginScreen again
      await tester.pumpWidget(
        MaterialApp(
          home: ChangeNotifierProvider<AuthProvider>.value(
            value: mockAuth,
            child: const LoginScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Verify email input has the remembered email from before logout
      final emailFinder = find.byKey(const Key('email_input_field'));
      final TextField emailField = tester.widget<TextField>(emailFinder);
      expect(emailField.controller?.text, equals('email_terakhir_setelah_logout@humora.id'));
    });

    testWidgets('Explicit initialEmail parameter takes precedence over SharedPreferences email', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      SharedPreferences.setMockInitialValues({
        LoginScreen.keyRememberMe: true,
        LoginScreen.keyRememberedEmail: 'stored_in_prefs@humora.id',
      });

      final mockAuth = MockAuthProviderForLogin();

      await tester.pumpWidget(
        MaterialApp(
          home: ChangeNotifierProvider<AuthProvider>.value(
            value: mockAuth,
            child: const LoginScreen(initialEmail: 'explicit_override@humora.id'),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final emailFinder = find.byKey(const Key('email_input_field'));
      final TextField emailField = tester.widget<TextField>(emailFinder);
      expect(emailField.controller?.text, equals('explicit_override@humora.id'));
    });
  });
}
