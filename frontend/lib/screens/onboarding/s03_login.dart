import 'package:flutter/material.dart';
import '/constants/colors.dart';
import '/constants/dimens.dart';
import '/constants/text_styles.dart';
import 's04_basic_info.dart';

class S03Login extends StatefulWidget {
  final String role;
  const S03Login({super.key, this.role = ''});

  @override
  State<S03Login> createState() => _S03LoginState();
}

class _S03LoginState extends State<S03Login> {
  bool isLogin = false;
  bool obscurePassword = true;
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: MedBuddyColors.warmWhite,
      body: SafeArea(
        child: Column(
          children: [
            // Back bar
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
                    child: const Icon(Icons.arrow_back_ios_new,
                        color: MedBuddyColors.slate900, size: 20),
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
                    // Role badge
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: MedBuddyDimens.spacingMd,
                          vertical: MedBuddyDimens.spacingXs),
                      decoration: BoxDecoration(
                        color: roleBadgeColor.withValues(alpha: 0.12),
                        borderRadius:
                            BorderRadius.circular(MedBuddyDimens.radiusPill),
                        border: Border.all(
                            color: roleBadgeColor.withValues(alpha: 0.4)),
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

                    // Email
                    const _FieldLabel('Email address'),
                    const SizedBox(height: MedBuddyDimens.spacingSm),
                    TextField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      style: MedBuddyTextStyles.body
                          .copyWith(color: MedBuddyColors.slate900),
                      decoration: _inputDecoration(
                          'you@example.com', Icons.email_outlined),
                    ),

                    const SizedBox(height: MedBuddyDimens.spacingXl),

                    // Password
                    const _FieldLabel('Password'),
                    const SizedBox(height: MedBuddyDimens.spacingSm),
                    TextField(
                      controller: _passwordController,
                      obscureText: obscurePassword,
                      style: MedBuddyTextStyles.body
                          .copyWith(color: MedBuddyColors.slate900),
                      decoration:
                          _inputDecoration('••••••••', Icons.lock_outline)
                              .copyWith(
                        suffixIcon: IconButton(
                          icon: Icon(
                            obscurePassword
                                ? Icons.visibility_off
                                : Icons.visibility,
                            color: MedBuddyColors.slate500,
                          ),
                          onPressed: () => setState(
                              () => obscurePassword = !obscurePassword),
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

                    const SizedBox(height: MedBuddyDimens.spacingXxl),

                    // Main CTA
                    SizedBox(
                      width: double.infinity,
                      height: MedBuddyDimens.buttonHeightPrimary,
                      child: ElevatedButton(
                        onPressed: () {
                          if (widget.role == 'patient') {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (_) => const S04BasicInfo()),
                            );
                          } else {
                            Navigator.of(context).pushNamedAndRemoveUntil(
                              '/caregiver-home',
                              (route) => false,
                            );
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: MedBuddyColors.primary,
                          foregroundColor: MedBuddyColors.pureWhite,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius:
                                BorderRadius.circular(MedBuddyDimens.radiusLg),
                          ),
                        ),
                        child: Text(
                          isLogin ? 'Sign In' : 'Create Account',
                          style: MedBuddyTextStyles.bodyBold
                              .copyWith(color: MedBuddyColors.pureWhite),
                        ),
                      ),
                    ),

                    const SizedBox(height: MedBuddyDimens.spacingLg),

                    // Biometric
                    SizedBox(
                      width: double.infinity,
                      height: MedBuddyDimens.buttonHeightPrimary,
                      child: OutlinedButton.icon(
                        onPressed: () {},
                        icon: const Icon(Icons.fingerprint,
                            color: MedBuddyColors.primary, size: 22),
                        label: Text(
                          'Sign in with Face ID / Fingerprint',
                          style: MedBuddyTextStyles.bodyBold.copyWith(
                            color: MedBuddyColors.primary,
                          ),
                        ),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(
                              color: MedBuddyColors.primary, width: 1.5),
                          shape: RoundedRectangleBorder(
                            borderRadius:
                                BorderRadius.circular(MedBuddyDimens.radiusLg),
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: MedBuddyDimens.spacingXl),

                    // Toggle
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
                          onTap: () => setState(() => isLogin = !isLogin),
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
      hintStyle:
          MedBuddyTextStyles.body.copyWith(color: MedBuddyColors.slate500),
      prefixIcon: Icon(icon, color: MedBuddyColors.slate500),
      filled: true,
      fillColor: MedBuddyColors.slate100,
      contentPadding: const EdgeInsets.symmetric(
          horizontal: MedBuddyDimens.spacingLg,
          vertical: MedBuddyDimens.spacingLg),
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
