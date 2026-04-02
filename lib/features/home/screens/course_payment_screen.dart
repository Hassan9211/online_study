import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import '../../../app/routes/app_routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/app_buttons.dart';
import '../controllers/course_purchase_controller.dart';
import '../models/course_detail_record.dart';
import '../models/payment_checkout_request.dart';
import '../models/payment_method_record.dart';

enum _CoursePaymentStep { method, details, password, success }

class CoursePaymentScreen extends StatefulWidget {
  const CoursePaymentScreen({super.key});

  @override
  State<CoursePaymentScreen> createState() => _CoursePaymentScreenState();
}

class _CoursePaymentScreenState extends State<CoursePaymentScreen> {
  static const List<({
    Color startColor,
    Color endColor,
    Color blobOneColor,
    Color blobTwoColor,
  })> _palettes = [
    (
      startColor: Color(0xFF3D5AFE),
      endColor: Color(0xFFE9E4FF),
      blobOneColor: Color(0xFF56D2FF),
      blobTwoColor: Color(0xFFE47BFF),
    ),
    (
      startColor: Color(0xFF4259F4),
      endColor: Color(0xFFDBC8FF),
      blobOneColor: Color(0xFF7DE8D0),
      blobTwoColor: Color(0xFFFF98C7),
    ),
    (
      startColor: Color(0xFF3D4BFF),
      endColor: Color(0xFFF0D9FF),
      blobOneColor: Color(0xFF6CD7FF),
      blobTwoColor: Color(0xFFFFB36B),
    ),
  ];

  final CoursePurchaseController _purchaseController =
      Get.find<CoursePurchaseController>();
  final GlobalKey<FormState> _paymentDetailsFormKey = GlobalKey<FormState>();
  final TextEditingController _cardholderNameController =
      TextEditingController();
  final TextEditingController _cardNumberController = TextEditingController();
  final TextEditingController _expiryController = TextEditingController();
  final TextEditingController _cvvController = TextEditingController();

  late final String _courseId;
  late final String _courseTitle;
  late final double _amountValue;
  late final String _amountLabel;
  late final String _currencyCode;
  CourseDetailRecord? _detail;

