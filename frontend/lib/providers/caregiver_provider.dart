import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/medication_model.dart';
import '../services/api_service.dart';
import '../services/service_interfaces.dart';

class LinkedPatient {
  final String id;
  final String fullName;
  final String? lastCheckinAt;
  final String? profileId;
  final String? linkId;

  const LinkedPatient({
    required this.id,
    required this.fullName,
    this.lastCheckinAt,
    this.profileId,
    this.linkId,
  });

  factory LinkedPatient.fromJson(Map<String, dynamic> json) {
    // Backend returns flat: link_id, patient_profile_id, full_name, phone, date_of_birth, linked_at
    return LinkedPatient(
      id: json['patient_profile_id'] as String? ?? json['id'] as String,
      fullName: json['full_name'] as String? ?? 'Patient',
      lastCheckinAt: json['last_checkin_at'] as String?,
      profileId: json['profile_id'] as String?,
      linkId: json['link_id'] as String?,
    );
  }

  String get initials {
    final parts = fullName.trim().split(' ');
    if (parts.length >= 2) return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    return fullName.isNotEmpty ? fullName[0].toUpperCase() : '?';
  }

  String get lastCheckinDisplay {
    if (lastCheckinAt == null) return 'No check-in';
    try {
      final dt = DateTime.parse(lastCheckinAt!).toLocal();
      final diff = DateTime.now().difference(dt);
      if (diff.inMinutes < 60) return '${diff.inMinutes} min ago';
      if (diff.inHours < 24) return '${diff.inHours} hours ago';
      return '${diff.inDays} days ago';
    } catch (_) {
      return 'No check-in';
    }
  }
}

class CaregiverPatientsNotifier
    extends StateNotifier<AsyncValue<List<LinkedPatient>>> {
  final Dio _dio;

  CaregiverPatientsNotifier(this._dio) : super(const AsyncValue.loading()) {
    fetch();
  }

  Future<void> fetch() async {
    state = const AsyncValue.loading();
    try {
      final response = await _dio.get('/caregiver/patients');
      // Backend returns {"patients": [...], "total": N}
      final body = response.data as Map<String, dynamic>;
      final list = body['patients'] as List<dynamic>? ?? [];
      final patients = list
          .map((p) => LinkedPatient.fromJson(p as Map<String, dynamic>))
          .toList();
      state = AsyncValue.data(patients);
    } on DioException catch (e) {
      state = AsyncValue.error(
        e.response?.data?['detail'] ?? e.message ?? 'Failed to load patients',
        e.stackTrace,
      );
    } catch (e) {
      state = AsyncValue.error(e.toString(), StackTrace.current);
    }
  }

  Future<void> acceptInvite(String code) async {
    await _dio.post('/caregiver/accept', data: {'code': code});
    await fetch();
  }
}

final caregiverPatientsProvider = StateNotifierProvider<
    CaregiverPatientsNotifier, AsyncValue<List<LinkedPatient>>>(
  (ref) => CaregiverPatientsNotifier(ref.watch(apiServiceProvider)),
);

// ── Linked-patient detail providers (caregiver read-only views) ───────────────

String _sleepLabel(int? score) {
  if (score == null) return 'fair';
  if (score >= 5) return 'excellent';
  if (score >= 4) return 'good';
  if (score >= 3) return 'fair';
  return 'poor';
}

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
      DateTime ts;
      try {
        ts = DateTime.parse(m['attempted_at'] as String).toLocal();
      } catch (_) {
        ts = DateTime.now();
      }
      return EmergencyStep(
        description: m['step_type'] as String? ?? '',
        timestamp: ts,
        success: (m['status'] as String?) == 'completed',
      );
    }).toList();
  } catch (_) {
    return [];
  }
}

/// A linked patient's active medications.
final caregiverPatientMedsProvider =
    FutureProvider.family<List<MedicationItem>, String>((ref, patientId) async {
  final dio = ref.watch(apiServiceProvider);
  final res = await dio.get('/caregiver/patients/$patientId/medications');
  final list = res.data as List<dynamic>? ?? [];
  return list
      .map((m) => MedicationItem.fromJson(m as Map<String, dynamic>))
      .toList();
});

/// A linked patient's recent wellness check-ins (most recent first).
final caregiverPatientCheckinsProvider =
    FutureProvider.family<List<WellnessCheckIn>, String>((ref, patientId) async {
  final dio = ref.watch(apiServiceProvider);
  final res = await dio.get('/caregiver/patients/$patientId/wellness-checkins');
  final list = res.data as List<dynamic>? ?? [];
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

/// A linked patient's emergency events (most recent first).
final caregiverPatientEmergenciesProvider =
    FutureProvider.family<List<EmergencyEvent>, String>((ref, patientId) async {
  final dio = ref.watch(apiServiceProvider);
  final res = await dio.get('/caregiver/patients/$patientId/emergency-events');
  final list = res.data as List<dynamic>? ?? [];
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
    return EmergencyEvent(
      id: m['id'] as String,
      type: typeStr == 'fall_detected'
          ? EmergencyEventType.fallDetected
          : EmergencyEventType.manualSOS,
      timestamp: ts,
      outcome: _parseOutcome(outcomeStr),
      steps: _parseSteps(m['emergency_escalation_steps']),
      gpsCoordinates: (lat != null && lng != null) ? '$lat,$lng' : null,
    );
  }).toList();
});
