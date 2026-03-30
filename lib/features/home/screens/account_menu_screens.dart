import 'dart:io';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';

import '../../../app/routes/app_routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/app_buttons.dart';
import '../../auth/controllers/auth_session_controller.dart';
import '../controllers/message_center_controller.dart';
import '../controllers/profile_controller.dart';
import '../controllers/product_design_course_controller.dart';
import '../controllers/settings_controller.dart';
import '../models/product_design_course_data.dart';
import '../widgets/profile_avatar.dart';
import 'message_screen.dart';

class FavouriteVideosScreen extends StatelessWidget {
  const FavouriteVideosScreen({super.key});

  static const List<int> _favouriteIndexes = [0, 1, 5, 7];

  void _openFavourite(
    ProductDesignCourseController controller,
    int lessonIndex,
  ) {
    if (controller.isLessonLocked(lessonIndex)) {
      Get.toNamed(AppRoutes.productDesignCourse);
      return;
    }

    Get.toNamed(
      AppRoutes.productDesignPlayer,
      arguments: {'lessonIndex': lessonIndex},
    );
  }

  @override
  Widget build(BuildContext context) {
    return GetBuilder<ProductDesignCourseController>(
      builder: (controller) {
        return _AccountDetailScaffold(
          title: 'Favourite',
          child: Column(
            children: _favouriteIndexes.map((lessonIndex) {
              final lesson = productDesignLessons[lessonIndex];

              return Padding(
                padding: const EdgeInsets.only(bottom: 14),
                child: _FavouriteVideoTile(
                  title: lesson.title,
                  durationLabel: controller.lessonDurationLabel(lessonIndex),
                  isLocked: controller.isLessonLocked(lessonIndex),
                  onTap: () => _openFavourite(controller, lessonIndex),
                ),
              );
            }).toList(),
          ),
        );
      },
    );
  }
}

class EditAccountScreen extends StatefulWidget {
  const EditAccountScreen({super.key});

  @override
  State<EditAccountScreen> createState() => _EditAccountScreenState();
}

class _EditAccountScreenState extends State<EditAccountScreen> {
  final AuthSessionController _authSessionController =
      Get.find<AuthSessionController>();
  final MessageCenterController _messageCenterController =
      Get.find<MessageCenterController>();
  final ProfileController _profileController = Get.find<ProfileController>();

  late final TextEditingController _nameController;
  late final TextEditingController _emailController;
  late final TextEditingController _phoneController;
  late final TextEditingController _bioController;

  bool _controllersReady = false;

  void _initializeControllers(ProfileController profileController) {
    if (_controllersReady) {
      return;
    }

    _nameController = TextEditingController(text: profileController.name);
    _emailController = TextEditingController(text: profileController.email);
    _phoneController = TextEditingController(text: profileController.phone);
    _bioController = TextEditingController(text: profileController.bio);
    _controllersReady = true;
  }

  @override
  void dispose() {
    if (_controllersReady) {
      _nameController.dispose();
      _emailController.dispose();
      _phoneController.dispose();
      _bioController.dispose();
    }
    super.dispose();
  }

  Future<void> _pickProfileImageFromSource(ImageSource source) async {
    final didPickImage = await _profileController.pickProfileImage(source);
    if (!didPickImage) {
      if (mounted) {
        Get.snackbar(
          'Photo Update Failed',
          _profileController.lastErrorMessage.isEmpty
              ? 'Profile photo update nahi ho saki.'
              : _profileController.lastErrorMessage,
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.white,
          colorText: AppColors.heading,
          margin: const EdgeInsets.all(14),
        );
      }
      return;
    }

    if (!mounted) {
      return;
    }

    Get.snackbar(
      'Profile Photo Updated',
      'Your new profile photo is now showing across the app.',
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: Colors.white,
      colorText: AppColors.heading,
      margin: const EdgeInsets.all(14),
    );
    _messageCenterController.recordProfilePhotoUpdated();
  }

