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
    // The verification screen fires triggerEmergency() WITHOUT awaiting it, so
    // when we arrive here the session may not be populated yet. Wait briefly for
    // an in-flight trigger; if the screen was opened directly (no emergency at
    // all), start one now so we always have a live Agora channel.
    var session = ref.read(fallProvider);
    for (var i = 0;
        i < 10 &&
            !session.hasAgora &&
            session.error == null &&
            session.eventId == null;
        i++) {
      await Future.delayed(const Duration(milliseconds: 400));
      session = ref.read(fallProvider);
    }
    if (!session.hasAgora && session.eventId == null) {
      await ref
          .read(fallProvider.notifier)
          .triggerEmergency(eventType: 'manual_sos');
      session = ref.read(fallProvider);
    }

    // No Agora channel/token (Agora not configured, or trigger failed) → fallback.
    if (!session.hasAgora) {
      debugPrint('Agora unavailable, falling back. error=${session.error}');
      _triggerFallback();
      return;
    }

    try {
      final status = await Permission.microphone.request();
      if (!status.isGranted) {
        debugPrint('Microphone permission denied → fallback');
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
            debugPrint('Agora: joined channel ${connection.channelId}');
            // Make sure the mic is actually capturing and not muted, and route
            // audio to the loudspeaker. All best-effort — never abort the call.
            engine.enableLocalAudio(true).catchError((_) {});
            engine.muteLocalAudioStream(false).catchError((_) {});
            engine.setEnableSpeakerphone(true).catchError((_) {});
          },
          onUserJoined: (connection, remoteUid, elapsed) {
            // Caregiver (or anyone) joined the channel → call is live.
            debugPrint('Agora: remote user $remoteUid joined');
            if (!mounted) return;
            setState(() => _connectionState = AgoraConnectionState.connected);
            _agoraTimer?.cancel();
          },
          onUserOffline: (connection, remoteUid, reason) {
            // Only escalate if we were actually connected to a caregiver who
            // then dropped — not on spurious early offline events.
            debugPrint('Agora: remote user $remoteUid offline ($reason)');
            if (!mounted) return;
            if (_connectionState == AgoraConnectionState.connected) {
              _triggerFallback();
            }
          },
          onError: (err, msg) {
            debugPrint('Agora ERROR: $err — $msg');
          },
          onConnectionStateChanged: (connection, state, reason) {
            debugPrint('Agora: connection state=$state reason=$reason');
          },
          onTokenPrivilegeWillExpire: (connection, token) {
            debugPrint('Agora: token about to expire');
          },
        ),
      );

      await engine.enableAudio();
      // setDefaultAudioRouteToSpeakerphone is the safe pre-join way to default
      // to the loudspeaker (setEnableSpeakerphone returns -3 before join).
      try {
        await engine.setDefaultAudioRouteToSpeakerphone(true);
      } catch (_) {}
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
        child: LayoutBuilder(
          builder: (context, constraints) => SingleChildScrollView(
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight),
              child: IntrinsicHeight(
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
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
            ),
          ),
        ),
      ),
    );
  }
}
