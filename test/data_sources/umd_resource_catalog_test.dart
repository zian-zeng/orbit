import 'package:chatbotapp/data_sources/umd_resource_catalog.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('matches UMD wellbeing resources from stress labels', () {
    const catalog = UmdResourceCatalog();

    final matches = catalog.match(
      message: 'I feel overwhelmed and anxious before finals.',
      labels: const ['wellbeing_checkin'],
    );

    expect(matches.first.name, 'Counseling Center');
  });

  test('matches UMD academic resources from study labels', () {
    const catalog = UmdResourceCatalog();

    final matches = catalog.match(
      message: 'I need help with exams and study habits.',
      labels: const ['study_help'],
    );

    expect(
      matches.map((resource) => resource.name),
      contains('Teaching and Learning Transformation Center'),
    );
  });

  test('matches UMD dining resources for vegan food preferences', () {
    const catalog = UmdResourceCatalog();

    final matches = catalog.match(
      message: 'I need food near campus',
      labels: const ['vegan', 'life_logistics'],
    );

    expect(matches.first.name, 'UMD Dining Services');
  });
}
