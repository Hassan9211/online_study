import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../app/routes/app_routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/app_buttons.dart';
import '../controllers/auth_session_controller.dart';

class LogInScreen extends StatefulWidget {
  const LogInScreen({super.key});

  @override
  State<LogInScreen> createState() => _LogInScreenState();
}

class _LogInScreenState extends State<LogInScreen> {
  final AuthSessionController _authSessionController =
      Get.find<AuthSessionController>();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  bool _obscurePassword = true;

  bool get _canLogIn {
    return _emailController.text.trim().isNotEmpty &&
        _passwordController.text.trim().isNotEmpty;
  }

  @override
  void initState() {
    super.initState();
    if (_authSessionController.email.isNotEmpty) {
      _emailController.text = _authSessionController.email;
    }
  }

  Future<void> _handleLogIn() async {
    if (!_canLogIn) {
      return;
    }

    final didLogIn = await _authSessionController.logIn(
      email: _emailController.text,
      password: _passwordController.text,
    );

    if (!didLogIn) {
      Get.snackbar(
        'Log In Failed',
        'Email ya password match nahi kar raha.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.white,
        colorText: AppColors.heading,
        margin: const EdgeInsets.all(14),
      );
      return;
    }

    Get.offAllNamed(AppRoutes.home);
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            const ColoredBox(
              color: AppColors.primary,
              child: SizedBox(width: double.infinity, height: 3),
            ),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(24, 56, 24, 18),
              decoration: const BoxDecoration(
                color: AppColors.topPanel,
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(26),
                  bottomRight: Radius.circular(26),
                ),
              ),
              child: Text(
                'Log In',
                style: theme.textTheme.headlineMedium?.copyWith(
                  fontSize: 27,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.6,
                ),
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 20, 24, 28),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Your Email',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: AppColors.mutedText,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 8),
                    _AuthInputField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      hintText: 'Email',
                      onChanged: (_) => setState(() {}),
                    ),
                    const SizedBox(height: 18),
                    Text(
                      'Password',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: AppColors.mutedText,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 8),
                    _AuthInputField(
                      controller: _passwordController,
                      obscureText: _obscurePassword,
                      hintText: 'Password',
                      onChanged: (_) => setState(() {}),
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
                    const SizedBox(height: 10),
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: () {},
                        style: TextButton.styleFrom(
                          foregroundColor: AppColors.mutedText,
                          padding: EdgeInsets.zero,
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        child: const Text('Forget password?'),
                      ),
                    ),
                    const SizedBox(height: 10),
                    SizedBox(
                      width: double.infinity,
                      child: AppPrimaryButton(
                        label: 'Log In',
                        onPressed: _canLogIn ? _handleLogIn : null,
                      ),
                    ),
                    const SizedBox(height: 18),
                    Center(
                      child: Wrap(
                        alignment: WrapAlignment.center,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          Text(
                            "Don't have an account? ",
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: AppColors.mutedText,
                              fontSize: 13,
                            ),
                          ),
                          GestureDetector(
                            onTap: () => Get.offNamed(AppRoutes.signUp),
                            child: const Text(
                              'Sign up',
                              style: TextStyle(
                                color: AppColors.primary,
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 18),
                    Row(
                      children: [
                        const Expanded(
                          child: Divider(color: AppColors.dividerLine),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 14),
                          child: Text(
                            'Or login with',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: AppColors.mutedText,
                              fontSize: 12,
                            ),
                          ),
                        ),
                        const Expanded(
                          child: Divider(color: AppColors.dividerLine),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _GoogleButton(),
                        SizedBox(width: 28),
                        _FacebookButton(),
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
}

class _AuthInputField extends StatelessWidget {
  const _AuthInputField({
    required this.controller,
    this.keyboardType,
    this.obscureText = false,
    this.hintText,
    this.onChanged,
    this.suffixIcon,
  });

  final TextEditingController controller;
  final TextInputType? keyboardType;
  final bool obscureText;
  final String? hintText;
  final ValueChanged<String>? onChanged;
  final Widget? suffixIcon;

  @override
  Widget build(BuildContext context) {
    final borderRadius = BorderRadius.circular(10);
    final hintPaint = Paint()
      ..color = AppColors.mutedText.withValues(alpha: 0.7)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 1.2);
    return TextField(
      controller: controller,
      onChanged: onChanged,
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

class _GoogleButton extends StatelessWidget {
  const _GoogleButton();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 42,
      height: 42,
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: AppColors.heading.withValues(alpha: 0.08),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Center(
        child: ShaderMask(
          shaderCallback: (bounds) {
            return const LinearGradient(
              colors: [
                Color(0xFFEA4335),
                Color(0xFFFBBC05),
                Color(0xFF34A853),
                Color(0xFF4285F4),
              ],
            ).createShader(bounds);
          },
          child: const Text(
            'G',
            style: TextStyle(
              color: Colors.white,
              fontSize: 28,
              fontWeight: FontWeight.w800,
              height: 1,
            ),
          ),
        ),
      ),
    );
  }
}

class _FacebookButton extends StatelessWidget {
  const _FacebookButton();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 42,
      height: 42,
      decoration: const BoxDecoration(
        color: AppColors.facebookBlue,
        shape: BoxShape.circle,
      ),
      child: const Icon(Icons.facebook_rounded, color: Colors.white, size: 26),
    );
  }
}
