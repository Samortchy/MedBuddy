import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_ringtone_player/flutter_ringtone_player.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_handler/permission_handler.dart';
import '/constants/colors.dart';
import '/services/api_service.dart';

/// Caregiver-side emergency call. Opened when an emergency push is tapped.
/// Fetches an Agora token for the patient's channel and joins the audio call.
class CaregiverEmergencyCallScreen extends ConsumerStatefulWidget {
  final String channelName;

  const CaregiverEmergencyCallScreen({super.key, required this.channelName});

  @override
  ConsumerState<CaregiverEmergencyCallScreen> createState() =>
      _CaregiverEmergencyCallScreenState();
}

class _CaregiverEmergencyCallScreenState
    extends ConsumerState<CaregiverEmergencyCallScreen> {
  RtcEngine? _engine;
  bool _joined = false;
  bool _connected = false;
  bool _isMuted = false;
  bool _speakerOn = true;
  bool _ringing = false;
  String? _error;

  final _ringtone = FlutterRingtonePlayer();

  // Non-zero uid so the caregiver doesn't collide with the patient (uid 0).
  final int _uid =
      (DateTime.now().millisecondsSinceEpoch % 100000) + 1;

  @override
  void initState() {
    super.initState();
    _startRinging();
    WidgetsBinding.instance.addPostFrameCallback((_) => _join());
  }

  void _startRinging() {
    if (_ringing) return;
    _ringing = true;
    try {
      _ringtone.play(
        android: AndroidSounds.ringtone,
        ios: IosSounds.alarm,
        looping: true,
        volume: 1.0,
        asAlarm: true,
      );
    } catch (_) {}
  }

  void _stopRinging() {
    if (!_ringing) return;
    _ringing = false;
    try {
      _ringtone.stop();
    } catch (_) {}
  }

  Future<void> _join() async {
    try {
      final status = await Permission.microphone.request();
      if (!status.isGranted) {
        _stopRinging();
        setState(() => _error = 'Microphone permission is required.');
        return;
      }

      final dio = ref.read(apiServiceProvider);
      final Response res = await dio.post('/agora/token', data: {
        'channel_name': widget.channelName,
        'uid': _uid,
      });
      final data = res.data as Map<String, dynamic>;
      final appId = data['app_id'] as String?;
      final token = data['token'] as String?;
      if (appId == null || token == null) {
        _stopRinging();
        setState(() => _error = 'Agora is not configured on the server.');
        return;
      }

      final engine = createAgoraRtcEngine();
      await engine.initialize(RtcEngineContext(appId: appId));
      _engine = engine;

      engine.registerEventHandler(
        RtcEngineEventHandler(
          onJoinChannelSuccess: (connection, elapsed) {
            _joined = true;
            debugPrint('Agora(caregiver): joined ${connection.channelId}');
          },
          onUserJoined: (connection, remoteUid, elapsed) {
            debugPrint('Agora(caregiver): patient $remoteUid joined');
            _stopRinging();
            if (mounted) setState(() => _connected = true);
          },
          onUserOffline: (connection, remoteUid, reason) {
            debugPrint('Agora(caregiver): patient $remoteUid offline ($reason)');
            if (mounted) setState(() => _connected = false);
          },
          onError: (err, msg) {
            debugPrint('Agora(caregiver) ERROR: $err — $msg');
          },
          onConnectionStateChanged: (connection, state, reason) {
            debugPrint('Agora(caregiver): state=$state reason=$reason');
          },
        ),
      );

      await engine.enableAudio();
      // Start hands-free so the caregiver can hear the patient immediately.
      await engine.setEnableSpeakerphone(true);
      await engine.setClientRole(role: ClientRoleType.clientRoleBroadcaster);
      await engine.joinChannel(
        token: token,
        channelId: widget.channelName,
        uid: _uid,
        options: const ChannelMediaOptions(
          channelProfile: ChannelProfileType.channelProfileCommunication,
          clientRoleType: ClientRoleType.clientRoleBroadcaster,
        ),
      );
    } on DioException catch (e) {
      _stopRinging();
      setState(() => _error =
          e.response?.data?['detail']?.toString() ?? 'Failed to connect.');
    } catch (e) {
      _stopRinging();
      setState(() => _error = 'Failed to connect: $e');
    }
  }

  Future<void> _toggleMute() async {
    setState(() => _isMuted = !_isMuted);
    await _engine?.muteLocalAudioStream(_isMuted);
  }

  Future<void> _toggleSpeaker() async {
    setState(() => _speakerOn = !_speakerOn);
    await _engine?.setEnableSpeakerphone(_speakerOn);
  }

  Future<void> _endCall() async {
    _stopRinging();
    try {
      if (_joined) await _engine?.leaveChannel();
      await _engine?.release();
    } catch (_) {}
    _engine = null;
    if (mounted) Navigator.of(context).maybePop();
  }

  @override
  void dispose() {
    _stopRinging();
    if (_engine != null) {
      _engine!.leaveChannel();
      _engine!.release();
      _engine = null;
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final statusText = _error != null
        ? _error!
        : _connected
            ? 'Connected — you can speak now'
            : 'Connecting to patient…';

    return Scaffold(
      backgroundColor: MedColors.emergency,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                children: [
                  const SizedBox(height: 24),
                  Text('EMERGENCY',
                      style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.8),
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 2)),
                  const SizedBox(height: 8),
                  const Text('Patient needs help',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 26,
                          fontWeight: FontWeight.bold)),
                ],
              ),
              Column(
                children: [
                  Icon(
                    _connected ? Icons.call : Icons.phone_in_talk,
                    color: Colors.white,
                    size: 72,
                  ),
                  const SizedBox(height: 20),
                  Text(statusText,
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.white, fontSize: 16)),
                ],
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _CallButton(
                    icon: _isMuted ? Icons.mic_off : Icons.mic,
                    label: _isMuted ? 'Unmute' : 'Mute',
                    color: Colors.white,
                    onTap: _toggleMute,
                  ),
                  _CallButton(
                    icon: _speakerOn ? Icons.volume_up : Icons.volume_off,
                    label: _speakerOn ? 'Speaker' : 'Earpiece',
                    color: _speakerOn ? Colors.white : Colors.white24,
                    onTap: _toggleSpeaker,
                  ),
                  _CallButton(
                    icon: Icons.call_end,
                    label: 'End',
                    color: Colors.red.shade900,
                    onTap: _endCall,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CallButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _CallButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: MedColors.emergency, size: 28),
          ),
          const SizedBox(height: 8),
          Text(label, style: const TextStyle(color: Colors.white)),
        ],
      ),
    );
  }
}
