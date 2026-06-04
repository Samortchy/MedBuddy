import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:audio_waveforms/audio_waveforms.dart';
import 'package:just_audio/just_audio.dart';
import 'package:path_provider/path_provider.dart';
import '../../constants/colors.dart';
import '../../providers/auth_provider.dart';
import '../../providers/chat_provider.dart';
import '../../services/api_service.dart';
import '../../widgets/shared/sos_button.dart';

/// A caregiver↔patient message thread. Works for both roles — "my" messages
/// (sender == current user) align right, the other person's align left.
class ConversationScreen extends ConsumerStatefulWidget {
  final String linkId;
  final String title;

  const ConversationScreen({
    super.key,
    required this.linkId,
    required this.title,
  });

  @override
  ConsumerState<ConversationScreen> createState() => _ConversationScreenState();
}

class _ConversationScreenState extends ConsumerState<ConversationScreen> {
  final _ctrl = TextEditingController();
  final _scroll = ScrollController();
  Timer? _poll;
  bool _sending = false;

  // Voice notes
  final _recorder = RecorderController();
  final _player = AudioPlayer();
  bool _recording = false;
  bool _uploadingVoice = false;
  String? _playingId; // id of the message currently playing

  @override
  void initState() {
    super.initState();
    // Light polling so new messages from the other side show up (~no realtime).
    _poll = Timer.periodic(const Duration(seconds: 4), (_) {
      ref.invalidate(conversationProvider(widget.linkId));
    });
    // Reset the play icon when a voice note finishes.
    _player.playerStateStream.listen((s) {
      if (s.processingState == ProcessingState.completed && mounted) {
        setState(() => _playingId = null);
        _player.seek(Duration.zero);
        _player.stop();
      }
    });
  }

