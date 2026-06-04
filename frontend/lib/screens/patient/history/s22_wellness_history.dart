import 'package:flutter/material.dart';
import '../../../constants/colors.dart';
import '../../../constants/dimens.dart';
import '../../../constants/text_styles.dart';
import '../../../services/service_interfaces.dart';
import '../../../widgets/shared/sos_button.dart';
import '../../../widgets/shared/bottom_nav_bar.dart';

/// S-22 — Wellness History

class WellnessHistoryScreen extends StatefulWidget {
  final List<WellnessCheckIn> checkIns;
  final VoidCallback? onExport;
  final ValueChanged<int>? onDateRangeChanged; // days: 7, 30, 90

  const WellnessHistoryScreen({
    super.key,
    this.checkIns = const [],
    this.onExport,
    this.onDateRangeChanged,
  });

  @override
  State<WellnessHistoryScreen> createState() => _WellnessHistoryScreenState();
}

class _WellnessHistoryScreenState extends State<WellnessHistoryScreen> {
  int _selectedRange = 7;
  final List<int> _ranges = [7, 30, 90];
  final List<String> _rangeLabels = ['7 Days', '30 Days', '3 Months'];

  List<WellnessCheckIn> get _filtered {
    final cutoff = DateTime.now().subtract(Duration(days: _selectedRange));
    final list = widget.checkIns
        .where((c) => c.timestamp.isAfter(cutoff))
        .toList()
      ..sort((a, b) => a.timestamp.compareTo(b.timestamp));
    return list;
  }

  List<double> get _moodData =>
      _filtered.map((c) => c.mood.toDouble()).toList();
  List<double> get _energyData =>
      _filtered.map((c) => c.energy.toDouble()).toList();
  List<double> get _painData =>
      _filtered.map((c) => c.painLevel.toDouble()).toList();

  List<String> get _dayLabels => _filtered.map((c) {
        final d = c.timestamp;
        return '${d.month}/${d.day}';
      }).toList();

