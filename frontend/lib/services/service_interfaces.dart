/// MedBuddy Service Interfaces
///
/// These are abstract contracts. When you integrate your backend,
/// create concrete implementations and inject them via your state
/// management solution (Provider, Riverpod, Bloc, etc).
///
/// Nothing in the UI assumes any implementation detail.
library;

// ─────────────────────────────────────────────
// AI / LLM Service (Qwen 2.5 7B via your backend)
// ─────────────────────────────────────────────
abstract class AIService {
  /// Send a user message, receive an AI response string.
  Future<String> sendMessage(String userMessage, {List<ChatMessage>? history});

  /// Stream tokens for a response (for real-time typing effect).
  Stream<String> streamMessage(String userMessage,
      {List<ChatMessage>? history});

  /// Start a structured wellness check-in session.
  Future<CheckInSession> startCheckIn();

  /// Submit a check-in answer and get the next question.
  Future<CheckInQuestion?> submitCheckInAnswer(String sessionId, String answer);
}

// ─────────────────────────────────────────────
// STT Service (Faster-Whisper via your backend)
// ─────────────────────────────────────────────
abstract class STTService {
  /// Start listening. Returns transcribed text when user stops speaking.
  Future<String> startListening();

  /// Stop listening manually.
  Future<void> stopListening();

  /// Stream of partial transcription results (live).
  Stream<String> get partialResults;

  /// Whether the STT is currently listening.
  bool get isListening;
}

// ─────────────────────────────────────────────
// TTS Service (ElevenLabs / Coqui XTTS-v2)
// ─────────────────────────────────────────────
abstract class TTSService {
  /// Speak the given text aloud.
  Future<void> speak(String text);

  /// Stop speaking immediately.
  Future<void> stop();

  /// Whether TTS is currently speaking.
  bool get isSpeaking;

  /// Muted state.
  bool get isMuted;
  Future<void> setMuted(bool muted);
}

// ─────────────────────────────────────────────
// Agora Service (real-time audio channel)
// ─────────────────────────────────────────────
abstract class AgoraService {
  /// Open a real-time audio channel to a caregiver.
  Future<AgoraChannelResult> openChannel(String channelId, String caregiverUid);

  /// Close the active channel.
  Future<void> closeChannel();

  /// Stream of channel status updates.
  Stream<AgoraChannelStatus> get channelStatus;
}

// ─────────────────────────────────────────────
// Emergency Service
// ─────────────────────────────────────────────
abstract class EmergencyService {
  /// Trigger SOS — sends SMS, activates Agora, escalates to 911 if needed.
  Future<void> triggerSOS();

  /// Cancel SOS within the grace period.
  Future<void> cancelSOS();

  /// Report fall detection event.
  Future<void> reportFallDetected();

  /// Verify liveness by name match.
  Future<LivenessResult> verifyLiveness(String spokenName);
}

// ─────────────────────────────────────────────
// Data Models (plain Dart — no backend assumed)
// ─────────────────────────────────────────────

class ChatMessage {
  final String id;
  final String content;
  final bool isFromAI;
  final DateTime timestamp;
  final MessageType type;

  const ChatMessage({
    required this.id,
    required this.content,
    required this.isFromAI,
    required this.timestamp,
    this.type = MessageType.text,
  });
}

enum MessageType { text, voice, healthReport }

class CheckInSession {
  final String sessionId;
  final CheckInQuestion firstQuestion;
  const CheckInSession({required this.sessionId, required this.firstQuestion});
}

class CheckInQuestion {
  final String id;
  final String text;
  final int questionNumber;
  final int totalQuestions;
  const CheckInQuestion({
    required this.id,
    required this.text,
    required this.questionNumber,
    required this.totalQuestions,
  });
}

enum AgoraChannelStatus { connecting, connected, failed, disconnected }

class AgoraChannelResult {
  final bool success;
  final AgoraChannelStatus status;
  final String? errorMessage;
  const AgoraChannelResult({
    required this.success,
    required this.status,
    this.errorMessage,
  });
}

enum LivenessResult { matched, noMatch, noResponse }

class MedicationEntry {
  final String id;
  final String name;
  final String dose;
  final String frequency;
  final MedicationStatus status;
  final DateTime? takenAt;

  const MedicationEntry({
    required this.id,
    required this.name,
    required this.dose,
    required this.frequency,
    required this.status,
    this.takenAt,
  });
}

enum MedicationStatus { taken, pending, missed, late }

class EmergencyEvent {
  final String id;
  final EmergencyEventType type;
  final DateTime timestamp;
  final EmergencyOutcome outcome;
  final List<EmergencyStep> steps;
  final String? gpsCoordinates;

  const EmergencyEvent({
    required this.id,
    required this.type,
    required this.timestamp,
    required this.outcome,
    required this.steps,
    this.gpsCoordinates,
  });
}

enum EmergencyEventType { fallDetected, manualSOS }

enum EmergencyOutcome {
  handledByCaregiver,
  falseAlarm,
  activated911,
  cancelled
}

class EmergencyStep {
  final String description;
  final DateTime timestamp;
  final bool success;
  const EmergencyStep({
    required this.description,
    required this.timestamp,
    required this.success,
  });
}

class SymptomEntry {
  final String id;
  final String description;
  final DateTime timestamp;
  final SymptomSeverity severity;

  const SymptomEntry({
    required this.id,
    required this.description,
    required this.timestamp,
    required this.severity,
  });
}

enum SymptomSeverity { normal, watch, flagged }

class WellnessCheckIn {
  final String id;
  final DateTime timestamp;
  final int mood; // 1–5
  final int energy; // 1–5
  final int painLevel; // 0–10
  final String sleepQuality;
  final bool allMedsTaken;
  final bool isFlagged;

  const WellnessCheckIn({
    required this.id,
    required this.timestamp,
    required this.mood,
    required this.energy,
    required this.painLevel,
    required this.sleepQuality,
    required this.allMedsTaken,
    this.isFlagged = false,
  });
}

class CaregiverLink {
  final String id;
  final String name;
  final String relationship;
  final String initials;
  final bool isActive;

  const CaregiverLink({
    required this.id,
    required this.name,
    required this.relationship,
    required this.initials,
    this.isActive = true,
  });
}

class PatientProfile {
  final String id;
  final String fullName;
  final int age;
  final String gender;
  final String language;
  final List<String> conditions;
  final List<MedicationEntry> medications;
  final String primaryContactName;
  final String primaryContactPhone;
  final String primaryContactRelationship;
  final int checkInHour;
  final bool checkInVoiceMode;
  final int painBaseline;
  final List<CaregiverLink> caregivers;
  final int profileCompleteness; // 0–100

  const PatientProfile({
    required this.id,
    required this.fullName,
    required this.age,
    required this.gender,
    required this.language,
    required this.conditions,
    required this.medications,
    required this.primaryContactName,
    required this.primaryContactPhone,
    required this.primaryContactRelationship,
    required this.checkInHour,
    required this.checkInVoiceMode,
    required this.painBaseline,
    required this.caregivers,
    required this.profileCompleteness,
  });
}
