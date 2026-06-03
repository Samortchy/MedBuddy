import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../constants/colors.dart';
import '../../../constants/dimens.dart';
import '../../../constants/text_styles.dart';
import '../../../models/medication_model.dart';
import '../../../providers/patient_provider.dart';
import '../../../providers/medication_provider.dart';
import '../../../widgets/shared/sos_button.dart';
import '../../../widgets/shared/bottom_nav_bar.dart';

class Home extends ConsumerStatefulWidget {
  const Home({super.key});

  @override
  ConsumerState<Home> createState() => _HomeState();
}

class _HomeState extends ConsumerState<Home> {
  final PatientNavTab _activeTab = PatientNavTab.home;

  String get _greeting {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning';
    if (hour < 17) return 'Good afternoon';
    return 'Good evening';
  }

  void _onTabSelected(PatientNavTab tab) {
    if (tab == _activeTab) return;
    switch (tab) {
      case PatientNavTab.meds:
        Navigator.of(context).pushNamed('/medication-schedule');
      case PatientNavTab.chat:
        Navigator.of(context).pushNamed('/ai-chat');
      case PatientNavTab.history:
        Navigator.of(context).pushNamed('/wellness-history');
      case PatientNavTab.profile:
        Navigator.of(context).pushNamed('/my-profile');
      case PatientNavTab.home:
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final profileState = ref.watch(patientProfileProvider);
    final medState = ref.watch(medicationProvider);

    final firstName = profileState.valueOrNull?.firstName ?? '…';
    final doses = medState.todayDoses.take(3).toList();

    return Scaffold(
      backgroundColor: MedBuddyColors.warmWhite,
      body: Stack(
        children: [
          Column(
            children: [
              _buildAppBar(context),
              Expanded(
                child: RefreshIndicator(
                  color: MedBuddyColors.primary,
                  onRefresh: () async {
                    ref.read(patientProfileProvider.notifier).fetch();
                    await ref.read(medicationProvider.notifier).refresh();
                  },
                  child: ListView(
                    padding: const EdgeInsets.only(
                      left: MedBuddyDimens.spacingLg,
                      right: MedBuddyDimens.spacingLg,
                      top: MedBuddyDimens.spacingXl,
                      bottom: 100,
                    ),
                    children: [
                      _buildGreetingRow(firstName),
                      const SizedBox(height: MedBuddyDimens.spacingXl),
                      _buildSectionHeader("TODAY'S MEDICATIONS"),
                      const SizedBox(height: MedBuddyDimens.spacingMd),
                      if (medState.isLoading)
                        const Center(
                          child: Padding(
                            padding: EdgeInsets.all(16),
                            child: CircularProgressIndicator(
                              color: MedBuddyColors.primary,
                              strokeWidth: 2,
                            ),
                          ),
                        )
                      else if (doses.isEmpty)
                        _buildEmptyMeds()
                      else
                        ...doses.map((d) => Padding(
                              padding: const EdgeInsets.only(
                                  bottom: MedBuddyDimens.spacingSm),
                              child: _MedCard(dose: d, onMarkTaken: () {
                                ref
                                    .read(medicationProvider.notifier)
                                    .markDose(d.doseId, 'taken');
                              }),
                            )),
                      if (doses.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 4, bottom: 4),
                          child: TextButton(
                            onPressed: () =>
                                Navigator.of(context).pushNamed('/medication-schedule'),
                            child: Text(
                              'View full schedule',
                              style: MedBuddyTextStyles.secondary.copyWith(
                                color: MedBuddyColors.primary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      const SizedBox(height: MedBuddyDimens.spacingXl),
                      _buildSectionHeader('HOW ARE YOU FEELING?'),
                      const SizedBox(height: MedBuddyDimens.spacingMd),
                      const _CheckInPrompt(),
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
              activeTab: _activeTab,
              onTabSelected: _onTabSelected,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAppBar(BuildContext context) {
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
          Container(
            width: MedBuddyDimens.avatarSizeMedium,
            height: MedBuddyDimens.avatarSizeMedium,
            decoration: const BoxDecoration(
              color: MedBuddyColors.primarySoft,
              shape: BoxShape.circle,
            ),
            child: const Center(
              child: Icon(Icons.person_outline,
                  color: MedBuddyColors.primaryDark, size: 22),
            ),
          ),
          const SizedBox(width: MedBuddyDimens.spacingMd),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'MedBuddy',
                style: MedBuddyTextStyles.label.copyWith(
                  color: MedBuddyColors.primaryDark,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.4,
                ),
              ),
              Text(
                'Home',
                style: MedBuddyTextStyles.heading2.copyWith(
                  color: MedBuddyColors.slate900,
                ),
              ),
            ],
          ),
          const Spacer(),
          IconButton(
            onPressed: () => Navigator.of(context).pushNamed('/settings'),
            icon: const Icon(Icons.settings_outlined,
                color: MedBuddyColors.slate500, size: 24),
            tooltip: 'Settings',
          ),
        ],
      ),
    );
  }

  Widget _buildGreetingRow(String firstName) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '$_greeting, $firstName',
          style: MedBuddyTextStyles.heading1.copyWith(
            color: MedBuddyColors.slate900,
            fontSize: 26,
          ),
        ),
        const SizedBox(height: MedBuddyDimens.spacingXs),
        Text(
          _formattedDate(),
          style: MedBuddyTextStyles.body.copyWith(
            color: MedBuddyColors.slate500,
          ),
        ),
      ],
    );
  }

  String _formattedDate() {
    final now = DateTime.now();
    const months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December',
    ];
    const days = [
      'Monday', 'Tuesday', 'Wednesday', 'Thursday',
      'Friday', 'Saturday', 'Sunday',
    ];
    return '${days[now.weekday - 1]}, ${months[now.month - 1]} ${now.day}';
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 0),
      child: Text(title, style: MedBuddyTextStyles.sectionHeader),
    );
  }

  Widget _buildEmptyMeds() {
    return Container(
      padding: const EdgeInsets.all(MedBuddyDimens.spacingXl),
      decoration: BoxDecoration(
        color: MedBuddyColors.pureWhite,
        borderRadius: BorderRadius.circular(MedBuddyDimens.radiusLg),
        border: Border.all(color: MedBuddyColors.slate300, width: 0.5),
      ),
      child: Column(
        children: [
          const Icon(Icons.medication_outlined,
              color: MedBuddyColors.slate300, size: 36),
          const SizedBox(height: MedBuddyDimens.spacingMd),
          Text(
            'No medications scheduled today',
            style: MedBuddyTextStyles.body.copyWith(
              color: MedBuddyColors.slate500,
            ),
          ),
          const SizedBox(height: MedBuddyDimens.spacingSm),
          TextButton(
            onPressed: () =>
                Navigator.of(context).pushNamed('/add-medication'),
            child: Text(
              'Add a medication',
              style: MedBuddyTextStyles.secondary.copyWith(
                color: MedBuddyColors.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Med Card ──────────────────────────────────────────────────────────────────

class _MedCard extends StatelessWidget {
  final DoseEntry dose;
  final VoidCallback onMarkTaken;

  const _MedCard({required this.dose, required this.onMarkTaken});

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

  IconData get _statusIcon {
    switch (dose.status) {
      case 'taken':
        return Icons.check_circle_outline;
      case 'missed':
        return Icons.error_outline;
      default:
        return Icons.schedule;
    }
  }

  String _formatTime(String raw) {
    // scheduledTime is a full ISO datetime — format like the meds schedule tab.
    try {
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

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: dose.status == 'pending' ? onMarkTaken : null,
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
                color: MedBuddyColors.primarySoft,
                borderRadius: BorderRadius.circular(MedBuddyDimens.radiusMd),
              ),
              child: const Center(
                child: Icon(Icons.medication_outlined,
                    color: MedBuddyColors.primaryDark, size: 22),
              ),
            ),
            const SizedBox(width: MedBuddyDimens.spacingMd),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(dose.medicationName, style: MedBuddyTextStyles.bodyBold),
                  const SizedBox(height: 2),
                  Text(
                    '${dose.dosage} · ${_formatTime(dose.scheduledTime)}',
                    style: MedBuddyTextStyles.secondary
                        .copyWith(color: MedBuddyColors.slate500),
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
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(_statusIcon, color: _statusText, size: 12),
                  const SizedBox(width: 4),
                  Text(
                    _statusLabel,
                    style: MedBuddyTextStyles.caption.copyWith(
                      color: _statusText,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Check-in Prompt ───────────────────────────────────────────────────────────

class _CheckInPrompt extends StatelessWidget {
  const _CheckInPrompt();

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.of(context).pushNamed('/checkin'),
      child: Container(
        padding: const EdgeInsets.all(MedBuddyDimens.spacingLg),
        decoration: BoxDecoration(
          color: MedBuddyColors.primarySoft,
          borderRadius: BorderRadius.circular(MedBuddyDimens.radiusLg),
          border: Border.all(
              color: MedBuddyColors.primaryLight.withValues(alpha: 0.6),
              width: 1),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: const BoxDecoration(
                color: MedBuddyColors.primary,
                shape: BoxShape.circle,
              ),
              child: const Center(
                child: Icon(Icons.chat_bubble_outline,
                    color: MedBuddyColors.pureWhite, size: 20),
              ),
            ),
            const SizedBox(width: MedBuddyDimens.spacingMd),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Daily Check-in',
                    style: MedBuddyTextStyles.bodyBold.copyWith(
                      color: MedBuddyColors.primaryDark,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Tap to tell MedBuddy how you feel today',
                    style: MedBuddyTextStyles.secondary.copyWith(
                      color: MedBuddyColors.slate500,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right,
                color: MedBuddyColors.primaryDark, size: 22),
          ],
        ),
      ),
    );
  }
}
