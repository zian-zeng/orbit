import 'package:chatbotapp/models/prompt_recommendation.dart';

class OnboardingAnswers {
  const OnboardingAnswers({
    required this.primaryGoalId,
    required this.responseStyleId,
    required this.blockerId,
  });

  final String primaryGoalId;
  final String responseStyleId;
  final String blockerId;
}

class OnboardingQuestion {
  const OnboardingQuestion({
    required this.id,
    required this.title,
    required this.description,
    required this.options,
  });

  final String id;
  final String title;
  final String description;
  final List<OnboardingOption> options;
}

class OnboardingOption {
  const OnboardingOption({
    required this.id,
    required this.title,
    required this.description,
    required this.labelWeights,
  });

  final String id;
  final String title;
  final String description;
  final Map<SupportLabel, int> labelWeights;
}

const onboardingQuestions = <OnboardingQuestion>[
  OnboardingQuestion(
    id: 'primary_goal',
    title: 'What do you want Orbit to help with first?',
    description: 'Pick the kind of help you expect to use most often.',
    options: [
      OnboardingOption(
        id: 'stay_organized',
        title: 'Stay organized',
        description: 'Break tasks into a clear plan.',
        labelWeights: {
          SupportLabel.planning: 6,
          SupportLabel.summarization: 2,
          SupportLabel.wellbeingCheckIn: 1,
        },
      ),
      OnboardingOption(
        id: 'write_something_clear',
        title: 'Write something clearly',
        description: 'Turn rough ideas into polished wording.',
        labelWeights: {
          SupportLabel.writing: 6,
          SupportLabel.summarization: 2,
          SupportLabel.planning: 1,
        },
      ),
      OnboardingOption(
        id: 'learn_a_topic',
        title: 'Learn a topic',
        description: 'Understand concepts with guided help.',
        labelWeights: {
          SupportLabel.studyHelp: 6,
          SupportLabel.planning: 1,
          SupportLabel.summarization: 1,
        },
      ),
      OnboardingOption(
        id: 'get_the_short_version',
        title: 'Get the short version',
        description: 'Condense long information into takeaways.',
        labelWeights: {
          SupportLabel.summarization: 6,
          SupportLabel.writing: 1,
          SupportLabel.studyHelp: 1,
        },
      ),
      OnboardingOption(
        id: 'understand_an_image',
        title: 'Understand an image',
        description: 'Explain screenshots, diagrams, or photos.',
        labelWeights: {
          SupportLabel.imageAnalysis: 6,
          SupportLabel.summarization: 1,
          SupportLabel.studyHelp: 1,
        },
      ),
      OnboardingOption(
        id: 'feel_less_overwhelmed',
        title: 'Feel less overwhelmed',
        description: 'Regroup when everything feels like too much.',
        labelWeights: {
          SupportLabel.wellbeingCheckIn: 6,
          SupportLabel.planning: 1,
          SupportLabel.summarization: 1,
        },
      ),
    ],
  ),
  OnboardingQuestion(
    id: 'response_style',
    title: 'What kind of response feels most useful?',
    description: 'Choose the format you want the app to bias toward.',
    options: [
      OnboardingOption(
        id: 'clear_steps',
        title: 'Clear steps',
        description: 'Give me a practical sequence to follow.',
        labelWeights: {
          SupportLabel.planning: 4,
          SupportLabel.studyHelp: 2,
        },
      ),
      OnboardingOption(
        id: 'polished_words',
        title: 'Polished wording',
        description: 'Help me sound clear and professional.',
        labelWeights: {
          SupportLabel.writing: 4,
          SupportLabel.summarization: 1,
        },
      ),
      OnboardingOption(
        id: 'teach_me',
        title: 'Teach me',
        description: 'Walk me through it like a coach or tutor.',
        labelWeights: {
          SupportLabel.studyHelp: 4,
          SupportLabel.planning: 1,
        },
      ),
      OnboardingOption(
        id: 'concise_takeaways',
        title: 'Concise takeaways',
        description: 'Lead with the main points and trim the rest.',
        labelWeights: {
          SupportLabel.summarization: 4,
          SupportLabel.writing: 1,
        },
      ),
      OnboardingOption(
        id: 'visual_breakdown',
        title: 'Visual breakdown',
        description: 'Explain what matters in screenshots and diagrams.',
        labelWeights: {
          SupportLabel.imageAnalysis: 4,
          SupportLabel.studyHelp: 1,
        },
      ),
      OnboardingOption(
        id: 'steady_support',
        title: 'Steady support',
        description: 'Keep it calm, grounding, and manageable.',
        labelWeights: {
          SupportLabel.wellbeingCheckIn: 4,
          SupportLabel.planning: 1,
        },
      ),
    ],
  ),
  OnboardingQuestion(
    id: 'blocker',
    title: 'What slows you down most right now?',
    description: 'This gives Orbit a better starting signal.',
    options: [
      OnboardingOption(
        id: 'too_many_tasks',
        title: 'Too many tasks',
        description: 'I need help deciding what to do first.',
        labelWeights: {
          SupportLabel.planning: 5,
          SupportLabel.wellbeingCheckIn: 1,
        },
      ),
      OnboardingOption(
        id: 'blank_page',
        title: 'Blank page',
        description: 'Starting emails, essays, and messages is the hard part.',
        labelWeights: {
          SupportLabel.writing: 5,
          SupportLabel.summarization: 1,
        },
      ),
      OnboardingOption(
        id: 'hard_to_understand',
        title: 'Hard to understand',
        description: 'Dense material is slowing me down.',
        labelWeights: {
          SupportLabel.studyHelp: 5,
          SupportLabel.summarization: 1,
        },
      ),
      OnboardingOption(
        id: 'buried_in_notes',
        title: 'Buried in notes',
        description: 'I need help pulling out the main points.',
        labelWeights: {
          SupportLabel.summarization: 5,
          SupportLabel.planning: 1,
        },
      ),
      OnboardingOption(
        id: 'screenshot_confusion',
        title: 'Screenshot confusion',
        description: 'Images and diagrams need explanation.',
        labelWeights: {
          SupportLabel.imageAnalysis: 5,
          SupportLabel.studyHelp: 1,
        },
      ),
      OnboardingOption(
        id: 'stress_spiral',
        title: 'Stress spiral',
        description: 'Overwhelm makes it harder to begin anything.',
        labelWeights: {
          SupportLabel.wellbeingCheckIn: 5,
          SupportLabel.planning: 1,
        },
      ),
    ],
  ),
];

List<SupportLabel> rankSupportLabels(OnboardingAnswers answers) {
  final scores = <SupportLabel, int>{
    for (final label in SupportLabel.values) label: 0,
  };

  final selectedOptions = [
    _findOption('primary_goal', answers.primaryGoalId),
    _findOption('response_style', answers.responseStyleId),
    _findOption('blocker', answers.blockerId),
  ];

  for (final option in selectedOptions) {
    for (final entry in option.labelWeights.entries) {
      scores[entry.key] = (scores[entry.key] ?? 0) + entry.value;
    }
  }

  final ranked = SupportLabel.values.toList(growable: false);
  ranked.sort((left, right) {
    final scoreDelta = (scores[right] ?? 0) - (scores[left] ?? 0);
    if (scoreDelta != 0) {
      return scoreDelta;
    }
    return left.index.compareTo(right.index);
  });
  return ranked;
}

OnboardingOption _findOption(String questionId, String optionId) {
  final question = onboardingQuestions.firstWhere(
    (item) => item.id == questionId,
  );
  return question.options.firstWhere((option) => option.id == optionId);
}
