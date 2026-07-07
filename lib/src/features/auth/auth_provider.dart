import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../core/api_client.dart';
import '../../core/constants.dart';

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
        'device_name': 'BugSayMIS Mobile App',
      });

      final data = response.data as Map<String, dynamic>;
      final token = data['token'] as String;
      final role = data['role'] as String? ?? 'parent';

      final userMap = {
        ...(data['user'] as Map<String, dynamic>),
        'role': role,
        if (role == 'parent' && data['parent_contact'] != null)
          'parentContactId': (data['parent_contact'] as Map<String, dynamic>)['id'],
        if (role == 'student') 'studentId': data['student_id'],
      };

      final user = AuthUser.fromJson(userMap);

      await _storage.write(key: AppConstants.tokenKey, value: token);
      await _storage.write(
          key: AppConstants.userKey, value: jsonEncode(user.toJson()));

      return user;
    });
  }

  Future<void> logout() async {
    try {
      final client = ref.read(apiClientProvider);
      await client.delete('/logout');
    } catch (_) {}
    await _storage.delete(key: AppConstants.tokenKey);
    await _storage.delete(key: AppConstants.userKey);
    state = const AsyncData(null);
  }
}
