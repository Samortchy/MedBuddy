// lib/providers/fall_provider.dart

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/api_service.dart';

enum FallPhase { idle, detected, cancelled, confirmed }

/// Holds the current fall/emergency phase plus the backend emergency event and
/// Agora channel details returned by POST /emergency/trigger.
class FallSession {
  final FallPhase phase;
  final String? eventId;
  final String? agoraChannel;
  final String? agoraToken;
  final String? agoraAppId;
  final String? error;

  const FallSession({
    this.phase = FallPhase.idle,
    this.eventId,
    this.agoraChannel,
    this.agoraToken,
    this.agoraAppId,
    this.error,
  });

  bool get hasAgora =>
      agoraChannel != null && agoraToken != null && agoraAppId != null;

  FallSession copyWith({
    FallPhase? phase,
    String? eventId,
    String? agoraChannel,
    String? agoraToken,
    String? agoraAppId,
    String? error,
  }) =>
      FallSession(
        phase: phase ?? this.phase,
        eventId: eventId ?? this.eventId,
        agoraChannel: agoraChannel ?? this.agoraChannel,
        agoraToken: agoraToken ?? this.agoraToken,
        agoraAppId: agoraAppId ?? this.agoraAppId,
        error: error,
      );
}

class FallNotifier extends StateNotifier<FallSession> {
  final Dio _dio;

  FallNotifier(this._dio) : super(const FallSession());

  void onFallDetected() => state = state.copyWith(phase: FallPhase.detected);
  void cancel() => state = state.copyWith(phase: FallPhase.cancelled);
  void confirm() => state = state.copyWith(phase: FallPhase.confirmed);
  void reset() => state = const FallSession();

  /// Logs an emergency event and stores the Agora channel/token for the call.
  Future<void> triggerEmergency({
    String eventType = 'fall_detected',
    double? gpsLat,
    double? gpsLng,
  }) async {
    // Avoid creating a second event if one is already active.
    if (state.eventId != null) return;
    try {
      final res = await _dio.post('/emergency/trigger', data: {
        'event_type': eventType,
        if (gpsLat != null) 'gps_lat': gpsLat,
        if (gpsLng != null) 'gps_lng': gpsLng,
      });
      final d = res.data as Map<String, dynamic>;
      state = state.copyWith(
        phase: FallPhase.confirmed,
        eventId: d['event_id'] as String?,
        agoraChannel: d['agora_channel'] as String?,
        agoraToken: d['agora_token'] as String?,
        agoraAppId: d['agora_app_id'] as String?,
      );
    } on DioException catch (e) {
      state = state.copyWith(
        error: e.response?.data?['detail']?.toString() ??
            e.message ??
            'Failed to trigger emergency',
      );
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  /// Records a liveness verification step. Returns the backend status
  /// ("resolved" | "escalate" | "retry" | "error" | "no_event").
  Future<String> verifyLiveness(bool verified, String factor) async {
    final eventId = state.eventId;
    if (eventId == null) return 'no_event';
    try {
      final res = await _dio.post('/emergency/verify', data: {
        'event_id': eventId,
        'verified': verified,
        'factor': factor,
      });
      return (res.data as Map<String, dynamic>)['status'] as String? ??
          'unknown';
    } on DioException catch (_) {
      return 'error';
    } catch (_) {
      return 'error';
    }
  }
}

final fallProvider = StateNotifierProvider<FallNotifier, FallSession>((ref) {
  return FallNotifier(ref.watch(apiServiceProvider));
});
