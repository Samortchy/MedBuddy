import 'dart:async';
import 'package:flutter/material.dart';
import '../../../constants/colors.dart';
import '../../../constants/text_styles.dart';
import '../../../widgets/shared/alarm_indicator.dart';
import 'fall_agora/widgets/connection_status_card.dart';
import 'fall_agora/widgets/caregiver_avatar.dart';
import 'fall_agora/widgets/fallback_status_card.dart';
import 'fall_agora/widgets/sos_countdown_card.dart';

// TODO: Replace with your Agora App ID when ready
const _caregiverName = 'Sarah Johnson'; // Replace with dynamic caregiver name

class FallAgoraScreen extends StatefulWidget {
  const FallAgoraScreen({super.key});

  @override
  State<FallAgoraScreen> createState() => _FallAgoraScreenState();
}

class _FallAgoraScreenState extends State<FallAgoraScreen> {
  AgoraConnectionState _connectionState = AgoraConnectionState.connecting;
  bool _isMuted = false;
  bool _smsSent = false;
  bool _callInitiated = false;
  bool _sosActivated = false;
  bool _showFallback = false;
  int _sosSecondsLeft = 30;
  int _agoraSecondsLeft = 30;

  Timer? _agoraTimer;
  Timer? _sosTimer;

  @override
  void initState() {
    super.initState();
    _startAgoraTimeout();
    _startSosCountdown();
  }

  void _startAgoraTimeout() {
    _agoraTimer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) {
        t.cancel();
        return;
      }
      setState(() => _agoraSecondsLeft = (_agoraSecondsLeft - 1).clamp(0, 30));
      if (_agoraSecondsLeft == 0) {
        t.cancel();
        _triggerFallback();
      }
    });
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted && _connectionState == AgoraConnectionState.connecting) {
        setState(() => _connectionState = AgoraConnectionState.connected);
        _agoraTimer?.cancel();
      }
    });
  }

  void _startSosCountdown() {
    _sosTimer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) {
        t.cancel();
        return;
      }
      setState(() => _sosSecondsLeft = (_sosSecondsLeft - 1).clamp(0, 30));
      if (_sosSecondsLeft == 0) {
        t.cancel();
        if (!_sosActivated) _activateSOS();
      }
    });
  }

  void _triggerFallback() {
    if (!mounted) return;
    setState(() {
      _showFallback = true;
      _connectionState = AgoraConnectionState.fallback;
      _smsSent = true;
    });
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) setState(() => _callInitiated = true);
    });
  }

  void _activateSOS() {
    if (!mounted) return;
    setState(() => _sosActivated = true);
  }

  void _cancelSOS() {
    _sosTimer?.cancel();
    Navigator.of(context).pushReplacementNamed('/fall-resolved');
  }

  @override
  void dispose() {
    _agoraTimer?.cancel();
    _sosTimer?.cancel();
    super.dispose();
  }

  bool get _isConnected => _connectionState == AgoraConnectionState.connected;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: MedBuddyColors.emergency,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: Column(
            children: [
              // Header
              Text(
                'EMERGENCY',
                style: MedBuddyTextStyles.sectionHeader.copyWith(
                  color: MedBuddyColors.pureWhite.withValues(alpha: 0.7),
                  letterSpacing: 2,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'Fall Detected',
                style: MedBuddyTextStyles.emergencyScreen,
              ),
              const SizedBox(height: 24),

              // Caregiver avatar
              CaregiverAvatar(name: _caregiverName, isConnected: _isConnected),
              const SizedBox(height: 24),

              // Connection status
              ConnectionStatusCard(
                  state: _connectionState, caregiverName: _caregiverName),
              const SizedBox(height: 16),

              // Alarm indicator
              AlarmIndicator(
                isMuted: _isMuted,
                onToggleMute: () => setState(() => _isMuted = !_isMuted),
              ),
              const SizedBox(height: 16),

              // Fallback status
              if (_showFallback) ...[
                FallbackStatusCard(
                    smsSent: _smsSent, callInitiated: _callInitiated),
                const SizedBox(height: 16),
              ],

              // SOS countdown
              const Spacer(),
              SosCountdownCard(
                secondsLeft: _sosSecondsLeft,
                activated: _sosActivated,
                onCancel: _cancelSOS,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
