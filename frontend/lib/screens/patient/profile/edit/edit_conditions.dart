import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../constants/colors.dart';
import '../../../../constants/dimens.dart';
import '../../../../constants/text_styles.dart';
import '../../../../providers/history_providers.dart';
import '../../../../services/api_service.dart';
import 'edit_scaffold.dart';

/// Dedicated editor for the Health Conditions section.
/// Adds/removes conditions and persists only the diff (POST new, DELETE removed).
class EditConditionsScreen extends ConsumerStatefulWidget {
  const EditConditionsScreen({super.key});

  @override
  ConsumerState<EditConditionsScreen> createState() =>
      _EditConditionsScreenState();
}

class _EditConditionsScreenState extends ConsumerState<EditConditionsScreen> {
  final _inputCtrl = TextEditingController();

  /// Original rows from the server: {id, name}.
  final List<Map<String, String>> _original = [];

  /// Working set of condition names (what the user wants after save).
  final List<String> _names = [];

  bool _loaded = false;
  bool _isLoading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _inputCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final dio = ref.read(apiServiceProvider);
      final res = await dio.get('/health-conditions/');
      final list = (res.data as List<dynamic>? ?? []);
      final seen = <String>{};
      for (final e in list) {
        final m = e as Map<String, dynamic>;
        final name = (m['name'] as String? ?? '').trim();
        final id = m['id'] as String? ?? '';
        if (name.isEmpty || id.isEmpty) continue;
        if (!seen.add(name.toLowerCase())) continue; // skip duplicates
        _original.add({'id': id, 'name': name});
        _names.add(name);
      }
    } catch (_) {
      // leave lists empty; user can still add
    }
    if (mounted) setState(() => _loaded = true);
  }

  void _add() {
    final name = _inputCtrl.text.trim();
    if (name.isEmpty) return;
    if (_names.any((n) => n.toLowerCase() == name.toLowerCase())) {
      setState(() => _error = 'That condition is already in the list.');
      return;
    }
    setState(() {
      _names.add(name);
      _inputCtrl.clear();
      _error = null;
    });
  }

  Future<void> _save() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    final dio = ref.read(apiServiceProvider);
    final working = _names.map((n) => n.toLowerCase()).toSet();
    final originalLower = _original.map((m) => m['name']!.toLowerCase()).toSet();

    final toDelete = _original
        .where((m) => !working.contains(m['name']!.toLowerCase()))
        .toList();
    final toAdd =
        _names.where((n) => !originalLower.contains(n.toLowerCase())).toList();

    try {
      await Future.wait([
        ...toDelete.map((m) => dio.delete('/health-conditions/${m['id']}')),
        ...toAdd.map((n) =>
            dio.post('/health-conditions/', data: {'name': n})),
      ]);
      ref.invalidate(healthConditionsProvider);
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
      title: 'Health Conditions',
      isLoading: _isLoading,
      canSave: _loaded,
      error: _error,
      onSave: _save,
      children: [
        const EditFieldLabel('Add a condition'),
        const SizedBox(height: MedBuddyDimens.spacingXs),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _inputCtrl,
                onSubmitted: (_) => _add(),
                style: MedBuddyTextStyles.body
                    .copyWith(color: MedBuddyColors.slate900),
                decoration: editInputDecoration('e.g. Hypertension'),
              ),
            ),
            const SizedBox(width: MedBuddyDimens.spacingSm),
            GestureDetector(
              onTap: _add,
              child: Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: MedBuddyColors.primary,
                  borderRadius: BorderRadius.circular(MedBuddyDimens.radiusMd),
                ),
                child: const Icon(Icons.add,
                    color: MedBuddyColors.pureWhite, size: 24),
              ),
            ),
          ],
        ),
        const SizedBox(height: MedBuddyDimens.spacingLg),
        if (!_loaded)
          const Center(
            child: Padding(
              padding: EdgeInsets.all(MedBuddyDimens.spacingXl),
              child: CircularProgressIndicator(color: MedBuddyColors.primary),
            ),
          )
        else if (_names.isEmpty)
          Text('No conditions added yet.',
              style: MedBuddyTextStyles.label
                  .copyWith(color: MedBuddyColors.slate500))
        else
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _names.map((name) {
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: MedBuddyColors.primaryLight,
                  borderRadius: BorderRadius.circular(MedBuddyDimens.radiusPill),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(name,
                        style: MedBuddyTextStyles.caption.copyWith(
                            color: MedBuddyColors.primaryDark,
                            fontWeight: FontWeight.w600)),
                    const SizedBox(width: 6),
                    GestureDetector(
                      onTap: () => setState(() => _names.remove(name)),
                      child: const Icon(Icons.close,
                          size: 16, color: MedBuddyColors.primaryDark),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
      ],
    );
  }
}
