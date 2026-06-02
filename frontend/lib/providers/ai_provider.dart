import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/api_service.dart';
import '../services/api_ai_service.dart';

final aiServiceProvider = Provider<ApiAIService>((ref) {
  return ApiAIService(ref.watch(apiServiceProvider));
});

final sttServiceProvider = Provider<ApiSTTService>((ref) {
  return ApiSTTService(ref.watch(apiServiceProvider));
});

final ttsServiceProvider = Provider<ApiTTSService>((ref) {
  return ApiTTSService(ref.watch(apiServiceProvider));
});