  void _openProfilePhotoActions() {
    final hasProfileImage = _profileController.imagePath != null;

    Get.bottomSheet<void>(
      Container(
        padding: const EdgeInsets.fromLTRB(18, 16, 18, 26),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 44,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.inputBorder,
                  borderRadius: BorderRadius.circular(99),
                ),
              ),
              const SizedBox(height: 18),
              Text(
                'Manage Photo',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: AppColors.heading,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 18),
              if (hasProfileImage) ...[
                _PhotoActionTile(
                  icon: Icons.visibility_outlined,
                  title: 'View Photo',
                  onTap: () {
                    Get.back();
                    _viewProfilePhoto();
                  },
                ),
                const SizedBox(height: 10),
              ],
              _PhotoActionTile(
                icon: Icons.photo_library_outlined,
                title: 'Choose from Gallery',
                onTap: () async {
                  Get.back();
                  await _pickProfileImageFromSource(ImageSource.gallery);
                },
              ),
              const SizedBox(height: 10),
              _PhotoActionTile(
                icon: Icons.camera_alt_outlined,
                title: 'Capture with Camera',
                onTap: () async {
                  Get.back();
                  await _pickProfileImageFromSource(ImageSource.camera);
                },
              ),
            ],
          ),
        ),
      ),
      isScrollControlled: true,
    );
  }

  void _viewProfilePhoto() {
    final imagePath = _profileController.imagePath;
    if (imagePath == null) {
      return;
    }

    Get.to(
      () => _ProfilePhotoViewer(
        imagePath: imagePath,
        title: _profileController.name,
      ),
      transition: Transition.fadeIn,
    );
  }

  Future<void> _saveProfile() async {
    if (!_controllersReady) {
      return;
    }

    final didSaveProfile = await _profileController.updateProfile(
      name: _nameController.text,
      email: _emailController.text,
      phone: _phoneController.text,
      bio: _bioController.text,
    );

    if (!didSaveProfile) {
      Get.snackbar(
        'Profile Update Failed',
        _profileController.lastErrorMessage.isEmpty
            ? 'Profile save nahi ho saka.'
            : _profileController.lastErrorMessage,
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.white,
        colorText: AppColors.heading,
        margin: const EdgeInsets.all(14),
      );
      return;
    }

    await _authSessionController.updateEmail(_emailController.text);

    Get.snackbar(
      'Profile Updated',
      'Your name and profile details now show across the app.',
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: Colors.white,
      colorText: AppColors.heading,
      margin: const EdgeInsets.all(14),
    );
    _messageCenterController.recordProfileUpdated();
  }

  @override
  Widget build(BuildContext context) {
    return GetBuilder<ProfileController>(
      builder: (profileController) {
        if (!profileController.isLoaded && !_controllersReady) {
          return const _AccountDetailScaffold(
            title: 'Edit Account',
            child: Center(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 60),
                child: CircularProgressIndicator(color: AppColors.primary),
              ),
            ),
          );
        }

        _initializeControllers(profileController);

        return _AccountDetailScaffold(
          title: 'Edit Account',
          footer: AppPrimaryButton(
            label: 'Save Changes',
            onPressed: _saveProfile,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 24),
                  child: _EditableProfileHeader(
                    onTap: _openProfilePhotoActions,
                  ),
                ),
              ),
              _ProfileField(label: 'Full name', controller: _nameController),
              const SizedBox(height: 16),
              _ProfileField(
                label: 'Email',
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 16),
              _ProfileField(
                label: 'Phone',
                controller: _phoneController,
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 16),
              _ProfileField(
                label: 'Bio',
                controller: _bioController,
                maxLines: 4,
              ),
            ],
          ),
        );
      },
    );
  }
}

class SettingsPrivacyScreen extends StatefulWidget {
  const SettingsPrivacyScreen({super.key});

  @override
  State<SettingsPrivacyScreen> createState() => _SettingsPrivacyScreenState();
}

class _SettingsPrivacyScreenState extends State<SettingsPrivacyScreen> {
  final AuthSessionController _authSessionController =
      Get.find<AuthSessionController>();
  final SettingsController _settingsController = Get.find<SettingsController>();

  Future<void> _openLogoutDialog() async {
    final shouldLogout = await Get.dialog<bool>(
      AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text('Log Out'),
        content: const Text(
          'Kya aap waqai apne account se log out karna chahte hain?',
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(result: false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Get.back(result: true),
            child: const Text('Log Out'),
          ),
        ],
      ),
    );

    if (shouldLogout != true) {
      return;
    }

