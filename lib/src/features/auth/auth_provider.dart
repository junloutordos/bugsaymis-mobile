import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../../core/api_client.dart';
import '../../core/constants.dart';

/// Outcome of a Google sign-in attempt.
sealed class GoogleLoginResult {
  const GoogleLoginResult();
}

class GoogleLoginSuccess extends GoogleLoginResult {
  const GoogleLoginSuccess();
}

class GoogleLoginCancelled extends GoogleLoginResult {
  const GoogleLoginCancelled();
}

/// First sign-in: account is valid but not yet linked to a student record.
class GoogleLoginNeedsLink extends GoogleLoginResult {
  final String idToken;
  final String email;
  const GoogleLoginNeedsLink({required this.idToken, required this.email});
}

// ── Models ────────────────────────────────────────────────────────────────────

class AuthUser {
  final int id;
  final String name;
  final String email;
  final String role; // 'parent' | 'student'
  final int? parentContactId;
  final int? studentId;

  const AuthUser({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    this.parentContactId,
    this.studentId,
  });

  bool get isStudent => role == 'student';
  bool get isParent  => role == 'parent';

  factory AuthUser.fromJson(Map<String, dynamic> json) {
    final role = json['role'] as String? ?? 'parent';
    return AuthUser(
      id: json['id'] as int,
      name: json['name'] as String,
      email: json['email'] as String,
      role: role,
      parentContactId: role == 'parent'
          ? json['parentContactId'] as int?
          : null,
      studentId: role == 'student'
          ? json['studentId'] as int?
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'email': email,
        'role': role,
        if (parentContactId != null) 'parentContactId': parentContactId,
        if (studentId != null) 'studentId': studentId,
      };
}

// ── Provider ──────────────────────────────────────────────────────────────────

final authStateProvider =
    AsyncNotifierProvider<AuthNotifier, AuthUser?>(() => AuthNotifier());

class AuthNotifier extends AsyncNotifier<AuthUser?> {
  final _storage = const FlutterSecureStorage();

  @override
  Future<AuthUser?> build() async {
    final userJson = await _storage.read(key: AppConstants.userKey);
    if (userJson == null) return null;
    final map = jsonDecode(userJson) as Map<String, dynamic>;
    return AuthUser.fromJson(map);
  }

  Future<void> login(String email, String password) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final client = ref.read(apiClientProvider);
      final response = await client.post('/login', data: {
        'email': email,
        'password': password,
        'device_name': 'AtlasGo Mobile App',
      });

      await _storeSession(response.data as Map<String, dynamic>);
      return state.value;
    });
  }

  /// Student sign-in with the official school Google account.
  /// Mirrors /student-portal: domain-restricted picker, server-side
  /// verification, shared student_google_links.
  Future<GoogleLoginResult> loginWithGoogle() async {
    final google = GoogleSignIn(
      hostedDomain: AppConstants.googleHostedDomain,
      serverClientId: AppConstants.googleServerClientId,
      scopes: const ['email'],
    );

    // Drop any cached account so the picker always shows.
    try {
      await google.signOut();
    } catch (_) {}

    final account = await google.signIn();
    if (account == null) return const GoogleLoginCancelled();

    final idToken = (await account.authentication).idToken;
    if (idToken == null) {
      throw Exception('Google did not return an ID token.');
    }

    final response =
        await ref.read(apiClientProvider).post('/student/google-login', data: {
      'id_token': idToken,
      'device_name': 'AtlasGo Mobile App',
    });

    final data = response.data as Map<String, dynamic>;

    if (data['needs_link'] == true) {
      return GoogleLoginNeedsLink(
        idToken: idToken,
        email: data['email'] as String? ?? account.email,
      );
    }

    await _storeSession(data);
    return const GoogleLoginSuccess();
  }

  /// First-time PISAY ID linking after Google sign-in.
  Future<void> linkStudentAccount(String idToken, String pisayId) async {
    final response =
        await ref.read(apiClientProvider).post('/student/google-link', data: {
      'id_token': idToken,
      'pisaysystemID': pisayId,
      'device_name': 'AtlasGo Mobile App',
    });

    await _storeSession(response.data as Map<String, dynamic>);
  }

  /// Persist a login response (token + user) and update auth state.
  Future<void> _storeSession(Map<String, dynamic> data) async {
    final role = data['role'] as String? ?? 'parent';
    final userMap = {
      ...(data['user'] as Map<String, dynamic>),
      'role': role,
      if (role == 'parent' && data['parent_contact'] != null)
        'parentContactId': (data['parent_contact'] as Map<String, dynamic>)['id'],
      if (role == 'student') 'studentId': data['student_id'],
    };
    final user = AuthUser.fromJson(userMap);

    await _storage.write(key: AppConstants.tokenKey, value: data['token'] as String);
    await _storage.write(key: AppConstants.userKey, value: jsonEncode(user.toJson()));
    state = AsyncData(user);
  }

  Future<void> logout() async {
    try {
      final client = ref.read(apiClientProvider);
      await client.delete('/logout');
    } catch (_) {}
    await forceLogout();
  }

  /// Clear the local session without calling the API — used when the
  /// server rejects our token (401) so every screen falls back to /login.
  Future<void> forceLogout() async {
    await _storage.delete(key: AppConstants.tokenKey);
    await _storage.delete(key: AppConstants.userKey);
    state = const AsyncData(null);
  }
}
