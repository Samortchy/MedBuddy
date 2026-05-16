import 'package:flutter/material.dart';
import '../../../constants/colors.dart';
import '../../../constants/dimens.dart';
import '../../../constants/text_styles.dart';
import '../../../services/service_interfaces.dart';
import '../../../widgets/shared/sos_button.dart';

/// S-17 — AI Buddy Chat
///
/// Backend hooks:
/// - [aiService]  → AIService (Qwen 2.5 / your LLM backend)
/// - [sttService] → STTService (Faster-Whisper)
/// - [ttsService] → TTSService (ElevenLabs / Coqui XTTS-v2)
///
/// Wire these in when ready. All UI is fully functional without them.
class AIBuddyChatScreen extends StatefulWidget {
  final AIService? aiService;
  final STTService? sttService;
  final TTSService? ttsService;

  const AIBuddyChatScreen({
    super.key,
    this.aiService,
    this.sttService,
    this.ttsService,
  });

  @override
  State<AIBuddyChatScreen> createState() => _AIBuddyChatScreenState();
}

class _AIBuddyChatScreenState extends State<AIBuddyChatScreen> {
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  bool _isListening = false;
  bool _isMuted = false;
  bool _isAITyping = false;

  // Replace with real data from your state management layer
  final List<ChatMessage> _messages = [
    ChatMessage(
      id: '1',
      content: 'Good morning! How are you feeling today?',
      isFromAI: true,
      timestamp: DateTime.now().subtract(const Duration(minutes: 10)),
    ),
    ChatMessage(
      id: '2',
      content: 'A bit tired today, to be honest.',
      isFromAI: false,
      timestamp: DateTime.now().subtract(const Duration(minutes: 8)),
    ),
    ChatMessage(
      id: '3',
      content:
          'I understand. Rest is so important for your recovery. Did you get enough sleep last night?',
      isFromAI: true,
      timestamp: DateTime.now().subtract(const Duration(minutes: 7)),
    ),
  ];

  final List<String> _quickReplies = ['Yes', 'No', 'Not sure', 'Tell me more'];

  @override
  void dispose() {
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  // ── Backend hook: send a text message ──────────────────────────
  Future<void> _sendTextMessage(String text) async {
    if (text.trim().isEmpty) return;
    _textController.clear();

    final userMsg = ChatMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      content: text,
      isFromAI: false,
      timestamp: DateTime.now(),
    );

    setState(() {
      _messages.add(userMsg);
      _isAITyping = true;
    });
    _scrollToBottom();

    // TODO: Replace with real AI call
    // final response = await widget.aiService?.sendMessage(text, history: _messages);
    // For now simulates a delay
    await Future.delayed(const Duration(seconds: 2));

    final aiMsg = ChatMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      content: 'Thank you for sharing that with me.',
      isFromAI: true,
      timestamp: DateTime.now(),
    );

