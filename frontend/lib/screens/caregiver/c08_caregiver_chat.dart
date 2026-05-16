import 'package:flutter/material.dart';
import '/constants/colors.dart';

class C08CaregiverChat extends StatefulWidget {
  const C08CaregiverChat({super.key});

  @override
  State<C08CaregiverChat> createState() => _C08CaregiverChatState();
}

class _C08CaregiverChatState extends State<C08CaregiverChat> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  final List<Map<String, dynamic>> messages = [
    {
      'text': 'Hassan, did you take your morning medication?',
      'isMe': true,
      'time': '9:00 AM',
      'type': 'text'
    },
    {
      'text': 'Yes I took it with breakfast',
      'isMe': false,
      'time': '9:05 AM',
      'type': 'text'
    },
    {
      'text': 'Great! How are you feeling today?',
      'isMe': true,
      'time': '9:06 AM',
      'type': 'text'
    },
    {
      'text': 'A little tired but okay',
      'isMe': false,
      'time': '9:10 AM',
      'type': 'text'
    },
    {
      'text': '🎤 Voice message (0:12)',
      'isMe': true,
      'time': '9:15 AM',
      'type': 'voice'
    },
    {
      'text':
          'Wellness Check-in Summary\nMood: 3/5 • Pain: 4/10\nSleep: Poor • Energy: 2/5',
      'isMe': true,
      'time': '9:20 AM',
      'type': 'report'
    },
  ];

  void _sendMessage() {
    if (_controller.text.trim().isEmpty) return;
    setState(() {
      messages.add({
        'text': _controller.text.trim(),
        'isMe': true,
        'time': 'Now',
        'type': 'text',
      });
      _controller.clear();
    });
    Future.delayed(const Duration(milliseconds: 100), () {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: MedColors.warmWhite,
      appBar: AppBar(
        backgroundColor: MedColors.primaryDark,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Row(
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: MedColors.primaryLight,
              child: Text('H',
                  style: TextStyle(
                      color: MedColors.primaryDark,
                      fontWeight: FontWeight.bold)),
            ),
            SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Hassan Ali',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold)),
                Text('Patient',
                    style: TextStyle(color: Colors.white70, fontSize: 12)),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.share, color: Colors.white),
            tooltip: 'Share Health Report',
            onPressed: () => _showShareReport(context),
          ),
        ],
      ),
      body: Column(
        children: [
          // Messages
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(16),
              itemCount: messages.length,
              itemBuilder: (context, i) {
                final msg = messages[i];
                return _ChatBubble(
                  text: msg['text'],
                  isMe: msg['isMe'],
                  time: msg['time'],
                  type: msg['type'],
                );
              },
            ),
          ),

          // Input bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: const BoxDecoration(
              color: Colors.white,
              border: Border(top: BorderSide(color: MedColors.slate300)),
            ),
            child: Row(
              children: [
                // Voice button
                Container(
                  decoration: BoxDecoration(
                    color: MedColors.primarySoft,
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.mic, color: MedColors.primary),
                    onPressed: () {},
                  ),
                ),
                const SizedBox(width: 8),
                // Text input
                Expanded(
                  child: TextField(
                    controller: _controller,
                    decoration: InputDecoration(
                      hintText: 'Type a message...',
                      hintStyle: const TextStyle(color: MedColors.slate500),
                      filled: true,
                      fillColor: MedColors.slate100,
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 10),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    onSubmitted: (_) => _sendMessage(),
                  ),
                ),
                const SizedBox(width: 8),
                // Send button
                Container(
                  decoration: BoxDecoration(
                    color: MedColors.primary,
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.send, color: Colors.white),
                    onPressed: _sendMessage,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showShareReport(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => const Padding(
        padding: EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Share Health Report',
                style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: MedColors.slate900)),
            SizedBox(height: 16),
            _ReportOption(
                icon: Icons.check_circle_outline,
                label: 'Wellness Check-in Summary'),
            _ReportOption(
                icon: Icons.medication, label: 'Medication Adherence Report'),
            _ReportOption(icon: Icons.timeline, label: 'Symptom Log'),
            SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}

class _ChatBubble extends StatelessWidget {
  final String text;
  final bool isMe;
  final String time;
  final String type;

  const _ChatBubble({
    required this.text,
    required this.isMe,
    required this.time,
    required this.type,
  });

  @override
  Widget build(BuildContext context) {
    if (type == 'report') {
      return Align(
        alignment: Alignment.centerRight,
        child: Container(
          margin: const EdgeInsets.only(bottom: 12, left: 48),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: MedColors.primarySoft,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: MedColors.primaryLight),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(Icons.insert_chart, color: MedColors.primary, size: 16),
                  SizedBox(width: 6),
                  Text('Health Report',
                      style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: MedColors.primaryDark)),
                ],
              ),
              const SizedBox(height: 6),
              Text(text,
                  style:
                      const TextStyle(fontSize: 14, color: MedColors.slate700)),
              const SizedBox(height: 6),
              Text(time,
                  style:
                      const TextStyle(fontSize: 11, color: MedColors.slate500)),
            ],
          ),
        ),
      );
    }

    if (type == 'voice') {
      return Align(
        alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
        child: Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: isMe ? MedColors.primary : Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: isMe ? null : Border.all(color: MedColors.slate300),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.play_circle_fill,
                  color: isMe ? Colors.white : MedColors.primary, size: 20),
              const SizedBox(width: 8),
              Text(text,
                  style: TextStyle(
                    fontSize: 14,
                    color: isMe ? Colors.white : MedColors.slate900,
                  )),
            ],
          ),
        ),
      );
    }

    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: EdgeInsets.only(
          bottom: 8,
          left: isMe ? 48 : 0,
          right: isMe ? 0 : 48,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: isMe ? MedColors.primary : Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(18),
            topRight: const Radius.circular(18),
            bottomLeft: Radius.circular(isMe ? 18 : 4),
            bottomRight: Radius.circular(isMe ? 4 : 18),
          ),
          border: isMe ? null : Border.all(color: MedColors.slate300),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(text,
                style: TextStyle(
                  fontSize: 15,
                  color: isMe ? Colors.white : MedColors.slate900,
                )),
            const SizedBox(height: 4),
            Text(time,
                style: TextStyle(
                  fontSize: 11,
                  color: isMe ? Colors.white70 : MedColors.slate500,
                )),
          ],
        ),
      ),
    );
  }
}

class _ReportOption extends StatelessWidget {
  final IconData icon;
  final String label;

  const _ReportOption({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: MedColors.primary),
      title: Text(label,
          style: const TextStyle(fontSize: 15, color: MedColors.slate900)),
      trailing: const Icon(Icons.send, color: MedColors.primary, size: 18),
      onTap: () => Navigator.pop(context),
    );
  }
}
