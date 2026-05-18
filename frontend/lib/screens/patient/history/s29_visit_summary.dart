import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../constants/colors.dart';
import '../../../constants/dimens.dart';
import '../../../constants/text_styles.dart';
import '../../../services/api_service.dart';
import '../../../widgets/shared/sos_button.dart';

// ── Provider ──────────────────────────────────────────────────────────────────

class _VisitSummaryNotifier
    extends StateNotifier<AsyncValue<List<VisitSummary>>> {
  final Dio _dio;

  _VisitSummaryNotifier(this._dio) : super(const AsyncValue.loading()) {
    fetch();
  }

  Future<void> fetch() async {
    state = const AsyncValue.loading();
    try {
      final response = await _dio.get('/visit-summaries/');
      final list = response.data as List<dynamic>? ?? [];
      final summaries = list
          .map((e) => VisitSummary.fromJson(e as Map<String, dynamic>))
          .toList();
      state = AsyncValue.data(summaries);
    } on DioException catch (e) {
      state = AsyncValue.error(
        e.response?.data?['detail'] ?? e.message ?? 'Failed to load',
        e.stackTrace,
      );
    } catch (e) {
      state = AsyncValue.error(e.toString(), StackTrace.current);
    }
  }

  Future<void> add({
    required String rawTranscript,
    String? diagnosis,
    String? medicationsChanged,
    String? instructions,
  }) async {
    final body = <String, dynamic>{'raw_transcript': rawTranscript};
    if (diagnosis != null) body['diagnosis'] = diagnosis;
    if (medicationsChanged != null) body['medications_changed'] = medicationsChanged;
    if (instructions != null) body['instructions'] = instructions;
    await _dio.post('/visit-summaries/', data: body);
    await fetch();
  }
}

final _visitSummaryProvider = StateNotifierProvider<_VisitSummaryNotifier,
    AsyncValue<List<VisitSummary>>>(
  (ref) => _VisitSummaryNotifier(ref.watch(apiServiceProvider)),
);

// ── Screen ────────────────────────────────────────────────────────────────────

class VisitSummaryScreen extends ConsumerStatefulWidget {
  const VisitSummaryScreen({super.key});

  @override
  ConsumerState<VisitSummaryScreen> createState() => _VisitSummaryScreenState();
}

class _VisitSummaryScreenState extends ConsumerState<VisitSummaryScreen> {
  final _notesCtrl = TextEditingController();
  bool _isSaving = false;
  String? _saveError;

