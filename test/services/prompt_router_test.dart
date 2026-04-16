import 'package:chatbotapp/models/prompt_recommendation.dart';
import 'package:chatbotapp/services/prompt_router.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const router = PromptRouter();

  test('prefers image analysis when an image is attached', () {
    final recommendations = router.recommend(
      context: const RoutingContext(
        draftText: '',
        selectedLabel: null,
        hasImages: true,
        recentLabels: [],
        preferredLabels: [],
      ),
    );

    expect(recommendations.first.label, SupportLabel.imageAnalysis);
  });

  test('manual label override beats draft keyword inference', () {
    final recommendations = router.recommend(
      context: const RoutingContext(
        draftText: 'Help me reply to this email',
        selectedLabel: SupportLabel.studyHelp,
        hasImages: false,
        recentLabels: [],
        preferredLabels: [],
      ),
    );

    expect(recommendations.first.label, SupportLabel.studyHelp);
  });

  test('falls back to stable defaults without strong signals', () {
    final recommendations = router.recommend(
      context: const RoutingContext(
        draftText: '',
        selectedLabel: null,
        hasImages: false,
        recentLabels: [],
        preferredLabels: [],
      ),
    );

    expect(recommendations.length, 3);
    expect(
      recommendations.map((item) => item.label).toList(),
      containsAll([
        SupportLabel.planning,
        SupportLabel.writing,
        SupportLabel.studyHelp,
      ]),
    );
  });

  test('higher-ranked preferred labels outrank lower-ranked ones', () {
    final recommendations = router.recommend(
      context: const RoutingContext(
        draftText: '',
        selectedLabel: null,
        hasImages: false,
        recentLabels: [],
        preferredLabels: [
          SupportLabel.wellbeingCheckIn,
          SupportLabel.planning,
          SupportLabel.writing,
          SupportLabel.studyHelp,
          SupportLabel.summarization,
          SupportLabel.imageAnalysis,
        ],
      ),
    );

    expect(recommendations.first.label, SupportLabel.wellbeingCheckIn);
  });

  test('strong saved-label matches still keep three recommendations', () {
    final recommendations = router.recommend(
      context: const RoutingContext(
        draftText: '',
        selectedLabel: null,
        hasImages: false,
        recentLabels: [],
        preferredLabels: [
          SupportLabel.planning,
          SupportLabel.studyHelp,
          SupportLabel.summarization,
          SupportLabel.wellbeingCheckIn,
          SupportLabel.writing,
          SupportLabel.imageAnalysis,
        ],
      ),
    );

    expect(recommendations, hasLength(3));
    expect(recommendations.first.label, SupportLabel.planning);
  });
}
