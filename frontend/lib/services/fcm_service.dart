import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'api_service.dart';

/// Registers this device's FCM token with the backend so the patient/caregiver
/// can receive push notifications (e.g. emergency alerts).
class FcmService {
  final Dio _dio;
  bool _refreshHooked = false;

  FcmService(this._dio);

  Future<void> registerToken() async {
    try {
      final messaging = FirebaseMessaging.instance;
      await messaging.requestPermission();

      final token = await messaging.getToken();
      if (token != null) {
        await _postToken(token);
      }

      // Re-register if FCM rotates the token (only hook once).
      if (!_refreshHooked) {
        _refreshHooked = true;
        messaging.onTokenRefresh.listen(_postToken);
      }
    } catch (e) {
      debugPrint('FCM registerToken failed: $e');
    }
  }

  Future<void> _postToken(String token) async {
    try {
      await _dio.post('/patient/fcm-token',
          data: {'token': token, 'platform': 'android'});
    } catch (e) {
      debugPrint('FCM token post failed: $e');
    }
  }
}

final fcmServiceProvider = Provider<FcmService>((ref) {
  return FcmService(ref.watch(apiServiceProvider));
});
