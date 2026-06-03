import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../constants/colors.dart';
import '../../../constants/text_styles.dart';
import '../../../providers/fall_provider.dart';
import 'fall_verification/widgets/waveform_animator.dart';
import 'fall_verification/widgets/mic_indicator.dart';
import 'fall_verification/widgets/verification_prompt.dart';
import 'fall_verification/widgets/factor_overlay.dart';
import 'fall_verification/widgets/confirmation_overlay.dart';
import '../../../widgets/shared/countdown_ring.dart';

enum VerificationState { ttsPlaying, listening, matched, failed }

class FallVerificationScreen extends ConsumerStatefulWidget {
  const FallVerificationScreen({super.key});

  @override
  ConsumerState<FallVerificationScreen> createState() =>
      _FallVerificationScreenState();
}

class _FallVerificationScreenState
    extends ConsumerState<FallVerificationScreen> {
  final FocusNode _focusNode = FocusNode();
  final TextEditingController _textController = TextEditingController();

  VerificationState _state = VerificationState.listening;
  bool _showFactorOverlay = false;
  bool _showConfirmation = false;

  static const String _prompt =
      'Please say or write your full name to confirm you are okay';

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(_onFocusChange);
    if (mounted) setState(() => _state = VerificationState.listening);
    // Log the emergency event on the backend and fetch the Agora channel/token.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(fallProvider.notifier).triggerEmergency();
    });
  }

  /// Patient confirmed they're okay → record + go to the resolved screen.
  void _resolveOkay() {
    ref.read(fallProvider.notifier).verifyLiveness(true, 'factor1');
    Navigator.of(context).pushReplacementNamed('/fall-resolved');
  }

  /// No / failed response → record escalation + open the Agora call screen.
  void _escalateToAgora() {
    ref.read(fallProvider.notifier).verifyLiveness(false, 'factor2');
    Navigator.of(context).pushReplacementNamed('/fall-agora');
  }

  void _onFocusChange() {
    setState(() {});
  }

  void _onMatched() {
    setState(() {
      _state = VerificationState.matched;
      _showConfirmation = true;
    });
  }

  // ignore: unused_element
  void _onListeningFailed() {
    setState(() {
      _state = VerificationState.failed;
      _showFactorOverlay = true;
    });
  }

  // ignore: unused_element
  void _onManualOkay() {
    _resolveOkay();
  }

  void _onFactorSuccess() {
    setState(() => _showFactorOverlay = false);
    _resolveOkay();
  }

  void _onFactorFailed() {
    setState(() => _showFactorOverlay = false);
    _escalateToAgora();
  }

  @override
  void dispose() {
    _focusNode.dispose();
    _textController.dispose();
    super.dispose();
  }

  bool get _isListening =>
      _state == VerificationState.listening && !_focusNode.hasFocus;
  bool get _isTTSPlaying => _state == VerificationState.ttsPlaying;

  @override
  Widget build(BuildContext context) {
    final bool isKeyboardOpen = MediaQuery.of(context).viewInsets.bottom > 0;

    return Scaffold(
      backgroundColor: MedBuddyColors.emergency,
      body: Stack(
        children: [
          Offstage(
            offstage: isKeyboardOpen,
            child: SafeArea(
              child: Align(
                alignment: Alignment.topRight,
                child: Padding(
                  padding: const EdgeInsets.only(top: 16.0, right: 16.0),
                  child: CountdownRing(
                    seconds: 30,
                    size: 60,
                    enableColorTween: false,
                    onExpired: _escalateToAgora,
                  ),
                ),
              ),
            ),
          ),
          GestureDetector(
            onTap: () => FocusScope.of(context).unfocus(),
            behavior: HitTestBehavior.opaque,
            child: SafeArea(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  return SingleChildScrollView(
                    child: ConstrainedBox(
                      constraints:
                          BoxConstraints(minHeight: constraints.maxHeight),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 28, vertical: 40),
                        child: IntrinsicHeight(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                children: [
                                  const Icon(Icons.hearing,
                                      size: 48,
                                      color: MedBuddyColors.pureWhite),
                                  const SizedBox(height: 20),
                                  const VerificationPrompt(text: _prompt),
                                  const SizedBox(height: 32),
                                  AnimatedOpacity(
                                    opacity: _isTTSPlaying ? 1.0 : 0.0,
                                    duration: const Duration(milliseconds: 300),
                                    child: WaveformAnimator(
                                        isPlaying: _isTTSPlaying),
                                  ),
                                ],
                              ),
                              Column(
                                children: [
                                  MicIndicator(isListening: _isListening),
                                  const SizedBox(height: 12),
                                  Text(
                                    _isListening ? 'Listening...' : '',
                                    style: MedBuddyTextStyles.body.copyWith(
                                      color: _isListening
                                          ? MedBuddyColors.pureWhite
                                          : MedBuddyColors.pureWhite
                                              .withValues(alpha: 0.7),
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                              Container(
                                width: double.infinity,
                                height: 60,
                                decoration: BoxDecoration(
                                  color: MedBuddyColors.pureWhite,
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: TextField(
                                  focusNode: _focusNode,
                                  controller: _textController,
                                  style: MedBuddyTextStyles.body
                                      .copyWith(color: MedBuddyColors.slate900),
                                  decoration: InputDecoration(
                                    hintText:
                                        'Type your name here to confirm...',
                                    hintStyle: MedBuddyTextStyles.body.copyWith(
                                        color: MedBuddyColors.slate500),
                                    border: InputBorder.none,
                                    contentPadding: const EdgeInsets.symmetric(
                                        horizontal: 20, vertical: 18),
                                  ),
                                  onSubmitted: (value) {
                                    if (value.trim().isNotEmpty) {
                                      _onMatched();
                                    }
                                  },
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
          if (_showConfirmation)
            ConfirmationOverlay(
              onContactEmergency: () {
                setState(() => _showConfirmation = false);
                _escalateToAgora();
              },
              onCancel: () {
                setState(() => _showConfirmation = false);
                _resolveOkay();
              },
            ),
          if (_showFactorOverlay)
            FactorOverlay(
              onSuccess: _onFactorSuccess,
              onFailed: _onFactorFailed,
            ),
        ],
      ),
    );
  }
}
