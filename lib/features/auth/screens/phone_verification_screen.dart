import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../app/routes/app_routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/app_buttons.dart';
import '../controllers/auth_session_controller.dart';

enum _VerificationChannel { email, phone }

class PhoneVerificationScreen extends StatefulWidget {
  const PhoneVerificationScreen({super.key});

  @override
  State<PhoneVerificationScreen> createState() =>
      _PhoneVerificationScreenState();
}

class _PhoneVerificationScreenState extends State<PhoneVerificationScreen> {
  final AuthSessionController _authSessionController =
      Get.find<AuthSessionController>();
  final TextEditingController _contactController = TextEditingController();
  final List<TextEditingController> _otpControllers = List.generate(
    4,
    (_) => TextEditingController(),
  );

  late final _VerificationChannel _channel;
  late final bool _contactReadOnly;
  int _stepIndex = 0;
  int _otpIndex = 0;
  bool _isSendingOtp = false;
  bool _isVerifyingOtp = false;

  bool get _isEmailFlow => _channel == _VerificationChannel.email;
  bool get _canContinueToOtp => _contactController.text.trim().isNotEmpty;
  String get _contactValue => _contactController.text.trim();
  String get _pendingEmail => _authSessionController.pendingEmail.trim();
  String get _requestEmail => _isEmailFlow ? _contactValue : _pendingEmail;
  String get _requestPhone => _isEmailFlow ? '' : _contactValue;
  String get _verificationTargetLabel {
    final email = _requestEmail.trim();
    final phone = _requestPhone.trim();

    if (email.isNotEmpty && phone.isNotEmpty) {
      return 'Email: $email\nPhone: $phone';
    }
    if (email.isNotEmpty) {
      return email;
    }
    return phone;
  }

  bool get _canVerifyOtp {
    return _otpControllers.every(
      (controller) => controller.text.trim().isNotEmpty,
    );
  }

  @override
  void initState() {
    super.initState();
    final arguments = Get.arguments;
    final requestedChannel = _readArgument(arguments, 'channel').toLowerCase();
    final presetEmail = _readArgument(arguments, 'email').trim();
    final presetPhone = _readArgument(arguments, 'phone').trim();
    final pendingEmail = _authSessionController.pendingEmail.trim();
    final pendingPhone = _authSessionController.pendingPhone.trim();
    final resolvedEmail = presetEmail.isNotEmpty ? presetEmail : pendingEmail;
    final resolvedPhone = presetPhone.isNotEmpty ? presetPhone : pendingPhone;

    if (requestedChannel == 'phone' ||
        (resolvedEmail.isEmpty && resolvedPhone.isNotEmpty)) {
      _channel = _VerificationChannel.phone;
      _contactReadOnly = false;
      _contactController.text = resolvedPhone;
      return;
    }

    _channel = _VerificationChannel.email;
    _contactReadOnly = resolvedEmail.isNotEmpty;
    _contactController.text = resolvedEmail;
  }

