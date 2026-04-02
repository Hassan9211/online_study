import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../app/routes/app_routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/app_buttons.dart';
import '../controllers/auth_session_controller.dart';

enum _ForgotPasswordStep { email, otp, password, success }

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final AuthSessionController _authSessionController =
      Get.find<AuthSessionController>();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _otpController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();

  _ForgotPasswordStep _step = _ForgotPasswordStep.email;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  @override
  void initState() {
    super.initState();
    final prefilledEmail = Get.arguments is Map
        ? (Get.arguments as Map)['email']?.toString() ?? ''
        : '';
    if (prefilledEmail.trim().isNotEmpty) {
      _emailController.text = prefilledEmail.trim();
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _otpController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _sendResetEmail() async {
    final email = _emailController.text.trim();
    if (email.isEmpty) {
      _showError('Email is required.');
      return;
    }

    final didSend = await _authSessionController.requestPasswordReset(
      email: email,
    );
    if (!didSend) {
      _showError(_authSessionController.lastErrorMessage);
      return;
    }

    setState(() {
      _step = _ForgotPasswordStep.otp;
    });
  }

  void _continueToPassword() {
    if (_otpController.text.trim().isEmpty) {
      _showError('Reset code is required.');
      return;
    }

    setState(() {
      _step = _ForgotPasswordStep.password;
    });
  }

  Future<void> _resetPassword() async {
    final password = _passwordController.text.trim();
    final confirmPassword = _confirmPasswordController.text.trim();
    final code = _otpController.text.trim();

    if (password.isEmpty || confirmPassword.isEmpty) {
      _showError('Both the new password and confirm password are required.');
      return;
    }
    if (code.isEmpty) {
      _showError('Reset code is required.');
      return;
    }
    if (password.length < 6) {
      _showError('Password must be at least 6 characters long.');
      return;
    }
    if (password != confirmPassword) {
      _showError('Confirm password does not match the new password.');
      return;
    }

    final didReset = await _authSessionController.resetPassword(
      email: _emailController.text,
      code: code,
      newPassword: password,
    );
    if (!didReset) {
      _showError(_authSessionController.lastErrorMessage);
      return;
    }

    setState(() {
      _step = _ForgotPasswordStep.success;
    });
  }

  void _showError(String message) {
    Get.snackbar(
      'Forgot Password',
      message.isEmpty ? 'Something went wrong.' : message,
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: Colors.white,
      colorText: AppColors.heading,
      margin: const EdgeInsets.all(14),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return GetBuilder<AuthSessionController>(
      builder: (authSessionController) {
        return Scaffold(
          backgroundColor: Colors.white,
          body: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 18, 24, 28),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  IconButton(
                    onPressed: Get.back,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    icon: const Icon(
                      Icons.arrow_back_ios_new_rounded,
                      size: 18,
                      color: AppColors.heading,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Forgot Password',
                    style: theme.textTheme.headlineMedium?.copyWith(
                      fontSize: 27,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.6,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _descriptionForStep(),
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: AppColors.mutedText,
                      height: 1.45,
                    ),
                  ),
                  const SizedBox(height: 28),
                  if (_step == _ForgotPasswordStep.email) ...[
                    _SectionLabel(label: 'Email'),
                    const SizedBox(height: 8),
                    _AuthInputField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      hintText: 'Enter your email',
                    ),
                    const SizedBox(height: 22),
                    AppPrimaryButton(
                      label: 'Send Reset Code',
                      onPressed: authSessionController.isBusy
                          ? null
                          : _sendResetEmail,
                      isLoading: authSessionController.isBusy,
                    ),
                  ] else if (_step == _ForgotPasswordStep.otp) ...[
                    _SectionLabel(label: 'Email'),
                    const SizedBox(height: 8),
                    _ReadOnlyBox(value: _emailController.text.trim()),
                    const SizedBox(height: 18),
                    _SectionLabel(label: 'Code'),
                    const SizedBox(height: 8),
                    _AuthInputField(
                      controller: _otpController,
                      keyboardType: TextInputType.number,
                      hintText: 'Enter code from email',
                    ),
                    const SizedBox(height: 22),
                    AppPrimaryButton(
                      label: 'Continue',
                      onPressed: _continueToPassword,
                    ),
                  ] else if (_step == _ForgotPasswordStep.password) ...[
                    _SectionLabel(label: 'New Password'),
                    const SizedBox(height: 8),
                    _AuthInputField(
                      controller: _passwordController,
                      obscureText: _obscurePassword,
                      hintText: 'New password',
                      suffixIcon: IconButton(
                        onPressed: () {
                          setState(() {
                            _obscurePassword = !_obscurePassword;
                          });
                        },
                        icon: Icon(
                          _obscurePassword
                              ? Icons.visibility_off_outlined
                              : Icons.visibility_outlined,
                          size: 20,
                          color: AppColors.heading,
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),
                    _SectionLabel(label: 'Confirm Password'),
                    const SizedBox(height: 8),
                    _AuthInputField(
                      controller: _confirmPasswordController,
                      obscureText: _obscureConfirmPassword,
                      hintText: 'Confirm password',
                      suffixIcon: IconButton(
                        onPressed: () {
                          setState(() {
                            _obscureConfirmPassword = !_obscureConfirmPassword;
                          });
                        },
                        icon: Icon(
                          _obscureConfirmPassword
                              ? Icons.visibility_off_outlined
                              : Icons.visibility_outlined,
                          size: 20,
                          color: AppColors.heading,
                        ),
                      ),
                    ),
                    const SizedBox(height: 22),
                    AppPrimaryButton(
                      label: 'Reset Password',
                      onPressed: authSessionController.isBusy
                          ? null
                          : _resetPassword,
                      isLoading: authSessionController.isBusy,
                    ),
                  ] else ...[
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.fromLTRB(24, 26, 24, 24),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(18),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.heading.withValues(alpha: 0.08),
                            blurRadius: 20,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          Container(
                            width: 62,
                            height: 62,
                            decoration: const BoxDecoration(
                              color: AppColors.primary,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.check,
                              color: Colors.white,
                              size: 32,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Password Updated',
                            style: theme.textTheme.titleLarge?.copyWith(
                              color: AppColors.heading,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'You can now log in with your new password.',
                            textAlign: TextAlign.center,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: AppColors.mutedText,
                              height: 1.4,
                            ),
                          ),
                          const SizedBox(height: 18),
                          SizedBox(
                            width: double.infinity,
                            child: AppPrimaryButton(
                              label: 'Back to Login',
                              onPressed: () => Get.offNamed(AppRoutes.logIn),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  String _descriptionForStep() {
    switch (_step) {
      case _ForgotPasswordStep.email:
        return 'Enter your registered email address. We will send the reset code there.';
      case _ForgotPasswordStep.otp:
        return 'Enter the reset code sent to your email.';
      case _ForgotPasswordStep.password:
        return 'Now set your new password.';
      case _ForgotPasswordStep.success:
        return 'Password reset successfully.';
    }
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
        color: AppColors.mutedText,
        fontSize: 14,
      ),
    );
  }
}

class _ReadOnlyBox extends StatelessWidget {
  const _ReadOnlyBox({required this.value});

  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
      decoration: BoxDecoration(
        color: const Color(0xFFF7F8FD),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.inputBorder),
      ),
      child: Text(
        value,
        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
          color: AppColors.inputText,
          fontSize: 14,
        ),
      ),
    );
  }
}

class _AuthInputField extends StatelessWidget {
  const _AuthInputField({
    required this.controller,
    this.keyboardType,
    this.obscureText = false,
    this.hintText,
    this.suffixIcon,
  });

  final TextEditingController controller;
  final TextInputType? keyboardType;
  final bool obscureText;
  final String? hintText;
  final Widget? suffixIcon;

  @override
  Widget build(BuildContext context) {
    final borderRadius = BorderRadius.circular(10);
    final hintPaint = Paint()
      ..color = AppColors.mutedText.withValues(alpha: 0.7)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 1.2);

    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      obscureText: obscureText,
      style: Theme.of(
        context,
      ).textTheme.bodyLarge?.copyWith(color: AppColors.inputText, fontSize: 14),
      decoration: InputDecoration(
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 16,
        ),
        suffixIcon: suffixIcon,
        hintText: hintText,
        hintStyle: Theme.of(
          context,
        ).textTheme.bodyLarge?.copyWith(foreground: hintPaint, fontSize: 14),
        filled: true,
        fillColor: Colors.white,
        enabledBorder: OutlineInputBorder(
          borderRadius: borderRadius,
          borderSide: const BorderSide(color: AppColors.inputBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: borderRadius,
          borderSide: const BorderSide(color: AppColors.primary),
        ),
      ),
    );
  }
}