  @override
  void dispose() {
    _poll?.cancel();
    _ctrl.dispose();
    _scroll.dispose();
    _recorder.dispose();
    _player.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final text = _ctrl.text.trim();
    if (text.isEmpty || _sending) return;
    setState(() => _sending = true);
    _ctrl.clear();
    try {
      final dio = ref.read(apiServiceProvider);
      await dio.post('/caregiver/links/${widget.linkId}/messages',
          data: {'content': text});
      ref.invalidate(conversationProvider(widget.linkId));
    } on DioException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(e.response?.data?['detail']?.toString() ??
                  'Failed to send')),
        );
      }
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  Future<void> _startRecording() async {
    if (_recording || _uploadingVoice) return;
    try {
      if (!await _recorder.checkPermission()) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
              content: Text('Microphone permission is required.')));
        }
        return;
      }
      final dir = await getTemporaryDirectory();
      final path =
          '${dir.path}/vn_${DateTime.now().millisecondsSinceEpoch}.m4a';
      // Defaults: AAC encoder in an mpeg4 (.m4a) container — playable by just_audio.
      await _recorder.record(path: path);
      if (mounted) setState(() => _recording = true);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Could not start recording: $e')));
      }
    }
  }

  /// Stop recording. If [cancel] is true, discard; otherwise upload & send.
  Future<void> _stopRecording({bool cancel = false}) async {
    if (!_recording) return;
    String? path;
    try {
      path = await _recorder.stop();
    } catch (_) {}
    if (mounted) setState(() => _recording = false);
    if (cancel || path == null) return;
    await _uploadVoice(path);
  }

  Future<void> _uploadVoice(String path) async {
    setState(() => _uploadingVoice = true);
    try {
      final dio = ref.read(apiServiceProvider);
      final form = FormData.fromMap({
        'audio': await MultipartFile.fromFile(path, filename: 'voice.m4a'),
      });
      await dio.post('/caregiver/links/${widget.linkId}/voice', data: form);
      ref.invalidate(conversationProvider(widget.linkId));
    } on DioException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(e.response?.data?['detail']?.toString() ??
                'Failed to send voice note')));
      }
    } finally {
      if (mounted) setState(() => _uploadingVoice = false);
    }
  }

  Future<void> _togglePlay(LinkMessage m) async {
    if (_playingId == m.id) {
      await _player.pause();
      if (mounted) setState(() => _playingId = null);
      return;
    }
    try {
      await _player.stop();
      await _player.setUrl(m.voiceUrl!);
      if (mounted) setState(() => _playingId = m.id);
      await _player.play();
    } catch (e) {
      if (mounted) {
        setState(() => _playingId = null);
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Could not play voice note')));
      }
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scroll.hasClients) {
        _scroll.jumpTo(_scroll.position.maxScrollExtent);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final myId = ref.watch(currentUserProvider)?.userId;
    final isPatient = ref.watch(currentUserProvider)?.role == 'patient';
    final async = ref.watch(conversationProvider(widget.linkId));

    return Scaffold(
      backgroundColor: MedBuddyColors.warmWhite,
      appBar: AppBar(
        backgroundColor: MedBuddyColors.primaryDark,
        foregroundColor: Colors.white,
        title: Text(widget.title,
            style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold)),
      ),
      body: Stack(
        children: [
          Column(
            children: [
              Expanded(
            child: async.when(
              loading: () => const Center(
                  child: CircularProgressIndicator(
                      color: MedBuddyColors.primary)),
              error: (e, _) => Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('Could not load messages',
                        style: TextStyle(color: MedBuddyColors.emergency)),
                    const SizedBox(height: 12),
                    ElevatedButton(
                      onPressed: () => ref
                          .invalidate(conversationProvider(widget.linkId)),
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
              data: (msgs) {
                if (msgs.isEmpty) {
                  return const Center(
                    child: Text('No messages yet. Say hello 👋',
                        style: TextStyle(color: MedBuddyColors.slate500)),
                  );
                }
                _scrollToBottom();
                return ListView.builder(
                  controller: _scroll,
                  padding: const EdgeInsets.all(12),
                  itemCount: msgs.length,
                  itemBuilder: (context, i) {
                    final m = msgs[i];
                    final mine = m.senderId == myId;
                    return m.isVoice
                        ? _voiceBubble(m, mine)
                        : _bubble(m, mine);
                  },
                );
              },
            ),
          ),
              _inputBar(),
            ],
          ),
          // Lift the SOS button above the chat input bar so it never covers
          // the mic / send button. padding.bottom is 0 while the keyboard is up.
          if (isPatient)
            SOSButton(bottom: MediaQuery.of(context).padding.bottom + 76),
        ],
      ),
    );
  }

  Widget _bubble(LinkMessage m, bool mine) {
    final h = m.sentAt.hour % 12 == 0 ? 12 : m.sentAt.hour % 12;
    final time =
        '$h:${m.sentAt.minute.toString().padLeft(2, '0')} ${m.sentAt.hour >= 12 ? 'PM' : 'AM'}';
    return Align(
      alignment: mine ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        constraints: const BoxConstraints(maxWidth: 260),
        decoration: BoxDecoration(
          color: mine ? MedBuddyColors.primary : MedBuddyColors.pureWhite,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: Radius.circular(mine ? 16 : 4),
            bottomRight: Radius.circular(mine ? 4 : 16),
          ),
          border: mine
              ? null
              : Border.all(color: MedBuddyColors.slate300, width: 0.5),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(m.content,
                style: TextStyle(
                    color:
                        mine ? Colors.white : MedBuddyColors.slate900,
                    fontSize: 15)),
            const SizedBox(height: 3),
            Text(time,
                style: TextStyle(
                    fontSize: 10,
                    color: mine
                        ? Colors.white.withValues(alpha: 0.8)
                        : MedBuddyColors.slate500)),
          ],
        ),
      ),
    );
  }

  Widget _voiceBubble(LinkMessage m, bool mine) {
    final h = m.sentAt.hour % 12 == 0 ? 12 : m.sentAt.hour % 12;
    final time =
        '$h:${m.sentAt.minute.toString().padLeft(2, '0')} ${m.sentAt.hour >= 12 ? 'PM' : 'AM'}';
    final playing = _playingId == m.id;
    final fg = mine ? Colors.white : MedBuddyColors.primaryDark;
    return Align(
      alignment: mine ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        constraints: const BoxConstraints(maxWidth: 240),
        decoration: BoxDecoration(
          color: mine ? MedBuddyColors.primary : MedBuddyColors.pureWhite,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: Radius.circular(mine ? 16 : 4),
            bottomRight: Radius.circular(mine ? 4 : 16),
          ),
          border: mine
              ? null
              : Border.all(color: MedBuddyColors.slate300, width: 0.5),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                GestureDetector(
                  onTap: () => _togglePlay(m),
                  child: Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: mine
                          ? Colors.white.withValues(alpha: 0.25)
                          : MedBuddyColors.primary.withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(playing ? Icons.pause : Icons.play_arrow,
                        color: fg, size: 22),
                  ),
                ),
                const SizedBox(width: 10),
                Icon(Icons.graphic_eq, color: fg, size: 20),
                const SizedBox(width: 6),
                Text('Voice message',
                    style: TextStyle(
                        color: fg,
                        fontSize: 14,
                        fontWeight: FontWeight.w500)),
              ],
            ),
            const SizedBox(height: 3),
            Text(time,
                style: TextStyle(
                    fontSize: 10,
                    color: mine
                        ? Colors.white.withValues(alpha: 0.8)
                        : MedBuddyColors.slate500)),
          ],
        ),
      ),
    );
  }

  Widget _inputBar() {
    return SafeArea(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: const BoxDecoration(
          color: MedBuddyColors.pureWhite,
          border: Border(
              top: BorderSide(color: MedBuddyColors.slate300, width: 0.5)),
        ),
        child: _recording ? _recordingBar() : _normalBar(),
      ),
    );
  }

  Widget _normalBar() {
    return Row(
      children: [
        Expanded(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
            decoration: BoxDecoration(
              color: MedBuddyColors.slate100,
              borderRadius: BorderRadius.circular(24),
            ),
            child: TextField(
              controller: _ctrl,
              minLines: 1,
              maxLines: 4,
              textInputAction: TextInputAction.send,
              onSubmitted: (_) => _send(),
              decoration: const InputDecoration(
                hintText: 'Type a message…',
                border: InputBorder.none,
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        // Mic when the field is empty, Send when there's text.
        ValueListenableBuilder<TextEditingValue>(
          valueListenable: _ctrl,
          builder: (context, value, _) {
            final hasText = value.text.trim().isNotEmpty;
            return GestureDetector(
              onTap: _uploadingVoice
                  ? null
                  : (hasText ? _send : _startRecording),
              child: Container(
                width: 44,
                height: 44,
                decoration: const BoxDecoration(
                  color: MedBuddyColors.primary,
                  shape: BoxShape.circle,
                ),
                child: (_sending || _uploadingVoice)
                    ? const Padding(
                        padding: EdgeInsets.all(12),
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white),
                      )
                    : Icon(hasText ? Icons.send : Icons.mic,
                        color: Colors.white, size: 20),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _recordingBar() {
    return Row(
      children: [
        IconButton(
          onPressed: () => _stopRecording(cancel: true),
          icon: const Icon(Icons.delete_outline,
              color: MedBuddyColors.emergency),
          tooltip: 'Cancel',
        ),
        const _RecordingDot(),
        const SizedBox(width: 8),
        const Expanded(
          child: Text('Recording…  tap send when done',
              style: TextStyle(color: MedBuddyColors.slate500)),
        ),
        GestureDetector(
          onTap: () => _stopRecording(),
          child: Container(
            width: 44,
            height: 44,
            decoration: const BoxDecoration(
              color: MedBuddyColors.primary,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.send, color: Colors.white, size: 20),
          ),
        ),
      ],
    );
  }
}

/// A small pulsing red dot shown while recording a voice note.
class _RecordingDot extends StatefulWidget {
  const _RecordingDot();

  @override
  State<_RecordingDot> createState() => _RecordingDotState();
}

class _RecordingDotState extends State<_RecordingDot>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 700),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: Tween<double>(begin: 0.3, end: 1.0).animate(_c),
      child: Container(
        width: 12,
        height: 12,
        decoration: const BoxDecoration(
          color: MedBuddyColors.emergency,
          shape: BoxShape.circle,
        ),
      ),
    );
  }
}
