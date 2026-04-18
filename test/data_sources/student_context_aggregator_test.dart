import 'package:chatbotapp/data_sources/canvas_data_source.dart';
import 'package:chatbotapp/data_sources/google_calendar_data_source.dart';
import 'package:chatbotapp/data_sources/google_routes_data_source.dart';
import 'package:chatbotapp/data_sources/integration_config.dart';
import 'package:chatbotapp/data_sources/student_context_aggregator.dart';
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
}

IntegrationConfig _config({required bool externalDataEnabled}) {
  return IntegrationConfig(
    externalDataEnabled: externalDataEnabled,
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
