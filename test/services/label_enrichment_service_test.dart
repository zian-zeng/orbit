import 'package:chatbotapp/hive/chat_history.dart';
import 'package:chatbotapp/models/prompt_recommendation.dart';
import 'package:chatbotapp/services/label_enrichment_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const service = LabelEnrichmentService();

  test('history and imported signals reshape the ranked labels', () {
    final snapshot = service.buildSnapshot(
      preferredLabelKeys: const [
        'writing',
        'planning',
        'study_help',
        'summarization',
        'image_analysis',
        'wellbeing_checkin',
      ],
      importedLabelKeys: const [
        'planning',
        'study_help',
        'summarization',
        'writing',
        'image_analysis',
        'wellbeing_checkin',
      ],
      importedSources: const ['Google Calendar'],
      history: [
        ChatHistory(
          chatId: 'chat-1',
          prompt: 'I am overwhelmed by deadlines and need a plan.',
          response: 'Let us organize the week.',
          imagesUrls: const [],
          timestamp: DateTime(2026, 4, 16, 10),
          selectedLabel: 'wellbeing_checkin',
        ),
      ],
    );

    expect(snapshot.rankedLabels.first, SupportLabel.planning);
    expect(snapshot.sourceBadges, contains('History'));
    expect(snapshot.sourceBadges, contains('Google Calendar'));
  });

  test('returns no routing labels when no signals exist yet', () {
    final snapshot = service.buildSnapshot(
      preferredLabelKeys: const [],
      importedLabelKeys: const [],
      importedSources: const [],
      history: const [],
    );

    expect(snapshot.rankedLabels, isEmpty);
    expect(snapshot.sourceBadges, isEmpty);
  });

  test('google calendar payload infers planning-heavy labels', () {
    final snapshot = service.inferGoogleCalendarLabelsFromPayload({
      'items': [
        {
          'summary': 'CMSC deadline planning',
          'description': 'Project milestones and review tasks',
        },
        {
          'summary': 'Office hours',
          'description': 'Study session for algorithms',
        },
        {
          'summary': 'Wellness check-in',
          'description': 'Therapy appointment',
        },
      ],
    });

    expect(snapshot.rankedLabels.first, SupportLabel.planning);
    expect(snapshot.sourceName, 'Google Calendar');
  });

  test('canvas payload infers study-help labels from assignments', () {
    final snapshot = service.inferCanvasLabelsFromPayload([
      {
        'title': 'Quiz 4',
        'description': 'Covers graph traversal',
        'type': 'assignment',
      },
      {
        'title': 'Homework draft',
        'description': 'Submit written reflection',
        'type': 'assignment',
      },
    ]);

    expect(snapshot.rankedLabels.first, SupportLabel.studyHelp);
    expect(snapshot.sourceName, 'Canvas');
  });

  test('canvas payload also accepts wrapped item maps', () {
    final snapshot = service.inferCanvasLabelsFromPayload({
      'items': [
        {
          'title': 'Exam review',
          'description': 'Practice for the midterm',
          'type': 'assignment',
        },
      ],
    });

    expect(snapshot.rankedLabels.first, SupportLabel.studyHelp);
    expect(snapshot.sourceName, 'Canvas');
  });
}
