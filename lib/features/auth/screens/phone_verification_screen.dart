import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../app/routes/app_routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/app_buttons.dart';
import '../controllers/auth_session_controller.dart';

class PhoneVerificationScreen extends StatefulWidget {
  const PhoneVerificationScreen({super.key});

  @override
  State<PhoneVerificationScreen> createState() =>
      _PhoneVerificationScreenState();
}

class _PhoneVerificationScreenState extends State<PhoneVerificationScreen> {
  final AuthSessionController _authSessionController =
      Get.find<AuthSessionController>();
  final TextEditingController _phoneController = TextEditingController();
  final List<TextEditingController> _otpControllers = List.generate(
    4,
    (_) => TextEditingController(),
  );

  int _stepIndex = 0;
  int _otpIndex = 0;

  bool get _canContinueToOtp => _phoneController.text.trim().isNotEmpty;

  bool get _canVerifyOtp {
    return _otpControllers.every(
      (controller) => controller.text.trim().isNotEmpty,
    );
  }

  @override
  void dispose() {
    _phoneController.dispose();
    for (final controller in _otpControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  void _goBack() {
    if (_stepIndex > 0) {
      setState(() {
        _stepIndex -= 1;
      });
      return;
    }
    Get.back();
  }

  void _goToOtp() {
    if (!_canContinueToOtp) {
      return;
    }
    setState(() {
      _stepIndex = 1;
    });
  }

  void _goToSuccess() {
    if (!_canVerifyOtp) {
      return;
    }
    setState(() {
      _stepIndex = 2;
    });
  }

  Future<void> _finishSignUp() async {
    await _authSessionController.completeRegistration();
    Get.offAllNamed(AppRoutes.home);
  }

  void _appendPhoneDigit(String digit) {
    if (digit.isEmpty) {
      return;
    }
    final newText = _phoneController.text + digit;
    _phoneController.value = _phoneController.value.copyWith(
      text: newText,
      selection: TextSelection.collapsed(offset: newText.length),
    );
  }

  void _removePhoneDigit() {
    if (_phoneController.text.isEmpty) {
      return;
    }
    final newText = _phoneController.text.substring(
      0,
      _phoneController.text.length - 1,
    );
    _phoneController.value = _phoneController.value.copyWith(
      text: newText,
      selection: TextSelection.collapsed(offset: newText.length),
    );
  }

  void _appendOtpDigit(String digit) {
    if (digit.isEmpty || _otpIndex >= _otpControllers.length) {
      return;
    }
    _otpControllers[_otpIndex].text = digit;
    setState(() {
      _otpIndex += 1;
    });
  }

  void _removeOtpDigit() {
    if (_otpIndex <= 0) {
      return;
    }
    setState(() {
      _otpIndex -= 1;
      _otpControllers[_otpIndex].clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(22, 18, 22, 18),
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 220),
            child: _stepIndex == 0
                ? _PhoneStep(
                    key: const ValueKey('phone-step'),
                    onBack: _goBack,
                    controller: _phoneController,
                    onContinue: _canContinueToOtp ? _goToOtp : null,
                    onPhoneChanged: (_) => setState(() {}),
                    onKeyTap: _appendPhoneDigit,
                    onBackspace: _removePhoneDigit,
                  )
                : _stepIndex == 1
                ? _OtpStep(
                    key: const ValueKey('otp-step'),
                    onBack: _goBack,
                    otpControllers: _otpControllers,
                    onVerify: _canVerifyOtp ? _goToSuccess : null,
                    onKeyTap: _appendOtpDigit,
                    onBackspace: _removeOtpDigit,
                  )
                : _SuccessStep(
                    key: const ValueKey('success-step'),
                    onDone: _finishSignUp,
                  ),
          ),
        ),
      ),
    );
  }
}

class _PhoneStep extends StatelessWidget {
  const _PhoneStep({
    super.key,
    required this.onBack,
    required this.controller,
    required this.onContinue,
    required this.onPhoneChanged,
    required this.onKeyTap,
    required this.onBackspace,
  });

