import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/medication_model.dart';
import '../services/api_service.dart';

class MedicationState {
  final List<DoseEntry> todayDoses;
  final List<MedicationItem> medications;
  final bool isLoading;
  final String? error;

  const MedicationState({
    this.todayDoses = const [],
    this.medications = const [],
    this.isLoading = false,
    this.error,
  });

  MedicationState copyWith({
    List<DoseEntry>? todayDoses,
    List<MedicationItem>? medications,
    bool? isLoading,
    String? error,
  }) =>
      MedicationState(
        todayDoses: todayDoses ?? this.todayDoses,
        medications: medications ?? this.medications,
        isLoading: isLoading ?? this.isLoading,
        error: error,
      );

  int get takenCount =>
      todayDoses.where((d) => d.status == 'taken').length;
  int get totalCount => todayDoses.length;

  List<DoseEntry> dosesForTimeOfDay(String timeOfDay) =>
      todayDoses.where((d) => d.timeOfDay == timeOfDay).toList();
}

class MedicationNotifier extends StateNotifier<MedicationState> {
  final Dio _dio;

  MedicationNotifier(this._dio) : super(const MedicationState()) {
    refresh();
  }

  Future<void> refresh() async {
    state = state.copyWith(isLoading: true);
    try {
      final today = _todayStr();
      final results = await Future.wait([
        _dio.get('/medications/'),
        _dio.get('/dose-logs/', queryParameters: {'date': today}),
      ]);

      final rawMeds = (results[0].data as List<dynamic>? ?? [])
          .map((m) => MedicationItem.fromJson(m as Map<String, dynamic>))
          .toList();

      final rawDoses = (results[1].data as List<dynamic>? ?? [])
          .map((d) => DoseEntry.fromJson(d as Map<String, dynamic>))
          .toList();

      state = MedicationState(
        medications: rawMeds,
        todayDoses: rawDoses,
        isLoading: false,
      );
    } on DioException catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.response?.data?['detail'] ?? e.message ?? 'Failed to load',
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> markDose(String doseId, String status) async {
    // Optimistic update
    state = state.copyWith(
      todayDoses: state.todayDoses
          .map((d) => d.doseId == doseId ? d.copyWith(status: status) : d)
          .toList(),
    );
    try {
      await _dio.post('/dose-logs/', data: {'dose_id': doseId, 'status': status});
    } on DioException catch (_) {
      // Revert on failure
      await refresh();
    }
  }

  Future<void> deleteMedication(String medicationId) async {
    try {
      await _dio.delete('/medications/$medicationId');
      await refresh();
    } on DioException catch (e) {
      state = state.copyWith(
        error: e.response?.data?['detail'] ?? 'Failed to delete',
      );
    }
  }

  String _todayStr() {
    final now = DateTime.now();
    final m = now.month.toString().padLeft(2, '0');
    final d = now.day.toString().padLeft(2, '0');
    return '${now.year}-$m-$d';
  }
}

final medicationProvider =
    StateNotifierProvider<MedicationNotifier, MedicationState>(
  (ref) => MedicationNotifier(ref.watch(apiServiceProvider)),
);