  _CoursePaymentStep _step = _CoursePaymentStep.method;
  int _selectedCardIndex = 0;
  String _paymentPin = '';
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    final arguments = Get.arguments as Map? ?? <String, dynamic>{};
    _courseId = arguments['courseId']?.toString().trim() ?? '';
    _courseTitle = arguments['courseTitle']?.toString().trim() ?? 'Course';
    _amountValue = (arguments['amountValue'] as num?)?.toDouble() ?? 0;
    _amountLabel = arguments['amountLabel']?.toString().trim().isNotEmpty == true
        ? arguments['amountLabel'].toString()
        : '\$${_amountValue.toStringAsFixed(2)}';
    _currencyCode =
        arguments['currencyCode']?.toString().trim().isNotEmpty == true
        ? arguments['currencyCode'].toString()
        : 'USD';
    final detail = arguments['detail'];
    if (detail is CourseDetailRecord) {
      _detail = detail;
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      _purchaseController.loadPaymentMethods();
    });
  }

  @override
  void dispose() {
    _cardholderNameController.dispose();
    _cardNumberController.dispose();
    _expiryController.dispose();
    _cvvController.dispose();
    super.dispose();
  }

  void _openPaymentDetailsStep(List<_CoursePaymentCardData> cards) {
    if (cards.isEmpty) {
      return;
    }
    setState(() {
      _step = _CoursePaymentStep.details;
    });
  }

  void _goBackFromDetails() {
    if (_isProcessing) {
      return;
    }
    setState(() {
      _step = _CoursePaymentStep.method;
    });
  }

  void _goBackFromPassword() {
    if (_isProcessing) {
      return;
    }
    setState(() {
      _paymentPin = '';
      _step = _CoursePaymentStep.details;
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

  Future<void> _submitPaymentDetails(
    List<_CoursePaymentCardData> cards,
  ) async {
    if (_isProcessing || cards.isEmpty) {
      return;
    }

    final isValid = _paymentDetailsFormKey.currentState?.validate() ?? false;
    if (!isValid) {
      return;
    }

    final expiry = _parseExpiryDate(_expiryController.text);
    if (expiry == null) {
      return;
    }

    final selectedCard = cards[_selectedCardIndex];
    setState(() {
      _isProcessing = true;
    });

    final didStartCheckout = await _purchaseController.startCheckout(
      courseId: _courseId,
      request: PaymentCheckoutRequest(
        paymentMethodId: selectedCard.id,
        paymentMethodLabel: selectedCard.label,
        cardholderName: _cardholderNameController.text.trim(),
        cardNumber: _cardNumberController.text,
        expiryMonth: expiry.month,
        expiryYear: expiry.year,
        cvv: _cvvController.text,
        amountValue: _amountValue,
        amountLabel: _amountLabel,
        currencyCode: _currencyCode,
      ),
    );

    if (!mounted) {
      return;
    }

    if (!didStartCheckout) {
      setState(() {
        _isProcessing = false;
      });
      Get.snackbar(
        'Checkout Failed',
        _purchaseController.lastErrorMessage.isEmpty
            ? 'Could not send the payment details to the backend.'
            : _purchaseController.lastErrorMessage,
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.white,
        colorText: AppColors.heading,
        margin: const EdgeInsets.all(14),
      );
      return;
    }

    setState(() {
      _paymentPin = '';
      _step = _CoursePaymentStep.password;
      _isProcessing = false;
    });
  }

  Future<void> _completePurchase() async {
    if (_isProcessing) {
      return;
    }

    setState(() {
      _isProcessing = true;
    });

    final didConfirm = await _purchaseController.confirmPurchase(
      courseId: _courseId,
      courseTitle: _courseTitle,
      pin: _paymentPin,
    );

    if (!mounted) {
      return;
    }

    if (!didConfirm) {
      setState(() {
        _paymentPin = '';
        _isProcessing = false;
      });
      Get.snackbar(
        'Payment Failed',
        _purchaseController.lastErrorMessage.isEmpty
            ? 'Could not verify the payment.'
            : _purchaseController.lastErrorMessage,
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.white,
        colorText: AppColors.heading,
        margin: const EdgeInsets.all(14),
      );
      return;
    }

    setState(() {
      _step = _CoursePaymentStep.success;
      _isProcessing = false;
    });
  }

  String? _validateCardholderName(String? value) {
    final trimmedValue = value?.trim() ?? '';
    if (trimmedValue.isEmpty) {
      return 'Cardholder name is required.';
    }
    if (trimmedValue.length < 2) {
      return 'Enter the full cardholder name.';
    }
    return null;
  }

  String? _validateCardNumber(String? value) {
    final normalized = (value ?? '').replaceAll(RegExp(r'\D'), '');
    if (normalized.isEmpty) {
      return 'Card number is required.';
    }
    if (normalized.length < 13 || normalized.length > 19) {
      return 'Enter a valid card number.';
    }
    return null;
  }

  String? _validateExpiry(String? value) {
    if ((value ?? '').trim().isEmpty) {
      return 'Expiry date is required.';
    }
    if (_parseExpiryDate(value) == null) {
      return 'Enter the expiry date in MM/YY format.';
    }
    return null;
  }

  String? _validateCvv(String? value) {
    final normalized = (value ?? '').replaceAll(RegExp(r'\D'), '');
    if (normalized.isEmpty) {
      return 'CVV is required.';
    }
    if (normalized.length < 3 || normalized.length > 4) {
      return 'Enter a valid CVV.';
    }
    return null;
  }

  _ParsedExpiryDate? _parseExpiryDate(String? rawValue) {
    final digits = (rawValue ?? '').replaceAll(RegExp(r'\D'), '');
    if (digits.length != 4) {
      return null;
    }

    final month = digits.substring(0, 2);
    final year = digits.substring(2);
    final monthValue = int.tryParse(month);
    if (monthValue == null || monthValue < 1 || monthValue > 12) {
      return null;
    }

    return _ParsedExpiryDate(month: month, year: year);
  }

  void _finishFlow() {
    final detail = _detail;
    if (detail != null && detail.lessons.isNotEmpty) {
      Get.offNamed(
        AppRoutes.coursePlayer,
        arguments: <String, dynamic>{
          'detail': detail.copyWith(isPurchased: true),
          'lessonIndex': 0,
        },
      );
      return;
    }

    if (Get.previousRoute == AppRoutes.courseDetail) {
      Get.back();
      return;
    }

    if (Get.key.currentState?.canPop() ?? false) {
      Get.back();
      return;
    }

    Get.offAllNamed(AppRoutes.home);
  }

  List<_CoursePaymentCardData> _buildCards(List<PaymentMethodRecord> methods) {
    return methods.asMap().entries.map((entry) {
      final palette = _palettes[entry.key % _palettes.length];
      final method = entry.value;
      return _CoursePaymentCardData(
        id: method.id,
        maskedNumber: method.maskedNumber,
        label: method.label,
        startColor: palette.startColor,
        endColor: palette.endColor,
        blobOneColor: palette.blobOneColor,
        blobTwoColor: palette.blobTwoColor,
      );
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return GetBuilder<CoursePurchaseController>(
      builder: (controller) {
        final cards = _buildCards(controller.paymentMethods);
        final safeSelectedIndex = cards.isEmpty
            ? 0
            : (_selectedCardIndex >= cards.length ? 0 : _selectedCardIndex);

        if (_selectedCardIndex != safeSelectedIndex) {
          _selectedCardIndex = safeSelectedIndex;
        }

        return Scaffold(
          backgroundColor: Colors.white,
          body: AnimatedSwitcher(
            duration: const Duration(milliseconds: 260),
            child: switch (_step) {
              _CoursePaymentStep.method => cards.isEmpty &&
                      controller.isLoadingPaymentMethods
                  ? _LoadingPaymentMethodStep(
                      key: const ValueKey('course-payment-loading'),
                      message: controller.lastErrorMessage,
                    )
                  : cards.isEmpty
                  ? _EmptyPaymentMethodStep(
                      key: const ValueKey('course-payment-empty'),
                      message: controller.lastErrorMessage,
                      onRetry: () => controller.loadPaymentMethods(
                        forceRefresh: true,
                      ),
                    )
                  : _CoursePaymentMethodStep(
                      key: const ValueKey('course-payment-method'),
                      cards: cards,
                      selectedCardIndex: safeSelectedIndex,
                      amountLabel: _amountLabel,
                      isBusy: _isProcessing,
                      helperMessage: controller.lastErrorMessage,
                      onSelectCard: _selectCard,
                      onPayNow: () => _openPaymentDetailsStep(cards),
                    ),
              _CoursePaymentStep.details => cards.isEmpty
                  ? _EmptyPaymentMethodStep(
                      key: const ValueKey('course-payment-empty-details'),
                      message: controller.lastErrorMessage,
                      onRetry: () => controller.loadPaymentMethods(
                        forceRefresh: true,
                      ),
                    )
                  : _CoursePaymentDetailsStep(
                      key: const ValueKey('course-payment-details'),
                      card: cards[safeSelectedIndex],
                      courseTitle: _courseTitle,
                      amountValue: _amountValue,
                      amountLabel: _amountLabel,
                      currencyCode: _currencyCode,
                      formKey: _paymentDetailsFormKey,
                      isBusy: _isProcessing,
                      helperMessage: controller.lastErrorMessage,
                      cardholderNameController: _cardholderNameController,
                      cardNumberController: _cardNumberController,
                      expiryController: _expiryController,
                      cvvController: _cvvController,
                      onBack: _goBackFromDetails,
                      onSubmit: () => _submitPaymentDetails(cards),
                      cardholderValidator: _validateCardholderName,
                      cardNumberValidator: _validateCardNumber,
                      expiryValidator: _validateExpiry,
                      cvvValidator: _validateCvv,
                    ),
              _CoursePaymentStep.password => cards.isEmpty
                  ? _EmptyPaymentMethodStep(
                      key: const ValueKey('course-payment-empty-password'),
                      message: controller.lastErrorMessage,
                      onRetry: () => controller.loadPaymentMethods(
                        forceRefresh: true,
                      ),
                    )
                  : _CoursePaymentPasswordStep(
                      key: const ValueKey('course-payment-password'),
                      card: cards[safeSelectedIndex],
                      amountLabel: _amountLabel,
                      pinLength: _paymentPin.length,
                      isProcessing: _isProcessing,
                      onClose: _goBackFromPassword,
                      onDigitPressed: _appendDigit,
                      onRemovePressed: _removeDigit,
                    ),
              _CoursePaymentStep.success => _CoursePaymentSuccessStep(
                  key: const ValueKey('course-payment-success'),
                  courseTitle: _courseTitle,
                  onPressed: _finishFlow,
                ),
            },
          ),
        );
      },
    );
  }
}

class _LoadingPaymentMethodStep extends StatelessWidget {
  const _LoadingPaymentMethodStep({
    super.key,
    required this.message,
  });

  final String message;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(color: AppColors.primary),
              const SizedBox(height: 18),
              Text(
                'Loading payment methods...',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: AppColors.heading,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                message.isEmpty
                    ? 'Fetching cards from the backend. Checkout will start after that.'
                    : message,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.mutedText,
                  height: 1.45,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptyPaymentMethodStep extends StatelessWidget {
  const _EmptyPaymentMethodStep({
    super.key,
    required this.message,
    required this.onRetry,
  });

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 18),
        child: Column(
          children: [
            _CoursePaymentHeader(title: 'Payment Method', onClose: Get.back),
            const Spacer(),
            Text(
              'No payment methods available right now.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: AppColors.heading,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message.isEmpty ? 'Please try again in a moment.' : message,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppColors.mutedText,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 18),
            SizedBox(
              width: double.infinity,
              child: AppPrimaryButton(
                label: 'Retry',
                onPressed: onRetry,
              ),
            ),
            const Spacer(),
          ],
        ),
      ),
    );
  }
}

class _CoursePaymentMethodStep extends StatelessWidget {
  const _CoursePaymentMethodStep({
    super.key,
    required this.cards,
    required this.selectedCardIndex,
    required this.amountLabel,
    required this.isBusy,
    required this.helperMessage,
    required this.onSelectCard,
    required this.onPayNow,
  });

  final List<_CoursePaymentCardData> cards;
  final int selectedCardIndex;
  final String amountLabel;
  final bool isBusy;
  final String helperMessage;
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
            _CoursePaymentHeader(title: 'Payment Method', onClose: Get.back),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _CoursePaymentCardPreview(card: card),
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
                    amountLabel,
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
                  if (helperMessage.isNotEmpty) ...[
                    const SizedBox(height: 18),
                    Text(
                      helperMessage,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.mutedText,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            AppPrimaryButton(
              label: 'Pay Now',
              onPressed: isBusy ? null : onPayNow,
              isLoading: isBusy,
            ),
          ],
        ),
      ),
    );
  }
}

