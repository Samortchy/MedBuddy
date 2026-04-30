// lib/providers/fall_provider.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';

enum FallState { idle, detected, cancelled, confirmed }

class FallNotifier extends StateNotifier<FallState> {
  FallNotifier() : super(FallState.idle);

  void onFallDetected() {
    state = FallState.detected;
  }

  void cancel() {
    state = FallState.cancelled;
  }

  void confirm() {
    // Timer expired without action
    state = FallState.confirmed;
  }

  void reset() {
    state = FallState.idle;
  }
}

final fallProvider = StateNotifierProvider<FallNotifier, FallState>((ref) {
  return FallNotifier();
});
