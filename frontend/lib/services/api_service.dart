import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// Backend base URL.
//  - Android emulator (default): 10.0.2.2 routes to the host PC's localhost.
//  - Real USB device with `adb reverse tcp:8000 tcp:8000`: pass
//      --dart-define=API_BASE=http://127.0.0.1:8000/api/v1
//  - LAN/other: pass the backend machine's IP, e.g. http://192.168.1.50:8000/api/v1
const _baseUrl = String.fromEnvironment(
  'API_BASE',
  defaultValue: 'http://10.0.2.2:8000/api/v1',
);

Dio _buildDio() {
  final dio = Dio(
    BaseOptions(
      baseUrl: _baseUrl,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 20),
      headers: {'Content-Type': 'application/json'},
    ),
  );

  dio.interceptors.add(
    InterceptorsWrapper(
      onRequest: (options, handler) {
        final session = Supabase.instance.client.auth.currentSession;
        final token = session?.accessToken;

        // ── DEBUG ──────────────────────────────────────────
        print('=== API REQUEST DEBUG ===');
        print('URL: ${options.path}');
        print('Session null: ${session == null}');
        print('Token type: ${token?.runtimeType}');
        print(
          'Token first 30 chars: ${token?.substring(0, token.length > 30 ? 30 : token.length)}',
        );
        // ── END DEBUG ──────────────────────────────────────

        if (token != null) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        handler.next(options);
      },
      onError: (err, handler) {
        if (err.response?.statusCode == 401) {
          Supabase.instance.client.auth.signOut();
        }
        handler.next(err);
      },
    ),
  );

  return dio;
}

final apiServiceProvider = Provider<Dio>((ref) => _buildDio());
