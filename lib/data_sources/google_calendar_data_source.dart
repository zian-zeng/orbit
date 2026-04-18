import 'package:chatbotapp/data_sources/http_json_client.dart';
import 'package:chatbotapp/data_sources/integration_config.dart';
import 'package:chatbotapp/data_sources/student_data_models.dart';

class GoogleCalendarDataSource {
  GoogleCalendarDataSource({
    IntegrationConfig? config,
    HttpJsonClient? httpClient,
  })  : config = config ?? IntegrationConfig.fromEnvironment(),
        _httpClient = httpClient ?? HttpJsonClient();

  final IntegrationConfig config;
  final HttpJsonClient _httpClient;

  bool get isConfigured => config.hasGoogleCalendar;

  Future<List<StudentCalendarEvent>> fetchUpcomingEvents({
    Duration horizon = const Duration(days: 7),
  }) async {
    if (!isConfigured) {
      return const [];
    }

    final now = DateTime.now().toUtc();
    final uri = Uri.https(
      'www.googleapis.com',
      '/calendar/v3/calendars/primary/events',
      {
        'singleEvents': 'true',
        'orderBy': 'startTime',
        'timeMin': now.toIso8601String(),
        'timeMax': now.add(horizon).toIso8601String(),
        'maxResults': '40',
      },
    );

    final decoded = await _httpClient.getJson(
      uri,
      headers: _headers,
      timeout: config.requestTimeout,
    );
    if (decoded is! Map<String, dynamic>) {
      return const [];
    }
    final items = decoded['items'];
    if (items is! List) {
      return const [];
    }

    return items
        .whereType<Map<String, dynamic>>()
        .map(
          (item) => StudentCalendarEvent(
            id: item['id']?.toString() ?? '',
            title: (item['summary'] as String?)?.trim().isNotEmpty == true
                ? item['summary'] as String
                : 'Busy',
            start: _parseEventTime(item['start']),
            end: _parseEventTime(item['end']),
            location: item['location'] as String?,
          ),
        )
        .where((event) => event.id.isNotEmpty)
        .toList(growable: false);
  }

  Map<String, String> get _headers => {
        'Authorization': 'Bearer ${config.googleAccessToken}',
        'Accept': 'application/json',
      };

  DateTime? _parseEventTime(dynamic value) {
    if (value is! Map<String, dynamic>) {
      return null;
    }
    final dateTime = value['dateTime'];
    if (dateTime is String) {
      return DateTime.tryParse(dateTime);
    }
    final date = value['date'];
    if (date is String) {
      return DateTime.tryParse(date);
    }
    return null;
  }
}
