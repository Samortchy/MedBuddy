import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// ── Auth state model ─────────────────────────────────────────────────────────

class AuthUser {
  final String userId;
  final String email;
  final String role;

  const AuthUser({
    required this.userId,
    required this.email,
    required this.role,
  });
}

// ── Notifier ──────────────────────────────────────────────────────────────────

class AuthNotifier extends StateNotifier<AsyncValue<AuthUser?>> {
  AuthNotifier() : super(const AsyncValue.loading()) {
    _init();
  }

  SupabaseClient get _client => Supabase.instance.client;

  void _init() {
    final session = _client.auth.currentSession;
    if (session != null) {
      state = AsyncValue.data(_userFromSession(session));
    } else {
      state = const AsyncValue.data(null);
    }
  }

  Future<void> signIn(String email, String password) async {
    state = const AsyncValue.loading();
    try {
      final response = await _client.auth.signInWithPassword(
        email: email,
        password: password,
      );
      final session = response.session;
      if (session == null) throw Exception('Sign in failed — no session.');
      state = AsyncValue.data(_userFromSession(session));
    } on AuthException catch (e) {
      state = AsyncValue.error(e.message, StackTrace.current);
    } catch (e) {
      state = AsyncValue.error(e.toString(), StackTrace.current);
    }
  }

  Future<void> signUp(String email, String password, String role) async {
    state = const AsyncValue.loading();
    try {
      final response = await _client.auth.signUp(
        email: email,
        password: password,
        data: {'role': role},
      );
      final session = response.session;
      // After signUp Supabase may require email confirmation; session can be null.
      if (session != null) {
        state = AsyncValue.data(_userFromSession(session));
      } else {
        // Email confirmation pending — treat as unauthenticated with a special
        // marker so the UI can show the "check your email" message.
        state = AsyncValue.error(
          'check_email',
          StackTrace.current,
        );
      }
    } on AuthException catch (e) {
      state = AsyncValue.error(e.message, StackTrace.current);
    } catch (e) {
      state = AsyncValue.error(e.toString(), StackTrace.current);
    }
  }

  Future<void> signOut() async {
    await _client.auth.signOut();
    state = const AsyncValue.data(null);
  }

  // ── Helpers ────────────────────────────────────────────────────────────────

  AuthUser _userFromSession(Session session) {
    final meta = session.user.userMetadata ?? {};
    final role = (meta['role'] as String?) ?? 'patient';
    debugPrint('[AUTH] role=$role token=${session.accessToken}');
    return AuthUser(
      userId: session.user.id,
      email: session.user.email ?? '',
      role: role,
    );
  }
}

// ── Providers ─────────────────────────────────────────────────────────────────

final authProvider =
    StateNotifierProvider<AuthNotifier, AsyncValue<AuthUser?>>(
  (ref) => AuthNotifier(),
);

/// Convenience — resolves to the AuthUser when authenticated, null otherwise.
final currentUserProvider = Provider<AuthUser?>((ref) {
  return ref.watch(authProvider).valueOrNull;
});