class _CoursePaymentDetailsStep extends StatelessWidget {
  const _CoursePaymentDetailsStep({
    super.key,
    required this.card,
    required this.courseTitle,
    required this.amountValue,
    required this.amountLabel,
    required this.currencyCode,
    required this.formKey,
    required this.isBusy,
    required this.helperMessage,
    required this.cardholderNameController,
    required this.cardNumberController,
    required this.expiryController,
    required this.cvvController,
    required this.onBack,
    required this.onSubmit,
    required this.cardholderValidator,
    required this.cardNumberValidator,
    required this.expiryValidator,
    required this.cvvValidator,
  });

  final _CoursePaymentCardData card;
  final String courseTitle;
  final double amountValue;
  final String amountLabel;
  final String currencyCode;
  final GlobalKey<FormState> formKey;
  final bool isBusy;
  final String helperMessage;
  final TextEditingController cardholderNameController;
  final TextEditingController cardNumberController;
  final TextEditingController expiryController;
  final TextEditingController cvvController;
  final VoidCallback onBack;
  final VoidCallback onSubmit;
  final String? Function(String?) cardholderValidator;
  final String? Function(String?) cardNumberValidator;
  final String? Function(String?) expiryValidator;
  final String? Function(String?) cvvValidator;

  @override
  Widget build(BuildContext context) {
    final previewControllers = Listenable.merge(<Listenable>[
      cardholderNameController,
      cardNumberController,
      expiryController,
    ]);

    return SafeArea(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: _CoursePaymentHeader(
              title: 'Payment Details',
              onClose: onBack,
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 18, 16, 18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF7F8FD),
                      borderRadius: BorderRadius.circular(28),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Wrap(
                          spacing: 10,
                          runSpacing: 10,
                          children: const [
                            _CoursePaymentMetaChip(
                              icon: Icons.auto_awesome_rounded,
                              label: 'Auto-selected USD total',
                            ),
                            _CoursePaymentMetaChip(
                              icon: Icons.cloud_done_outlined,
                              label: 'Ready for backend',
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        AnimatedBuilder(
                          animation: previewControllers,
                          builder: (context, child) {
                            return _CoursePaymentCardPreview(
                              card: card,
                              showAmount: true,
                              amountLabel: amountLabel,
                              amountCaption: 'Course total',
                              cardNumber: cardNumberController.text,
                              cardholderName: cardholderNameController.text,
                              expiryLabel: expiryController.text,
                              brandLabel: _resolveCardBrand(
                                cardNumberController.text,
                                fallbackLabel: card.label,
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 22),
                  Text(
                    'Card checkout',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: AppColors.heading,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '$amountLabel is auto-selected from $courseTitle. Enter the card number, expiry date, and CVV, then we will push the checkout request to POST /payments/checkout.',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.mutedText,
                      height: 1.45,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: _CoursePaymentInfoCard(
                          icon: Icons.attach_money_rounded,
                          title: 'Course total',
                          value: '$currencyCode ${amountValue.toStringAsFixed(2)}',
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _CoursePaymentInfoCard(
                          icon: Icons.credit_card_rounded,
                          title: 'Method',
                          value: card.label,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  Form(
                    key: formKey,
                    child: Column(
                      children: [
                        _CoursePaymentTextField(
                          label: 'Name on Card',
                          controller: cardholderNameController,
                          hintText: 'Hassan Raza',
                          prefixIcon: Icons.person_outline_rounded,
                          textInputAction: TextInputAction.next,
                          textCapitalization: TextCapitalization.words,
                          validator: cardholderValidator,
                        ),
                        const SizedBox(height: 14),
                        _CoursePaymentTextField(
                          label: 'Card Number',
                          controller: cardNumberController,
                          hintText: '4242 4242 4242 4242',
                          prefixIcon: Icons.credit_card_rounded,
                          keyboardType: TextInputType.number,
                          textInputAction: TextInputAction.next,
                          validator: cardNumberValidator,
                          inputFormatters: <TextInputFormatter>[
                            FilteringTextInputFormatter.digitsOnly,
                            LengthLimitingTextInputFormatter(19),
                            _CardNumberFormatter(),
                          ],
                        ),
                        const SizedBox(height: 14),
                        Row(
                          children: [
                            Expanded(
                              child: _CoursePaymentTextField(
                                label: 'Expiry (MM/YY)',
                                controller: expiryController,
                                hintText: '08/29',
                                prefixIcon: Icons.date_range_outlined,
                                keyboardType: TextInputType.number,
                                textInputAction: TextInputAction.next,
                                validator: expiryValidator,
                                inputFormatters: <TextInputFormatter>[
                                  FilteringTextInputFormatter.digitsOnly,
                                  LengthLimitingTextInputFormatter(4),
                                  _ExpiryDateFormatter(),
                                ],
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _CoursePaymentTextField(
                                label: 'CVV',
                                controller: cvvController,
                                hintText: '123',
                                prefixIcon: Icons.lock_outline_rounded,
                                keyboardType: TextInputType.number,
                                textInputAction: TextInputAction.done,
                                validator: cvvValidator,
                                obscureText: true,
                                inputFormatters: <TextInputFormatter>[
                                  FilteringTextInputFormatter.digitsOnly,
                                  LengthLimitingTextInputFormatter(4),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  if (helperMessage.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    Text(
                      helperMessage,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.mutedText,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 18),
            child: AppPrimaryButton(
              label: 'Send checkout request',
              onPressed: isBusy ? null : onSubmit,
              isLoading: isBusy,
            ),
          ),
        ],
      ),
    );
  }
}

class _CoursePaymentPasswordStep extends StatelessWidget {
  const _CoursePaymentPasswordStep({
    super.key,
    required this.card,
    required this.amountLabel,
    required this.pinLength,
    required this.isProcessing,
    required this.onClose,
    required this.onDigitPressed,
    required this.onRemovePressed,
  });

  final _CoursePaymentCardData card;
  final String amountLabel;
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
              child: _CoursePaymentHeader(
                title: 'Payment Method',
                onClose: onClose,
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 18, 16, 0),
              child: Stack(
                children: [
                  _CoursePaymentCardPreview(
                    card: card,
                    showAmount: true,
                    amountLabel: amountLabel,
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
                      'Payment Approval',
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(
                            color: AppColors.heading,
                            fontWeight: FontWeight.w800,
                            fontSize: 18,
                          ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'The backend approved your checkout request. Enter the 6-digit payment password to finish.',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.mutedText,
                      ),
                      textAlign: TextAlign.center,
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
                      child: _CoursePaymentKeypad(
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

class _CoursePaymentSuccessStep extends StatelessWidget {
  const _CoursePaymentSuccessStep({
    super.key,
    required this.courseTitle,
    required this.onPressed,
  });

  final String courseTitle;
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
              'You can now unlock all lessons in $courseTitle.',
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

class _CoursePaymentHeader extends StatelessWidget {
  const _CoursePaymentHeader({required this.title, required this.onClose});

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

class _CoursePaymentCardPreview extends StatelessWidget {
  const _CoursePaymentCardPreview({
    required this.card,
    this.showAmount = false,
    this.amountLabel,
    this.amountCaption,
    this.cardNumber,
    this.cardholderName,
    this.expiryLabel,
    this.brandLabel,
  });

  final _CoursePaymentCardData card;
  final bool showAmount;
  final String? amountLabel;
  final String? amountCaption;
  final String? cardNumber;
  final String? cardholderName;
  final String? expiryLabel;
  final String? brandLabel;

  @override
  Widget build(BuildContext context) {
    final displayCardNumber = _formatCardPreviewNumber(
      cardNumber,
      fallback: card.maskedNumber,
    );
    final displayCardholderName = _formatCardholderName(cardholderName);
    final displayExpiryLabel = _formatExpiryLabel(expiryLabel);
    final displayBrandLabel = _formatBrandLabel(
      brandLabel,
      fallback: card.label,
    );

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
                left: 18,
                top: 18,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.18),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.auto_mode_rounded,
                        size: 14,
                        color: Colors.white,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        card.label,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Positioned(
                right: 18,
                top: 18,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.92),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    displayBrandLabel,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.heading,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.4,
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Spacer(flex: 3),
                    if (showAmount && amountLabel != null) ...[
                      Text(
                        amountCaption ?? 'Balance',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.white.withValues(alpha: 0.82),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        amountLabel!,
                        style: Theme.of(context).textTheme.headlineSmall
                            ?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w800,
                            ),
                      ),
                      const SizedBox(height: 16),
                    ] else ...[
                      const SizedBox(height: 28),
                    ],
                    Text(
                      displayCardNumber,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.3,
                      ),
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Expanded(
                          child: _CoursePaymentCardCaption(
                            label: 'CARD HOLDER',
                            value: displayCardholderName,
                          ),
                        ),
                        const SizedBox(width: 16),
                        _CoursePaymentCardCaption(
                          label: 'EXPIRES',
                          value: displayExpiryLabel,
                        ),
                      ],
                    ),
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

class _CoursePaymentKeypad extends StatelessWidget {
  const _CoursePaymentKeypad({
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
            Expanded(child: _KeypadButton(label: '1', onTap: () => onDigitPressed('1'))),
            Expanded(child: _KeypadButton(label: '2', onTap: () => onDigitPressed('2'))),
            Expanded(child: _KeypadButton(label: '3', onTap: () => onDigitPressed('3'))),
          ],
        ),
        Row(
          children: [
            Expanded(child: _KeypadButton(label: '4', onTap: () => onDigitPressed('4'))),
            Expanded(child: _KeypadButton(label: '5', onTap: () => onDigitPressed('5'))),
            Expanded(child: _KeypadButton(label: '6', onTap: () => onDigitPressed('6'))),
          ],
        ),
        Row(
          children: [
            Expanded(child: _KeypadButton(label: '7', onTap: () => onDigitPressed('7'))),
            Expanded(child: _KeypadButton(label: '8', onTap: () => onDigitPressed('8'))),
            Expanded(child: _KeypadButton(label: '9', onTap: () => onDigitPressed('9'))),
          ],
        ),
        Row(
          children: [
            const Expanded(child: SizedBox()),
            Expanded(child: _KeypadButton(label: '0', onTap: () => onDigitPressed('0'))),
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

class _CoursePaymentTextField extends StatelessWidget {
  const _CoursePaymentTextField({
    required this.label,
    required this.controller,
    required this.validator,
    this.keyboardType,
    this.textInputAction,
    this.inputFormatters,
    this.obscureText = false,
    this.hintText,
    this.prefixIcon,
    this.textCapitalization = TextCapitalization.none,
  });

  final String label;
  final TextEditingController controller;
  final String? Function(String?) validator;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final List<TextInputFormatter>? inputFormatters;
  final bool obscureText;
  final String? hintText;
  final IconData? prefixIcon;
  final TextCapitalization textCapitalization;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: AppColors.mutedText,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          validator: validator,
          keyboardType: keyboardType,
          textInputAction: textInputAction,
          inputFormatters: inputFormatters,
          obscureText: obscureText,
          textCapitalization: textCapitalization,
          decoration: InputDecoration(
            filled: true,
            fillColor: const Color(0xFFF7F8FD),
            hintText: hintText,
            prefixIcon: prefixIcon == null
                ? null
                : Icon(prefixIcon, color: AppColors.mutedText),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(
                color: AppColors.primary.withValues(alpha: 0.18),
              ),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 14,
            ),
          ),
        ),
      ],
    );
  }
}

class _SuccessBadge extends StatelessWidget {
  const _SuccessBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
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
    );
  }
}

class _ParsedExpiryDate {
  const _ParsedExpiryDate({
    required this.month,
    required this.year,
  });

  final String month;
  final String year;
}

class _CoursePaymentMetaChip extends StatelessWidget {
  const _CoursePaymentMetaChip({
    required this.icon,
    required this.label,
  });

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: AppColors.primary),
          const SizedBox(width: 8),
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: AppColors.heading,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _CoursePaymentInfoCard extends StatelessWidget {
  const _CoursePaymentInfoCard({
    required this.icon,
    required this.title,
    required this.value,
  });

  final IconData icon;
  final String title;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF7F8FD),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            alignment: Alignment.center,
            child: Icon(icon, color: AppColors.primary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.mutedText,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  value,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.heading,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CoursePaymentCardCaption extends StatelessWidget {
  const _CoursePaymentCardCaption({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Colors.white.withValues(alpha: 0.7),
            fontWeight: FontWeight.w500,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.4,
          ),
        ),
      ],
    );
  }
}

class _CardNumberFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final digits = newValue.text.replaceAll(RegExp(r'\D'), '');
    final buffer = StringBuffer();

    for (var index = 0; index < digits.length; index++) {
      if (index > 0 && index % 4 == 0) {
        buffer.write(' ');
      }
      buffer.write(digits[index]);
    }

    final formatted = buffer.toString();
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}

class _ExpiryDateFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final digits = newValue.text.replaceAll(RegExp(r'\D'), '');
    final formatted = digits.length <= 2
        ? digits
        : '${digits.substring(0, 2)}/${digits.substring(2)}';

    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}

class _CoursePaymentCardData {
  const _CoursePaymentCardData({
    required this.id,
    required this.maskedNumber,
    required this.label,
    required this.startColor,
    required this.endColor,
    required this.blobOneColor,
    required this.blobTwoColor,
  });

  final String id;
  final String maskedNumber;
  final String label;
  final Color startColor;
  final Color endColor;
  final Color blobOneColor;
  final Color blobTwoColor;
}

String _formatCardPreviewNumber(String? rawValue, {required String fallback}) {
  final digits = (rawValue ?? '').replaceAll(RegExp(r'\D'), '');
  if (digits.isEmpty) {
    return fallback;
  }

  final buffer = StringBuffer();
  for (var index = 0; index < digits.length; index++) {
    if (index > 0 && index % 4 == 0) {
      buffer.write(' ');
    }
    buffer.write(digits[index]);
  }
  return buffer.toString();
}

String _formatCardholderName(String? rawValue) {
  final normalized = (rawValue ?? '').trim();
  if (normalized.isEmpty) {
    return 'CARD HOLDER';
  }
  return normalized.toUpperCase();
}

String _formatExpiryLabel(String? rawValue) {
  final digits = (rawValue ?? '').replaceAll(RegExp(r'\D'), '');
  if (digits.isEmpty) {
    return 'MM/YY';
  }
  if (digits.length <= 2) {
    return digits;
  }
  return '${digits.substring(0, 2)}/${digits.substring(2)}';
}

String _resolveCardBrand(String? rawValue, {required String fallbackLabel}) {
  final digits = (rawValue ?? '').replaceAll(RegExp(r'\D'), '');
  if (digits.startsWith('4')) {
    return 'VISA';
  }
  if (RegExp(r'^(5[1-5]|2[2-7])').hasMatch(digits)) {
    return 'MASTERCARD';
  }
  if (digits.startsWith('34') || digits.startsWith('37')) {
    return 'AMEX';
  }
  if (digits.startsWith('6')) {
    return 'DISCOVER';
  }
  return _formatBrandLabel(fallbackLabel, fallback: 'CARD');
}

String _formatBrandLabel(String? rawValue, {required String fallback}) {
  final normalized = (rawValue ?? '').trim();
  if (normalized.isEmpty) {
    return fallback;
  }

  final words = normalized
      .split(RegExp(r'\s+'))
      .where((word) => word.isNotEmpty && word.toLowerCase() != 'card')
      .toList();
  final label = words.isEmpty ? normalized : words.first;
  return label.toUpperCase();
}