  final VoidCallback onBack;
  final TextEditingController controller;
  final VoidCallback? onContinue;
  final ValueChanged<String> onPhoneChanged;
  final ValueChanged<String> onKeyTap;
  final VoidCallback onBackspace;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _StepHeader(title: 'Continue with Phone', onBack: onBack),
          const SizedBox(height: 28),
          Center(
            child: Container(
              width: 120,
              height: 120,
              decoration: const BoxDecoration(
                color: AppColors.softPanel,
                shape: BoxShape.circle,
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Icon(
                    Icons.phone_iphone,
                    size: 54,
                    color: AppColors.primary.withValues(alpha: 0.9),
                  ),
                  Positioned(
                    right: 10,
                    top: 20,
                    child: Container(
                      width: 18,
                      height: 18,
                      decoration: const BoxDecoration(
                        color: AppColors.primary,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 22),
          Center(
            child: Text(
              'Enter your phone number',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: AppColors.mutedText,
                fontSize: 13,
              ),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: controller,
                  onChanged: onPhoneChanged,
                  keyboardType: TextInputType.phone,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: AppColors.inputText,
                    fontSize: 14,
                  ),
                  decoration: InputDecoration(
                    isDense: true,
                    hintText: 'Phone number',
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 14,
                    ),
                    filled: true,
                    fillColor: Colors.white,
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(
                        color: AppColors.inputBorder,
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: AppColors.primary),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              SizedBox(
                width: 128,
                height: 46,
                child: AppPrimaryButton(
                  label: 'Continue',
                  onPressed: onContinue,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          _NumericKeypad(onKeyTap: onKeyTap, onBackspace: onBackspace),
        ],
      ),
    );
  }
}

class _OtpStep extends StatelessWidget {
  const _OtpStep({
    super.key,
    required this.onBack,
    required this.otpControllers,
    required this.onVerify,
    required this.onKeyTap,
    required this.onBackspace,
  });

  final VoidCallback onBack;
  final List<TextEditingController> otpControllers;
  final VoidCallback? onVerify;
  final ValueChanged<String> onKeyTap;
  final VoidCallback onBackspace;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _StepHeader(title: 'Verify Phone', onBack: onBack, closeIcon: true),
          const SizedBox(height: 26),
          Text(
            'Code is sent to your phone number',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: AppColors.mutedText,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(otpControllers.length, (index) {
              return Padding(
                padding: EdgeInsets.only(right: index == 3 ? 0 : 12),
                child: SizedBox(
                  width: 52,
                  child: TextField(
                    controller: otpControllers[index],
                    readOnly: true,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: AppColors.heading,
                      fontWeight: FontWeight.w700,
                    ),
                    decoration: InputDecoration(
                      counterText: '',
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(vertical: 14),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(
                          color: AppColors.inputBorder,
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: AppColors.primary),
                      ),
                    ),
                  ),
                ),
              );
            }),
          ),
          const SizedBox(height: 22),
          SizedBox(
            width: double.infinity,
            child: AppPrimaryButton(
              label: 'Verify and Create Account',
              onPressed: onVerify,
            ),
          ),
          const SizedBox(height: 22),
          _NumericKeypad(onKeyTap: onKeyTap, onBackspace: onBackspace),
        ],
      ),
    );
  }
}

class _SuccessStep extends StatelessWidget {
  const _SuccessStep({super.key, required this.onDone});

  final VoidCallback onDone;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Container(
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
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 62,
              height: 62,
              decoration: const BoxDecoration(
                color: AppColors.primary,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.check, color: Colors.white, size: 32),
            ),
            const SizedBox(height: 16),
            Text(
              'Success',
              style: theme.textTheme.titleLarge?.copyWith(
                color: AppColors.heading,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Congratulations, you have completed your registration!',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodySmall?.copyWith(
                color: AppColors.mutedText,
                fontSize: 12,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 18),
            SizedBox(
              width: double.infinity,
              child: AppPrimaryButton(label: 'Done', onPressed: onDone),
            ),
          ],
        ),
      ),
    );
  }
}

class _StepHeader extends StatelessWidget {
  const _StepHeader({
    required this.title,
    required this.onBack,
    this.closeIcon = false,
  });

  final String title;
  final VoidCallback onBack;
  final bool closeIcon;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        IconButton(
          onPressed: onBack,
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(),
          icon: Icon(
            closeIcon ? Icons.close : Icons.arrow_back_ios_new_rounded,
            size: 18,
            color: AppColors.heading,
          ),
        ),
        const SizedBox(width: 10),
        Text(
          title,
          style: theme.textTheme.titleMedium?.copyWith(
            color: AppColors.heading,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

class _NumericKeypad extends StatelessWidget {
  const _NumericKeypad({required this.onKeyTap, required this.onBackspace});

  final ValueChanged<String> onKeyTap;
  final VoidCallback onBackspace;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final keys = ['1', '2', '3', '4', '5', '6', '7', '8', '9', '', '0', 'back'];

    return GridView.builder(
      primary: false,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: keys.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        mainAxisSpacing: 10,
        crossAxisSpacing: 10,
        childAspectRatio: 2.1,
      ),
      itemBuilder: (context, index) {
        final key = keys[index];
        if (key.isEmpty) {
          return const SizedBox.shrink();
        }
        if (key == 'back') {
          return _KeyButton(
            onTap: onBackspace,
            child: const Icon(
              Icons.backspace_outlined,
              size: 20,
              color: AppColors.heading,
            ),
          );
        }
        return _KeyButton(
          onTap: () => onKeyTap(key),
          child: Text(
            key,
            style: theme.textTheme.titleMedium?.copyWith(
              color: AppColors.heading,
              fontWeight: FontWeight.w600,
            ),
          ),
        );
      },
    );
  }
}

class _KeyButton extends StatelessWidget {
  const _KeyButton({required this.onTap, required this.child});

  final VoidCallback onTap;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Center(child: child),
      ),
    );
  }
}
