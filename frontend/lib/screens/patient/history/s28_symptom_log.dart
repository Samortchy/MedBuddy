import 'package:flutter/material.dart';
import '../../../constants/colors.dart';
import '../../../constants/dimens.dart';
import '../../../constants/text_styles.dart';
import '../../../services/service_interfaces.dart';
import '../../../widgets/shared/sos_button.dart';
import '../../../widgets/shared/bottom_nav_bar.dart';

/// S-28 — Symptom Log (Phase 5 Shell)
///
/// Backend hooks:
/// - [entries]       → List<SymptomEntry> from your data layer
/// - [onAddEntry]    → Called with text description to save a new entry
/// - [onVoiceRecord] → Called to start voice-based entry (Phase 5 full)
/// - [onExport]      → Export symptom timeline as report
class SymptomLogScreen extends StatefulWidget {
  final List<SymptomEntry> entries;
  final Future<void> Function(String description)? onAddEntry;
  final VoidCallback? onVoiceRecord;
  final VoidCallback? onExport;

  const SymptomLogScreen({
    super.key,
    this.entries = const [],
    this.onAddEntry,
    this.onVoiceRecord,
    this.onExport,
  });

  @override
  State<SymptomLogScreen> createState() => _SymptomLogScreenState();
}

class _SymptomLogScreenState extends State<SymptomLogScreen> {
  // Placeholder entries — replace with widget.entries when backend is wired
  final List<Map<String, dynamic>> _placeholderEntries = [
    {
      'date': 'Apr 5',
      'description': 'Mild headache in the morning, went away after breakfast.',
      'severity': SymptomSeverity.normal,
    },
    {
      'date': 'Apr 1',
      'description':
          'Shortness of breath after walking upstairs. Lasted about 10 minutes.',
      'severity': SymptomSeverity.flagged,
    },
    {
      'date': 'Mar 29',
      'description': 'Feeling more tired than usual. No specific symptoms.',
      'severity': SymptomSeverity.watch,
    },
    {
      'date': 'Mar 26',
      'description':
          'Slight joint stiffness in the morning. Felt better after moving around.',
      'severity': SymptomSeverity.normal,
    },
  ];

  void _showAddEntrySheet() {
    final controller = TextEditingController();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          left: 16,
          right: 16,
          top: 16,
          bottom: MediaQuery.of(context).viewInsets.bottom + 16,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Today's Symptom Entry",
                style: MedBuddyTextStyles.heading3),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              maxLines: 4,
              style: MedBuddyTextStyles.body,
              decoration: InputDecoration(
                hintText: 'Describe how you are feeling...',
                hintStyle: MedBuddyTextStyles.body
                    .copyWith(color: MedBuddyColors.slate500),
                filled: true,
                fillColor: MedBuddyColors.slate100,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              height: MedBuddyDimens.buttonHeightPrimary,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: MedBuddyColors.primary,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: () async {
                  final text = controller.text.trim();
                  if (text.isNotEmpty) {
                    await widget.onAddEntry?.call(text);
                    if (context.mounted) Navigator.pop(context);
                  }
                },
                child: Text('Save Entry',
                    style: MedBuddyTextStyles.bodyBold
                        .copyWith(color: MedBuddyColors.pureWhite)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: MedBuddyColors.warmWhite,
      body: Stack(
        children: [
          Column(
            children: [
              _buildAppBar(),
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
                    _buildAddButton(),
                    const SizedBox(height: MedBuddyDimens.spacingMd),
                    const Text('Recent Entries',
                        style: MedBuddyTextStyles.bodyBold),
                    const SizedBox(height: MedBuddyDimens.spacingMd),
                    _buildTimeline(),
                    const SizedBox(height: MedBuddyDimens.spacingMd),
                    _buildComingSoonBanner(),
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

  Widget _buildAppBar() {
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
              child: Text('Symptom Log',
                  style: MedBuddyTextStyles.heading3,
                  textAlign: TextAlign.center)),
          IconButton(
            onPressed: widget.onExport,
            icon: const Icon(Icons.download_outlined,
                color: MedBuddyColors.primary),
          ),
        ],
      ),
    );
  }

  Widget _buildAddButton() {
    return GestureDetector(
      onTap: () {
        // TODO: Phase 5 — prioritize voice. For now open text sheet.
        widget.onVoiceRecord != null
            ? widget.onVoiceRecord!()
            : _showAddEntrySheet();
      },
      child: Container(
        height: MedBuddyDimens.buttonHeightPrimary,
        decoration: BoxDecoration(
          color: MedBuddyColors.primary,
          borderRadius: BorderRadius.circular(MedBuddyDimens.radiusLg),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.mic_none,
                color: MedBuddyColors.pureWhite, size: 22),
            const SizedBox(width: MedBuddyDimens.spacingMd),
            Text("Add Today's Entry",
                style: MedBuddyTextStyles.bodyBold
                    .copyWith(color: MedBuddyColors.pureWhite)),
          ],
        ),
      ),
    );
  }

