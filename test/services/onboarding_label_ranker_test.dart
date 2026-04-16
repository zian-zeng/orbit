import 'package:chatbotapp/models/prompt_recommendation.dart';
import 'package:chatbotapp/services/onboarding_label_ranker.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('ranks all six labels exactly once', () {
    final labels = rankSupportLabels(
      const OnboardingAnswers(
        primaryGoalId: 'stay_organized',
        responseStyleId: 'clear_steps',
        blockerId: 'too_many_tasks',
      ),
    );

    expect(labels, hasLength(SupportLabel.values.length));
    expect(labels.toSet(), SupportLabel.values.toSet());
  });

  test('study-oriented answers prioritize study help', () {
    final labels = rankSupportLabels(
      const OnboardingAnswers(
        primaryGoalId: 'learn_a_topic',
        responseStyleId: 'teach_me',
        blockerId: 'hard_to_understand',
      ),
    );

    expect(labels.first, SupportLabel.studyHelp);
  });

  test('overwhelm-oriented answers prioritize wellbeing check-in', () {
    final labels = rankSupportLabels(
      const OnboardingAnswers(
        primaryGoalId: 'feel_less_overwhelmed',
        responseStyleId: 'steady_support',
        blockerId: 'stress_spiral',
      ),
    );

    expect(labels.first, SupportLabel.wellbeingCheckIn);
  });
}
