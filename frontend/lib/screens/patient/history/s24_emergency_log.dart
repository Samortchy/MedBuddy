import 'package:flutter/material.dart';
import '../../../constants/colors.dart';
import '../../../constants/dimens.dart';
import '../../../constants/text_styles.dart';
import '../../../services/service_interfaces.dart';
import '../../../widgets/shared/sos_button.dart';
import '../../../widgets/shared/bottom_nav_bar.dart';

/// S-24 — Emergency Event Log
class EmergencyEventLogScreen extends StatelessWidget {
  final List<EmergencyEvent> events;
  final VoidCallback? onExport;

  const EmergencyEventLogScreen({
    super.key,
    this.events = const [],
    this.onExport,
  });

  // Placeholder events — replace with widget.events
  List<Map<String, dynamic>> get _placeholderEvents => [
        {
          'type': 'Fall Detected',
          'date': 'Apr 5, 7:42 AM',
          'outcome': 'Handled by Caregiver',
          'outcomeColor': MedBuddyColors.success,
          'borderColor': MedBuddyColors.success,
          'bgColor': MedBuddyColors.pureWhite,
          'detail': 'Agora channel connected · Sarah responded',
          'expanded': false,
          'steps': <Map<String, dynamic>>[],
        },
        {
          'type': 'SOS Activated',
          'date': 'Apr 3, 2:15 PM',
          'outcome': 'False Alarm — Cancelled',
          'outcomeColor': MedBuddyColors.success,
          'borderColor': MedBuddyColors.success,
          'bgColor': MedBuddyColors.pureWhite,
          'detail': 'Cancelled within 10s · No escalation',
          'expanded': false,
          'steps': <Map<String, dynamic>>[],
        },
        {
          'type': 'Fall Detected',
          'date': 'Mar 28, 11:03 PM',
          'outcome': '911 Activated',
          'outcomeColor': MedBuddyColors.emergency,
          'borderColor': MedBuddyColors.emergency,
          'bgColor': const Color(0xFFFFF5F5),
          'detail': 'Full escalation chain triggered',
          'expanded': true,
          'steps': [
            {
              'desc': 'Fall detected — 10s cancel window',
              'time': '11:03:00 PM',
              'success': true
            },
            {
              'desc': 'Factor 1 — Name verification failed',
              'time': '11:03:12 PM',
              'success': false
            },
            {
              'desc': 'Factor 1.5 — Retry also failed',
              'time': '11:03:20 PM',
              'success': false
            },
            {
              'desc': 'Agora channel opened to Sarah',
              'time': '11:03:22 PM',
              'success': true
            },
            {
              'desc': '911 activated · GPS shared',
              'time': '11:03:55 PM',
              'success': false
            },
          ],
        },
      ];

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
                    left: MedBuddyDimens.spacingMd,
                    right: MedBuddyDimens.spacingMd,
                    top: MedBuddyDimens.spacingMd,
                    bottom: MedBuddyDimens.bottomNavHeight +
                        MedBuddyDimens.sosBottomOffset,
                  ),
                  children: [
                    _buildSummaryBar(),
                    const SizedBox(height: MedBuddyDimens.spacingMd),
                    ..._placeholderEvents.map(_buildEventCard),
                  ],
                ),
              ),
              PatientBottomNavBar(
                activeTab: PatientNavTab.history,
                onTabSelected: (tab) {
                  if (tab == PatientNavTab.history) return;
                  switch (tab) {
                    case PatientNavTab.home:
                      Navigator.of(context).pushNamed('/home');
                    case PatientNavTab.chat:
                      Navigator.of(context).pushNamed('/ai-chat');
                    case PatientNavTab.meds:
                      Navigator.of(context).pushNamed('/medication-schedule');
                    case PatientNavTab.profile:
                      Navigator.of(context).pushNamed('/my-profile');
                    case PatientNavTab.history:
                      break;
                  }
                },
              ),
            ],
          ),
          const SOSButton(),
        ],
      ),
    );
  }

  Widget _buildAppBar(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top,
        left: MedBuddyDimens.spacingLg,
        right: MedBuddyDimens.spacingLg,
        bottom: MedBuddyDimens.spacingMd,
      ),
      decoration: const BoxDecoration(
        color: MedBuddyColors.pureWhite,
        border: Border(
            bottom: BorderSide(color: MedBuddyColors.slate300, width: 0.5)),
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(Icons.arrow_back_ios,
                color: MedBuddyColors.primary, size: 20),
          ),
          const Expanded(
              child: Text('Emergency Log',
                  style: MedBuddyTextStyles.heading3,
                  textAlign: TextAlign.center)),
          IconButton(
            onPressed: onExport,
            icon: const Icon(Icons.calendar_today_outlined,
                color: MedBuddyColors.primary),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryBar() {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: MedBuddyDimens.spacingMd,
        vertical: MedBuddyDimens.spacingMd,
      ),
      decoration: BoxDecoration(
        color: MedBuddyColors.pureWhite,
        borderRadius: BorderRadius.circular(MedBuddyDimens.radiusMd),
        border: Border.all(color: MedBuddyColors.slate300, width: 0.5),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          RichText(
            text: const TextSpan(
              children: [
                TextSpan(
                    text: '3 events',
                    style: TextStyle(
                        fontWeight: FontWeight.w700,
                        color: MedBuddyColors.slate900,
                        fontSize: 14)),
                TextSpan(
                    text: ' this month',
                    style: TextStyle(
                        color: MedBuddyColors.slate700, fontSize: 14)),
              ],
            ),
          ),
          Row(
            children: [
              _badge(MedBuddyColors.emergencyLight, MedBuddyColors.emergency,
                  'Fall x2'),
              const SizedBox(width: 8),
              _badge(MedBuddyColors.warningLight, MedBuddyColors.warning,
                  'SOS x1'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _badge(Color bg, Color text, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration:
          BoxDecoration(color: bg, borderRadius: BorderRadius.circular(20)),
      child: Text(label,
          style: TextStyle(
              fontSize: 12, color: text, fontWeight: FontWeight.w700)),
    );
  }

  Widget _buildEventCard(Map<String, dynamic> event) {
    final steps = event['steps'] as List<Map<String, dynamic>>;
    final expanded = event['expanded'] as bool;

    return Container(
      margin: const EdgeInsets.only(bottom: MedBuddyDimens.spacingMd),
      decoration: BoxDecoration(
        color: event['bgColor'] as Color,
        borderRadius: BorderRadius.circular(MedBuddyDimens.radiusLg),
        border: Border(
          left: BorderSide(color: event['borderColor'] as Color, width: 4),
          top: const BorderSide(color: MedBuddyColors.slate300, width: 0.5),
          right: const BorderSide(color: MedBuddyColors.slate300, width: 0.5),
          bottom: const BorderSide(color: MedBuddyColors.slate300, width: 0.5),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(MedBuddyDimens.spacingMd),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          _badge(
                              MedBuddyColors.emergencyLight,
                              MedBuddyColors.emergency,
                              event['type'] as String),
                          const SizedBox(width: 8),
                          Text(event['date'] as String,
                              style: MedBuddyTextStyles.caption),
                        ],
                      ),
                      const SizedBox(height: 4),
                      RichText(
                        text: TextSpan(
                          children: [
                            const TextSpan(
                                text: 'Outcome: ',
                                style: TextStyle(
                                    fontSize: 13,
                                    color: MedBuddyColors.slate700)),
                            TextSpan(
                                text: event['outcome'] as String,
                                style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                    color: event['outcomeColor'] as Color)),
                          ],
                        ),
                      ),
                      Text(event['detail'] as String,
                          style: MedBuddyTextStyles.caption),
                    ],
                  ),
                ),
                Icon(expanded ? Icons.keyboard_arrow_down : Icons.chevron_right,
                    color: MedBuddyColors.slate300),
              ],
            ),
            if (expanded && steps.isNotEmpty) ...[
              const SizedBox(height: MedBuddyDimens.spacingMd),
              ...steps
                  .asMap()
                  .entries
                  .map((e) => _buildStep(e.value, e.key == steps.length - 1)),
              const SizedBox(height: MedBuddyDimens.spacingSm),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: MedBuddyColors.emergencyLight,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.location_on_outlined,
                        color: MedBuddyColors.emergency, size: 14),
                    const SizedBox(width: 6),
                    Text('View GPS location at time of event',
                        style: MedBuddyTextStyles.caption.copyWith(
                            color: MedBuddyColors.emergency,
                            fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStep(Map<String, dynamic> step, bool isLast) {
    final success = step['success'] as bool;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                color:
                    success ? MedBuddyColors.success : MedBuddyColors.emergency,
                shape: BoxShape.circle,
              ),
              child: Icon(
                success ? Icons.check : Icons.close,
                color: MedBuddyColors.pureWhite,
                size: 10,
              ),
            ),
            if (!isLast)
              Container(width: 2, height: 22, color: MedBuddyColors.slate300),
          ],
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Padding(
            padding: EdgeInsets.only(bottom: isLast ? 0 : 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(step['desc'] as String,
                    style: MedBuddyTextStyles.caption.copyWith(
                        fontWeight: FontWeight.w600,
                        color: MedBuddyColors.slate900)),
                Text(step['time'] as String, style: MedBuddyTextStyles.caption),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
