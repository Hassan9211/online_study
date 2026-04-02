import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../app/routes/app_routes.dart';
import '../../../core/theme/app_colors.dart';
import '../controllers/profile_controller.dart';
import '../widgets/profile_avatar.dart';

class AccountScreen extends StatelessWidget {
  const AccountScreen({super.key});

  static const List<({String label, String route})> _menuItems = [
    (label: 'Favourite', route: AppRoutes.favouriteVideos),
    (label: 'Edit Account', route: AppRoutes.editAccount),
    (label: 'Settings and Privacy', route: AppRoutes.settingsPrivacy),
    (label: 'Help', route: AppRoutes.helpCenter),
  ];

  Future<void> _refreshAccount() async {
    await Get.find<ProfileController>().refreshProfile();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      color: Colors.white,
      child: SafeArea(
        child: RefreshIndicator(
          onRefresh: _refreshAccount,
          color: AppColors.primary,
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(
              parent: BouncingScrollPhysics(),
            ),
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
            children: [
              Text(
                'Account',
                style: theme.textTheme.headlineSmall?.copyWith(
                  color: AppColors.heading,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 20),
              Center(
                child: ProfileAvatar(
                  size: 94,
                  showEditBadge: true,
                  onTap: () => Get.toNamed(AppRoutes.editAccount),
                  backgroundColor: const Color(0xFFFFE7EC),
                  innerPadding: 8,
                ),
              ),
              const SizedBox(height: 22),
              ..._menuItems.map(
                (item) => _AccountMenuTile(
                  label: item.label,
                  onTap: () => Get.toNamed(item.route),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AccountMenuTile extends StatelessWidget {
  const _AccountMenuTile({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  label,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: AppColors.heading,
                    fontSize: 18,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              Icon(
                Icons.visibility_off_outlined,
                size: 18,
                color: AppColors.heading.withValues(alpha: 0.84),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
