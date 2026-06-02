import 'package:flutter/material.dart';
import '../../../constants/colors.dart';
import '../../../constants/dimens.dart';
import '../../../constants/text_styles.dart';
import '../../../services/service_interfaces.dart';
import '../../../widgets/shared/sos_button.dart';
import '../../../widgets/shared/bottom_nav_bar.dart';

/// S-24 — Emergency Event Log
class EmergencyEventLogScreen extends StatefulWidget {
  final List<EmergencyEvent> events;
  final VoidCallback? onExport;

  const EmergencyEventLogScreen({
    super.key,
    this.events = const [],
    this.onExport,
  });

  @override
  State<EmergencyEventLogScreen> createState() =>
      _EmergencyEventLogScreenState();
}

class _EmergencyEventLogScreenState extends State<EmergencyEventLogScreen> {
  final Set<String> _expanded = {};

  String _outcomeLabel(EmergencyOutcome o) {
    switch (o) {
      case EmergencyOutcome.handledByCaregiver:
        return 'Handled by Caregiver';
      case EmergencyOutcome.falseAlarm:
        return 'False Alarm';
      case EmergencyOutcome.activated911:
        return '911 Activated';
      case EmergencyOutcome.cancelled:
        return 'Cancelled';
    }
  }

  Color _outcomeColor(EmergencyOutcome o) {
    switch (o) {
      case EmergencyOutcome.activated911:
        return MedBuddyColors.emergency;
      case EmergencyOutcome.handledByCaregiver:
      case EmergencyOutcome.falseAlarm:
      case EmergencyOutcome.cancelled:
        return MedBuddyColors.success;
    }
  }

  @override
  Widget build(BuildContext context) {
    final events = widget.events;
    final fallCount =
        events.where((e) => e.type == EmergencyEventType.fallDetected).length;
    final sosCount =
        events.where((e) => e.type == EmergencyEventType.manualSOS).length;

    return Scaffold(
      backgroundColor: MedBuddyColors.warmWhite,
      body: Stack(
        children: [
          Column(
            children: [
              _buildAppBar(context),
              Expanded(
                child: events.isEmpty
                    ? _buildEmptyState()
                    : ListView(
                        padding: const EdgeInsets.only(
                          left: MedBuddyDimens.spacingMd,
                          right: MedBuddyDimens.spacingMd,
                          top: MedBuddyDimens.spacingMd,
                          bottom: MedBuddyDimens.bottomNavHeight +
                              MedBuddyDimens.sosBottomOffset,
                        ),
                        children: [
                          _buildSummaryBar(
                              events.length, fallCount, sosCount),
                          const SizedBox(height: MedBuddyDimens.spacingMd),
                          ...events.map(_buildEventCard),
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
            onPressed: widget.onExport,
            icon: const Icon(Icons.calendar_today_outlined,
                color: MedBuddyColors.primary),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(MedBuddyDimens.spacingXl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.shield_outlined,
                size: 48, color: MedBuddyColors.slate300),
            const SizedBox(height: 12),
            Text('No emergency events',
                style: MedBuddyTextStyles.bodyBold
                    .copyWith(color: MedBuddyColors.slate500)),
            const SizedBox(height: 4),
            Text('All clear. Emergency events will appear here.',
                style: MedBuddyTextStyles.secondary,
                textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryBar(int total, int falls, int sos) {
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
            text: TextSpan(
              children: [
                TextSpan(
                    text: '$total event${total == 1 ? '' : 's'}',
                    style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        color: MedBuddyColors.slate900,
                        fontSize: 14)),
                const TextSpan(
                    text: ' total',
                    style: TextStyle(
                        color: MedBuddyColors.slate700, fontSize: 14)),
              ],
            ),
          ),
          Row(
            children: [
              if (falls > 0) ...[
                _badge(MedBuddyColors.emergencyLight, MedBuddyColors.emergency,
                    'Fall x$falls'),
                const SizedBox(width: 8),
              ],
              if (sos > 0)
                _badge(MedBuddyColors.warningLight, MedBuddyColors.warning,
                    'SOS x$sos'),
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

  Widget _buildEventCard(EmergencyEvent event) {
    final isExpanded = _expanded.contains(event.id);
    final outcomeColor = _outcomeColor(event.outcome);
    final isCritical = event.outcome == EmergencyOutcome.activated911;
    final typeLabel = event.type == EmergencyEventType.fallDetected
        ? 'Fall Detected'
        : 'SOS Activated';
    final d = event.timestamp;
    final dateStr =
        '${d.month}/${d.day}/${d.year} ${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';

    return GestureDetector(
      onTap: () => setState(() {
        if (isExpanded) {
          _expanded.remove(event.id);
        } else {
          _expanded.add(event.id);
        }
      }),
      child: Container(
        margin: const EdgeInsets.only(bottom: MedBuddyDimens.spacingMd),
        decoration: BoxDecoration(
          color: isCritical ? const Color(0xFFFFF5F5) : MedBuddyColors.pureWhite,
          borderRadius: BorderRadius.circular(MedBuddyDimens.radiusLg),
          border: Border(
            left: BorderSide(color: outcomeColor, width: 4),
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
                            _badge(MedBuddyColors.emergencyLight,
                                MedBuddyColors.emergency, typeLabel),
                            const SizedBox(width: 8),
                            Text(dateStr, style: MedBuddyTextStyles.caption),
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
                                  text: _outcomeLabel(event.outcome),
                                  style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w700,
                                      color: outcomeColor)),
                            ],
                          ),
                        ),
                        if (event.gpsCoordinates != null)
                          Text('GPS: ${event.gpsCoordinates}',
                              style: MedBuddyTextStyles.caption),
                      ],
                    ),
                  ),
                  Icon(
                      isExpanded
                          ? Icons.keyboard_arrow_down
                          : Icons.chevron_right,
                      color: MedBuddyColors.slate300),
                ],
              ),
              if (isExpanded && event.steps.isNotEmpty) ...[
                const SizedBox(height: MedBuddyDimens.spacingMd),
                ...event.steps.asMap().entries.map(
                    (e) => _buildStep(e.value, e.key == event.steps.length - 1)),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStep(EmergencyStep step, bool isLast) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                color: step.success
                    ? MedBuddyColors.success
                    : MedBuddyColors.emergency,
                shape: BoxShape.circle,
              ),
              child: Icon(
                step.success ? Icons.check : Icons.close,
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
                Text(step.description,
                    style: MedBuddyTextStyles.caption.copyWith(
                        fontWeight: FontWeight.w600,
                        color: MedBuddyColors.slate900)),
                Text(
                    '${step.timestamp.hour.toString().padLeft(2, '0')}:${step.timestamp.minute.toString().padLeft(2, '0')}',
                    style: MedBuddyTextStyles.caption),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