  @override
  void dispose() {
    _contactController.dispose();
    for (final controller in _otpControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  void _goBack() {
    if (_isSendingOtp || _isVerifyingOtp) {
      return;
    }

    if (_stepIndex > 0) {
      setState(() {
        _stepIndex -= 1;
        if (_stepIndex == 0) {
          _resetOtpEntry();
        }
      });
      return;
    }
    Get.back();
  }

  Future<void> _goToOtp() async {
    if (!_canContinueToOtp) {
      return;
    }

    setState(() {
      _isSendingOtp = true;
    });

    final didSendOtp = await _authSessionController.sendOtp(
      email: _requestEmail,
      phone: _requestPhone,
    );

    if (!mounted) {
      return;
    }

    setState(() {
      _isSendingOtp = false;
      if (didSendOtp) {
        _resetOtpEntry();
        _stepIndex = 1;
      }
    });

    if (!didSendOtp) {
      Get.snackbar(
        'OTP Send Failed',
        _authSessionController.lastErrorMessage.isEmpty
            ? 'Could not send the verification code.'
            : _authSessionController.lastErrorMessage,
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.white,
        colorText: AppColors.heading,
        margin: const EdgeInsets.all(14),
      );
    }
  }

  Future<void> _goToSuccess() async {
    if (!_canVerifyOtp) {
      return;
    }

    setState(() {
      _isVerifyingOtp = true;
    });

    final didCompleteRegistration =
        await _authSessionController.completeRegistration(
          email: _requestEmail,
          phone: _requestPhone,
          code: _otpControllers.map((controller) => controller.text).join(),
        );

    if (!mounted) {
      return;
    }

    setState(() {
      _isVerifyingOtp = false;
      if (didCompleteRegistration) {
        _stepIndex = 2;
      }
    });

    if (!didCompleteRegistration) {
      Get.snackbar(
        'Verification Failed',
        _authSessionController.lastErrorMessage.isEmpty
            ? 'Could not verify the OTP.'
            : _authSessionController.lastErrorMessage,
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.white,
        colorText: AppColors.heading,
        margin: const EdgeInsets.all(14),
      );
    }
  }

  Future<void> _finishSignUp() async {
    Get.offAllNamed(AppRoutes.home);
  }

  void _appendContactDigit(String digit) {
    if (_isEmailFlow || digit.isEmpty || _isSendingOtp) {
      return;
    }
    final newText = _contactController.text + digit;
    _contactController.value = _contactController.value.copyWith(
      text: newText,
      selection: TextSelection.collapsed(offset: newText.length),
    );
  }

  void _removeContactDigit() {
    if (_isEmailFlow || _contactController.text.isEmpty || _isSendingOtp) {
      return;
    }
    final newText = _contactController.text.substring(
      0,
      _contactController.text.length - 1,
    );
    _contactController.value = _contactController.value.copyWith(
      text: newText,
      selection: TextSelection.collapsed(offset: newText.length),
    );
  }

  void _appendOtpDigit(String digit) {
    if (digit.isEmpty || _otpIndex >= _otpControllers.length || _isVerifyingOtp) {
      return;
    }
    _otpControllers[_otpIndex].text = digit;
    setState(() {
      _otpIndex += 1;
    });
  }

  void _removeOtpDigit() {
    if (_otpIndex <= 0 || _isVerifyingOtp) {
      return;
    }
    setState(() {
      _otpIndex -= 1;
      _otpControllers[_otpIndex].clear();
    });
  }

  void _resetOtpEntry() {
    _otpIndex = 0;
    for (final controller in _otpControllers) {
      controller.clear();
    }
  }

  String _readArgument(dynamic arguments, String key) {
    if (arguments is Map) {
      final value = arguments[key];
      if (value != null) {
        return value.toString();
      }
    }
    return '';
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
                ? _ContactStep(
                    key: ValueKey(
                      _isEmailFlow ? 'email-step' : 'phone-step',
                    ),
                    onBack: _goBack,
                    controller: _contactController,
                    isEmailFlow: _isEmailFlow,
                    isReadOnly: _contactReadOnly,
                    onContinue:
                        _canContinueToOtp && !_isSendingOtp ? _goToOtp : null,
                    isLoading: _isSendingOtp,
                    onContactChanged: (_) => setState(() {}),
                    onKeyTap: _appendContactDigit,
                    onBackspace: _removeContactDigit,
                  )
                : _stepIndex == 1
                ? _OtpStep(
                    key: ValueKey(_isEmailFlow ? 'email-otp-step' : 'otp-step'),
                    onBack: _goBack,
                    isEmailFlow: _isEmailFlow,
                    verificationTargetLabel: _verificationTargetLabel,
                    otpControllers: _otpControllers,
                    onVerify:
                        _canVerifyOtp && !_isVerifyingOtp ? _goToSuccess : null,
                    isLoading: _isVerifyingOtp,
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

class _ContactStep extends StatelessWidget {
  const _ContactStep({
    super.key,
    required this.onBack,
    required this.controller,
    required this.isEmailFlow,
    required this.isReadOnly,
    required this.onContinue,
    required this.isLoading,
    required this.onContactChanged,
    required this.onKeyTap,
    required this.onBackspace,
  });

  final VoidCallback onBack;
  final TextEditingController controller;
  final bool isEmailFlow;
  final bool isReadOnly;
  final VoidCallback? onContinue;
  final bool isLoading;
  final ValueChanged<String> onContactChanged;
  final ValueChanged<String> onKeyTap;
  final VoidCallback onBackspace;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final title = isEmailFlow ? 'Verify Email' : 'Continue with Phone';
    final subtitle = isEmailFlow
        ? 'We will send a 4-digit OTP to your email address.'
        : 'Enter your phone number to continue. We will use your verification details to send the OTP.';
    final hintText = isEmailFlow ? 'Email address' : 'Phone number';
    final icon = isEmailFlow ? Icons.mark_email_read_outlined : Icons.phone_iphone;

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _StepHeader(title: title, onBack: onBack),
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
                    icon,
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
              subtitle,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: AppColors.mutedText,
                fontSize: 13,
              ),
            ),
          ),
          const SizedBox(height: 10),
          LayoutBuilder(
            builder: (context, constraints) {
              final shouldStackFields = constraints.maxWidth < 340;
              final contactField = TextField(
                controller: controller,
                onChanged: onContactChanged,
                readOnly: isReadOnly,
                keyboardType: isEmailFlow
                    ? TextInputType.emailAddress
                    : TextInputType.phone,
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: AppColors.inputText,
                  fontSize: 14,
                ),
                decoration: InputDecoration(
                  isDense: true,
                  hintText: hintText,
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
              );
              final continueButton = SizedBox(
                width: shouldStackFields ? double.infinity : 128,
                height: 46,
                child: AppPrimaryButton(
                  label: 'Continue',
                  onPressed: onContinue,
                  isLoading: isLoading,
                ),
              );

              if (shouldStackFields) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    contactField,
                    const SizedBox(height: 10),
                    continueButton,
                  ],
                );
              }

              return Row(
                children: [
                  Expanded(child: contactField),
                  const SizedBox(width: 10),
                  continueButton,
                ],
              );
            },
          ),
          if (!isEmailFlow) ...[
            const SizedBox(height: 24),
            _NumericKeypad(onKeyTap: onKeyTap, onBackspace: onBackspace),
          ],
        ],
      ),
    );
  }
}

