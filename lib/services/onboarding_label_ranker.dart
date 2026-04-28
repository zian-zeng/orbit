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
    this.visibleWhenOptionIds = const [],
  });

  final String id;
  final String title;
  final String description;
  final List<OnboardingOption> options;
  final List<String> visibleWhenOptionIds;

  bool isVisible(Map<String, String> selections) {
    if (visibleWhenOptionIds.isEmpty) {
      return true;
    }
    final selectedIds = selections.values.toSet();
    return visibleWhenOptionIds.any(selectedIds.contains);
  }
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
    id: 'student_stage',
    title: 'Where are you in school right now?',
    description:
        'This helps Orbit tune advice for incoming, undergraduate, graduate, and returning students.',
    options: [
      OnboardingOption(
        id: 'incoming_student',
        title: 'Incoming or first-year student',
        description: 'I am still learning campus, expectations, and routines.',
        labelWeights: {
          SupportLabel.planning: 4,
          SupportLabel.wellbeingCheckIn: 2,
        },
        profileLabels: [
          'incoming_student',
          'undergraduate',
          'campus_navigation'
        ],
      ),
      OnboardingOption(
        id: 'undergrad_early',
        title: 'Undergraduate, early years',
        description: 'I am building study habits and choosing a direction.',
        labelWeights: {
          SupportLabel.studyHelp: 3,
          SupportLabel.planning: 3,
        },
        profileLabels: ['undergraduate', 'early_college'],
      ),
      OnboardingOption(
        id: 'undergrad_upper',
        title: 'Undergraduate, upper years',
        description:
            'Major classes, internships, and graduation planning matter.',
        labelWeights: {
          SupportLabel.planning: 3,
          SupportLabel.studyHelp: 2,
          SupportLabel.writing: 1,
        },
        profileLabels: ['undergraduate', 'upper_division', 'career_builder'],
      ),
      OnboardingOption(
        id: 'masters_student',
        title: 'Master\'s student',
        description:
            'I need support balancing advanced classes, projects, or work.',
        labelWeights: {
          SupportLabel.planning: 3,
          SupportLabel.studyHelp: 2,
          SupportLabel.writing: 1,
        },
        profileLabels: ['graduate_student', 'masters_student'],
      ),
      OnboardingOption(
        id: 'phd_student',
        title: 'PhD student',
        description:
            'Research, teaching, advising, and long-term planning matter.',
        labelWeights: {
          SupportLabel.planning: 3,
          SupportLabel.writing: 2,
          SupportLabel.wellbeingCheckIn: 1,
        },
        profileLabels: ['graduate_student', 'phd_student', 'research_student'],
      ),
      OnboardingOption(
        id: 'returning_or_nontraditional',
        title: 'Returning or nontraditional student',
        description: 'School has to fit around more life responsibilities.',
        labelWeights: {
          SupportLabel.planning: 4,
          SupportLabel.wellbeingCheckIn: 2,
        },
        profileLabels: ['nontraditional_student', 'life_logistics'],
      ),
    ],
  ),
  OnboardingQuestion(
    id: 'major_area',
    title: 'What area best matches your major or path?',
    description: 'A broad signal is enough; Orbit can refine this later.',
    options: [
      OnboardingOption(
        id: 'cs_engineering',
        title: 'Computer science or engineering',
        description:
            'Coding, systems, labs, projects, or technical interviews.',
        labelWeights: {
          SupportLabel.studyHelp: 4,
          SupportLabel.planning: 2,
        },
        profileLabels: ['stem', 'cs_engineering', 'career_builder'],
      ),
      OnboardingOption(
        id: 'math_physics',
        title: 'Math, physics, or quantitative STEM',
        description: 'Problem sets, proofs, formulas, or technical exams.',
        labelWeights: {
          SupportLabel.studyHelp: 5,
          SupportLabel.planning: 1,
        },
        profileLabels: ['stem', 'math_physics', 'quantitative_courses'],
      ),
      OnboardingOption(
        id: 'bio_health_science',
        title: 'Biology, health, or lab science',
        description: 'Memorization, labs, exams, and dense course material.',
        labelWeights: {
          SupportLabel.studyHelp: 4,
          SupportLabel.summarization: 2,
        },
        profileLabels: ['science_courses', 'lab_courses'],
      ),
      OnboardingOption(
        id: 'business_policy_social',
        title: 'Business, policy, or social science',
        description: 'Reading, cases, presentations, research, or analysis.',
        labelWeights: {
          SupportLabel.writing: 2,
          SupportLabel.summarization: 3,
          SupportLabel.planning: 1,
        },
        profileLabels: ['reading_heavy_courses', 'presentation_support'],
      ),
      OnboardingOption(
        id: 'arts_humanities',
        title: 'Arts, humanities, or communication',
        description: 'Writing, critique, projects, and creative work.',
        labelWeights: {
          SupportLabel.writing: 4,
          SupportLabel.summarization: 2,
        },
        profileLabels: ['writing_heavy_courses', 'creative_courses'],
      ),
      OnboardingOption(
        id: 'undecided_major',
        title: 'Undecided or exploring',
        description: 'I want help comparing classes, majors, or directions.',
        labelWeights: {
          SupportLabel.planning: 4,
          SupportLabel.wellbeingCheckIn: 1,
        },
        profileLabels: ['major_exploration', 'course_selection'],
      ),
    ],
  ),
  OnboardingQuestion(
    id: 'age_context',
    title: 'What life-stage context should Orbit assume?',
    description:
        'A broad range is enough; this helps avoid advice that assumes one kind of student life.',
    options: [
      OnboardingOption(
        id: 'traditional_age',
        title: 'Traditional undergraduate age',
        description: 'Most campus routines and peer activities may fit.',
        labelWeights: {
          SupportLabel.planning: 1,
        },
        profileLabels: ['traditional_age_student'],
      ),
      OnboardingOption(
        id: 'adult_learner',
        title: 'Adult learner',
        description:
            'Work, family, commuting, or returning to school may matter.',
        labelWeights: {
          SupportLabel.planning: 3,
          SupportLabel.wellbeingCheckIn: 1,
        },
        profileLabels: ['adult_learner', 'nontraditional_student'],
      ),
      OnboardingOption(
        id: 'prefer_not_age',
        title: 'Prefer not to say',
        description: 'Do not use age context for personalization.',
        labelWeights: {
          SupportLabel.planning: 1,
        },
      ),
    ],
  ),
  OnboardingQuestion(
    id: 'enrollment_work',
    title: 'What does your weekly load look like outside class?',
    description:
        'Orbit should know if school has to fit around work or caregiving.',
    options: [
      OnboardingOption(
        id: 'full_time_student',
        title: 'Full-time student',
        description: 'School is the main weekly commitment.',
        labelWeights: {
          SupportLabel.planning: 2,
        },
        profileLabels: ['full_time_student'],
      ),
      OnboardingOption(
        id: 'student_working',
        title: 'Student and working',
        description: 'I need school plans that respect job shifts.',
        labelWeights: {
          SupportLabel.planning: 5,
          SupportLabel.wellbeingCheckIn: 2,
        },
        profileLabels: ['working_student', 'work_shift_constraints'],
      ),
      OnboardingOption(
        id: 'part_time_student',
        title: 'Part-time student',
        description: 'My schedule is not a standard full-time student week.',
        labelWeights: {
          SupportLabel.planning: 4,
        },
        profileLabels: ['part_time_student', 'life_logistics'],
      ),
      OnboardingOption(
        id: 'caregiver_or_family',
        title: 'Family or caregiving duties',
        description: 'Home responsibilities affect when I can study.',
        labelWeights: {
          SupportLabel.planning: 4,
          SupportLabel.wellbeingCheckIn: 2,
        },
        profileLabels: ['caregiver_student', 'life_logistics'],
      ),
    ],
  ),
  OnboardingQuestion(
    id: 'international_status',
    title: 'Should language or international-student context matter?',
    description: 'Choose what you want Orbit to remember locally.',
    options: [
      OnboardingOption(
        id: 'international_student',
        title: 'International student',
        description: 'Visa, language, culture, and campus systems may matter.',
        labelWeights: {
          SupportLabel.writing: 2,
          SupportLabel.summarization: 2,
          SupportLabel.planning: 2,
        },
        profileLabels: ['international_student', 'campus_resources'],
      ),
      OnboardingOption(
        id: 'multilingual_student',
        title: 'Multilingual or English is not always easiest',
        description: 'Clear wording and language support may help.',
        labelWeights: {
          SupportLabel.writing: 3,
          SupportLabel.summarization: 2,
        },
        profileLabels: ['multilingual_student', 'language_support'],
      ),
      OnboardingOption(
        id: 'domestic_student',
        title: 'No special language context',
        description: 'Use standard campus and academic guidance.',
        labelWeights: {
          SupportLabel.planning: 1,
        },
      ),
      OnboardingOption(
        id: 'prefer_not_language',
        title: 'Prefer not to say',
        description: 'Do not use this signal unless I bring it up later.',
        labelWeights: {
          SupportLabel.planning: 1,
        },
      ),
    ],
  ),
  OnboardingQuestion(
    id: 'first_language',
    title: 'What language should Orbit consider first?',
    description: 'This only appears when language context may be useful.',
    visibleWhenOptionIds: [
      'international_student',
      'multilingual_student',
    ],
    options: [
      OnboardingOption(
        id: 'first_language_english',
        title: 'English',
        description: 'English is comfortable for school support.',
        labelWeights: {
          SupportLabel.writing: 1,
        },
        profileLabels: ['english_first_language'],
      ),
      OnboardingOption(
        id: 'first_language_chinese',
        title: 'Chinese',
        description: 'Plain English rewrites and term explanations may help.',
        labelWeights: {
          SupportLabel.writing: 2,
          SupportLabel.summarization: 2,
        },
        profileLabels: ['language_chinese', 'language_support'],
      ),
      OnboardingOption(
        id: 'first_language_spanish',
        title: 'Spanish',
        description: 'Plain English rewrites and term explanations may help.',
        labelWeights: {
          SupportLabel.writing: 2,
          SupportLabel.summarization: 2,
        },
        profileLabels: ['language_spanish', 'language_support'],
      ),
      OnboardingOption(
        id: 'first_language_other',
        title: 'Another language',
        description: 'Keep wording clear and explain campus terminology.',
        labelWeights: {
          SupportLabel.writing: 2,
          SupportLabel.summarization: 2,
        },
        profileLabels: ['language_other', 'language_support'],
      ),
    ],
  ),
  OnboardingQuestion(
    id: 'background_support',
    title: 'Which background signal would help Orbit support you better?',
    description:
        'Pick the one that matters most now; you can change this later.',
    options: [
      OnboardingOption(
        id: 'first_generation',
        title: 'First-generation college student',
        description: 'Campus processes and hidden expectations can be unclear.',
        labelWeights: {
          SupportLabel.planning: 3,
          SupportLabel.wellbeingCheckIn: 2,
        },
        profileLabels: ['first_generation_student', 'campus_resources'],
      ),
      OnboardingOption(
        id: 'financial_stress',
        title: 'Financial stress',
        description: 'Work, cost, food, books, or housing pressure matters.',
        labelWeights: {
          SupportLabel.planning: 3,
          SupportLabel.wellbeingCheckIn: 3,
        },
        profileLabels: [
          'financial_stress',
          'campus_resources',
          'life_logistics'
        ],
      ),
      OnboardingOption(
        id: 'accessibility_or_health',
        title: 'Disability, ADHD, depression, anxiety, or health support',
        description:
            'I may need pacing, accommodations, or the right resource.',
        labelWeights: {
          SupportLabel.wellbeingCheckIn: 5,
          SupportLabel.planning: 3,
        },
        profileLabels: [
          'accessibility',
          'mental_health_support',
          'accommodation',
          'stress_sensitive',
        ],
      ),
      OnboardingOption(
        id: 'housing_transport_pressure',
        title: 'Housing, rent, transport, or shopping pressure',
        description: 'Everyday logistics can affect school plans.',
        labelWeights: {
          SupportLabel.planning: 4,
          SupportLabel.wellbeingCheckIn: 1,
        },
        profileLabels: ['housing_support', 'renting', 'life_logistics'],
      ),
      OnboardingOption(
        id: 'no_background_signal',
        title: 'None right now',
        description: 'Start with academic and schedule support.',
        labelWeights: {
          SupportLabel.planning: 1,
        },
      ),
    ],
  ),
  OnboardingQuestion(
    id: 'subject_pressure',
    title: 'Which academic area feels most stressful?',
    description:
        'This helps Orbit decide whether to lead with tutoring, practice, writing, or planning.',
    options: [
      OnboardingOption(
        id: 'math_physics_stress',
        title: 'Math, physics, or quantitative work',
        description: 'Problem solving, formulas, or proofs feel stressful.',
        labelWeights: {
          SupportLabel.studyHelp: 5,
          SupportLabel.planning: 2,
        },
        profileLabels: ['math_stress', 'physics_stress', 'exam_prep'],
      ),
      OnboardingOption(
        id: 'coding_lab_stress',
        title: 'Coding, labs, or technical projects',
        description: 'Projects feel hard to start, debug, or finish.',
        labelWeights: {
          SupportLabel.studyHelp: 4,
          SupportLabel.planning: 3,
        },
        profileLabels: ['coding_stress', 'lab_support', 'project_planning'],
      ),
      OnboardingOption(
        id: 'reading_writing_stress',
        title: 'Reading, writing, or presentations',
        description: 'Dense material, essays, or speaking tasks take energy.',
        labelWeights: {
          SupportLabel.writing: 3,
          SupportLabel.summarization: 4,
        },
        profileLabels: ['writing_stress', 'reading_heavy_courses'],
      ),
      OnboardingOption(
        id: 'exam_stress_general',
        title: 'Exams in general',
        description: 'I need review plans and calmer test prep.',
        labelWeights: {
          SupportLabel.studyHelp: 4,
          SupportLabel.planning: 3,
          SupportLabel.wellbeingCheckIn: 2,
        },
        profileLabels: ['exam_prep', 'stress_sensitive'],
      ),
      OnboardingOption(
        id: 'academics_feel_ok',
        title: 'Academics feel okay',
        description: 'I mainly need schedule, life, or career support.',
        labelWeights: {
          SupportLabel.planning: 2,
        },
      ),
    ],
  ),
  OnboardingQuestion(
    id: 'academic_strength',
    title: 'What usually feels strongest for you?',
    description: 'This helps Orbit encourage the strategies that already work.',
    options: [
      OnboardingOption(
        id: 'strength_math_logic',
        title: 'Math, logic, or problem solving',
        description: 'Use structured examples and practice loops.',
        labelWeights: {
          SupportLabel.studyHelp: 2,
          SupportLabel.planning: 1,
        },
        profileLabels: ['strength_quantitative'],
      ),
      OnboardingOption(
        id: 'strength_writing_reading',
        title: 'Writing, reading, or discussion',
        description: 'Use explanations, outlines, and verbal reasoning.',
        labelWeights: {
          SupportLabel.writing: 2,
          SupportLabel.summarization: 1,
        },
        profileLabels: ['strength_writing_reading'],
      ),
      OnboardingOption(
        id: 'strength_visual_hands_on',
        title: 'Visual or hands-on learning',
        description: 'Use diagrams, examples, and applied practice.',
        labelWeights: {
          SupportLabel.imageAnalysis: 2,
          SupportLabel.studyHelp: 2,
        },
        profileLabels: ['visual_learner', 'hands_on_learning'],
      ),
      OnboardingOption(
        id: 'strength_still_learning',
        title: 'I am still figuring that out',
        description: 'Help me test different study approaches.',
        labelWeights: {
          SupportLabel.studyHelp: 2,
          SupportLabel.wellbeingCheckIn: 1,
        },
        profileLabels: ['learning_strategy_support'],
      ),
    ],
  ),
  OnboardingQuestion(
    id: 'course_life_need',
    title: 'What should Orbit be ready to help with later?',
    description:
        'This creates starting labels for class choice, work, campus life, and daily logistics.',
    options: [
      OnboardingOption(
        id: 'choose_classes_professors',
        title: 'Choosing classes and professors',
        description: 'Course difficulty, professor fit, and ratings matter.',
        labelWeights: {
          SupportLabel.planning: 5,
          SupportLabel.summarization: 1,
        },
        profileLabels: [
          'course_selection',
          'professor_ratings',
          'planet_terp',
        ],
      ),
      OnboardingOption(
        id: 'regular_course_review',
        title: 'Regular study and course review',
        description: 'Keep me reviewing material before exams.',
        labelWeights: {
          SupportLabel.studyHelp: 4,
          SupportLabel.planning: 3,
        },
        profileLabels: ['regular_review', 'exam_prep'],
      ),
      OnboardingOption(
        id: 'job_internship_work',
        title: 'Jobs, internships, or work help',
        description: 'Resume, applications, interviews, or job balancing.',
        labelWeights: {
          SupportLabel.writing: 3,
          SupportLabel.planning: 3,
        },
        profileLabels: ['career_builder', 'job_search', 'internship_search'],
      ),
      OnboardingOption(
        id: 'campus_events_groups',
        title: 'Events, clubs, or email lists',
        description: 'Help me find relevant campus events or groups.',
        labelWeights: {
          SupportLabel.planning: 2,
          SupportLabel.summarization: 1,
        },
        profileLabels: [
          'event_recommendations',
          'campus_resources',
          'cs_email_list'
        ],
      ),
      OnboardingOption(
        id: 'life_shopping_renting',
        title: 'Life logistics',
        description: 'Shopping, renting, food, transport, and errands.',
        labelWeights: {
          SupportLabel.planning: 4,
          SupportLabel.wellbeingCheckIn: 1,
        },
        profileLabels: ['life_logistics', 'shopping_support', 'renting'],
      ),
    ],
  ),
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
    visibleWhenOptionIds: [
      'learn_a_topic',
      'hard_to_understand',
      'math_physics_stress',
      'coding_lab_stress',
      'exam_stress_general',
      'regular_course_review',
    ],
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
    visibleWhenOptionIds: [
      'write_something_clear',
      'polished_words',
      'blank_page',
      'reading_writing_stress',
      'job_internship_work',
      'international_student',
      'multilingual_student',
    ],
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
    visibleWhenOptionIds: [
      'get_the_short_version',
      'concise_takeaways',
      'buried_in_notes',
      'reading_writing_stress',
      'business_policy_social',
      'bio_health_science',
    ],
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
    visibleWhenOptionIds: [
      'understand_an_image',
      'visual_breakdown',
      'screenshot_confusion',
    ],
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
    visibleWhenOptionIds: [
      'feel_less_overwhelmed',
      'stress_spiral',
      'financial_stress',
      'accessibility_or_health',
      'exam_stress_general',
      'overplan',
    ],
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
    visibleWhenOptionIds: [
      'before_exams',
      'when_behind',
      'financial_stress',
      'accessibility_or_health',
      'student_working',
      'caregiver_or_family',
    ],
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
    visibleWhenOptionIds: [
      'stay_organized',
      'too_many_tasks',
      'choose_classes_professors',
      'regular_course_review',
      'student_working',
      'caregiver_or_family',
    ],
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
    visibleWhenOptionIds: [
      'google_calendar',
      'canvas_calendar',
      'manual_schedule',
      'student_working',
      'caregiver_or_family',
    ],
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
    visibleWhenOptionIds: [
      'canvas_calendar',
      'heavy_course_load',
      'last_minute',
      'choose_classes_professors',
      'regular_course_review',
    ],
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
    title: 'What kind of access support should Orbit watch for?',
    description:
        'This stays local and helps route to accommodations or pacing support.',
    visibleWhenOptionIds: [
      'accessibility_or_health',
    ],
    options: [
      OnboardingOption(
        id: 'accessibility_documented',
        title: 'Documented disability or accommodation',
        description: 'Help me plan around approved accommodations.',
        labelWeights: {
          SupportLabel.planning: 3,
          SupportLabel.wellbeingCheckIn: 3,
        },
        profileLabels: [
          'accessibility',
          'accommodation',
          'disability_resources'
        ],
      ),
      OnboardingOption(
        id: 'accessibility_realizing',
        title: 'I may be realizing I need help',
        description: 'Help me find the right office or next step.',
        labelWeights: {
          SupportLabel.wellbeingCheckIn: 4,
          SupportLabel.planning: 2,
        },
        profileLabels: [
          'accessibility',
          'accommodation_exploration',
          'campus_resources',
        ],
      ),
      OnboardingOption(
        id: 'adhd_or_focus_support',
        title: 'ADHD, focus, anxiety, or depression support',
        description: 'Keep plans smaller and resource-aware.',
        labelWeights: {
          SupportLabel.wellbeingCheckIn: 5,
          SupportLabel.planning: 3,
        },
        profileLabels: [
          'mental_health_support',
          'adhd_support',
          'stress_sensitive'
        ],
      ),
      OnboardingOption(
        id: 'accessibility_prefer_not',
        title: 'Prefer not to specify',
        description: 'Use general stress-sensitive planning.',
        labelWeights: {
          SupportLabel.wellbeingCheckIn: 2,
          SupportLabel.planning: 1,
        },
        profileLabels: ['stress_sensitive'],
      ),
    ],
  ),
  OnboardingQuestion(
    id: 'career_focus',
    title: 'How much career support do you want?',
    description: 'This helps ORBIT route internships and resumes.',
    visibleWhenOptionIds: [
      'job_internship_work',
      'career_active',
      'career_exploring',
      'undergrad_upper',
      'cs_engineering',
    ],
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
    visibleWhenOptionIds: [
      'incoming_student',
      'first_generation',
      'international_student',
      'campus_events_groups',
      'campus_walking',
      'commuter',
    ],
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

List<OnboardingQuestion> visibleOnboardingQuestions(
  Map<String, String> selections,
) {
  return onboardingQuestions
      .where((question) => question.isVisible(selections))
      .toList(growable: false);
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
