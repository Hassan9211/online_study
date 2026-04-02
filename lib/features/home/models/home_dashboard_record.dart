class HomeDashboardRecord {
  const HomeDashboardRecord({
    required this.learnedTodaySeconds,
    required this.dailyGoalMinutes,
    required this.totalHours,
    required this.totalDays,
    required this.learningCards,
    required this.learningPlan,
    required this.meetupTitle,
    required this.meetupSubtitle,
  });

  const HomeDashboardRecord.defaults()
      : learnedTodaySeconds = 0,
        dailyGoalMinutes = 60,
        totalHours = 468,
        totalDays = 554,
        learningCards = const <HomeLearningCardRecord>[
          HomeLearningCardRecord(
            title: 'Packaging Design',
            subtitle: '14 courses',
            buttonLabel: 'Get Started',
            themeKey: 'sky',
          ),
          HomeLearningCardRecord(
            title: 'UI Design',
            subtitle: '8 courses',
            themeKey: 'mint',
          ),
          HomeLearningCardRecord(
            title: 'Illustration',
            subtitle: '12 courses',
            themeKey: 'lilac',
          ),
        ],
        learningPlan = const <HomeLearningPlanRecord>[
          HomeLearningPlanRecord(
            title: 'Packaging Design',
            progress: 40,
            total: 48,
            isDone: true,
          ),
          HomeLearningPlanRecord(
            title: 'Product Design',
            progress: 6,
            total: 24,
          ),
          HomeLearningPlanRecord(
            title: 'Animation Basics',
            progress: 18,
            total: 24,
          ),
        ],
        meetupTitle = 'Meetup',
        meetupSubtitle = 'Off-line exchange of learning experiences';

  final int learnedTodaySeconds;
  final int dailyGoalMinutes;
  final int totalHours;
  final int totalDays;
  final List<HomeLearningCardRecord> learningCards;
  final List<HomeLearningPlanRecord> learningPlan;
  final String meetupTitle;
  final String meetupSubtitle;

  int get learnedTodayMinutes => learnedTodaySeconds ~/ 60;

  String get learnedTodayDisplayLabel {
    if (learnedTodaySeconds <= 0) {
      return '0';
    }

    final minuteValue = learnedTodaySeconds / 60;
    if (minuteValue >= 10 || learnedTodaySeconds % 60 == 0) {
      return minuteValue.toStringAsFixed(0);
    }

    return minuteValue.toStringAsFixed(1);
  }

  double get learnedTodayProgress {
    final goalSeconds = dailyGoalMinutes * 60;
    if (goalSeconds <= 0) {
      return 0;
    }

    return (learnedTodaySeconds / goalSeconds).clamp(0.0, 1.0);
  }
}

class HomeLearningCardRecord {
  const HomeLearningCardRecord({
    required this.title,
    required this.subtitle,
    this.buttonLabel,
    this.themeKey = '',
  });

  final String title;
  final String subtitle;
  final String? buttonLabel;
  final String themeKey;
}

class HomeLearningPlanRecord {
  const HomeLearningPlanRecord({
    required this.title,
    required this.progress,
    required this.total,
    this.isDone = false,
  });

  final String title;
  final int progress;
  final int total;
  final bool isDone;
}
