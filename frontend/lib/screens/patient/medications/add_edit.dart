import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../constants/colors.dart';
import '../../../constants/dimens.dart';
import '../../../constants/text_styles.dart';
import '../../../models/medication_model.dart';
import '../../../providers/medication_provider.dart';
import '../../../services/api_service.dart';
import '../../../widgets/shared/sos_button.dart';

class AddEditMedication extends ConsumerStatefulWidget {
  final MedicationItem? medication;

  const AddEditMedication({super.key, this.medication});

  @override
  ConsumerState<AddEditMedication> createState() => _AddEditMedicationState();
}

class _AddEditMedicationState extends ConsumerState<AddEditMedication> {
  late final TextEditingController _nameCtrl;
  late final TextEditingController _doseCtrl;
  late final TextEditingController _instructionCtrl;

  String _frequency = 'daily';
  final Set<String> _selectedTimes = {'morning'};
  bool _isLoading = false;
  String? _error;

  bool get isEdit => widget.medication != null;

  static const _frequencies = [
    ('daily', 'Once daily'),
    ('twice_daily', 'Twice daily'),
    ('three_times_daily', 'Three times daily'),
  ];

  static const _timeOptions = [
    ('morning', 'Morning'),
    ('afternoon', 'Afternoon'),
    ('evening', 'Evening'),
    ('night', 'Night'),
  ];

  static const _timeDoseMap = {
    'morning': '08:00',
    'afternoon': '13:00',
    'evening': '18:00',
    'night': '21:00',
  };

  static const _hhmToKey = {
    '08:00': 'morning',
    '13:00': 'afternoon',
    '18:00': 'evening',
    '21:00': 'night',
  };

