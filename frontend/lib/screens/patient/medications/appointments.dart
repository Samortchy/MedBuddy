import 'package:flutter/material.dart';
import '../../../constants/colors.dart';
import '../../../constants/dimens.dart';
import '../../../constants/text_styles.dart';
import '../../../widgets/shared/sos_button.dart';
import '../../../widgets/shared/bottom_nav_bar.dart';

class AppointmentsScreen extends StatelessWidget {
  const AppointmentsScreen({super.key});

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
                    top: MedBuddyDimens.spacingLg,
                    bottom: 100,
                  ),
                  children: const [
                    _SectionHeader('UPCOMING'),
                    SizedBox(height: MedBuddyDimens.spacingMd),
                    _AppointmentCard(
                      doctor: 'Dr. Ahmed',
                      specialty: 'General Practitioner',
                      dateLabel: 'Tomorrow',
                      timeLabel: '10:00 AM',
                      urgency: _Urgency.soon,
                    ),
                    SizedBox(height: MedBuddyDimens.spacingSm),
                    _AppointmentCard(
                      doctor: 'Cardiology Clinic',
                      specialty: 'Cardiology',
                      dateLabel: 'April 10',
                      timeLabel: '2:00 PM',
                      urgency: _Urgency.normal,
                    ),
                    SizedBox(height: MedBuddyDimens.spacingXl),
                    _SectionHeader('PAST'),
                    SizedBox(height: MedBuddyDimens.spacingMd),
                    _AppointmentCard(
                      doctor: 'Dr. Hassan',
                      specialty: 'Endocrinology',
                      dateLabel: 'March 20',
                      timeLabel: '9:30 AM',
                      urgency: _Urgency.past,
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
          GestureDetector(
            onTap: () => Navigator.of(context).maybePop(),
            child: const Icon(Icons.arrow_back_ios_new,
                color: MedBuddyColors.primaryDark, size: 20),
          ),
          const SizedBox(width: MedBuddyDimens.spacingMd),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('CALENDAR', style: MedBuddyTextStyles.sectionHeader),
              Text(
                'Appointments',
                style: MedBuddyTextStyles.heading2
                    .copyWith(color: MedBuddyColors.slate900),
              ),
            ],
          ),
          const Spacer(),
          GestureDetector(
            onTap: () => Navigator.of(context).pushNamed('/add-medication'),
            child: Container(
              width: MedBuddyDimens.buttonHeightSecondary,
              height: MedBuddyDimens.buttonHeightSecondary,
              decoration: BoxDecoration(
                color: MedBuddyColors.primarySoft,
                borderRadius: BorderRadius.circular(MedBuddyDimens.radiusMd),
              ),
              child: const Icon(Icons.add,
                  color: MedBuddyColors.primaryDark, size: 22),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Urgency ───────────────────────────────────────────────────────────────────

enum _Urgency { soon, normal, past }

// ── Section Header ────────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader(this.title);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Text(title, style: MedBuddyTextStyles.sectionHeader),
    );
  }
}

// ── Appointment Card ──────────────────────────────────────────────────────────

class _AppointmentCard extends StatelessWidget {
  final String doctor;
  final String specialty;
  final String dateLabel;
  final String timeLabel;
  final _Urgency urgency;

  const _AppointmentCard({
    required this.doctor,
    required this.specialty,
    required this.dateLabel,
    required this.timeLabel,
    required this.urgency,
  });

  Color get _badgeBg {
    switch (urgency) {
      case _Urgency.soon:
        return MedBuddyColors.warningLight;
      case _Urgency.normal:
        return MedBuddyColors.primarySoft;
      case _Urgency.past:
        return MedBuddyColors.slate100;
    }
  }

  Color get _badgeText {
    switch (urgency) {
      case _Urgency.soon:
        return MedBuddyColors.warning;
      case _Urgency.normal:
        return MedBuddyColors.primaryDark;
      case _Urgency.past:
        return MedBuddyColors.slate500;
    }
  }

  String get _badgeLabel {
    switch (urgency) {
      case _Urgency.soon:
        return 'Soon';
      case _Urgency.normal:
        return 'Upcoming';
      case _Urgency.past:
        return 'Past';
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
              color: urgency == _Urgency.past
                  ? MedBuddyColors.slate100
                  : MedBuddyColors.primarySoft,
              borderRadius: BorderRadius.circular(MedBuddyDimens.radiusMd),
            ),
            child: Center(
              child: Icon(
                Icons.local_hospital_outlined,
                color: urgency == _Urgency.past
                    ? MedBuddyColors.slate500
                    : MedBuddyColors.primaryDark,
                size: 20,
              ),
            ),
          ),
          const SizedBox(width: MedBuddyDimens.spacingMd),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(doctor, style: MedBuddyTextStyles.bodyBold),
                const SizedBox(height: 2),
                Text(
                  specialty,
                  style: MedBuddyTextStyles.secondary
                      .copyWith(color: MedBuddyColors.slate500),
                ),
                const SizedBox(height: MedBuddyDimens.spacingXs),
                Row(
                  children: [
                    const Icon(Icons.schedule,
                        color: MedBuddyColors.slate500, size: 13),
                    const SizedBox(width: 4),
                    Text(
                      '$dateLabel · $timeLabel',
                      style: MedBuddyTextStyles.label.copyWith(
                        color: MedBuddyColors.slate500,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: MedBuddyDimens.spacingSm),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: _badgeBg,
              borderRadius: BorderRadius.circular(MedBuddyDimens.radiusPill),
            ),
            child: Text(
              _badgeLabel,
              style: MedBuddyTextStyles.caption.copyWith(
                color: _badgeText,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
