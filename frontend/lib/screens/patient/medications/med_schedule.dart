import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../constants/colors.dart';
import '../../../constants/dimens.dart';
import '../../../constants/text_styles.dart';
import '../../../models/medication_model.dart';
import '../../../providers/medication_provider.dart';
import '../../../widgets/shared/sos_button.dart';
import '../../../widgets/shared/bottom_nav_bar.dart';
import 'add_edit.dart';

class MedicationSchedule extends ConsumerWidget {
  const MedicationSchedule({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final medState = ref.watch(medicationProvider);

    final sections = [
      ('MORNING', Icons.wb_sunny_outlined, 'morning'),
      ('AFTERNOON', Icons.wb_cloudy_outlined, 'afternoon'),
      ('EVENING', Icons.nights_stay_outlined, 'evening'),
      ('NIGHT', Icons.bedtime_outlined, 'night'),
    ];

    return Scaffold(
      backgroundColor: MedBuddyColors.warmWhite,
      body: Stack(
        children: [
          Column(
            children: [
              _AppBar(
                takenCount: medState.takenCount,
                totalCount: medState.totalCount,
              ),
              Expanded(
                child: RefreshIndicator(
                  color: MedBuddyColors.primary,
                  onRefresh: () =>
                      ref.read(medicationProvider.notifier).refresh(),
                  child: medState.isLoading
                      ? const Center(
                          child: CircularProgressIndicator(
                            color: MedBuddyColors.primary,
                          ),
                        )
                      : medState.todayDoses.isEmpty
                          ? _buildEmpty(context)
                          : ListView(
                              padding: const EdgeInsets.only(
                                left: MedBuddyDimens.spacingLg,
                                right: MedBuddyDimens.spacingLg,
                                top: MedBuddyDimens.spacingLg,
                                bottom: 100,
                              ),
                              children: [
                                for (final section in sections) ...[
                                  _buildSection(
                                    context,
                                    ref,
                                    label: section.$1,
                                    icon: section.$2,
                                    timeOfDay: section.$3,
                                    doses: medState
                                        .dosesForTimeOfDay(section.$3),
                                  ),
                                  const SizedBox(
                                      height: MedBuddyDimens.spacingXl),
                                ],
                              ],
                            ),
                ),
              ),
            ],
          ),
          const SOSButton(),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: PatientBottomNavBar(
              activeTab: PatientNavTab.meds,
              onTabSelected: (tab) {
                if (tab == PatientNavTab.meds) return;
                switch (tab) {
                  case PatientNavTab.home:
                    Navigator.of(context).pushNamed('/home');
                  case PatientNavTab.chat:
                    Navigator.of(context).pushNamed('/ai-chat');
                  case PatientNavTab.history:
                    Navigator.of(context).pushNamed('/wellness-history');
                  case PatientNavTab.profile:
                    Navigator.of(context).pushNamed('/my-profile');
                  case PatientNavTab.meds:
                    break;
                }
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: MedBuddyColors.primary,
        foregroundColor: MedBuddyColors.pureWhite,
        elevation: 2,
        onPressed: () async {
          await Navigator.of(context).pushNamed('/add-medication');
          ref.read(medicationProvider.notifier).refresh();
        },
        tooltip: 'Add medication',
        child: const Icon(Icons.add, size: 28),
      ),
    );
  }

  Widget _buildSection(
    BuildContext context,
    WidgetRef ref, {
    required String label,
    required IconData icon,
    required String timeOfDay,
    required List<DoseEntry> doses,
  }) {
    if (doses.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: MedBuddyColors.slate500, size: 16),
            const SizedBox(width: MedBuddyDimens.spacingXs),
            Text(label, style: MedBuddyTextStyles.sectionHeader),
          ],
        ),
        const SizedBox(height: MedBuddyDimens.spacingMd),
        ...doses.map((d) => Padding(
              padding:
                  const EdgeInsets.only(bottom: MedBuddyDimens.spacingSm),
              child: _MedTile(
                dose: d,
                onMarkTaken: () =>
                    ref.read(medicationProvider.notifier).markDose(d.doseId, 'taken'),
              ),
            )),
      ],
    );
  }