    await _authSessionController.logout();
    Get.offAllNamed(AppRoutes.logIn);
  }

  @override
  Widget build(BuildContext context) {
    return GetBuilder<SettingsController>(
      builder: (controller) {
        return _AccountDetailScaffold(
          title: 'Settings and Privacy',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Notifications',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: AppColors.heading,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 10),
              _SettingsSwitchTile(
                label: 'Push Notifications',
                value: controller.pushNotifications,
                onChanged: (value) => _settingsController.updateSettings(
                  pushNotifications: value,
                ),
              ),
              _SettingsSwitchTile(
                label: 'Course Reminders',
                value: controller.courseReminders,
                onChanged: (value) => _settingsController.updateSettings(
                  courseReminders: value,
                ),
              ),
              _SettingsSwitchTile(
                label: 'Download on Wi-Fi only',
                value: controller.wifiDownloadsOnly,
                onChanged: (value) => _settingsController.updateSettings(
                  wifiDownloadsOnly: value,
                ),
              ),
              const SizedBox(height: 18),
              Text(
                'Privacy',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: AppColors.heading,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 10),
              _SettingsSwitchTile(
                label: 'Private Profile',
                value: controller.privateProfile,
                onChanged: (value) => _settingsController.updateSettings(
                  privateProfile: value,
                ),
              ),
              const SizedBox(height: 4),
              _SettingsActionTile(
                label: 'Change Password',
                onTap: () => Get.toNamed(AppRoutes.changePassword),
              ),
              _SettingsActionTile(
                label: 'Privacy Policy',
                onTap: () => Get.toNamed(AppRoutes.privacyPolicy),
              ),
              _SettingsActionTile(
                label: 'Terms and Conditions',
                onTap: () => Get.toNamed(AppRoutes.termsConditions),
              ),
              const SizedBox(height: 20),
              Text(
                'Account',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: AppColors.heading,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 10),
              _SettingsActionTile(
                label: 'Log Out',
                onTap: _openLogoutDialog,
                textColor: const Color(0xFFE15A5A),
                iconColor: const Color(0xFFE15A5A),
                trailingIcon: Icons.logout_rounded,
              ),
            ],
          ),
        );
      },
    );
  }
}

class ChangePasswordScreen extends StatefulWidget {
  const ChangePasswordScreen({super.key});

  @override
  State<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  final AuthSessionController _authSessionController =
      Get.find<AuthSessionController>();
  final MessageCenterController _messageCenterController =
      Get.find<MessageCenterController>();

  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _currentPasswordController =
      TextEditingController();
  final TextEditingController _newPasswordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();

  bool _obscureCurrentPassword = true;
  bool _obscureNewPassword = true;
  bool _obscureConfirmPassword = true;
  bool _showValidation = false;

  String get _accountEmail => _authSessionController.email;

  @override
  void dispose() {
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  String? _validateCurrentPassword(String? value) {
    final password = value?.trim() ?? '';
    if (password.isEmpty) {
      return 'Current password required hai.';
    }

    if (!_authSessionController.isCurrentPasswordValid(password)) {
      return 'Current password sahi nahi hai.';
    }

    return null;
  }

  String? _validateNewPassword(String? value) {
    final password = value?.trim() ?? '';
    if (password.isEmpty) {
      return 'New password required hai.';
    }

    if (password.length < 6) {
      return 'New password kam az kam 6 characters ka ho.';
    }

    if (password == _currentPasswordController.text.trim()) {
      return 'New password current password se different ho.';
    }

    return null;
  }

  String? _validateConfirmPassword(String? value) {
    final password = value?.trim() ?? '';
    if (password.isEmpty) {
      return 'Confirm password required hai.';
    }

    if (password != _newPasswordController.text.trim()) {
      return 'Confirm password new password se match nahi kar raha.';
    }

    return null;
  }

  Future<void> _savePassword() async {
    setState(() {
      _showValidation = true;
    });

    final isValid = _formKey.currentState?.validate() ?? false;
    if (!isValid) {
      return;
    }

    final didUpdatePassword = await _authSessionController.updatePassword(
      currentPassword: _currentPasswordController.text,
      newPassword: _newPasswordController.text,
    );

    if (!didUpdatePassword) {
      Get.snackbar(
        'Password Update Failed',
        _authSessionController.lastErrorMessage.isEmpty
            ? 'Password update nahi ho saka.'
            : _authSessionController.lastErrorMessage,
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.white,
        colorText: AppColors.heading,
        margin: const EdgeInsets.all(14),
      );
      return;
    }

    if (!mounted) {
      return;
    }

    Get.back();
    Get.snackbar(
      'Password Updated',
      'Aap ka password successfully change ho gaya.',
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: Colors.white,
      colorText: AppColors.heading,
      margin: const EdgeInsets.all(14),
    );
    _messageCenterController.recordPasswordChanged();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return _AccountDetailScaffold(
      title: 'Change Password',
      footer: AppPrimaryButton(
        label: 'Save Password',
        onPressed: _savePassword,
      ),
      child: Form(
        key: _formKey,
        autovalidateMode: _showValidation
            ? AutovalidateMode.onUserInteraction
            : AutovalidateMode.disabled,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: const Color(0xFFF4F6FF),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Account Email',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: AppColors.mutedText,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    _accountEmail.isEmpty
                        ? 'No email available'
                        : _accountEmail,
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: AppColors.heading,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 22),
            _PasswordFormField(
              label: 'Current Password',
              controller: _currentPasswordController,
              obscureText: _obscureCurrentPassword,
              validator: _validateCurrentPassword,
              onVisibilityToggle: () {
                setState(() {
                  _obscureCurrentPassword = !_obscureCurrentPassword;
                });
              },
            ),
            const SizedBox(height: 16),
            _PasswordFormField(
              label: 'New Password',
              controller: _newPasswordController,
              obscureText: _obscureNewPassword,
              validator: _validateNewPassword,
              onChanged: (_) {
                if (_showValidation) {
                  setState(() {});
                }
              },
              onVisibilityToggle: () {
                setState(() {
                  _obscureNewPassword = !_obscureNewPassword;
                });
              },
            ),
            const SizedBox(height: 16),
            _PasswordFormField(
              label: 'Confirm Password',
              controller: _confirmPasswordController,
              obscureText: _obscureConfirmPassword,
              validator: _validateConfirmPassword,
              onVisibilityToggle: () {
                setState(() {
                  _obscureConfirmPassword = !_obscureConfirmPassword;
                });
              },
            ),
          ],
        ),
      ),
    );
  }
}

