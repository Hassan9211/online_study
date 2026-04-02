import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import 'app_buttons.dart';

class NoInternetScreen extends StatelessWidget {
  const NoInternetScreen({
    super.key,
    required this.onRetry,
    this.isChecking = false,
  });

  final VoidCallback onRetry;
  final bool isChecking;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 14, 14, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Padding(
                padding: EdgeInsets.only(left: 2),
                child: Icon(
                  Icons.visibility_off_outlined,
                  color: AppColors.heading,
                  size: 20,
                ),
              ),
              Expanded(
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 320),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const _NoInternetIllustration(),
                        const SizedBox(height: 24),
                        Text(
                          'No Network!',
                          style: theme.textTheme.headlineSmall?.copyWith(
                            color: AppColors.heading,
                            fontWeight: FontWeight.w800,
                            fontSize: 28,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Please check your internet connection and try again',
                          textAlign: TextAlign.center,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: AppColors.mutedText,
                            height: 1.5,
                          ),
                        ),
                        const SizedBox(height: 26),
                        SizedBox(
                          width: 180,
                          child: AppPrimaryButton(
                            label: 'Try again',
                            onPressed: isChecking ? null : onRetry,
                            isLoading: isChecking,
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

class _NoInternetIllustration extends StatelessWidget {
  const _NoInternetIllustration();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 190,
      height: 135,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Positioned(
            right: 20,
            top: 8,
            child: Container(
              width: 96,
              height: 96,
              decoration: BoxDecoration(
                color: const Color(0xFFF3F1FF),
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFFE8E5FF)),
              ),
            ),
          ),
          Positioned(
            top: 14,
            left: 44,
            child: Transform.rotate(
              angle: 0.36,
              child: const Icon(
                Icons.send_rounded,
                color: Color(0xFFD7D2FF),
                size: 20,
              ),
            ),
          ),
          const Positioned(left: 18, top: 34, child: _SoftCloud(width: 34)),
          const Positioned(right: 18, top: 54, child: _SoftCloud(width: 42)),
          Positioned(
            right: 58,
            top: 28,
            child: Container(
              width: 46,
              height: 46,
              decoration: const BoxDecoration(
                color: Color(0xFFDAD6FF),
                shape: BoxShape.circle,
              ),
            ),
          ),
          Positioned(
            right: 14,
            bottom: 6,
            child: SizedBox(
              width: 112,
              height: 86,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Positioned(
                    bottom: 0,
                    child: Container(
                      width: 54,
                      height: 34,
                      decoration: const BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.vertical(
                          top: Radius.circular(22),
                          bottom: Radius.circular(12),
                        ),
                      ),
                    ),
                  ),
                  const Positioned(
                    top: 18,
                    child: CircleAvatar(
                      radius: 15,
                      backgroundColor: AppColors.skin,
                    ),
                  ),
                  Positioned(
                    top: 8,
                    child: Container(
                      width: 34,
                      height: 20,
                      decoration: const BoxDecoration(
                        color: AppColors.avatarHair,
                        borderRadius: BorderRadius.vertical(
                          top: Radius.circular(16),
                          bottom: Radius.circular(10),
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    left: 18,
                    top: 46,
                    child: Transform.rotate(
                      angle: 0.62,
                      child: Container(
                        width: 12,
                        height: 42,
                        decoration: const BoxDecoration(
                          color: AppColors.skin,
                          borderRadius: BorderRadius.all(Radius.circular(10)),
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    right: 8,
                    bottom: 14,
                    child: Container(
                      width: 28,
                      height: 18,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.35),
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            right: 50,
            top: 18,
            child: Container(
              width: 68,
              height: 68,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFFE2DEFF)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SoftCloud extends StatelessWidget {
  const _SoftCloud({required this.width});

  final double width;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      height: width * 0.55,
      child: Stack(
        children: [
          Positioned(
            left: 0,
            bottom: 0,
            child: Container(
              width: width * 0.46,
              height: width * 0.36,
              decoration: const BoxDecoration(
                color: Color(0xFFF1F2FF),
                shape: BoxShape.circle,
              ),
            ),
          ),
          Positioned(
            left: width * 0.18,
            top: 0,
            child: Container(
              width: width * 0.42,
              height: width * 0.34,
              decoration: const BoxDecoration(
                color: Color(0xFFF1F2FF),
                shape: BoxShape.circle,
              ),
            ),
          ),
          Positioned(
            right: 0,
            bottom: 0,
            child: Container(
              width: width * 0.48,
              height: width * 0.36,
              decoration: const BoxDecoration(
                color: Color(0xFFF1F2FF),
                shape: BoxShape.circle,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
