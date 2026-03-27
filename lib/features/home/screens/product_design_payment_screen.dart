import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../app/routes/app_routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/app_buttons.dart';
import '../controllers/message_center_controller.dart';
import '../controllers/product_design_course_controller.dart';
import '../models/product_design_course_data.dart';

enum _PaymentStep { method, password, success }

class ProductDesignPaymentScreen extends StatefulWidget {
  const ProductDesignPaymentScreen({super.key});

  @override
  State<ProductDesignPaymentScreen> createState() =>
      _ProductDesignPaymentScreenState();
}

class _ProductDesignPaymentScreenState
    extends State<ProductDesignPaymentScreen> {
  static const List<_PaymentCardData> _cards = [
    _PaymentCardData(
      maskedNumber: '•••• •••• •••• 4829',
      label: 'My card',
      startColor: Color(0xFF3D5AFE),
      endColor: Color(0xFFE9E4FF),
      blobOneColor: Color(0xFF56D2FF),
      blobTwoColor: Color(0xFFE47BFF),
    ),
    _PaymentCardData(
      maskedNumber: '•••• •••• •••• 2641',
      label: 'Work card',
      startColor: Color(0xFF4259F4),
      endColor: Color(0xFFDBC8FF),
      blobOneColor: Color(0xFF7DE8D0),
      blobTwoColor: Color(0xFFFF98C7),
    ),
    _PaymentCardData(
      maskedNumber: '•••• •••• •••• 3156',
      label: 'Family card',
      startColor: Color(0xFF3D4BFF),
      endColor: Color(0xFFF0D9FF),
      blobOneColor: Color(0xFF6CD7FF),
      blobTwoColor: Color(0xFFFFB36B),
    ),
  ];

  ProductDesignCourseController get _courseController =>
      Get.find<ProductDesignCourseController>();
  MessageCenterController get _messageCenterController =>
      Get.find<MessageCenterController>();

  _PaymentStep _step = _PaymentStep.method;
  int _selectedCardIndex = 0;
  String _paymentPin = '';
  bool _isProcessing = false;

  void _openPasswordStep() {
    setState(() {
      _step = _PaymentStep.password;
      _paymentPin = '';
      _isProcessing = false;
    });
  }

  void _selectCard(int index) {
    setState(() {
      _selectedCardIndex = index;
    });
  }

  Future<void> _appendDigit(String digit) async {
    if (_paymentPin.length >= 6 || _isProcessing) {
      return;
    }

    setState(() {
      _paymentPin += digit;
    });

    if (_paymentPin.length == 6) {
      await _completePurchase();
    }
  }

  void _removeDigit() {
    if (_paymentPin.isEmpty || _isProcessing) {
      return;
    }

    setState(() {
      _paymentPin = _paymentPin.substring(0, _paymentPin.length - 1);
    });
  }

  Future<void> _completePurchase() async {
    if (_isProcessing) {
      return;
    }

    setState(() {
      _isProcessing = true;
    });

    await Future<void>.delayed(const Duration(milliseconds: 320));

    if (!_courseController.isPurchased) {
      _courseController.purchaseCourse();
      _messageCenterController.recordPurchaseSuccess();
    }

    if (!mounted) {
      return;
    }

    setState(() {
      _step = _PaymentStep.success;
      _isProcessing = false;
    });
  }

  void _finishFlow() {
    if (Get.previousRoute == AppRoutes.productDesignCourse) {
      Get.offNamed(
        AppRoutes.productDesignPlayer,
        arguments: {'lessonIndex': 0},
      );
      return;
    }

    Get.back();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 260),
        child: switch (_step) {
          _PaymentStep.method => _PaymentMethodStep(
            key: const ValueKey('payment-method'),
            cards: _cards,
            selectedCardIndex: _selectedCardIndex,
            onSelectCard: _selectCard,
            onPayNow: _openPasswordStep,
          ),
          _PaymentStep.password => _PaymentPasswordStep(
            key: const ValueKey('payment-password'),
            card: _cards[_selectedCardIndex],
            pinLength: _paymentPin.length,
            isProcessing: _isProcessing,
            onClose: Get.back,
            onDigitPressed: _appendDigit,
            onRemovePressed: _removeDigit,
          ),
          _PaymentStep.success => _PaymentSuccessStep(
            key: const ValueKey('payment-success'),
            onPressed: _finishFlow,
          ),
        },
      ),
    );
  }
}

class _PaymentMethodStep extends StatelessWidget {
  const _PaymentMethodStep({
    super.key,
    required this.cards,
    required this.selectedCardIndex,
    required this.onSelectCard,
    required this.onPayNow,
  });

  final List<_PaymentCardData> cards;
  final int selectedCardIndex;
  final ValueChanged<int> onSelectCard;
  final VoidCallback onPayNow;

