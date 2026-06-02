import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'service_interfaces.dart';

// ── AI (LLM) ──────────────────────────────────────────────────────────────────

class ApiAIService implements AIService {
  final Dio _dio;

  ApiAIService(this._dio);

  @override
  Future<String> sendMessage(String userMessage,
      {List<ChatMessage>? history}) async {
    final historyJson = (history ?? [])
        .map((m) => {
              'role': m.isFromAI ? 'assistant' : 'user',
              'content': m.content,
            })
        .toList();

    final response = await _dio.post('/chat', data: {
      'message': userMessage,
      'history': historyJson,
    });
    return (response.data as Map<String, dynamic>)['reply'] as String? ?? '';
  }

  @override
  Stream<String> streamMessage(String userMessage,
      {List<ChatMessage>? history}) {
    return Stream.fromFuture(sendMessage(userMessage, history: history));
  }

  @override
  Future<CheckInSession> startCheckIn() async {
    final reply = await sendMessage(
      'Start a wellness check-in. Ask me the first question about how I am feeling today.',
    );
    final sessionId = DateTime.now().millisecondsSinceEpoch.toString();
    return CheckInSession(
      sessionId: sessionId,
      firstQuestion: CheckInQuestion(
        id: '1',
        text: reply,
        questionNumber: 1,
        totalQuestions: 5,
      ),
    );
  }

  @override
  Future<CheckInQuestion?> submitCheckInAnswer(
      String sessionId, String answer) async {
    final reply = await sendMessage(answer);
    final lower = reply.toLowerCase();
    if (lower.contains('thank you') ||
        lower.contains('check-in complete') ||
        lower.contains('شكرا') ||
        lower.contains('اكتمل')) {
      return null;
    }
    return CheckInQuestion(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      text: reply,
      questionNumber: 2,
      totalQuestions: 5,
    );
  }
}

// ── STT (speech_to_text — local on-device, supports Arabic) ──────────────────

class ApiSTTService implements STTService {
  final Dio _dio;
  bool _listening = false;
  final stt.SpeechToText _speech = stt.SpeechToText();
  final StreamController<String> _partialController =
      StreamController<String>.broadcast();
  Completer<String>? _resultCompleter;

  ApiSTTService(this._dio);

  @override
  bool get isListening => _listening;

  @override
  Stream<String> get partialResults => _partialController.stream;

  @override
  Future<String> startListening() async {
    final available = await _speech.initialize(
      onError: (e) => debugPrint('STT error: $e'),
    );
    if (!available) return '';

    _listening = true;
    _resultCompleter = Completer<String>();

    // Try Arabic locale first; fall back to device default if not available
    final locales = await _speech.locales();
    final arLocale = locales.where((l) =>
        l.localeId.startsWith('ar')).firstOrNull;
    final localeId = arLocale?.localeId; // null = device default

    await _speech.listen(
      onResult: (result) {
        _partialController.add(result.recognizedWords);
        if (result.finalResult &&
            _resultCompleter?.isCompleted == false) {
          _resultCompleter!.complete(result.recognizedWords);
          _listening = false;
        }
      },
      localeId: localeId,
      listenFor: const Duration(seconds: 30),
      pauseFor: const Duration(seconds: 3),
      listenOptions: stt.SpeechListenOptions(cancelOnError: true),
    );

    return await _resultCompleter!.future;
  }

  @override
  Future<void> stopListening() async {
    await _speech.stop();
    _listening = false;
    if (_resultCompleter?.isCompleted == false) {
      _resultCompleter!.complete('');
    }
  }

  /// Send raw audio bytes to the backend Whisper endpoint.
  /// Use this when you have a recorded audio file instead of live mic.
  Future<String> transcribeBytes(Uint8List audioBytes,
      {String? language}) async {
    final formData = FormData.fromMap({
      'audio': MultipartFile.fromBytes(audioBytes, filename: 'audio.wav'),
      if (language != null) 'language': language,
    });
    final response = await _dio.post('/stt', data: formData);
    return (response.data as Map<String, dynamic>)['text'] as String? ?? '';
  }
}

// ── TTS (backend Chatterbox → just_audio playback) ───────────────────────────

class _WavAudioSource extends StreamAudioSource {
  final Uint8List _bytes;
  _WavAudioSource(this._bytes) : super(tag: 'medbuddy_tts');

  @override
  Future<StreamAudioResponse> request([int? start, int? end]) async {
    final from = start ?? 0;
    final to = end ?? _bytes.length;
    return StreamAudioResponse(
      sourceLength: _bytes.length,
      contentLength: to - from,
      offset: from,
      stream: Stream.value(Uint8List.sublistView(_bytes, from, to)),
      contentType: 'audio/wav',
    );
  }
}

class ApiTTSService implements TTSService {
  final Dio _dio;
  bool _speaking = false;
  bool _muted = false;
  AudioPlayer? _player;

  ApiTTSService(this._dio);

  @override
  bool get isSpeaking => _speaking;

  @override
  bool get isMuted => _muted;

  @override
  Future<void> setMuted(bool muted) async {
    _muted = muted;
    if (muted) await _player?.pause();
  }

  @override
  Future<void> speak(String text) async {
    if (_muted || text.trim().isEmpty) return;
    _speaking = true;
    try {
      final response = await _dio.post(
        '/tts',
        data: {'text': text, 'language_id': 'ar'},
        options: Options(responseType: ResponseType.bytes),
      );
      final bytes = Uint8List.fromList(response.data as List<int>);
      _player = AudioPlayer();
      await _player!.setAudioSource(_WavAudioSource(bytes));
      await _player!.play();
      await _player!.playerStateStream.firstWhere(
        (s) => s.processingState == ProcessingState.completed,
      );
    } catch (e) {
      debugPrint('TTS speak error: $e');
    } finally {
      _speaking = false;
    }
  }

  @override
  Future<void> stop() async {
    await _player?.stop();
    _speaking = false;
  }
}
