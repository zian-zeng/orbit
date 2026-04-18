import 'package:chatbotapp/data_sources/http_json_client.dart';
import 'package:chatbotapp/data_sources/integration_config.dart';
import 'package:chatbotapp/data_sources/student_data_models.dart';

class StudentDataProxySource {
  StudentDataProxySource({
    IntegrationConfig? config,
    HttpJsonClient? httpClient,
  })  : config = config ?? IntegrationConfig.fromEnvironment(),
        _httpClient = httpClient ?? HttpJsonClient();

  final IntegrationConfig config;
  final HttpJsonClient _httpClient;

  bool get isConfigured => config.hasStudentDataProxy;

  Future<StudentSignalSnapshot> fetchSnapshot({
    required String taskText,
    required Iterable<String> preferenceTags,
  }) async {
    if (!isConfigured) {
      return StudentSignalSnapshot.empty(
        sourceNotes: const ['Student data proxy is not configured.'],
      );
    }

    final base = Uri.parse(config.studentDataProxyUrl);
    final uri = base.replace(
      path: _joinPath(base.path, '/student/snapshot'),
      queryParameters: {
        'userId': config.studentDataProxyUserId,
        if (taskText.trim().isNotEmpty) 'taskText': taskText.trim(),
        if (preferenceTags.isNotEmpty)
          'preferenceTags': preferenceTags
              .map((tag) => tag.trim())
              .where((tag) => tag.isNotEmpty)
              .join(','),
      },
    );
    final decoded = await _httpClient.getJson(
      uri,
      timeout: config.requestTimeout,
    );
    if (decoded is! Map<String, dynamic>) {
      return StudentSignalSnapshot.empty(
        sourceNotes: const ['Student data proxy returned an empty snapshot.'],
      );
    }
    return _parseSnapshot(decoded);
  }

  StudentSignalSnapshot _parseSnapshot(Map<String, dynamic> json) {
    return StudentSignalSnapshot(
      fetchedAt: _parseDateTime(json['fetchedAt']) ?? DateTime.now(),
      assignments: _parseList(json['assignments'])
          .map(_parseAssignment)
          .whereType<StudentAssignment>()
          .toList(growable: false),
      calendarEvents: _parseList(json['calendarEvents'])
          .map(_parseCalendarEvent)
          .whereType<StudentCalendarEvent>()
          .toList(growable: false),
      routes: _parseList(json['routes'])
          .map(_parseRoute)
          .whereType<CampusRoute>()
          .toList(growable: false),
      places: _parseList(json['places'])
          .map(_parsePlace)
          .whereType<CampusPlace>()
          .toList(growable: false),
      sourceNotes: _parseStringList(json['sourceNotes'])
          .map((note) => note.toString())
          .where((note) => note.trim().isNotEmpty)
          .toList(growable: false),
    );
  }

  StudentAssignment? _parseAssignment(Map<String, dynamic> item) {
    final id = item['id']?.toString() ?? '';
    final name = item['name']?.toString() ?? '';
    if (id.isEmpty || name.trim().isEmpty) {
      return null;
    }
    return StudentAssignment(
      id: id,
      courseId: item['courseId']?.toString() ?? '',
      courseName: item['courseName']?.toString(),
      name: name,
      dueAt: _parseDateTime(item['dueAt']),
      pointsPossible: _parseDouble(item['pointsPossible']),
      htmlUrl: item['htmlUrl']?.toString(),
    );
  }

  StudentCalendarEvent? _parseCalendarEvent(Map<String, dynamic> item) {
    final id = item['id']?.toString() ?? '';
    final title =
        item['title']?.toString() ?? item['summary']?.toString() ?? '';
    if (id.isEmpty || title.trim().isEmpty) {
      return null;
    }
    return StudentCalendarEvent(
      id: id,
      title: title,
      start: _parseDateTime(item['start']),
      end: _parseDateTime(item['end']),
      location: item['location']?.toString(),
    );
  }

  CampusRoute? _parseRoute(Map<String, dynamic> item) {
    final origin = item['origin']?.toString() ?? '';
    final destination = item['destination']?.toString() ?? '';
    if (origin.trim().isEmpty || destination.trim().isEmpty) {
      return null;
    }
    return CampusRoute(
      origin: origin,
      destination: destination,
      travelMode: item['travelMode']?.toString() ?? 'walk',
      duration: _parseDuration(item['durationSeconds'] ?? item['duration']),
      distanceMeters: _parseInt(item['distanceMeters']),
    );
  }

  CampusPlace? _parsePlace(Map<String, dynamic> item) {
    final name = item['name']?.toString() ?? '';
    final address = item['formattedAddress']?.toString() ?? '';
    if (name.trim().isEmpty || address.trim().isEmpty) {
      return null;
    }
    return CampusPlace(
      name: name,
      formattedAddress: address,
      reason: item['reason']?.toString() ?? 'Matched the student context.',
      googleMapsUri: item['googleMapsUri']?.toString(),
      servesVegetarianFood: _parseBool(item['servesVegetarianFood']),
    );
  }

  List<Map<String, dynamic>> _parseList(dynamic value) {
    if (value is! List) {
      return const [];
    }
    return value.whereType<Map<String, dynamic>>().toList(growable: false);
  }

  List<dynamic> _parseStringList(dynamic value) {
    if (value is! List) {
      return const [];
    }
    return value;
  }

  String _joinPath(String basePath, String childPath) {
    final normalizedBase = basePath.endsWith('/')
        ? basePath.substring(0, basePath.length - 1)
        : basePath;
    return '$normalizedBase$childPath';
  }

  DateTime? _parseDateTime(dynamic value) {
    if (value is DateTime) {
      return value;
    }
    if (value is String && value.trim().isNotEmpty) {
      return DateTime.tryParse(value);
    }
    return null;
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

  int? _parseInt(dynamic value) {
    if (value is int) {
      return value;
    }
    if (value is num) {
      return value.round();
    }
    if (value is String) {
      return int.tryParse(value);
    }
    return null;
  }

  bool? _parseBool(dynamic value) {
    if (value is bool) {
      return value;
    }
    if (value is String) {
      final normalized = value.toLowerCase();
      if (normalized == 'true') {
        return true;
      }
      if (normalized == 'false') {
        return false;
      }
    }
    return null;
  }

  Duration? _parseDuration(dynamic value) {
    if (value is Duration) {
      return value;
    }
    if (value is num) {
      return Duration(seconds: value.round());
    }
    if (value is String) {
      final seconds = int.tryParse(value);
      if (seconds != null) {
        return Duration(seconds: seconds);
      }
      if (value.endsWith('s')) {
        final googleSeconds =
            double.tryParse(value.substring(0, value.length - 1));
        if (googleSeconds != null) {
          return Duration(milliseconds: (googleSeconds * 1000).round());
        }
      }
    }
    return null;
  }
}
