import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../app/routes/app_routes.dart';
import '../../../core/theme/app_colors.dart';
import '../controllers/auth_session_controller.dart';

class SessionGateScreen extends StatefulWidget {
  const SessionGateScreen({super.key});

  @override
  State<SessionGateScreen> createState() => _SessionGateScreenState();
}

class _SessionGateScreenState extends State<SessionGateScreen> {
  bool _didRedirect = false;

  void _redirect(AuthSessionController controller) {
    if (_didRedirect || !controller.isReady) {
      return;
    }

    _didRedirect = true;
    final targetRoute = controller.isLoggedIn
        ? AppRoutes.home
        : controller.hasSavedCredentials
        ? AppRoutes.logIn
        : AppRoutes.onboarding;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }

      Get.offAllNamed(targetRoute);
    });
  }

  @override
  Widget build(BuildContext context) {
    return GetBuilder<AuthSessionController>(
      builder: (controller) {
        _redirect(controller);

        return const Scaffold(
          backgroundColor: Colors.white,
          body: Center(
            child: CircularProgressIndicator(color: AppColors.primary),
          ),
        );
      },
    );
  }
}
