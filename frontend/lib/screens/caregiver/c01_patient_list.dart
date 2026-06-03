import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '/constants/colors.dart';
import '/providers/caregiver_provider.dart';
import 'c04_patient_dashboard.dart';
import 'c02_add_patient.dart';

class C01PatientList extends ConsumerWidget {
  const C01PatientList({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final patientsState = ref.watch(caregiverPatientsProvider);

    return Scaffold(
      backgroundColor: MedColors.warmWhite,
      appBar: AppBar(
        backgroundColor: MedColors.primaryDark,
        title: const Text('My Patients',
            style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: const Icon(Icons.person_add, color: Colors.white),
            onPressed: () => Navigator.push(context,
                MaterialPageRoute(builder: (_) => const C02AddPatient())),
          ),
        ],
      ),
      body: patientsState.when(
        loading: () => const Center(
            child: CircularProgressIndicator(color: MedColors.primary)),
        error: (e, _) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Failed to load patients',
                  style: TextStyle(color: MedColors.emergency)),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: () =>
                    ref.read(caregiverPatientsProvider.notifier).fetch(),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
        data: (patients) => patients.isEmpty
            ? const Center(
                child: Text('No linked patients yet.',
                    style: TextStyle(color: MedColors.slate500)))
            : RefreshIndicator(
                color: MedColors.primary,
                onRefresh: () =>
                    ref.read(caregiverPatientsProvider.notifier).fetch(),
                child: ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: patients.length,
                  itemBuilder: (context, index) {
                    final p = patients[index];
                    return _PatientCard(
                      name: p.fullName,
                      lastCheckin: p.lastCheckinDisplay,
                      status: 'green',
                      patientId: p.id,
                    );
                  },
                ),
              ),
      ),
    );
  }
}

class _PatientCard extends StatelessWidget {
  final String name;
  final String lastCheckin;
  final String status;
  final String patientId;

  const _PatientCard({
    required this.name,
    required this.lastCheckin,
    required this.status,
    required this.patientId,
  });

  Color get dotColor {
    if (status == 'red') return MedColors.emergency;
    if (status == 'amber') return MedColors.warningMid;
    return MedColors.success;
  }

  Color get borderColor {
    if (status == 'red') return MedColors.emergencyLight;
    return MedColors.slate300;
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => C04PatientDashboard(
            patientName: name,
            lastCheckin: lastCheckin,
            status: status,
            patientId: patientId,
          ),
        ),
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border:
              Border.all(color: borderColor, width: status == 'red' ? 2 : 1),
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 26,
              backgroundColor: MedColors.primarySoft,
              child: Text(name[0],
                  style: const TextStyle(
                    fontSize: 20,
                    color: MedColors.primary,
                    fontWeight: FontWeight.bold,
                  )),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: MedColors.slate900,
                      )),
                  const SizedBox(height: 4),
                  Text('Last check-in: $lastCheckin',
                      style: TextStyle(
                        fontSize: 14,
                        color: status == 'red'
                            ? MedColors.emergency
                            : MedColors.slate500,
                        fontWeight: status == 'red'
                            ? FontWeight.bold
                            : FontWeight.normal,
                      )),
                ],
              ),
            ),
            Container(
              width: 14,
              height: 14,
              decoration:
                  BoxDecoration(color: dotColor, shape: BoxShape.circle),
            ),
          ],
        ),
      ),
    );
  }
}
