import 'package:flutter/material.dart';
import '../../../constants/colors.dart';
import '../../../constants/dimens.dart';
import '../../../constants/text_styles.dart';
import '../../../services/service_interfaces.dart';
import '../../../widgets/shared/sos_button.dart';

/// S-17b — Wellness Check-in Active
///
/// Full-screen check-in experience. No bottom nav — focused flow.
///
/// Backend hooks:
/// - [aiService]  → AIService.startCheckIn() / submitCheckInAnswer()
/// - [sttService] → STTService for voice answers
/// - [ttsService] → TTSService to read questions aloud
/// - [onComplete] → Called when all questions are answered
class WellnessCheckInScreen extends StatefulWidget {
  final AIService? aiService;
  final STTService? sttService;
  final TTSService? ttsService;
  final VoidCallback? onComplete;
  final VoidCallback? onDismiss;

  const WellnessCheckInScreen({
    super.key,
    this.aiService,
    this.sttService,
    this.ttsService,
    this.onComplete,
    this.onDismiss,
  });

  @override
  State<WellnessCheckInScreen> createState() => _WellnessCheckInScreenState();
}

class _WellnessCheckInScreenState extends State<WellnessCheckInScreen>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late AnimationController _waveController;
  late Animation<double> _pulseAnimation;

  final TextEditingController _textController = TextEditingController();

  bool _isListening = false;

  // Replace with real session data from AIService.startCheckIn()
  final int _currentQuestion = 3;
  final int _totalQuestions = 5;
  final String _questionText =
      'How are you feeling today? Rate your energy from 1 to 5.';
  // ignore: unused_field
  final String _sessionId = ''; // set from AIService.startCheckIn()

  @override
  void initState() {
    super.initState();

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();

    _waveController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 0.95, end: 1.08).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    // TODO: Start check-in session and read question aloud
    // _initSession();
  }

  // ── Backend hook: init session ────────────────────────────────
  // Future<void> _initSession() async {
  //   final session = await widget.aiService?.startCheckIn();
  //   if (session != null && mounted) {
  //     setState(() {
  //       _sessionId = session.sessionId;
  //       _questionText = session.firstQuestion.text;
  //       _currentQuestion = session.firstQuestion.questionNumber;
  //       _totalQuestions = session.firstQuestion.totalQuestions;
  //     });
  //     widget.ttsService?.speak(_questionText);
  //   }
  // }

  @override
  void dispose() {
    _pulseController.dispose();
    _waveController.dispose();
    _textController.dispose();
    super.dispose();
  }

  // ── Backend hook: submit answer ────────────────────────────────
  Future<void> _submitAnswer(String answer) async {
    // TODO:
    // final nextQuestion = await widget.aiService
    //     ?.submitCheckInAnswer(_sessionId, answer);
    // if (nextQuestion == null) {
    //   widget.onComplete?.call();
    //   return;
    // }
    // setState(() {
    //   _questionText = nextQuestion.text;
    //   _currentQuestion = nextQuestion.questionNumber;
    // });
    // widget.ttsService?.speak(_questionText);
  }

  // ── Backend hook: toggle mic ───────────────────────────────────
  Future<void> _toggleListening() async {
    if (_isListening) {
      setState(() => _isListening = false);
      // TODO: final text = await widget.sttService?.stopListening();
      // if (text != null) _submitAnswer(text);
    } else {
      setState(() => _isListening = true);
      // TODO: widget.sttService?.startListening();
    }
  }

  void _skipQuestion() {
    // TODO: submit empty/skip answer
    _submitAnswer('skip');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: MedBuddyColors.warmWhite,
      body: Stack(
        children: [
          SafeArea(
            child: Column(
              children: [
                _buildAppBar(),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: MedBuddyDimens.spacingXl),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _buildAvatar(),
                        _buildQuestion(),
                        _buildWaveform(),
                        _buildProgress(),
                      ],
                    ),
                  ),
                ),
                _buildInputBar(),
              ],
            ),
          ),
          const SOSButton(),
        ],
      ),
    );
  }

  Widget _buildAppBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: MedBuddyDimens.spacingLg,
        vertical: MedBuddyDimens.spacingSm,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const SizedBox(width: 36),
          const Text('Daily Check-in', style: MedBuddyTextStyles.heading3),
          IconButton(
            onPressed: widget.onDismiss ?? () => Navigator.of(context).pop(),
            icon: const Icon(Icons.close, color: MedBuddyColors.slate500),
          ),
        ],
      ),
    );
  }

  Widget _buildAvatar() {
    return Column(
      children: [
        ScaleTransition(
          scale: _pulseAnimation,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Outer ring
              Container(
                width: 140,
                height: 140,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border:
                      Border.all(color: MedBuddyColors.primaryLight, width: 2),
                ),
              ),
              // Mid ring
              Container(
                width: 116,
                height: 116,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border:
                      Border.all(color: MedBuddyColors.primaryMid, width: 2),
                ),
              ),
              // Avatar
              Container(
                width: 92,
                height: 92,
                decoration: const BoxDecoration(
                  color: MedBuddyColors.primary,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.smart_toy_outlined,
                    color: MedBuddyColors.pureWhite, size: 40),
              ),
            ],
          ),
        ),
        const SizedBox(height: MedBuddyDimens.spacingMd),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: const BoxDecoration(
                color: MedBuddyColors.success,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 6),
            Text(
              'LISTENING',
              style: MedBuddyTextStyles.caption.copyWith(
                letterSpacing: 0.8,
                color: MedBuddyColors.slate500,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildQuestion() {
    return Column(
      children: [
        Text(
          _questionText,
          style: MedBuddyTextStyles.heading1.copyWith(
            fontSize: 22,
            color: MedBuddyColors.slate900,
            height: 1.4,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: MedBuddyDimens.spacingMd),
        const Text(
          'Speak your answer or type below.',
          style: MedBuddyTextStyles.secondary,
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildWaveform() {
    return AnimatedBuilder(
      animation: _waveController,
      builder: (_, __) {
        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(15, (i) {
            final heights = [
              12.0,
              20.0,
              30.0,
              38.0,
              44.0,
              44.0,
              38.0,
              30.0,
              20.0,
              12.0,
              28.0,
              36.0,
              42.0,
              34.0,
              22.0
            ];
            final base = heights[i];
            final wave = _isListening
                ? base * (0.6 + 0.4 * _waveController.value)
                : base * 0.3;
            return Container(
              width: 4,
              height: wave,
              margin: const EdgeInsets.symmetric(horizontal: 2),
              decoration: BoxDecoration(
                color: MedBuddyColors.primaryMid,
                borderRadius: BorderRadius.circular(4),
              ),
            );
          }),
        );
      },
    );
  }

  Widget _buildProgress() {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(_totalQuestions, (i) {
            final isActive = i == _currentQuestion - 1;
            return Container(
              width: isActive ? 14 : 10,
              height: isActive ? 14 : 10,
              margin: const EdgeInsets.symmetric(horizontal: 5),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: i < _currentQuestion
                    ? MedBuddyColors.primaryLight
                    : i == _currentQuestion - 1
                        ? MedBuddyColors.primary
                        : MedBuddyColors.slate300,
              ),
            );
          }),
        ),
        const SizedBox(height: MedBuddyDimens.spacingSm),
        Text(
          'Question $_currentQuestion of $_totalQuestions',
          style: MedBuddyTextStyles.label,
        ),
        const SizedBox(height: MedBuddyDimens.spacingSm),
        GestureDetector(
          onTap: _skipQuestion,
          child: Text(
            'Skip this question',
            style: MedBuddyTextStyles.body.copyWith(
              color: MedBuddyColors.slate500,
              decoration: TextDecoration.underline,
            ),
          ),
        ),
      ],
    );
  }

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
          // SOS compact
          GestureDetector(
            onTap: () => Navigator.of(context).pushNamed('/sos-confirmation'),
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
                      fontWeight: FontWeight.w700,
                    )),
              ),
            ),
          ),
          const SizedBox(width: MedBuddyDimens.spacingSm),
          // Text fallback
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: MedBuddyColors.slate100,
                    borderRadius:
                        BorderRadius.circular(MedBuddyDimens.radiusPill),
                  ),
                  child: TextField(
                    controller: _textController,
                    style: MedBuddyTextStyles.body,
                    decoration: InputDecoration(
                      hintText: 'Or type your answer...',
                      hintStyle: MedBuddyTextStyles.body
                          .copyWith(color: MedBuddyColors.slate500),
                      border: InputBorder.none,
                      isDense: true,
                      contentPadding: EdgeInsets.zero,
                    ),
                    onSubmitted: _submitAnswer,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(left: 12, top: 2),
                  child: Text('Voice is preferred',
                      style: MedBuddyTextStyles.caption
                          .copyWith(color: MedBuddyColors.slate500)),
                ),
              ],
            ),
          ),
          const SizedBox(width: MedBuddyDimens.spacingSm),
          // Mic
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
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
              const SizedBox(height: 2),
              Text('Speak',
                  style: MedBuddyTextStyles.caption
                      .copyWith(color: MedBuddyColors.primary)),
            ],
          ),
        ],
      ),
    );
  }
}