  @override
  void dispose() {
    _notesCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final text = _notesCtrl.text.trim();
    if (text.isEmpty) return;
    setState(() {
      _isSaving = true;
      _saveError = null;
    });
    try {
      await ref.read(_visitSummaryProvider.notifier).add(rawTranscript: text);
      if (mounted) {
        _notesCtrl.clear();
        setState(() => _isSaving = false);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isSaving = false;
          _saveError = e.toString();
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final summariesState = ref.watch(_visitSummaryProvider);

    return Scaffold(
      backgroundColor: MedBuddyColors.warmWhite,
      body: Stack(
        children: [
          Column(
            children: [
              _buildAppBar(),
              Expanded(
                child: summariesState.when(
                  loading: () => const Center(
                    child:
                        CircularProgressIndicator(color: MedBuddyColors.primary),
                  ),
                  error: (e, _) => Center(
                    child: Padding(
                      padding: const EdgeInsets.all(MedBuddyDimens.spacingLg),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(e.toString(),
                              textAlign: TextAlign.center,
                              style: MedBuddyTextStyles.body.copyWith(
                                  color: MedBuddyColors.emergency)),
                          const SizedBox(height: 12),
                          ElevatedButton(
                            onPressed: () => ref
                                .read(_visitSummaryProvider.notifier)
                                .fetch(),
                            child: const Text('Retry'),
                          ),
                        ],
                      ),
                    ),
                  ),
                  data: (summaries) => ListView(
                    padding: const EdgeInsets.only(
                      left: MedBuddyDimens.spacingLg,
                      right: MedBuddyDimens.spacingLg,
                      top: MedBuddyDimens.spacingXl,
                      bottom: MedBuddyDimens.bottomNavHeight +
                          MedBuddyDimens.sosBottomOffset,
                    ),
                    children: [
                      _buildNewNoteSection(),
                      if (summaries.isNotEmpty) ...[
                        const SizedBox(height: MedBuddyDimens.spacingXl),
                        Text(
                          'Previous Summaries',
                          style: MedBuddyTextStyles.bodyBold.copyWith(
                              color: MedBuddyColors.slate700),
                        ),
                        const SizedBox(height: MedBuddyDimens.spacingMd),
                        ...summaries.map((s) => Padding(
                              padding: const EdgeInsets.only(
                                  bottom: MedBuddyDimens.spacingMd),
                              child: _buildSummaryCard(s),
                            )),
                      ] else ...[
                        const SizedBox(height: MedBuddyDimens.spacingXl),
                        Center(
                          child: Text(
                            'No visit summaries yet.\nAdd your first note above.',
                            textAlign: TextAlign.center,
                            style: MedBuddyTextStyles.body
                                .copyWith(color: MedBuddyColors.slate500),
                          ),
                        ),
                      ],
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
              child: Text('Visit Summary',
                  style: MedBuddyTextStyles.heading3,
                  textAlign: TextAlign.center)),
          const SizedBox(width: 36),
        ],
      ),
    );
  }

  Widget _buildNewNoteSection() {
    return Container(
      padding: const EdgeInsets.all(MedBuddyDimens.spacingMd),
      decoration: BoxDecoration(
        color: MedBuddyColors.pureWhite,
        borderRadius: BorderRadius.circular(MedBuddyDimens.radiusLg),
        border: Border.all(color: MedBuddyColors.slate300, width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.note_add_outlined,
                  color: MedBuddyColors.primary, size: 18),
              const SizedBox(width: 8),
              Text('New Visit Note',
                  style: MedBuddyTextStyles.bodyBold
                      .copyWith(color: MedBuddyColors.primaryDark)),
            ],
          ),
          const SizedBox(height: MedBuddyDimens.spacingMd),
          TextField(
            controller: _notesCtrl,
            maxLines: 6,
            style:
                MedBuddyTextStyles.body.copyWith(color: MedBuddyColors.slate900),
            decoration: InputDecoration(
              hintText:
                  'Describe your visit — diagnosis, medication changes, doctor instructions, next appointment…',
              hintStyle: MedBuddyTextStyles.body
                  .copyWith(color: MedBuddyColors.slate500),
              filled: true,
              fillColor: MedBuddyColors.slate100,
              contentPadding: const EdgeInsets.all(MedBuddyDimens.spacingMd),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(MedBuddyDimens.radiusMd),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(MedBuddyDimens.radiusMd),
                borderSide: const BorderSide(
                    color: MedBuddyColors.primaryMid, width: 1.5),
              ),
            ),
          ),
          if (_saveError != null) ...[
            const SizedBox(height: MedBuddyDimens.spacingSm),
            Text(_saveError!,
                style: MedBuddyTextStyles.caption
                    .copyWith(color: MedBuddyColors.emergency)),
          ],
          const SizedBox(height: MedBuddyDimens.spacingMd),
          SizedBox(
            width: double.infinity,
            height: MedBuddyDimens.buttonHeightPrimary,
            child: ElevatedButton(
              onPressed: _isSaving ? null : _save,
              style: ElevatedButton.styleFrom(
                backgroundColor: MedBuddyColors.primary,
                disabledBackgroundColor: MedBuddyColors.slate300,
                elevation: 0,
                shape: RoundedRectangleBorder(
                    borderRadius:
                        BorderRadius.circular(MedBuddyDimens.radiusMd)),
              ),
              child: _isSaving
                  ? const SizedBox(
                      height: 22,
                      width: 22,
                      child: CircularProgressIndicator(
                          strokeWidth: 2.5, color: Colors.white),
                    )
                  : Text('Save Note',
                      style: MedBuddyTextStyles.bodyBold
                          .copyWith(color: MedBuddyColors.pureWhite)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(VisitSummary summary) {
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
          Row(
            children: [
              const Icon(Icons.description_outlined,
                  color: MedBuddyColors.primary, size: 16),
              const SizedBox(width: 8),
              Text('Visit — ${summary.date}',
                  style: MedBuddyTextStyles.label.copyWith(
                      fontWeight: FontWeight.w700,
                      color: MedBuddyColors.primaryDark)),
            ],
          ),
          const Divider(color: MedBuddyColors.primaryLight, height: 16),
          if (summary.diagnosis.isNotEmpty)
            _summaryField('NOTES', summary.diagnosis),
          if (summary.medicationsChanged.isNotEmpty)
            _summaryField('MEDICATIONS CHANGED', summary.medicationsChanged),
          if (summary.instructions.isNotEmpty)
            _summaryField("INSTRUCTIONS", summary.instructions),
          if (summary.nextAppointment.isNotEmpty)
            _summaryField('NEXT APPOINTMENT', summary.nextAppointment,
                isLast: true),
          if (summary.diagnosis.isEmpty &&
              summary.medicationsChanged.isEmpty &&
              summary.instructions.isEmpty &&
              summary.nextAppointment.isEmpty)
            Text('(no details recorded)',
                style: MedBuddyTextStyles.caption
                    .copyWith(color: MedBuddyColors.slate500)),
        ],
      ),
    );
  }

  Widget _summaryField(String label, String value, {bool isLast = false}) {
    return Padding(
      padding: EdgeInsets.only(bottom: isLast ? 0 : MedBuddyDimens.spacingMd),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: MedBuddyTextStyles.sectionHeader),
          const SizedBox(height: 3),
          Text(value,
              style: MedBuddyTextStyles.label
                  .copyWith(color: MedBuddyColors.slate700)),
        ],
      ),
    );
  }
}

// ── Data model ────────────────────────────────────────────────────────────────

class VisitSummary {
  final String id;
  final String date;
  final String diagnosis;
  final String medicationsChanged;
  final String instructions;
  final String nextAppointment;

  const VisitSummary({
    required this.id,
    required this.date,
    required this.diagnosis,
    required this.medicationsChanged,
    required this.instructions,
    required this.nextAppointment,
  });

  factory VisitSummary.fromJson(Map<String, dynamic> json) {
    final recordedAt = json['recorded_at'] as String? ?? '';
    final date = recordedAt.isEmpty ? 'Unknown date' : _formatDate(recordedAt);
    final transcript = json['raw_transcript'] as String? ?? '';
    final diagnosisRaw = json['diagnosis'] as String? ?? '';
    return VisitSummary(
      id: json['id'] as String? ?? '',
      date: date,
      diagnosis: diagnosisRaw.isNotEmpty ? diagnosisRaw : transcript,
      medicationsChanged: json['medications_changed'] as String? ?? '',
      instructions: json['instructions'] as String? ?? '',
      nextAppointment: json['next_appointment'] as String? ?? '',
    );
  }

  static String _formatDate(String iso) {
    try {
      final dt = DateTime.parse(iso).toLocal();
      const months = [
        '',
        'Jan',
        'Feb',
        'Mar',
        'Apr',
        'May',
        'Jun',
        'Jul',
        'Aug',
        'Sep',
        'Oct',
        'Nov',
        'Dec'
      ];
      return '${months[dt.month]} ${dt.day}, ${dt.year}';
    } catch (_) {
      return iso;
    }
  }
}
