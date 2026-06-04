import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/api_service.dart';

/// A single message in a caregiver↔patient conversation.
class LinkMessage {
  final String id;
  final String senderId;
  final String content;
  final String? voiceUrl;
  final DateTime sentAt;

  const LinkMessage({
    required this.id,
    required this.senderId,
    required this.content,
    this.voiceUrl,
    required this.sentAt,
  });

  bool get isVoice => voiceUrl != null && voiceUrl!.isNotEmpty;

  factory LinkMessage.fromJson(Map<String, dynamic> json) {
    DateTime ts;
    try {
      ts = DateTime.parse(json['sent_at'] as String).toLocal();
    } catch (_) {
      ts = DateTime.now();
    }
    final raw = json['voice_url'] as String?;
    return LinkMessage(
      id: json['id'] as String? ?? '',
      senderId: json['sender_id'] as String? ?? '',
      content: json['content'] as String? ?? '',
      voiceUrl: (raw != null && raw.isNotEmpty) ? raw : null,
      sentAt: ts,
    );
  }
}

/// Message thread for a given caregiver_patient_links id.
final conversationProvider =
    FutureProvider.family<List<LinkMessage>, String>((ref, linkId) async {
  final dio = ref.watch(apiServiceProvider);
  final res = await dio.get('/caregiver/links/$linkId/messages');
  final list = res.data as List<dynamic>? ?? [];
  return list
      .map((e) => LinkMessage.fromJson(e as Map<String, dynamic>))
      .toList();
});