    if (mounted) {
      setState(() {
        _messages.add(aiMsg);
        _isAITyping = false;
      });
      _scrollToBottom();
      // TODO: widget.ttsService?.speak(aiMsg.content);
    }
  }

  // ── Backend hook: start STT recording ─────────────────────────
  Future<void> _toggleListening() async {
    if (_isListening) {
      setState(() => _isListening = false);
      // TODO: final text = await widget.sttService?.stopListening();
      // if (text != null) _sendTextMessage(text);
    } else {
      setState(() => _isListening = true);
      // TODO: widget.sttService?.startListening();
    }
  }

  // ── Backend hook: toggle TTS mute ─────────────────────────────
  Future<void> _toggleMute() async {
    setState(() => _isMuted = !_isMuted);
    // TODO: widget.ttsService?.setMuted(_isMuted);
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
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
              Expanded(child: _buildChatArea()),
              _buildQuickReplies(),
              _buildInputBar(),
            ],
          ),
          const SOSButton(),
        ],
      ),
    );
  }

  // ── App Bar ────────────────────────────────────────────────────
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
          bottom: BorderSide(color: MedBuddyColors.slate300, width: 0.5),
        ),
      ),
      child: Row(
        children: [
          // AI Avatar
          Container(
            width: 36,
            height: 36,
            decoration: const BoxDecoration(
              color: MedBuddyColors.primary,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.smart_toy_outlined,
                color: MedBuddyColors.pureWhite, size: 18),
          ),
          const SizedBox(width: MedBuddyDimens.spacingSm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('MedBuddy',
                    style: MedBuddyTextStyles.heading3
                        .copyWith(color: MedBuddyColors.primaryDark)),
                Row(
                  children: [
                    Container(
                      width: 7,
                      height: 7,
                      decoration: const BoxDecoration(
                        color: MedBuddyColors.success,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text('AI ONLINE',
                        style: MedBuddyTextStyles.caption
                            .copyWith(color: MedBuddyColors.slate500)),
                  ],
                ),
              ],
            ),
          ),
          // Mute toggle
          IconButton(
            onPressed: _toggleMute,
            icon: Icon(
              _isMuted ? Icons.volume_off_outlined : Icons.volume_up_outlined,
              color: MedBuddyColors.slate500,
            ),
          ),
        ],
      ),
    );
  }

  // ── Chat Area ──────────────────────────────────────────────────
  Widget _buildChatArea() {
    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.all(MedBuddyDimens.spacingMd),
      itemCount: _messages.length + (_isAITyping ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == _messages.length) return _buildTypingIndicator();
        return _buildMessageBubble(_messages[index]);
      },
    );
  }

  Widget _buildMessageBubble(ChatMessage message) {
    final isAI = message.isFromAI;
    return Padding(
      padding: const EdgeInsets.only(bottom: MedBuddyDimens.spacingMd),
      child: Row(
        mainAxisAlignment:
            isAI ? MainAxisAlignment.start : MainAxisAlignment.end,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (isAI) ...[
            Container(
              width: MedBuddyDimens.avatarSizeSmall,
              height: MedBuddyDimens.avatarSizeSmall,
              decoration: const BoxDecoration(
                color: MedBuddyColors.primary,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.smart_toy_outlined,
                  color: MedBuddyColors.pureWhite, size: 14),
            ),
            const SizedBox(width: MedBuddyDimens.spacingSm),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: MedBuddyDimens.spacingMd,
                vertical: MedBuddyDimens.spacingSm + 2,
              ),
              decoration: BoxDecoration(
                color: isAI ? MedBuddyColors.primary : MedBuddyColors.pureWhite,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(18),
                  topRight: const Radius.circular(18),
                  bottomLeft: Radius.circular(isAI ? 4 : 18),
                  bottomRight: Radius.circular(isAI ? 18 : 4),
                ),
                border: isAI
                    ? null
                    : Border.all(color: MedBuddyColors.slate300, width: 0.5),
                boxShadow: isAI
                    ? null
                    : [
                        BoxShadow(
                          color: MedBuddyColors.slate300.withValues(alpha: 0.3),
                          blurRadius: 4,
                          offset: const Offset(0, 1),
                        ),
                      ],
              ),
              child: Text(
                message.content,
                style: MedBuddyTextStyles.body.copyWith(
                  color:
                      isAI ? MedBuddyColors.pureWhite : MedBuddyColors.slate700,
                ),
              ),
            ),
          ),
          if (!isAI) const SizedBox(width: MedBuddyDimens.spacingSm),
        ],
      ),
    );
  }

  Widget _buildTypingIndicator() {
    return Row(
      children: [
        Container(
          width: MedBuddyDimens.avatarSizeSmall,
          height: MedBuddyDimens.avatarSizeSmall,
          decoration: const BoxDecoration(
            color: MedBuddyColors.primary,
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.smart_toy_outlined,
              color: MedBuddyColors.pureWhite, size: 14),
        ),
        const SizedBox(width: MedBuddyDimens.spacingSm),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: MedBuddyColors.primary,
            borderRadius: BorderRadius.circular(18),
          ),
          child: const _TypingDots(),
        ),
      ],
    );
  }

  // ── Quick Reply Chips ──────────────────────────────────────────
  Widget _buildQuickReplies() {
    return Container(
      color: MedBuddyColors.warmWhite,
      padding: const EdgeInsets.symmetric(
        horizontal: MedBuddyDimens.spacingMd,
        vertical: MedBuddyDimens.spacingSm,
      ),
      child: Wrap(
        spacing: MedBuddyDimens.spacingSm,
        runSpacing: MedBuddyDimens.spacingSm,
        children: _quickReplies
            .map((reply) => _QuickReplyChip(
                  label: reply,
                  onTap: () => _sendTextMessage(reply),
                ))
            .toList(),
      ),
    );
  }

  // ── Input Bar ──────────────────────────────────────────────────
  Widget _buildInputBar() {
    return Container(
      padding: EdgeInsets.only(
        left: MedBuddyDimens.spacingMd,
        right: MedBuddyDimens.spacingMd,
        top: MedBuddyDimens.spacingSm,
        bottom:
            MedBuddyDimens.spacingSm + MediaQuery.of(context).padding.bottom,
      ),
      decoration: const BoxDecoration(
        color: MedBuddyColors.pureWhite,
        border: Border(
          top: BorderSide(color: MedBuddyColors.slate300, width: 0.5),
        ),
      ),
      child: Row(
        children: [
          // SOS compact in bar
          _SOSCompact(),
          const SizedBox(width: MedBuddyDimens.spacingSm),
          // Text field
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: MedBuddyDimens.spacingMd,
                vertical: MedBuddyDimens.spacingSm + 2,
              ),
              decoration: BoxDecoration(
                color: MedBuddyColors.slate100,
                borderRadius: BorderRadius.circular(MedBuddyDimens.radiusPill),
              ),
              child: TextField(
                controller: _textController,
                style: MedBuddyTextStyles.body,
                decoration: InputDecoration(
                  hintText: 'Type a message...',
                  hintStyle: MedBuddyTextStyles.body
                      .copyWith(color: MedBuddyColors.slate500),
                  border: InputBorder.none,
                  isDense: true,
                  contentPadding: EdgeInsets.zero,
                ),
                onSubmitted: _sendTextMessage,
              ),
            ),
          ),
          const SizedBox(width: MedBuddyDimens.spacingSm),
          // Mic button
          GestureDetector(
            onTap: _toggleListening,
            child: Container(
              width: MedBuddyDimens.micButtonSize,
              height: MedBuddyDimens.micButtonSize,
              decoration: BoxDecoration(
                color: _isListening
                    ? MedBuddyColors.primaryDark
                    : MedBuddyColors.primary,
                shape: BoxShape.circle,
              ),
              child: Icon(
                _isListening ? Icons.mic : Icons.mic_none,
                color: MedBuddyColors.pureWhite,
                size: 24,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Subwidgets ─────────────────────────────────────────────────────

class _TypingDots extends StatefulWidget {
  const _TypingDots();
  @override
  State<_TypingDots> createState() => _TypingDotsState();
}

class _TypingDotsState extends State<_TypingDots>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (_, __) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(3, (i) {
            final delay = i * 0.2;
            final progress =
                ((_controller.value - delay) % 1.0).clamp(0.0, 1.0);
            final opacity = (progress < 0.5 ? progress * 2 : (1 - progress) * 2)
                .clamp(0.3, 1.0);
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 2),
              child: Opacity(
                opacity: opacity,
                child: Container(
                  width: 6,
                  height: 6,
                  decoration: const BoxDecoration(
                    color: MedBuddyColors.pureWhite,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            );
          }),
        );
      },
    );
  }
}

class _QuickReplyChip extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _QuickReplyChip({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          border: Border.all(color: MedBuddyColors.primary, width: 1.5),
          borderRadius: BorderRadius.circular(MedBuddyDimens.radiusPill),
        ),
        child: Text(label,
            style: MedBuddyTextStyles.label
                .copyWith(color: MedBuddyColors.primary)),
      ),
    );
  }
}

class _SOSCompact extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.of(context).pushNamed('/sos-confirmation'),
      child: Container(
        width: MedBuddyDimens.buttonHeightSecondary,
        height: MedBuddyDimens.buttonHeightSecondary,
        decoration: const BoxDecoration(
          color: MedBuddyColors.emergency,
          shape: BoxShape.circle,
        ),
        child: const Center(
          child: Text('SOS',
              style: TextStyle(
                color: MedBuddyColors.pureWhite,
                fontSize: 10,
                fontWeight: FontWeight.w700,
              )),
        ),
      ),
    );
  }
}
