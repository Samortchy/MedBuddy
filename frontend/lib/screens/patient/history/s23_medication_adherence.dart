import 'package:flutter/material.dart';
import '../../../utils/nav_helpers.dart';
import '../../../constants/colors.dart';
import '../../../constants/dimens.dart';
import '../../../constants/text_styles.dart';
import '../../../services/service_interfaces.dart';
import '../../../widgets/shared/sos_button.dart';
import '../../../widgets/shared/bottom_nav_bar.dart';

/// S-23 — Medication Adherence History
class MedicationAdherenceScreen extends StatefulWidget {
  final List<MedicationEntry> medications;
  final Map<DateTime, MedicationStatus> calendarData;
  final int adherencePercent;
  final int takenOnTime;
  final int takenLate;
  final int missed;
  final ValueChanged<DateTime>? onDayTapped;
  final VoidCallback? onExport;

  const MedicationAdherenceScreen({
    super.key,
    this.medications = const [],
    this.calendarData = const {},
    this.adherencePercent = 87,
    this.takenOnTime = 24,
    this.takenLate = 3,
    this.missed = 3,
    this.onDayTapped,
    this.onExport,
  });

  @override
  State<MedicationAdherenceScreen> createState() =>
      _MedicationAdherenceScreenState();
}

class _MedicationAdherenceScreenState extends State<MedicationAdherenceScreen> {
  String _selectedFilter = 'All';
  late DateTime _selectedDay;
  late DateTime _displayedMonth;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _selectedDay = DateTime(now.year, now.month, now.day);
    _displayedMonth = DateTime(now.year, now.month, 1);
  }

  List<String> get _filterOptions => widget.medications.isEmpty
      ? ['All']
      : ['All', ...widget.medications.map((m) => m.name).take(4)];

  MedicationStatus _statusForDay(int day) {
    final key = DateTime(_displayedMonth.year, _displayedMonth.month, day);
    return widget.calendarData[key] ?? MedicationStatus.pending;
  }

  Color _colorForStatus(MedicationStatus? status, bool isFuture) {
    if (isFuture || status == null) return MedBuddyColors.slate100;
    switch (status) {
      case MedicationStatus.taken:
        return MedBuddyColors.success;
      case MedicationStatus.late:
        return MedBuddyColors.warning;
      case MedicationStatus.missed:
        return MedBuddyColors.emergency;
      case MedicationStatus.pending:
        return MedBuddyColors.slate100;
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
                    _buildSummaryCard(),
                    const SizedBox(height: MedBuddyDimens.spacingMd),
                    _buildFilterChips(),
                    const SizedBox(height: MedBuddyDimens.spacingMd),
                    _buildCalendarHeatmap(),
                    const SizedBox(height: MedBuddyDimens.spacingMd),
                    _buildDayDetail(),
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
            onPressed: () => goBack(context, fallbackRoute: '/wellness-history'),
            icon: const Icon(Icons.arrow_back_ios,
                color: MedBuddyColors.primary, size: 20),
          ),
          const Expanded(
              child: Text('Medication History',
                  style: MedBuddyTextStyles.heading3,
                  textAlign: TextAlign.center)),
          IconButton(
            onPressed: widget.onExport,
            icon: const Icon(Icons.filter_alt_outlined,
                color: MedBuddyColors.primary),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard() {
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
          const Text('Overall Adherence This Month',
              style: MedBuddyTextStyles.label),
          const SizedBox(height: 4),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('${widget.adherencePercent}%',
                  style: const TextStyle(
                    fontSize: 42,
                    fontWeight: FontWeight.w700,
                    color: MedBuddyColors.primary,
                    height: 1,
                  )),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  _statRow(MedBuddyColors.success,
                      'On time — ${widget.takenOnTime} days'),
                  _statRow(MedBuddyColors.warning,
                      'Late — ${widget.takenLate} days'),
                  _statRow(MedBuddyColors.emergency,
                      'Missed — ${widget.missed} days'),
                ],
              ),
            ],
          ),
          const SizedBox(height: MedBuddyDimens.spacingMd),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: widget.adherencePercent / 100,
              backgroundColor: MedBuddyColors.slate300,
              color: MedBuddyColors.primary,
              minHeight: 8,
            ),
          ),
        ],
      ),
    );
  }

  Widget _statRow(Color dotColor, String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 5),
      child: Row(
        children: [
          Container(
              width: 8,
              height: 8,
              decoration:
                  BoxDecoration(color: dotColor, shape: BoxShape.circle)),
          const SizedBox(width: 5),
          Text(label,
              style: MedBuddyTextStyles.caption
                  .copyWith(color: MedBuddyColors.slate700)),
        ],
      ),
    );
  }

  Widget _buildFilterChips() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: _filterOptions.map((filter) {
          final isSelected = _selectedFilter == filter;
          return GestureDetector(
            onTap: () => setState(() => _selectedFilter = filter),
            child: Container(
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: isSelected ? MedBuddyColors.primary : Colors.transparent,
                borderRadius: BorderRadius.circular(MedBuddyDimens.radiusPill),
                border: Border.all(color: MedBuddyColors.primary, width: 1.5),
              ),
              child: Text(filter,
                  style: MedBuddyTextStyles.label.copyWith(
                    color: isSelected
                        ? MedBuddyColors.pureWhite
                        : MedBuddyColors.primary,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                  )),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildCalendarHeatmap() {
    final today = DateTime.now();
    final firstDay = DateTime(_displayedMonth.year, _displayedMonth.month, 1);
    final daysInMonth =
        DateTime(_displayedMonth.year, _displayedMonth.month + 1, 0).day;
    final startWeekday = firstDay.weekday % 7; // 0=Sun

    return Container(
      padding: const EdgeInsets.all(MedBuddyDimens.spacingMd),
      decoration: BoxDecoration(
        color: MedBuddyColors.pureWhite,
        borderRadius: BorderRadius.circular(MedBuddyDimens.radiusLg),
        border: Border.all(color: MedBuddyColors.slate300, width: 0.5),
      ),
      child: Column(
        children: [
          // Month nav
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                onPressed: () => setState(() => _displayedMonth = DateTime(
                    _displayedMonth.year, _displayedMonth.month - 1, 1)),
                icon: const Icon(Icons.chevron_left,
                    color: MedBuddyColors.primary),
              ),
              Text(
                '${_monthName(_displayedMonth.month)} ${_displayedMonth.year}',
                style: MedBuddyTextStyles.bodyBold,
              ),
              IconButton(
                onPressed: () => setState(() => _displayedMonth = DateTime(
                    _displayedMonth.year, _displayedMonth.month + 1, 1)),
                icon: const Icon(Icons.chevron_right,
                    color: MedBuddyColors.primary),
              ),
            ],
          ),
          // Day headers
          Row(
            children: ['S', 'M', 'T', 'W', 'T', 'F', 'S']
                .map((d) => Expanded(
                      child: Text(d,
                          textAlign: TextAlign.center,
                          style: MedBuddyTextStyles.caption),
                    ))
                .toList(),
          ),
          const SizedBox(height: 6),
          // Grid
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
              mainAxisSpacing: 3,
              crossAxisSpacing: 3,
              childAspectRatio: 1,
            ),
            itemCount: startWeekday + daysInMonth,
            itemBuilder: (context, index) {
              if (index < startWeekday) return const SizedBox();
              final day = index - startWeekday + 1;
              final date =
                  DateTime(_displayedMonth.year, _displayedMonth.month, day);
              final isFuture = date.isAfter(today);
              final isToday = date.day == today.day &&
                  date.month == today.month &&
                  date.year == today.year;
              final isSelected = _selectedDay.day == day &&
                  _selectedDay.month == _displayedMonth.month;
              final status = _statusForDay(day);
              final color = _colorForStatus(status, isFuture);

              return GestureDetector(
                onTap: isFuture
                    ? null
                    : () {
                        setState(() => _selectedDay = date);
                        widget.onDayTapped?.call(date);
                      },
                child: Container(
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(6),
                    border: isToday || isSelected
                        ? Border.all(color: MedBuddyColors.primary, width: 2)
                        : null,
                  ),
                  child: Center(
                    child: Text(
                      '$day',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: isFuture
                            ? MedBuddyColors.slate300
                            : MedBuddyColors.pureWhite,
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
          // Legend
          const SizedBox(height: MedBuddyDimens.spacingMd),
          const Divider(color: MedBuddyColors.slate100),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _legendItem(MedBuddyColors.success, 'On time'),
              const SizedBox(width: 14),
              _legendItem(MedBuddyColors.warning, 'Late'),
              const SizedBox(width: 14),
              _legendItem(MedBuddyColors.emergency, 'Missed'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _legendItem(Color color, String label) {
    return Row(
      children: [
        Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
                color: color, borderRadius: BorderRadius.circular(3))),
        const SizedBox(width: 5),
        Text(label, style: MedBuddyTextStyles.caption),
      ],
    );
  }

  Widget _buildDayDetail() {
    // TODO: Replace with real data fetched via widget.onDayTapped
    final items = [
      {
        'name': 'Metformin 500mg',
        'status': MedicationStatus.taken,
        'time': '8:02 AM'
      },
      {
        'name': 'Lisinopril 10mg',
        'status': MedicationStatus.late,
        'time': '10:45 AM'
      },
      {'name': 'Aspirin 75mg', 'status': MedicationStatus.missed, 'time': null},
    ];

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
          Text(
            'Apr ${_selectedDay.day} — Detail',
            style: MedBuddyTextStyles.label.copyWith(
                fontWeight: FontWeight.w700, color: MedBuddyColors.primaryDark),
          ),
          const SizedBox(height: MedBuddyDimens.spacingSm),
          ...items.map((item) => _medicationDetailRow(item)),
        ],
      ),
    );
  }

  Widget _medicationDetailRow(Map<String, dynamic> item) {
    final status = item['status'] as MedicationStatus;
    Color bgColor;
    Color textColor;
    String statusLabel;

    switch (status) {
      case MedicationStatus.taken:
        bgColor = MedBuddyColors.successLight;
        textColor = MedBuddyColors.success;
        statusLabel = 'Taken ${item['time']}';
        break;
      case MedicationStatus.late:
        bgColor = MedBuddyColors.warningLight;
        textColor = MedBuddyColors.warning;
        statusLabel = 'Late ${item['time']}';
        break;
      case MedicationStatus.missed:
        bgColor = MedBuddyColors.emergencyLight;
        textColor = MedBuddyColors.emergency;
        statusLabel = 'Missed';
        break;
      default:
        bgColor = MedBuddyColors.slate100;
        textColor = MedBuddyColors.slate500;
        statusLabel = 'Pending';
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 7),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(item['name'] as String,
              style: MedBuddyTextStyles.label
                  .copyWith(color: MedBuddyColors.slate700)),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
            decoration: BoxDecoration(
                color: bgColor, borderRadius: BorderRadius.circular(20)),
            child: Text(statusLabel,
                style: MedBuddyTextStyles.caption
                    .copyWith(color: textColor, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  String _monthName(int month) {
    const names = [
      '',
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
      'December'
    ];
    return names[month];
  }
}
