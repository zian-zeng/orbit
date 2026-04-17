import 'dart:convert';
import 'dart:io';

import 'package:chatbotapp/hive/chat_history.dart';
import 'package:chatbotapp/models/prompt_recommendation.dart';

class LabelImportSnapshot {
  const LabelImportSnapshot({
    required this.rankedLabels,
    required this.sourceName,
    required this.itemCount,
  });

  final List<SupportLabel> rankedLabels;
  final String sourceName;
  final int itemCount;

  List<String> get labelKeys =>
      rankedLabels.map((label) => label.storageKey).toList(growable: false);
}

class LabelEnrichmentSnapshot {
  const LabelEnrichmentSnapshot({
    required this.rankedLabels,
    required this.sourceBadges,
  });

  final List<SupportLabel> rankedLabels;
  final List<String> sourceBadges;
}

class LabelEnrichmentService {
  const LabelEnrichmentService();

  static const List<int> _preferredWeights = [36, 24, 18, 12, 8, 6];
  static const List<int> _importedWeights = [28, 20, 14, 10, 6, 4];
  static const Map<SupportLabel, List<String>> _keywords = {
    SupportLabel.planning: [
      'plan',
      'schedule',
      'deadline',
      'milestone',
      'organize',
      'calendar',
      'week',
      'task',
      'assignment',
      'due',
    ],
    SupportLabel.writing: [
      'write',
      'draft',
      'essay',
      'email',
      'reply',
      'reflection',
      'statement',
      'message',
      'feedback',
    ],
    SupportLabel.studyHelp: [
      'study',
      'quiz',
      'exam',
      'lecture',
      'lab',
      'office hour',
      'homework',
      'practice',
      'concept',
      'class',
    ],
    SupportLabel.summarization: [
      'summary',
      'summarize',
      'recap',
      'notes',
      'reading',
      'article',
      'brief',
      'overview',
    ],
    SupportLabel.imageAnalysis: [
      'image',
      'photo',
      'screenshot',
      'diagram',
      'figure',
      'chart',
      'graph',
      'slide',
    ],
    SupportLabel.wellbeingCheckIn: [
      'overwhelmed',
      'stress',
      'stressed',
      'anxious',
      'burnout',
      'therapy',
      'wellness',
      'panic',
      'tired',
      'reset',
    ],
  };

  LabelEnrichmentSnapshot buildSnapshot({
    required List<String> preferredLabelKeys,
    required List<String> importedLabelKeys,
    required Iterable<String> importedSources,
    required Iterable<ChatHistory> history,
  }) {
    final scores = _blankScores();
    final sourceBadges = <String>[];

    final preferred = supportLabelsFromKeys(preferredLabelKeys);
    if (preferred.isNotEmpty) {
      _seedScores(scores, preferred, _preferredWeights);
      sourceBadges.add('Signup');
    }

    final imported = supportLabelsFromKeys(importedLabelKeys);
    if (imported.isNotEmpty) {
      _seedScores(scores, imported, _importedWeights);
      for (final source in importedSources) {
        if (source.trim().isNotEmpty && !sourceBadges.contains(source)) {
          sourceBadges.add(source);
        }
      }
    }

    final historyScores = _historyScores(history);
    final hasHistorySignal = historyScores.values.any((value) => value > 0);
    if (hasHistorySignal) {
      for (final entry in historyScores.entries) {
        scores[entry.key] = (scores[entry.key] ?? 0) + entry.value;
      }
      if (!sourceBadges.contains('History')) {
        sourceBadges.add('History');
      }
    }

    return LabelEnrichmentSnapshot(
      rankedLabels:
          sourceBadges.isEmpty ? const <SupportLabel>[] : _rankLabels(scores),
      sourceBadges: sourceBadges,
    );
  }

