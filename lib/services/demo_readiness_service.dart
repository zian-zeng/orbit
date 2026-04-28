import 'dart:async';
import 'dart:convert';

import 'package:chatbotapp/agents/local_llm_client.dart';
import 'package:chatbotapp/apis/api_service.dart';
import 'package:chatbotapp/constants/constants.dart';
import 'package:chatbotapp/hive/boxes.dart';
import 'package:chatbotapp/services/demo_bootstrap_service.dart';
// ignore: depend_on_referenced_packages
import 'package:http/http.dart' as http;
import 'package:hive/hive.dart';

enum DemoReadinessState {
  ready,
  warning,
  missing,
}

class DemoReadinessItem {
  const DemoReadinessItem({
    required this.label,
    required this.detail,
    required this.state,
  });

  final String label;
  final String detail;
  final DemoReadinessState state;
}

class DemoReadinessReport {
  const DemoReadinessReport({
    required this.items,
    required this.checkedAt,
  });

  final List<DemoReadinessItem> items;
  final DateTime checkedAt;

  int get readyCount =>
      items.where((item) => item.state == DemoReadinessState.ready).length;

  bool get isDemoReady =>
      items.every((item) => item.state != DemoReadinessState.missing);

  String get summaryLabel =>
      isDemoReady ? 'Demo ready' : 'Demo needs attention';
}

class DemoReadinessService {
  const DemoReadinessService({
    http.Client? httpClient,
    LocalLlmConfig? localLlmConfig,
  })  : _httpClient = httpClient,
        _localLlmConfig = localLlmConfig;

  final http.Client? _httpClient;
  final LocalLlmConfig? _localLlmConfig;

  Future<DemoReadinessReport> buildReport({
    Duration timeout = const Duration(milliseconds: 1600),
  }) async {
    final items = <DemoReadinessItem>[
      _profileItem(),
      _fixtureItem(),
      _historyItem(),
      _skillItem(),
      _auditItem(),
      _geminiItem(),
      await _gemmaItem(timeout: timeout),
    ];

    return DemoReadinessReport(
      items: items,
      checkedAt: DateTime.now(),
    );
  }

  DemoReadinessItem _profileItem() {
    if (!Hive.isBoxOpen(Constants.userBox) || Boxes.getUser().isEmpty) {
      return const DemoReadinessItem(
        label: 'Maya profile',
        detail: 'Log in with the Maya demo profile before pitching.',
        state: DemoReadinessState.missing,
      );
    }

    final user = Boxes.getUser().getAt(0);
    final ready =
        user?.email.trim().toLowerCase() == DemoBootstrapService.demoEmail &&
            (user?.hasCompletedOnboarding ?? false) &&
            (user?.hasCompletedGuide ?? false);
    return DemoReadinessItem(
      label: 'Maya profile',
      detail: ready
          ? 'Maya Chen is logged in and startup is skipped.'
          : 'A user is present, but it is not the seeded Maya profile.',
      state: ready ? DemoReadinessState.ready : DemoReadinessState.warning,
    );
  }

  DemoReadinessItem _fixtureItem() {
    if (!Hive.isBoxOpen(Constants.settingsBox) || Boxes.getSettings().isEmpty) {
      return const DemoReadinessItem(
        label: 'Demo fixture',
        detail: 'Settings are not initialized yet.',
        state: DemoReadinessState.missing,
      );
    }
    final enabled = Boxes.getSettings().getAt(0)?.preferDemoFixture ?? false;
    return DemoReadinessItem(
      label: 'Demo fixture',
      detail: enabled
          ? 'Deterministic Canvas, Calendar, Places, and Routes data is on.'
          : 'Live/data fallback may vary. Turn on Use demo fixture for pitches.',
      state: enabled ? DemoReadinessState.ready : DemoReadinessState.warning,
    );
  }

