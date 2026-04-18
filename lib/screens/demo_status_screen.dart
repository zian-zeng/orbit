import 'package:chatbotapp/demo/orbit_business_demo_scenario.dart';
import 'package:chatbotapp/hive/monitor_history_entry.dart';
import 'package:chatbotapp/providers/settings_provider.dart';
import 'package:chatbotapp/providers/user_profile_provider.dart';
import 'package:chatbotapp/services/monitor_history_service.dart';
import 'package:chatbotapp/services/student_monitor_service.dart';
import 'package:chatbotapp/services/student_notification_policy.dart';
import 'package:chatbotapp/widgets/app_icon_button.dart';
import 'package:chatbotapp/widgets/app_screen_scaffold.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

class DemoStatusScreen extends StatefulWidget {
  const DemoStatusScreen({super.key});

  static final OrbitBusinessDemoScenario scenario =
      OrbitBusinessDemoScenario.veganUmdStudent();

  @override
  State<DemoStatusScreen> createState() => _DemoStatusScreenState();
}

class _DemoStatusScreenState extends State<DemoStatusScreen> {
  static const StudentMonitorService _monitorService = StudentMonitorService();
  static const StudentNotificationPolicy _notificationPolicy =
      StudentNotificationPolicy();
  static const MonitorHistoryService _historyService = MonitorHistoryService();
  bool _didRequestLiveSignals = false;
  DateTime? _focusStartedAt;
  bool _preferDemoFixture = false;
  List<MonitorHistoryEntry> _history = const [];
  String _lastRecordedMonitorSignature = '';
  bool _isRecordingMonitorHistory = false;
  bool _skipNextMonitorRecord = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      _refreshLiveSignals();
      _loadMonitorHistory(email: DemoStatusScreen.scenario.email);
    });
  }

  void _refreshLiveSignals({bool forceRefresh = false}) {
    if (_didRequestLiveSignals && !forceRefresh) {
      return;
    }
    _didRequestLiveSignals = true;
    final profile = context.read<UserProfileProvider>();
    profile.refreshExternalStudentSignals(
      forceRefresh: forceRefresh,
      taskText: DemoStatusScreen.scenario.demoPrompt,
      preferenceTags: {
        ...profile.routingLabelKeys,
        ...profile.preferredLabelKeys,
        ...DemoStatusScreen.scenario.preferenceLabels,
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final profile = context.watch<UserProfileProvider>();
    final settings = context.watch<SettingsProvider>();
    final report = _monitorService.build(
      studentName: profile.name,
      email: profile.email,
      profileLabels: {
        ...profile.routingLabelKeys,
        ...profile.preferredLabelKeys,
      },
      snapshot: _preferDemoFixture ? null : profile.latestStudentSnapshot,
      fallback: DemoStatusScreen.scenario,
    );
    final notificationPlan = _notificationPolicy.build(
      report: report,
      focusStartedAt: _focusStartedAt,
      focusBreakMinutes: settings.focusBreakMinutes,
    );
    _recordMonitorCheckpoint(report);

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
                      report.isLive ? 'Student Monitor' : 'UMD Demo Path',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      report.isLive
                          ? 'Live signals for ${report.firstName}'
                          : 'Demo fixture for ${report.firstName}',
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                    ),
                  ],
                ),
              ),
              if (profile.isRefreshingExternalSignals)
                const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(strokeWidth: 2.4),
                )
              else
                AppIconButton(
                  icon: CupertinoIcons.arrow_clockwise,
                  tooltip: 'Refresh live signals',
                  onTap: () => _refreshLiveSignals(forceRefresh: true),
                ),
              const SizedBox(width: 8),
              _DemoBadge(label: report.isLive ? 'Live' : 'Demo fixture'),
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
                  final left = Column(
                    children: [
                      _ScenarioPanel(report: report),
                      const SizedBox(height: 12),
                      _StressPanel(report: report),
                      const SizedBox(height: 12),
                      _HistoryPanel(
                        report: report,
                        history: _history,
                        onClear: () => _clearMonitorHistory(report),
                      ),
                      const SizedBox(height: 12),
                      _NotificationPanel(
                        plan: notificationPlan,
                        focusBreakMinutes: settings.focusBreakMinutes,
                        onStartFocus: _startFocusSession,
                        onSimulateLongFocus: () => _simulateLongFocus(
                          settings.focusBreakMinutes,
                        ),
                        onEndFocus: _endFocusSession,
                        onFocusBreakChanged: (value) {
                          settings.setFocusBreakMinutes(value: value);
                        },
                      ),
                      const SizedBox(height: 12),
                      _WorkloadChart(week: report.week),
                    ],
                  );
                  final right = Column(
                    children: [
                      _SearchPanel(report: report),
                      const SizedBox(height: 12),
                      _AgentPanel(report: report),
                      const SizedBox(height: 12),
                      _DatasetPanel(summary: report.datasetSummary),
                      const SizedBox(height: 12),
                      _PrivacyPanel(
                        report: report,
                        preferDemoFixture: _preferDemoFixture,
                        onPreferDemoFixtureChanged: (value) {
                          setState(() {
                            _preferDemoFixture = value;
                          });
                        },
                      ),
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

  void _startFocusSession() {
    setState(() {
      _focusStartedAt = DateTime.now();
    });
  }

  void _simulateLongFocus(int focusBreakMinutes) {
    setState(() {
      _focusStartedAt = DateTime.now().subtract(
        Duration(minutes: focusBreakMinutes + 5),
      );
    });
  }

  void _endFocusSession() {
    setState(() {
      _focusStartedAt = null;
    });
  }

  void _recordMonitorCheckpoint(StudentMonitorReport report) {
    final signature = [
      report.email,
      report.isLive ? 'live' : 'demo',
      report.snapshot.stressRiskScore.toStringAsFixed(3),
      report.snapshot.deadlinesNextSevenDays,
      report.snapshot.calendarHoursNextSevenDays.toStringAsFixed(2),
      report.snapshot.places.length,
      report.snapshot.routes.length,
    ].join('|');
    if (_lastRecordedMonitorSignature == signature ||
        _isRecordingMonitorHistory) {
      return;
    }
    if (_skipNextMonitorRecord) {
      _skipNextMonitorRecord = false;
      _lastRecordedMonitorSignature = signature;
      return;
    }
    _lastRecordedMonitorSignature = signature;

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) {
        return;
      }
      _isRecordingMonitorHistory = true;
      await _historyService.recordReport(report);
      if (!mounted) {
        return;
      }
      _loadMonitorHistory(email: report.email);
      _isRecordingMonitorHistory = false;
    });
  }

  void _loadMonitorHistory({required String email}) {
    if (!mounted) {
      return;
    }
    setState(() {
      _history = _historyService.loadRecent(email: email);
    });
  }

  Future<void> _clearMonitorHistory(StudentMonitorReport report) async {
    await _historyService.clearForStudent(email: report.email);
    if (!mounted) {
      return;
    }
    setState(() {
      _history = const [];
      _lastRecordedMonitorSignature = '';
      _skipNextMonitorRecord = true;
    });
  }
}

