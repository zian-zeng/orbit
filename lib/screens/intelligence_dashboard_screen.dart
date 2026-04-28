import 'package:chatbotapp/hive/agent_audit_log_entry.dart';
import 'package:chatbotapp/hive/assistant_feedback_entry.dart';
import 'package:chatbotapp/hive/skill_registry_entry.dart';
import 'package:chatbotapp/providers/settings_provider.dart';
import 'package:chatbotapp/providers/user_profile_provider.dart';
import 'package:chatbotapp/services/agent_audit_log_service.dart';
import 'package:chatbotapp/services/assistant_feedback_service.dart';
import 'package:chatbotapp/services/demo_readiness_service.dart';
import 'package:chatbotapp/services/evaluation_readiness_service.dart';
import 'package:chatbotapp/services/skill_registry_service.dart';
import 'package:chatbotapp/widgets/app_icon_button.dart';
import 'package:chatbotapp/widgets/app_screen_scaffold.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class IntelligenceDashboardScreen extends StatefulWidget {
  const IntelligenceDashboardScreen({super.key});

  @override
  State<IntelligenceDashboardScreen> createState() =>
      _IntelligenceDashboardScreenState();
}

class _IntelligenceDashboardScreenState
    extends State<IntelligenceDashboardScreen> {
  static const SkillRegistryService _skillRegistryService =
      SkillRegistryService();
  static const AssistantFeedbackService _feedbackService =
      AssistantFeedbackService();
  static const AgentAuditLogService _auditLogService = AgentAuditLogService();
  static const EvaluationReadinessService _evaluationService =
      EvaluationReadinessService();
  static const DemoReadinessService _readinessService = DemoReadinessService();

  late Future<DemoReadinessReport> _readinessFuture;

  @override
  void initState() {
    super.initState();
    _readinessFuture = _readinessService.buildReport();
  }

  void _refreshReadiness() {
    setState(() {
      _readinessFuture = _readinessService.buildReport();
    });
  }

  Future<void> _resetMayaDemo() async {
    await context.read<UserProfileProvider>().resetDemoUser();
    if (!mounted) {
      return;
    }
    context.read<SettingsProvider>().reloadSavedSettings();
    _refreshReadiness();
  }

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
    final evaluationReport = _evaluationService.buildDemoReport(
      feedbackCount: feedback.length,
      auditCount: audits.length,
      savedSkillCount: skills.length,
    );

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
                      _DemoReadinessPanel(
                        readinessFuture: _readinessFuture,
                        onRefresh: _refreshReadiness,
                        onResetDemo: _resetMayaDemo,
                      ),
                      const SizedBox(height: 12),
                      _EvaluationPanel(report: evaluationReport),
                      const SizedBox(height: 12),
                      _SkillRegistryPanel(skills: skills),
                    ],
                  );
                  final right = Column(
                    children: [
                      _InvestorTourPanel(
                        hasSkills: skills.isNotEmpty,
                        hasAudits: audits.isNotEmpty,
                        hasFeedback: feedback.isNotEmpty,
                      ),
                      const SizedBox(height: 12),
                      _CollaborationPanel(audits: audits),
                      const SizedBox(height: 12),
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

class _DemoReadinessPanel extends StatelessWidget {
  const _DemoReadinessPanel({
    required this.readinessFuture,
    required this.onRefresh,
    required this.onResetDemo,
  });

  final Future<DemoReadinessReport> readinessFuture;
  final VoidCallback onRefresh;
  final VoidCallback onResetDemo;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<DemoReadinessReport>(
      future: readinessFuture,
      builder: (context, snapshot) {
        final report = snapshot.data;
        final loading = snapshot.connectionState != ConnectionState.done;
        return _DashboardPanel(
          title: 'Demo Readiness',
          subtitle: report?.summaryLabel ?? 'Checking local demo state',
          icon: CupertinoIcons.checkmark_shield_fill,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (loading)
                const LinearProgressIndicator(minHeight: 6)
              else if (report == null)
                const _EmptyText(text: 'Could not read demo readiness.')
              else ...[
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _MetricTile(
                      label: 'Ready',
                      value: '${report.readyCount}/${report.items.length}',
                    ),
                    _MetricTile(
                      label: 'Checked',
                      value:
                          '${report.checkedAt.hour.toString().padLeft(2, '0')}:${report.checkedAt.minute.toString().padLeft(2, '0')}',
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                ...report.items.map(
                  (item) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: _ReadinessRow(item: item),
                  ),
                ),
              ],
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  OutlinedButton.icon(
                    onPressed: onRefresh,
                    icon: const Icon(CupertinoIcons.arrow_clockwise),
                    label: const Text('Refresh readiness'),
                  ),
                  FilledButton.icon(
                    onPressed: onResetDemo,
                    icon: const Icon(CupertinoIcons.person_crop_circle),
                    label: const Text('Reset Maya demo'),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

class _ReadinessRow extends StatelessWidget {
  const _ReadinessRow({required this.item});

  final DemoReadinessItem item;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final (icon, color) = switch (item.state) {
      DemoReadinessState.ready => (
          CupertinoIcons.checkmark_circle_fill,
          colorScheme.primary,
        ),
      DemoReadinessState.warning => (
          CupertinoIcons.exclamationmark_triangle_fill,
          colorScheme.tertiary,
        ),
      DemoReadinessState.missing => (
          CupertinoIcons.xmark_circle_fill,
          colorScheme.error,
        ),
    };

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 17, color: color),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(item.label, style: Theme.of(context).textTheme.labelLarge),
              const SizedBox(height: 2),
              Text(
                item.detail,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _InvestorTourPanel extends StatelessWidget {
  const _InvestorTourPanel({
    required this.hasSkills,
    required this.hasAudits,
    required this.hasFeedback,
  });

  final bool hasSkills;
  final bool hasAudits;
  final bool hasFeedback;

  @override
  Widget build(BuildContext context) {
    return _DashboardPanel(
      title: 'Investor Tour',
      subtitle: 'Five-minute proof path',
      icon: CupertinoIcons.play_rectangle_fill,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _TourStep(
            title: 'Log in as Maya',
            detail: 'Open the finished student profile with local history.',
            complete: true,
          ),
          const _TourStep(
            title: 'Show UMD Demo Path',
            detail:
                'Canvas, Calendar, Places, Routes, stress, and action plan.',
            complete: true,
          ),
          _TourStep(
            title: 'Send the demo prompt',
            detail: 'Show Gemma/Gemini synthesis plus deterministic fallback.',
            complete: hasAudits,
          ),
          _TourStep(
            title: 'Open Agent Collaboration',
            detail:
                'Explain labels + history + current query -> runtime skill.',
            complete: hasAudits,
          ),
          _TourStep(
            title: 'Show learning loop',
            detail:
                'Saved skills and feedback prove personalization can improve.',
            complete: hasSkills && hasFeedback,
          ),
        ],
      ),
    );
  }
}

class _TourStep extends StatelessWidget {
  const _TourStep({
    required this.title,
    required this.detail,
    required this.complete,
  });

  final String title;
  final String detail;
  final bool complete;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            complete
                ? CupertinoIcons.checkmark_circle_fill
                : CupertinoIcons.circle,
            size: 17,
            color: complete ? colorScheme.primary : colorScheme.outline,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: Theme.of(context).textTheme.labelLarge),
                const SizedBox(height: 2),
                Text(
                  detail,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CollaborationPanel extends StatelessWidget {
  const _CollaborationPanel({required this.audits});

  final List<AgentAuditLogEntry> audits;

  @override
  Widget build(BuildContext context) {
    final audit = audits.isEmpty ? null : audits.first;
    final labels =
        audit?.labelKeys.take(8).toList(growable: false) ?? const <String>[];
    final roles = audit?.activatedRoles.take(6).toList(growable: false) ??
        const <String>[];
    final tools =
        audit?.toolNames.take(6).toList(growable: false) ?? const <String>[];

    return _DashboardPanel(
      title: 'Agent Collaboration',
      subtitle: 'Labels + history + query -> runtime skill',
      icon: CupertinoIcons.flowchart_fill,
      child: audit == null
          ? const _EmptyText(
              text:
                  'No collaboration trace yet. Log in as Maya or send a message to create one.',
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _TraceStep(
                  label: '1. Personal context',
                  value:
                      labels.isEmpty ? 'No labels captured' : labels.join(', '),
                ),
                const SizedBox(height: 8),
                _TraceStep(
                  label: '2. Current query',
                  value: audit.userMessagePreview,
                ),
                const SizedBox(height: 8),
                _TraceStep(
                  label: '3. Runtime skill',
                  value: audit.skillIds.isEmpty
                      ? 'No generated skill recorded'
                      : audit.skillIds.first,
                ),
                const SizedBox(height: 8),
                _TraceStep(
                  label: '4. Agent roles',
                  value:
                      roles.isEmpty ? 'No roles recorded' : roles.join(' -> '),
                ),
                const SizedBox(height: 8),
                _TraceStep(
                  label: '5. Tool path',
                  value:
                      tools.isEmpty ? 'No tools recorded' : tools.join(' -> '),
                ),
              ],
            ),
    );
  }
}

class _TraceStep extends StatelessWidget {
  const _TraceStep({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHigh.withValues(alpha: 0.62),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(alpha: 0.55),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: Theme.of(context).textTheme.labelLarge),
          const SizedBox(height: 4),
          Text(
            value,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
          ),
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

class _EvaluationPanel extends StatelessWidget {
  const _EvaluationPanel({required this.report});

  final EvaluationReadinessReport report;

  @override
  Widget build(BuildContext context) {
    return _DashboardPanel(
      title: 'Evaluation Readiness',
      subtitle: report.readinessLabel,
      icon: CupertinoIcons.checkmark_seal_fill,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _MetricTile(
                  label: 'Fixture users', value: '${report.fixtureSize}'),
              _MetricTile(
                label: 'High stress',
                value: '${report.highStressCases}',
              ),
              _MetricTile(
                label: 'Elevated',
                value: '${report.elevatedCases}',
              ),
              _MetricTile(label: 'Steady', value: '${report.steadyCases}'),
            ],
          ),
          const SizedBox(height: 12),
          ...report.metrics.map(
            (metric) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: _MetricCheck(metric: metric),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Course planner proof: ${report.coursePlan.plannedCredits}/${report.coursePlan.targetCredits} credits, '
            '${report.coursePlan.recommendations.where((item) => item.course.isHeavy).length} heavy course, '
            '${report.coursePlan.recommendations.length} recommendations.',
          ),
          const SizedBox(height: 12),
          Text(
            'Remaining production gaps',
            style: Theme.of(context).textTheme.titleSmall,
          ),
          const SizedBox(height: 6),
          ...report.productionGaps.take(4).map(
                (gap) => Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Text('- $gap'),
                ),
              ),
        ],
      ),
    );
  }
}

class _MetricCheck extends StatelessWidget {
  const _MetricCheck({required this.metric});

  final EvaluationMetric metric;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          metric.passed
              ? CupertinoIcons.checkmark_circle_fill
              : CupertinoIcons.exclamationmark_triangle_fill,
          size: 16,
          color: metric.passed ? colorScheme.primary : colorScheme.tertiary,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            '${metric.label}: ${metric.value} (target ${metric.target})',
          ),
        ),
      ],
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
