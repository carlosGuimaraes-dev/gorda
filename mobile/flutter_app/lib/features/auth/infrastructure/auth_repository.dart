import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../domain/user_session.dart';

final secureStorageProvider = Provider<FlutterSecureStorage>((ref) {
  return const FlutterSecureStorage();
});

class AuthRepository {
  AuthRepository(this._storage);

  final FlutterSecureStorage _storage;
  static const _tokenKey = 'auth_token';
  static const _nameKey = 'auth_name';
  static const _roleKey = 'auth_role';

  Future<void> saveSession(UserSession session) async {
    await _storage.write(key: _tokenKey, value: session.token);
    await _storage.write(key: _nameKey, value: session.name);
    await _storage.write(key: _roleKey, value: session.role.name);
  }

  Future<UserSession?> getSession() async {
    final token = await _storage.read(key: _tokenKey);
    final name = await _storage.read(key: _nameKey);
    final roleStr = await _storage.read(key: _roleKey);

    if (token != null && name != null && roleStr != null) {
      final role = UserRole.values.firstWhere(
        (e) => e.name == roleStr,
        orElse: () => UserRole.employee, // Default fallback
      );

      return UserSession(
        token: token,
        name: name,
        role: role,
      );
    }
    return null;
  }

  Future<void> clearSession() async {
    await _storage.delete(key: _tokenKey);
    await _storage.delete(key: _nameKey);
    await _storage.delete(key: _roleKey);
  }
}

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  final storage = ref.watch(secureStorageProvider);
  return AuthRepository(storage);
});
