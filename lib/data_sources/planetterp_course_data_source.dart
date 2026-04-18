import 'package:chatbotapp/data_sources/http_json_client.dart';
import 'package:chatbotapp/models/course_planning.dart';

class PlanetterpCourseDataSource {
  PlanetterpCourseDataSource({HttpJsonClient? httpClient})
      : _httpClient = httpClient ?? HttpJsonClient();

  final HttpJsonClient _httpClient;

  Future<CourseCandidate?> fetchCourse({
    required String courseId,
    bool includeReviews = false,
  }) async {
    final normalized = courseId.trim().toUpperCase();
    if (normalized.isEmpty) {
      return null;
    }
    final uri = Uri.https('api.planetterp.com', '/v1/course', {
      'name': normalized,
      if (includeReviews) 'reviews': 'true',
    });
    final decoded = await _httpClient.getJson(uri);
    if (decoded is! Map<String, dynamic> || decoded.containsKey('error')) {
      return null;
    }
    final professors = _parseProfessorNames(decoded['professors'])
        .map(
          (name) => ProfessorSignal(
            name: name,
            sourceUrl: _professorUrl(name),
          ),
        )
        .toList(growable: false);
    return CourseCandidate(
      courseId: decoded['name']?.toString().toUpperCase() ?? normalized,
      title: decoded['title']?.toString() ?? normalized,
      credits: _parseCredits(decoded['credits']),
      requirementTag: 'candidate',
      workloadLevel: _workloadFromGpa(_parseDouble(decoded['average_gpa'])),
      projectLevel: 'unknown',
      averageGpa: _parseDouble(decoded['average_gpa']),
      description: decoded['description']?.toString() ?? '',
      sourceUrl: 'https://planetterp.com/course/$normalized',
      professors: professors,
      forumSignals: const [
        'Forum/reddit workload signals should be retrieved as corroborating evidence, not treated as ground truth.',
      ],
    );
  }

  Future<CourseCandidate?> fetchCourseWithProfessorSignals({
    required String courseId,
    int professorLimit = 6,
  }) async {
    final course = await fetchCourse(courseId: courseId);
    if (course == null) {
      return null;
    }
    final professorSignals = <ProfessorSignal>[];
    for (final professor in course.professors.take(professorLimit)) {
      final signal = await fetchProfessor(
        professorName: professor.name,
        includeReviews: true,
      );
      professorSignals.add(signal ?? professor);
    }
    return CourseCandidate(
      courseId: course.courseId,
      title: course.title,
      credits: course.credits,
      requirementTag: course.requirementTag,
      workloadLevel: course.workloadLevel,
      projectLevel: course.projectLevel,
      averageGpa: course.averageGpa,
      description: course.description,
      sourceUrl: course.sourceUrl,
      professors:
          professorSignals.isEmpty ? course.professors : professorSignals,
      forumSignals: course.forumSignals,
    );
  }

  Future<ProfessorSignal?> fetchProfessor({
    required String professorName,
    bool includeReviews = false,
  }) async {
    final name = professorName.trim();
    if (name.isEmpty) {
      return null;
    }
    final uri = Uri.https('api.planetterp.com', '/v1/professor', {
      'name': name,
      if (includeReviews) 'reviews': 'true',
    });
    final decoded = await _httpClient.getJson(uri);
    if (decoded is! Map<String, dynamic> || decoded.containsKey('error')) {
      return null;
    }
    final reviews = decoded['reviews'];
    return ProfessorSignal(
      name: decoded['name']?.toString() ?? name,
      averageRating: _parseDouble(decoded['average_rating']),
      reviewCount:
          reviews is List ? reviews.length : _parseInt(decoded['reviews']),
      averageGpa: _parseDouble(decoded['average_gpa']),
      sourceUrl: _professorUrl(decoded['slug']?.toString() ?? name),
      studentNotes: reviews is List
          ? reviews
              .whereType<Map<String, dynamic>>()
              .map((review) => review['review']?.toString() ?? '')
              .where((review) => review.trim().isNotEmpty)
              .take(3)
              .toList(growable: false)
          : const [],
    );
  }

  Future<List<Map<String, dynamic>>> fetchGrades({
    String? courseId,
    String? professorName,
    String? semester,
  }) async {
    final uri = Uri.https('api.planetterp.com', '/v1/grades', {
      if (courseId != null && courseId.trim().isNotEmpty)
        'course': courseId.trim().toUpperCase(),
      if (professorName != null && professorName.trim().isNotEmpty)
        'professor': professorName.trim(),
      if (semester != null && semester.trim().isNotEmpty)
        'semester': semester.trim(),
    });
    final decoded = await _httpClient.getJson(uri);
    if (decoded is! List) {
      return const [];
    }
    return decoded.whereType<Map<String, dynamic>>().toList(growable: false);
  }

  List<String> _parseProfessorNames(dynamic value) {
    if (value is! List) {
      return const [];
    }
    return value
        .map((item) => item.toString().trim())
        .where((item) => item.isNotEmpty)
        .toSet()
        .toList(growable: false);
  }

  int _parseCredits(dynamic value) {
    if (value is int) {
      return value;
    }
    if (value is num) {
      return value.round();
    }
    if (value is String) {
      final match = RegExp(r'\d+').firstMatch(value);
      if (match != null) {
        return int.tryParse(match.group(0)!) ?? 3;
      }
    }
    return 3;
  }

  double? _parseDouble(dynamic value) {
    if (value is num) {
      return value.toDouble();
    }
    if (value is String) {
      return double.tryParse(value);
    }
    return null;
  }

  int _parseInt(dynamic value) {
    if (value is int) {
      return value;
    }
    if (value is num) {
      return value.round();
    }
    if (value is String) {
      return int.tryParse(value) ?? 0;
    }
    return 0;
  }

  String _workloadFromGpa(double? gpa) {
    if (gpa == null) {
      return 'unknown';
    }
    if (gpa < 2.9) {
      return 'high';
    }
    if (gpa < 3.25) {
      return 'medium';
    }
    return 'moderate';
  }

  String _professorUrl(String value) {
    final slug = value
        .trim()
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]+'), '_')
        .replaceAll(RegExp(r'_+'), '_')
        .replaceAll(RegExp(r'^_|_$'), '');
    return 'https://planetterp.com/professor/$slug';
  }
}