class HelpCenterScreen extends StatelessWidget {
  const HelpCenterScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return _AccountDetailScaffold(
      title: 'Help',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: const Color(0xFFF3F6FF),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Need help with your learning?',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: AppColors.heading,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'We can help with payments, account access, or lesson playback.',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.mutedText,
                    height: 1.45,
                  ),
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: AppPrimaryButton(
                        label: 'Chat Support',
                        onPressed: () =>
                            Get.to(() => const AiGuestChatScreen()),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Get.toNamed(AppRoutes.supportRequest),
                        child: const Text('Email Us'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 22),
          Text(
            'Frequently asked questions',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: AppColors.heading,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 10),
          const _HelpTile(
            title: 'How do I buy a course?',
            answer:
                'Open the course, tap Buy Now, choose your payment method, and complete the password step.',
          ),
          const _HelpTile(
            title: 'Why is a lesson locked?',
            answer:
                'Locked lessons are unlocked after purchase. Preview lessons can still be opened for free.',
          ),
          const _HelpTile(
            title: 'Can I continue where I left off?',
            answer:
                'Yes, your course progress and unlocked lessons stay available after purchase.',
          ),
        ],
      ),
    );
  }
}

class _AccountDetailScaffold extends StatelessWidget {
  const _AccountDetailScaffold({
    required this.title,
    required this.child,
    this.footer,
  });

  final String title;
  final Widget child;
  final Widget? footer;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: Colors.white,
      bottomNavigationBar: footer == null
          ? null
          : SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                child: footer!,
              ),
            ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(16, 14, 16, footer == null ? 24 : 110),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
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
                        style: theme.textTheme.titleLarge?.copyWith(
                          color: AppColors.heading,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 26),
                ],
              ),
              const SizedBox(height: 26),
              child,
            ],
          ),
        ),
      ),
    );
  }
}

class _FavouriteVideoTile extends StatelessWidget {
  const _FavouriteVideoTile({
    required this.title,
    required this.durationLabel,
    required this.isLocked,
    required this.onTap,
  });