  @override
  Widget build(BuildContext context) {
    final card = cards[selectedCardIndex];

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 18),
        child: Column(
          children: [
            _PaymentHeader(title: 'Payment Method', onClose: Get.back),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _PaymentCardPreview(card: card),
                  const SizedBox(height: 26),
                  Text(
                    card.label,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: AppColors.heading,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    productDesignCoursePriceLabel,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      color: AppColors.heading,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 22),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(cards.length, (index) {
                      final isSelected = index == selectedCardIndex;
                      return GestureDetector(
                        onTap: () => onSelectCard(index),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 180),
                          width: isSelected ? 18 : 6,
                          height: 6,
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? AppColors.primary
                                : AppColors.indicatorInactive,
                            borderRadius: BorderRadius.circular(999),
                          ),
                        ),
                      );
                    }),
                  ),
                ],
              ),
            ),
            AppPrimaryButton(label: 'Pay Now', onPressed: onPayNow),
          ],
        ),
      ),
    );
  }
}

class _PaymentPasswordStep extends StatelessWidget {
  const _PaymentPasswordStep({
    super.key,
    required this.card,
    required this.pinLength,
    required this.isProcessing,
    required this.onClose,
    required this.onDigitPressed,
    required this.onRemovePressed,
  });

  final _PaymentCardData card;
  final int pinLength;
  final bool isProcessing;
  final VoidCallback onClose;
  final ValueChanged<String> onDigitPressed;
  final VoidCallback onRemovePressed;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: const Color(0xFFF5F6FC),
      child: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: _PaymentHeader(title: 'Payment Method', onClose: onClose),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 18, 16, 0),
              child: Stack(
                children: [
                  _PaymentCardPreview(
                    card: card,
                    showAmount: true,
                    amountLabel: productDesignCoursePriceLabel,
                  ),
                  Positioned.fill(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.25),
                        borderRadius: BorderRadius.circular(24),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Container(
                width: double.infinity,
                margin: const EdgeInsets.only(top: 22),
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 18),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(34)),
                ),
                child: Column(
                  children: [
                    Text(
                      'Payment Password',
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(
                            color: AppColors.heading,
                            fontWeight: FontWeight.w800,
                            fontSize: 18,
                          ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Please enter the payment password',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.mutedText,
                      ),
                    ),
                    const SizedBox(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(6, (index) {
                        final isFilled = index < pinLength;
                        return Container(
                          width: 30,
                          height: 34,
                          margin: const EdgeInsets.symmetric(horizontal: 5),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: isFilled
                                  ? AppColors.primary.withValues(alpha: 0.25)
                                  : AppColors.inputBorder,
                            ),
                          ),
                          alignment: Alignment.center,
                          child: AnimatedOpacity(
                            duration: const Duration(milliseconds: 120),
                            opacity: isFilled ? 1 : 0,
                            child: Container(
                              width: 8,
                              height: 8,
                              decoration: const BoxDecoration(
                                color: AppColors.heading,
                                shape: BoxShape.circle,
                              ),
                            ),
                          ),
                        );
                      }),
                    ),
                    const SizedBox(height: 16),
                    if (isProcessing)
                      const Padding(
                        padding: EdgeInsets.only(bottom: 6),
                        child: SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.2,
                            color: AppColors.primary,
                          ),
                        ),
                      )
                    else
                      const SizedBox(height: 24),
                    Expanded(
                      child: _PaymentKeypad(
                        onDigitPressed: onDigitPressed,
                        onRemovePressed: onRemovePressed,
                      ),
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

class _PaymentSuccessStep extends StatelessWidget {
  const _PaymentSuccessStep({super.key, required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 24, 16, 18),
        child: Column(
          children: [
            const Spacer(flex: 4),
            const _SuccessBadge(),
            const SizedBox(height: 22),
            Text(
              'Successful purchase!',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: AppColors.heading,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'You can now unlock all lessons in $productDesignCourseTitle.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppColors.mutedText,
                height: 1.45,
              ),
            ),
            const Spacer(flex: 5),
            AppPrimaryButton(label: 'Start learning', onPressed: onPressed),
          ],
        ),
      ),
    );
  }
}

class _PaymentHeader extends StatelessWidget {
  const _PaymentHeader({required this.title, required this.onClose});

  final String title;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        IconButton(
          onPressed: onClose,
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(),
          icon: const Icon(Icons.close_rounded, color: AppColors.heading),
        ),
        Expanded(
          child: Center(
            child: Text(
              title,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: AppColors.heading,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ),
        const SizedBox(width: 24),
      ],
    );
  }
}

class _PaymentCardPreview extends StatelessWidget {
  const _PaymentCardPreview({
    required this.card,
    this.showAmount = false,
    this.amountLabel,
  });

