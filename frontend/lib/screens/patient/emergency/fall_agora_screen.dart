import 'dart:async';
import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../../constants/colors.dart';
import '../../../constants/text_styles.dart';
import '../../../providers/fall_provider.dart';
import '../../../widgets/shared/alarm_indicator.dart';
import 'fall_agora/widgets/connection_status_card.dart';
import 'fall_agora/widgets/caregiver_avatar.dart';
import 'fall_agora/widgets/fallback_status_card.dart';
import 'fall_agora/widgets/sos_countdown_card.dart';

const _caregiverName = 'Your caregiver';

class FallAgoraScreen extends ConsumerStatefulWidget {
  const FallAgoraScreen({super.key});

  @override
  ConsumerState<FallAgoraScreen> createState() => _FallAgoraScreenState();
}

class _FallAgoraScreenState extends ConsumerState<FallAgoraScreen> {
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

  RtcEngine? _engine;
  bool _joined = false;

  @override
  void initState() {
    super.initState();
    _startAgoraTimeout();
    _startSosCountdown();
    WidgetsBinding.instance.addPostFrameCallback((_) => _initAgora());
  }

  Future<void> _initAgora() async {
    final session = ref.read(fallProvider);

    // No Agora channel/token (e.g. Agora not configured) → go to fallback.
    if (!session.hasAgora) {
      _triggerFallback();
      return;
    }

    try {
      final status = await Permission.microphone.request();
      if (!status.isGranted) {
        _triggerFallback();
        return;
      }

      final engine = createAgoraRtcEngine();
      await engine.initialize(RtcEngineContext(appId: session.agoraAppId!));
      _engine = engine;

      engine.registerEventHandler(
        RtcEngineEventHandler(
          onJoinChannelSuccess: (connection, elapsed) {
            _joined = true;
          },
          onUserJoined: (connection, remoteUid, elapsed) {
            // Caregiver (or anyone) joined the channel → call is live.
            if (!mounted) return;
            setState(() => _connectionState = AgoraConnectionState.connected);
            _agoraTimer?.cancel();
          },
          onUserOffline: (connection, remoteUid, reason) {
            // Caregiver dropped — fall back to SMS/call escalation.
            if (!mounted) return;
            _triggerFallback();
          },
        ),
      );

      await engine.enableAudio();
      // Hands-free by default — the patient may be on the floor, away from the
      // phone, so route audio through the loudspeaker.
      await engine.setEnableSpeakerphone(true);
      await engine.setClientRole(role: ClientRoleType.clientRoleBroadcaster);
      await engine.joinChannel(
        token: session.agoraToken!,
        channelId: session.agoraChannel!,
        uid: 0,
        options: const ChannelMediaOptions(
          channelProfile: ChannelProfileType.channelProfileCommunication,
          clientRoleType: ClientRoleType.clientRoleBroadcaster,
        ),
      );
    } catch (e) {
      debugPrint('Agora init/join failed: $e');
      _triggerFallback();
    }
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
        // No caregiver answered in time → escalate to fallback.
        if (_connectionState != AgoraConnectionState.connected) {
          _triggerFallback();
        }
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

  Future<void> _toggleMute() async {
    setState(() => _isMuted = !_isMuted);
    await _engine?.muteLocalAudioStream(_isMuted);
  }

  void _cancelSOS() {
    _sosTimer?.cancel();
    Navigator.of(context).pushReplacementNamed('/fall-resolved');
  }

  Future<void> _leaveAgora() async {
    try {
      if (_joined) await _engine?.leaveChannel();
      await _engine?.release();
    } catch (_) {}
    _engine = null;
  }

  @override
  void dispose() {
    _agoraTimer?.cancel();
    _sosTimer?.cancel();
    _leaveAgora();
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

              // Alarm indicator (mic mute toggle)
              AlarmIndicator(
                isMuted: _isMuted,
                onToggleMute: _toggleMute,
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
