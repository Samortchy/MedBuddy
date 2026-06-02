import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../constants/colors.dart';
import '../../../../constants/dimens.dart';
import '../../../../constants/text_styles.dart';
import '../../../../providers/patient_provider.dart';
import '../../../../services/api_service.dart';
import 'edit_scaffold.dart';

/// Dedicated editor for the Basic Info profile section.
/// Prefills from the current profile, saves via PATCH /patient/profile, pops back.
class EditBasicInfoScreen extends ConsumerStatefulWidget {
  const EditBasicInfoScreen({super.key});

  @override
  ConsumerState<EditBasicInfoScreen> createState() =>
      _EditBasicInfoScreenState();
}

class _EditBasicInfoScreenState extends ConsumerState<EditBasicInfoScreen> {
  late final TextEditingController _nameCtrl;
  DateTime? _dob;
  String? _gender;
  bool _isLoading = false;
  String? _error;

  static const _genders = ['Male', 'Female', 'Prefer not to say'];

  @override
  void initState() {
    super.initState();
    final data = ref.read(patientProfileProvider).valueOrNull;
    _nameCtrl = TextEditingController(text: data?.fullName ?? '');
    if (data?.dateOfBirth != null) {
      _dob = DateTime.tryParse(data!.dateOfBirth!);
    }
    _gender = data?.gender;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  bool get _canSave => _nameCtrl.text.trim().isNotEmpty;

  String _fmtDob(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  Future<void> _pickDob() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _dob ?? DateTime(now.year - 65),
      firstDate: DateTime(now.year - 120),
      lastDate: now,
      helpText: 'Select date of birth',
    );
    if (picked != null) setState(() => _dob = picked);
  }

  Future<void> _save() async {
    if (!_canSave) return;
    setState(() {
      _isLoading = true;
      _error = null;
    });
    final dio = ref.read(apiServiceProvider);
    final body = <String, dynamic>{
      'full_name': _nameCtrl.text.trim(),
      if (_dob != null) 'date_of_birth': _fmtDob(_dob!),
      if (_gender != null) 'gender': _gender,
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
      title: 'Basic Info',
      isLoading: _isLoading,
      canSave: _canSave,
      error: _error,
      onSave: _save,
      children: [
        const EditFieldLabel('Full Name'),
        const SizedBox(height: MedBuddyDimens.spacingXs),
        TextField(
          controller: _nameCtrl,
          onChanged: (_) => setState(() {}),
          style: MedBuddyTextStyles.body.copyWith(color: MedBuddyColors.slate900),
          decoration: editInputDecoration('e.g. Hassan Ali'),
        ),
        const SizedBox(height: MedBuddyDimens.spacingLg),
        const EditFieldLabel('Date of Birth'),
        const SizedBox(height: MedBuddyDimens.spacingXs),
        GestureDetector(
          onTap: _pickDob,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(
              horizontal: MedBuddyDimens.spacingLg,
              vertical: MedBuddyDimens.spacingLg,
            ),
            decoration: BoxDecoration(
              color: MedBuddyColors.slate100,
              borderRadius: BorderRadius.circular(MedBuddyDimens.radiusLg),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _dob != null ? _fmtDob(_dob!) : 'Select a date',
                  style: MedBuddyTextStyles.body.copyWith(
                    color: _dob != null
                        ? MedBuddyColors.slate900
                        : MedBuddyColors.slate500,
                  ),
                ),
                const Icon(Icons.calendar_today_outlined,
                    color: MedBuddyColors.primary, size: 20),
              ],
            ),
          ),
        ),
        const SizedBox(height: MedBuddyDimens.spacingLg),
        const EditFieldLabel('Gender'),
        const SizedBox(height: MedBuddyDimens.spacingMd),
        ..._genders.map((g) {
          final selected = _gender == g;
          return GestureDetector(
            onTap: () => setState(() => _gender = g),
            child: Container(
              margin: const EdgeInsets.only(bottom: MedBuddyDimens.spacingSm),
              padding: const EdgeInsets.all(MedBuddyDimens.spacingLg),
              decoration: BoxDecoration(
                color: selected
                    ? MedBuddyColors.primarySoft
                    : MedBuddyColors.pureWhite,
                borderRadius: BorderRadius.circular(MedBuddyDimens.radiusLg),
                border: Border.all(
                  color: selected
                      ? MedBuddyColors.primary
                      : MedBuddyColors.slate300,
                  width: selected ? 2 : 0.5,
                ),
              ),
              child: Row(
                children: [
                  Text(
                    g,
                    style: MedBuddyTextStyles.body.copyWith(
                      fontWeight: selected ? FontWeight.w700 : FontWeight.w400,
                      color: selected
                          ? MedBuddyColors.primaryDark
                          : MedBuddyColors.slate700,
                    ),
                  ),
                  const Spacer(),
                  if (selected)
                    const Icon(Icons.check_circle,
                        color: MedBuddyColors.primary, size: 20),
                ],
              ),
            ),
          );
        }),
      ],
    );
  }
}
