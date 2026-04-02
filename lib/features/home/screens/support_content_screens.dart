import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/app_buttons.dart';
import '../controllers/message_center_controller.dart';
import '../controllers/profile_controller.dart';
import '../repositories/support_repository.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return _ContentScaffold(
      title: 'Privacy Policy',
      sections: _privacySections,
    );
  }
}

class TermsConditionsScreen extends StatelessWidget {
  const TermsConditionsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return _ContentScaffold(
      title: 'Terms and Conditions',
      sections: _termsSections,
    );
  }
}

class SupportRequestScreen extends StatefulWidget {
  const SupportRequestScreen({super.key});

  @override
  State<SupportRequestScreen> createState() => _SupportRequestScreenState();
}

class _SupportRequestScreenState extends State<SupportRequestScreen> {
  final ProfileController _profileController = Get.find<ProfileController>();
  final MessageCenterController _messageCenterController =
      Get.find<MessageCenterController>();
  final SupportRepository _supportRepository = Get.find<SupportRepository>();

  final TextEditingController _subjectController = TextEditingController();
  final TextEditingController _messageController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  String _selectedTopic = _supportTopics.first;
  bool _isSubmitting = false;
  bool _showValidation = false;

  @override
  void dispose() {
    _subjectController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  String? _validateSubject(String? value) {
    final text = value?.trim() ?? '';
    if (text.isEmpty) {
      return 'Subject is required.';
    }

    if (text.length < 4) {
      return 'Please add a little more detail to the subject.';
    }

    return null;
  }

  String? _validateMessage(String? value) {
    final text = value?.trim() ?? '';
    if (text.isEmpty) {
      return 'Message is required.';
    }

    if (text.length < 10) {
      return 'Please add a little more detail about the issue.';
    }

    return null;
  }

  Future<void> _submitRequest() async {
    if (_isSubmitting) {
      return;
    }

    setState(() {
      _showValidation = true;
    });

    final isValid = _formKey.currentState?.validate() ?? false;
    if (!isValid) {
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      final request = await _supportRepository.submitRequest(
        topic: _selectedTopic,
        subject: _subjectController.text.trim(),
        message: _messageController.text.trim(),
        email: _profileController.email,
      );

      await _messageCenterController.addNotification(
        title: 'Support request sent',
        message:
            'Ticket ${request.id} for $_selectedTopic has been submitted successfully.',
        type: NotificationType.message,
      );

      if (!mounted) {
        return;
      }

      Get.back();
      Get.snackbar(
        'Support Request Sent',
        'Our team will contact you soon.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.white,
        colorText: AppColors.heading,
        margin: const EdgeInsets.all(14),
      );
    } catch (error) {
      if (!mounted) {
        return;
      }

      Get.snackbar(
        'Support Request Failed',
        error.toString(),
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.white,
        colorText: AppColors.heading,
        margin: const EdgeInsets.all(14),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: Colors.white,
      bottomNavigationBar: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          child: AppPrimaryButton(
            label: 'Send Request',
            onPressed: _isSubmitting ? null : _submitRequest,
            isLoading: _isSubmitting,
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 110),
          child: Form(
            key: _formKey,
            autovalidateMode: _showValidation
                ? AutovalidateMode.onUserInteraction
                : AutovalidateMode.disabled,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const _ContentHeader(title: 'Email Support'),
                const SizedBox(height: 26),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF5F7FF),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'We usually reply within 24 hours',
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: AppColors.heading,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        _profileController.email,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: AppColors.mutedText,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 22),
                Text(
                  'Topic',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: AppColors.mutedText,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  initialValue: _selectedTopic,
                  decoration: _inputDecoration(),
                  items: _supportTopics.map((topic) {
                    return DropdownMenuItem(value: topic, child: Text(topic));
                  }).toList(),
                  onChanged: (value) {
                    if (value == null) {
                      return;
                    }

                    setState(() {
                      _selectedTopic = value;
                    });
                  },
                ),
                const SizedBox(height: 16),
                Text(
                  'Subject',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: AppColors.mutedText,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _subjectController,
                  validator: _validateSubject,
                  decoration: _inputDecoration(hintText: 'Short issue title'),
                ),
                const SizedBox(height: 16),
                Text(
                  'Message',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: AppColors.mutedText,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _messageController,
                  minLines: 5,
                  maxLines: 7,
                  validator: _validateMessage,
                  decoration: _inputDecoration(
                    hintText: 'Please explain your issue in detail',
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  InputDecoration _inputDecoration({String? hintText}) {
    return InputDecoration(
      hintText: hintText,
      filled: true,
      fillColor: const Color(0xFFF8F9FF),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: BorderSide.none,
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    );
  }
}

class _ContentScaffold extends StatelessWidget {
  const _ContentScaffold({required this.title, required this.sections});

  final String title;
  final List<({String title, String body})> sections;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _ContentHeader(title: title),
              const SizedBox(height: 26),
              ...sections.map(
                (section) => Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8F9FF),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          section.title,
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(
                                color: AppColors.heading,
                                fontWeight: FontWeight.w800,
                              ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          section.body,
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(
                                color: AppColors.mutedText,
                                height: 1.55,
                              ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ContentHeader extends StatelessWidget {
  const _ContentHeader({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        InkWell(
          onTap: Get.back,
          borderRadius: BorderRadius.circular(16),
          child: const Padding(
            padding: EdgeInsets.all(4),
            child: Icon(
              Icons.arrow_back_ios_new_rounded,
              color: AppColors.heading,
              size: 18,
            ),
          ),
        ),
        Expanded(
          child: Center(
            child: Text(
              title,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: AppColors.heading,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ),
        const SizedBox(width: 26),
      ],
    );
  }
}

const List<String> _supportTopics = [
  'Payments',
  'Account Access',
  'Course Playback',
  'Progress Sync',
  'Other',
];

const List<({String title, String body})> _privacySections = [
  (
    title: 'Information We Collect',
    body:
        'We collect your profile details, learning activity, purchases, and account preferences so we can personalize your learning experience and keep your progress synced.',
  ),
  (
    title: 'How We Use Your Data',
    body:
        'Your information is used to manage your account, unlock purchased courses, show progress, send notifications, and improve support responses inside the app.',
  ),
  (
    title: 'Sharing and Security',
    body:
        'We do not share personal data unnecessarily. Sensitive account activity like password changes and purchases should be protected with secure server-side authentication and encryption.',
  ),
];

const List<({String title, String body})> _termsSections = [
  (
    title: 'Account Responsibility',
    body:
        'You are responsible for maintaining accurate account information and keeping your login credentials secure. Activity performed through your account is treated as your own.',
  ),
  (
    title: 'Courses and Purchases',
    body:
        'Purchased courses unlock according to the payment status returned by the backend. Preview lessons may remain available for free while premium content requires a successful transaction.',
  ),
  (
    title: 'Usage Rules',
    body:
        'You may use the app and its content for personal learning. Unauthorized copying, redistribution, or misuse of course materials should be restricted by backend access rules.',
  ),
];
