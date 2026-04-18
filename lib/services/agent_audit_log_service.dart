import 'package:chatbotapp/agents/orbit_models.dart';
import 'package:chatbotapp/constants/constants.dart';
import 'package:chatbotapp/data_sources/student_data_models.dart';
import 'package:chatbotapp/hive/agent_audit_log_entry.dart';
import 'package:chatbotapp/hive/boxes.dart';
import 'package:chatbotapp/models/message.dart';
import 'package:hive/hive.dart';

class AgentAuditLogService {
  const AgentAuditLogService();

  Future<AgentAuditLogEntry?> record({
    required Message assistantMessage,
    required String userMessage,
    required OrbitAgentResponse response,
    required StudentSignalSnapshot snapshot,
    required Iterable<String> labelKeys,
    required int latencyMs,
    DateTime? now,
  }) async {
    if (!Hive.isBoxOpen(Constants.agentAuditLogBox)) {
      return null;
    }
    final entry = AgentAuditLogEntry(
      id: _entryId(assistantMessage),
      chatId: assistantMessage.chatId,
      messageId: assistantMessage.messageId,
      createdAt: now ?? DateTime.now(),
      activatedRoles:
          response.trace.activatedRoles.map((role) => role.label).toList(),
      skillIds:
          response.trace.skillResults.map((skill) => skill.skillId).toList(),
      toolNames: _extractTools(response.trace.skillResults),
      dataSources: _dataSources(snapshot),
      labelKeys: _normalize(labelKeys),
      usedLocalModel: response.trace.usedLocalModel,
      modelName: response.trace.modelName,
      fallbackReason: response.trace.fallbackReason ?? '',
      latencyMs: latencyMs,
      userMessagePreview: _preview(userMessage),
      responsePreview: _preview(response.text),
    );
    await Boxes.getAgentAuditLog().put(entry.id, entry);
    return entry;
  }

  AgentAuditLogEntry? loadForMessage(Message message) {
    if (!Hive.isBoxOpen(Constants.agentAuditLogBox)) {
      return null;
    }
    return Boxes.getAgentAuditLog().get(_entryId(message));
  }

  List<AgentAuditLogEntry> loadRecent({int limit = 50}) {
    if (!Hive.isBoxOpen(Constants.agentAuditLogBox)) {
      return const [];
    }
    final entries = Boxes.getAgentAuditLog().values.toList(growable: false)
      ..sort((left, right) => right.createdAt.compareTo(left.createdAt));
    return entries.take(limit).toList(growable: false);
  }

  List<String> _extractTools(List<SkillResult> skillResults) {
    final tools = <String>{};
    for (final skill in skillResults) {
      for (final recommendation in skill.recommendations) {
        const marker = 'Tool priority:';
        if (!recommendation.startsWith(marker)) {
          continue;
        }
        final value = recommendation.substring(marker.length).trim();
        if (value == 'none') {
          continue;
        }
        tools.addAll(
          value
              .split('->')
              .map((tool) => tool.trim())
              .where((tool) => tool.isNotEmpty),
        );
      }
    }
    return tools.toList(growable: false)..sort();
  }

  List<String> _dataSources(StudentSignalSnapshot snapshot) {
    return [
      if (snapshot.assignments.isNotEmpty) 'Canvas',
      if (snapshot.calendarEvents.isNotEmpty) 'Google Calendar',
      if (snapshot.places.isNotEmpty) 'Google Places',
      if (snapshot.routes.isNotEmpty) 'Google Routes',
      if (snapshot.sourceNotes.isNotEmpty) 'Source notes',
    ];
  }

  List<String> _normalize(Iterable<String> values) {
    return values
        .map((value) => value.trim())
        .where((value) => value.isNotEmpty)
        .toSet()
        .toList(growable: false)
      ..sort();
  }

  String _entryId(Message message) {
    return '${message.chatId}|${message.messageId}';
  }

  String _preview(String text) {
    final normalized = text.trim().replaceAll(RegExp(r'\s+'), ' ');
    if (normalized.length <= 240) {
      return normalized;
    }
    return normalized.substring(0, 240);
  }
}
