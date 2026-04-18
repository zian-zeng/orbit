import 'package:chatbotapp/data_sources/http_json_client.dart';
import 'package:chatbotapp/data_sources/integration_config.dart';
import 'package:chatbotapp/data_sources/student_data_models.dart';

class CanvasDataSource {
  CanvasDataSource({
    IntegrationConfig? config,
    HttpJsonClient? httpClient,
  })  : config = config ?? IntegrationConfig.fromEnvironment(),
        _httpClient = httpClient ?? HttpJsonClient();

  final IntegrationConfig config;
  final HttpJsonClient _httpClient;

  bool get isConfigured => config.hasCanvas;

  Future<List<StudentAssignment>> fetchUpcomingAssignments() async {
    if (!isConfigured) {
      return const [];
    }

    final courses = await _fetchActiveCourses();
    final assignments = <StudentAssignment>[];

    for (final course in courses.take(8)) {
      final courseId = course['id']?.toString();
      if (courseId == null || courseId.isEmpty) {
        continue;
      }

      final courseAssignments = await _fetchCourseAssignments(
        courseId: courseId,
        courseName: course['name'] as String?,
      );
      assignments.addAll(courseAssignments);
    }

    assignments.sort((a, b) {
      final left = a.dueAt;
      final right = b.dueAt;
      if (left == null && right == null) {
        return a.name.compareTo(b.name);
      }
      if (left == null) {
        return 1;
      }
      if (right == null) {
        return -1;
      }
      return left.compareTo(right);
    });
    return assignments.take(40).toList(growable: false);
  }

  Future<List<Map<String, dynamic>>> _fetchActiveCourses() async {
    final uri = _canvasUri('/api/v1/courses', {
      'enrollment_state': 'active',
      'per_page': '50',
    });
    final decoded = await _httpClient.getJson(
      uri,
      headers: _headers,
      timeout: config.requestTimeout,
    );
    if (decoded is! List) {
      return const [];
    }
    return decoded.whereType<Map<String, dynamic>>().toList(growable: false);
  }

  Future<List<StudentAssignment>> _fetchCourseAssignments({
    required String courseId,
    required String? courseName,
  }) async {
    final uri = _canvasUri('/api/v1/courses/$courseId/assignments', {
      'bucket': 'upcoming',
      'order_by': 'due_at',
      'per_page': '50',
    });
    final decoded = await _httpClient.getJson(
      uri,
      headers: _headers,
      timeout: config.requestTimeout,
    );
    if (decoded is! List) {
      return const [];
    }
    return decoded
        .whereType<Map<String, dynamic>>()
        .map(
          (item) => StudentAssignment(
            id: item['id']?.toString() ?? '',
            courseId: courseId,
            courseName: courseName,
            name: (item['name'] as String?)?.trim().isNotEmpty == true
                ? item['name'] as String
                : 'Untitled assignment',
            dueAt: _parseDateTime(item['due_at']),
            pointsPossible: _parseDouble(item['points_possible']),
            htmlUrl: item['html_url'] as String?,
          ),
        )
        .where((assignment) => assignment.id.isNotEmpty)
        .toList(growable: false);
  }

  Uri _canvasUri(String path, Map<String, String> query) {
    final base = Uri.parse(config.canvasBaseUrl);
    return base.replace(
      path: path,
      queryParameters: query,
    );
  }

  Map<String, String> get _headers => {
        'Authorization': 'Bearer ${config.canvasAccessToken}',
        'Accept': 'application/json',
      };

  DateTime? _parseDateTime(dynamic value) {
    if (value is! String || value.trim().isEmpty) {
      return null;
    }
    return DateTime.tryParse(value);
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
}
