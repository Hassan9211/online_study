import 'dart:io';

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/theme/app_colors.dart';
import '../controllers/profile_controller.dart';

class ProfileAvatar extends StatelessWidget {
  const ProfileAvatar({
    super.key,
    this.size = 44,
    this.onTap,
    this.showEditBadge = false,
    this.backgroundColor = Colors.white,
    this.borderColor,
    this.boxShadow,
    this.innerPadding,
  });

  final double size;
  final VoidCallback? onTap;
  final bool showEditBadge;
  final Color backgroundColor;
  final Color? borderColor;
  final List<BoxShadow>? boxShadow;
  final double? innerPadding;

  @override
  Widget build(BuildContext context) {
    final avatar = GetBuilder<ProfileController>(
      builder: (controller) {
        final effectivePadding = innerPadding ?? (size * 0.08).clamp(2.0, 8.0);

        return SizedBox(
          width: size,
          height: size,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                width: size,
                height: size,
                padding: EdgeInsets.all(effectivePadding),
                decoration: BoxDecoration(
                  color: backgroundColor,
                  shape: BoxShape.circle,
                  border: borderColor == null
                      ? null
                      : Border.all(color: borderColor!),
                  boxShadow: boxShadow,
                ),
                child: _AvatarContent(
                  imagePath: controller.imagePath,
                  initials: controller.initials,
                  avatarSize: size - (effectivePadding * 2),
                ),
              ),
              if (showEditBadge)
                Positioned(
                  right: -2,
                  bottom: -2,
                  child: Container(
                    width: size * 0.28,
                    height: size * 0.28,
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                    child: Icon(
                      Icons.edit_rounded,
                      size: size * 0.13,
                      color: Colors.white,
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );

    if (onTap == null) {
      return avatar;
    }

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: avatar,
      ),
    );
  }
}

class _AvatarContent extends StatelessWidget {
  const _AvatarContent({
    required this.imagePath,
    required this.initials,
    required this.avatarSize,
  });

  final String? imagePath;
  final String initials;
  final double avatarSize;

  @override
  Widget build(BuildContext context) {
    final imageFile = imagePath == null ? null : File(imagePath!);
    final hasImage = imageFile != null && imageFile.existsSync();

    return ClipOval(
      child: hasImage
          ? Image.file(
              imageFile,
              fit: BoxFit.cover,
              width: avatarSize,
              height: avatarSize,
            )
          : Container(
              width: avatarSize,
              height: avatarSize,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFFFFD0D9), Color(0xFF536DFF)],
                ),
              ),
              alignment: Alignment.center,
              child: avatarSize < 30
                  ? const Icon(
                      Icons.person_rounded,
                      color: Colors.white,
                      size: 16,
                    )
                  : Text(
                      initials,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        fontSize: avatarSize * 0.28,
                        letterSpacing: 0.4,
                      ),
                    ),
            ),
    );
  }
}
