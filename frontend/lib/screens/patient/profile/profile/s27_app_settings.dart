import 'package:flutter/material.dart';
import '../../../constants/colors.dart';
import '../../../constants/dimens.dart';
import '../../../constants/text_styles.dart';
import '../../../widgets/shared/sos_button.dart';
import '../../../widgets/shared/bottom_nav_bar.dart';

/// S-27 — App Settings
///
/// Backend hooks:
/// - All onChanged callbacks → persist to your settings storage (SharedPreferences, Hive, etc.)
/// - [onExportData]   → Trigger data export
/// - [onDeleteAccount]→ Trigger account deletion flow
/// - [onTestSOS]      → Trigger a test SOS alert
class AppSettingsScreen extends StatefulWidget {
  // Notification settings
  final bool reminderSoundEnabled;
  final bool vibrationEnabled;
  final double reminderVolume;
  final ValueChanged<bool>? onReminderSoundChanged;
  final ValueChanged<bool>? onVibrationChanged;
  final ValueChanged<double>? onReminderVolumeChanged;

  // Voice settings
  final String ttsSpeed; // 'slow' | 'normal' | 'fast'
  final String voiceGender; // 'female' | 'male'
  final bool readAloud;
  final ValueChanged<String>? onTTSSpeedChanged;
  final ValueChanged<String>? onVoiceGenderChanged;
  final ValueChanged<bool>? onReadAloudChanged;

  // Emergency settings
  final double alarmVolume;
  final ValueChanged<double>? onAlarmVolumeChanged;
  final VoidCallback? onTestSOS;

  // Privacy
  final VoidCallback? onExportData;
  final VoidCallback? onDeleteAccount;

  const AppSettingsScreen({
    super.key,
    this.reminderSoundEnabled = true,
    this.vibrationEnabled = true,
    this.reminderVolume = 0.7,
    this.onReminderSoundChanged,
    this.onVibrationChanged,
    this.onReminderVolumeChanged,
    this.ttsSpeed = 'normal',
    this.voiceGender = 'female',
    this.readAloud = true,
    this.onTTSSpeedChanged,
    this.onVoiceGenderChanged,
    this.onReadAloudChanged,
    this.alarmVolume = 0.9,
    this.onAlarmVolumeChanged,
    this.onTestSOS,
    this.onExportData,
    this.onDeleteAccount,
  });

  @override
  State<AppSettingsScreen> createState() => _AppSettingsScreenState();
}

class _AppSettingsScreenState extends State<AppSettingsScreen> {
  late bool _reminderSound;
  late bool _vibration;
  late double _reminderVolume;
  late String _ttsSpeed;
  late String _voiceGender;
  late bool _readAloud;
  late double _alarmVolume;

