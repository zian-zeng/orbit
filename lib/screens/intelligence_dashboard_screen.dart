import 'package:chatbotapp/hive/agent_audit_log_entry.dart';
import 'package:chatbotapp/hive/assistant_feedback_entry.dart';
import 'package:chatbotapp/hive/skill_registry_entry.dart';
import 'package:chatbotapp/services/agent_audit_log_service.dart';
import 'package:chatbotapp/services/assistant_feedback_service.dart';
import 'package:chatbotapp/services/skill_registry_service.dart';
import 'package:chatbotapp/widgets/app_icon_button.dart';
import 'package:chatbotapp/widgets/app_screen_scaffold.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class IntelligenceDashboardScreen extends StatelessWidget {
  const IntelligenceDashboardScreen({super.key});

  static const SkillRegistryService _skillRegistryService =
      SkillRegistryService();
  static const AssistantFeedbackService _feedbackService =
      AssistantFeedbackService();
  static const AgentAuditLogService _auditLogService = AgentAuditLogService();

  @override
  Widget build(BuildContext context) {
    final skills = _skillRegistryService.loadRecent(limit: 8);
    final feedback = _feedbackService.loadRecent(limit: 20);
    final feedbackCounts = _feedbackService.feedbackCounts(limit: 200);
    final audits = _auditLogService.loadRecent(limit: 8);
    final helpfulCount = feedbackCounts['helpful'] ?? 0;
    final issueCount = feedbackCounts.entries
        .where((entry) => entry.key != 'helpful')
        .fold<int>(0, (total, entry) => total + entry.value);

    return AppScreenScaffold(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
      child: Column(
        children: [
          Row(
            children: [
              AppIconButton(
                icon: CupertinoIcons.chevron_back,
                tooltip: 'Back',
                onTap: () => Navigator.of(context).pop(),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Intelligence Dashboard',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Saved skills, feedback, and agent audit trail',
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                            color:
                                Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.only(
                bottom: homeIndicatorSpacing(context, base: 24),
              ),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final wide = constraints.maxWidth >= 860;
                  final overview = _OverviewPanel(
                    skills: skills.length,
                    feedback: feedback.length,
                    audits: audits.length,
                    helpful: helpfulCount,
                    issues: issueCount,
                  );
                  final left = Column(
                    children: [
                      overview,
                      const SizedBox(height: 12),
                      _SkillRegistryPanel(skills: skills),
                    ],
                  );
                  final right = Column(
                    children: [
                      _FeedbackPanel(
                        feedback: feedback,
                        counts: feedbackCounts,
                      ),
                      const SizedBox(height: 12),
                      _AuditPanel(audits: audits),
                    ],
                  );

                  if (!wide) {
                    return Column(
                      children: [
                        left,
                        const SizedBox(height: 12),
                        right,
                      ],
                    );
                  }

                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(child: left),
                      const SizedBox(width: 12),
                      Expanded(child: right),
                    ],
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _OverviewPanel extends StatelessWidget {
  const _OverviewPanel({
    required this.skills,
    required this.feedback,
    required this.audits,
    required this.helpful,
    required this.issues,
  });

  final int skills;
  final int feedback;
  final int audits;
  final int helpful;
  final int issues;

  @override
  Widget build(BuildContext context) {
    return _DashboardPanel(
      title: 'Learning Loop',
      subtitle: 'Local product intelligence',
      icon: CupertinoIcons.chart_bar_alt_fill,
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          _MetricTile(label: 'Saved skills', value: '$skills'),
          _MetricTile(label: 'Feedback', value: '$feedback'),
          _MetricTile(label: 'Audit logs', value: '$audits'),
          _MetricTile(label: 'Helpful', value: '$helpful'),
          _MetricTile(label: 'Issues', value: '$issues'),
        ],
      ),
    );
  }
}

class _SkillRegistryPanel extends StatelessWidget {
  const _SkillRegistryPanel({required this.skills});

  final List<SkillRegistryEntry> skills;

  @override
  Widget build(BuildContext context) {
    return _DashboardPanel(
      title: 'Skill Registry',
      subtitle: 'Generated skills saved as versions',
      icon: CupertinoIcons.square_stack_3d_up_fill,
      child: skills.isEmpty
          ? const _EmptyText(
              text:
                  'No saved skills yet. Use Support Pulse > Save to create a versioned skill.',
            )
          : Column(
              children: skills
                  .map(
                    (skill) => _ListCard(
                      title: '${skill.title} ${skill.versionLabel}',
                      subtitle:
                          '${skill.stressBand} stress | ${skill.toolIds.length} tools',
                      detail: skill.summary,
                      chips: [
                        ...skill.sourceLabels.take(3),
                        ...skill.toolIds.take(3),
                      ],
                    ),
                  )
                  .toList(growable: false),
            ),
    );
  }
}

class _FeedbackPanel extends StatelessWidget {
  const _FeedbackPanel({
    required this.feedback,
    required this.counts,
  });

  final List<AssistantFeedbackEntry> feedback;
  final Map<String, int> counts;

  @override
  Widget build(BuildContext context) {
    return _DashboardPanel(
      title: 'Feedback Signal',
      subtitle: 'Recommendation learning inputs',
      icon: CupertinoIcons.hand_thumbsup,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _MiniChip(label: 'Helpful ${counts['helpful'] ?? 0}'),
              _MiniChip(label: 'Not helpful ${counts['not_helpful'] ?? 0}'),
              _MiniChip(label: 'Wrong context ${counts['wrong_context'] ?? 0}'),
              _MiniChip(label: 'Too much ${counts['too_much'] ?? 0}'),
            ],
          ),
          const SizedBox(height: 12),
          if (feedback.isEmpty)
            const _EmptyText(
              text:
                  'No feedback yet. Rate an assistant response to create a learning signal.',
            )
          else
            ...feedback.take(4).map(
                  (entry) => _ListCard(
                    title: _feedbackLabel(entry.feedbackType),
                    subtitle: entry.createdAt.toLocal().toString(),
                    detail: entry.responsePreview,
                    chips: [
                      if (entry.agentTrace.isNotEmpty) 'agent trace',
                    ],
                  ),
                ),
        ],
      ),
    );
  }

  String _feedbackLabel(String type) {
    return switch (type) {
      'helpful' => 'Helpful',
      'not_helpful' => 'Not helpful',
      'wrong_context' => 'Wrong context',
      'too_much' => 'Too much',
      _ => type,
    };
  }
}