class _ScenarioPanel extends StatelessWidget {
  const _ScenarioPanel({required this.report});

  final StudentMonitorReport report;

  @override
  Widget build(BuildContext context) {
    return _DemoPanel(
      title: report.studentName,
      subtitle: report.email,
      icon: CupertinoIcons.person_crop_circle,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(report.subtitle),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: report.profileLabels
                .take(10)
                .map((label) => _DemoChip(label: label))
                .toList(growable: false),
          ),
          const SizedBox(height: 14),
          _SignalGrid(report: report),
          const SizedBox(height: 14),
          Text(
            report.isLive ? 'Monitor prompt' : 'Demo request',
            style: Theme.of(context).textTheme.titleSmall,
          ),
          const SizedBox(height: 6),
          Text(report.prompt),
          const SizedBox(height: 12),
          FilledButton.icon(
            style: _buttonStyle(),
            onPressed: () => Navigator.of(context).pop(report.prompt),
            icon: const Icon(CupertinoIcons.arrow_turn_down_right, size: 16),
            label: const Text('Use this prompt in chat'),
          ),
        ],
      ),
    );
  }
}

class _SignalGrid extends StatelessWidget {
  const _SignalGrid({required this.report});

  final StudentMonitorReport report;

  @override
  Widget build(BuildContext context) {
    final snapshot = report.snapshot;
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        _MetricTile(
          label: 'Canvas',
          value: '${snapshot.assignments.length}',
          detail: 'deadlines',
        ),
        _MetricTile(
          label: 'Calendar',
          value: snapshot.calendarHoursNextSevenDays.toStringAsFixed(1),
          detail: 'hours',
        ),
        _MetricTile(
          label: 'Stress',
          value: '${(snapshot.stressRiskScore * 100).round()}%',
          detail: 'risk',
        ),
        _MetricTile(
          label: 'Places',
          value: '${snapshot.places.length}',
          detail: 'vegan hits',
        ),
      ],
    );
  }
}

