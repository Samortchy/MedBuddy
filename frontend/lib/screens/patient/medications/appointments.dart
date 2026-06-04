import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../utils/nav_helpers.dart';
import '../../../constants/colors.dart';
import '../../../constants/dimens.dart';
import '../../../constants/text_styles.dart';
import '../../../providers/appointment_provider.dart';
import '../../../widgets/shared/sos_button.dart';
import '../../../widgets/shared/bottom_nav_bar.dart';

class AppointmentsScreen extends ConsumerWidget {
  const AppointmentsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(appointmentProvider);

    return Scaffold(
      backgroundColor: MedBuddyColors.warmWhite,
      body: Stack(
        children: [
          Column(
            children: [
              _AppBar(onAdd: () => _showAddSheet(context, ref)),
              Expanded(
                child: RefreshIndicator(
                  color: MedBuddyColors.primary,
                  onRefresh: () =>
                      ref.read(appointmentProvider.notifier).refresh(),
                  child: state.isLoading
                      ? const Center(
                          child: CircularProgressIndicator(
                              color: MedBuddyColors.primary))
                      : _buildList(context, ref, state),
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

  Widget _buildList(
      BuildContext context, WidgetRef ref, AppointmentState state) {
    final upcoming = state.upcoming;
    final past = state.past;

    if (upcoming.isEmpty && past.isEmpty) {
      return _buildEmpty(context, ref);
    }

    return ListView(
      padding: const EdgeInsets.only(
        left: MedBuddyDimens.spacingLg,
        right: MedBuddyDimens.spacingLg,
        top: MedBuddyDimens.spacingLg,
        bottom: 100,
      ),
      children: [
        if (upcoming.isNotEmpty) ...[
          const _SectionHeader('UPCOMING'),
          const SizedBox(height: MedBuddyDimens.spacingMd),
          ...upcoming.map((a) => Padding(
                padding:
                    const EdgeInsets.only(bottom: MedBuddyDimens.spacingSm),
                child: _AppointmentCard(
                  appointment: a,
                  onDelete: () =>
                      ref.read(appointmentProvider.notifier).delete(a.id),
                ),
              )),
        ],
        if (past.isNotEmpty) ...[
          const SizedBox(height: MedBuddyDimens.spacingXl),
          const _SectionHeader('PAST'),
          const SizedBox(height: MedBuddyDimens.spacingMd),
          ...past.map((a) => Padding(
                padding:
                    const EdgeInsets.only(bottom: MedBuddyDimens.spacingSm),
                child: _AppointmentCard(appointment: a, onDelete: null),
              )),
        ],
      ],
    );
  }

  Widget _buildEmpty(BuildContext context, WidgetRef ref) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(MedBuddyDimens.spacingXxl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.calendar_today_outlined,
                color: MedBuddyColors.slate300, size: 48),
            const SizedBox(height: MedBuddyDimens.spacingLg),
            Text(
              'No appointments yet',
              style: MedBuddyTextStyles.body
                  .copyWith(color: MedBuddyColors.slate500),
            ),
            const SizedBox(height: MedBuddyDimens.spacingMd),
            ElevatedButton.icon(
              onPressed: () => _showAddSheet(context, ref),
              icon: const Icon(Icons.add, size: 18),
              label: const Text('Schedule Appointment'),
              style: ElevatedButton.styleFrom(
                backgroundColor: MedBuddyColors.primary,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                    borderRadius:
                        BorderRadius.circular(MedBuddyDimens.radiusLg)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showAddSheet(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: MedBuddyColors.pureWhite,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
              top: Radius.circular(MedBuddyDimens.radiusLg))),
      builder: (_) => _AddAppointmentSheet(
        onSave: (title, scheduledAt, doctorName, notes) =>
            ref.read(appointmentProvider.notifier).create(
                  title: title,
                  scheduledAt: scheduledAt,
                  doctorName: doctorName,
                  notes: notes,
                ),
      ),
    );
  }
}

// ── App Bar ───────────────────────────────────────────────────────────────────

class _AppBar extends StatelessWidget {
  final VoidCallback onAdd;
  const _AppBar({required this.onAdd});

  @override
  Widget build(BuildContext context) {
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
            bottom: BorderSide(color: MedBuddyColors.slate300, width: 0.5)),
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => goBack(context),
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
            onTap: onAdd,
            child: Container(
              width: MedBuddyDimens.buttonHeightSecondary,
              height: MedBuddyDimens.buttonHeightSecondary,
              decoration: BoxDecoration(
                color: MedBuddyColors.primarySoft,
                borderRadius:
                    BorderRadius.circular(MedBuddyDimens.radiusMd),
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
  final AppointmentItem appointment;
  final VoidCallback? onDelete;

  const _AppointmentCard({required this.appointment, required this.onDelete});

  String _formatDate(DateTime dt) {
    final now = DateTime.now();
    final diff = dt.difference(DateTime(now.year, now.month, now.day)).inDays;
    if (diff == 0) return 'Today';
    if (diff == 1) return 'Tomorrow';
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return '${months[dt.month - 1]} ${dt.day}';
  }

  String _formatTime(DateTime dt) {
    int h = dt.hour;
    final m = dt.minute.toString().padLeft(2, '0');
    final suffix = h >= 12 ? 'PM' : 'AM';
    if (h > 12) h -= 12;
    if (h == 0) h = 12;
    return '$h:$m $suffix';
  }

  @override
  Widget build(BuildContext context) {
    final isPast = !appointment.isUpcoming;
    return Dismissible(
      key: Key(appointment.id),
      direction: onDelete != null
          ? DismissDirection.endToStart
          : DismissDirection.none,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: MedBuddyDimens.spacingLg),
        decoration: BoxDecoration(
          color: MedBuddyColors.emergencyLight,
          borderRadius: BorderRadius.circular(MedBuddyDimens.radiusLg),
        ),
        child:
            const Icon(Icons.delete_outline, color: MedBuddyColors.emergency),
      ),
      onDismissed: (_) => onDelete?.call(),
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
                color: isPast
                    ? MedBuddyColors.slate100
                    : MedBuddyColors.primarySoft,
                borderRadius:
                    BorderRadius.circular(MedBuddyDimens.radiusMd),
              ),
              child: Center(
                child: Icon(
                  Icons.local_hospital_outlined,
                  color: isPast
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
                  Text(
                    appointment.doctorName ?? appointment.title,
                    style: MedBuddyTextStyles.bodyBold,
                  ),
                  if (appointment.doctorName != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      appointment.title,
                      style: MedBuddyTextStyles.secondary
                          .copyWith(color: MedBuddyColors.slate500),
                    ),
                  ],
                  const SizedBox(height: MedBuddyDimens.spacingXs),
                  Row(
                    children: [
                      const Icon(Icons.schedule,
                          color: MedBuddyColors.slate500, size: 13),
                      const SizedBox(width: 4),
                      Text(
                        '${_formatDate(appointment.scheduledAt)} · ${_formatTime(appointment.scheduledAt)}',
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
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: isPast
                    ? MedBuddyColors.slate100
                    : MedBuddyColors.primarySoft,
                borderRadius:
                    BorderRadius.circular(MedBuddyDimens.radiusPill),
              ),
              child: Text(
                isPast ? 'Past' : 'Upcoming',
                style: MedBuddyTextStyles.caption.copyWith(
                  color: isPast
                      ? MedBuddyColors.slate500
                      : MedBuddyColors.primaryDark,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Add Appointment Sheet ─────────────────────────────────────────────────────

class _AddAppointmentSheet extends StatefulWidget {
  final Future<void> Function(
      String title, DateTime scheduledAt, String? doctorName, String? notes)
      onSave;

  const _AddAppointmentSheet({required this.onSave});

  @override
  State<_AddAppointmentSheet> createState() => _AddAppointmentSheetState();
}

class _AddAppointmentSheetState extends State<_AddAppointmentSheet> {
  final _titleCtrl = TextEditingController();
  final _doctorCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();
  DateTime _selectedDate = DateTime.now().add(const Duration(days: 1));
  TimeOfDay _selectedTime = const TimeOfDay(hour: 10, minute: 0);
  bool _isSaving = false;
  String? _error;

  @override
  void dispose() {
    _titleCtrl.dispose();
    _doctorCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) setState(() => _selectedDate = picked);
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
    );
    if (picked != null) setState(() => _selectedTime = picked);
  }

  Future<void> _save() async {
    if (_titleCtrl.text.trim().isEmpty) {
      setState(() => _error = 'Please enter a title.');
      return;
    }
    setState(() {
      _isSaving = true;
      _error = null;
    });
    try {
      final dt = DateTime(
        _selectedDate.year,
        _selectedDate.month,
        _selectedDate.day,
        _selectedTime.hour,
        _selectedTime.minute,
      );
      await widget.onSave(
        _titleCtrl.text.trim(),
        dt,
        _doctorCtrl.text.trim().isEmpty ? null : _doctorCtrl.text.trim(),
        _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim(),
      );
      if (mounted) Navigator.pop(context);
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isSaving = false;
      });
    }
  }

  String _formatDate(DateTime dt) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return '${months[dt.month - 1]} ${dt.day}, ${dt.year}';
  }

  String _formatTime(TimeOfDay t) {
    int h = t.hour;
    final m = t.minute.toString().padLeft(2, '0');
    final suffix = h >= 12 ? 'PM' : 'AM';
    if (h > 12) h -= 12;
    if (h == 0) h = 12;
    return '$h:$m $suffix';
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: MedBuddyDimens.spacingXl,
        right: MedBuddyDimens.spacingXl,
        top: MedBuddyDimens.spacingXl,
        bottom: MediaQuery.of(context).viewInsets.bottom +
            MedBuddyDimens.spacingXl,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Schedule Appointment',
              style: MedBuddyTextStyles.heading2
                  .copyWith(color: MedBuddyColors.slate900)),
          const SizedBox(height: MedBuddyDimens.spacingXl),

          _sheetField(_titleCtrl, 'Appointment title (e.g. Blood test)'),
          const SizedBox(height: MedBuddyDimens.spacingMd),
          _sheetField(_doctorCtrl, 'Doctor / clinic name (optional)'),
          const SizedBox(height: MedBuddyDimens.spacingMd),

          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: _pickDate,
                  child: _datePill(Icons.calendar_today_outlined,
                      _formatDate(_selectedDate)),
                ),
              ),
              const SizedBox(width: MedBuddyDimens.spacingSm),
              Expanded(
                child: GestureDetector(
                  onTap: _pickTime,
                  child: _datePill(
                      Icons.schedule, _formatTime(_selectedTime)),
                ),
              ),
            ],
          ),
          const SizedBox(height: MedBuddyDimens.spacingMd),
          _sheetField(_notesCtrl, 'Notes (optional)', maxLines: 2),

          if (_error != null) ...[
            const SizedBox(height: MedBuddyDimens.spacingSm),
            Text(_error!,
                style: MedBuddyTextStyles.secondary
                    .copyWith(color: MedBuddyColors.emergency)),
          ],

          const SizedBox(height: MedBuddyDimens.spacingXl),
          SizedBox(
            width: double.infinity,
            height: MedBuddyDimens.buttonHeightPrimary,
            child: ElevatedButton(
              onPressed: _isSaving ? null : _save,
              style: ElevatedButton.styleFrom(
                backgroundColor: MedBuddyColors.primary,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                    borderRadius:
                        BorderRadius.circular(MedBuddyDimens.radiusLg)),
              ),
              child: _isSaving
                  ? const SizedBox(
                      height: 22,
                      width: 22,
                      child: CircularProgressIndicator(
                          strokeWidth: 2.5, color: Colors.white))
                  : Text('Save Appointment',
                      style: MedBuddyTextStyles.bodyBold
                          .copyWith(color: Colors.white)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _sheetField(TextEditingController ctrl, String hint,
          {int maxLines = 1}) =>
      TextField(
        controller: ctrl,
        maxLines: maxLines,
        style:
            MedBuddyTextStyles.body.copyWith(color: MedBuddyColors.slate900),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: MedBuddyTextStyles.body
              .copyWith(color: MedBuddyColors.slate500),
          filled: true,
          fillColor: MedBuddyColors.slate100,
          contentPadding: const EdgeInsets.symmetric(
              horizontal: MedBuddyDimens.spacingLg,
              vertical: MedBuddyDimens.spacingMd),
          border: OutlineInputBorder(
            borderRadius:
                BorderRadius.circular(MedBuddyDimens.radiusLg),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius:
                BorderRadius.circular(MedBuddyDimens.radiusLg),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius:
                BorderRadius.circular(MedBuddyDimens.radiusLg),
            borderSide: const BorderSide(
                color: MedBuddyColors.primaryMid, width: 1.5),
          ),
        ),
      );

  Widget _datePill(IconData icon, String label) => Container(
        padding: const EdgeInsets.symmetric(
            horizontal: MedBuddyDimens.spacingMd,
            vertical: MedBuddyDimens.spacingMd),
        decoration: BoxDecoration(
          color: MedBuddyColors.primarySoft,
          borderRadius: BorderRadius.circular(MedBuddyDimens.radiusMd),
          border: Border.all(
              color: MedBuddyColors.primaryLight, width: 1),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: MedBuddyColors.primaryDark, size: 16),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                label,
                style: MedBuddyTextStyles.secondary.copyWith(
                  color: MedBuddyColors.primaryDark,
                  fontWeight: FontWeight.w600,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      );
}
