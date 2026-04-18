class UmdResource {
  const UmdResource({
    required this.id,
    required this.name,
    required this.category,
    required this.summary,
    required this.tags,
    this.whenToUse =
        'Use when the student need matches this category and live retrieval is unavailable.',
    this.eligibility = 'Check the official page for current eligibility.',
    this.action = 'Open the official resource page.',
    this.url,
  });

  final String id;
  final String name;
  final String category;
  final String summary;
  final List<String> tags;
  final String whenToUse;
  final String eligibility;
  final String action;
  final String? url;

  String get agentBrief {
    final linkText = url == null ? '' : ' Official page: $url';
    return '$name ($category): $summary Use when: $whenToUse Action: $action$linkText';
  }
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
      whenToUse:
          'A disability, injury, ADHD, testing barrier, or accessibility issue is affecting coursework.',
      eligibility:
          'UMD students seeking disability-related accommodations or accessibility support.',
      action:
          'Review ADS guidance and prepare documentation or accommodation questions.',
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
      whenToUse:
          'Stress, anxiety, crisis concern, burnout, or emotional pressure is affecting the student.',
      eligibility:
          'UMD students seeking counseling, consultation, crisis, or referral support.',
      action:
          'Use the get-help-now page for urgent options or schedule counseling support.',
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
      whenToUse:
          'The student asks about campus food, allergies, vegan/vegetarian needs, or dining choices.',
      eligibility:
          'UMD students and campus diners using dining halls or campus food resources.',
      action:
          'Open Dining guidance before recommending meals with dietary constraints.',
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
      whenToUse:
          'Food access, grocery cost, or food insecurity is part of the student problem.',
      eligibility:
          'UMD community members seeking pantry support; check official requirements.',
      action:
          'Review pantry access instructions and plan a discreet next step.',
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
      whenToUse:
          'The student asks about shuttle routes, parking, biking, commuting, or campus mobility.',
      eligibility:
          'UMD students, staff, faculty, and visitors using DOTS services.',
      action:
          'Open DOTS route, parking, or shuttle guidance for current details.',
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
      whenToUse:
          'A student needs course help, tutoring, exam prep, or gateway-class support.',
      eligibility:
          'UMD undergraduate students in supported courses; check current course coverage.',
      action:
          'Find the course support option and choose tutoring or study sessions.',
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
      whenToUse:
          'The student needs structured review for a difficult course before an exam or assignment.',
      eligibility:
          'UMD students in supported GSS courses; check current session listings.',
      action: 'Look up the course and attend the next guided study session.',
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
      whenToUse:
          'Lease, landlord, conduct, traffic, or legal uncertainty is interfering with school.',
      eligibility:
          'Eligible UMD undergraduate students; check the office page for scope and limits.',
      action:
          'Use Legal Aid to understand options before acting on legal issues.',
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
      whenToUse:
          'An urgent financial issue could affect enrollment, housing, food, safety, or continuity.',
      eligibility:
          'UMD students with qualifying urgent needs; check current fund requirements.',
      action:
          'Review the crisis fund process and prepare the urgent-need context.',
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
      whenToUse:
          'The issue spans multiple offices or the student does not know where to start.',
      eligibility:
          'UMD students seeking resource navigation or advocacy support.',
      action:
          'Use Dean of Students as the routing point for complex support needs.',
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
      whenToUse:
          'The student mentions relationship violence, stalking, sexual harassment, or power-based harm.',
      eligibility:
          'UMD community members seeking confidential advocacy or therapy support.',
      action:
          'Prioritize confidential support and avoid forcing disclosure details.',
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
      whenToUse:
          'The student asks about discrimination, harassment, sexual misconduct, or Title IX reporting.',
      eligibility:
          'UMD community members seeking civil rights or Title IX resources.',
      action:
          'Use OCRSM resources for reporting options, rights, and support pathways.',
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
      whenToUse:
          'The student needs late-night campus transportation or feels unsafe walking.',
      eligibility:
          'UMD campus riders using Shuttle-UM overnight services; check current service area.',
      action: 'Use NITE Ride or Terp Ride details before suggesting a route.',
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
      whenToUse:
          'Accessibility, temporary injury, or disability affects campus transportation.',
      eligibility:
          'Students, faculty, staff, and visitors with temporary or permanent disabilities.',
      action:
          'Use Paratransit scheduling guidance for accessible campus travel.',
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
      whenToUse:
          'The student wants late-night safety support, trusted-contact sharing, or emergency access.',
      eligibility: 'UMD community members using campus safety tools.',
      action: 'Set up Guardian before the student needs it during a late walk.',
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
      whenToUse:
          'The student wants anonymous peer support, a confidential hotline, or a lower-friction check-in.',
      eligibility:
          'Students seeking peer counseling or anonymous support; check service details.',
      action:
          'Use Help Center for peer support when the student wants to talk now.',
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
