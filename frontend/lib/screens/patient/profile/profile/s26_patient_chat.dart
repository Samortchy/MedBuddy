import 'package:flutter/material.dart';
import '../../../constants/colors.dart';
import '../../../constants/dimens.dart';
import '../../../constants/text_styles.dart';
import '../../../services/service_interfaces.dart';
import '../../../widgets/shared/sos_button.dart';
import '../../../widgets/shared/bottom_nav_bar.dart';

/// S-26 — Patient Chat (with Caregiver)
///
/// Backend hooks:
/// - [messages]         → List<ChatMessage> from your messaging layer
/// - [caregiverName]    → String caregiver's display name
/// - [caregiverInitials]→ String 2-letter initials
/// - [caregiverRelationship] → String e.g. 'Daughter'
/// - [isOnline]         → bool caregiver online status
/// - [onSendText]       → Send a text message
/// - [onStartVoiceRecord] / [onStopVoiceRecord] → Agora voice message
/// - [onCallCaregiver]  → Open Agora real-time audio call
/// - [unreadCount]      → int badge count on chat nav tab
class PatientChatScreen extends StatefulWidget {
  final String caregiverName;
  final String caregiverInitials;
  final String caregiverRelationship;
  final bool isOnline;
  final List<ChatMessage> messages;
  final Future<void> Function(String text)? onSendText;
  final Future<void> Function()? onStartVoiceRecord;
  final Future<void> Function()? onStopVoiceRecord;
  final VoidCallback? onCallCaregiver;
  final int unreadCount;

  const PatientChatScreen({
    super.key,
    this.caregiverName = 'Sarah Mitchell',
    this.caregiverInitials = 'SM',
    this.caregiverRelationship = 'Daughter',
    this.isOnline = true,
    this.messages = const [],
    this.onSendText,
    this.onStartVoiceRecord,
    this.onStopVoiceRecord,
    this.onCallCaregiver,
    this.unreadCount = 0,
  });

  @override
  State<PatientChatScreen> createState() => _PatientChatScreenState();
}

class _PatientChatScreenState extends State<PatientChatScreen> {
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _isRecording = false;

  // Placeholder messages — replace with widget.messages
  final List<Map<String, dynamic>> _placeholderMessages = [
    {
      'from': 'caregiver',
      'type': 'text',
      'content': 'Good morning Dad! Did you take your morning medications? 💊',
      'time': '9:02 AM'
    },
    {
      'from': 'patient',
      'type': 'text',
      'content': 'Yes I took them all! Metformin and the others too.',
      'time': '9:08 AM',
      'read': true
    },
    {
      'from': 'caregiver',
      'type': 'healthReport',
      'content': '',
      'time': '9:15 AM',
      'sharedBy': 'Sarah',
      'report': {
        'title': 'Morning Check-in Summary',
        'mood': 4,
        'pain': 2,
        'sleep': '6 hrs',
        'meds': true
      }
    },
    {
      'from': 'patient',
      'type': 'voice',
      'content': '0:24',
      'time': '9:20 AM',
      'read': true
    },
  ];

