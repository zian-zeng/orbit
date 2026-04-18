import 'package:chatbotapp/data_sources/http_json_client.dart';
import 'package:chatbotapp/data_sources/integration_config.dart';
import 'package:chatbotapp/data_sources/student_data_models.dart';

class GooglePlacesDataSource {
  GooglePlacesDataSource({
    IntegrationConfig? config,
    HttpJsonClient? httpClient,
  })  : config = config ?? IntegrationConfig.fromEnvironment(),
        _httpClient = httpClient ?? HttpJsonClient();

  final IntegrationConfig config;
  final HttpJsonClient _httpClient;

  bool get isConfigured => config.hasGoogleMaps;

  Future<List<CampusPlace>> searchStudentPlaces({
    required String message,
    required Iterable<String> preferenceTags,
  }) async {
    if (!isConfigured || !_looksLikePlaceSearch(message)) {
      return const [];
    }

    final query = _buildQuery(
      message: message,
      preferenceTags: preferenceTags,
    );
    final uri = Uri.https('places.googleapis.com', '/v1/places:searchText');
    final decoded = await _httpClient.postJson(
      uri,
      headers: {
        'X-Goog-Api-Key': config.googleMapsApiKey,
        'X-Goog-FieldMask':
            'places.displayName,places.formattedAddress,places.googleMapsUri,places.servesVegetarianFood',
      },
      body: {
        'textQuery': query,
        'maxResultCount': 5,
        'languageCode': 'en',
        'regionCode': 'US',
      },
      timeout: config.requestTimeout,
    );

    if (decoded is! Map<String, dynamic>) {
      return const [];
    }
    final places = decoded['places'];
    if (places is! List) {
      return const [];
    }

    return places
        .whereType<Map<String, dynamic>>()
        .map(
          (place) => CampusPlace(
            name: _displayName(place),
            formattedAddress:
                (place['formattedAddress'] as String?) ?? 'Address unavailable',
            googleMapsUri: place['googleMapsUri'] as String?,
            servesVegetarianFood: place['servesVegetarianFood'] as bool?,
            reason: 'Matched live Google Places query: $query',
          ),
        )
        .where((place) => place.name.trim().isNotEmpty)
        .toList(growable: false);
  }

  bool _looksLikePlaceSearch(String message) {
    final text = message.toLowerCase();
    return _containsAny(text, const [
      'food',
      'eat',
      'restaurant',
      'dining',
      'coffee',
      'meal',
      'lunch',
      'dinner',
      'housing',
      'apartment',
      'gym',
      'walk',
      'route',
      'near',
      'nearby',
      'place',
    ]);
  }

  String _buildQuery({
    required String message,
    required Iterable<String> preferenceTags,
  }) {
    final text = message.toLowerCase();
    final preferences = preferenceTags.map((tag) => tag.toLowerCase()).toSet();
    const campus = 'near University of Maryland College Park';

    if (_hasVeganPreference(preferences, text) && _isFoodTask(text)) {
      return 'vegan food $campus';
    }
    if (_hasVegetarianPreference(preferences, text) && _isFoodTask(text)) {
      return 'vegetarian food $campus';
    }
    if (_hasPreference(preferences, text, 'halal') && _isFoodTask(text)) {
      return 'halal food $campus';
    }
    if (_hasPreference(preferences, text, 'kosher') && _isFoodTask(text)) {
      return 'kosher food $campus';
    }
    if ((preferences.contains('gluten_free') ||
            text.contains('gluten free') ||
            text.contains('gluten-free')) &&
        _isFoodTask(text)) {
      return 'gluten free food $campus';
    }
    if ((preferences.contains('food_allergy') || text.contains('allerg')) &&
        _isFoodTask(text)) {
      return 'allergy friendly restaurants $campus';
    }
    if (_containsAny(text, const ['coffee', 'cafe'])) {
      return 'coffee $campus';
    }
    if (_containsAny(text, const ['housing', 'apartment', 'rent'])) {
      return 'student housing $campus';
    }

    return '$message $campus';
  }

  bool _hasVeganPreference(Set<String> preferences, String text) {
    return preferences.contains('vegan') ||
        preferences.contains('diet_vegan') ||
        preferences.contains('plant_based') ||
        text.contains('vegan') ||
        text.contains('plant based') ||
        text.contains('plant-based');
  }

  bool _hasVegetarianPreference(Set<String> preferences, String text) {
    return _hasVeganPreference(preferences, text) ||
        preferences.contains('vegetarian') ||
        preferences.contains('diet_vegetarian') ||
        text.contains('vegetarian');
  }

  bool _hasPreference(Set<String> preferences, String text, String label) {
    return preferences.contains(label) || text.contains(label);
  }

  bool _isFoodTask(String text) {
    return _containsAny(
      text,
      const ['food', 'eat', 'restaurant', 'meal', 'lunch', 'dinner', 'dining'],
    );
  }

  bool _containsAny(String text, Iterable<String> keywords) {
    return keywords.any(text.contains);
  }

  String _displayName(Map<String, dynamic> place) {
    final displayName = place['displayName'];
    if (displayName is Map<String, dynamic>) {
      return (displayName['text'] as String?) ?? '';
    }
    return '';
  }
}
