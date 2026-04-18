import 'package:chatbotapp/models/prompt_recommendation.dart';
import 'package:chatbotapp/services/onboarding_label_ranker.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('signup intake includes the business-demo question count', () {
    expect(onboardingQuestions, hasLength(20));
  });

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

  test('full intake extracts durable student profile labels', () {
    final answers = OnboardingAnswers.fromSelectedOptions(const {
      'primary_goal': 'stay_organized',
      'response_style': 'clear_steps',
      'blocker': 'too_many_tasks',
      'dining_preference': 'vegan_food',
      'commute': 'commuter',
      'notification_style': 'break_nudges',
      'schedule_source': 'google_calendar',
    });

    final labels = onboardingProfileLabels(answers);

    expect(
      labels,
      containsAll([
        'college_student',
        'local_first',
        'vegan',
        'plant_based',
        'commuter',
        'campus_navigation',
        'movement_breaks',
        'google_calendar',
      ]),
    );
  });
}