class _StressPanel extends StatelessWidget {
  const _StressPanel({required this.report});

  final StudentMonitorReport report;

  @override
  Widget build(BuildContext context) {
    final score = report.snapshot.stressRiskScore;
    return _DemoPanel(
      title: 'Stress Monitor',
      subtitle: score >= 0.72
          ? 'High pressure detected'
          : score >= 0.48
              ? 'Elevated pressure detected'
              : 'Steady pressure detected',
      icon: CupertinoIcons.waveform_path_ecg,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _ProgressMeter(value: score),
          const SizedBox(height: 12),
          ...report.alerts.map(
            (alert) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: _AlertRow(alert: alert),
            ),
          ),
        ],
      ),
    );
  }
}

class _HistoryPanel extends StatelessWidget {
  const _HistoryPanel({
    required this.report,
    required this.history,
    required this.onClear,
  });

  final StudentMonitorReport report;
  final List<MonitorHistoryEntry> history;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final entries = history.isEmpty
        ? [
            MonitorHistoryEntry(
              id: 'preview',
              createdAt: DateTime.now(),
              studentEmail: report.email,
              source: report.isLive ? 'live' : 'demo',
              stressScore: report.snapshot.stressRiskScore,
              deadlines: report.snapshot.deadlinesNextSevenDays,
              calendarHours: report.snapshot.calendarHoursNextSevenDays,
              placeCount: report.snapshot.places.length,
              routeCount: report.snapshot.routes.length,
              labels: report.profileLabels,
              sourceNote: 'Preview until the first checkpoint is stored.',
            ),
          ]
        : history;
    final latest = entries.last;
    final averageStress =
        entries.fold<double>(0, (total, entry) => total + entry.stressScore) /
            entries.length;

    return _DemoPanel(
      title: 'Monitor History',
      subtitle: '${entries.length} saved daily checkpoint'
          '${entries.length == 1 ? '' : 's'}',
      icon: CupertinoIcons.chart_bar_alt_fill,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: _MetricTile(
                  label: 'Latest',
                  value: '${(latest.stressScore * 100).round()}%',
                  detail: latest.source,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _MetricTile(
                  label: 'Avg risk',
                  value: '${(averageStress * 100).round()}%',
                  detail: 'saved',
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          SizedBox(
            height: 150,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: entries
                  .take(14)
                  .map(
                    (entry) => Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 3),
                        child: _HistoryBar(entry: entry),
                      ),
                    ),
                  )
                  .toList(growable: false),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Daily checkpoints turn the monitor into a trend: stress, deadlines, calendar hours, and live/demo source are saved locally.',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
          if (history.isNotEmpty) ...[
            const SizedBox(height: 10),
            OutlinedButton(
              style: _outlinedButtonStyle(),
              onPressed: onClear,
              child: const Text('Clear monitor history'),
            ),
          ],
        ],
      ),
    );
  }
}

