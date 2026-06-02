import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../constants/colors.dart';
import '../../../../constants/dimens.dart';
import '../../../../constants/text_styles.dart';
import '../../../../providers/history_providers.dart';
import '../../../../services/api_service.dart';
import '../../../../widgets/shared/sos_button.dart';

const int _maxContacts = 5;

/// Dedicated editor for the Emergency Contacts section.
class EditContactsScreen extends ConsumerWidget {
  const EditContactsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final contactsState = ref.watch(emergencyContactsProvider);
    final contacts = contactsState.valueOrNull ?? [];

    return Scaffold(
      backgroundColor: MedBuddyColors.warmWhite,
      body: Stack(
        children: [
          Column(
            children: [
              _buildAppBar(context),
              Expanded(
                child: contactsState.isLoading
                    ? const Center(
                        child: CircularProgressIndicator(
                            color: MedBuddyColors.primary))
                    : contacts.isEmpty
                        ? Center(
                            child: Text('No emergency contacts added yet.',
                                style: MedBuddyTextStyles.label.copyWith(
                                    color: MedBuddyColors.slate500)),
                          )
                        : ListView.separated(
                            padding:
                                const EdgeInsets.all(MedBuddyDimens.spacingLg),
                            itemCount: contacts.length,
                            separatorBuilder: (_, _) => const SizedBox(
                                height: MedBuddyDimens.spacingSm),
                            itemBuilder: (context, i) {
                              final c = contacts[i];
                              return Container(
                                padding: const EdgeInsets.all(
                                    MedBuddyDimens.spacingLg),
                                decoration: BoxDecoration(
                                  color: MedBuddyColors.pureWhite,
                                  borderRadius: BorderRadius.circular(
                                      MedBuddyDimens.radiusLg),
                                  border: Border.all(
                                      color: MedBuddyColors.slate300,
                                      width: 0.5),
                                ),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            c.relationship.isNotEmpty
                                                ? '${c.name} (${c.relationship})'
                                                : c.name,
                                            style: MedBuddyTextStyles.bodyBold
                                                .copyWith(
                                                    color: MedBuddyColors
                                                        .slate900),
                                          ),
                                          const SizedBox(height: 2),
                                          Text(c.phone,
                                              style: MedBuddyTextStyles.secondary
                                                  .copyWith(
                                                      color: MedBuddyColors
                                                          .slate500)),
                                        ],
                                      ),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.edit_outlined,
                                          color: MedBuddyColors.primary,
                                          size: 20),
                                      onPressed: () =>
                                          _openForm(context, ref, existing: c),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.delete_outline,
                                          color: MedBuddyColors.emergency,
                                          size: 20),
                                      onPressed: () =>
                                          _delete(context, ref, c),
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
        onPressed: () {
          if (contacts.length >= _maxContacts) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                  content: Text('Maximum of 5 emergency contacts allowed.')),
            );
            return;
          }
          _openForm(context, ref);
        },
        tooltip: 'Add contact',
        child: const Icon(Icons.add, size: 28),
      ),
    );
  }

  Future<void> _openForm(BuildContext context, WidgetRef ref,
      {EmergencyContactData? existing}) async {
    final result = await showDialog<Map<String, String>>(
      context: context,
      builder: (_) => _ContactFormDialog(existing: existing),
    );
    if (result == null) return;

    final dio = ref.read(apiServiceProvider);
    try {
      if (existing != null) {
        await dio.patch('/emergency-contacts/${existing.id}', data: {
          'name': result['name'],
          'phone': result['phone'],
          'relationship': result['relationship'],
        });
      } else {
        final contacts = ref.read(emergencyContactsProvider).valueOrNull ?? [];
        final used = contacts.map((c) => c.priority).toSet();
        int priority = 1;
        while (used.contains(priority) && priority < _maxContacts) {
          priority++;
        }
        await dio.post('/emergency-contacts/', data: {
          'name': result['name'],
          'phone': result['phone'],
          'relationship': result['relationship'],
          'priority': priority,
        });
      }
      ref.invalidate(emergencyContactsProvider);
    } on DioException catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(
                  e.response?.data?['detail']?.toString() ??
                      'Failed to save contact')),
        );
      }
    }
  }

  Future<void> _delete(
      BuildContext context, WidgetRef ref, EmergencyContactData c) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete contact'),
        content: Text('Remove ${c.name} from your emergency contacts?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel')),
          TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Delete',
                  style: TextStyle(color: MedBuddyColors.emergency))),
        ],
      ),
    );
    if (confirm != true) return;
    final dio = ref.read(apiServiceProvider);
    try {
      await dio.delete('/emergency-contacts/${c.id}');
      ref.invalidate(emergencyContactsProvider);
    } on DioException catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(e.response?.data?['detail']?.toString() ??
                  'Failed to delete contact')),
        );
      }
    }
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
              const Text('PROFILE', style: MedBuddyTextStyles.sectionHeader),
              Text('Emergency Contacts',
                  style: MedBuddyTextStyles.heading2
                      .copyWith(color: MedBuddyColors.slate900)),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Add/Edit dialog ───────────────────────────────────────────────────────────

class _ContactFormDialog extends StatefulWidget {
  final EmergencyContactData? existing;
  const _ContactFormDialog({this.existing});

  @override
  State<_ContactFormDialog> createState() => _ContactFormDialogState();
}

class _ContactFormDialogState extends State<_ContactFormDialog> {
  late final TextEditingController _name;
  late final TextEditingController _phone;
  late final TextEditingController _relationship;

  @override
  void initState() {
    super.initState();
    _name = TextEditingController(text: widget.existing?.name ?? '');
    _phone = TextEditingController(text: widget.existing?.phone ?? '');
    _relationship =
        TextEditingController(text: widget.existing?.relationship ?? '');
  }

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    _relationship.dispose();
    super.dispose();
  }

  bool get _valid =>
      _name.text.trim().isNotEmpty && _phone.text.trim().length >= 7;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.existing != null ? 'Edit Contact' : 'Add Contact'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _name,
            onChanged: (_) => setState(() {}),
            decoration: const InputDecoration(labelText: 'Name'),
          ),
          TextField(
            controller: _phone,
            keyboardType: TextInputType.phone,
            onChanged: (_) => setState(() {}),
            decoration: const InputDecoration(labelText: 'Phone'),
          ),
          TextField(
            controller: _relationship,
            decoration:
                const InputDecoration(labelText: 'Relationship (optional)'),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: _valid
              ? () => Navigator.pop(context, {
                    'name': _name.text.trim(),
                    'phone': _phone.text.trim(),
                    'relationship': _relationship.text.trim(),
                  })
              : null,
          child: const Text('Save'),
        ),
      ],
    );
  }
}
