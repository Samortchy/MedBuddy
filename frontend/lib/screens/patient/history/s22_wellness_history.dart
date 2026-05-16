import 'package:flutter/material.dart';
import '../../../constants/colors.dart';
import '../../../constants/dimens.dart';
import '../../../constants/text_styles.dart';
import '../../../services/service_interfaces.dart';
import '../../../widgets/shared/sos_button.dart';
import '../../../widgets/shared/bottom_nav_bar.dart';

/// S-22 — Wellness History
///
/// Backend hooks:
/// - [checkIns] → List<WellnessCheckIn> from your data layer
/// - [onExport] → Called to generate PDF report (wire to your PDF service)
/// - [onDateRangeChanged] → Fetch new data for selected range
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
  int _selectedRange = 7; // days
  final List<int> _ranges = [7, 30, 90];
  final List<String> _rangeLabels = ['7 Days', '30 Days', '3 Months'];

  // Placeholder data — replace with real data from widget.checkIns
  final List<Map<String, dynamic>> _placeholderCheckIns = [
    {
      'date': 'Apr 5 — Morning',
      'mood': 4,
      'pain': 2,
      'sleep': 'good',
      'flagged': false
    },
    {
      'date': 'Apr 4 — Morning',
      'mood': 3,
      'pain': 5,
      'sleep': 'fair',
      'flagged': false
    },
    {
      'date': 'Apr 3 — Morning',
      'mood': 2,
      'pain': 8,
      'sleep': 'poor',
      'flagged': true
    },
  ];

  // Chart data — replace with derived data from widget.checkIns
  final List<double> _moodData = [3, 4, 3.5, 5, 4, 4.5, 4];
  final List<double> _energyData = [4, 3.5, 4.5, 2.5, 3.5, 3, 4];
  final List<double> _painData = [2, 2.5, 3, 8, 7, 6.5, 3];
  final List<String> _dayLabels = [
    'Mon',
    'Tue',
    'Wed',
    'Thu',
    'Fri',
    'Sat',
    'Sun'
  ];

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
                    _buildAIInsightCard(),
                    const SizedBox(height: MedBuddyDimens.spacingMd),
                    _buildChart('Mood', _moodData, 5, isAnomaly: false),
                    const SizedBox(height: MedBuddyDimens.spacingMd),
                    _buildChart('Energy', _energyData, 5, isAnomaly: false),
                    const SizedBox(height: MedBuddyDimens.spacingMd),
                    _buildChart('Pain Level', _painData, 10, isAnomaly: true),
                    const SizedBox(height: MedBuddyDimens.spacingMd),
                    _buildCheckInList(),
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
                // TODO: Replace with real AI-generated insight from your backend
                Text(
                  'Pain scores increased on 3 consecutive days. Consider checking in with your doctor.',
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

  Widget _buildCheckInList() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Recent Check-ins', style: MedBuddyTextStyles.bodyBold),
        const SizedBox(height: MedBuddyDimens.spacingSm),
        ...(_placeholderCheckIns.isEmpty
            ? widget.checkIns.map(_checkInFromModel).toList()
            : _placeholderCheckIns.map(_checkInFromMap).toList()),
      ],
    );
  }

  Widget _checkInFromMap(Map<String, dynamic> data) {
    final flagged = data['flagged'] as bool;
    final declining = (data['pain'] as int) >= 5 && !flagged;
    Color borderColor = flagged
        ? MedBuddyColors.emergency
        : declining
            ? MedBuddyColors.warning
            : MedBuddyColors.success;

    return Container(
      margin: const EdgeInsets.only(bottom: MedBuddyDimens.spacingSm),
      padding: const EdgeInsets.all(MedBuddyDimens.spacingMd),
      decoration: BoxDecoration(
        color:
            flagged ? MedBuddyColors.emergencyLight : MedBuddyColors.pureWhite,
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
                    Text(data['date'],
                        style:
                            MedBuddyTextStyles.bodyBold.copyWith(fontSize: 14)),
                    if (flagged) ...[
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
                  'Mood ${data['mood']}/5 · Pain ${data['pain']}/10 · Sleep ${data['sleep']}',
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

  Widget _checkInFromModel(WellnessCheckIn checkIn) {
    // TODO: wire real data model display
    return _checkInFromMap({
      'date': checkIn.timestamp.toString(),
      'mood': checkIn.mood,
      'pain': checkIn.painLevel,
      'sleep': checkIn.sleepQuality,
      'flagged': checkIn.isFlagged,
    });
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
