import 'dart:async';

import 'package:chatbotapp/data_sources/canvas_data_source.dart';
import 'package:chatbotapp/data_sources/google_calendar_data_source.dart';
import 'package:chatbotapp/data_sources/google_places_data_source.dart';
import 'package:chatbotapp/data_sources/google_routes_data_source.dart';
import 'package:chatbotapp/data_sources/integration_config.dart';
import 'package:chatbotapp/data_sources/student_data_models.dart';

class StudentContextAggregator {
  factory StudentContextAggregator({
    IntegrationConfig? config,
    CanvasDataSource? canvasDataSource,
    GoogleCalendarDataSource? calendarDataSource,
    GooglePlacesDataSource? placesDataSource,
    GoogleRoutesDataSource? routesDataSource,
  }) {
    final resolvedConfig = config ?? IntegrationConfig.fromEnvironment();
    return StudentContextAggregator._(
      config: resolvedConfig,
      canvasDataSource:
          canvasDataSource ?? CanvasDataSource(config: resolvedConfig),
      calendarDataSource: calendarDataSource ??
          GoogleCalendarDataSource(config: resolvedConfig),
      placesDataSource:
          placesDataSource ?? GooglePlacesDataSource(config: resolvedConfig),
      routesDataSource:
          routesDataSource ?? GoogleRoutesDataSource(config: resolvedConfig),
    );
  }

  StudentContextAggregator._({
    required this.config,
    required CanvasDataSource canvasDataSource,
    required GoogleCalendarDataSource calendarDataSource,
    required GooglePlacesDataSource placesDataSource,
    required GoogleRoutesDataSource routesDataSource,
  })  : _canvasDataSource = canvasDataSource,
        _calendarDataSource = calendarDataSource,
        _placesDataSource = placesDataSource,
        _routesDataSource = routesDataSource;

  final IntegrationConfig config;
  final CanvasDataSource _canvasDataSource;
  final GoogleCalendarDataSource _calendarDataSource;
  final GooglePlacesDataSource _placesDataSource;
  final GoogleRoutesDataSource _routesDataSource;
  StudentSignalSnapshot? _cachedSnapshot;
  String _cachedSnapshotKey = '';
  Future<StudentSignalSnapshot>? _inFlightSnapshot;
  String _inFlightSnapshotKey = '';

  Future<StudentSignalSnapshot> loadSnapshot({
    Duration? timeout,
    bool forceRefresh = false,
    bool allowExternalData = true,
    String taskText = '',
    Iterable<String> preferenceTags = const [],
  }) async {
    final effectiveTimeout = timeout ?? config.requestTimeout;
    final cacheKey = _cacheKey(
      allowExternalData: allowExternalData,
      taskText: taskText,
      preferenceTags: preferenceTags,
    );
    final cached = _cachedSnapshot;
    if (!forceRefresh &&
        cached != null &&
        _cachedSnapshotKey == cacheKey &&
        !_isCacheExpired(cached)) {
      return cached;
    }

    final inFlight = _inFlightSnapshot;
    if (!forceRefresh && inFlight != null && _inFlightSnapshotKey == cacheKey) {
      return inFlight;
    }

    final request = _loadSnapshotUncached(
      timeout: effectiveTimeout,
      allowExternalData: allowExternalData,
      taskText: taskText,
      preferenceTags: preferenceTags,
    );
    _inFlightSnapshot = request;
    _inFlightSnapshotKey = cacheKey;
    try {
      final snapshot = await request;
      _cachedSnapshot = snapshot;
      _cachedSnapshotKey = cacheKey;
      return snapshot;
    } finally {
      if (identical(_inFlightSnapshot, request)) {
        _inFlightSnapshot = null;
        _inFlightSnapshotKey = '';
      }
    }
  }

