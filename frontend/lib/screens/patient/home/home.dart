import 'package:flutter/material.dart';
import '../../../constants/colors.dart';
import '../../../constants/dimens.dart';
import '../../../constants/text_styles.dart';
import '../../../widgets/shared/sos_button.dart';
import '../../../widgets/shared/bottom_nav_bar.dart';

class Home extends StatefulWidget {
  const Home({super.key});

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
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
    return Scaffold(
      backgroundColor: MedBuddyColors.warmWhite,
      body: Stack(
        children: [
          Column(
            children: [
              _buildAppBar(context),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.only(
                    left: MedBuddyDimens.spacingLg,
                    right: MedBuddyDimens.spacingLg,
                    top: MedBuddyDimens.spacingXl,
                    bottom: 100,
                  ),
                  children: [
                    _buildGreetingRow(),
                    const SizedBox(height: MedBuddyDimens.spacingXl),
                    _buildSectionHeader("TODAY'S MEDICATIONS"),
                    const SizedBox(height: MedBuddyDimens.spacingMd),
                    const _MedCard(
                      name: 'Metformin',
                      dose: '500 mg',
                      time: '8:00 AM',
                      status: _MedStatus.taken,
                    ),
                    const SizedBox(height: MedBuddyDimens.spacingSm),
                    const _MedCard(
                      name: 'Aspirin',
                      dose: '100 mg',
                      time: '12:00 PM',
                      status: _MedStatus.pending,
                    ),
                    const SizedBox(height: MedBuddyDimens.spacingSm),
                    const _MedCard(
                      name: 'Insulin',
                      dose: '10 IU',
                      time: '7:00 AM',
                      status: _MedStatus.missed,
                    ),
                    const SizedBox(height: MedBuddyDimens.spacingXl),
                    _buildSectionHeader('UPCOMING'),
                    const SizedBox(height: MedBuddyDimens.spacingMd),
                    const _AppointmentCard(),
                    const SizedBox(height: MedBuddyDimens.spacingXl),
                    _buildSectionHeader('HOW ARE YOU FEELING?'),
                    const SizedBox(height: MedBuddyDimens.spacingMd),
                    const _CheckInPrompt(),
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
            icon: const Icon(Icons.notifications_outlined,
                color: MedBuddyColors.slate500, size: 24),
            tooltip: 'Notifications',
          ),
        ],
      ),
    );
  }

  Widget _buildGreetingRow() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '$_greeting, Kevin',
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
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];
    const days = [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday',
    ];
    final weekday = days[now.weekday - 1];
    final month = months[now.month - 1];
    return '$weekday, $month ${now.day}';
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 0),
      child: Text(title, style: MedBuddyTextStyles.sectionHeader),
    );
  }
}

// ── Med Status enum ───────────────────────────────────────────────────────────

enum _MedStatus { taken, pending, missed }

// ── Medication Card ───────────────────────────────────────────────────────────

class _MedCard extends StatelessWidget {
  final String name;
  final String dose;
  final String time;
  final _MedStatus status;

  const _MedCard({
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

  IconData get _statusIcon {
    switch (status) {
      case _MedStatus.taken:
        return Icons.check_circle_outline;
      case _MedStatus.pending:
        return Icons.schedule;
      case _MedStatus.missed:
        return Icons.error_outline;
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
                Text(name, style: MedBuddyTextStyles.bodyBold),
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
    );
  }
}

// ── Appointment Card ──────────────────────────────────────────────────────────

class _AppointmentCard extends StatelessWidget {
  const _AppointmentCard();

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
              color: MedBuddyColors.primarySoft,
              borderRadius: BorderRadius.circular(MedBuddyDimens.radiusMd),
            ),
            child: const Center(
              child: Icon(Icons.calendar_today_outlined,
                  color: MedBuddyColors.primaryDark, size: 20),
            ),
          ),
          const SizedBox(width: MedBuddyDimens.spacingMd),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Dr. Ahmed', style: MedBuddyTextStyles.bodyBold),
                const SizedBox(height: 2),
                Text(
                  'Tomorrow · 10:00 AM',
                  style: MedBuddyTextStyles.secondary.copyWith(
                    color: MedBuddyColors.slate500,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: MedBuddyColors.primaryLight.withValues(alpha: 0.4),
              borderRadius: BorderRadius.circular(MedBuddyDimens.radiusPill),
            ),
            child: Text(
              'Soon',
              style: MedBuddyTextStyles.caption.copyWith(
                color: MedBuddyColors.primaryDark,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
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
