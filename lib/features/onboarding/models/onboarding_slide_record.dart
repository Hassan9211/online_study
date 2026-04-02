class OnboardingSlideRecord {
  const OnboardingSlideRecord({
    required this.title,
    required this.description,
    this.showActions = false,
    this.illustrationKey = '',
  });

  final String title;
  final String description;
  final bool showActions;
  final String illustrationKey;
}
