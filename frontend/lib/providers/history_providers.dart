import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/api_service.dart';
import '../services/service_interfaces.dart';

// ── Wellness check-ins ────────────────────────────────────────────────────────

String _sleepLabel(int? score) {
  if (score == null) return 'fair';
  if (score >= 5) return 'excellent';
  if (score >= 4) return 'good';
  if (score >= 3) return 'fair';
  return 'poor';
}

final wellnessCheckInsProvider =
    FutureProvider<List<WellnessCheckIn>>((ref) async {
  final dio = ref.watch(apiServiceProvider);
  final response = await dio.get('/wellness-checkins/');
  final list = response.data as List<dynamic>? ?? [];
  return list.map((e) {
    final m = e as Map<String, dynamic>;
    DateTime ts;
    try {
      ts = DateTime.parse(m['completed_at'] as String).toLocal();
    } catch (_) {
      ts = DateTime.now();
    }
    return WellnessCheckIn(
      id: m['id'] as String,
      timestamp: ts,
      mood: (m['mood_score'] as num?)?.toInt() ?? 3,
      energy: (m['energy_score'] as num?)?.toInt() ?? 3,
      painLevel: (m['pain_level'] as num?)?.toInt() ?? 0,
      sleepQuality: _sleepLabel((m['sleep_quality'] as num?)?.toInt()),
      allMedsTaken: m['meds_confirmed'] as bool? ?? false,
      isFlagged: (m['ai_flags'] as List?)?.isNotEmpty ?? false,
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
    final typeStr = m['trigger_type'] as String? ?? 'manual_sos';
    final outcomeStr = m['outcome'] as String? ?? 'cancelled';
    DateTime ts;
    try {
      ts = DateTime.parse(m['triggered_at'] as String).toLocal();
    } catch (_) {
      ts = DateTime.now();
    }
    final lat = m['gps_lat'];
    final lng = m['gps_lng'];
    final gps = (lat != null && lng != null) ? '$lat,$lng' : null;
    return EmergencyEvent(
      id: m['id'] as String,
      type: typeStr == 'fall_detected'
          ? EmergencyEventType.fallDetected
          : EmergencyEventType.manualSOS,
      timestamp: ts,
      outcome: _parseOutcome(outcomeStr),
      steps: _parseSteps(m['emergency_escalation_steps']),
      gpsCoordinates: gps,
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
      DateTime stepTs;
      try {
        stepTs = DateTime.parse(m['attempted_at'] as String).toLocal();
      } catch (_) {
        stepTs = DateTime.now();
      }
      return EmergencyStep(
        description: m['step_type'] as String? ?? '',
        timestamp: stepTs,
        success: (m['status'] as String?) == 'completed',
      );
    }).toList();
  } catch (_) {
    return [];
  }
}

// ── Symptom logs ──────────────────────────────────────────────────────────────

SymptomSeverity _severityFrom(String? s) {
  switch (s) {
    case 'flagged':
      return SymptomSeverity.flagged;
    case 'watch':
      return SymptomSeverity.watch;
    default:
      return SymptomSeverity.normal;
  }
}

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
        DateTime ts;
        try {
          ts = DateTime.parse(m['logged_at'] as String).toLocal();
        } catch (_) {
          ts = DateTime.now();
        }
        return SymptomEntry(
          id: m['id'] as String,
          description: m['body'] as String? ?? '',
          timestamp: ts,
          severity: _severityFrom(m['ai_severity'] as String?),
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
    await _dio.post('/symptom-logs/', data: {'body': description, 'input_type': 'text'});
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
  final seen = <String>{};
  return list
      .map((e) => (e as Map<String, dynamic>)['name'] as String? ?? '')
      .where((s) => s.isNotEmpty)
      .where((s) => seen.add(s.toLowerCase()))
      .toList();
});

// ── Emergency contacts ────────────────────────────────────────────────────────

class EmergencyContactData {
  final String id;
  final String name;
  final String phone;
  final String relationship;
  final int priority;

  const EmergencyContactData({
    required this.id,
    required this.name,
    required this.phone,
    required this.relationship,
    required this.priority,
  });

  factory EmergencyContactData.fromJson(Map<String, dynamic> json) {
    return EmergencyContactData(
      id: json['id'] as String? ?? '',
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
