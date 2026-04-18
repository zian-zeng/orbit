class UmdResource {
  const UmdResource({
    required this.id,
    required this.name,
    required this.category,
    required this.summary,
    required this.tags,
    this.url,
  });

  final String id;
  final String name;
  final String category;
  final String summary;
  final List<String> tags;
  final String? url;
}

class UmdResourceCatalog {
  const UmdResourceCatalog();

  static const List<UmdResource> resources = [
    UmdResource(
      id: 'umd.ads',
      name: 'Accessibility and Disability Service',
      category: 'Academic accommodation',
      summary:
          'Support path for accommodations, accessibility barriers, testing needs, and disability-related academic planning.',
      url: 'https://ads.umd.edu/',
      tags: [
        'adhd',
        'accessibility',
        'accommodation',
        'exam',
        'deadline',
        'study_help',
        'planning',
      ],
    ),
    UmdResource(
      id: 'umd.counseling_center',
      name: 'Counseling Center',
      category: 'Mental health and wellbeing',
      summary:
          'Starting point for counseling, crisis consultation, stress support, and wellbeing referrals.',
      url: 'https://counseling.umd.edu/get-help-now',
      tags: [
        'stress',
        'wellbeing',
        'overwhelmed',
        'anxious',
        'burnout',
        'crisis',
        'mental_health',
        'wellbeing_checkin',
      ],
    ),
    UmdResource(
      id: 'umd.tltc',
      name: 'Teaching and Learning Transformation Center',
      category: 'Learning support',
      summary:
          'Academic success support for study strategies, learning habits, and course-support programs.',
      url: 'https://tltc.umd.edu/welcome-learning-success',
      tags: [
        'study',
        'course',
        'class',
        'learning',
        'exam',
        'study_help',
      ],
    ),
    UmdResource(
      id: 'umd.career_center',
      name: 'University Career Center',
      category: 'Career planning',
      summary:
          'Career coaching path for resumes, internships, interviews, networking, and job-search planning.',
      url: 'https://careers.umd.edu/',
      tags: [
        'career',
        'internship',
        'resume',
        'interview',
        'job',
        'planning',
      ],
    ),
    UmdResource(
      id: 'umd.health_center',
      name: 'University Health Center',
      category: 'Health and recovery',
      summary:
          'Health-service anchor for care navigation, recovery planning, and wellbeing routines around campus.',
      url: 'https://health.umd.edu/',
      tags: [
        'health',
        'wellness',
        'recovery',
        'hydration',
        'walk',
        'wellbeing_checkin',
      ],
    ),
    UmdResource(
      id: 'umd.dining_services',
      name: 'UMD Dining Services',
      category: 'Food and dietary needs',
      summary:
          'Campus dining anchor for meal planning, dining halls, dietary preference filtering, and allergy-aware food decisions.',
      url: 'https://dining.umd.edu/allergy',
      tags: [
        'food',
        'meal',
        'dining',
        'nutrition',
        'vegan',
        'vegetarian',
        'halal',
        'kosher',
        'gluten_free',
        'food_allergy',
        'allergy',
        'plant_based',
        'life_logistics',
      ],
    ),
    UmdResource(
      id: 'umd.campus_pantry',
      name: 'Campus Pantry',
      category: 'Food security',
      summary:
          'Support path for students who need low-cost food access or help managing food insecurity.',
      url: 'https://dining.umd.edu/sustainability/campus-pantry',
      tags: [
        'food',
        'budget',
        'money',
        'pantry',
        'financial_stress',
        'life_logistics',
      ],
    ),
    UmdResource(
      id: 'umd.reslife',
      name: 'Resident Life',
      category: 'Housing and campus living',
      summary:
          'Campus-living support for residence halls, roommate friction, move-in questions, and housing logistics.',
      url: 'https://reslife.umd.edu/',
      tags: [
        'housing',
        'roommate',
        'move',
        'dorm',
        'residence',
        'life_logistics',
      ],
    ),
    UmdResource(
      id: 'umd.dots',
      name: 'Department of Transportation Services',
      category: 'Transportation',
      summary:
          'Transportation anchor for parking, shuttle, biking, commute, and campus mobility planning.',
      url: 'https://transportation.umd.edu/shuttle-um-faq',
      tags: [
        'transport',
        'commute',
        'parking',
        'shuttle',
        'bus',
        'bike',
        'route',
        'schedule',
        'transit_app',
        'campus_navigation',
      ],
    ),
    UmdResource(
      id: 'umd.isss',
      name: 'International Student and Scholar Services',
      category: 'International student support',
      summary:
          'International-student support for immigration logistics, campus adjustment, and administrative navigation.',
      url:
          'https://globalmaryland.umd.edu/offices/international-students-scholar-services',
      tags: [
        'international',
        'visa',
        'immigration',
        'incoming',
        'campus_resources',
      ],
    ),
    UmdResource(
      id: 'umd.writing_center',
      name: 'Writing Center',
      category: 'Writing support',
      summary:
          'Writing support for essays, class papers, applications, statements, and revision planning.',
      url: 'https://english.umd.edu/writing-programs/writing-center',
      tags: [
        'writing',
        'essay',
        'draft',
        'paper',
        'statement',
      ],
    ),
    UmdResource(
      id: 'umd.asts',
      name: 'Academic Success and Tutorial Services',
      category: 'Tutoring and academic support',
      summary:
          'Free peer tutoring path for many high-risk and gateway undergraduate courses.',
      url: 'https://tutoring.umd.edu/',
      tags: [
        'tutoring',
        'academic_success',
        'gateway',
        'hard_class',
        'study_help',
        'exam',
        'course',
      ],
    ),
    UmdResource(
      id: 'umd.gss',
      name: 'Guided Study Sessions',
      category: 'Course study groups',
      summary:
          'Regular group-review sessions for traditionally difficult courses.',
      url: 'https://tltc.umd.edu/students/guided-study-sessions',
      tags: [
        'guided_study',
        'study_group',
        'gss',
        'exam',
        'difficult_course',
        'study_help',
      ],
    ),
    UmdResource(
      id: 'umd.math_success',
      name: 'Math Success Program',
      category: 'Math support',
      summary:
          'Drop-in and small-group math coaching for UMD students in math and math-related courses.',
      url: 'https://tutoring.umd.edu/tutoring-resources/math',
      tags: [
        'math',
        'statistics',
        'matlab',
        'calculus',
        'exam',
        'study_help',
      ],
    ),
    UmdResource(
      id: 'umd.keystone',
      name: 'Keystone Center',
      category: 'Engineering academic support',
      summary:
          'Engineering study and tutoring anchor for foundational Clark School coursework.',
      url: 'https://eng.umd.edu/keystone/resources/center',
      tags: [
        'engineering',
        'keystone',
        'homework',
        'project',
        'study_help',
      ],
    ),
    UmdResource(
      id: 'umd.omse',
      name: 'Office of Multi-Ethnic Student Education',
      category: 'Academic and belonging support',
      summary:
          'Academic support and tutorial programs for writing, math, biology, chemistry, economics, and student success.',
      url: 'https://omse.umd.edu/',
      tags: [
        'omse',
        'belonging',
        'first_gen_support',
        'tutoring',
        'study_help',
        'campus_resources',
      ],
    ),
    UmdResource(
      id: 'umd.student_legal_aid',
      name: 'Undergraduate Student Legal Aid Office',
      category: 'Legal and conduct support',
      summary:
          'Free legal advice and university charge assistance for eligible undergraduate students.',
      url: 'https://undergradlegalaid.umd.edu/',
      tags: [
        'legal',
        'lease',
        'landlord',
        'traffic',
        'conduct',
        'charge',
        'housing',
        'life_logistics',
      ],
    ),
    UmdResource(
      id: 'umd.student_crisis_fund',
      name: 'Student Crisis Fund',
      category: 'Emergency financial support',
      summary:
          'Emergency financial support path for urgent student needs affecting enrollment, housing, food, or safety.',
      url:
          'https://studentaffairs.umd.edu/division-of-student-affairs-crisis-fund',
      tags: [
        'crisis',
        'emergency',
        'money',
        'financial_stress',
        'rent',
        'food',
        'life_logistics',
      ],
    ),
    UmdResource(
      id: 'umd.financial_aid',
      name: 'Office of Student Financial Aid',
      category: 'Financial aid',
      summary:
          'Financial-aid support for aid questions, scholarships, costs, and documentation.',
      url: 'https://financialaid.umd.edu/',
      tags: [
        'financial_aid',
        'scholarship',
        'fafsa',
        'tuition',
        'money',
        'financial_stress',
      ],
    ),
    UmdResource(
      id: 'umd.dean_of_students',
      name: 'Dean of Students Office',
      category: 'Student support navigation',
      summary:
          'Navigation point for complex student issues, resources, advocacy, and support referrals.',
      url: 'https://deanofstudents.umd.edu/',
      tags: [
        'dean',
        'ombuds',
        'advocacy',
        'basic_needs',
        'essential_needs',
        'complex_issue',
        'campus_resources',
      ],
    ),
    UmdResource(
      id: 'umd.registrar',
      name: 'Office of the Registrar',
      category: 'Academic records and enrollment',
      summary:
          'Support path for registration, enrollment, transcripts, academic records, and schedule logistics.',
      url: 'https://registrar.umd.edu/',
      tags: [
        'registrar',
        'registration',
        'transcript',
        'drop',
        'add',
        'enrollment',
        'planning',
      ],
    ),
    UmdResource(
      id: 'umd.care_stop_violence',
      name: 'CARE to Stop Violence',
      category: 'Confidential advocacy',
      summary:
          'Confidential advocacy and therapy support for power-based violence, relationship violence, stalking, and sexual harassment.',
      url: 'https://health.umd.edu/node/39',
      tags: [
        'care',
        'violence',
        'stalking',
        'relationship',
        'confidential',
        'crisis',
        'safety',
        'wellbeing_checkin',
      ],
    ),
    UmdResource(
      id: 'umd.ocrsm',
      name: 'Office of Civil Rights and Sexual Misconduct',
      category: 'Civil rights and Title IX',
      summary:
          'University office for discrimination, harassment, sexual misconduct, Title IX, and rights-related support.',
      url: 'https://ocrsm.umd.edu/resources',
      tags: [
        'title_ix',
        'discrimination',
        'harassment',
        'civil_rights',
        'misconduct',
        'safety',
        'campus_resources',
      ],
    ),
    UmdResource(
      id: 'umd.nite_ride',
      name: 'NITE Ride',
      category: 'Overnight transportation',
      summary:
          'Shuttle-UM overnight service for campus areas not covered by evening routes.',
      url: 'https://transportation.umd.edu/shuttle-um/nite-ride',
      tags: [
        'nite_ride',
        'terp_ride',
        'night',
        'late',
        'safety',
        'transport',
        'shuttle',
        'campus_navigation',
      ],
    ),
    UmdResource(
      id: 'umd.paratransit',
      name: 'Shuttle-UM Paratransit',
      category: 'Accessible transportation',
      summary:
          'Curb-to-curb Shuttle-UM service for students, faculty, staff, and visitors with temporary or permanent disabilities.',
      url: 'https://transportation.umd.edu/shuttle-um/paratransit',
      tags: [
        'paratransit',
        'terp_ride',
        'accessibility',
        'temporary_injury',
        'disability',
        'transport',
        'campus_navigation',
      ],
    ),
    UmdResource(
      id: 'umd.terp_ride',
      name: 'Terp Ride App',
      category: 'Transportation apps',
      summary:
          'Official app path for scheduling NITE Ride and Paratransit services.',
      url: 'https://transportation.umd.edu/terp-ride',
      tags: [
        'terp_ride',
        'app',
        'nite_ride',
        'paratransit',
        'late',
        'transport',
        'campus_navigation',
      ],
    ),
    UmdResource(
      id: 'umd.guardian_app',
      name: 'UMD Guardian App',
      category: 'Campus safety',
      summary:
          'Safety app that connects students with UMPD, trusted contacts, and emergency support.',
      url: 'https://umpd.umd.edu/resources/safety-information/guardian-app',
      tags: [
        'guardian',
        'safety',
        'emergency',
        'escort',
        'umpd',
        'night',
        'campus_resources',
      ],
    ),
    UmdResource(
      id: 'umd.help_center',
      name: 'Help Center at UMD',
      category: 'Peer support',
      summary:
          'Student-run peer counseling and crisis intervention hotline for anonymous, confidential support.',
      url: 'https://helpcenterumd.org/',
      tags: [
        'help_center',
        'peer',
        'hotline',
        'anonymous',
        'confidential',
        'stress',
        'crisis',
        'wellbeing_checkin',
      ],
    ),
  ];

  List<UmdResource> match({
    required String message,
    required Iterable<String> labels,
    int limit = 3,
  }) {
    final text = message.toLowerCase();
    final labelSet = labels.map((label) => label.toLowerCase()).toSet();
    final scored = resources
        .map((resource) {
          final tagMatches = resource.tags
              .where((tag) => text.contains(tag) || labelSet.contains(tag))
              .length;
          final nameMatches =
              text.contains(resource.name.toLowerCase()) ? 2 : 0;
          return _ScoredResource(
            resource: resource,
            score: tagMatches + nameMatches,
          );
        })
        .where((item) => item.score > 0)
        .toList(growable: false)
      ..sort((a, b) => b.score.compareTo(a.score));

    if (scored.isEmpty) {
      return resources.take(limit).toList(growable: false);
    }

    return scored
        .take(limit)
        .map((item) => item.resource)
        .toList(growable: false);
  }
}

class _ScoredResource {
  const _ScoredResource({
    required this.resource,
    required this.score,
  });

  final UmdResource resource;
  final int score;
}