class _NotificationPanel extends StatelessWidget {
  const _NotificationPanel({
    required this.plan,
    required this.focusBreakMinutes,
    required this.onStartFocus,
    required this.onSimulateLongFocus,
    required this.onEndFocus,
    required this.onFocusBreakChanged,
  });

  final StudentNotificationPlan plan;
  final int focusBreakMinutes;
  final VoidCallback onStartFocus;
  final VoidCallback onSimulateLongFocus;
  final VoidCallback onEndFocus;
  final ValueChanged<int> onFocusBreakChanged;

  @override
  Widget build(BuildContext context) {
    return _DemoPanel(
      title: 'Notification Center',
      subtitle: 'In-app now, OS notifications later',
      icon: CupertinoIcons.bell,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              _DemoChip(label: 'Focus: ${plan.focusDurationLabel}'),
              _DemoChip(
                label: plan.needsBreak ? 'Break due' : 'Watching',
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...plan.notifications.map(
            (alert) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: _AlertRow(alert: alert),
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              FilledButton(
                style: _buttonStyle(),
                onPressed:
                    plan.hasActiveFocusSession ? onEndFocus : onStartFocus,
                child: Text(
                  plan.hasActiveFocusSession ? 'End focus' : 'Start focus',
                ),
              ),
              OutlinedButton(
                style: _outlinedButtonStyle(),
                onPressed: onSimulateLongFocus,
                child: Text('Simulate ${focusBreakMinutes}m laptop block'),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Text(
                  'Break threshold',
                  style: Theme.of(context).textTheme.titleSmall,
                ),
              ),
              Text('$focusBreakMinutes min'),
            ],
          ),
          Slider(
            min: 15,
            max: 180,
            divisions: 11,
            value: focusBreakMinutes.clamp(15, 180).toDouble(),
            label: '$focusBreakMinutes min',
            onChanged: (value) => onFocusBreakChanged(value.round()),
          ),
          const SizedBox(height: 8),
          Text(
            'Production path: connect this policy to local notifications and platform screen-time permissions.',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
        ],
      ),
    );
  }
}

class _WorkloadChart extends StatelessWidget {
  const _WorkloadChart({required this.week});

  final List<DemoWorkloadDay> week;

  @override
  Widget build(BuildContext context) {
    return _DemoPanel(
      title: 'Workload Shape',
      subtitle: 'Deadlines, calendar load, and stress risk',
      icon: CupertinoIcons.chart_bar,
      child: SizedBox(
        height: 232,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: week
              .map(
                (day) => Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: _DayBar(day: day),
                  ),
                ),
              )
              .toList(growable: false),
        ),
      ),
    );
  }
}

class _SearchPanel extends StatelessWidget {
  const _SearchPanel({required this.report});

  final StudentMonitorReport report;

  @override
  Widget build(BuildContext context) {
    return _DemoPanel(
      title: 'Personalized Food Search',
      subtitle: report.snapshot.places.isEmpty
          ? 'Ready when Places signals are configured'
          : 'No extra diet prompt required',
      icon: CupertinoIcons.location,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            report.snapshot.places.isEmpty
                ? 'No live place search result is loaded yet.'
                : report.snapshot.places.first.reason,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 12),
          if (report.snapshot.places.isEmpty)
            const _PlaceRow(
              name: 'Place search',
              detail:
                  'Enable Google Places and ask a food/location task to populate live results.',
            )
          else
            ...report.snapshot.places.map(
              (place) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: _PlaceRow(
                  name: place.name,
                  detail: place.formattedAddress,
                ),
              ),
            ),
          const SizedBox(height: 8),
          if (report.snapshot.routes.isEmpty)
            const _PlaceRow(
              name: 'Campus route',
              detail:
                  'Enable Google Routes or configure campus origin/destination to show travel time.',
            )
          else
            _PlaceRow(
              name: 'Campus route',
              detail: report.snapshot.routes.first.summary,
            ),
        ],
      ),
    );
  }
}

