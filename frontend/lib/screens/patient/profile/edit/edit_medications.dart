import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../utils/nav_helpers.dart';
import '../../../../constants/colors.dart';
import '../../../../constants/dimens.dart';
import '../../../../constants/text_styles.dart';
import '../../../../providers/medication_provider.dart';
import '../../../../widgets/shared/sos_button.dart';
import '../../medications/add_edit.dart';

/// Dedicated editor for the Medications section.
/// Lists current medications with per-row edit/delete, plus an add button.
/// Reuses [AddEditMedication] for the actual create/edit form.
class EditMedicationsScreen extends ConsumerWidget {
  const EditMedicationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final medState = ref.watch(medicationProvider);
    final meds = medState.medications;

    return Scaffold(
      backgroundColor: MedBuddyColors.warmWhite,
      body: Stack(
        children: [
          Column(
            children: [
              _buildAppBar(context),
              Expanded(
                child: medState.isLoading
                    ? const Center(
                        child: CircularProgressIndicator(
                            color: MedBuddyColors.primary))
                    : meds.isEmpty
                        ? Center(
                            child: Text('No medications added yet.',
                                style: MedBuddyTextStyles.label.copyWith(
                                    color: MedBuddyColors.slate500)),
                          )
                        : ListView.separated(
                            padding: const EdgeInsets.all(MedBuddyDimens.spacingLg),
                            itemCount: meds.length,
                            separatorBuilder: (_, _) =>
                                const SizedBox(height: MedBuddyDimens.spacingSm),
                            itemBuilder: (context, i) {
                              final m = meds[i];
                              return Container(
                                padding:
                                    const EdgeInsets.all(MedBuddyDimens.spacingLg),
                                decoration: BoxDecoration(
                                  color: MedBuddyColors.pureWhite,
                                  borderRadius: BorderRadius.circular(
                                      MedBuddyDimens.radiusLg),
                                  border: Border.all(
                                      color: MedBuddyColors.slate300, width: 0.5),
                                ),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(m.name,
                                              style: MedBuddyTextStyles.bodyBold
                                                  .copyWith(
                                                      color: MedBuddyColors
                                                          .slate900)),
                                          const SizedBox(height: 2),
                                          Text(
                                            '${m.dosage} · ${m.frequency.replaceAll('_', ' ')}',
                                            style: MedBuddyTextStyles.secondary
                                                .copyWith(
                                                    color:
                                                        MedBuddyColors.slate500),
                                          ),
                                        ],
                                      ),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.edit_outlined,
                                          color: MedBuddyColors.primary,
                                          size: 20),
                                      onPressed: () async {
                                        await Navigator.of(context).push(
                                          MaterialPageRoute(
                                            builder: (_) =>
                                                AddEditMedication(medication: m),
                                          ),
                                        );
                                      },
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.delete_outline,
                                          color: MedBuddyColors.emergency,
                                          size: 20),
                                      onPressed: () => _confirmDelete(
                                          context, ref, m.id, m.name),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
              ),
            ],
          ),
          const SOSButton(),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: MedBuddyColors.primary,
        foregroundColor: MedBuddyColors.pureWhite,
        elevation: 2,
        onPressed: () async {
          await Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const AddEditMedication()),
          );
        },
        tooltip: 'Add medication',
        child: const Icon(Icons.add, size: 28),
      ),
    );
  }

  void _confirmDelete(
      BuildContext context, WidgetRef ref, String id, String name) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete medication'),
        content: Text('Remove "$name" from your medications?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              ref.read(medicationProvider.notifier).deleteMedication(id);
            },
            child: const Text('Delete',
                style: TextStyle(color: MedBuddyColors.emergency)),
          ),
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
            onTap: () => goBack(context, fallbackRoute: '/my-profile'),
            child: const Icon(Icons.arrow_back_ios_new,
                color: MedBuddyColors.primaryDark, size: 20),
          ),
          const SizedBox(width: MedBuddyDimens.spacingMd),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('PROFILE', style: MedBuddyTextStyles.sectionHeader),
              Text('Medications',
                  style: MedBuddyTextStyles.heading2
                      .copyWith(color: MedBuddyColors.slate900)),
            ],
          ),
        ],
      ),
    );
  }
}
