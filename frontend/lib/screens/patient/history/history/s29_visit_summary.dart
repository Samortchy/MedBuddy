import 'package:flutter/material.dart';
import '../../../constants/colors.dart';
import '../../../constants/dimens.dart';
import '../../../constants/text_styles.dart';
import '../../../widgets/shared/sos_button.dart';

/// S-29 — Visit Summary Recorder (Phase 5 Shell)
///
/// Backend hooks:
/// - [existingSummary]  → VisitSummary? if a previous summary exists
/// - [onStartRecording] → Start audio recording (wire to Faster-Whisper STT)
/// - [onStopRecording]  → Stop recording and send to AI for structuring
/// - [onShare]          → Share/export the AI-structured summary as PDF
class VisitSummaryScreen extends StatefulWidget {
  final VisitSummary? existingSummary;
  final VoidCallback? onStartRecording;
  final VoidCallback? onStopRecording;
  final VoidCallback? onShare;

  const VisitSummaryScreen({
    super.key,
    this.existingSummary,
    this.onStartRecording,
    this.onStopRecording,
    this.onShare,
  });

  @override
  State<VisitSummaryScreen> createState() => _VisitSummaryScreenState();
}

class _VisitSummaryScreenState extends State<VisitSummaryScreen>
    with SingleTickerProviderStateMixin {
  bool _isRecording = false;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  // Placeholder summary — remove when real data is wired via widget.existingSummary
  final VisitSummary _placeholderSummary = const VisitSummary(
    date: 'Apr 3, 2026',
    diagnosis: 'Type 2 Diabetes — stable. Blood pressure slightly elevated.',
    medicationsChanged: 'Lisinopril increased from 10mg to 20mg daily.',
    instructions:
        'Reduce salt intake. Walk 20 minutes daily. Monitor BP at home.',
    nextAppointment: 'May 3, 2026 — Dr. Karim, 10:00 AM',
  );

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
    _pulseAnimation = Tween<double>(begin: 0.95, end: 1.1).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  void _toggleRecording() {
    if (_isRecording) {
      setState(() => _isRecording = false);
      widget.onStopRecording?.call();
    } else {
      setState(() => _isRecording = true);
      widget.onStartRecording?.call();
    }
  }

  VisitSummary? get _summary => widget.existingSummary ?? _placeholderSummary;

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
                child: SingleChildScrollView(
                  padding: const EdgeInsets.only(
                    left: MedBuddyDimens.spacingLg,
                    right: MedBuddyDimens.spacingLg,
                    top: MedBuddyDimens.spacingXl,
                    bottom: MedBuddyDimens.bottomNavHeight +
                        MedBuddyDimens.sosBottomOffset,
                  ),
                  child: Column(
                    children: [
                      _buildInstruction(),
                      const SizedBox(height: MedBuddyDimens.spacingXl),
                      _buildHeroRecordButton(),
                      const SizedBox(height: MedBuddyDimens.spacingXl),
                      _buildPlaybackSection(),
                      const SizedBox(height: MedBuddyDimens.spacingXl),
                      if (_summary != null) _buildSummaryCard(_summary!),
                      const SizedBox(height: MedBuddyDimens.spacingXl),
                      _buildShareButton(),
                    ],
                  ),
                ),
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
              child: Text('Visit Summary',
                  style: MedBuddyTextStyles.heading3,
                  textAlign: TextAlign.center)),
          const SizedBox(width: 36),
        ],
      ),
    );
  }

  Widget _buildInstruction() {
    return Text(
      'After your appointment, tap record and describe what happened. '
      'MedBuddy will organise it for you.',
      style: MedBuddyTextStyles.body.copyWith(color: MedBuddyColors.slate500),
      textAlign: TextAlign.center,
    );
  }

  Widget _buildHeroRecordButton() {
    return Column(
      children: [
        ScaleTransition(
          scale: _isRecording
              ? _pulseAnimation
              : const AlwaysStoppedAnimation(1.0),
          child: Stack(
            alignment: Alignment.center,
            children: [
              if (_isRecording) ...[
                Container(
                  width: 110,
                  height: 110,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                        color: MedBuddyColors.primaryLight, width: 2),
                  ),
                ),
                Container(
                  width: 90,
                  height: 90,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border:
                        Border.all(color: MedBuddyColors.primaryMid, width: 2),
                  ),
                ),
              ],
              GestureDetector(
                onTap: _toggleRecording,
                child: Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    color: _isRecording
                        ? MedBuddyColors.emergency
                        : MedBuddyColors.primary,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    _isRecording ? Icons.stop : Icons.mic_none,
                    color: MedBuddyColors.pureWhite,
                    size: 32,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: MedBuddyDimens.spacingMd),
        Text(
          _isRecording ? 'Recording... tap to stop' : 'Tap to Record',
          style: MedBuddyTextStyles.body.copyWith(
            color: _isRecording
                ? MedBuddyColors.emergency
                : MedBuddyColors.primary,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildPlaybackSection() {
    final hasRecording = _summary != null;
    return Opacity(
      opacity: hasRecording ? 1.0 : 0.4,
      child: Container(
        padding: const EdgeInsets.all(MedBuddyDimens.spacingMd),
        decoration: BoxDecoration(
          color: MedBuddyColors.pureWhite,
          borderRadius: BorderRadius.circular(MedBuddyDimens.radiusLg),
          border: Border.all(color: MedBuddyColors.slate300, width: 0.5),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            if (!hasRecording)
              const Text('Record a visit first',
                  style: MedBuddyTextStyles.caption,
                  textAlign: TextAlign.center),
            const SizedBox(height: 8),
            Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: hasRecording
                        ? MedBuddyColors.primary
                        : MedBuddyColors.slate100,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.play_arrow,
                      color: hasRecording
                          ? MedBuddyColors.pureWhite
                          : MedBuddyColors.slate300,
                      size: 18),
                ),
                const SizedBox(width: MedBuddyDimens.spacingMd),
                Expanded(
                  child: Row(
                    children: [
                      8.0,
                      14.0,
                      20.0,
                      12.0,
                      18.0,
                      10.0,
                      8.0,
                      14.0,
                      10.0,
                      6.0,
                      12.0
                    ]
                        .map((h) => Container(
                              width: 3,
                              height: h,
                              margin: const EdgeInsets.symmetric(horizontal: 1),
                              decoration: BoxDecoration(
                                color: hasRecording
                                    ? MedBuddyColors.primary
                                    : MedBuddyColors.slate300,
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ))
                        .toList(),
                  ),
                ),
                const SizedBox(width: MedBuddyDimens.spacingMd),
                Text(hasRecording ? '1:32' : '0:00',
                    style: MedBuddyTextStyles.label
                        .copyWith(color: MedBuddyColors.slate500)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryCard(VisitSummary summary) {
    return Container(
      padding: const EdgeInsets.all(MedBuddyDimens.spacingMd),
      decoration: BoxDecoration(
        color: MedBuddyColors.primarySoft,
        borderRadius: BorderRadius.circular(MedBuddyDimens.radiusLg),
        border: Border.all(color: MedBuddyColors.primaryLight, width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.auto_awesome_outlined,
                  color: MedBuddyColors.primary, size: 16),
              const SizedBox(width: 8),
              Text('Visit Summary — ${summary.date}',
                  style: MedBuddyTextStyles.label.copyWith(
                      fontWeight: FontWeight.w700,
                      color: MedBuddyColors.primaryDark)),
            ],
          ),
          const Divider(color: MedBuddyColors.primaryLight, height: 16),
          _summaryField('DIAGNOSIS', summary.diagnosis),
          _summaryField('MEDICATIONS CHANGED', summary.medicationsChanged),
          _summaryField("DOCTOR'S INSTRUCTIONS", summary.instructions),
          _summaryField('NEXT APPOINTMENT', summary.nextAppointment,
              isLast: true),
        ],
      ),
    );
  }

  Widget _summaryField(String label, String value, {bool isLast = false}) {
    return Padding(
      padding: EdgeInsets.only(bottom: isLast ? 0 : MedBuddyDimens.spacingMd),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: MedBuddyTextStyles.sectionHeader),
          const SizedBox(height: 3),
          Text(value,
              style: MedBuddyTextStyles.label
                  .copyWith(color: MedBuddyColors.slate700)),
        ],
      ),
    );
  }

  Widget _buildShareButton() {
    return GestureDetector(
      onTap: widget.onShare,
      child: Container(
        height: MedBuddyDimens.buttonHeightPrimary,
        decoration: BoxDecoration(
          border: Border.all(color: MedBuddyColors.primary, width: 1.5),
          borderRadius: BorderRadius.circular(MedBuddyDimens.radiusMd),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.share_outlined,
                color: MedBuddyColors.primary, size: 18),
            const SizedBox(width: MedBuddyDimens.spacingMd),
            Text('Share Summary',
                style: MedBuddyTextStyles.body.copyWith(
                    color: MedBuddyColors.primary,
                    fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }
}

/// Data model for a visit summary.
/// Move to service_interfaces.dart if you need it shared across screens.
class VisitSummary {
  final String date;
  final String diagnosis;
  final String medicationsChanged;
  final String instructions;
  final String nextAppointment;

  const VisitSummary({
    required this.date,
    required this.diagnosis,
    required this.medicationsChanged,
    required this.instructions,
    required this.nextAppointment,
  });
}
