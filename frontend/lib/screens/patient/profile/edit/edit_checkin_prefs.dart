import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../constants/colors.dart';
import '../../../../constants/dimens.dart';
import '../../../../constants/text_styles.dart';
import '../../../../providers/patient_provider.dart';
import '../../../../services/api_service.dart';
import 'edit_scaffold.dart';

/// Dedicated editor for the Check-in Preferences profile section.
class EditCheckinPrefsScreen extends ConsumerStatefulWidget {
  const EditCheckinPrefsScreen({super.key});

  @override
  ConsumerState<EditCheckinPrefsScreen> createState() =>
      _EditCheckinPrefsScreenState();
}

class _EditCheckinPrefsScreenState
    extends ConsumerState<EditCheckinPrefsScreen> {
  String _timeKey = 'morning';
  int _frequency = 1;
  double _painBaseline = 3;
  bool _isLoading = false;
  String? _error;

  static const _timeOptions = [
    ('morning', 'Morning', '08:00'),
    ('midday', 'Midday', '12:00'),
    ('evening', 'Evening', '18:00'),
  ];

  @override
  void initState() {
    super.initState();
    final data = ref.read(patientProfileProvider).valueOrNull;
    final t = data?.checkinTime;
    if (t != null && t.length >= 2) {
      final hour = int.tryParse(t.substring(0, 2)) ?? 8;
      if (hour < 11) {
        _timeKey = 'morning';
      } else if (hour < 15) {
        _timeKey = 'midday';
      } else {
        _timeKey = 'evening';
      }
    }
    _frequency = int.tryParse(data?.checkinFrequency ?? '1') ?? 1;
    _painBaseline = (data?.painBaseline ?? 3).toDouble();
  }

  String get _timeValue =>
      _timeOptions.firstWhere((o) => o.$1 == _timeKey).$3;

  Future<void> _save() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    final dio = ref.read(apiServiceProvider);
    final body = <String, dynamic>{
      'checkin_time': _timeValue,
      'checkin_frequency': _frequency,
      'pain_baseline': _painBaseline.round(),
    };
    try {
      await dio.patch('/patient/profile', data: body);
      await ref.read(patientProfileProvider.notifier).fetch();
      if (!mounted) return;
      Navigator.of(context).pop();
    } on DioException catch (e) {
      setState(() {
        _error = e.response?.data?['detail'] ?? e.message ?? 'Failed to save';
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return EditScaffold(
      sectionLabel: 'PROFILE',
      title: 'Check-in Preferences',
      isLoading: _isLoading,
      canSave: true,
      error: _error,
      onSave: _save,
      children: [
        const EditFieldLabel('Daily check-in time'),
        const SizedBox(height: MedBuddyDimens.spacingMd),
        Wrap(
          spacing: MedBuddyDimens.spacingSm,
          children: _timeOptions.map((opt) {
            final selected = _timeKey == opt.$1;
            return GestureDetector(
              onTap: () => setState(() => _timeKey = opt.$1),
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: MedBuddyDimens.spacingLg,
                    vertical: MedBuddyDimens.spacingSm),
                decoration: BoxDecoration(
                  color: selected
                      ? MedBuddyColors.primary
                      : MedBuddyColors.slate100,
                  borderRadius: BorderRadius.circular(MedBuddyDimens.radiusPill),
                  border: selected
                      ? null
                      : Border.all(color: MedBuddyColors.slate300, width: 0.5),
                ),
                child: Text(
                  '${opt.$2} (${opt.$3})',
                  style: MedBuddyTextStyles.secondary.copyWith(
                    color: selected
                        ? MedBuddyColors.pureWhite
                        : MedBuddyColors.slate700,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: MedBuddyDimens.spacingLg),
        const EditFieldLabel('Frequency'),
        const SizedBox(height: MedBuddyDimens.spacingMd),
        Row(
          children: [
            _freqChip('Daily', 1),
            const SizedBox(width: MedBuddyDimens.spacingSm),
            _freqChip('Twice daily', 2),
          ],
        ),
        const SizedBox(height: MedBuddyDimens.spacingLg),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const EditFieldLabel('Pain baseline'),
            Text('${_painBaseline.round()} / 10',
                style: MedBuddyTextStyles.bodyBold
                    .copyWith(color: MedBuddyColors.primaryDark)),
          ],
        ),
        const SizedBox(height: MedBuddyDimens.spacingXs),
        Text(
          'Your usual day-to-day pain level. Check-ins compare against this.',
          style: MedBuddyTextStyles.secondary
              .copyWith(color: MedBuddyColors.slate500),
        ),
        Slider(
          value: _painBaseline,
          min: 0,
          max: 10,
          divisions: 10,
          label: _painBaseline.round().toString(),
          activeColor: MedBuddyColors.primary,
          onChanged: (v) => setState(() => _painBaseline = v),
        ),
      ],
    );
  }

  Widget _freqChip(String label, int value) {
    final selected = _frequency == value;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _frequency = value),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: MedBuddyDimens.spacingMd),
          decoration: BoxDecoration(
            color: selected ? MedBuddyColors.primary : MedBuddyColors.slate100,
            borderRadius: BorderRadius.circular(MedBuddyDimens.radiusLg),
            border: selected
                ? null
                : Border.all(color: MedBuddyColors.slate300, width: 0.5),
          ),
          child: Center(
            child: Text(
              label,
              style: MedBuddyTextStyles.secondary.copyWith(
                color: selected
                    ? MedBuddyColors.pureWhite
                    : MedBuddyColors.slate700,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