  Widget _buildTimeline() {
    final entries = widget.entries.isEmpty
        ? _placeholderEntries
        : widget.entries
            .map((e) => {
                  'date': '${e.timestamp.month}/${e.timestamp.day}',
                  'description': e.description,
                  'severity': e.severity,
                })
            .toList();

    return Stack(
      children: [
        Positioned(
          left: 9,
          top: 10,
          bottom: 10,
          child: Container(width: 2, color: MedBuddyColors.primaryLight),
        ),
        Column(
          children: entries.asMap().entries.map((e) {
            return _buildTimelineEntry(e.value, e.key == entries.length - 1);
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildTimelineEntry(Map<String, dynamic> entry, bool isLast) {
    final severity = entry['severity'] as SymptomSeverity;
    Color dotColor;
    Color cardBg;
    Color cardBorder;
    String? badge;
    Color? badgeBg;
    Color? badgeText;

    switch (severity) {
      case SymptomSeverity.flagged:
        dotColor = MedBuddyColors.emergency;
        cardBg = const Color(0xFFFFF5F5);
        cardBorder = MedBuddyColors.emergencyLight;
        badge = 'Flagged';
        badgeBg = MedBuddyColors.emergencyLight;
        badgeText = MedBuddyColors.emergency;
        break;
      case SymptomSeverity.watch:
        dotColor = MedBuddyColors.warning;
        cardBg = const Color(0xFFFFFBEB);
        cardBorder = const Color(0xFFFDE68A);
        badge = 'Watch';
        badgeBg = MedBuddyColors.warningLight;
        badgeText = MedBuddyColors.warning;
        break;
      case SymptomSeverity.normal:
        dotColor = MedBuddyColors.primary;
        cardBg = MedBuddyColors.pureWhite;
        cardBorder = MedBuddyColors.slate300;
        break;
    }

    return Padding(
      padding: EdgeInsets.only(bottom: isLast ? 0 : MedBuddyDimens.spacingLg),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 20,
            height: 20,
            decoration: BoxDecoration(
              color: dotColor,
              shape: BoxShape.circle,
              border: Border.all(color: MedBuddyColors.warmWhite, width: 2),
            ),
          ),
          const SizedBox(width: MedBuddyDimens.spacingMd),
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(MedBuddyDimens.spacingMd),
              decoration: BoxDecoration(
                color: cardBg,
                borderRadius: BorderRadius.circular(MedBuddyDimens.radiusMd),
                border: Border.all(color: cardBorder, width: 0.5),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        entry['date'] as String,
                        style: MedBuddyTextStyles.label.copyWith(
                          fontWeight: FontWeight.w700,
                          color: severity == SymptomSeverity.flagged
                              ? MedBuddyColors.emergency
                              : severity == SymptomSeverity.watch
                                  ? MedBuddyColors.warning
                                  : MedBuddyColors.primary,
                        ),
                      ),
                      if (badge != null)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 2),
                          decoration: BoxDecoration(
                            color: badgeBg,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(badge,
                              style: MedBuddyTextStyles.caption.copyWith(
                                  color: badgeText,
                                  fontWeight: FontWeight.w700)),
                        ),
                    ],
                  ),
                  const SizedBox(height: MedBuddyDimens.spacingSm),
                  Text(entry['description'] as String,
                      style: MedBuddyTextStyles.label
                          .copyWith(color: MedBuddyColors.slate700)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildComingSoonBanner() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: MedBuddyColors.primarySoft,
        borderRadius: BorderRadius.circular(MedBuddyDimens.radiusMd),
        border: Border.all(
            color: MedBuddyColors.primary, width: 1, style: BorderStyle.solid),
      ),
      child: Row(
        children: [
          const Icon(Icons.schedule_outlined,
              color: MedBuddyColors.primary, size: 18),
          const SizedBox(width: MedBuddyDimens.spacingMd),
          Text('Full voice journaling coming in Phase 5',
              style: MedBuddyTextStyles.label
                  .copyWith(color: MedBuddyColors.primaryDark)),
        ],
      ),
    );
  }
}