  Future<StudentSignalSnapshot> _loadSnapshotUncached({
    required Duration timeout,
    required bool allowExternalData,
    required String taskText,
    required Iterable<String> preferenceTags,
  }) async {
    if (!allowExternalData) {
      return StudentSignalSnapshot.empty(
        sourceNotes: const [
          'Live student data is off. Enable Canvas/Google live data in Settings after getting consent.',
        ],
      );
    }

    if (!config.hasAnyRealData) {
      return StudentSignalSnapshot.empty(
        sourceNotes: [
          config.externalDataEnabled
              ? 'No real-data credentials configured. Using labels, chat history, and deterministic ORBIT signals.'
              : 'External data is disabled. Enable EXTERNAL_DATA_ENABLED for desktop/web real-data demos.',
        ],
      );
    }

    final sourceNotes = <String>[];
    final assignmentsFuture = _guarded(
      label: 'Canvas',
      sourceNotes: sourceNotes,
      fallback: const <StudentAssignment>[],
      fetch: _canvasDataSource.isConfigured
          ? _canvasDataSource.fetchUpcomingAssignments
          : null,
      timeout: timeout,
    );
    final eventsFuture = _guarded(
      label: 'Google Calendar',
      sourceNotes: sourceNotes,
      fallback: const <StudentCalendarEvent>[],
      fetch: _calendarDataSource.isConfigured
          ? _calendarDataSource.fetchUpcomingEvents
          : null,
      timeout: timeout,
    );
    final routesFuture = _guarded(
      label: 'Google Routes',
      sourceNotes: sourceNotes,
      fallback: const <CampusRoute>[],
      fetch: _routesDataSource.isConfigured
          ? _routesDataSource.fetchDefaultCampusRoutes
          : null,
      timeout: timeout,
    );
    final placesFuture = _guarded(
      label: 'Google Places',
      sourceNotes: sourceNotes,
      fallback: const <CampusPlace>[],
      fetch: _placesDataSource.isConfigured
          ? () => _placesDataSource.searchStudentPlaces(
                message: taskText,
                preferenceTags: preferenceTags,
              )
          : null,
      timeout: timeout,
    );

    final results = await Future.wait([
      assignmentsFuture,
      eventsFuture,
      routesFuture,
      placesFuture,
    ]).timeout(timeout);

    return StudentSignalSnapshot(
      fetchedAt: DateTime.now(),
      assignments: results[0] as List<StudentAssignment>,
      calendarEvents: results[1] as List<StudentCalendarEvent>,
      routes: results[2] as List<CampusRoute>,
      places: results[3] as List<CampusPlace>,
      sourceNotes: sourceNotes,
    );
  }

  Future<ExternalLabelImport> loadLabelImport({
    Duration? timeout,
    bool forceRefresh = false,
    bool allowExternalData = true,
    String taskText = '',
    Iterable<String> preferenceTags = const [],
  }) async {
    final snapshot = await loadSnapshot(
      timeout: timeout,
      forceRefresh: forceRefresh,
      allowExternalData: allowExternalData,
      taskText: taskText,
      preferenceTags: preferenceTags,
    );
    final labels = snapshot.inferredLabelKeys
        .where(
          (label) => const {
            'planning',
            'writing',
            'study_help',
            'summarization',
            'image_analysis',
            'wellbeing_checkin',
          }.contains(label),
        )
        .toList(growable: false);
    final sources = <String>[
      if (snapshot.assignments.isNotEmpty) 'Canvas',
      if (snapshot.calendarEvents.isNotEmpty) 'Google Calendar',
      if (snapshot.routes.isNotEmpty) 'Google Maps',
      if (snapshot.places.isNotEmpty) 'Google Places',
      if (snapshot.assignments.isEmpty &&
          snapshot.calendarEvents.isEmpty &&
          snapshot.routes.isEmpty &&
          snapshot.places.isEmpty)
        'Real Data',
    ];
    return ExternalLabelImport(
      labelKeys: labels,
      sourceName: sources.join(' + '),
      snapshot: snapshot,
    );
  }

  Future<List<T>> _guarded<T>({
    required String label,
    required List<String> sourceNotes,
    required List<T> fallback,
    required Future<List<T>> Function()? fetch,
    required Duration timeout,
  }) async {
    if (fetch == null) {
      sourceNotes.add('$label not configured.');
      return fallback;
    }

    try {
      return await fetch().timeout(timeout);
    } on TimeoutException {
      sourceNotes.add('$label fetch timed out.');
      return fallback;
    } catch (error) {
      sourceNotes.add('$label fetch failed: $error');
      return fallback;
    }
  }

  bool _isCacheExpired(StudentSignalSnapshot snapshot) {
    final ttl = config.cacheTtl;
    if (ttl <= Duration.zero) {
      return true;
    }
    return DateTime.now().difference(snapshot.fetchedAt) > ttl;
  }

  String _cacheKey({
    required bool allowExternalData,
    required String taskText,
    required Iterable<String> preferenceTags,
  }) {
    final normalizedTask = taskText.trim().toLowerCase();
    final normalizedTags = preferenceTags
        .map((tag) => tag.trim().toLowerCase())
        .where((tag) => tag.isNotEmpty)
        .toSet()
        .toList(growable: false)
      ..sort();
    return '$allowExternalData::$normalizedTask::${normalizedTags.join(',')}';
  }
}

class ExternalLabelImport {
  const ExternalLabelImport({
    required this.labelKeys,
    required this.sourceName,
    required this.snapshot,
  });

  final List<String> labelKeys;
  final String sourceName;
  final StudentSignalSnapshot snapshot;
}
