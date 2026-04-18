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

  test('matches legal aid for lease and conduct concerns', () {
    const catalog = UmdResourceCatalog();

    final matches = catalog.match(
      message: 'My landlord lease issue is affecting classes.',
      labels: const ['housing', 'life_logistics'],
    );

    expect(
      matches.map((resource) => resource.name),
      contains('Undergraduate Student Legal Aid Office'),
    );
  });

  test('matches transportation resources for night rides and paratransit', () {
    const catalog = UmdResourceCatalog();

    final matches = catalog.match(
      message: 'I need a late night ride and accessible shuttle option.',
      labels: const ['campus_navigation', 'accessibility'],
      limit: 5,
    );

    expect(matches.map((resource) => resource.name), contains('NITE Ride'));
    expect(
      matches.map((resource) => resource.name),
      contains('Shuttle-UM Paratransit'),
    );
    expect(matches.map((resource) => resource.name), contains('Terp Ride App'));
  });

  test('matches safety app and peer support resources', () {
    const catalog = UmdResourceCatalog();

    final safetyMatches = catalog.match(
      message: 'I am walking late and want a guardian safety app.',
      labels: const ['safety', 'campus_resources'],
      limit: 5,
    );
    final supportMatches = catalog.match(
      message: 'I want an anonymous peer hotline because stress is high.',
      labels: const ['wellbeing_checkin'],
      limit: 5,
    );

    expect(safetyMatches.map((resource) => resource.name),
        contains('UMD Guardian App'));
    expect(supportMatches.map((resource) => resource.name),
        contains('Help Center at UMD'));
  });
}
