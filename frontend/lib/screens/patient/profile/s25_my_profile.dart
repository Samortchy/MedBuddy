import 'package:flutter/material.dart';
import '../../../constants/colors.dart';
import '../../../constants/dimens.dart';
import '../../../constants/text_styles.dart';
import '../../../services/service_interfaces.dart';
import '../../../widgets/shared/sos_button.dart';
import '../../../widgets/shared/bottom_nav_bar.dart';

/// S-25 — My Profile
///
/// Backend hooks:
/// - [profile]           → PatientProfile from your data layer
/// - [onEditSection]     → Called with section name when user taps edit
/// - [onGenerateInvite]  → Call to generate a 6-digit caregiver invite code
/// - [onRevokeCaregiver] → Call with caregiver ID to revoke access
class MyProfileScreen extends StatelessWidget {
  final PatientProfile profile;
  final ValueChanged<String>? onEditSection;
  final Future<String> Function()? onGenerateInvite;
  final ValueChanged<String>? onRevokeCaregiver;

  const MyProfileScreen({
    super.key,
    required this.profile,
    this.onEditSection,
    this.onGenerateInvite,
    this.onRevokeCaregiver,
  });

  void _handleGenerateInvite(BuildContext context) async {
    if (onGenerateInvite == null) {
      // TODO: wire to your backend invite code generation
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('Invite Code'),
          content: const Text(
              'Wire onGenerateInvite to your backend to generate a real 6-digit code.'),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('OK'))
          ],
        ),
      );
      return;
    }
    final code = await onGenerateInvite!();
    if (context.mounted) {
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('Share this code'),
          content: Text('Code: $code\n\nThis code expires in 24 hours.'),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Done'))
          ],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = profile;
    return Scaffold(
      backgroundColor: MedBuddyColors.warmWhite,
      body: Stack(
        children: [
          Column(
            children: [
              _buildAppBar(context),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.only(
                    bottom: MedBuddyDimens.bottomNavHeight +
                        MedBuddyDimens.sosBottomOffset,
                  ),
                  children: [
                    _buildProfileHeader(p),
                    Padding(
                      padding: const EdgeInsets.all(MedBuddyDimens.spacingMd),
                      child: Column(
                        children: [
                          _buildSectionCard(
                            icon: Icons.person_outline,
                            title: 'Basic Info',
                            iconColor: MedBuddyColors.primary,
                            onEdit: () => onEditSection?.call('basic_info'),
                            children: [
                              _infoRow('Name', p.fullName),
                              _infoRow('Age', '${p.age} years'),
                              _infoRow('Language', p.language),
                            ],
                          ),
                          const SizedBox(height: MedBuddyDimens.spacingMd),
                          _buildSectionCard(
                            icon: Icons.monitor_heart_outlined,
                            title: 'Health Conditions',
                            iconColor: MedBuddyColors.primary,
                            onEdit: () => onEditSection?.call('conditions'),
                            children: [
                              Wrap(
                                spacing: 6,
                                runSpacing: 6,
                                children:
                                    p.conditions.map((c) => _chip(c)).toList(),
                              ),
                            ],
                          ),
                          const SizedBox(height: MedBuddyDimens.spacingMd),
                          _buildSectionCard(
                            icon: Icons.medication_outlined,
                            title: 'Medications',
                            iconColor: MedBuddyColors.primary,
                            onEdit: () => onEditSection?.call('medications'),
                            children: [
                              if (p.medications.isEmpty)
                                Text(
                                  'No medications added',
                                  style: MedBuddyTextStyles.label.copyWith(
                                      color: MedBuddyColors.slate700),
                                )
                              else
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Wrap(
                                      spacing: 6,
                                      runSpacing: 6,
                                      children: p.medications
                                          .map((m) => _chip(m.name))
                                          .toList(),
                                    ),
                                    const SizedBox(height: 8),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 10, vertical: 3),
                                      decoration: BoxDecoration(
                                        color: MedBuddyColors.primary,
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      child: Text(
                                        '${p.medications.length} active',
                                        style: MedBuddyTextStyles.caption
                                            .copyWith(
                                                color: MedBuddyColors.pureWhite,
                                                fontWeight: FontWeight.w700),
                                      ),
                                    ),
                                  ],
                                ),
                            ],
                          ),
                          const SizedBox(height: MedBuddyDimens.spacingMd),
                          _buildSectionCard(
                            icon: Icons.phone_outlined,
                            title: 'Emergency Contacts',
                            iconColor: MedBuddyColors.emergency,
                            onEdit: () =>
                                onEditSection?.call('emergency_contacts'),
                            children: [
                              _infoRow('Primary',
                                  '${p.primaryContactName} (${p.primaryContactRelationship})'),
                              _infoRow('Phone', p.primaryContactPhone,
                                  valueColor: MedBuddyColors.primary),
                            ],
                          ),
                          const SizedBox(height: MedBuddyDimens.spacingMd),
                          _buildSectionCard(
                            icon: Icons.schedule_outlined,
                            title: 'Check-in Preferences',
                            iconColor: MedBuddyColors.primary,
                            onEdit: () => onEditSection?.call('checkin_prefs'),
                            children: [
                              _infoRow('Frequency',
                                  'Daily — ${p.checkInHour}:00 AM'),
                              _infoRow(
                                  'Modality',
                                  p.checkInVoiceMode
                                      ? 'Voice + Text'
                                      : 'Text only'),
                            ],
                          ),
                          const SizedBox(height: MedBuddyDimens.spacingMd),
                          _buildCaregiverSection(context, p),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              PatientBottomNavBar(
                activeTab: PatientNavTab.profile,
                onTabSelected: (tab) {
                  if (tab == PatientNavTab.profile) return;
                  switch (tab) {
                    case PatientNavTab.home:
                      Navigator.of(context).pushNamed('/home');
                    case PatientNavTab.chat:
                      Navigator.of(context).pushNamed('/ai-chat');
                    case PatientNavTab.meds:
                      Navigator.of(context).pushNamed('/medication-schedule');
                    case PatientNavTab.history:
                      Navigator.of(context).pushNamed('/wellness-history');
                    case PatientNavTab.profile:
                      break;
                  }
                },
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
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const SizedBox(width: 36),
          const Text('My Profile', style: MedBuddyTextStyles.heading3),
          IconButton(
            onPressed: () => onEditSection?.call('all'),
            icon:
                const Icon(Icons.edit_outlined, color: MedBuddyColors.primary),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileHeader(PatientProfile p) {
    return Container(
      color: MedBuddyColors.primary,
      padding: const EdgeInsets.symmetric(
        horizontal: MedBuddyDimens.spacingLg,
        vertical: MedBuddyDimens.spacingXl,
      ),
      child: Column(
        children: [
          Container(
            width: MedBuddyDimens.avatarSizeLarge,
            height: MedBuddyDimens.avatarSizeLarge,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: MedBuddyColors.pureWhite,
              border: Border.all(color: MedBuddyColors.primaryLight, width: 3),
            ),
            child: const Icon(Icons.person_outline,
                color: MedBuddyColors.primary, size: 40),
          ),
          const SizedBox(height: MedBuddyDimens.spacingMd),
          Text(p.fullName,
              style: MedBuddyTextStyles.heading1
                  .copyWith(color: MedBuddyColors.pureWhite)),
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
            decoration: BoxDecoration(
              color: MedBuddyColors.pureWhite.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(MedBuddyDimens.radiusPill),
            ),
            child: Text(
              p.conditions.join(' · '),
              style: MedBuddyTextStyles.label
                  .copyWith(color: const Color(0xFFE0FDF4)),
            ),
          ),
          const SizedBox(height: MedBuddyDimens.spacingMd),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: MedBuddyColors.pureWhite.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Profile completeness',
                    style: MedBuddyTextStyles.caption
                        .copyWith(color: const Color(0xFFE0FDF4))),
                Row(
                  children: [
                    SizedBox(
                      width: 80,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: p.profileCompleteness / 100,
                          backgroundColor:
                              MedBuddyColors.pureWhite.withValues(alpha: 0.2),
                          color: MedBuddyColors.primaryLight,
                          minHeight: 6,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text('${p.profileCompleteness}%',
                        style: MedBuddyTextStyles.caption.copyWith(
                            color: MedBuddyColors.pureWhite,
                            fontWeight: FontWeight.w600)),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionCard({
    required IconData icon,
    required String title,
    required Color iconColor,
    required VoidCallback onEdit,
    required List<Widget> children,
  }) {
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
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: iconColor,
                      borderRadius:
                          BorderRadius.circular(MedBuddyDimens.radiusSm),
                    ),
                    child:
                        Icon(icon, color: MedBuddyColors.pureWhite, size: 14),
                  ),
                  const SizedBox(width: MedBuddyDimens.spacingSm),
                  Text(title,
                      style: MedBuddyTextStyles.bodyBold
                          .copyWith(color: MedBuddyColors.primaryDark)),
                ],
              ),
              GestureDetector(
                onTap: onEdit,
                child: const Icon(Icons.chevron_right,
                    color: MedBuddyColors.primary),
              ),
            ],
          ),
          const SizedBox(height: MedBuddyDimens.spacingMd),
          ...children,
        ],
      ),
    );
  }

  Widget _infoRow(String label, String value, {Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 5),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: MedBuddyTextStyles.label),
          Text(value,
              style: MedBuddyTextStyles.label.copyWith(
                fontWeight: FontWeight.w600,
                color: valueColor ?? MedBuddyColors.slate700,
              )),
        ],
      ),
    );
  }

  Widget _chip(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: MedBuddyColors.primaryLight,
        borderRadius: BorderRadius.circular(MedBuddyDimens.radiusPill),
      ),
      child: Text(label,
          style: MedBuddyTextStyles.caption.copyWith(
              color: MedBuddyColors.primaryDark, fontWeight: FontWeight.w600)),
    );
  }

  Widget _buildCaregiverSection(BuildContext context, PatientProfile p) {
    return Container(
      padding: const EdgeInsets.all(MedBuddyDimens.spacingMd),
      decoration: BoxDecoration(
        color: MedBuddyColors.pureWhite,
        borderRadius: BorderRadius.circular(MedBuddyDimens.radiusLg),
        border: Border.all(
            color: MedBuddyColors.primary,
            width: 1.5,
            style: BorderStyle.solid),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Caregiver Access',
              style: MedBuddyTextStyles.bodyBold
                  .copyWith(color: MedBuddyColors.primaryDark)),
          const SizedBox(height: MedBuddyDimens.spacingMd),
          ...p.caregivers.map((cg) => _caregiverCard(context, cg)),
          const SizedBox(height: MedBuddyDimens.spacingSm),
          GestureDetector(
            onTap: () => _handleGenerateInvite(context),
            child: Container(
              padding: const EdgeInsets.all(MedBuddyDimens.spacingMd),
              decoration: BoxDecoration(
                border: Border.all(color: MedBuddyColors.primary, width: 1.5),
                borderRadius: BorderRadius.circular(MedBuddyDimens.radiusMd),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.add,
                      color: MedBuddyColors.primary, size: 18),
                  const SizedBox(width: 8),
                  Text('Invite a Caregiver',
                      style: MedBuddyTextStyles.body.copyWith(
                          color: MedBuddyColors.primary,
                          fontWeight: FontWeight.w600)),
                ],
              ),
            ),
          ),
          const SizedBox(height: MedBuddyDimens.spacingSm),
          const Center(
            child: Text('Generates a 6-digit invite code',
                style: MedBuddyTextStyles.caption),
          ),
        ],
      ),
    );
  }

  Widget _caregiverCard(BuildContext context, CaregiverLink cg) {
    return Container(
      margin: const EdgeInsets.only(bottom: MedBuddyDimens.spacingMd),
      padding: const EdgeInsets.symmetric(
        horizontal: MedBuddyDimens.spacingMd,
        vertical: MedBuddyDimens.spacingMd,
      ),
      decoration: BoxDecoration(
        color: MedBuddyColors.primarySoft,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: const BoxDecoration(
              color: MedBuddyColors.primary,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(cg.initials,
                  style: MedBuddyTextStyles.label.copyWith(
                      color: MedBuddyColors.pureWhite,
                      fontWeight: FontWeight.w700)),
            ),
          ),
          const SizedBox(width: MedBuddyDimens.spacingMd),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(cg.name,
                    style: MedBuddyTextStyles.bodyBold.copyWith(fontSize: 14)),
                Text(
                    '${cg.relationship} · ${cg.isActive ? "Active" : "Pending"}',
                    style: MedBuddyTextStyles.caption),
              ],
            ),
          ),
          GestureDetector(
            onTap: () => onRevokeCaregiver?.call(cg.id),
            child: Text('Revoke',
                style: MedBuddyTextStyles.label.copyWith(
                    color: MedBuddyColors.emergency,
                    fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }
}
