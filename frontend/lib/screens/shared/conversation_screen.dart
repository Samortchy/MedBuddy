import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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

  @override
  void initState() {
    super.initState();
    // Light polling so new messages from the other side show up (~no realtime).
    _poll = Timer.periodic(const Duration(seconds: 4), (_) {
      ref.invalidate(conversationProvider(widget.linkId));
    });
  }

  @override
  void dispose() {
    _poll?.cancel();
    _ctrl.dispose();
    _scroll.dispose();
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
                    return _bubble(m, mine);
                  },
                );
              },
            ),
          ),
              _inputBar(),
            ],
          ),
          if (isPatient) const SOSButton(),
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

  Widget _inputBar() {
    return SafeArea(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: const BoxDecoration(
          color: MedBuddyColors.pureWhite,
          border: Border(
              top: BorderSide(color: MedBuddyColors.slate300, width: 0.5)),
        ),
        child: Row(
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
            GestureDetector(
              onTap: _send,
              child: Container(
                width: 44,
                height: 44,
                decoration: const BoxDecoration(
                  color: MedBuddyColors.primary,
                  shape: BoxShape.circle,
                ),
                child: _sending
                    ? const Padding(
                        padding: EdgeInsets.all(12),
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white),
                      )
                    : const Icon(Icons.send, color: Colors.white, size: 20),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
