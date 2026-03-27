import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../app/routes/app_routes.dart';
import '../../../core/theme/app_colors.dart';
import '../controllers/profile_controller.dart';
import '../widgets/profile_avatar.dart';
import 'account_screen.dart';
import 'course_screen.dart';
import 'message_screen.dart';
import 'search_screen.dart';
import '../widgets/home_bottom_nav_bar.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: AppColors.homeBackground,
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 220),
        child: _buildCurrentTab(theme),
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.fromLTRB(18, 0, 18, 18),
        child: HomeBottomNavBar(
          currentIndex: _currentIndex,
          onTap: (index) {
            setState(() {
              _currentIndex = index;
            });
          },
        ),
      ),
    );
  }

  Widget _buildCurrentTab(ThemeData theme) {
    switch (_currentIndex) {
      case 1:
        return const CourseScreen(key: ValueKey('course-tab'));
      case 2:
        return const SearchScreen(key: ValueKey('search-tab'));
      case 3:
        return const MessageScreen(key: ValueKey('message-tab'));
      case 4:
        return const AccountScreen(key: ValueKey('account-tab'));
      default:
        return _HomeDashboardView(
          key: const ValueKey('home-tab'),
          theme: theme,
        );
    }
  }
}

class _HomeDashboardView extends StatelessWidget {
  const _HomeDashboardView({super.key, required this.theme});

  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Container(
          height: 245,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [AppColors.homeGradientStart, AppColors.homeGradientEnd],
            ),
          ),
        ),
        SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 120),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _HeaderSection(theme: theme),
                const SizedBox(height: 22),
                _StudyProgressCard(
                  onTap: () => Get.toNamed(AppRoutes.myCourses),
                ),
                const SizedBox(height: 22),
                Text(
                  'What do you want to learn today?',
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: AppColors.heading,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 14),
                SizedBox(
                  height: 138,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    children: const [
                      _LearningCard(
                        title: 'Packaging Design',
                        subtitle: '14 courses',
                        backgroundColor: AppColors.homeCardSky,
                        accentColor: AppColors.warmAccent,
                        buttonLabel: 'Get Started',
                        isLarge: true,
                      ),
                      SizedBox(width: 14),
                      _LearningCard(
                        title: 'UI Design',
                        subtitle: '8 courses',
                        backgroundColor: AppColors.homeCardMint,
                        accentColor: AppColors.primary,
                      ),
                      SizedBox(width: 14),
                      _LearningCard(
                        title: 'Illustration',
                        subtitle: '12 courses',
                        backgroundColor: AppColors.homeCardLilac,
                        accentColor: AppColors.heading,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 22),
                Text(
                  'Learning Plan',
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: AppColors.heading,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 14),
                const _LearningPlanCard(),
                const SizedBox(height: 18),
                const _MeetupCard(),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _HeaderSection extends StatelessWidget {
  const _HeaderSection({required this.theme});

  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    return GetBuilder<ProfileController>(
      builder: (profileController) {
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Hi, ${profileController.firstName}',
                    style: theme.textTheme.headlineSmall?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Let\'s start learning',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: Colors.white.withValues(alpha: 0.8),
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
            ProfileAvatar(
              size: 38,
              onTap: () => Get.toNamed(AppRoutes.editAccount),
              backgroundColor: Colors.white.withValues(alpha: 0.18),
              borderColor: Colors.white.withValues(alpha: 0.22),
              innerPadding: 3,
            ),
          ],
        );
      },
    );
  }
}