class _AgentPanel extends StatelessWidget {
  const _AgentPanel({required this.report});

  final StudentMonitorReport report;

  @override
  Widget build(BuildContext context) {
    return _DemoPanel(
      title: 'Agent Execution Path',
      subtitle: 'Labels choose tools before local synthesis',
      icon: CupertinoIcons.wand_stars,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: report.agentTools
                .map((tool) => _DemoChip(label: tool))
                .toList(growable: false),
          ),
          const SizedBox(height: 12),
          Text(
            report.isLive
                ? 'This path is generated from the latest connected student signals.'
                : 'The deterministic controller keeps tool use reliable, while Gemma/Ollama handles the final natural-language synthesis.',
          ),
        ],
      ),
    );
  }
}

class _DatasetPanel extends StatelessWidget {
  const _DatasetPanel({required this.summary});

  final String summary;

  @override
  Widget build(BuildContext context) {
    return _DemoPanel(
      title: 'Dataset Backing',
      subtitle: 'Evaluation fixture plus public-data roadmap',
      icon: CupertinoIcons.square_stack_3d_up,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(summary),
          const SizedBox(height: 12),
          const _DistributionRow(label: 'High', count: 25, total: 40),
          const _DistributionRow(label: 'Elevated', count: 13, total: 40),
          const _DistributionRow(label: 'Steady', count: 2, total: 40),
          const SizedBox(height: 12),
          const Text(
            'Next data step: replace the synthetic fixture with StudentLife, OULAD, and UMD-consented connector exports for stronger model evaluation.',
          ),
        ],
      ),
    );
  }
}

class _PrivacyPanel extends StatelessWidget {
  const _PrivacyPanel({
    required this.report,
    required this.preferDemoFixture,
    required this.onPreferDemoFixtureChanged,
  });

  final StudentMonitorReport report;
  final bool preferDemoFixture;
  final ValueChanged<bool> onPreferDemoFixtureChanged;

  @override
  Widget build(BuildContext context) {
    return _DemoPanel(
      title: 'Data & Privacy',
      subtitle: report.isLive
          ? 'Connected signals are active'
          : 'Using local demo fixture',
      icon: CupertinoIcons.lock_shield,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Use demo fixture'),
            subtitle: const Text(
              'Keep the pitch path deterministic even without credentials.',
            ),
            value: preferDemoFixture,
            onChanged: onPreferDemoFixtureChanged,
          ),
          const SizedBox(height: 8),
          Text(
            report.isLive
                ? 'Live mode uses configured Canvas, Google Calendar, Google Places, and Google Routes signals. Tokens should move to a backend before production.'
                : 'Demo mode uses a local deterministic UMD scenario. No external account data is required.',
          ),
          if (report.snapshot.sourceNotes.isNotEmpty) ...[
            const SizedBox(height: 12),
            ...report.snapshot.sourceNotes.take(3).map(
                  (note) => Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Text('- $note'),
                  ),
                ),
          ],
        ],
      ),
    );
  }
}

class _DemoPanel extends StatelessWidget {
  const _DemoPanel({
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
                    Text(
                      title,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
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
    required this.detail,
  });

  final String label;
  final String value;
  final String detail;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      width: 118,
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
          Text(
            detail,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
          ),
        ],
      ),
    );
  }
}

class _ProgressMeter extends StatelessWidget {
  const _ProgressMeter({required this.value});

  final double value;

  @override
  Widget build(BuildContext context) {
    final clamped = value.clamp(0.0, 1.0);
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                'Stress risk',
                style: Theme.of(context).textTheme.titleSmall,
              ),
            ),
            Text('${(clamped * 100).round()}%'),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: LinearProgressIndicator(
            minHeight: 12,
            value: clamped,
            color: colorScheme.error,
            backgroundColor: colorScheme.errorContainer.withValues(alpha: 0.45),
          ),
        ),
      ],
    );
  }
}

