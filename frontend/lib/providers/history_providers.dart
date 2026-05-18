import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/api_service.dart';
import '../services/service_interfaces.dart';

// ── Wellness check-ins ────────────────────────────────────────────────────────

final wellnessCheckInsProvider =
    FutureProvider<List<WellnessCheckIn>>((ref) async {
  final dio = ref.watch(apiServiceProvider);
  final response = await dio.get('/wellness-checkins/');
  final list = response.data as List<dynamic>? ?? [];
  return list.map((e) {
    final m = e as Map<String, dynamic>;
    return WellnessCheckIn(
      id: m['id'] as String,
      timestamp: DateTime.parse(m['created_at'] as String).toLocal(),
      mood: (m['mood'] as num?)?.toInt() ?? 3,
      energy: (m['energy'] as num?)?.toInt() ?? 3,
      painLevel: (m['pain_level'] as num?)?.toInt() ?? 0,
      sleepQuality: m['sleep_quality'] as String? ?? 'fair',
      allMedsTaken: m['all_meds_taken'] as bool? ?? false,
      isFlagged: m['is_flagged'] as bool? ?? false,
    );
  }).toList();
});

// ── Emergency events ──────────────────────────────────────────────────────────

final emergencyEventsProvider =
    FutureProvider<List<EmergencyEvent>>((ref) async {
  final dio = ref.watch(apiServiceProvider);
  final response = await dio.get('/emergency-events/');
  final list = response.data as List<dynamic>? ?? [];
  return list.map((e) {
    final m = e as Map<String, dynamic>;
    final typeStr = m['event_type'] as String? ?? 'manual_sos';
    final outcomeStr = m['outcome'] as String? ?? 'cancelled';
    return EmergencyEvent(
      id: m['id'] as String,
      type: typeStr == 'fall_detected'
          ? EmergencyEventType.fallDetected
          : EmergencyEventType.manualSOS,
      timestamp: DateTime.parse(m['created_at'] as String).toLocal(),
      outcome: _parseOutcome(outcomeStr),
      steps: _parseSteps(m['steps']),
      gpsCoordinates: m['gps_coordinates'] as String?,
    );
  }).toList();
});

EmergencyOutcome _parseOutcome(String s) {
  switch (s) {
    case 'handled_by_caregiver':
      return EmergencyOutcome.handledByCaregiver;
    case 'false_alarm':
      return EmergencyOutcome.falseAlarm;
    case 'activated_911':
      return EmergencyOutcome.activated911;
    default:
      return EmergencyOutcome.cancelled;
  }
}

List<EmergencyStep> _parseSteps(dynamic raw) {
  if (raw == null) return [];
  try {
    return (raw as List<dynamic>).map((s) {
      final m = s as Map<String, dynamic>;
      return EmergencyStep(
        description: m['description'] as String? ?? '',
        timestamp:
            DateTime.parse(m['timestamp'] as String).toLocal(),
        success: m['success'] as bool? ?? true,
      );
    }).toList();
  } catch (_) {
    return [];
  }
}

// ── Symptom logs ──────────────────────────────────────────────────────────────

class SymptomLogNotifier extends StateNotifier<AsyncValue<List<SymptomEntry>>> {
  final Dio _dio;

  SymptomLogNotifier(this._dio) : super(const AsyncValue.loading()) {
    fetch();
  }

  Future<void> fetch() async {
    state = const AsyncValue.loading();
    try {
      final response = await _dio.get('/symptom-logs/');
      final list = response.data as List<dynamic>? ?? [];
      final entries = list.map((e) {
        final m = e as Map<String, dynamic>;
        final sevStr = m['severity'] as String? ?? 'normal';
        return SymptomEntry(
          id: m['id'] as String,
          description: m['description'] as String? ?? '',
          timestamp: DateTime.parse(m['created_at'] as String).toLocal(),
          severity: sevStr == 'flagged'
              ? SymptomSeverity.flagged
              : sevStr == 'watch'
                  ? SymptomSeverity.watch
                  : SymptomSeverity.normal,
        );
      }).toList();
      state = AsyncValue.data(entries);
    } on DioException catch (e) {
      state = AsyncValue.error(
        e.response?.data?['detail'] ?? e.message ?? 'Failed to load',
        e.stackTrace,
      );
    } catch (e) {
      state = AsyncValue.error(e.toString(), StackTrace.current);
    }
  }

  Future<void> add(String description) async {
    await _dio.post('/symptom-logs/', data: {'description': description});
    await fetch();
  }
}

final symptomLogProvider =
    StateNotifierProvider<SymptomLogNotifier, AsyncValue<List<SymptomEntry>>>(
  (ref) => SymptomLogNotifier(ref.watch(apiServiceProvider)),
);

// ── Health conditions ─────────────────────────────────────────────────────────

final healthConditionsProvider = FutureProvider<List<String>>((ref) async {
  final dio = ref.watch(apiServiceProvider);
  final response = await dio.get('/health-conditions/');
  final list = response.data as List<dynamic>? ?? [];
  return list
      .map((e) => (e as Map<String, dynamic>)['name'] as String? ?? '')
      .where((s) => s.isNotEmpty)
      .toList();
});

// ── Emergency contacts ────────────────────────────────────────────────────────

class EmergencyContactData {
  final String name;
  final String phone;
  final String relationship;
  final int priority;

  const EmergencyContactData({
    required this.name,
    required this.phone,
    required this.relationship,
    required this.priority,
  });

  factory EmergencyContactData.fromJson(Map<String, dynamic> json) {
    return EmergencyContactData(
      name: json['name'] as String? ?? '',
      phone: json['phone'] as String? ?? '',
      relationship: json['relationship'] as String? ?? '',
      priority: (json['priority'] as num?)?.toInt() ?? 1,
    );
  }
}

final emergencyContactsProvider =
    FutureProvider<List<EmergencyContactData>>((ref) async {
  final dio = ref.watch(apiServiceProvider);
  final response = await dio.get('/emergency-contacts/');
  final list = response.data as List<dynamic>? ?? [];
  return list
      .map((e) =>
          EmergencyContactData.fromJson(e as Map<String, dynamic>))
      .toList();
});