  @override
  void initState() {
    super.initState();
    _reminderSound = widget.reminderSoundEnabled;
    _vibration = widget.vibrationEnabled;
    _reminderVolume = widget.reminderVolume;
    _ttsSpeed = widget.ttsSpeed;
    _voiceGender = widget.voiceGender;
    _readAloud = widget.readAloud;
    _alarmVolume = widget.alarmVolume;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: MedBuddyColors.warmWhite,
      body: Stack(
        children: [
          Column(
            children: [
              _buildAppBar(),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.only(
                    left: MedBuddyDimens.spacingMd,
                    right: MedBuddyDimens.spacingMd,
                    top: MedBuddyDimens.spacingMd,
                    bottom: MedBuddyDimens.bottomNavHeight +
                        MedBuddyDimens.sosBottomOffset,
                  ),
                  children: [
                    _sectionHeader('NOTIFICATIONS'),
                    _buildNotificationsSection(),
                    const SizedBox(height: MedBuddyDimens.spacingLg),
                    _sectionHeader('VOICE & AUDIO'),
                    _buildVoiceSection(),
                    const SizedBox(height: MedBuddyDimens.spacingLg),
                    _sectionHeader('EMERGENCY'),
                    _buildEmergencySection(),
                    const SizedBox(height: MedBuddyDimens.spacingLg),
                    _sectionHeader('PRIVACY'),
                    _buildPrivacySection(),
                    const SizedBox(height: MedBuddyDimens.spacingLg),
                    _sectionHeader('ABOUT'),
                    _buildAboutSection(),
                  ],
                ),
              ),
              PatientBottomNavBar(
                activeTab: PatientNavTab.profile,
                onTabSelected: (_) {},
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
        bottom: MedBuddyDimens.spacingMd,
      ),
      decoration: const BoxDecoration(
        color: MedBuddyColors.pureWhite,
        border: Border(
            bottom: BorderSide(color: MedBuddyColors.slate300, width: 0.5)),
      ),
      child: const Center(
          child: Text('Settings', style: MedBuddyTextStyles.heading3)),
    );
  }

  Widget _sectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(title, style: MedBuddyTextStyles.sectionHeader),
    );
  }

  Widget _buildCard(List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: MedBuddyColors.pureWhite,
        borderRadius: BorderRadius.circular(MedBuddyDimens.radiusLg),
        border: Border.all(color: MedBuddyColors.slate300, width: 0.5),
      ),
      child: Column(
        children: children.asMap().entries.map((e) {
          final isLast = e.key == children.length - 1;
          return Column(
            children: [
              e.value,
              if (!isLast)
                const Divider(color: MedBuddyColors.slate100, height: 1),
            ],
          );
        }).toList(),
      ),
    );
  }

  Widget _toggleRow({
    required IconData icon,
    required String label,
    required bool value,
    required ValueChanged<bool> onChanged,
    Color iconColor = MedBuddyColors.primary,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: MedBuddyDimens.spacingLg,
        vertical: MedBuddyDimens.spacingMd,
      ),
      child: Row(
        children: [
          Icon(icon, color: iconColor, size: 18),
          const SizedBox(width: MedBuddyDimens.spacingMd),
          Expanded(child: Text(label, style: MedBuddyTextStyles.body)),
          Switch(
            value: value,
            onChanged: onChanged,
            activeThumbColor: MedBuddyColors.primary,
          ),
        ],
      ),
    );
  }

  Widget _sliderRow({
    required IconData icon,
    required String label,
    required double value,
    required ValueChanged<double> onChanged,
    Color iconColor = MedBuddyColors.primary,
    Color sliderColor = MedBuddyColors.primary,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: MedBuddyDimens.spacingLg,
        vertical: MedBuddyDimens.spacingMd,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: iconColor, size: 18),
              const SizedBox(width: MedBuddyDimens.spacingMd),
              Text(label, style: MedBuddyTextStyles.body),
            ],
          ),
          const SizedBox(height: MedBuddyDimens.spacingSm),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: sliderColor,
              thumbColor: sliderColor,
              inactiveTrackColor: MedBuddyColors.slate300,
              trackHeight: 6,
            ),
            child: Slider(value: value, onChanged: onChanged),
          ),
        ],
      ),
    );
  }

  Widget _chevronRow({
    required IconData icon,
    required String label,
    required VoidCallback? onTap,
    Color? labelColor,
    Color iconColor = MedBuddyColors.primary,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: MedBuddyDimens.spacingLg,
          vertical: MedBuddyDimens.spacingMd,
        ),
        child: Row(
          children: [
            Icon(icon, color: iconColor, size: 18),
            const SizedBox(width: MedBuddyDimens.spacingMd),
            Expanded(
              child: Text(label,
                  style: MedBuddyTextStyles.body
                      .copyWith(color: labelColor ?? MedBuddyColors.slate900)),
            ),
            const Icon(Icons.chevron_right, color: MedBuddyColors.slate300),
          ],
        ),
      ),
    );
  }

  Widget _buildNotificationsSection() {
    return _buildCard([
      _toggleRow(
        icon: Icons.notifications_outlined,
        label: 'Reminder sound',
        value: _reminderSound,
        onChanged: (v) {
          setState(() => _reminderSound = v);
          widget.onReminderSoundChanged?.call(v);
        },
      ),
      _toggleRow(
        icon: Icons.vibration,
        label: 'Vibration',
        value: _vibration,
        onChanged: (v) {
          setState(() => _vibration = v);
          widget.onVibrationChanged?.call(v);
        },
      ),
      _sliderRow(
        icon: Icons.volume_up_outlined,
        label: 'Reminder volume',
        value: _reminderVolume,
        onChanged: (v) {
          setState(() => _reminderVolume = v);
          widget.onReminderVolumeChanged?.call(v);
        },
      ),
    ]);
  }

  Widget _buildVoiceSection() {
    return _buildCard([
      Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: MedBuddyDimens.spacingLg,
          vertical: MedBuddyDimens.spacingMd,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.speed_outlined,
                    color: MedBuddyColors.primary, size: 18),
                SizedBox(width: MedBuddyDimens.spacingMd),
                Text('TTS speed', style: MedBuddyTextStyles.body),
              ],
            ),
            const SizedBox(height: MedBuddyDimens.spacingMd),
            Row(
              children: ['Slow', 'Normal', 'Fast'].map((speed) {
                final isSelected = _ttsSpeed == speed.toLowerCase();
                return Expanded(
                  child: GestureDetector(
                    onTap: () {
                      setState(() => _ttsSpeed = speed.toLowerCase());
                      widget.onTTSSpeedChanged?.call(speed.toLowerCase());
                    },
                    child: Container(
                      margin: const EdgeInsets.only(right: 8),
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? MedBuddyColors.primary
                            : MedBuddyColors.slate100,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(speed,
                          textAlign: TextAlign.center,
                          style: MedBuddyTextStyles.label.copyWith(
                            color: isSelected
                                ? MedBuddyColors.pureWhite
                                : MedBuddyColors.slate500,
                            fontWeight:
                                isSelected ? FontWeight.w600 : FontWeight.w400,
                          )),
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
      _toggleRow(
        icon: Icons.mic_outlined,
        label: 'Read responses aloud',
        value: _readAloud,
        onChanged: (v) {
          setState(() => _readAloud = v);
          widget.onReadAloudChanged?.call(v);
        },
      ),
      Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: MedBuddyDimens.spacingLg,
          vertical: MedBuddyDimens.spacingMd,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Row(
              children: [
                Icon(Icons.person_outline,
                    color: MedBuddyColors.primary, size: 18),
                SizedBox(width: MedBuddyDimens.spacingMd),
                Text('Voice gender', style: MedBuddyTextStyles.body),
              ],
            ),
            Container(
              decoration: BoxDecoration(
                color: MedBuddyColors.slate100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: ['Female', 'Male'].map((gender) {
                  final isSelected = _voiceGender == gender.toLowerCase();
                  return GestureDetector(
                    onTap: () {
                      setState(() => _voiceGender = gender.toLowerCase());
                      widget.onVoiceGenderChanged?.call(gender.toLowerCase());
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 6),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? MedBuddyColors.primary
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(gender,
                          style: MedBuddyTextStyles.label.copyWith(
                            color: isSelected
                                ? MedBuddyColors.pureWhite
                                : MedBuddyColors.slate500,
                            fontWeight:
                                isSelected ? FontWeight.w600 : FontWeight.w400,
                          )),
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    ]);
  }

  Widget _buildEmergencySection() {
    return _buildCard([
      _sliderRow(
        icon: Icons.volume_up_outlined,
        label: 'Alarm volume',
        value: _alarmVolume,
        iconColor: MedBuddyColors.emergency,
        sliderColor: MedBuddyColors.emergency,
        onChanged: (v) {
          setState(() => _alarmVolume = v);
          widget.onAlarmVolumeChanged?.call(v);
        },
      ),
      _chevronRow(
        icon: Icons.warning_amber_outlined,
        label: 'Test SOS alert',
        labelColor: MedBuddyColors.warning,
        iconColor: MedBuddyColors.warning,
        onTap: widget.onTestSOS,
      ),
    ]);
  }

  Widget _buildPrivacySection() {
    return _buildCard([
      _chevronRow(
        icon: Icons.download_outlined,
        label: 'Export my data',
        onTap: widget.onExportData,
      ),
      _chevronRow(
        icon: Icons.delete_outline,
        label: 'Delete account',
        labelColor: MedBuddyColors.emergency,
        iconColor: MedBuddyColors.emergency,
        onTap: widget.onDeleteAccount,
      ),
    ]);
  }

  Widget _buildAboutSection() {
    return _buildCard([
      const Padding(
        padding: EdgeInsets.symmetric(
          horizontal: MedBuddyDimens.spacingLg,
          vertical: MedBuddyDimens.spacingMd,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('App version', style: MedBuddyTextStyles.body),
            Text('MedBuddy v2.0', style: MedBuddyTextStyles.secondary),
          ],
        ),
      ),
      _chevronRow(
        icon: Icons.support_agent_outlined,
        label: 'Support contact',
        onTap: () {
          // TODO: open support contact
        },
      ),
    ]);
  }
}
