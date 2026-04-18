import 'package:chatbotapp/data_sources/canvas_data_source.dart';
import 'package:chatbotapp/data_sources/google_calendar_data_source.dart';
import 'package:chatbotapp/data_sources/google_routes_data_source.dart';
import 'package:chatbotapp/data_sources/integration_config.dart';
import 'package:chatbotapp/data_sources/student_context_aggregator.dart';
import 'package:chatbotapp/data_sources/student_data_proxy_source.dart';
import 'package:chatbotapp/data_sources/student_data_models.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('external data is opt-in for production safety', () async {
    final aggregator = StudentContextAggregator(
      config: _config(externalDataEnabled: false),
    );

    final snapshot = await aggregator.loadSnapshot();

    expect(snapshot.assignments, isEmpty);
    expect(snapshot.calendarEvents, isEmpty);
    expect(snapshot.routes, isEmpty);
    expect(snapshot.sourceNotes.single, contains('External data is disabled'));
  });

  test('caches real-data snapshots within the configured TTL', () async {
    final canvas = _FakeCanvasDataSource();
    final aggregator = StudentContextAggregator(
      config: _config(externalDataEnabled: true),
      canvasDataSource: canvas,
      calendarDataSource: _FakeCalendarDataSource(),
      routesDataSource: _FakeRoutesDataSource(),
    );

    final first = await aggregator.loadSnapshot();
    final second = await aggregator.loadSnapshot();

    expect(identical(first, second), isTrue);
    expect(canvas.callCount, 1);
    expect(first.inferredLabelKeys, contains('study_help'));
  });

  test('user consent gates live connector fetches', () async {
    final canvas = _FakeCanvasDataSource();
    final aggregator = StudentContextAggregator(
      config: _config(externalDataEnabled: true),
      canvasDataSource: canvas,
      calendarDataSource: _FakeCalendarDataSource(),
      routesDataSource: _FakeRoutesDataSource(),
    );

    final snapshot = await aggregator.loadSnapshot(allowExternalData: false);

    expect(snapshot.assignments, isEmpty);
    expect(canvas.callCount, 0);
    expect(snapshot.sourceNotes.single, contains('Live student data is off'));
  });

  test('consent state is part of the snapshot cache key', () async {
    final canvas = _FakeCanvasDataSource();
    final aggregator = StudentContextAggregator(
      config: _config(externalDataEnabled: true),
      canvasDataSource: canvas,
      calendarDataSource: _FakeCalendarDataSource(),
      routesDataSource: _FakeRoutesDataSource(),
    );

    await aggregator.loadSnapshot(allowExternalData: false);
    final live = await aggregator.loadSnapshot(allowExternalData: true);

    expect(live.assignments, isNotEmpty);
    expect(canvas.callCount, 1);
  });

  test('label import respects user consent', () async {
    final canvas = _FakeCanvasDataSource();
    final aggregator = StudentContextAggregator(
      config: _config(externalDataEnabled: true),
      canvasDataSource: canvas,
      calendarDataSource: _FakeCalendarDataSource(),
      routesDataSource: _FakeRoutesDataSource(),
    );

    final import = await aggregator.loadLabelImport(allowExternalData: false);

    expect(import.labelKeys, isEmpty);
    expect(import.sourceName, 'Real Data');
    expect(canvas.callCount, 0);
  });

  test('force refresh bypasses the cache', () async {
    final canvas = _FakeCanvasDataSource();
    final aggregator = StudentContextAggregator(
      config: _config(externalDataEnabled: true),
      canvasDataSource: canvas,
      calendarDataSource: _FakeCalendarDataSource(),
      routesDataSource: _FakeRoutesDataSource(),
    );

    await aggregator.loadSnapshot();
    await aggregator.loadSnapshot(forceRefresh: true);

    expect(canvas.callCount, 2);
  });

  test('configured student data proxy is preferred over direct connectors',
      () async {
    final canvas = _FakeCanvasDataSource();
    final proxy = _FakeProxyDataSource();
    final aggregator = StudentContextAggregator(
      config: _config(
        externalDataEnabled: true,
        studentDataProxyUrl: 'http://127.0.0.1:8787',
      ),
      canvasDataSource: canvas,
      calendarDataSource: _FakeCalendarDataSource(),
      routesDataSource: _FakeRoutesDataSource(),
      proxyDataSource: proxy,
    );

    final snapshot = await aggregator.loadSnapshot(
      taskText: 'I need vegan food before class',
      preferenceTags: const ['vegan'],
    );

    expect(proxy.callCount, 1);
    expect(canvas.callCount, 0);
    expect(snapshot.assignments.single.name, 'Proxy lab report');
    expect(snapshot.places.single.name, 'UMD Vegan Cafe');
    expect(
        snapshot.sourceNotes, contains('Loaded through student data proxy.'));
  });
}