class _AlertRow extends StatelessWidget {
  const _AlertRow({required this.alert});

  final DemoAlert alert;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final color = switch (alert.severity) {
      DemoAlertSeverity.urgent => colorScheme.error,
      DemoAlertSeverity.warning => colorScheme.tertiary,
      DemoAlertSeverity.info => colorScheme.primary,
    };

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(CupertinoIcons.bell, size: 16, color: color),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(alert.title,
                    style: Theme.of(context).textTheme.titleSmall),
                const SizedBox(height: 3),
                Text(alert.detail),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DayBar extends StatelessWidget {
  const _DayBar({required this.day});

  final DemoWorkloadDay day;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final stressHeight = 24 + (day.stressScore.clamp(0.0, 1.0) * 116);
    final calendarHeight = 20 + (day.calendarHours.clamp(0.0, 10.0) * 8);

    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Text('${(day.stressScore * 100).round()}%'),
        const SizedBox(height: 6),
        SizedBox(
          height: 148,
          child: Stack(
            alignment: Alignment.bottomCenter,
            children: [
              Container(
                width: 28,
                height: calendarHeight,
                decoration: BoxDecoration(
                  color: colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
              Container(
                width: 14,
                height: stressHeight,
                decoration: BoxDecoration(
                  color: day.stressScore >= 0.75
                      ? colorScheme.error
                      : colorScheme.primary,
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 6),
        Text(day.label),
        Text(
          '${day.deadlines} due',
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
        ),
      ],
    );
  }
}

class _HistoryBar extends StatelessWidget {
  const _HistoryBar({required this.entry});

  final MonitorHistoryEntry entry;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final score = entry.stressScore.clamp(0.0, 1.0);
    final height = 20 + (score * 68);
    final color = score >= 0.72
        ? colorScheme.error
        : score >= 0.48
            ? colorScheme.tertiary
            : colorScheme.primary;

    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Text(
          '${(score * 100).round()}%',
          style: Theme.of(context).textTheme.labelSmall,
        ),
        const SizedBox(height: 5),
        Container(
          width: 20,
          height: height,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(6),
          ),
        ),
        const SizedBox(height: 5),
        Text(
          entry.dayLabel,
          style: Theme.of(context).textTheme.labelSmall,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }
}

class _PlaceRow extends StatelessWidget {
  const _PlaceRow({
    required this.name,
    required this.detail,
  });

  final String name;
  final String detail;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(name, style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: 3),
          Text(
            detail,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
          ),
        ],
      ),
    );
  }
}

class _DistributionRow extends StatelessWidget {
  const _DistributionRow({
    required this.label,
    required this.count,
    required this.total,
  });

  final String label;
  final int count;
  final int total;

  @override
  Widget build(BuildContext context) {
    final value = count / total;
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          SizedBox(width: 72, child: Text(label)),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(5),
              child: LinearProgressIndicator(
                minHeight: 10,
                value: value,
                backgroundColor: colorScheme.surfaceContainerHighest,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Text('$count/$total'),
        ],
      ),
    );
  }
}

class _DemoChip extends StatelessWidget {
  const _DemoChip({required this.label});

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

class _DemoBadge extends StatelessWidget {
  const _DemoBadge({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: colorScheme.onPrimaryContainer,
            ),
      ),
    );
  }
}

ButtonStyle _buttonStyle() {
  return FilledButton.styleFrom(
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
  );
}

ButtonStyle _outlinedButtonStyle() {
  return OutlinedButton.styleFrom(
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
  );
}

Future<void> copyDemoPromptToClipboard(BuildContext context) async {
  await Clipboard.setData(
    ClipboardData(text: DemoStatusScreen.scenario.demoPrompt),
  );
}
