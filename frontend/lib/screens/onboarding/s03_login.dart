import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '/constants/colors.dart';
import '/constants/dimens.dart';
import '/constants/text_styles.dart';
import '/providers/auth_provider.dart';
import '/providers/onboarding_provider.dart';
import '/services/api_service.dart';
import 's04_basic_info.dart';

class S03Login extends ConsumerStatefulWidget {
  final String role;
  const S03Login({super.key, this.role = ''});

  @override
  ConsumerState<S03Login> createState() => _S03LoginState();
}

class _S03LoginState extends ConsumerState<S03Login> {
  bool isLogin = false;
  bool obscurePassword = true;
  bool _isLoading = false;
  String? _errorMessage;

  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  String get roleLabel => widget.role == 'patient' ? 'Patient' : 'Caregiver';
  Color get roleBadgeColor => widget.role == 'patient'
      ? MedBuddyColors.primary
      : MedBuddyColors.success;

  Future<void> _submit() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text;

    if (email.isEmpty || password.isEmpty) {
      setState(() => _errorMessage = 'Please enter your email and password.');
      return;
    }
    if (password.length < 6) {
      setState(() => _errorMessage = 'Password must be at least 6 characters.');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final notifier = ref.read(authProvider.notifier);

    if (isLogin) {
      await notifier.signIn(email, password);
    } else {
      await notifier.signUp(email, password, widget.role);
    }

    if (!mounted) return;
    setState(() => _isLoading = false);

    await Future.delayed(const Duration(milliseconds: 200));
    if (!mounted) return;

    ref.invalidate(onboardingProvider);

    final authState = ref.read(authProvider);
    authState.when(
      data: (user) async {
        if (user == null) return;
        if (user.role == 'caregiver') {
          Navigator.of(context).pushNamedAndRemoveUntil('/caregiver-home', (_) => false);
        } else if (isLogin) {
          // For existing accounts: skip onboarding if profile is already set up
          final nav = Navigator.of(context);
          try {
            await ref.read(apiServiceProvider).get('/patient/profile');
            if (!mounted) return;
            nav.pushNamedAndRemoveUntil('/home', (_) => false);
          } catch (_) {
            if (!mounted) return;
            nav.push(MaterialPageRoute(builder: (_) => const S04BasicInfo()));
          }
        } else {
          Navigator.of(context).push(MaterialPageRoute(builder: (_) => const S04BasicInfo()));
        }
      },
      error: (err, _) {
        final msg = err.toString();
        setState(() {
          _errorMessage = msg == 'check_email'
              ? 'Account created! Please check your email to confirm, then sign in.'
              : msg;
          _isLoading = false;
        });
      },
      loading: () {},
    );

    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: MedBuddyColors.warmWhite,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.only(
                top: MedBuddyDimens.spacingMd,
                left: MedBuddyDimens.spacingLg,
                right: MedBuddyDimens.spacingLg,
              ),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: const Icon(
                      Icons.arrow_back_ios_new,
                      color: MedBuddyColors.slate900,
                      size: 20,
                    ),
                  ),
                ],
              ),
            ),

            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(MedBuddyDimens.spacingXl),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: MedBuddyDimens.spacingMd,
                        vertical: MedBuddyDimens.spacingXs,
                      ),
                      decoration: BoxDecoration(
                        color: roleBadgeColor.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(
                          MedBuddyDimens.radiusPill,
                        ),
                        border: Border.all(
                          color: roleBadgeColor.withValues(alpha: 0.4),
                        ),
                      ),
                      child: Text(
                        roleLabel,
                        style: MedBuddyTextStyles.label.copyWith(
                          fontWeight: FontWeight.w700,
                          color: roleBadgeColor,
                        ),
                      ),
                    ),

                    const SizedBox(height: MedBuddyDimens.spacingXl),

                    Text(
                      isLogin ? 'Welcome back' : 'Create your account',
                      style: MedBuddyTextStyles.heading1.copyWith(
                        fontSize: 28,
                        color: MedBuddyColors.slate900,
                      ),
                    ),
                    const SizedBox(height: MedBuddyDimens.spacingXs),
                    Text(
                      isLogin
                          ? 'Sign in to continue to MedBuddy.'
                          : 'Set up your account to get started.',
                      style: MedBuddyTextStyles.body.copyWith(
                        color: MedBuddyColors.slate500,
                      ),
                    ),

                    const SizedBox(height: MedBuddyDimens.spacingXxl),

                    const _FieldLabel('Email address'),
                    const SizedBox(height: MedBuddyDimens.spacingSm),
                    TextField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      style: MedBuddyTextStyles.body.copyWith(
                        color: MedBuddyColors.slate900,
                      ),
                      decoration: _inputDecoration(
                        'you@example.com',
                        Icons.email_outlined,
                      ),
                    ),

                    const SizedBox(height: MedBuddyDimens.spacingXl),

                    const _FieldLabel('Password'),
                    const SizedBox(height: MedBuddyDimens.spacingSm),
                    TextField(
                      controller: _passwordController,
                      obscureText: obscurePassword,
                      style: MedBuddyTextStyles.body.copyWith(
                        color: MedBuddyColors.slate900,
                      ),
                      decoration:
                          _inputDecoration(
                            '••••••••',
                            Icons.lock_outline,
                          ).copyWith(
                            suffixIcon: IconButton(
                              icon: Icon(
                                obscurePassword
                                    ? Icons.visibility_off
                                    : Icons.visibility,
                                color: MedBuddyColors.slate500,
                              ),
                              onPressed: () => setState(
                                () => obscurePassword = !obscurePassword,
                              ),
                            ),
                          ),
                    ),

                    if (isLogin) ...[
                      const SizedBox(height: MedBuddyDimens.spacingSm),
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: () {},
                          child: Text(
                            'Forgot password?',
                            style: MedBuddyTextStyles.secondary.copyWith(
                              color: MedBuddyColors.primary,
                            ),
                          ),
                        ),
                      ),
                    ],

                    if (_errorMessage != null) ...[
                      const SizedBox(height: MedBuddyDimens.spacingMd),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(MedBuddyDimens.spacingMd),
                        decoration: BoxDecoration(
                          color: MedBuddyColors.emergency.withValues(
                            alpha: 0.08,
                          ),
                          borderRadius: BorderRadius.circular(
                            MedBuddyDimens.radiusMd,
                          ),
                          border: Border.all(
                            color: MedBuddyColors.emergency.withValues(
                              alpha: 0.3,
                            ),
                          ),
                        ),
                        child: Text(
                          _errorMessage!,
                          style: MedBuddyTextStyles.secondary.copyWith(
                            color: MedBuddyColors.emergency,
                          ),
                        ),
                      ),
                    ],

                    const SizedBox(height: MedBuddyDimens.spacingXxl),

                    SizedBox(
                      width: double.infinity,
                      height: MedBuddyDimens.buttonHeightPrimary,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _submit,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: MedBuddyColors.primary,
                          foregroundColor: MedBuddyColors.pureWhite,
                          disabledBackgroundColor: MedBuddyColors.primary
                              .withValues(alpha: 0.6),
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(
                              MedBuddyDimens.radiusLg,
                            ),
                          ),
                        ),
                        child: _isLoading
                            ? const SizedBox(
                                height: 22,
                                width: 22,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.5,
                                  color: Colors.white,
                                ),
                              )
                            : Text(
                                isLogin ? 'Sign In' : 'Create Account',
                                style: MedBuddyTextStyles.bodyBold.copyWith(
                                  color: MedBuddyColors.pureWhite,
                                ),
                              ),
                      ),
                    ),

                    const SizedBox(height: MedBuddyDimens.spacingXl),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          isLogin
                              ? "Don't have an account? "
                              : 'Already have an account? ',
                          style: MedBuddyTextStyles.secondary.copyWith(
                            color: MedBuddyColors.slate500,
                          ),
                        ),
                        GestureDetector(
                          onTap: () => setState(() {
                            isLogin = !isLogin;
                            _errorMessage = null;
                          }),
                          child: Text(
                            isLogin ? 'Register' : 'Sign In',
                            style: MedBuddyTextStyles.secondary.copyWith(
                              fontWeight: FontWeight.w700,
                              color: MedBuddyColors.primary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String hint, IconData icon) {
    return InputDecoration(
      hintText: hint,
      hintStyle: MedBuddyTextStyles.body.copyWith(
        color: MedBuddyColors.slate500,
      ),
      prefixIcon: Icon(icon, color: MedBuddyColors.slate500),
      filled: true,
      fillColor: MedBuddyColors.slate100,
      contentPadding: const EdgeInsets.symmetric(
        horizontal: MedBuddyDimens.spacingLg,
        vertical: MedBuddyDimens.spacingLg,
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(MedBuddyDimens.radiusLg),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(MedBuddyDimens.radiusLg),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(MedBuddyDimens.radiusLg),
        borderSide: const BorderSide(color: MedBuddyColors.primary, width: 2),
      ),
    );
  }
}

class _FieldLabel extends StatelessWidget {
  final String text;
  const _FieldLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: MedBuddyTextStyles.label.copyWith(
        fontWeight: FontWeight.w600,
        color: MedBuddyColors.slate700,
      ),
    );
  }
}