IntegrationConfig _config({
  required bool externalDataEnabled,
  String studentDataProxyUrl = '',
}) {
  return IntegrationConfig(
    externalDataEnabled: externalDataEnabled,
    studentDataProxyUrl: studentDataProxyUrl,
    canvasBaseUrl: IntegrationConfig.umdCanvasBaseUrl,
    canvasAccessToken: externalDataEnabled ? 'canvas-token' : '',
    googleAccessToken: externalDataEnabled ? 'calendar-token' : '',
    googleMapsApiKey: externalDataEnabled ? 'maps-key' : '',
    defaultCampusOrigin: IntegrationConfig.defaultOrigin,
    defaultCampusDestination: IntegrationConfig.defaultDestination,
    cacheTtl: const Duration(minutes: 5),
    requestTimeout: const Duration(seconds: 2),
  );
}

class _FakeProxyDataSource extends StudentDataProxySource {
  _FakeProxyDataSource() : super(config: _config(externalDataEnabled: true));

  int callCount = 0;

  @override
  bool get isConfigured => true;

  @override
  Future<StudentSignalSnapshot> fetchSnapshot({
    required String taskText,
    required Iterable<String> preferenceTags,
  }) async {
    callCount++;
    expect(taskText, contains('vegan food'));
    expect(preferenceTags, contains('vegan'));
    return StudentSignalSnapshot(
      fetchedAt: DateTime.now(),
      assignments: [
        StudentAssignment(
          id: 'proxy-assignment',
          courseId: 'inst201',
          name: 'Proxy lab report',
          dueAt: DateTime.now().add(const Duration(days: 1)),
        ),
      ],
      calendarEvents: const [],
      routes: const [],
      places: const [
        CampusPlace(
          name: 'UMD Vegan Cafe',
          formattedAddress: 'College Park, MD',
          reason: 'Matched vegan profile.',
          servesVegetarianFood: true,
        ),
      ],
      sourceNotes: const ['Loaded through student data proxy.'],
    );
  }
}

class _FakeCanvasDataSource extends CanvasDataSource {
  _FakeCanvasDataSource() : super(config: _config(externalDataEnabled: true));

  int callCount = 0;

  @override
  bool get isConfigured => true;

  @override
  Future<List<StudentAssignment>> fetchUpcomingAssignments() async {
    callCount++;
    return [
      StudentAssignment(
        id: 'assignment-1',
        courseId: 'cmsc131',
        name: 'Project checkpoint',
        dueAt: DateTime.now().add(const Duration(days: 2)),
      ),
    ];
  }
}

class _FakeCalendarDataSource extends GoogleCalendarDataSource {
  _FakeCalendarDataSource() : super(config: _config(externalDataEnabled: true));

  @override
  bool get isConfigured => true;

  @override
  Future<List<StudentCalendarEvent>> fetchUpcomingEvents({
    Duration horizon = const Duration(days: 7),
  }) async {
    return const [];
  }
}

class _FakeRoutesDataSource extends GoogleRoutesDataSource {
  _FakeRoutesDataSource() : super(config: _config(externalDataEnabled: true));

  @override
  bool get isConfigured => true;

  @override
  Future<List<CampusRoute>> fetchDefaultCampusRoutes() async {
    return const [];
  }
}
