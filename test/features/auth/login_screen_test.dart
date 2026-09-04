import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:atlasgo/src/core/api_client.dart';
import 'package:atlasgo/src/features/auth/login_screen.dart';

/// Throws a fixed [DioException] from `post` instead of calling the network,
/// so tests can drive the login screen's error-handling branches directly.
class _ThrowingApiClient extends ApiClient {
  final DioException Function() build;
  _ThrowingApiClient(this.build);

  @override
  Future<Response> post(String path, {dynamic data}) async => throw build();
}

DioException _badResponse(int statusCode, Map<String, dynamic>? data) {
  final options = RequestOptions(path: '/login');
  return DioException(
    requestOptions: options,
    type: DioExceptionType.badResponse,
    response: Response(requestOptions: options, statusCode: statusCode, data: data),
  );
}

DioException _connectionError() => DioException(
      requestOptions: RequestOptions(path: '/login'),
      type: DioExceptionType.connectionError,
    );

Future<void> _fillParentFormAndSubmit(WidgetTester tester) async {
  await tester.tap(find.text("I'm a Parent"));
  await tester.pumpAndSettle();
  await tester.enterText(find.byType(TextFormField).first, 'parent@crc.pshs.edu.ph');
  await tester.enterText(find.byType(TextFormField).last, 'somepassword');
  await tester.tap(find.text('Sign In'));
  await tester.pumpAndSettle();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const secureStorageChannel = MethodChannel('plugins.it_nomads.com/flutter_secure_storage');
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(secureStorageChannel, (call) async => null);

  // No real Google account exists in a widget test — make the plugin's
  // signIn call fail immediately instead of hanging forever waiting for a
  // native response, so _googleSignIn's catch block runs deterministically.
  const googleSignInChannel = MethodChannel('plugins.flutter.io/google_sign_in');
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(googleSignInChannel, (call) async {
    if (call.method == 'init') return null;
    if (call.method == 'signOut') return <String, dynamic>{};
    if (call.method == 'signIn') {
      throw PlatformException(code: 'sign_in_failed', message: 'no test account');
    }
    return null;
  });

  testWidgets('opens on the role chooser with no form fields visible', (tester) async {
    await tester.pumpWidget(
      const ProviderScope(child: MaterialApp(home: LoginScreen())),
    );
    await tester.pumpAndSettle();

    expect(find.text("I'm a Scholar"), findsOneWidget);
    expect(find.text("I'm a Parent"), findsOneWidget);
    expect(find.byType(TextFormField), findsNothing);
  });

  testWidgets('tapping "I\'m a Parent" reveals the email/password form', (tester) async {
    await tester.pumpWidget(
      const ProviderScope(child: MaterialApp(home: LoginScreen())),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text("I'm a Parent"));
    await tester.pumpAndSettle();

    expect(find.byType(TextFormField), findsNWidgets(2));
    expect(find.text("I'm a Scholar"), findsNothing);
  });

  testWidgets('the back arrow from the parent form returns to the chooser', (tester) async {
    await tester.pumpWidget(
      const ProviderScope(child: MaterialApp(home: LoginScreen())),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text("I'm a Parent"));
    await tester.pumpAndSettle();
    expect(find.byType(TextFormField), findsNWidgets(2));

    await tester.tap(find.byIcon(Icons.arrow_back_ios_new_rounded));
    await tester.pumpAndSettle();

    expect(find.text("I'm a Scholar"), findsOneWidget);
    expect(find.byType(TextFormField), findsNothing);
  });

  testWidgets('tapping "I\'m a Scholar" invokes the Google sign-in path', (tester) async {
    await tester.pumpWidget(
      const ProviderScope(child: MaterialApp(home: LoginScreen())),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text("I'm a Scholar"));
    // The tapped card shows an indeterminate CircularProgressIndicator
    // while busy, which schedules frames forever — pumpAndSettle would
    // hang on it, so pump bounded steps instead.
    for (var i = 0; i < 5; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }

    // No real Google Sign-In platform channel exists in a widget test, so
    // the call throws and _googleSignIn's own catch block surfaces a
    // SnackBar — that SnackBar appearing is proof the Google path was
    // actually invoked (not just that the button exists).
    expect(find.byType(SnackBar), findsOneWidget);
  });

  testWidgets('shows the server message for a 403 (e.g. inactive account)', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          apiClientProvider.overrideWithValue(_ThrowingApiClient(
            () => _badResponse(403, {'message': 'Account is inactive.'}),
          )),
        ],
        child: const MaterialApp(home: LoginScreen()),
      ),
    );
    await tester.pumpAndSettle();
    await _fillParentFormAndSubmit(tester);

    expect(find.text('Account is inactive.'), findsOneWidget);
    expect(find.text('Login failed. Check your connection and try again.'), findsNothing);
  });

  testWidgets('redirects to /verify-email for a 403 requiring verification', (tester) async {
    final router = GoRouter(routes: [
      GoRoute(path: '/', builder: (c, s) => const LoginScreen()),
      GoRoute(path: '/verify-email', builder: (c, s) => const Scaffold(body: Text('Verify Page'))),
    ]);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          apiClientProvider.overrideWithValue(_ThrowingApiClient(
            () => _badResponse(403, {
              'message': 'Please verify your email before signing in.',
              'requires_verification': true,
            }),
          )),
        ],
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await tester.pumpAndSettle();
    await _fillParentFormAndSubmit(tester);

    expect(find.text('Verify Page'), findsOneWidget);
  });

  testWidgets('shows "Incorrect email or password." for a 401', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          apiClientProvider.overrideWithValue(_ThrowingApiClient(
            () => _badResponse(401, {'message': 'Unauthenticated.'}),
          )),
        ],
        child: const MaterialApp(home: LoginScreen()),
      ),
    );
    await tester.pumpAndSettle();
    await _fillParentFormAndSubmit(tester);

    expect(find.text('Incorrect email or password.'), findsOneWidget);
  });

  testWidgets('shows the connection message for a real network failure', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          apiClientProvider.overrideWithValue(_ThrowingApiClient(() => _connectionError())),
        ],
        child: const MaterialApp(home: LoginScreen()),
      ),
    );
    await tester.pumpAndSettle();
    await _fillParentFormAndSubmit(tester);

    expect(find.text('Login failed. Check your connection and try again.'), findsOneWidget);
  });
}
