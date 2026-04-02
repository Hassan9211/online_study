import '../../../core/network/api_client.dart';
import '../../../core/network/api_endpoints.dart';
import '../../../core/network/api_parsing.dart';
import '../models/onboarding_slide_record.dart';
import 'local_onboarding_content_repository.dart';
import 'onboarding_content_repository.dart';

class RemoteOnboardingContentRepository implements OnboardingContentRepository {
  RemoteOnboardingContentRepository(this._apiClient, this._localStore);

  final ApiClient _apiClient;
  final LocalOnboardingContentRepository _localStore;

  @override
  Future<List<OnboardingSlideRecord>> loadSlides() async {
    final cachedSlides = await _localStore.loadSlides();

    try {
      final body = await _apiClient.getJson(ApiEndpoints.onboarding.content);
      final payload = unwrapBody(body, keys: const ['data', 'slides', 'items']);
      final list = payload is List
          ? payload
          : readList(asMap(body), const ['slides', 'items', 'pages', 'data']);

      final slides = list.asMap().entries.map((entry) {
        return _parseSlide(asMap(entry.value), index: entry.key);
      }).where((slide) {
        return slide.title.trim().isNotEmpty &&
            slide.description.trim().isNotEmpty;
      }).toList();

      return slides.isEmpty ? cachedSlides : slides;
    } catch (_) {
      return cachedSlides;
    }
  }

  OnboardingSlideRecord _parseSlide(
    Map<String, dynamic> map, {
    required int index,
  }) {
    return OnboardingSlideRecord(
      title: readString(map, const ['title', 'heading', 'name']),
      description: readString(
        map,
        const ['description', 'body', 'subtitle', 'content'],
      ),
      showActions: readBool(
        map,
        const ['show_actions', 'showActions', 'is_last', 'isLast'],
        fallback: index >= 2,
      ),
      illustrationKey: readString(
        map,
        const ['illustration', 'illustration_key', 'illustrationKey', 'type'],
        fallback: _fallbackIllustrationKey(index),
      ),
    );
  }

  String _fallbackIllustrationKey(int index) {
    return switch (index) {
      0 => 'trial_courses',
      1 => 'quick_learning',
      _ => 'study_plan',
    };
  }
}