  List<String> mergeImportedSourceRankings(Iterable<List<String>> rankings) {
    final scores = _blankScores();
    for (final ranking in rankings) {
      _seedScores(scores, supportLabelsFromKeys(ranking), _importedWeights);
    }
    return _hasPositiveScore(scores)
        ? _rankLabels(scores)
            .map((label) => label.storageKey)
            .toList(growable: false)
        : const <String>[];
  }

  LabelImportSnapshot inferGoogleCalendarLabelsFromPayload(
    Map<String, dynamic> payload,
  ) {
    final scores = _blankScores();
    final items = (payload['items'] as List? ?? const <Object>[])
        .whereType<Map>()
        .map((item) => item.map((key, value) => MapEntry('$key', value)))
        .toList(growable: false);

    for (final item in items) {
      final content =
          '${item['summary'] ?? ''} ${item['description'] ?? ''}'.toLowerCase();
      _applyKeywordScores(scores, content, boost: 4);
    }

    if (items.length >= 3) {
      scores[SupportLabel.planning] = (scores[SupportLabel.planning] ?? 0) + 8;
    }

    return LabelImportSnapshot(
      rankedLabels: _hasPositiveScore(scores)
          ? _rankLabels(scores)
          : const <SupportLabel>[],
      sourceName: 'Google Calendar',
      itemCount: items.length,
    );
  }

  LabelImportSnapshot inferCanvasLabelsFromPayload(Object? payload) {
    final scores = _blankScores();
    final entries = switch (payload) {
      List<dynamic> value => value,
      Map<String, dynamic> value => value['items'] as List? ?? const <Object>[],
      _ => const <Object>[],
    };

    final items = entries
        .whereType<Map>()
        .map((item) => item.map((key, value) => MapEntry('$key', value)))
        .toList(growable: false);

    for (final item in items) {
      final content =
          '${item['title'] ?? item['name'] ?? ''} ${item['description'] ?? ''} ${item['type'] ?? ''}'
              .toLowerCase();
      _applyKeywordScores(scores, content, boost: 4);
      if (content.contains('assignment') ||
          content.contains('quiz') ||
          content.contains('exam')) {
        scores[SupportLabel.studyHelp] =
            (scores[SupportLabel.studyHelp] ?? 0) + 5;
        scores[SupportLabel.planning] =
            (scores[SupportLabel.planning] ?? 0) + 3;
      }
    }

    return LabelImportSnapshot(
      rankedLabels: _hasPositiveScore(scores)
          ? _rankLabels(scores)
          : const <SupportLabel>[],
      sourceName: 'Canvas',
      itemCount: items.length,
    );
  }

  Future<LabelImportSnapshot> fetchGoogleCalendarLabels({
    required String accessToken,
    String calendarId = 'primary',
  }) async {
    final now = DateTime.now().toUtc();
    final uri = Uri.https(
      'www.googleapis.com',
      '/calendar/v3/calendars/${Uri.encodeComponent(calendarId)}/events',
      {
        'singleEvents': 'true',
        'orderBy': 'startTime',
        'maxResults': '20',
        'timeMin': now.toIso8601String(),
      },
    );
    final payload = await _getJson(uri: uri, accessToken: accessToken);
    if (payload is! Map<String, dynamic>) {
      throw StateError('Unexpected calendar response.');
    }
    return inferGoogleCalendarLabelsFromPayload(payload);
  }

  Future<LabelImportSnapshot> fetchCanvasLabels({
    required String baseUrl,
    required String accessToken,
  }) async {
    final baseUri = Uri.parse(baseUrl.trim());
    final normalizedPath = baseUri.path.endsWith('/')
        ? '${baseUri.path}api/v1/users/self/upcoming_events'
        : '${baseUri.path}/api/v1/users/self/upcoming_events';
    final uri = baseUri.replace(
      path: normalizedPath,
      queryParameters: {'per_page': '20'},
    );
    final payload = await _getJson(uri: uri, accessToken: accessToken);
    return inferCanvasLabelsFromPayload(payload);
  }