class _AuditPanel extends StatelessWidget {
  const _AuditPanel({required this.audits});

  final List<AgentAuditLogEntry> audits;

  @override
  Widget build(BuildContext context) {
    return _DashboardPanel(
      title: 'Agent Audit Trail',
      subtitle: 'Roles, tools, sources, and latency',
      icon: CupertinoIcons.doc_text_search,
      child: audits.isEmpty
          ? const _EmptyText(
              text:
                  'No audit logs yet. Send a message to record the agent path.',
            )
          : Column(
              children: audits
                  .map(
                    (audit) => _ListCard(
                      title: audit.usedLocalModel
                          ? 'Local model: ${audit.modelName}'
                          : 'Deterministic fallback',
                      subtitle: '${audit.latencyMs} ms',
                      detail: audit.userMessagePreview,
                      chips: [
                        ...audit.activatedRoles.take(2),
                        ...audit.toolNames.take(2),
                        ...audit.dataSources.take(2),
                      ],
                    ),
                  )
                  .toList(growable: false),
            ),
    );
  }
}

class _DashboardPanel extends StatelessWidget {
  const _DashboardPanel({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.child,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLow.withValues(alpha: 0.94),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(alpha: 0.7),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: colorScheme.primary),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }
}

class _MetricTile extends StatelessWidget {
  const _MetricTile({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      width: 124,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: Theme.of(context).textTheme.labelSmall),
          const SizedBox(height: 4),
          Text(value, style: Theme.of(context).textTheme.titleLarge),
        ],
      ),
    );
  }
}

class _ListCard extends StatelessWidget {
  const _ListCard({
    required this.title,
    required this.subtitle,
    required this.detail,
    this.chips = const [],
  });

  final String title;
  final String subtitle;
  final String detail;
  final List<String> chips;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: 3),
          Text(
            subtitle,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
          ),
          if (detail.trim().isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              detail,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
          ],
          if (chips.isNotEmpty) ...[
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: chips
                  .where((chip) => chip.trim().isNotEmpty)
                  .map((chip) => _MiniChip(label: chip))
                  .toList(growable: false),
            ),
          ],
        ],
      ),
    );
  }
}

class _MiniChip extends StatelessWidget {
  const _MiniChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Chip(
      label: Text(label),
      side: BorderSide.none,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
    );
  }
}

class _EmptyText extends StatelessWidget {
  const _EmptyText({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
    );
  }
}
