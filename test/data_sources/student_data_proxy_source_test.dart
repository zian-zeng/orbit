import 'package:chatbotapp/data_sources/http_json_client.dart';
import 'package:chatbotapp/data_sources/integration_config.dart';
import 'package:chatbotapp/data_sources/student_data_proxy_source.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('parses proxy snapshot into app student signal models', () async {
    final httpClient = _FakeHttpJsonClient();
    final dataSource = StudentDataProxySource(
      config: _config(),
      httpClient: httpClient,
    );

    final snapshot = await dataSource.fetchSnapshot(
      taskText: 'Find vegan food near class',
      preferenceTags: const ['vegan', 'commuter'],
    );

    expect(httpClient.lastUri.path, '/student/snapshot');
    expect(httpClient.lastUri.queryParameters['userId'], 'demo');
    expect(httpClient.lastUri.queryParameters['taskText'], contains('vegan'));
    expect(
        httpClient.lastUri.queryParameters['preferenceTags'], 'vegan,commuter');
    expect(snapshot.assignments.single.name, 'CMSC project');
    expect(snapshot.calendarEvents.single.title, 'Study group');
    expect(snapshot.routes.single.duration!.inMinutes, 12);
    expect(snapshot.places.single.servesVegetarianFood, isTrue);
    expect(snapshot.sourceNotes, contains('Proxy loaded Canvas and Calendar.'));
    expect(snapshot.inferredLabelKeys, contains('life_logistics'));
  });

  test('returns empty snapshot when proxy is not configured', () async {
    final dataSource = StudentDataProxySource(
      config: _config(studentDataProxyUrl: ''),
      httpClient: _FakeHttpJsonClient(),
    );

    final snapshot = await dataSource.fetchSnapshot(
      taskText: 'anything',
      preferenceTags: const [],
    );

    expect(snapshot.assignments, isEmpty);
    expect(snapshot.sourceNotes.single, contains('not configured'));
  });
}

IntegrationConfig _config({
  String studentDataProxyUrl = 'http://127.0.0.1:8787',
}) {
  return IntegrationConfig(
    externalDataEnabled: true,
    studentDataProxyUrl: studentDataProxyUrl,
    canvasBaseUrl: IntegrationConfig.umdCanvasBaseUrl,
    canvasAccessToken: '',
    googleAccessToken: '',
    googleMapsApiKey: '',
    defaultCampusOrigin: IntegrationConfig.defaultOrigin,
    defaultCampusDestination: IntegrationConfig.defaultDestination,
    cacheTtl: const Duration(minutes: 5),
    requestTimeout: const Duration(seconds: 2),
  );
}

class _FakeHttpJsonClient extends HttpJsonClient {
  Uri lastUri = Uri();

  @override
  Future<dynamic> getJson(
    Uri uri, {
    Map<String, String> headers = const {},
    Duration timeout = const Duration(seconds: 12),
  }) async {
    lastUri = uri;
    return {
      'fetchedAt': '2026-04-18T12:00:00Z',
      'assignments': [
        {
          'id': 'a1',
          'courseId': 'cmsc132',
          'courseName': 'Object-Oriented Programming II',
          'name': 'CMSC project',
          'dueAt': '2026-04-20T23:59:00Z',
          'pointsPossible': 100,
          'htmlUrl': 'https://umd.instructure.com/courses/1/assignments/1',
        },
      ],
      'calendarEvents': [
        {
          'id': 'e1',
          'title': 'Study group',
          'start': '2026-04-18T14:00:00Z',
          'end': '2026-04-18T15:30:00Z',
          'location': 'McKeldin Library',
        },
      ],
      'routes': [
        {
          'origin': 'McKeldin Library',
          'destination': 'UMD Health Center',
          'travelMode': 'walk',
          'durationSeconds': 720,
          'distanceMeters': 850,
        },
      ],
      'places': [
        {
          'name': 'Plant Cafe',
          'formattedAddress': 'College Park, MD',
          'reason': 'Matched vegan profile.',
          'googleMapsUri': 'https://maps.google.com/example',
          'servesVegetarianFood': true,
        },
      ],
      'sourceNotes': ['Proxy loaded Canvas and Calendar.'],
    };
  }
}