  Map<SupportLabel, int> _historyScores(Iterable<ChatHistory> history) {
    final scores = _blankScores();
    final ordered = history.toList(growable: false)
      ..sort((a, b) => b.timestamp.compareTo(a.timestamp));

    for (var index = 0; index < ordered.length && index < 12; index++) {
      final item = ordered[index];
      final recencyBoost = index < 3
          ? 7
          : index < 6
              ? 5
              : 3;
      final selected = supportLabelFromKey(item.selectedLabel);
      if (selected != null) {
        scores[selected] = (scores[selected] ?? 0) + 6 + recencyBoost;
      }

      if (item.imagesUrls.isNotEmpty) {
        scores[SupportLabel.imageAnalysis] =
            (scores[SupportLabel.imageAnalysis] ?? 0) + 3 + recencyBoost;
      }

      _applyKeywordScores(
        scores,
        '${item.prompt} ${item.response}'.toLowerCase(),
        boost: recencyBoost,
      );

      final templateId = item.templateId ?? '';
      if (templateId.contains('plan')) {
        scores[SupportLabel.planning] =
            (scores[SupportLabel.planning] ?? 0) + 3;
      } else if (templateId.contains('draft')) {
        scores[SupportLabel.writing] = (scores[SupportLabel.writing] ?? 0) + 3;
      } else if (templateId.contains('study')) {
        scores[SupportLabel.studyHelp] =
            (scores[SupportLabel.studyHelp] ?? 0) + 3;
      } else if (templateId.contains('summarize')) {
        scores[SupportLabel.summarization] =
            (scores[SupportLabel.summarization] ?? 0) + 3;
      } else if (templateId.contains('analyze_image')) {
        scores[SupportLabel.imageAnalysis] =
            (scores[SupportLabel.imageAnalysis] ?? 0) + 3;
      } else if (templateId.contains('wellbeing')) {
        scores[SupportLabel.wellbeingCheckIn] =
            (scores[SupportLabel.wellbeingCheckIn] ?? 0) + 3;
      }
    }

    return scores;
  }

  void _applyKeywordScores(
    Map<SupportLabel, int> scores,
    String content, {
    required int boost,
  }) {
    for (final entry in _keywords.entries) {
      final matches = entry.value.where(content.contains).length;
      if (matches == 0) {
        continue;
      }
      scores[entry.key] = (scores[entry.key] ?? 0) + (matches * boost);
    }
  }

  void _seedScores(
    Map<SupportLabel, int> scores,
    List<SupportLabel> labels,
    List<int> weights,
  ) {
    for (var index = 0;
        index < labels.length && index < weights.length;
        index++) {
      final label = labels[index];
      scores[label] = (scores[label] ?? 0) + weights[index];
    }
  }

  List<SupportLabel> _rankLabels(Map<SupportLabel, int> scores) {
    final ranked = SupportLabel.values.toList(growable: false);
    ranked.sort((left, right) {
      final scoreDelta = (scores[right] ?? 0) - (scores[left] ?? 0);
      if (scoreDelta != 0) {
        return scoreDelta;
      }
      return left.index.compareTo(right.index);
    });
    return ranked;
  }

  Map<SupportLabel, int> _blankScores() {
    return <SupportLabel, int>{
      for (final label in SupportLabel.values) label: 0,
    };
  }

  bool _hasPositiveScore(Map<SupportLabel, int> scores) {
    return scores.values.any((value) => value > 0);
  }

  Future<Object?> _getJson({
    required Uri uri,
    required String accessToken,
  }) async {
    final client = HttpClient();
    try {
      final request = await client.getUrl(uri);
      request.headers
          .set(HttpHeaders.authorizationHeader, 'Bearer $accessToken');
      request.headers.set(HttpHeaders.acceptHeader, 'application/json');
      final response = await request.close();
      final body = await utf8.decoder.bind(response).join();
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw StateError('Import failed (${response.statusCode}).');
      }
      return jsonDecode(body);
    } finally {
      client.close(force: true);
    }
  }
}
