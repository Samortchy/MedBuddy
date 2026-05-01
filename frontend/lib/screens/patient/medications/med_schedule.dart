import 'package:flutter/material.dart';
import '../../../constants/colors.dart';
import '../../../constants/dimens.dart';
import '../../../constants/text_styles.dart';
import '../../../widgets/shared/sos_button.dart';
import '../../../widgets/shared/bottom_nav_bar.dart';

class MedicationSchedule extends StatefulWidget {
  const MedicationSchedule({super.key});

  @override
  State<MedicationSchedule> createState() => _MedicationScheduleState();
}

class _MedicationScheduleState extends State<MedicationSchedule> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: MedBuddyColors.warmWhite,
      body: Stack(
        children: [
          Column(
            children: [
              const _AppBar(),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.only(
                    left: MedBuddyDimens.spacingLg,
                    right: MedBuddyDimens.spacingLg,
                    top: MedBuddyDimens.spacingLg,
                    bottom: 100,
                  ),
                  children: const [
                    _TimeSection(
                      label: 'MORNING',
                      icon: Icons.wb_sunny_outlined,
                      tiles: [
                        _MedTile(
                          name: 'Metformin',
                          dose: '500 mg',
                          time: '8:00 AM',
                          status: _MedStatus.taken,
                        ),
                        _MedTile(
                          name: 'Aspirin',
                          dose: '100 mg',
                          time: '9:00 AM',
                          status: _MedStatus.pending,
                        ),
                      ],
                    ),
                    SizedBox(height: MedBuddyDimens.spacingXl),
                    _TimeSection(
                      label: 'AFTERNOON',
                      icon: Icons.wb_cloudy_outlined,
                      tiles: [
                        _MedTile(
                          name: 'Lisinopril',
                          dose: '10 mg',
                          time: '1:00 PM',
                          status: _MedStatus.pending,
                        ),
                      ],
                    ),
                    SizedBox(height: MedBuddyDimens.spacingXl),
                    _TimeSection(
                      label: 'EVENING',
                      icon: Icons.nights_stay_outlined,
                      tiles: [
                        _MedTile(
                          name: 'Insulin',
                          dose: '10 IU',
                          time: '7:00 AM',
                          status: _MedStatus.missed,
                        ),
                      ],
                    ),
                    SizedBox(height: MedBuddyDimens.spacingXl),
                    _TimeSection(
                      label: 'NIGHT',
                      icon: Icons.bedtime_outlined,
                      tiles: [
                        _MedTile(
                          name: 'Atorvastatin',
                          dose: '20 mg',
                          time: '10:00 PM',
                          status: _MedStatus.pending,
                        ),
                      ],
                    ),
                  ],
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
        onPressed: () => Navigator.of(context).pushNamed('/add-medication'),
        tooltip: 'Add medication',
        child: const Icon(Icons.add, size: 28),
      ),
    );
  }
}

// ── App Bar ───────────────────────────────────────────────────────────────────

class _AppBar extends StatelessWidget {
  const _AppBar();

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
              const Text(
                'SCHEDULE',
                style: MedBuddyTextStyles.sectionHeader,
              ),
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
                  '1 of 5 taken',
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

// ── Time-of-day Section ───────────────────────────────────────────────────────

class _TimeSection extends StatelessWidget {
  final String label;
  final IconData icon;
  final List<_MedTile> tiles;

  const _TimeSection({
    required this.label,
    required this.icon,
    required this.tiles,
  });

  @override
  Widget build(BuildContext context) {
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
        ...tiles.map((tile) => Padding(
              padding: const EdgeInsets.only(bottom: MedBuddyDimens.spacingSm),
              child: tile,
            )),
      ],
    );
  }
}

// ── Med Status ────────────────────────────────────────────────────────────────

enum _MedStatus { taken, pending, missed }

// ── Med Tile ──────────────────────────────────────────────────────────────────

class _MedTile extends StatelessWidget {
  final String name;
  final String dose;
  final String time;
  final _MedStatus status;

  const _MedTile({
    required this.name,
    required this.dose,
    required this.time,
    required this.status,
  });

  Color get _statusBg {
    switch (status) {
      case _MedStatus.taken:
        return MedBuddyColors.successLight;
      case _MedStatus.pending:
        return MedBuddyColors.warningLight;
      case _MedStatus.missed:
        return MedBuddyColors.emergencyLight;
    }
  }

  Color get _statusText {
    switch (status) {
      case _MedStatus.taken:
        return MedBuddyColors.success;
      case _MedStatus.pending:
        return MedBuddyColors.warning;
      case _MedStatus.missed:
        return MedBuddyColors.emergency;
    }
  }

  String get _statusLabel {
    switch (status) {
      case _MedStatus.taken:
        return 'Taken';
      case _MedStatus.pending:
        return 'Pending';
      case _MedStatus.missed:
        return 'Missed';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
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
              color: status == _MedStatus.taken
                  ? MedBuddyColors.successLight
                  : MedBuddyColors.primarySoft,
              borderRadius: BorderRadius.circular(MedBuddyDimens.radiusMd),
            ),
            child: Center(
              child: Icon(
                status == _MedStatus.taken
                    ? Icons.check_circle_outline
                    : Icons.medication_outlined,
                color: status == _MedStatus.taken
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
                  name,
                  style: MedBuddyTextStyles.bodyBold.copyWith(
                    color: MedBuddyColors.slate900,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '$dose · $time',
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
              borderRadius: BorderRadius.circular(MedBuddyDimens.radiusPill),
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
    );
  }
}
