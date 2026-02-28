import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../domain/user_session.dart';
import '../infrastructure/auth_repository.dart';

final authStateProvider = StateNotifierProvider<AuthController, AsyncValue<UserSession?>>((ref) {
  final repository = ref.watch(authRepositoryProvider);
  return AuthController(repository);
});

class AuthController extends StateNotifier<AsyncValue<UserSession?>> {
  AuthController(this._repository) : super(const AsyncValue.loading()) {
    _checkSession();
  }

  final AuthRepository _repository;

  Future<void> _checkSession() async {
    try {
      final session = await _repository.getSession();
      state = AsyncValue.data(session);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> login(String username, String password) async {
    state = const AsyncValue.loading();
    try {
      // Mock login validation for MVP
      await Future.delayed(const Duration(seconds: 1));
      
      final session = UserSession(
        token: 'mock_jwt_token_12345',
        name: username.isNotEmpty ? username : 'User',
        role: UserRole.employee,
      );
      
      await _repository.saveSession(session);
      state = AsyncValue.data(session);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> selectRole(UserRole role) async {
    if (state.value == null) return;
    
    final currentSession = state.value!;
    final newSession = UserSession(
      token: currentSession.token,
      name: currentSession.name,
      role: role,
    );
    
    await _repository.saveSession(newSession);
    state = AsyncValue.data(newSession);
  }

  Future<void> logout() async {
    state = const AsyncValue.loading();
    try {
      await _repository.clearSession();
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}
