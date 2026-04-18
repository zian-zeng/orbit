import 'package:chatbotapp/data_sources/google_places_data_source.dart';
import 'package:chatbotapp/data_sources/http_json_client.dart';
import 'package:chatbotapp/data_sources/integration_config.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('uses vegan preference when building live food search', () async {
    final dataSource = GooglePlacesDataSource(
      config: _config(),
      httpClient: _FakeHttpJsonClient(),
    );

    final places = await dataSource.searchStudentPlaces(
      message: 'I need food near campus',
      preferenceTags: const ['vegan'],
    );

    expect(places, hasLength(1));
    expect(places.first.name, 'Plant Cafe');
    expect(places.first.reason, contains('vegan food'));
  });

  test('does not call live search for non-place tasks', () async {
    final httpClient = _FakeHttpJsonClient();
    final dataSource = GooglePlacesDataSource(
      config: _config(),
      httpClient: httpClient,
    );

    final places = await dataSource.searchStudentPlaces(
      message: 'Help me understand my exam notes',
      preferenceTags: const ['vegan'],
    );

    expect(places, isEmpty);
    expect(httpClient.postCount, 0);
  });

  test('uses dietary preference stated in the current task', () async {
    final dataSource = GooglePlacesDataSource(
      config: _config(),
      httpClient: _FakeHttpJsonClient(expectedQuery: 'vegan food'),
    );

    final places = await dataSource.searchStudentPlaces(
      message: 'I am vegan and need lunch near campus',
      preferenceTags: const [],
    );

    expect(places.single.reason, contains('vegan food'));
  });
}

IntegrationConfig _config() {
  return const IntegrationConfig(
    externalDataEnabled: true,
    studentDataProxyUrl: '',
    canvasBaseUrl: IntegrationConfig.umdCanvasBaseUrl,
    canvasAccessToken: '',
    googleAccessToken: '',
    googleMapsApiKey: 'maps-key',
    defaultCampusOrigin: IntegrationConfig.defaultOrigin,
    defaultCampusDestination: IntegrationConfig.defaultDestination,
    cacheTtl: Duration(minutes: 5),
    requestTimeout: Duration(seconds: 2),
  );
}

class _FakeHttpJsonClient extends HttpJsonClient {
  _FakeHttpJsonClient({this.expectedQuery = 'vegan food'});

  final String expectedQuery;
  int postCount = 0;

  @override
  Future<dynamic> postJson(
    Uri uri, {
    required Map<String, dynamic> body,
    Map<String, String> headers = const {},
    Duration timeout = const Duration(seconds: 12),
  }) async {
    postCount++;
    expect(body['textQuery'], contains(expectedQuery));
    expect(headers['X-Goog-FieldMask'], contains('places.displayName'));
    return {
      'places': [
        {
          'displayName': {'text': 'Plant Cafe'},
          'formattedAddress': 'College Park, MD',
          'googleMapsUri': 'https://maps.google.com/example',
          'servesVegetarianFood': true,
        },
      ],
    };
  }
}
