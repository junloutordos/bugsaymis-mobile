import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:atlasgo/src/features/auth/login_screen.dart';

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
}
