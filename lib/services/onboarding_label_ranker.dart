import 'package:chatbotapp/models/prompt_recommendation.dart';

class OnboardingAnswers {
  const OnboardingAnswers({
    required this.primaryGoalId,
    required this.responseStyleId,
    required this.blockerId,
    this.additionalOptionIds = const {},
  });

  OnboardingAnswers.fromSelectedOptions(Map<String, String> selections)
      : primaryGoalId = selections['primary_goal'] ?? '',
        responseStyleId = selections['response_style'] ?? '',
        blockerId = selections['blocker'] ?? '',
        additionalOptionIds = Map.unmodifiable(selections);

  final String primaryGoalId;
  final String responseStyleId;
  final String blockerId;
  final Map<String, String> additionalOptionIds;

  Map<String, String> get selectedOptionIds {
    return {
      'primary_goal': primaryGoalId,
      'response_style': responseStyleId,
      'blocker': blockerId,
      ...additionalOptionIds,
    };
  }
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
    this.profileLabels = const [],
  });

  final String id;
  final String title;
  final String description;
  final Map<SupportLabel, int> labelWeights;
  final List<String> profileLabels;
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
  OnboardingQuestion(
    id: 'semester_load',
    title: 'How packed is your semester?',
    description: 'This helps estimate planning and stress sensitivity.',
    options: [
      OnboardingOption(
        id: 'heavy_course_load',
        title: 'Heavy course load',
        description: 'Several demanding classes or labs.',
        labelWeights: {
          SupportLabel.planning: 4,
          SupportLabel.studyHelp: 3,
          SupportLabel.wellbeingCheckIn: 2,
        },
        profileLabels: ['academic_planning', 'stress_sensitive'],
      ),
      OnboardingOption(
        id: 'balanced_load',
        title: 'Balanced load',
        description: 'Manageable, but still needs structure.',
        labelWeights: {
          SupportLabel.planning: 3,
          SupportLabel.summarization: 1,
        },
        profileLabels: ['academic_planning'],
      ),
      OnboardingOption(
        id: 'uncertain_load',
        title: 'Still figuring it out',
        description: 'I need help understanding what is hard.',
        labelWeights: {
          SupportLabel.studyHelp: 3,
          SupportLabel.wellbeingCheckIn: 2,
        },
      ),
    ],
  ),
  OnboardingQuestion(
    id: 'deadline_pattern',
    title: 'What happens around deadlines?',
    description: 'Orbit can adjust how early it nudges planning.',
    options: [
      OnboardingOption(
        id: 'last_minute',
        title: 'I start late',
        description: 'I usually need rescue plans.',
        labelWeights: {
          SupportLabel.planning: 5,
          SupportLabel.wellbeingCheckIn: 2,
        },
        profileLabels: ['deadline_sensitive'],
      ),
      OnboardingOption(
        id: 'overplan',
        title: 'I over-plan',
        description: 'I make lists but still freeze.',
        labelWeights: {
          SupportLabel.wellbeingCheckIn: 4,
          SupportLabel.planning: 2,
        },
        profileLabels: ['stress_sensitive'],
      ),
      OnboardingOption(
        id: 'steady_deadlines',
        title: 'I stay steady',
        description: 'I mainly want reminders and checks.',
        labelWeights: {
          SupportLabel.planning: 3,
        },
      ),
    ],
  ),
  OnboardingQuestion(
    id: 'class_support',
    title: 'Which class support would help most?',
    description: 'This tunes the academic agent.',
    options: [
      OnboardingOption(
        id: 'concept_help',
        title: 'Concept help',
        description: 'Explain hard ideas clearly.',
        labelWeights: {
          SupportLabel.studyHelp: 5,
          SupportLabel.summarization: 1,
        },
      ),
      OnboardingOption(
        id: 'practice_plan',
        title: 'Practice plan',
        description: 'Give me drills and review blocks.',
        labelWeights: {
          SupportLabel.studyHelp: 4,
          SupportLabel.planning: 3,
        },
      ),
      OnboardingOption(
        id: 'office_hours',
        title: 'Office-hour prep',
        description: 'Help me ask better questions.',
        labelWeights: {
          SupportLabel.writing: 2,
          SupportLabel.studyHelp: 3,
        },
      ),
    ],
  ),
  OnboardingQuestion(
    id: 'writing_need',
    title: 'What writing help do you need?',
    description: 'This includes emails, essays, and applications.',
    options: [
      OnboardingOption(
        id: 'draft_from_scratch',
        title: 'Draft from scratch',
        description: 'Turn rough intent into words.',
        labelWeights: {
          SupportLabel.writing: 5,
          SupportLabel.planning: 1,
        },
      ),
      OnboardingOption(
        id: 'revise_tone',
        title: 'Revise tone',
        description: 'Make writing clearer and more professional.',
        labelWeights: {
          SupportLabel.writing: 5,
          SupportLabel.summarization: 1,
        },
      ),
      OnboardingOption(
        id: 'rare_writing',
        title: 'Not often',
        description: 'Writing is not my main need.',
        labelWeights: {
          SupportLabel.planning: 1,
        },
      ),
    ],
  ),
  OnboardingQuestion(
    id: 'reading_volume',
    title: 'How much dense reading do you handle?',
    description: 'Orbit can bias toward summaries when needed.',
    options: [
      OnboardingOption(
        id: 'many_readings',
        title: 'A lot',
        description: 'Articles, PDFs, and long notes pile up.',
        labelWeights: {
          SupportLabel.summarization: 5,
          SupportLabel.studyHelp: 2,
        },
      ),
      OnboardingOption(
        id: 'some_readings',
        title: 'Some',
        description: 'I need occasional takeaways.',
        labelWeights: {
          SupportLabel.summarization: 3,
        },
      ),
      OnboardingOption(
        id: 'mostly_practice',
        title: 'Mostly practice',
        description: 'Problem sets matter more than reading.',
        labelWeights: {
          SupportLabel.studyHelp: 4,
        },
      ),
    ],
  ),
  OnboardingQuestion(
    id: 'image_need',
    title: 'Will you share screenshots or diagrams?',
    description: 'This affects routing for visual help.',
    options: [
      OnboardingOption(
        id: 'frequent_images',
        title: 'Often',
        description: 'Screenshots, charts, diagrams, or error messages.',
        labelWeights: {
          SupportLabel.imageAnalysis: 5,
          SupportLabel.studyHelp: 1,
        },
      ),
      OnboardingOption(
        id: 'sometimes_images',
        title: 'Sometimes',
        description: 'Only when text is not enough.',
        labelWeights: {
          SupportLabel.imageAnalysis: 3,
        },
      ),
      OnboardingOption(
        id: 'rare_images',
        title: 'Rarely',
        description: 'Most of my requests are text.',
        labelWeights: {
          SupportLabel.summarization: 1,
        },
      ),
    ],
  ),
  OnboardingQuestion(
    id: 'stress_pattern',
    title: 'When does stress usually spike?',
    description: 'This configures check-ins and pacing.',
    options: [
      OnboardingOption(
        id: 'before_exams',
        title: 'Before exams',
        description: 'Tests and finals hit hardest.',
        labelWeights: {
          SupportLabel.wellbeingCheckIn: 4,
          SupportLabel.studyHelp: 2,
          SupportLabel.planning: 2,
        },
        profileLabels: ['stress_sensitive'],
      ),
      OnboardingOption(
        id: 'when_behind',
        title: 'When I fall behind',
        description: 'Backlogs make it hard to restart.',
        labelWeights: {
          SupportLabel.wellbeingCheckIn: 5,
          SupportLabel.planning: 3,
        },
        profileLabels: ['stress_sensitive', 'deadline_sensitive'],
      ),
      OnboardingOption(
        id: 'low_stress',
        title: 'Not often',
        description: 'I mainly want productivity help.',
        labelWeights: {
          SupportLabel.planning: 2,
        },
      ),
    ],
  ),
  OnboardingQuestion(
    id: 'energy_pattern',
    title: 'What drains your energy most?',
    description: 'Orbit can keep actions smaller when needed.',
    options: [
      OnboardingOption(
        id: 'long_laptop_blocks',
        title: 'Long laptop blocks',
        description: 'I sit too long and lose focus.',
        labelWeights: {
          SupportLabel.wellbeingCheckIn: 3,
          SupportLabel.planning: 2,
        },
        profileLabels: ['movement_breaks', 'notification_breaks'],
      ),
      OnboardingOption(
        id: 'context_switching',
        title: 'Context switching',
        description: 'Classes, work, and messages collide.',
        labelWeights: {
          SupportLabel.planning: 4,
          SupportLabel.wellbeingCheckIn: 2,
        },
      ),
      OnboardingOption(
        id: 'social_load',
        title: 'Social load',
        description: 'Messages and coordination are tiring.',
        labelWeights: {
          SupportLabel.writing: 2,
          SupportLabel.wellbeingCheckIn: 3,
        },
      ),
    ],
  ),
  OnboardingQuestion(
    id: 'schedule_source',
    title: 'Where should schedule context come from?',
    description: 'This prepares the connector strategy.',
    options: [
      OnboardingOption(
        id: 'google_calendar',
        title: 'Google Calendar',
        description: 'My week lives in Google Calendar.',
        labelWeights: {
          SupportLabel.planning: 4,
        },
        profileLabels: ['google_calendar'],
      ),
      OnboardingOption(
        id: 'canvas_calendar',
        title: 'Canvas and ELMS',
        description: 'Assignments are the key schedule source.',
        labelWeights: {
          SupportLabel.planning: 3,
          SupportLabel.studyHelp: 2,
        },
        profileLabels: ['canvas'],
      ),
      OnboardingOption(
        id: 'manual_schedule',
        title: 'Manual for now',
        description: 'I will tell Orbit what matters.',
        labelWeights: {
          SupportLabel.planning: 2,
        },
        profileLabels: ['local_first'],
      ),
    ],
  ),
  OnboardingQuestion(
    id: 'calendar_density',
    title: 'How crowded is your calendar?',
    description: 'This helps estimate workload pressure.',
    options: [
      OnboardingOption(
        id: 'very_crowded',
        title: 'Very crowded',
        description: 'Classes, work, clubs, and appointments.',
        labelWeights: {
          SupportLabel.planning: 5,
          SupportLabel.wellbeingCheckIn: 3,
        },
        profileLabels: ['calendar_density', 'stress_sensitive'],
      ),
      OnboardingOption(
        id: 'moderately_crowded',
        title: 'Moderate',
        description: 'Busy, but not packed every day.',
        labelWeights: {
          SupportLabel.planning: 3,
        },
        profileLabels: ['calendar_density'],
      ),
      OnboardingOption(
        id: 'open_calendar',
        title: 'Pretty open',
        description: 'Tasks matter more than events.',
        labelWeights: {
          SupportLabel.studyHelp: 2,
          SupportLabel.planning: 1,
        },
      ),
    ],
  ),
  OnboardingQuestion(
    id: 'canvas_habit',
    title: 'How do you use Canvas?',
    description: 'This affects deadline retrieval and study routing.',
    options: [
      OnboardingOption(
        id: 'canvas_daily',
        title: 'Daily',
        description: 'Canvas is my assignment source of truth.',
        labelWeights: {
          SupportLabel.planning: 3,
          SupportLabel.studyHelp: 3,
        },
        profileLabels: ['canvas', 'study_help'],
      ),
      OnboardingOption(
        id: 'canvas_when_needed',
        title: 'When needed',
        description: 'I check it near deadlines.',
        labelWeights: {
          SupportLabel.planning: 4,
          SupportLabel.wellbeingCheckIn: 1,
        },
        profileLabels: ['canvas', 'deadline_sensitive'],
      ),
      OnboardingOption(
        id: 'canvas_messy',
        title: 'It feels messy',
        description: 'I need help finding what matters.',
        labelWeights: {
          SupportLabel.summarization: 3,
          SupportLabel.planning: 3,
        },
        profileLabels: ['canvas'],
      ),
    ],
  ),
  OnboardingQuestion(
    id: 'commute',
    title: 'How do you move around campus?',
    description: 'Orbit can include route and timing constraints.',
    options: [
      OnboardingOption(
        id: 'commuter',
        title: 'I commute',
        description: 'Parking, shuttles, or travel time matter.',
        labelWeights: {
          SupportLabel.planning: 3,
        },
        profileLabels: ['commuter', 'campus_navigation', 'life_logistics'],
      ),
      OnboardingOption(
        id: 'campus_walking',
        title: 'Mostly walking',
        description: 'Routes between campus buildings matter.',
        labelWeights: {
          SupportLabel.planning: 2,
        },
        profileLabels: ['campus_navigation'],
      ),
      OnboardingOption(
        id: 'remote_light',
        title: 'Not a big issue',
        description: 'Movement is rarely a constraint.',
        labelWeights: {
          SupportLabel.planning: 1,
        },
      ),
    ],
  ),
  OnboardingQuestion(
    id: 'dining_preference',
    title: 'Any food preference Orbit should remember?',
    description: 'Used for dining and nearby food searches.',
    options: [
      OnboardingOption(
        id: 'vegan_food',
        title: 'Vegan or plant-based',
        description: 'Search food with vegan options first.',
        labelWeights: {
          SupportLabel.planning: 1,
          SupportLabel.wellbeingCheckIn: 1,
        },
        profileLabels: ['vegan', 'plant_based', 'life_logistics'],
      ),
      OnboardingOption(
        id: 'vegetarian_food',
        title: 'Vegetarian',
        description: 'Prefer vegetarian options.',
        labelWeights: {
          SupportLabel.planning: 1,
        },
        profileLabels: ['vegetarian', 'life_logistics'],
      ),
      OnboardingOption(
        id: 'dietary_restriction',
        title: 'Halal, kosher, allergy, or gluten-free',
        description: 'Food searches should respect restrictions.',
        labelWeights: {
          SupportLabel.planning: 1,
          SupportLabel.wellbeingCheckIn: 1,
        },
        profileLabels: [
          'dietary_restriction',
          'food_allergy',
          'life_logistics',
        ],
      ),
      OnboardingOption(
        id: 'no_food_preference',
        title: 'No preference',
        description: 'Do not filter food searches by diet.',
        labelWeights: {
          SupportLabel.planning: 1,
        },
      ),
    ],
  ),
  OnboardingQuestion(
    id: 'accessibility_need',
    title: 'Should accessibility needs affect planning?',
    description: 'Only choose this if you want Orbit to remember it locally.',
    options: [
      OnboardingOption(
        id: 'accessibility_yes',
        title: 'Yes',
        description: 'Account for accommodations, access, or pacing.',
        labelWeights: {
          SupportLabel.planning: 3,
          SupportLabel.wellbeingCheckIn: 3,
        },
        profileLabels: ['accessibility', 'accommodation'],
      ),
      OnboardingOption(
        id: 'accessibility_maybe',
        title: 'Maybe later',
        description: 'Ask before using this signal.',
        labelWeights: {
          SupportLabel.wellbeingCheckIn: 1,
        },
      ),
      OnboardingOption(
        id: 'accessibility_no',
        title: 'No',
        description: 'Not needed for now.',
        labelWeights: {
          SupportLabel.planning: 1,
        },
      ),
    ],
  ),
  OnboardingQuestion(
    id: 'career_focus',
    title: 'How much career support do you want?',
    description: 'This helps ORBIT route internships and resumes.',
    options: [
      OnboardingOption(
        id: 'career_active',
        title: 'Active search',
        description: 'Internships, resume, interviews, and networking.',
        labelWeights: {
          SupportLabel.writing: 3,
          SupportLabel.planning: 3,
        },
        profileLabels: ['career_builder', 'pre_internship'],
      ),
      OnboardingOption(
        id: 'career_exploring',
        title: 'Exploring',
        description: 'I want direction, not pressure.',
        labelWeights: {
          SupportLabel.planning: 2,
          SupportLabel.wellbeingCheckIn: 1,
        },
        profileLabels: ['career_builder'],
      ),
      OnboardingOption(
        id: 'career_later',
        title: 'Later',
        description: 'Coursework comes first.',
        labelWeights: {
          SupportLabel.studyHelp: 2,
        },
      ),
    ],
  ),
  OnboardingQuestion(
    id: 'campus_confidence',
    title: 'How confident are you navigating UMD resources?',
    description: 'This tunes campus-resource suggestions.',
    options: [
      OnboardingOption(
        id: 'not_confident',
        title: 'Not confident',
        description: 'I do not know which office or resource to trust.',
        labelWeights: {
          SupportLabel.planning: 2,
          SupportLabel.wellbeingCheckIn: 2,
        },
        profileLabels: ['campus_resources', 'first_gen_support'],
      ),
      OnboardingOption(
        id: 'somewhat_confident',
        title: 'Somewhat',
        description: 'Point me in the right direction.',
        labelWeights: {
          SupportLabel.planning: 2,
        },
        profileLabels: ['campus_resources'],
      ),
      OnboardingOption(
        id: 'very_confident',
        title: 'Confident',
        description: 'Only suggest resources when directly relevant.',
        labelWeights: {
          SupportLabel.summarization: 1,
        },
      ),
    ],
  ),
  OnboardingQuestion(
    id: 'notification_style',
    title: 'What kind of nudges should Orbit use?',
    description: 'This prepares future notifications and advice.',
    options: [
      OnboardingOption(
        id: 'early_nudges',
        title: 'Early reminders',
        description: 'Warn me before deadlines pile up.',
        labelWeights: {
          SupportLabel.planning: 4,
        },
        profileLabels: ['early_notifications'],
      ),
      OnboardingOption(
        id: 'break_nudges',
        title: 'Break reminders',
        description: 'Tell me when I should walk or reset.',
        labelWeights: {
          SupportLabel.wellbeingCheckIn: 4,
        },
        profileLabels: ['movement_breaks', 'notification_breaks'],
      ),
      OnboardingOption(
        id: 'minimal_nudges',
        title: 'Minimal',
        description: 'Only notify me for important changes.',
        labelWeights: {
          SupportLabel.planning: 1,
        },
        profileLabels: ['minimal_notifications'],
      ),
    ],
  ),
];

List<SupportLabel> rankSupportLabels(OnboardingAnswers answers) {
  final scores = <SupportLabel, int>{
    for (final label in SupportLabel.values) label: 0,
  };

  final selectedOptions = _selectedOptions(answers);

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

List<String> onboardingProfileLabels(OnboardingAnswers answers) {
  final labels = <String>{
    'college_student',
    'local_first',
    ..._selectedOptions(answers).expand((option) => option.profileLabels),
  };
  return labels.toList(growable: false)..sort();
}

List<OnboardingOption> _selectedOptions(OnboardingAnswers answers) {
  return answers.selectedOptionIds.entries
      .map((entry) => _tryFindOption(entry.key, entry.value))
      .whereType<OnboardingOption>()
      .toList(growable: false);
}

OnboardingOption? _tryFindOption(String questionId, String optionId) {
  final question = onboardingQuestions.firstWhere(
    (item) => item.id == questionId,
    orElse: () => const OnboardingQuestion(
      id: '',
      title: '',
      description: '',
      options: [],
    ),
  );
  if (question.id.isEmpty) {
    return null;
  }
  for (final option in question.options) {
    if (option.id == optionId) {
      return option;
    }
  }
  return null;
}