  @override
  void dispose() {
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _sendText() async {
    final text = _textController.text.trim();
    if (text.isEmpty) return;
    _textController.clear();
    // TODO: await widget.onSendText?.call(text);
  }

  Future<void> _toggleVoiceRecord() async {
    if (_isRecording) {
      setState(() => _isRecording = false);
      // TODO: await widget.onStopVoiceRecord?.call();
    } else {
      setState(() => _isRecording = true);
      // TODO: await widget.onStartVoiceRecord?.call();
    }
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
              _buildInputBar(),
              PatientBottomNavBar(
                activeTab: PatientNavTab.chat,
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
        left: MedBuddyDimens.spacingSm,
        right: MedBuddyDimens.spacingMd,
        bottom: MedBuddyDimens.spacingMd,
      ),
      decoration: const BoxDecoration(
        color: MedBuddyColors.pureWhite,
        border: Border(
            bottom: BorderSide(color: MedBuddyColors.slate300, width: 0.5)),
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(Icons.arrow_back_ios,
                color: MedBuddyColors.primary, size: 20),
          ),
          Stack(
            children: [
              Container(
                width: MedBuddyDimens.avatarSizeMedium,
                height: MedBuddyDimens.avatarSizeMedium,
                decoration: const BoxDecoration(
                  color: MedBuddyColors.primary,
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(widget.caregiverInitials,
                      style: MedBuddyTextStyles.bodyBold
                          .copyWith(color: MedBuddyColors.pureWhite)),
                ),
              ),
              if (widget.isOnline)
                Positioned(
                  bottom: 1,
                  right: 1,
                  child: Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: MedBuddyColors.success,
                      shape: BoxShape.circle,
                      border:
                          Border.all(color: MedBuddyColors.pureWhite, width: 2),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(width: MedBuddyDimens.spacingMd),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(widget.caregiverName, style: MedBuddyTextStyles.bodyBold),
                Text(
                    '${widget.caregiverRelationship} · ${widget.isOnline ? "Online" : "Offline"}',
                    style: MedBuddyTextStyles.caption),
              ],
            ),
          ),
          IconButton(
            onPressed: widget.onCallCaregiver,
            icon: Container(
              width: 36,
              height: 36,
              decoration: const BoxDecoration(
                color: MedBuddyColors.primarySoft,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.phone_outlined,
                  color: MedBuddyColors.primary, size: 18),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChatArea() {
    final msgs = widget.messages.isEmpty
        ? _placeholderMessages
        : _toMapList(widget.messages);
    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.all(MedBuddyDimens.spacingMd),
      itemCount: msgs.length + 1, // +1 for date chip
      itemBuilder: (context, index) {
        if (index == 0) return _dateDivider('Today, Apr 5');
        final msg = msgs[index - 1];
        return _buildMessage(msg);
      },
    );
  }

  Widget _dateDivider(String label) {
    return Center(
      child: Container(
        margin: const EdgeInsets.only(bottom: MedBuddyDimens.spacingMd),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
        decoration: BoxDecoration(
          color: MedBuddyColors.slate100,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(label, style: MedBuddyTextStyles.caption),
      ),
    );
  }

  Widget _buildMessage(Map<String, dynamic> msg) {
    final isPatient = msg['from'] == 'patient';
    final type = msg['type'] as String;

    return Padding(
      padding: const EdgeInsets.only(bottom: MedBuddyDimens.spacingMd),
      child: Column(
        crossAxisAlignment:
            isPatient ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          if (type == 'text') _textBubble(msg, isPatient),
          if (type == 'voice') _voiceBubble(msg, isPatient),
          if (type == 'healthReport') _healthReportCard(msg),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment:
                isPatient ? MainAxisAlignment.end : MainAxisAlignment.start,
            children: [
              Text(msg['time'] as String, style: MedBuddyTextStyles.caption),
              if (isPatient && (msg['read'] ?? false)) ...[
                const SizedBox(width: 4),
                const Icon(Icons.done_all,
                    color: MedBuddyColors.primary, size: 14),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _textBubble(Map<String, dynamic> msg, bool isPatient) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 220),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
      decoration: BoxDecoration(
        color: isPatient ? MedBuddyColors.pureWhite : MedBuddyColors.slate100,
        borderRadius: BorderRadius.only(
          topLeft: const Radius.circular(18),
          topRight: const Radius.circular(18),
          bottomLeft: Radius.circular(isPatient ? 18 : 4),
          bottomRight: Radius.circular(isPatient ? 4 : 18),
        ),
        border: isPatient
            ? Border.all(color: MedBuddyColors.primaryLight, width: 1.5)
            : null,
      ),
      child: Text(msg['content'] as String,
          style:
              MedBuddyTextStyles.body.copyWith(color: MedBuddyColors.slate700)),
    );
  }

  Widget _voiceBubble(Map<String, dynamic> msg, bool isPatient) {
    return Container(
      width: 210,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
      decoration: BoxDecoration(
        color: isPatient ? MedBuddyColors.pureWhite : MedBuddyColors.slate100,
        borderRadius: BorderRadius.only(
          topLeft: const Radius.circular(18),
          topRight: const Radius.circular(18),
          bottomLeft: Radius.circular(isPatient ? 18 : 4),
          bottomRight: Radius.circular(isPatient ? 4 : 18),
        ),
        border: isPatient
            ? Border.all(color: MedBuddyColors.primaryLight, width: 1.5)
            : null,
      ),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: const BoxDecoration(
                color: MedBuddyColors.primary, shape: BoxShape.circle),
            child: const Icon(Icons.play_arrow,
                color: MedBuddyColors.pureWhite, size: 18),
          ),
          const SizedBox(width: MedBuddyDimens.spacingMd),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Waveform bars
                Row(
                  children: [
                    8.0,
                    14.0,
                    20.0,
                    12.0,
                    18.0,
                    10.0,
                    8.0,
                    14.0,
                    10.0,
                    6.0,
                    12.0
                  ]
                      .map((h) => Container(
                            width: 3,
                            height: h,
                            margin: const EdgeInsets.symmetric(horizontal: 1),
                            decoration: BoxDecoration(
                              color: MedBuddyColors.primary,
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ))
                      .toList(),
                ),
                const SizedBox(height: 4),
                Text(msg['content'] as String,
                    style: MedBuddyTextStyles.caption),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _healthReportCard(Map<String, dynamic> msg) {
    final report = msg['report'] as Map<String, dynamic>;
    return Container(
      width: 230,
      padding: const EdgeInsets.all(MedBuddyDimens.spacingMd),
      decoration: BoxDecoration(
        color: MedBuddyColors.primarySoft,
        borderRadius: BorderRadius.circular(MedBuddyDimens.radiusLg),
        border: Border.all(color: MedBuddyColors.primaryLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.show_chart,
                  color: MedBuddyColors.primary, size: 16),
              const SizedBox(width: 6),
              Expanded(
                child: Text(report['title'] as String,
                    style: MedBuddyTextStyles.label.copyWith(
                        fontWeight: FontWeight.w700,
                        color: MedBuddyColors.primaryDark)),
              ),
            ],
          ),
          const Divider(color: MedBuddyColors.primaryLight, height: 16),
          _reportRow('Mood', '${report['mood']}/5', MedBuddyColors.slate700),
          _reportRow('Pain level', '${report['pain']}/10 — Low',
              MedBuddyColors.success),
          _reportRow(
              'Sleep', report['sleep'] as String, MedBuddyColors.warning),
          _reportRow(
              'Medications',
              (report['meds'] as bool) ? 'All taken' : 'Missed',
              MedBuddyColors.success),
        ],
      ),
    );
  }

  Widget _reportRow(String label, String value, Color valueColor) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: MedBuddyTextStyles.caption),
          Text(value,
              style: MedBuddyTextStyles.caption
                  .copyWith(color: valueColor, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Widget _buildInputBar() {
    return Container(
      padding: const EdgeInsets.only(
        left: MedBuddyDimens.spacingMd,
        right: MedBuddyDimens.spacingMd,
        top: MedBuddyDimens.spacingSm,
        bottom: MedBuddyDimens.spacingSm,
      ),
      decoration: const BoxDecoration(
        color: MedBuddyColors.pureWhite,
        border:
            Border(top: BorderSide(color: MedBuddyColors.slate300, width: 0.5)),
      ),
      child: Row(
        children: [
          // SOS compact
          GestureDetector(
            onTap: () {
              // TODO: Navigate to SOSConfirmationScreen
            },
            child: Container(
              width: 44,
              height: 44,
              decoration: const BoxDecoration(
                color: MedBuddyColors.emergency,
                shape: BoxShape.circle,
              ),
              child: const Center(
                child: Text('SOS',
                    style: TextStyle(
                        color: MedBuddyColors.pureWhite,
                        fontSize: 10,
                        fontWeight: FontWeight.w700)),
              ),
            ),
          ),
          const SizedBox(width: MedBuddyDimens.spacingSm),
          // Text field
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
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
                onSubmitted: (_) => _sendText(),
              ),
            ),
          ),
          const SizedBox(width: MedBuddyDimens.spacingSm),
          // Voice record / send
          GestureDetector(
            onTap: _toggleVoiceRecord,
            child: Container(
              width: MedBuddyDimens.micButtonSize,
              height: MedBuddyDimens.micButtonSize,
              decoration: BoxDecoration(
                color: _isRecording
                    ? MedBuddyColors.primaryDark
                    : MedBuddyColors.primary,
                shape: BoxShape.circle,
              ),
              child: Icon(
                _isRecording ? Icons.stop : Icons.mic_none,
                color: MedBuddyColors.pureWhite,
                size: 24,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Convert ChatMessage model list to display map list
  List<Map<String, dynamic>> _toMapList(List<ChatMessage> msgs) {
    return msgs
        .map((m) => {
              'from': m.isFromAI ? 'caregiver' : 'patient',
              'type': m.type == MessageType.voice ? 'voice' : 'text',
              'content': m.content,
              'time':
                  '${m.timestamp.hour}:${m.timestamp.minute.toString().padLeft(2, '0')}',
              'read': true,
            })
        .toList();
  }
}
