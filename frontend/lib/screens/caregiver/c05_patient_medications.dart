import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '/constants/colors.dart';
import '/models/medication_model.dart';
import '/providers/caregiver_provider.dart';

/// Read-only view of a linked patient's medications (caregiver side).
class C05PatientMedications extends ConsumerWidget {
  final String patientId;
  final String patientName;

  const C05PatientMedications({
    super.key,
    required this.patientId,
    this.patientName = 'Patient',
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final medsAsync = ref.watch(caregiverPatientMedsProvider(patientId));

    return Scaffold(
      backgroundColor: MedColors.warmWhite,
      appBar: AppBar(
        backgroundColor: MedColors.primaryDark,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('Medications — $patientName',
            style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold)),
      ),
      body: medsAsync.when(
        loading: () => const Center(
            child: CircularProgressIndicator(color: MedColors.primary)),
        error: (e, _) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Could not load medications',
                  style: TextStyle(color: MedColors.emergency)),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: () =>
                    ref.invalidate(caregiverPatientMedsProvider(patientId)),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
        data: (meds) => meds.isEmpty
            ? const Center(
                child: Text('No medications on file.',
                    style: TextStyle(color: MedColors.slate500)))
            : ListView(
                padding: const EdgeInsets.all(16),
                children: meds.map((m) => _MedCard(med: m)).toList(),
              ),
      ),
    );
  }
}

class _MedCard extends StatelessWidget {
  final MedicationItem med;
  const _MedCard({required this.med});

  String get _times {
    if (med.schedules.isEmpty) return '—';
    return med.schedules.map((s) => s.timeOfDay).join(' · ');
  }

  String get _frequencyLabel => med.frequency.replaceAll('_', ' ');

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: MedColors.slate300),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: MedColors.primarySoft,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.medication,
                      color: MedColors.primary, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        med.dosage.isNotEmpty
                            ? '${med.name} · ${med.dosage}'
                            : med.name,
                        style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: MedColors.slate900),
                      ),
                      Text(_frequencyLabel,
                          style: const TextStyle(
                              fontSize: 13, color: MedColors.slate500)),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                const Icon(Icons.access_time,
                    size: 14, color: MedColors.slate500),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(_times,
                      style: const TextStyle(
                          fontSize: 13, color: MedColors.slate500)),
                ),
              ],
            ),
            if (med.instruction != null && med.instruction!.isNotEmpty) ...[
              const SizedBox(height: 6),
              Row(
                children: [
                  const Icon(Icons.info_outline,
                      size: 14, color: MedColors.slate500),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(med.instruction!,
                        style: const TextStyle(
                            fontSize: 13, color: MedColors.slate500)),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
