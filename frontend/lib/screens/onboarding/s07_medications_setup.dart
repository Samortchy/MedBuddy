import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '/constants/colors.dart';
import '/constants/dimens.dart';
import '/constants/text_styles.dart';
import '/providers/onboarding_provider.dart';
import 's08_emergency_contacts.dart';

class S07MedicationsSetup extends ConsumerStatefulWidget {
  const S07MedicationsSetup({super.key});

  @override
  ConsumerState<S07MedicationsSetup> createState() =>
      _S07MedicationsSetupState();
}

class _S07MedicationsSetupState extends ConsumerState<S07MedicationsSetup> {
  final List<Map<String, dynamic>> medications = [];

  void _showAddSheet({Map<String, dynamic>? existing, int? index}) {
    final nameController = TextEditingController(text: existing?['name'] ?? '');
    final doseController = TextEditingController(text: existing?['dose'] ?? '');
    String frequency = existing?['frequency'] ?? 'Once daily';
    bool withFood = existing?['withFood'] ?? false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: MedBuddyColors.pureWhite,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
            top: Radius.circular(MedBuddyDimens.radiusLg)),
      ),
      builder: (_) => StatefulBuilder(
        builder: (ctx, setSheet) => Padding(
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
              Text(
                existing == null ? 'Add Medication' : 'Edit Medication',
                style: MedBuddyTextStyles.heading2
                    .copyWith(color: MedBuddyColors.slate900),
              ),
              const SizedBox(height: MedBuddyDimens.spacingXl),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: nameController,
                      style: MedBuddyTextStyles.body
                          .copyWith(color: MedBuddyColors.slate900),
                      decoration: _sheetInput('Medication name'),
                    ),
                  ),
                  const SizedBox(width: MedBuddyDimens.spacingSm),
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color: MedBuddyColors.primarySoft,
                      borderRadius:
                          BorderRadius.circular(MedBuddyDimens.radiusMd),
                    ),
                    child: const Icon(Icons.mic,
                        color: MedBuddyColors.primary, size: 24),
                  ),
                ],
              ),
              const SizedBox(height: MedBuddyDimens.spacingMd),
              TextField(
                controller: doseController,
                style: MedBuddyTextStyles.body
                    .copyWith(color: MedBuddyColors.slate900),
                decoration: _sheetInput('Dose (e.g. 500mg, 10ml)'),
              ),
              const SizedBox(height: MedBuddyDimens.spacingMd),
              DropdownButtonFormField<String>(
                initialValue: frequency,
                decoration: _sheetInput('Frequency'),
                items: [
                  'Once daily',
                  'Twice daily',
                  'Three times daily',
                  'Custom'
                ]
                    .map((f) => DropdownMenuItem(value: f, child: Text(f)))
                    .toList(),
                onChanged: (v) => setSheet(() => frequency = v!),
              ),
              const SizedBox(height: MedBuddyDimens.spacingMd),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: MedBuddyDimens.spacingLg,
                    vertical: MedBuddyDimens.spacingXs),
                decoration: BoxDecoration(
                  color: MedBuddyColors.slate100,
                  borderRadius: BorderRadius.circular(MedBuddyDimens.radiusMd),
                ),
                child: SwitchListTile(
                  title: Text(
                    'Take with food',
                    style: MedBuddyTextStyles.body
                        .copyWith(color: MedBuddyColors.slate900),
                  ),
                  value: withFood,
                  onChanged: (v) => setSheet(() => withFood = v),
                  activeThumbColor: MedBuddyColors.primary,
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              const SizedBox(height: MedBuddyDimens.spacingXl),
              SizedBox(
                width: double.infinity,
                height: MedBuddyDimens.buttonHeightPrimary,
                child: ElevatedButton(
                  onPressed: () {
                    final med = {
                      'name': nameController.text.trim(),
                      'dose': doseController.text.trim(),
                      'frequency': frequency,
                      'withFood': withFood,
                    };
                    setState(() {
                      if (index != null) {
                        medications[index] = med;
                      } else {
                        medications.add(med);
                      }
                    });
                    Navigator.pop(context);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: MedBuddyColors.primary,
                    foregroundColor: MedBuddyColors.pureWhite,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.circular(MedBuddyDimens.radiusLg),
                    ),
                  ),
                  child: Text(
                    existing == null ? 'Add Medication' : 'Save Changes',
                    style: MedBuddyTextStyles.bodyBold
                        .copyWith(color: MedBuddyColors.pureWhite),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: MedBuddyColors.warmWhite,
      body: SafeArea(
        child: Column(
          children: [
            _buildTopBar(context),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(MedBuddyDimens.spacingXl),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Step 4 of 6',
                      style: MedBuddyTextStyles.label
                          .copyWith(color: MedBuddyColors.slate500),
                    ),
                    const SizedBox(height: MedBuddyDimens.spacingXs),
                    Text(
                      'Your Medications',
                      style: MedBuddyTextStyles.heading1.copyWith(
                          fontSize: 26, color: MedBuddyColors.slate900),
                    ),
                    const SizedBox(height: MedBuddyDimens.spacingXs),
                    Text(
                      'Add your regular medications so MedBuddy can remind you and track adherence.',
                      style: MedBuddyTextStyles.body
                          .copyWith(color: MedBuddyColors.slate500),
                    ),
                    const SizedBox(height: MedBuddyDimens.spacingXl),
                    if (medications.isEmpty)
                      Center(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                              vertical: MedBuddyDimens.spacingXxl),
                          child: Column(
                            children: [
                              Container(
                                width: 80,
                                height: 80,
                                decoration: const BoxDecoration(
                                  color: MedBuddyColors.primarySoft,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.medication,
                                    color: MedBuddyColors.primary, size: 36),
                              ),
                              const SizedBox(height: MedBuddyDimens.spacingLg),
                              Text(
                                'No medications added yet',
                                style: MedBuddyTextStyles.bodyBold
                                    .copyWith(color: MedBuddyColors.slate700),
                              ),
                              const SizedBox(height: MedBuddyDimens.spacingXs),
                              Text(
                                'Tap "Add Medication" to get started',
                                style: MedBuddyTextStyles.secondary
                                    .copyWith(color: MedBuddyColors.slate500),
                              ),
                            ],
                          ),
                        ),
                      )
                    else
                      ...medications.asMap().entries.map((e) {
                        final i = e.key;
                        final med = e.value;
                        return Container(
                          margin: const EdgeInsets.only(
                              bottom: MedBuddyDimens.spacingSm),
                          padding:
                              const EdgeInsets.all(MedBuddyDimens.spacingMd),
                          decoration: BoxDecoration(
                            color: MedBuddyColors.pureWhite,
                            borderRadius:
                                BorderRadius.circular(MedBuddyDimens.radiusMd),
                            border: Border.all(
                                color: MedBuddyColors.slate300, width: 0.5),
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(
                                    MedBuddyDimens.spacingSm),
                                decoration: BoxDecoration(
                                  color: MedBuddyColors.primarySoft,
                                  borderRadius: BorderRadius.circular(
                                      MedBuddyDimens.radiusSm),
                                ),
                                child: const Icon(Icons.medication,
                                    color: MedBuddyColors.primary, size: 20),
                              ),
                              const SizedBox(width: MedBuddyDimens.spacingMd),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      '${med['name']} ${med['dose']}',
                                      style: MedBuddyTextStyles.bodyBold
                                          .copyWith(
                                              color: MedBuddyColors.slate900),
                                    ),
                                    Text(
                                      (med['frequency'] as String) +
                                          ((med['withFood'] as bool)
                                              ? ' · with food'
                                              : ''),
                                      style: MedBuddyTextStyles.secondary
                                          .copyWith(
                                              color: MedBuddyColors.slate500),
                                    ),
                                  ],
                                ),
                              ),
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.edit_outlined,
                                        color: MedBuddyColors.primary,
                                        size: 20),
                                    onPressed: () =>
                                        _showAddSheet(existing: med, index: i),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.delete_outline,
                                        color: MedBuddyColors.emergency,
                                        size: 20),
                                    onPressed: () =>
                                        setState(() => medications.removeAt(i)),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        );
                      }),
                    const SizedBox(height: MedBuddyDimens.spacingMd),
                    SizedBox(
                      width: double.infinity,
                      height: MedBuddyDimens.buttonHeightSecondary,
                      child: OutlinedButton.icon(
                        onPressed: () => _showAddSheet(),
                        icon: const Icon(Icons.add,
                            color: MedBuddyColors.primary, size: 20),
                        label: Text(
                          'Add Medication',
                          style: MedBuddyTextStyles.bodyBold
                              .copyWith(color: MedBuddyColors.primary),
                        ),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(
                              color: MedBuddyColors.primary, width: 1.5),
                          shape: RoundedRectangleBorder(
                            borderRadius:
                                BorderRadius.circular(MedBuddyDimens.radiusLg),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: MedBuddyDimens.spacingXxl),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(MedBuddyDimens.spacingXl),
              child: SizedBox(
                width: double.infinity,
                height: MedBuddyDimens.buttonHeightPrimary,
                child: ElevatedButton(
                  onPressed: () {
                    ref.read(onboardingProvider.notifier).setMedications(
                          medications
                              .map((m) => OnboardingMedication(
                                    name: m['name'] as String,
                                    dosage: m['dose'] as String,
                                    frequency: m['frequency'] as String,
                                    withFood: m['withFood'] as bool,
                                  ))
                              .toList(),
                        );
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const S08EmergencyContacts()),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: MedBuddyColors.primary,
                    foregroundColor: MedBuddyColors.pureWhite,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.circular(MedBuddyDimens.radiusLg),
                    ),
                  ),
                  child: Text(
                    'Next',
                    style: MedBuddyTextStyles.bodyBold
                        .copyWith(color: MedBuddyColors.pureWhite),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopBar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(
        top: MedBuddyDimens.spacingMd,
        left: MedBuddyDimens.spacingLg,
        right: MedBuddyDimens.spacingLg,
        bottom: MedBuddyDimens.spacingMd,
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: const Icon(Icons.arrow_back_ios_new,
                color: MedBuddyColors.slate900, size: 20),
          ),
          const SizedBox(width: MedBuddyDimens.spacingMd),
          const Expanded(child: _ProgressBar(current: 4, total: 6)),
        ],
      ),
    );
  }

  InputDecoration _sheetInput(String label) => InputDecoration(
        labelText: label,
        filled: true,
        fillColor: MedBuddyColors.slate100,
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
          borderSide: const BorderSide(color: MedBuddyColors.primary, width: 2),
        ),
      );
}

class _ProgressBar extends StatelessWidget {
  final int current;
  final int total;
  const _ProgressBar({required this.current, required this.total});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(
        total,
        (i) => Expanded(
          child: Container(
            height: 4,
            margin: const EdgeInsets.symmetric(horizontal: 2),
            decoration: BoxDecoration(
              color: i < current
                  ? MedBuddyColors.primary
                  : MedBuddyColors.slate300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ),
      ),
    );
  }
}
