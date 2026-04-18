import 'package:chatbotapp/data_sources/http_json_client.dart';
import 'package:chatbotapp/data_sources/integration_config.dart';
import 'package:chatbotapp/data_sources/student_data_models.dart';

class GoogleRoutesDataSource {
  GoogleRoutesDataSource({
    IntegrationConfig? config,
    HttpJsonClient? httpClient,
  })  : config = config ?? IntegrationConfig.fromEnvironment(),
        _httpClient = httpClient ?? HttpJsonClient();

  final IntegrationConfig config;
  final HttpJsonClient _httpClient;

  bool get isConfigured => config.hasGoogleMaps;

  Future<List<CampusRoute>> fetchDefaultCampusRoutes() async {
    if (!isConfigured) {
      return const [];
    }

    final route = await computeRoute(
      origin: config.defaultCampusOrigin,
      destination: config.defaultCampusDestination,
      travelMode: 'WALK',
    );
    return route == null ? const [] : [route];
  }

  Future<CampusRoute?> computeRoute({
    required String origin,
    required String destination,
    String travelMode = 'WALK',
  }) async {
    if (!isConfigured) {
      return null;
    }

    final uri = Uri.https(
      'routes.googleapis.com',
      '/directions/v2:computeRoutes',
    );
    final decoded = await _httpClient.postJson(
      uri,
      headers: {
        'X-Goog-Api-Key': config.googleMapsApiKey,
        'X-Goog-FieldMask':
            'routes.duration,routes.distanceMeters,routes.localizedValues',
      },
      body: {
        'origin': {
          'address': origin,
        },
        'destination': {
          'address': destination,
        },
        'travelMode': travelMode,
        'languageCode': 'en-US',
        'units': 'IMPERIAL',
      },
      timeout: config.requestTimeout,
    );

    if (decoded is! Map<String, dynamic>) {
      return null;
    }
    final routes = decoded['routes'];
    if (routes is! List || routes.isEmpty) {
      return null;
    }
    final first = routes.first;
    if (first is! Map<String, dynamic>) {
      return null;
    }

    return CampusRoute(
      origin: origin,
      destination: destination,
      travelMode: travelMode.toLowerCase(),
      duration: _parseDuration(first['duration']),
      distanceMeters: _parseInt(first['distanceMeters']),
    );
  }

  Duration? _parseDuration(dynamic value) {
    if (value is! String || !value.endsWith('s')) {
      return null;
    }
    final seconds = double.tryParse(value.substring(0, value.length - 1));
    if (seconds == null) {
      return null;
    }
    return Duration(milliseconds: (seconds * 1000).round());
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
}
