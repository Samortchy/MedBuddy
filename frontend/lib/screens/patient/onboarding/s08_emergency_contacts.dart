import 'package:flutter/material.dart';
import '../../constants/colors.dart';
import '../../constants/dimens.dart';
import '../../constants/text_styles.dart';
import 's09_checkin_prefs.dart';

class S08EmergencyContacts extends StatefulWidget {
  const S08EmergencyContacts({super.key});

  @override
  State<S08EmergencyContacts> createState() => _S08EmergencyContactsState();
}

class _S08EmergencyContactsState extends State<S08EmergencyContacts> {
  final _primaryNameCtrl = TextEditingController();
  final _primaryPhoneCtrl = TextEditingController();
  final _secondaryNameCtrl = TextEditingController();
  final _secondaryPhoneCtrl = TextEditingController();
  String primaryRelation = 'Son / Daughter';
  String secondaryRelation = 'Son / Daughter';
  bool showSecondary = false;
  bool smsSent = false;

  final relations = [
    'Son / Daughter',
    'Spouse',
    'Sibling',
    'Parent',
    'Friend',
    'Nurse / Caregiver',
    'Other',
  ];

  bool get canProceed =>
      _primaryNameCtrl.text.trim().isNotEmpty &&
      _primaryPhoneCtrl.text.trim().isNotEmpty;

  @override
  void dispose() {
    _primaryNameCtrl.dispose();
    _primaryPhoneCtrl.dispose();
    _secondaryNameCtrl.dispose();
    _secondaryPhoneCtrl.dispose();
    super.dispose();
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
                      'Step 5 of 6',
                      style: MedBuddyTextStyles.label
                          .copyWith(color: MedBuddyColors.slate500),
                    ),
                    const SizedBox(height: MedBuddyDimens.spacingXs),
                    Text(
                      'Emergency Contacts',
                      style: MedBuddyTextStyles.heading1.copyWith(
                          fontSize: 26, color: MedBuddyColors.slate900),
                    ),
                    const SizedBox(height: MedBuddyDimens.spacingXs),
                    Text(
                      'These people will be notified if you miss a medication or need help. At least one contact is required.',
                      style: MedBuddyTextStyles.body
                          .copyWith(color: MedBuddyColors.slate500),
                    ),

                    const SizedBox(height: MedBuddyDimens.spacingXl),

                    // Notification info card
                    Container(
                      padding: const EdgeInsets.all(MedBuddyDimens.spacingMd),
                      decoration: BoxDecoration(
                        color: MedBuddyColors.primarySoft,
                        borderRadius:
                            BorderRadius.circular(MedBuddyDimens.radiusMd),
                        border: Border.all(
                            color: MedBuddyColors.primaryLight, width: 1),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'When will they be notified?',
                            style: MedBuddyTextStyles.secondary.copyWith(
                              fontWeight: FontWeight.w700,
                              color: MedBuddyColors.primaryDark,
                            ),
                          ),
                          const SizedBox(height: MedBuddyDimens.spacingSm),
                          const _NotifyRow(
                              text:
                                  'Medication not acknowledged after 15 minutes'),
                          const _NotifyRow(text: 'Emergency SOS activated'),
                          const _NotifyRow(
                              text: 'Fall detected and unverified'),
                          const _NotifyRow(text: '911 has been contacted'),
                        ],
                      ),
                    ),

                    const SizedBox(height: MedBuddyDimens.spacingXl),

                    // Primary
                    _ContactSection(
                      title: 'Primary Contact',
                      subtitle: 'Required',
                      nameCtrl: _primaryNameCtrl,
                      phoneCtrl: _primaryPhoneCtrl,
                      relation: primaryRelation,
                      relations: relations,
                      onRelationChanged: (v) =>
                          setState(() => primaryRelation = v!),
                      onChanged: () => setState(() {}),
                    ),

                    const SizedBox(height: MedBuddyDimens.spacingLg),

                    if (!showSecondary)
                      SizedBox(
                        width: double.infinity,
                        height: MedBuddyDimens.buttonHeightSecondary,
                        child: OutlinedButton.icon(
                          onPressed: () => setState(() => showSecondary = true),
                          icon: const Icon(Icons.person_add_outlined,
                              color: MedBuddyColors.primary, size: 20),
                          label: Text(
                            'Add Secondary Contact',
                            style: MedBuddyTextStyles.bodyBold
                                .copyWith(color: MedBuddyColors.primary),
                          ),
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(
                                color: MedBuddyColors.primary, width: 1.5),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(
                                  MedBuddyDimens.radiusLg),
                            ),
                          ),
                        ),
                      )
                    else ...[
                      _ContactSection(
                        title: 'Secondary Contact',
                        subtitle: 'Optional',
                        nameCtrl: _secondaryNameCtrl,
                        phoneCtrl: _secondaryPhoneCtrl,
                        relation: secondaryRelation,
                        relations: relations,
                        onRelationChanged: (v) =>
                            setState(() => secondaryRelation = v!),
                        onChanged: () => setState(() {}),
                      ),
                    ],

                    if (canProceed) ...[
                      const SizedBox(height: MedBuddyDimens.spacingXl),
                      GestureDetector(
                        onTap: () => setState(() => smsSent = true),
                        child: Container(
                          padding:
                              const EdgeInsets.all(MedBuddyDimens.spacingMd),
                          decoration: BoxDecoration(
                            color: smsSent
                                ? MedBuddyColors.successLight
                                : MedBuddyColors.pureWhite,
                            borderRadius:
                                BorderRadius.circular(MedBuddyDimens.radiusMd),
                            border: Border.all(
                              color: smsSent
                                  ? MedBuddyColors.success
                                  : MedBuddyColors.slate300,
                              width: 0.5,
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                smsSent
                                    ? Icons.check_circle
                                    : Icons.sms_outlined,
                                color: smsSent
                                    ? MedBuddyColors.success
                                    : MedBuddyColors.primary,
                                size: 20,
                              ),
                              const SizedBox(width: MedBuddyDimens.spacingSm),
                              Text(
                                smsSent
                                    ? 'Test SMS sent successfully!'
                                    : 'Send a test SMS to verify the number',
                                style: MedBuddyTextStyles.bodyBold.copyWith(
                                  color: smsSent
                                      ? MedBuddyColors.success
                                      : MedBuddyColors.primary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],

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
                  onPressed: canProceed
                      ? () => Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) => const S09CheckinPrefs()),
                          )
                      : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: MedBuddyColors.primary,
                    disabledBackgroundColor: MedBuddyColors.slate300,
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
            onTap: () => Navigator.maybePop(context),
            child: const Icon(Icons.arrow_back_ios_new,
                color: MedBuddyColors.slate900, size: 20),
          ),
          const SizedBox(width: MedBuddyDimens.spacingMd),
          const Expanded(child: _ProgressBar(current: 5, total: 6)),
        ],
      ),
    );
  }
}