  @override
  void initState() {
    super.initState();
    final med = widget.medication;
    _nameCtrl = TextEditingController(text: med?.name ?? '');
    _doseCtrl = TextEditingController(text: med?.dosage ?? '');
    _instructionCtrl = TextEditingController(text: med?.instruction ?? '');
    if (med != null) {
      _frequency = med.frequency.isNotEmpty ? med.frequency : 'daily';
      _selectedTimes.clear();
      for (final s in med.schedules) {
        final key = _hhmToKey[s.timeOfDay] ?? 'morning';
        _selectedTimes.add(key);
      }
      if (_selectedTimes.isEmpty) _selectedTimes.add('morning');
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _doseCtrl.dispose();
    _instructionCtrl.dispose();
    super.dispose();
  }

  bool get _canSave =>
      _nameCtrl.text.trim().isNotEmpty && _doseCtrl.text.trim().isNotEmpty;

  double _parseDoseAmount(String dosage) {
    final match = RegExp(r'[\d.]+').firstMatch(dosage);
    return match != null ? double.tryParse(match.group(0)!) ?? 1.0 : 1.0;
  }

  String _parseDoseUnit(String dosage) {
    final lower = dosage.toLowerCase();
    if (lower.contains('mcg')) return 'mcg';
    if (lower.contains('mg')) return 'mg';
    if (lower.contains('ml')) return 'ml';
    if (lower.contains('tablet')) return 'tablet';
    if (lower.contains('capsule')) return 'capsule';
    return 'tablet';
  }

  Future<void> _save() async {
    if (!_canSave) return;

    if (!isEdit) {
      final nameLower = _nameCtrl.text.trim().toLowerCase();
      final exists = ref
          .read(medicationProvider)
          .medications
          .any((m) => m.name.toLowerCase() == nameLower);
      if (exists) {
        setState(() {
          _error = 'You already have this medication — edit it instead.';
        });
        return;
      }
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    final dio = ref.read(apiServiceProvider);
    final dosageText = _doseCtrl.text.trim();
    final body = <String, dynamic>{
      'name': _nameCtrl.text.trim(),
      'dose_amount': _parseDoseAmount(dosageText),
      'dose_unit': _parseDoseUnit(dosageText),
      'frequency': _frequency,
      if (!isEdit)
        'start_date': DateTime.now().toIso8601String().split('T')[0],
      if (_instructionCtrl.text.trim().isNotEmpty)
        'instructions': _instructionCtrl.text.trim(),
      'schedules': _selectedTimes
          .map((t) => {'time_of_day': _timeDoseMap[t]!})
          .toList(),
    };

    try {
      if (isEdit) {
        await dio.patch('/medications/${widget.medication!.id}', data: body);
      } else {
        await dio.post('/medications/', data: body);
      }
      if (!mounted) return;
      await ref.read(medicationProvider.notifier).refresh();
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
    return Scaffold(
      backgroundColor: MedBuddyColors.warmWhite,
      body: Stack(
        children: [
          Column(
            children: [
              _buildAppBar(context),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.only(
                    left: MedBuddyDimens.spacingLg,
                    right: MedBuddyDimens.spacingLg,
                    top: MedBuddyDimens.spacingXl,
                    bottom: MedBuddyDimens.spacingXxl,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const _FieldLabel('Medication Name'),
                      const SizedBox(height: MedBuddyDimens.spacingXs),
                      _textField(_nameCtrl, 'e.g. Metformin',
                          onChanged: (_) => setState(() {})),

                      const SizedBox(height: MedBuddyDimens.spacingLg),
                      const _FieldLabel('Dose'),
                      const SizedBox(height: MedBuddyDimens.spacingXs),
                      _textField(_doseCtrl, 'e.g. 500 mg'),

                      const SizedBox(height: MedBuddyDimens.spacingLg),
                      const _FieldLabel('Frequency'),
                      const SizedBox(height: MedBuddyDimens.spacingXs),
                      _frequencyDropdown(),

                      const SizedBox(height: MedBuddyDimens.spacingLg),
                      const _FieldLabel('Time of Day'),
                      const SizedBox(height: MedBuddyDimens.spacingXs),
                      _timeSelector(),

                      const SizedBox(height: MedBuddyDimens.spacingLg),
                      const _FieldLabel('Notes (optional)'),
                      const SizedBox(height: MedBuddyDimens.spacingXs),
                      _textField(_instructionCtrl, 'e.g. Take with food',
                          maxLines: 3),

                      if (_error != null) ...[
                        const SizedBox(height: MedBuddyDimens.spacingMd),
                        Container(
                          width: double.infinity,
                          padding:
                              const EdgeInsets.all(MedBuddyDimens.spacingMd),
                          decoration: BoxDecoration(
                            color: MedBuddyColors.emergency
                                .withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(
                                MedBuddyDimens.radiusMd),
                          ),
                          child: Text(
                            _error!,
                            style: MedBuddyTextStyles.secondary
                                .copyWith(color: MedBuddyColors.emergency),
                          ),
                        ),
                      ],

                      const SizedBox(height: MedBuddyDimens.spacingXxl),

                      SizedBox(
                        width: double.infinity,
                        height: MedBuddyDimens.buttonHeightPrimary,
                        child: ElevatedButton(
                          onPressed:
                              (_canSave && !_isLoading) ? _save : null,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: MedBuddyColors.primary,
                            foregroundColor: MedBuddyColors.pureWhite,
                            disabledBackgroundColor:
                                MedBuddyColors.slate300,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(
                                  MedBuddyDimens.radiusLg),
                            ),
                          ),
                          child: _isLoading
                              ? const SizedBox(
                                  height: 22,
                                  width: 22,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2.5,
                                    color: Colors.white,
                                  ),
                                )
                              : Text(
                                  isEdit
                                      ? 'Save Changes'
                                      : 'Add Medication',
                                  style: MedBuddyTextStyles.bodyBold
                                      .copyWith(
                                          color: MedBuddyColors.pureWhite),
                                ),
                        ),
                      ),
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

  Widget _buildAppBar(BuildContext context) {
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
          bottom: BorderSide(color: MedBuddyColors.slate300, width: 0.5),
        ),
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.of(context).maybePop(),
            child: const Icon(Icons.arrow_back_ios_new,
                color: MedBuddyColors.primaryDark, size: 20),
          ),
          const SizedBox(width: MedBuddyDimens.spacingMd),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('MEDICATIONS',
                  style: MedBuddyTextStyles.sectionHeader),
              Text(
                isEdit ? 'Edit Medication' : 'Add Medication',
                style: MedBuddyTextStyles.heading2
                    .copyWith(color: MedBuddyColors.slate900),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _textField(
    TextEditingController ctrl,
    String hint, {
    int maxLines = 1,
    ValueChanged<String>? onChanged,
  }) =>
      TextField(
        controller: ctrl,
        maxLines: maxLines,
        onChanged: onChanged,
        style: MedBuddyTextStyles.body
            .copyWith(color: MedBuddyColors.slate900),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: MedBuddyTextStyles.body
              .copyWith(color: MedBuddyColors.slate500),
          filled: true,
          fillColor: MedBuddyColors.slate100,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: MedBuddyDimens.spacingLg,
            vertical: MedBuddyDimens.spacingMd,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(MedBuddyDimens.radiusLg),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(MedBuddyDimens.radiusLg),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(MedBuddyDimens.radiusLg),
            borderSide: const BorderSide(
                color: MedBuddyColors.primaryMid, width: 1.5),
          ),
        ),
      );

  Widget _frequencyDropdown() => DropdownButtonFormField<String>(
        initialValue: _frequency,
        decoration: InputDecoration(
          filled: true,
          fillColor: MedBuddyColors.slate100,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: MedBuddyDimens.spacingLg,
            vertical: MedBuddyDimens.spacingMd,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(MedBuddyDimens.radiusLg),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(MedBuddyDimens.radiusLg),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(MedBuddyDimens.radiusLg),
            borderSide: const BorderSide(
                color: MedBuddyColors.primaryMid, width: 1.5),
          ),
        ),
        items: _frequencies
            .map((f) => DropdownMenuItem(value: f.$1, child: Text(f.$2)))
            .toList(),
        onChanged: (v) {
          if (v != null) setState(() => _frequency = v);
        },
        style: MedBuddyTextStyles.body
            .copyWith(color: MedBuddyColors.slate900),
      );

  Widget _timeSelector() => Wrap(
        spacing: MedBuddyDimens.spacingSm,
        children: _timeOptions.map((opt) {
          final isSelected = _selectedTimes.contains(opt.$1);
          return GestureDetector(
            onTap: () => setState(() {
              if (isSelected && _selectedTimes.length > 1) {
                _selectedTimes.remove(opt.$1);
              } else if (!isSelected) {
                _selectedTimes.add(opt.$1);
              }
            }),
            child: Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: MedBuddyDimens.spacingLg,
                  vertical: MedBuddyDimens.spacingSm),
              decoration: BoxDecoration(
                color: isSelected
                    ? MedBuddyColors.primary
                    : MedBuddyColors.slate100,
                borderRadius:
                    BorderRadius.circular(MedBuddyDimens.radiusPill),
                border: isSelected
                    ? null
                    : Border.all(
                        color: MedBuddyColors.slate300, width: 0.5),
              ),
              child: Text(
                opt.$2,
                style: MedBuddyTextStyles.secondary.copyWith(
                  color: isSelected
                      ? MedBuddyColors.pureWhite
                      : MedBuddyColors.slate700,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          );
        }).toList(),
      );
}

// ── Field Label ───────────────────────────────────────────────────────────────

class _FieldLabel extends StatelessWidget {
  final String text;
  const _FieldLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: MedBuddyTextStyles.label.copyWith(
        color: MedBuddyColors.slate500,
        fontWeight: FontWeight.w600,
      ),
    );
  }
}