  final String title;
  final String durationLabel;
  final bool isLocked;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: const Color(0xFFF8F9FF),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: isLocked
                      ? const Color(0xFFE9ECFF)
                      : AppColors.primary.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(
                  isLocked ? Icons.lock_rounded : Icons.play_arrow_rounded,
                  color: isLocked ? AppColors.primary : AppColors.primary,
                  size: 28,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            title,
                            style: theme.textTheme.titleMedium?.copyWith(
                              color: AppColors.heading,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        const Icon(
                          Icons.star_rounded,
                          color: Color(0xFFFFC83D),
                          size: 20,
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      durationLabel,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: AppColors.mutedText,
                        fontWeight: FontWeight.w600,
                      ),
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

class _EditableProfileHeader extends StatelessWidget {
  const _EditableProfileHeader({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GetBuilder<ProfileController>(
      builder: (profileController) {
        return Column(
          children: [
            ProfileAvatar(
              size: 92,
              onTap: onTap,
              showEditBadge: true,
              backgroundColor: const Color(0xFFFFE7EC),
              innerPadding: 8,
            ),
            const SizedBox(height: 12),
            Text(
              profileController.name,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: AppColors.heading,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Tap the photo to view, capture, or choose an image',
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: AppColors.mutedText),
            ),
          ],
        );
      },
    );
  }
}

class _ProfileField extends StatelessWidget {
  const _ProfileField({
    required this.label,
    required this.controller,
    this.keyboardType,
    this.maxLines = 1,
  });

  final String label;
  final TextEditingController controller;
  final TextInputType? keyboardType;
  final int maxLines;

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
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          maxLines: maxLines,
          decoration: InputDecoration(
            filled: true,
            fillColor: const Color(0xFFF7F8FD),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide.none,
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

class _SettingsSwitchTile extends StatelessWidget {
  const _SettingsSwitchTile({
    required this.label,
    required this.value,
    required this.onChanged,
  });

  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F9FF),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: AppColors.heading,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Switch(
            value: value,
            activeThumbColor: Colors.white,
            activeTrackColor: AppColors.primary,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}

class _SettingsActionTile extends StatelessWidget {
  const _SettingsActionTile({
    required this.label,
    required this.onTap,
    this.textColor,
    this.iconColor,
    this.trailingIcon = Icons.arrow_forward_ios_rounded,
  });

  final String label;
  final VoidCallback onTap;
  final Color? textColor;
  final Color? iconColor;
  final IconData trailingIcon;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 14),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  label,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: textColor ?? AppColors.heading,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Icon(
                trailingIcon,
                size: 16,
                color: iconColor ?? AppColors.mutedText,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PasswordFormField extends StatelessWidget {
  const _PasswordFormField({
    required this.label,
    required this.controller,
    required this.obscureText,
    required this.onVisibilityToggle,
    required this.validator,
    this.onChanged,
  });

  final String label;
  final TextEditingController controller;
  final bool obscureText;
  final VoidCallback onVisibilityToggle;
  final String? Function(String?) validator;
  final ValueChanged<String>? onChanged;

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
          obscureText: obscureText,
          validator: validator,
          onChanged: onChanged,
          decoration: InputDecoration(
            filled: true,
            fillColor: const Color(0xFFF7F8FD),
            suffixIcon: IconButton(
              onPressed: onVisibilityToggle,
              icon: Icon(
                obscureText
                    ? Icons.visibility_off_outlined
                    : Icons.visibility_outlined,
                color: AppColors.heading,
              ),
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide.none,
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

class _PhotoActionTile extends StatelessWidget {
  const _PhotoActionTile({
    required this.icon,
    required this.title,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFFF8F9FF),
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: AppColors.primary),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: AppColors.heading,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const Icon(
                Icons.arrow_forward_ios_rounded,
                size: 16,
                color: AppColors.mutedText,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProfilePhotoViewer extends StatelessWidget {
  const _ProfilePhotoViewer({required this.imagePath, required this.title});

  final String imagePath;
  final String title;

  @override
  Widget build(BuildContext context) {
    final imageFile = File(imagePath);

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Stack(
          children: [
            Center(
              child: InteractiveViewer(
                minScale: 0.8,
                maxScale: 4,
                child: imageFile.existsSync()
                    ? Image.file(imageFile, fit: BoxFit.contain)
                    : const Text(
                        'Photo not available',
                        style: TextStyle(color: Colors.white),
                      ),
              ),
            ),
            Positioned(
              top: 12,
              left: 12,
              right: 12,
              child: Row(
                children: [
                  InkWell(
                    onTap: Get.back,
                    borderRadius: BorderRadius.circular(18),
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.35),
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: const Icon(
                        Icons.arrow_back_ios_new_rounded,
                        color: Colors.white,
                        size: 18,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HelpTile extends StatelessWidget {
  const _HelpTile({required this.title, required this.answer});

  final String title;
  final String answer;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F9FF),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              color: AppColors.heading,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            answer,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppColors.mutedText,
              height: 1.45,
            ),
          ),
        ],
      ),
    );
  }
}