class _NotifyRow extends StatelessWidget {
  final String text;
  const _NotifyRow({required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: MedBuddyDimens.spacingXs),
      child: Row(
        children: [
          const Icon(Icons.notifications_active,
              color: MedBuddyColors.primary, size: 14),
          const SizedBox(width: MedBuddyDimens.spacingSm),
          Expanded(
            child: Text(
              text,
              style: MedBuddyTextStyles.secondary
                  .copyWith(color: MedBuddyColors.primaryDark),
            ),
          ),
        ],
      ),
    );
  }
}

class _ContactSection extends StatelessWidget {
  final String title;
  final String subtitle;
  final TextEditingController nameCtrl;
  final TextEditingController phoneCtrl;
  final String relation;
  final List<String> relations;
  final ValueChanged<String?> onRelationChanged;
  final VoidCallback onChanged;

  const _ContactSection({
    required this.title,
    required this.subtitle,
    required this.nameCtrl,
    required this.phoneCtrl,
    required this.relation,
    required this.relations,
    required this.onRelationChanged,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                title,
                style: MedBuddyTextStyles.bodyBold
                    .copyWith(color: MedBuddyColors.slate900),
              ),
              const SizedBox(width: MedBuddyDimens.spacingSm),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: MedBuddyDimens.spacingSm, vertical: 2),
                decoration: BoxDecoration(
                  color: MedBuddyColors.primarySoft,
                  borderRadius:
                      BorderRadius.circular(MedBuddyDimens.radiusPill),
                ),
                child: Text(
                  subtitle,
                  style: MedBuddyTextStyles.caption.copyWith(
                    color: MedBuddyColors.primaryDark,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: MedBuddyDimens.spacingMd),
          TextField(
            controller: nameCtrl,
            onChanged: (_) => onChanged(),
            style: MedBuddyTextStyles.body
                .copyWith(color: MedBuddyColors.slate900),
            decoration: _dec('Full name'),
          ),
          const SizedBox(height: MedBuddyDimens.spacingSm),
          DropdownButtonFormField<String>(
            initialValue: relation,
            decoration: _dec('Relationship'),
            items: relations
                .map((r) => DropdownMenuItem(value: r, child: Text(r)))
                .toList(),
            onChanged: onRelationChanged,
          ),
          const SizedBox(height: MedBuddyDimens.spacingSm),
          TextField(
            controller: phoneCtrl,
            onChanged: (_) => onChanged(),
            keyboardType: TextInputType.phone,
            style: MedBuddyTextStyles.body
                .copyWith(color: MedBuddyColors.slate900),
            decoration: _dec('Phone number'),
          ),
        ],
      ),
    );
  }

  InputDecoration _dec(String label) => InputDecoration(
        labelText: label,
        filled: true,
        fillColor: MedBuddyColors.slate100,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(MedBuddyDimens.radiusMd),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(MedBuddyDimens.radiusMd),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(MedBuddyDimens.radiusMd),
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
