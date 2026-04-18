import 'package:chatbotapp/services/student_preference_extractor.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const extractor = StudentPreferenceExtractor();

  test('extracts dietary preferences from student history text', () {
    final labels = extractor.extractFromTexts(const [
      'I am vegan and usually need plant-based options near campus.',
      'Also I am gluten free because of celiac.',
    ]);

    expect(labels, containsAll(['vegan', 'plant_based', 'gluten_free']));
  });

  test('extracts campus logistics preferences without LLM calls', () {
    final labels = extractor.extractFromText(
      'I am a commuter student and parking before class is hard.',
    );

    expect(labels, containsAll(['commuter', 'campus_navigation']));
  });
}
