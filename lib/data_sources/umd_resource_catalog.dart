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
      tags: [
        'stress',
        'wellbeing',
        'overwhelmed',
        'anxious',
        'burnout',
        'wellbeing_checkin',
      ],
    ),
    UmdResource(
      id: 'umd.tltc',
      name: 'Teaching and Learning Transformation Center',
      category: 'Learning support',
      summary:
          'Academic success support for study strategies, learning habits, and course-support programs.',
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
      tags: [
        'food',
        'meal',
        'dining',
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
      tags: [
        'transport',
        'commute',
        'parking',
        'shuttle',
        'bus',
        'bike',
        'campus_navigation',
      ],
    ),
    UmdResource(
      id: 'umd.isss',
      name: 'International Student and Scholar Services',
      category: 'International student support',
      summary:
          'International-student support for immigration logistics, campus adjustment, and administrative navigation.',
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
      tags: [
        'writing',
        'essay',
        'draft',
        'paper',
        'statement',
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