  final _PaymentCardData card;
  final bool showAmount;
  final String? amountLabel;

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 1.72,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          gradient: LinearGradient(
            colors: [card.startColor, card.endColor],
            begin: Alignment.centerLeft,
            end: Alignment.topRight,
          ),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: Stack(
            children: [
              Positioned(
                left: -30,
                top: -26,
                child: Container(
                  width: 136,
                  height: 136,
                  decoration: BoxDecoration(
                    color: card.blobOneColor,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
              Positioned(
                right: -16,
                top: -34,
                child: Container(
                  width: 122,
                  height: 122,
                  decoration: BoxDecoration(
                    color: card.blobTwoColor,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
              Positioned(
                right: 16,
                top: 16,
                child: Container(
                  width: 26,
                  height: 18,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.92),
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Spacer(),
                    Text(
                      card.maskedNumber,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.1,
                      ),
                    ),
                    const SizedBox(height: 8),
                    if (showAmount && amountLabel != null) ...[
                      Text(
                        amountLabel!,
                        style: Theme.of(context).textTheme.headlineSmall
                            ?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w800,
                            ),
                      ),
                      Text(
                        'Balance',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.white.withValues(alpha: 0.86),
                        ),
                      ),
                    ] else ...[
                      Text(
                        'Balance',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.white.withValues(alpha: 0.86),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PaymentKeypad extends StatelessWidget {
  const _PaymentKeypad({
    required this.onDigitPressed,
    required this.onRemovePressed,
  });

  final ValueChanged<String> onDigitPressed;
  final VoidCallback onRemovePressed;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        Row(
          children: [
            Expanded(
              child: _KeypadButton(
                label: '1',
                onTap: () => onDigitPressed('1'),
              ),
            ),
            Expanded(
              child: _KeypadButton(
                label: '2',
                onTap: () => onDigitPressed('2'),
              ),
            ),
            Expanded(
              child: _KeypadButton(
                label: '3',
                onTap: () => onDigitPressed('3'),
              ),
            ),
          ],
        ),
        Row(
          children: [
            Expanded(
              child: _KeypadButton(
                label: '4',
                onTap: () => onDigitPressed('4'),
              ),
            ),
            Expanded(
              child: _KeypadButton(
                label: '5',
                onTap: () => onDigitPressed('5'),
              ),
            ),
            Expanded(
              child: _KeypadButton(
                label: '6',
                onTap: () => onDigitPressed('6'),
              ),
            ),
          ],
        ),
        Row(
          children: [
            Expanded(
              child: _KeypadButton(
                label: '7',
                onTap: () => onDigitPressed('7'),
              ),
            ),
            Expanded(
              child: _KeypadButton(
                label: '8',
                onTap: () => onDigitPressed('8'),
              ),
            ),
            Expanded(
              child: _KeypadButton(
                label: '9',
                onTap: () => onDigitPressed('9'),
              ),
            ),
          ],
        ),
        Row(
          children: [
            const Expanded(child: SizedBox()),
            Expanded(
              child: _KeypadButton(
                label: '0',
                onTap: () => onDigitPressed('0'),
              ),
            ),
            Expanded(
              child: _KeypadButton(
                icon: Icons.backspace_outlined,
                onTap: onRemovePressed,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _KeypadButton extends StatelessWidget {
  const _KeypadButton({this.label, this.icon, required this.onTap});

  final String? label;
  final IconData? icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final child = label != null
        ? Text(
            label!,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: AppColors.heading,
              fontWeight: FontWeight.w700,
            ),
          )
        : Icon(icon, color: AppColors.heading);

    return SizedBox(
      height: 58,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(18),
          child: Center(child: child),
        ),
      ),
    );
  }
}

class _SuccessBadge extends StatelessWidget {
  const _SuccessBadge();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 118,
      height: 118,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Positioned(
            left: 10,
            top: 24,
            child: Container(
              width: 8,
              height: 8,
              decoration: const BoxDecoration(
                color: AppColors.warmAccent,
                shape: BoxShape.circle,
              ),
            ),
          ),
          Positioned(
            right: 18,
            top: 14,
            child: Container(
              width: 10,
              height: 10,
              decoration: const BoxDecoration(
                color: Color(0xFFD3D7FF),
                shape: BoxShape.circle,
              ),
            ),
          ),
          Positioned(
            left: 24,
            bottom: 22,
            child: Container(
              width: 8,
              height: 8,
              decoration: const BoxDecoration(
                color: Color(0xFFF7C9F2),
                shape: BoxShape.circle,
              ),
            ),
          ),
          Positioned(
            right: 16,
            bottom: 30,
            child: Container(
              width: 8,
              height: 8,
              decoration: const BoxDecoration(
                color: Color(0xFFE7D8FF),
                shape: BoxShape.circle,
              ),
            ),
          ),
          Container(
            width: 82,
            height: 82,
            decoration: const BoxDecoration(
              color: AppColors.primary,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.check_rounded,
              color: Colors.white,
              size: 38,
            ),
          ),
        ],
      ),
    );
  }
}

class _PaymentCardData {
  const _PaymentCardData({
    required this.maskedNumber,
    required this.label,
    required this.startColor,
    required this.endColor,
    required this.blobOneColor,
    required this.blobTwoColor,
  });

  final String maskedNumber;
  final String label;
  final Color startColor;
  final Color endColor;
  final Color blobOneColor;
  final Color blobTwoColor;
}