  Widget _buildEmpty(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(MedBuddyDimens.spacingXxl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.medication_outlined,
                color: MedBuddyColors.slate300, size: 48),
            const SizedBox(height: MedBuddyDimens.spacingLg),
            Text(
              'No medications scheduled today',
              style: MedBuddyTextStyles.body
                  .copyWith(color: MedBuddyColors.slate500),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: MedBuddyDimens.spacingMd),
            ElevatedButton.icon(
              onPressed: () =>
                  Navigator.of(context).pushNamed('/add-medication'),
              icon: const Icon(Icons.add, size: 18),
              label: const Text('Add Medication'),
              style: ElevatedButton.styleFrom(
                backgroundColor: MedBuddyColors.primary,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                    borderRadius:
                        BorderRadius.circular(MedBuddyDimens.radiusLg)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── App Bar ───────────────────────────────────────────────────────────────────

class _AppBar extends StatelessWidget {
  final int takenCount;
  final int totalCount;

  const _AppBar({required this.takenCount, required this.totalCount});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + MedBuddyDimens.spacingMd,
        left: MedBuddyDimens.spacingLg,
        right: MedBuddyDimens.spacingLg,
        bottom: MedBuddyDimens.spacingMd,
      ),
      decoration: const BoxDecoration(
        color: MedBuddyColors.pureWhite,
        border: Border(
          bottom: BorderSide(color: MedBuddyColors.slate300, width: 0.5),
        ),
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.of(context).maybePop(),
            child: const Icon(Icons.arrow_back_ios_new,
                color: MedBuddyColors.primaryDark, size: 20),
          ),
          const SizedBox(width: MedBuddyDimens.spacingMd),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('SCHEDULE', style: MedBuddyTextStyles.sectionHeader),
              Text(
                'Medications',
                style: MedBuddyTextStyles.heading2.copyWith(
                  color: MedBuddyColors.slate900,
                ),
              ),
            ],
          ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(
                horizontal: MedBuddyDimens.spacingMd,
                vertical: MedBuddyDimens.spacingSm),
            decoration: BoxDecoration(
              color: MedBuddyColors.primarySoft,
              borderRadius: BorderRadius.circular(MedBuddyDimens.radiusPill),
            ),
            child: Row(
              children: [
                const Icon(Icons.check_circle_outline,
                    color: MedBuddyColors.success, size: 16),
                const SizedBox(width: 4),
                Text(
                  '$takenCount of $totalCount taken',
                  style: MedBuddyTextStyles.label.copyWith(
                    color: MedBuddyColors.primaryDark,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Med Tile ──────────────────────────────────────────────────────────────────

class _MedTile extends ConsumerWidget {
  final DoseEntry dose;
  final VoidCallback onMarkTaken;

  const _MedTile({required this.dose, required this.onMarkTaken});

  Color get _statusBg {
    switch (dose.status) {
      case 'taken':
        return MedBuddyColors.successLight;
      case 'missed':
        return MedBuddyColors.emergencyLight;
      default:
        return MedBuddyColors.warningLight;
    }
  }

  Color get _statusText {
    switch (dose.status) {
      case 'taken':
        return MedBuddyColors.success;
      case 'missed':
        return MedBuddyColors.emergency;
      default:
        return MedBuddyColors.warning;
    }
  }

  String get _statusLabel {
    switch (dose.status) {
      case 'taken':
        return 'Taken';
      case 'missed':
        return 'Missed';
      case 'late':
        return 'Late';
      default:
        return 'Pending';
    }
  }

  String _formatTime(String raw) {
    try {
      // Handle full ISO datetime (e.g. 2026-06-02T08:00:00+00:00)
      // Use UTC hour to match how doses are bucketed
      final dt = DateTime.parse(raw).toUtc();
      int h = dt.hour;
      final m = dt.minute.toString().padLeft(2, '0');
      final suffix = h >= 12 ? 'PM' : 'AM';
      if (h > 12) h -= 12;
      if (h == 0) h = 12;
      return '$h:$m $suffix';
    } catch (_) {
      return raw;
    }
  }

  void _showOptions(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      backgroundColor: MedBuddyColors.pureWhite,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
              top: Radius.circular(MedBuddyDimens.radiusLg))),
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.edit_outlined,
                  color: MedBuddyColors.primary),
              title: Text('Edit ${dose.medicationName}',
                  style: MedBuddyTextStyles.body),
              onTap: () async {
                Navigator.pop(context);
                final meds = ref.read(medicationProvider).medications;
                final med = meds
                    .where((m) => m.id == dose.medicationId)
                    .firstOrNull;
                await Navigator.of(context).push(MaterialPageRoute(
                  builder: (_) => AddEditMedication(medication: med),
                ));
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete_outline,
                  color: MedBuddyColors.emergency),
              title: Text('Delete ${dose.medicationName}',
                  style: MedBuddyTextStyles.body
                      .copyWith(color: MedBuddyColors.emergency)),
              onTap: () {
                Navigator.pop(context);
                ref
                    .read(medicationProvider.notifier)
                    .deleteMedication(dose.medicationId);
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isTaken = dose.status == 'taken';
    return GestureDetector(
      onTap: dose.status == 'pending' ? onMarkTaken : null,
      onLongPress: () => _showOptions(context, ref),
      child: Container(
        padding: const EdgeInsets.all(MedBuddyDimens.spacingLg),
        decoration: BoxDecoration(
          color: MedBuddyColors.pureWhite,
          borderRadius: BorderRadius.circular(MedBuddyDimens.radiusLg),
          border: Border.all(color: MedBuddyColors.slate300, width: 0.5),
          boxShadow: [
            BoxShadow(
              color: MedBuddyColors.slate300.withValues(alpha: 0.25),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: isTaken
                    ? MedBuddyColors.successLight
                    : MedBuddyColors.primarySoft,
                borderRadius: BorderRadius.circular(MedBuddyDimens.radiusMd),
              ),
              child: Center(
                child: Icon(
                  isTaken
                      ? Icons.check_circle_outline
                      : Icons.medication_outlined,
                  color: isTaken
                      ? MedBuddyColors.success
                      : MedBuddyColors.primaryDark,
                  size: 22,
                ),
              ),
            ),
            const SizedBox(width: MedBuddyDimens.spacingMd),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    dose.medicationName,
                    style: MedBuddyTextStyles.bodyBold.copyWith(
                      color: MedBuddyColors.slate900,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${dose.dosage} · ${_formatTime(dose.scheduledTime)}',
                    style: MedBuddyTextStyles.secondary.copyWith(
                      color: MedBuddyColors.slate500,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: MedBuddyDimens.spacingSm),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: _statusBg,
                borderRadius:
                    BorderRadius.circular(MedBuddyDimens.radiusPill),
              ),
              child: Text(
                _statusLabel,
                style: MedBuddyTextStyles.caption.copyWith(
                  color: _statusText,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
