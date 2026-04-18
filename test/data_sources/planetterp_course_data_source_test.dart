import 'package:chatbotapp/data_sources/http_json_client.dart';
import 'package:chatbotapp/data_sources/planetterp_course_data_source.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('parses PlanetTerp course data into course candidate signals', () async {
    final dataSource = PlanetterpCourseDataSource(
      httpClient: _FakeHttpJsonClient(),
    );

    final course = await dataSource.fetchCourse(courseId: 'cmsc216');

    expect(course, isNotNull);
    expect(course!.courseId, 'CMSC216');
    expect(course.title, 'Introduction to Computer Systems');
    expect(course.averageGpa, 2.86);
    expect(course.workloadLevel, 'high');
    expect(course.professors.map((professor) => professor.name),
        contains('Larry Herman'));
  });

  test('parses PlanetTerp professor data into professor signals', () async {
    final dataSource = PlanetterpCourseDataSource(
      httpClient: _FakeHttpJsonClient(),
    );

    final professor = await dataSource.fetchProfessor(
      professorName: 'Larry Herman',
      includeReviews: true,
    );

    expect(professor, isNotNull);
    expect(professor!.averageRating, 4.1);
    expect(professor.reviewCount, 2);
    expect(professor.studentNotes.first, contains('structured'));
  });

  test('hydrates course candidates with professor review signals', () async {
    final dataSource = PlanetterpCourseDataSource(
      httpClient: _FakeHttpJsonClient(),
    );

    final course = await dataSource.fetchCourseWithProfessorSignals(
      courseId: 'CMSC216',
    );

    expect(course, isNotNull);
    expect(course!.professors.first.averageRating, 4.1);
    expect(course.professors.first.reviewCount, 2);
    expect(course.professors.first.studentNotes.last, contains('start early'));
  });
}

class _FakeHttpJsonClient extends HttpJsonClient {
  @override
  Future<dynamic> getJson(
    Uri uri, {
    Map<String, String> headers = const {},
    Duration timeout = const Duration(seconds: 12),
  }) async {
    if (uri.path == '/v1/course') {
      expect(uri.queryParameters['name'], 'CMSC216');
      return {
        'name': 'CMSC216',
        'title': 'Introduction to Computer Systems',
        'credits': '4',
        'average_gpa': 2.86,
        'professors': ['Larry Herman', 'Nelson Padua-Perez'],
      };
    }
    if (uri.path == '/v1/professor') {
      if (uri.queryParameters['name'] == 'Nelson Padua-Perez') {
        return {
          'name': 'Nelson Padua-Perez',
          'slug': 'nelson_padua_perez',
          'average_rating': 3.7,
          'average_gpa': 2.88,
          'reviews': [
            {'review': 'Helpful, but exams require practice.'},
          ],
        };
      }
      expect(uri.queryParameters['name'], 'Larry Herman');
      return {
        'name': 'Larry Herman',
        'slug': 'larry_herman',
        'average_rating': 4.1,
        'average_gpa': 2.95,
        'reviews': [
          {'review': 'Very structured and clear.'},
          {'review': 'Projects take time, start early.'},
        ],
      };
    }
    fail('Unexpected URI: $uri');
  }
}