class _OtpStep extends StatelessWidget {
  const _OtpStep({
    super.key,
    required this.onBack,
    required this.isEmailFlow,
    required this.verificationTargetLabel,
    required this.otpControllers,
    required this.onVerify,
    required this.isLoading,
    required this.onKeyTap,
    required this.onBackspace,
  });

  final VoidCallback onBack;
  final bool isEmailFlow;
  final String verificationTargetLabel;
  final List<TextEditingController> otpControllers;
  final VoidCallback? onVerify;
  final bool isLoading;
  final ValueChanged<String> onKeyTap;
  final VoidCallback onBackspace;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _StepHeader(
            title: isEmailFlow ? 'Enter Email OTP' : 'Enter OTP',
            onBack: onBack,
            closeIcon: true,
          ),
          const SizedBox(height: 26),
          Text(
            isEmailFlow
                ? 'Enter the 4-digit code sent to your email.'
                : 'Enter the 4-digit code sent to your verification contact.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: AppColors.mutedText,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.inputBorder),
            ),
            child: Text(
              verificationTargetLabel,
              overflow: TextOverflow.ellipsis,
              maxLines: 2,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: AppColors.heading,
                fontWeight: FontWeight.w600,
              ),
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
              label: 'Verify and Continue',
              onPressed: onVerify,
              isLoading: isLoading,
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
              'Your OTP has been verified and your session is ready.',
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
        Expanded(
          child: Text(
            title,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.titleMedium?.copyWith(
              color: AppColors.heading,
              fontWeight: FontWeight.w700,
            ),
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