class _StudyProgressCard extends StatelessWidget {
  const _StudyProgressCard({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(22),
        child: Ink(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(22),
            boxShadow: [
              BoxShadow(
                color: AppColors.heading.withValues(alpha: 0.06),
                blurRadius: 24,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Learned today',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: AppColors.mutedText,
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(height: 4),
                        RichText(
                          text: TextSpan(
                            style: theme.textTheme.bodyLarge?.copyWith(
                              color: AppColors.heading,
                            ),
                            children: [
                              const TextSpan(
                                text: '46min',
                                style: TextStyle(
                                  fontSize: 30,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: -0.8,
                                ),
                              ),
                              TextSpan(
                                text: ' / 60min',
                                style: TextStyle(
                                  color: AppColors.mutedText.withValues(
                                    alpha: 0.9,
                                  ),
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  Row(
                    children: [
                      Text(
                        'My courses',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Icon(
                        Icons.arrow_forward_ios_rounded,
                        size: 12,
                        color: AppColors.primary,
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 16),
              ClipRRect(
                borderRadius: BorderRadius.circular(999),
                child: LinearProgressIndicator(
                  value: 46 / 60,
                  minHeight: 6,
                  backgroundColor: AppColors.dividerSoft,
                  valueColor: const AlwaysStoppedAnimation<Color>(
                    AppColors.warmAccent,
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

class _LearningCard extends StatelessWidget {
  const _LearningCard({
    required this.title,
    required this.subtitle,
    required this.backgroundColor,
    required this.accentColor,
    this.buttonLabel,
    this.isLarge = false,
  });

  final String title;
  final String subtitle;
  final Color backgroundColor;
  final Color accentColor;
  final String? buttonLabel;
  final bool isLarge;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: isLarge ? 214 : 124,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Stack(
        children: [
          Positioned(
            right: -8,
            top: -10,
            child: Container(
              width: 74,
              height: 74,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.22),
                shape: BoxShape.circle,
              ),
            ),
          ),
          Positioned(
            right: isLarge ? 10 : 2,
            bottom: 2,
            child: _CourseIllustration(
              accentColor: accentColor,
              isLarge: isLarge,
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: isLarge ? 110 : 78,
                child: Text(
                  title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleSmall?.copyWith(
                    color: AppColors.heading,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                subtitle,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: AppColors.inputText,
                  fontSize: 11,
                ),
              ),
              const Spacer(),
              if (buttonLabel != null)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.warmAccent,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    buttonLabel!,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _CourseIllustration extends StatelessWidget {
  const _CourseIllustration({required this.accentColor, required this.isLarge});

  final Color accentColor;
  final bool isLarge;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: isLarge ? 86 : 70,
      height: isLarge ? 98 : 82,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Positioned(
            bottom: 0,
            child: Container(
              width: isLarge ? 64 : 54,
              height: isLarge ? 54 : 46,
              decoration: BoxDecoration(
                color: accentColor,
                borderRadius: BorderRadius.circular(20),
              ),
            ),
          ),
          Positioned(
            top: 8,
            child: Container(
              width: isLarge ? 30 : 24,
              height: isLarge ? 30 : 24,
              decoration: const BoxDecoration(
                color: AppColors.skin,
                shape: BoxShape.circle,
              ),
            ),
          ),
          Positioned(
            top: 2,
            child: Container(
              width: isLarge ? 34 : 28,
              height: isLarge ? 18 : 14,
              decoration: const BoxDecoration(
                color: AppColors.orangeHair,
                borderRadius: BorderRadius.vertical(
                  top: Radius.circular(18),
                  bottom: Radius.circular(10),
                ),
              ),
            ),
          ),
          Positioned(
            top: isLarge ? 34 : 30,
            child: Container(
              width: isLarge ? 10 : 8,
              height: isLarge ? 22 : 18,
              decoration: const BoxDecoration(
                color: AppColors.skin,
                borderRadius: BorderRadius.all(Radius.circular(8)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LearningPlanCard extends StatelessWidget {
  const _LearningPlanCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: AppColors.heading.withValues(alpha: 0.06),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: const Column(
        children: [
          _PlanRow(
            title: 'Packaging Design',
            progress: 40,
            total: 48,
            isDone: true,
          ),
          Divider(height: 24, color: AppColors.dividerSoft),
          _PlanRow(title: 'Product Design', progress: 6, total: 24),
          Divider(height: 24, color: AppColors.dividerSoft),
          _PlanRow(title: 'Animation Basics', progress: 18, total: 24),
        ],
      ),
    );
  }
}

class _PlanRow extends StatelessWidget {
  const _PlanRow({
    required this.title,
    required this.progress,
    required this.total,
    this.isDone = false,
  });

  final String title;
  final int progress;
  final int total;
  final bool isDone;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Container(
          width: 22,
          height: 22,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isDone ? AppColors.primary.withValues(alpha: 0.14) : null,
            border: Border.all(
              color: isDone ? AppColors.primary : AppColors.inputBorder,
              width: 1.4,
            ),
          ),
          child: isDone
              ? const Icon(
                  Icons.check_rounded,
                  size: 14,
                  color: AppColors.primary,
                )
              : null,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            title,
            style: theme.textTheme.bodyLarge?.copyWith(
              color: AppColors.heading,
              fontSize: 15,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        Text(
          '$progress',
          style: theme.textTheme.bodyLarge?.copyWith(
            color: AppColors.heading,
            fontWeight: FontWeight.w700,
          ),
        ),
        Text(
          '/$total',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: AppColors.mutedText,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class _MeetupCard extends StatelessWidget {
  const _MeetupCard();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFF2E3FF), Color(0xFFF7EFFF)],
        ),
        borderRadius: BorderRadius.circular(22),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Meetup',
                  style: theme.textTheme.headlineSmall?.copyWith(
                    color: const Color(0xFF5226A5),
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.6,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Off-line exchange of learning experiences',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: const Color(0xFF7B6A9E),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          SizedBox(
            width: 88,
            height: 68,
            child: Stack(
              children: const [
                Positioned(
                  left: 2,
                  bottom: 0,
                  child: _MeetupAvatar(
                    hairColor: AppColors.orangeHair,
                    shirtColor: AppColors.primary,
                  ),
                ),
                Positioned(
                  right: 4,
                  bottom: 4,
                  child: _MeetupAvatar(
                    hairColor: AppColors.avatarHair,
                    shirtColor: AppColors.softPink,
                  ),
                ),
                Positioned(
                  left: 28,
                  top: 0,
                  child: _MeetupAvatar(
                    hairColor: AppColors.warmAccent,
                    shirtColor: AppColors.homeCardMint,
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

class _MeetupAvatar extends StatelessWidget {
  const _MeetupAvatar({required this.hairColor, required this.shirtColor});

  final Color hairColor;
  final Color shirtColor;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 34,
      height: 42,
      child: Stack(
        alignment: Alignment.topCenter,
        children: [
          Positioned(
            bottom: 0,
            child: Container(
              width: 28,
              height: 20,
              decoration: BoxDecoration(
                color: shirtColor,
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
          Positioned(
            top: 10,
            child: Container(
              width: 18,
              height: 16,
              decoration: const BoxDecoration(
                color: AppColors.skin,
                borderRadius: BorderRadius.all(Radius.circular(8)),
              ),
            ),
          ),
          Positioned(
            top: 0,
            child: Container(
              width: 20,
              height: 16,
              decoration: BoxDecoration(
                color: hairColor,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(10),
                  bottom: Radius.circular(7),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