  String get _aiInsight {
    final data = _filtered;
    if (data.length < 2) return 'Add more check-ins to see trends.';
    final recent = data.reversed.take(3).toList();
    final avgPain =
        recent.fold(0, (sum, c) => sum + c.painLevel) / recent.length;
    final avgMood =
        recent.fold(0, (sum, c) => sum + c.mood) / recent.length;
    final flagged = data.where((c) => c.isFlagged).length;
    if (flagged > 0) {
      return '$flagged check-in(s) were flagged recently. Consider contacting your doctor.';
    }
    if (avgPain > 5) {
      return 'Pain levels have been elevated recently. Consider checking in with your doctor.';
    }
    if (avgMood >= 4) {
      return 'Your mood has been good lately. Keep it up!';
    }
    return 'Your wellness looks stable. Keep checking in daily.';
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
              _buildDateRangeTabs(),
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
                    _buildHistoryLinks(),
                    const SizedBox(height: MedBuddyDimens.spacingLg),
                    ...(_filtered.isEmpty
                        ? [_buildEmptyState()]
                        : [
                            _buildAIInsightCard(),
                            const SizedBox(height: MedBuddyDimens.spacingMd),
                            if (_moodData.length > 1)
                              _buildChart('Mood', _moodData, 5,
                                  isAnomaly: false),
                            if (_moodData.length > 1)
                              const SizedBox(height: MedBuddyDimens.spacingMd),
                            if (_energyData.length > 1)
                              _buildChart('Energy', _energyData, 5,
                                  isAnomaly: false),
                            if (_energyData.length > 1)
                              const SizedBox(height: MedBuddyDimens.spacingMd),
                            if (_painData.length > 1)
                              _buildChart('Pain Level', _painData, 10,
                                  isAnomaly: true),
                            if (_painData.length > 1)
                              const SizedBox(height: MedBuddyDimens.spacingMd),
                            _buildCheckInList(),
                          ]),
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

  Widget _buildHistoryLinks() {
    final items = <(String, IconData, String)>[
      ('Symptom Log', Icons.note_alt_outlined, '/symptom-log'),
      ('Medications', Icons.medication_outlined, '/med-adherence'),
      ('Emergencies', Icons.warning_amber_outlined, '/emergency-log'),
      ('Visit Summary', Icons.description_outlined, '/visit-summary'),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('MORE HISTORY', style: MedBuddyTextStyles.sectionHeader),
        const SizedBox(height: MedBuddyDimens.spacingSm),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: items.map((it) {
            return GestureDetector(
              onTap: () => Navigator.of(context).pushNamed(it.$3),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: MedBuddyColors.primarySoft,
                  borderRadius: BorderRadius.circular(MedBuddyDimens.radiusMd),
                  border: Border.all(color: MedBuddyColors.primaryLight),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(it.$2, size: 16, color: MedBuddyColors.primary),
                    const SizedBox(width: 6),
                    Text(it.$1,
                        style: MedBuddyTextStyles.label.copyWith(
                            color: MedBuddyColors.primaryDark,
                            fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ],
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
              child: Text('Wellness History',
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

  Widget _buildDateRangeTabs() {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: MedBuddyDimens.spacingMd,
        vertical: MedBuddyDimens.spacingSm,
      ),
      decoration: const BoxDecoration(
        color: MedBuddyColors.pureWhite,
        border: Border(
            bottom: BorderSide(color: MedBuddyColors.slate300, width: 0.5)),
      ),
      child: Row(
        children: List.generate(_ranges.length, (i) {
          final isSelected = _selectedRange == _ranges[i];
          return Expanded(
            child: GestureDetector(
              onTap: () {
                setState(() => _selectedRange = _ranges[i]);
                widget.onDateRangeChanged?.call(_ranges[i]);
              },
              child: Container(
                margin: EdgeInsets.only(right: i < _ranges.length - 1 ? 8 : 0),
                padding: const EdgeInsets.symmetric(vertical: 7),
                decoration: BoxDecoration(
                  color: isSelected
                      ? MedBuddyColors.primary
                      : MedBuddyColors.slate100,
                  borderRadius:
                      BorderRadius.circular(MedBuddyDimens.radiusPill),
                ),
                child: Text(
                  _rangeLabels[i],
                  textAlign: TextAlign.center,
                  style: MedBuddyTextStyles.label.copyWith(
                    color: isSelected
                        ? MedBuddyColors.pureWhite
                        : MedBuddyColors.slate500,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildAIInsightCard() {
    return Container(
      padding: const EdgeInsets.all(MedBuddyDimens.spacingMd),
      decoration: BoxDecoration(
        color: MedBuddyColors.primarySoft,
        borderRadius: BorderRadius.circular(MedBuddyDimens.radiusLg),
        border: const Border(
            left: BorderSide(color: MedBuddyColors.primary, width: 4)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: MedBuddyColors.primary,
              borderRadius: BorderRadius.circular(MedBuddyDimens.radiusSm),
            ),
            child: const Icon(Icons.lightbulb_outline,
                color: MedBuddyColors.pureWhite, size: 14),
          ),
          const SizedBox(width: MedBuddyDimens.spacingMd),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('AI Insight',
                    style: MedBuddyTextStyles.label.copyWith(
                        fontWeight: FontWeight.w700,
                        color: MedBuddyColors.primaryDark)),
                const SizedBox(height: 4),
                Text(
                  _aiInsight,
                  style: MedBuddyTextStyles.label
                      .copyWith(color: MedBuddyColors.slate700),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChart(String title, List<double> data, double maxValue,
      {required bool isAnomaly}) {
    // Detect anomaly threshold — any value > 70% of max considered anomaly
    final anomalyThreshold = maxValue * 0.6;
    final hasAnomaly = isAnomaly && data.any((v) => v > anomalyThreshold);

    return Container(
      padding: const EdgeInsets.all(MedBuddyDimens.spacingMd),
      decoration: BoxDecoration(
        color:
            hasAnomaly ? const Color(0xFFFFF5F5) : MedBuddyColors.primarySoft,
        borderRadius: BorderRadius.circular(MedBuddyDimens.radiusLg),
        border: Border.all(
          color: hasAnomaly
              ? MedBuddyColors.emergencyLight
              : MedBuddyColors.primaryLight,
          width: 0.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Text(title,
                      style: MedBuddyTextStyles.label.copyWith(
                        fontWeight: FontWeight.w700,
                        color: hasAnomaly
                            ? const Color(0xFF991B1B)
                            : MedBuddyColors.primaryDark,
                      )),
                  if (hasAnomaly) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: MedBuddyColors.emergencyLight,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text('Flagged',
                          style: MedBuddyTextStyles.caption.copyWith(
                              color: MedBuddyColors.emergency,
                              fontWeight: FontWeight.w700)),
                    ),
                  ],
                ],
              ),
              Text('out of ${maxValue.toInt()}',
                  style: MedBuddyTextStyles.caption),
            ],
          ),
          const SizedBox(height: MedBuddyDimens.spacingMd),
          SizedBox(
            height: 80,
            child: CustomPaint(
              size: const Size(double.infinity, 80),
              painter: _LineChartPainter(
                data: data,
                maxValue: maxValue,
                anomalyThreshold:
                    isAnomaly ? anomalyThreshold : double.infinity,
                dayLabels: _dayLabels,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 60),
      child: Center(
        child: Column(
          children: [
            const Icon(Icons.monitor_heart_outlined,
                size: 48, color: MedBuddyColors.slate300),
            const SizedBox(height: 12),
            Text('No check-ins yet',
                style: MedBuddyTextStyles.bodyBold
                    .copyWith(color: MedBuddyColors.slate500)),
            const SizedBox(height: 4),
            Text('Complete your first daily check-in to see trends here.',
                style: MedBuddyTextStyles.secondary,
                textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }

  Widget _buildCheckInList() {
    final items = _filtered.reversed.toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Recent Check-ins', style: MedBuddyTextStyles.bodyBold),
        const SizedBox(height: MedBuddyDimens.spacingSm),
        ...items.map(_checkInCard).toList(),
      ],
    );
  }

  Widget _checkInCard(WellnessCheckIn c) {
    final Color borderColor = c.isFlagged
        ? MedBuddyColors.emergency
        : c.painLevel >= 5
            ? MedBuddyColors.warning
            : MedBuddyColors.success;
    final d = c.timestamp;
    final dateStr =
        '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
    return Container(
      margin: const EdgeInsets.only(bottom: MedBuddyDimens.spacingSm),
      padding: const EdgeInsets.all(MedBuddyDimens.spacingMd),
      decoration: BoxDecoration(
        color: c.isFlagged
            ? MedBuddyColors.emergencyLight
            : MedBuddyColors.pureWhite,
        borderRadius: BorderRadius.circular(MedBuddyDimens.radiusMd),
        border: Border(left: BorderSide(color: borderColor, width: 4)),
        boxShadow: [
          BoxShadow(
              color: MedBuddyColors.slate300.withValues(alpha: 0.2),
              blurRadius: 4)
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(dateStr,
                        style:
                            MedBuddyTextStyles.bodyBold.copyWith(fontSize: 14)),
                    if (c.isFlagged) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 7, vertical: 1),
                        decoration: BoxDecoration(
                          color: MedBuddyColors.emergencyLight,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text('Flagged',
                            style: MedBuddyTextStyles.caption.copyWith(
                                color: MedBuddyColors.emergency,
                                fontWeight: FontWeight.w700)),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  'Mood ${c.mood}/5 · Pain ${c.painLevel}/10 · Sleep ${c.sleepQuality}',
                  style: MedBuddyTextStyles.caption,
                ),
              ],
            ),
          ),
          const Icon(Icons.chevron_right, color: MedBuddyColors.slate300),
        ],
      ),
    );
  }
}

class _LineChartPainter extends CustomPainter {
  final List<double> data;
  final double maxValue;
  final double anomalyThreshold;
  final List<String> dayLabels;

  _LineChartPainter({
    required this.data,
    required this.maxValue,
    required this.anomalyThreshold,
    required this.dayLabels,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (data.isEmpty) return;

    final chartHeight = size.height - 20; // reserve space for labels
    final stepX = size.width / (data.length - 1);

    // Build points
    final points = List.generate(data.length, (i) {
      final x = i * stepX;
      final y = chartHeight - (data[i] / maxValue) * chartHeight;
      return Offset(x, y);
    });

    // Draw segments with color based on anomaly
    for (int i = 0; i < points.length - 1; i++) {
      final isAnomalySegment =
          data[i] > anomalyThreshold || data[i + 1] > anomalyThreshold;
      final paint = Paint()
        ..color =
            isAnomalySegment ? MedBuddyColors.emergency : MedBuddyColors.primary
        ..strokeWidth = 2.5
        ..strokeCap = StrokeCap.round
        ..style = PaintingStyle.stroke;
      canvas.drawLine(points[i], points[i + 1], paint);
    }

    // Draw dots
    for (int i = 0; i < points.length; i++) {
      final isAnomaly = data[i] > anomalyThreshold;
      final dotPaint = Paint()
        ..color = isAnomaly ? MedBuddyColors.emergency : MedBuddyColors.primary
        ..style = PaintingStyle.fill;
      canvas.drawCircle(points[i], isAnomaly ? 5.0 : 3.5, dotPaint);
      if (isAnomaly) {
        final borderPaint = Paint()
          ..color = Colors.white
          ..strokeWidth = 1.5
          ..style = PaintingStyle.stroke;
        canvas.drawCircle(points[i], 5.0, borderPaint);
      }
    }

    // Draw day labels
    const textStyle = TextStyle(fontSize: 9, color: MedBuddyColors.slate500);
    for (int i = 0; i < dayLabels.length && i < points.length; i++) {
      final tp = TextPainter(
        text: TextSpan(text: dayLabels[i], style: textStyle),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, Offset(points[i].dx - tp.width / 2, size.height - 16));
    }
  }

  @override
  bool shouldRepaint(_LineChartPainter old) =>
      old.data != data || old.maxValue != maxValue;
}
