import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/api_service.dart';

class LinkedPatient {
  final String id;
  final String fullName;
  final String? lastCheckinAt;
  final String? profileId;

  const LinkedPatient({
    required this.id,
    required this.fullName,
    this.lastCheckinAt,
    this.profileId,
  });

  factory LinkedPatient.fromJson(Map<String, dynamic> json) {
    // Backend returns patient_profiles joined with profiles
    final profile = json['profiles'] as Map<String, dynamic>? ?? {};
    return LinkedPatient(
      id: json['id'] as String,
      fullName: profile['full_name'] as String? ??
          json['full_name'] as String? ??
          'Patient',
      lastCheckinAt: json['last_checkin_at'] as String?,
      profileId: json['profile_id'] as String?,
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
      final list = response.data as List<dynamic>? ?? [];
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
