import 'package:chatbotapp/constants/constants.dart';
import 'package:chatbotapp/hive/boxes.dart';
import 'package:chatbotapp/hive/skill_registry_entry.dart';
import 'package:chatbotapp/models/support_intelligence.dart';
import 'package:hive/hive.dart';

class SkillRegistryService {
  const SkillRegistryService();

  Future<SkillRegistryEntry?> saveBlueprint({
    required AgentSkillBlueprint blueprint,
    required Iterable<String> sourceLabels,
    required StressBand stressBand,
    DateTime? now,
  }) async {
    if (!Hive.isBoxOpen(Constants.skillRegistryBox)) {
      return null;
    }
    final nextVersion = _nextVersion(blueprint.skillId);
    final entry = SkillRegistryEntry(
      id: '${blueprint.skillId}|v$nextVersion',
      skillId: blueprint.skillId,
      version: nextVersion,
      createdAt: now ?? DateTime.now(),
      title: blueprint.title,
      summary: blueprint.summary,
      systemPrompt: blueprint.systemPrompt,
      starterPrompt: blueprint.starterPrompt,
      toolIds: blueprint.tools.map((tool) => tool.toolId).toList(),
      toolLabels: blueprint.tools.map((tool) => tool.label).toList(),
      toolReasons: blueprint.tools.map((tool) => tool.reason).toList(),
      sourceLabels: _normalize(sourceLabels),
      stressBand: stressBand.name,
      isActive: true,
    );
    await Boxes.getSkillRegistry().put(entry.id, entry);
    return entry;
  }

  SkillRegistryEntry? latestForSkill(String skillId) {
    if (!Hive.isBoxOpen(Constants.skillRegistryBox)) {
      return null;
    }
    final entries = Boxes.getSkillRegistry()
        .values
        .where((entry) => entry.skillId == skillId)
        .toList(growable: false)
      ..sort((left, right) => right.version.compareTo(left.version));
    return entries.isEmpty ? null : entries.first;
  }

  List<SkillRegistryEntry> loadRecent({int limit = 20}) {
    if (!Hive.isBoxOpen(Constants.skillRegistryBox)) {
      return const [];
    }
    final entries = Boxes.getSkillRegistry().values.toList(growable: false)
      ..sort((left, right) => right.createdAt.compareTo(left.createdAt));
    return entries.take(limit).toList(growable: false);
  }

  int _nextVersion(String skillId) {
    final latest = latestForSkill(skillId);
    return (latest?.version ?? 0) + 1;
  }

  List<String> _normalize(Iterable<String> labels) {
    return labels
        .map((label) => label.trim())
        .where((label) => label.isNotEmpty)
        .toSet()
        .toList(growable: false)
      ..sort();
  }
}
