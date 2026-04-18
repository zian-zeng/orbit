import 'package:flutter_dotenv/flutter_dotenv.dart';

class IntegrationConfig {
  const IntegrationConfig({
    required this.externalDataEnabled,
    required this.studentDataProxyUrl,
    this.studentDataProxyUserId = 'demo',
    required this.canvasBaseUrl,
    required this.canvasAccessToken,
    required this.googleAccessToken,
    required this.googleMapsApiKey,
    required this.defaultCampusOrigin,
    required this.defaultCampusDestination,
    required this.cacheTtl,
    required this.requestTimeout,
  });

  static const String umdCanvasBaseUrl = 'https://umd.instructure.com';
  static const String defaultOrigin = 'McKeldin Library, College Park, MD';
  static const String defaultDestination =
      'University Health Center, College Park, MD';
  static const Duration defaultCacheTtl = Duration(minutes: 5);
  static const Duration defaultRequestTimeout = Duration(seconds: 8);

  final bool externalDataEnabled;
  final String studentDataProxyUrl;
  final String studentDataProxyUserId;
  final String canvasBaseUrl;
  final String canvasAccessToken;
  final String googleAccessToken;
  final String googleMapsApiKey;
  final String defaultCampusOrigin;
  final String defaultCampusDestination;
  final Duration cacheTtl;
  final Duration requestTimeout;

  bool get hasCanvas =>
      externalDataEnabled &&
      canvasBaseUrl.startsWith('https://') &&
      canvasAccessToken.isNotEmpty;
  bool get hasStudentDataProxy =>
      externalDataEnabled &&
      (studentDataProxyUrl.startsWith('http://') ||
          studentDataProxyUrl.startsWith('https://'));
  bool get hasGoogleCalendar =>
      externalDataEnabled && googleAccessToken.isNotEmpty;
  bool get hasGoogleMaps => externalDataEnabled && googleMapsApiKey.isNotEmpty;
  bool get hasAnyRealData =>
      hasStudentDataProxy || hasCanvas || hasGoogleCalendar || hasGoogleMaps;

  static IntegrationConfig fromEnvironment() {
    return IntegrationConfig(
      externalDataEnabled: _boolValue(
        const String.fromEnvironment('EXTERNAL_DATA_ENABLED'),
        'EXTERNAL_DATA_ENABLED',
        false,
      ),
      studentDataProxyUrl: _value(
        const String.fromEnvironment('STUDENT_DATA_PROXY_URL'),
        'STUDENT_DATA_PROXY_URL',
        '',
      ),
      studentDataProxyUserId: _value(
        const String.fromEnvironment('STUDENT_DATA_PROXY_USER_ID'),
        'STUDENT_DATA_PROXY_USER_ID',
        'demo',
      ),
      canvasBaseUrl: _value(
        const String.fromEnvironment('CANVAS_BASE_URL'),
        'CANVAS_BASE_URL',
        umdCanvasBaseUrl,
      ),
      canvasAccessToken: _value(
        const String.fromEnvironment('CANVAS_ACCESS_TOKEN'),
        'CANVAS_ACCESS_TOKEN',
        '',
      ),
      googleAccessToken: _value(
        const String.fromEnvironment('GOOGLE_ACCESS_TOKEN'),
        'GOOGLE_ACCESS_TOKEN',
        '',
      ),
      googleMapsApiKey: _value(
        const String.fromEnvironment('GOOGLE_MAPS_API_KEY'),
        'GOOGLE_MAPS_API_KEY',
        '',
      ),
      defaultCampusOrigin: _value(
        const String.fromEnvironment('CAMPUS_ROUTE_ORIGIN'),
        'CAMPUS_ROUTE_ORIGIN',
        defaultOrigin,
      ),
      defaultCampusDestination: _value(
        const String.fromEnvironment('CAMPUS_ROUTE_DESTINATION'),
        'CAMPUS_ROUTE_DESTINATION',
        defaultDestination,
      ),
      cacheTtl: Duration(
        seconds: _intValue(
          const String.fromEnvironment('EXTERNAL_DATA_CACHE_SECONDS'),
          'EXTERNAL_DATA_CACHE_SECONDS',
          defaultCacheTtl.inSeconds,
        ),
      ),
      requestTimeout: Duration(
        seconds: _intValue(
          const String.fromEnvironment('EXTERNAL_DATA_TIMEOUT_SECONDS'),
          'EXTERNAL_DATA_TIMEOUT_SECONDS',
          defaultRequestTimeout.inSeconds,
        ),
      ),
    );
  }

  static String _value(
      String dartDefineValue, String envName, String fallback) {
    final defineValue = dartDefineValue.trim();
    if (defineValue.isNotEmpty) {
      return defineValue;
    }
    if (!dotenv.isInitialized) {
      return fallback;
    }
    final envValue = dotenv.env[envName]?.trim();
    return envValue == null || envValue.isEmpty ? fallback : envValue;
  }

  static bool _boolValue(
      String dartDefineValue, String envName, bool fallback) {
    final value = _value(dartDefineValue, envName, '$fallback').toLowerCase();
    return value == 'true' || value == '1' || value == 'yes';
  }

  static int _intValue(String dartDefineValue, String envName, int fallback) {
    final value = int.tryParse(_value(dartDefineValue, envName, '$fallback'));
    if (value == null || value <= 0) {
      return fallback;
    }
    return value;
  }
}