  DemoReadinessItem _historyItem() {
    final chatCount = Hive.isBoxOpen(Constants.chatHistoryBox)
        ? Boxes.getChatHistory().length
        : 0;
    final monitorCount = Hive.isBoxOpen(Constants.monitorHistoryBox)
        ? Boxes.getMonitorHistory().length
        : 0;
    final ready = chatCount >= 5 && monitorCount >= 30;
    return DemoReadinessItem(
      label: 'Personalization history',
      detail:
          '$chatCount chats and $monitorCount monitor checkpoints are seeded.',
      state: ready ? DemoReadinessState.ready : DemoReadinessState.warning,
    );
  }

  DemoReadinessItem _skillItem() {
    final count = Hive.isBoxOpen(Constants.skillRegistryBox)
        ? Boxes.getSkillRegistry().length
        : 0;
    return DemoReadinessItem(
      label: 'Generated skill',
      detail: count > 0
          ? '$count saved skill version is available.'
          : 'Save or seed a support skill before showing the dashboard.',
      state: count > 0 ? DemoReadinessState.ready : DemoReadinessState.warning,
    );
  }

  DemoReadinessItem _auditItem() {
    final count = Hive.isBoxOpen(Constants.agentAuditLogBox)
        ? Boxes.getAgentAuditLog().length
        : 0;
    return DemoReadinessItem(
      label: 'Agent trace',
      detail: count > 0
          ? '$count collaboration trace is available.'
          : 'Send a prompt or seed Maya to show agent collaboration.',
      state: count > 0 ? DemoReadinessState.ready : DemoReadinessState.warning,
    );
  }

  DemoReadinessItem _geminiItem() {
    return DemoReadinessItem(
      label: 'Gemini key',
      detail: ApiService.isConfigured
          ? 'Gemini API key is configured locally.'
          : 'Gemini is not configured. Gemma/local fallback can still demo.',
      state: ApiService.isConfigured
          ? DemoReadinessState.ready
          : DemoReadinessState.warning,
    );
  }

  Future<DemoReadinessItem> _gemmaItem({required Duration timeout}) async {
    final config = _localLlmConfig ?? LocalLlmConfig.fromEnvironment();
    final client = _httpClient ?? http.Client();
    final shouldClose = _httpClient == null;
    try {
      final endpoint = Uri.parse(config.endpoint);
      final uri = endpoint.replace(path: _joinPath(endpoint.path, 'api/tags'));
      final response = await client.get(uri).timeout(timeout);
      if (response.statusCode < 200 || response.statusCode >= 300) {
        return DemoReadinessItem(
          label: 'Gemma local',
          detail: 'Ollama responded with HTTP ${response.statusCode}.',
          state: DemoReadinessState.warning,
        );
      }

      final decoded = jsonDecode(response.body);
      final models = decoded is Map<String, dynamic>
          ? decoded['models'] as List<dynamic>? ?? const []
          : const [];
      final modelNames = models
          .whereType<Map<String, dynamic>>()
          .map((model) => (model['name'] as String?) ?? '')
          .where((name) => name.isNotEmpty)
          .toList(growable: false);
      final installed = modelNames.contains(config.model);
      return DemoReadinessItem(
        label: 'Gemma local',
        detail: installed
            ? '${config.model} is installed in Ollama.'
            : modelNames.isEmpty
                ? 'Ollama is running, but no local models are listed.'
                : '${config.model} is not installed. Found: ${modelNames.join(', ')}.',
        state:
            installed ? DemoReadinessState.ready : DemoReadinessState.warning,
      );
    } on TimeoutException {
      return DemoReadinessItem(
        label: 'Gemma local',
        detail: 'Ollama did not respond quickly at ${config.endpoint}.',
        state: DemoReadinessState.warning,
      );
    } catch (error) {
      return DemoReadinessItem(
        label: 'Gemma local',
        detail: 'Ollama check failed: $error',
        state: DemoReadinessState.warning,
      );
    } finally {
      if (shouldClose) {
        client.close();
      }
    }
  }

  String _joinPath(String basePath, String suffix) {
    final normalizedBase = basePath.trim();
    if (normalizedBase.isEmpty || normalizedBase == '/') {
      return '/$suffix';
    }
    return '${normalizedBase.replaceAll(RegExp(r'/+$'), '')}/$suffix';
  }
}
