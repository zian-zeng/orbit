import 'dart:math' as math;

import 'package:chatbotapp/constants/constants.dart';
import 'package:chatbotapp/demo/orbit_business_demo_scenario.dart';
import 'package:chatbotapp/hive/boxes.dart';
import 'package:chatbotapp/hive/monitor_history_entry.dart';
import 'package:chatbotapp/providers/user_profile_provider.dart';
import 'package:chatbotapp/widgets/app_icon_button.dart';
import 'package:chatbotapp/widgets/app_screen_scaffold.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:provider/provider.dart';

class StudentReportScreen extends StatefulWidget {
  const StudentReportScreen({super.key});

  @override
  State<StudentReportScreen> createState() => _StudentReportScreenState();
}

class _StudentReportScreenState extends State<StudentReportScreen> {
  static const _ranges = [
    _ReportRange(id: 'now', label: 'Now'),
    _ReportRange(id: '3d', label: '3 days', duration: Duration(days: 3)),
    _ReportRange(id: '7d', label: 'Week', duration: Duration(days: 7)),
    _ReportRange(id: '30d', label: 'Month', duration: Duration(days: 30)),
    _ReportRange(id: '6m', label: '6 months', duration: Duration(days: 183)),
    _ReportRange(id: '1y', label: 'Full year', duration: Duration(days: 365)),
    _ReportRange(id: 'ytd', label: 'YTD'),
    _ReportRange(id: 'all', label: 'All time'),
  ];

  _ReportRange _selectedRange = _ranges.first;

  @override
  Widget build(BuildContext context) {
    final profile = context.watch<UserProfileProvider>();
    final entries = _loadEntries(profile.email);
    final selectedEntries = _selectEntries(entries, _selectedRange);
    final summary = _ReportSummary.fromEntries(
      selectedEntries.isEmpty ? entries.takeLast(1) : selectedEntries,
    );
    final recommendations = _recommendations(summary, _selectedRange);

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
                      'Student Report',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${profile.name} | ${entries.length} local checkpoints',
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
                  final overview = Column(
                    children: [
                      _RangeSelector(
                        ranges: _ranges,
                        selected: _selectedRange,
                        onSelected: (range) {
                          setState(() {
                            _selectedRange = range;
                          });
                        },
                      ),
                      const SizedBox(height: 12),
                      _WellbeingOverviewPanel(
                        summary: summary,
                        range: _selectedRange,
                      ),
                      const SizedBox(height: 12),
                      _PulseScorePanel(summary: summary),
                      const SizedBox(height: 12),
                      _StatusPanel(summary: summary, range: _selectedRange),
                      const SizedBox(height: 12),
                      _TrendPanel(
                          entries: selectedEntries, range: _selectedRange),
                      const SizedBox(height: 12),
                      _PressureMixPanel(summary: summary),
                    ],
                  );
                  final guidance = Column(
                    children: [
                      _RecommendationPanel(
                        recommendations: recommendations,
                        range: _selectedRange,
                      ),
                      const SizedBox(height: 12),
                      _OutlookPanel(summary: summary, range: _selectedRange),
                      const SizedBox(height: 12),
                      _CarePlanPanel(summary: summary),
                      const SizedBox(height: 12),
                      _DataCoveragePanel(
                        totalEntries: entries.length,
                        selectedEntries: selectedEntries.length,
                        range: _selectedRange,
                      ),
                    ],
                  );

                  if (!wide) {
                    return Column(
                      children: [
                        overview,
                        const SizedBox(height: 12),
                        guidance,
                      ],
                    );
                  }

                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(child: overview),
                      const SizedBox(width: 12),
                      Expanded(child: guidance),
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

  List<MonitorHistoryEntry> _loadEntries(String email) {
    if (!Hive.isBoxOpen(Constants.monitorHistoryBox)) {
      return _previewEntries();
    }
    final normalizedEmail = email.trim().toLowerCase();
    final demoEmail =
        OrbitBusinessDemoScenario.veganUmdStudent().email.trim().toLowerCase();
    final key = normalizedEmail.isEmpty ? demoEmail : normalizedEmail;
    final entries = Boxes.getMonitorHistory()
        .values
        .where((entry) => entry.studentEmail.trim().toLowerCase() == key)
        .toList(growable: false)
      ..sort((left, right) => left.createdAt.compareTo(right.createdAt));

    return entries.isEmpty ? _previewEntries() : entries;
  }

  List<MonitorHistoryEntry> _previewEntries() {
    final scenario = OrbitBusinessDemoScenario.veganUmdStudent();
    return [
      MonitorHistoryEntry(
        id: 'report-preview',
        createdAt: DateTime.now(),
        studentEmail: scenario.email,
        source: 'demo',
        stressScore: scenario.snapshot.stressRiskScore,
        deadlines: scenario.snapshot.deadlinesNextSevenDays,
        calendarHours: scenario.snapshot.calendarHoursNextSevenDays,
        placeCount: scenario.snapshot.places.length,
        routeCount: scenario.snapshot.routes.length,
        labels: scenario.preferenceLabels,
        sourceNote: 'Preview from the deterministic UMD demo fixture.',
      ),
    ];
  }

  List<MonitorHistoryEntry> _selectEntries(
    List<MonitorHistoryEntry> entries,
    _ReportRange range,
  ) {
    if (entries.isEmpty) {
      return const [];
    }
    if (range.id == 'now') {
      return [entries.last];
    }
    if (range.id == 'all') {
      return entries;
    }
    final now = DateTime.now();
    if (range.id == 'ytd') {
      final start = DateTime(now.year);
      return entries
          .where((entry) => !entry.createdAt.isBefore(start))
          .toList();
    }
    final duration = range.duration;
    if (duration == null) {
      return entries;
    }
    final start = now.subtract(duration);
    return entries.where((entry) => !entry.createdAt.isBefore(start)).toList();
  }

  List<_ReportRecommendation> _recommendations(
    _ReportSummary summary,
    _ReportRange range,
  ) {
    final recommendations = <_ReportRecommendation>[];
    if (summary.latestStress >= 0.72 || summary.averageStress >= 0.65) {
      recommendations.add(
        const _ReportRecommendation(
          title: 'Let us make the next step smaller',
          detail:
              'You have been carrying a lot. I would keep today gentle: one 20-minute checkpoint, one clear stopping point, and no guilt for choosing a smaller step that you can actually finish.',
          icon: CupertinoIcons.waveform_path_ecg,
        ),
      );
    } else if (summary.averageStress >= 0.45) {
      recommendations.add(
        const _ReportRecommendation(
          title: 'Protect one recovery pocket',
          detail:
              'Your workload is workable, but it is not light. I would put a short reset on the calendar before adding another task, so you get a real breath instead of only another obligation.',
          icon: CupertinoIcons.timer,
        ),
      );
    } else {
      recommendations.add(
        const _ReportRecommendation(
          title: 'Keep this calmer rhythm going',
          detail:
              'This steadier window is worth protecting. Finish one visible task, let that count, and do not manufacture urgency just because you finally have a little room.',
          icon: CupertinoIcons.checkmark_circle,
        ),
      );
    }

    if (summary.deadlinePressure >= 0.72) {
      recommendations.add(
        const _ReportRecommendation(
          title: 'Choose the deadline that needs care first',
          detail:
              'Before opening every Canvas tab, sort the work by due window, grade impact, and confusion level. Start with the one that would make tomorrow feel heavier if it stayed untouched.',
          icon: CupertinoIcons.doc_text_search,
        ),
      );
    }

    if (summary.calendarPressure >= 0.72) {
      recommendations.add(
        const _ReportRecommendation(
          title: 'Leave white space around the busy parts',
          detail:
              'Your calendar is doing a lot. I would keep buffer around class, work, food, and commute, because a normal delay should not be allowed to take the whole day with it.',
          icon: CupertinoIcons.calendar,
        ),
      );
    }

    if (summary.trend > 0.08) {
      recommendations.add(
        _ReportRecommendation(
          title: 'Your trend is asking for gentleness',
          detail:
              '${range.label} is moving upward. I would read that as a care signal, not a character flaw: choose fewer tasks, make the first action almost too easy to begin, and let momentum build quietly.',
          icon: CupertinoIcons.arrow_up_right,
        ),
      );
    }

    if (summary.recoveryScore < 0.42) {
      recommendations.add(
        const _ReportRecommendation(
          title: 'Put recovery on the plan, not after it',
          detail:
              'You are more likely to follow through if food, rest, and transition time are treated as part of the plan. I would block those first, then fit the work around them.',
          icon: CupertinoIcons.moon_stars,
        ),
      );
    }

    return recommendations.take(4).toList(growable: false);
  }
}

class _ReportRange {
  const _ReportRange({
    required this.id,
    required this.label,
    this.duration,
  });

  final String id;
  final String label;
  final Duration? duration;
}

double _normalizedStressScore(double value) {
  if (value.isNaN || value.isInfinite) {
    return 0;
  }
  if (value > 1) {
    return (value / 100).clamp(0.0, 1.0);
  }
  return value.clamp(0.0, 1.0);
}

class _ReportSummary {
  const _ReportSummary({
    required this.count,
    required this.latestStress,
    required this.averageStress,
    required this.averageDeadlines,
    required this.averageCalendarHours,
    required this.trend,
    required this.happinessScore,
    required this.focusScore,
    required this.recoveryScore,
    required this.balanceScore,
    required this.deadlinePressure,
    required this.calendarPressure,
    required this.momentumScore,
    required this.supportScore,
  });

  final int count;
  final double latestStress;
  final double averageStress;
  final double averageDeadlines;
  final double averageCalendarHours;
  final double trend;
  final double happinessScore;
  final double focusScore;
  final double recoveryScore;
  final double balanceScore;
  final double deadlinePressure;
  final double calendarPressure;
  final double momentumScore;
  final double supportScore;

  factory _ReportSummary.fromEntries(List<MonitorHistoryEntry> entries) {
    if (entries.isEmpty) {
      return const _ReportSummary(
        count: 0,
        latestStress: 0,
        averageStress: 0,
        averageDeadlines: 0,
        averageCalendarHours: 0,
        trend: 0,
        happinessScore: 0,
        focusScore: 0,
        recoveryScore: 0,
        balanceScore: 0,
        deadlinePressure: 0,
        calendarPressure: 0,
        momentumScore: 0,
        supportScore: 0,
      );
    }
    final normalizedStressValues =
        entries.map((entry) => _normalizedStressScore(entry.stressScore));
    final averageStress = normalizedStressValues.average();
    final averageDeadlines =
        entries.map((entry) => entry.deadlines.toDouble()).average();
    final averageHours = entries.map((entry) => entry.calendarHours).average();
    final deadlinePressure = (averageDeadlines / 5).clamp(0.0, 1.0);
    final calendarPressure = (averageHours / 8).clamp(0.0, 1.0);
    final stressPressure = averageStress.clamp(0.0, 1.0);
    final happiness = (1 -
            ((stressPressure * 0.55) +
                (deadlinePressure * 0.25) +
                (calendarPressure * 0.2)))
        .clamp(0.0, 1.0);
    final focus = (1 -
            ((calendarPressure * 0.42) +
                (stressPressure * 0.38) +
                (deadlinePressure * 0.2)))
        .clamp(0.0, 1.0);
    final recovery = (1 -
            ((stressPressure * 0.45) +
                (calendarPressure * 0.35) +
                (deadlinePressure * 0.2)))
        .clamp(0.0, 1.0);
    final balance = ((happiness + focus + recovery) / 3).clamp(0.0, 1.0);
    final trend = entries.length < 2
        ? 0.0
        : _normalizedStressScore(entries.last.stressScore) -
            _normalizedStressScore(entries.first.stressScore);
    final momentum =
        (0.68 + (-trend * 0.9) - (stressPressure * 0.24)).clamp(0.0, 1.0);
    final support = (1 -
            ((stressPressure * 0.36) +
                (deadlinePressure * 0.34) +
                (calendarPressure * 0.3)))
        .clamp(0.0, 1.0);
    return _ReportSummary(
      count: entries.length,
      latestStress: _normalizedStressScore(entries.last.stressScore),
      averageStress: averageStress,
      averageDeadlines: averageDeadlines,
      averageCalendarHours: averageHours,
      trend: trend,
      happinessScore: happiness,
      focusScore: focus,
      recoveryScore: recovery,
      balanceScore: balance,
      deadlinePressure: deadlinePressure,
      calendarPressure: calendarPressure,
      momentumScore: momentum,
      supportScore: support,
    );
  }
}

class _ReportRecommendation {
  const _ReportRecommendation({
    required this.title,
    required this.detail,
    required this.icon,
  });

  final String title;
  final String detail;
  final IconData icon;
}

class _RangeSelector extends StatelessWidget {
  const _RangeSelector({
    required this.ranges,
    required this.selected,
    required this.onSelected,
  });

  final List<_ReportRange> ranges;
  final _ReportRange selected;
  final ValueChanged<_ReportRange> onSelected;

  @override
  Widget build(BuildContext context) {
    return _ReportPanel(
      title: 'Range',
      subtitle: 'Current, short-term, and long-term views',
      icon: CupertinoIcons.slider_horizontal_3,
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: ranges
            .map(
              (range) => ChoiceChip(
                label: Text(range.label),
                selected: selected.id == range.id,
                onSelected: (_) => onSelected(range),
              ),
            )
            .toList(growable: false),
      ),
    );
  }
}

class _StatusPanel extends StatelessWidget {
  const _StatusPanel({
    required this.summary,
    required this.range,
  });

  final _ReportSummary summary;
  final _ReportRange range;

  @override
  Widget build(BuildContext context) {
    return _ReportPanel(
      title: '${range.label} Status',
      subtitle: '${summary.count} checkpoint${summary.count == 1 ? '' : 's'}',
      icon: CupertinoIcons.gauge,
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          _MetricTile(
            label: 'Latest stress',
            value: '${(summary.latestStress * 100).round()}%',
          ),
          _MetricTile(
            label: 'Avg stress',
            value: '${(summary.averageStress * 100).round()}%',
          ),
          _MetricTile(
            label: 'Avg deadlines',
            value: summary.averageDeadlines.toStringAsFixed(1),
          ),
          _MetricTile(
            label: 'Avg calendar',
            value: '${summary.averageCalendarHours.toStringAsFixed(1)}h',
          ),
          _MetricTile(
            label: 'Happiness',
            value: '${(summary.happinessScore * 100).round()}%',
          ),
          _MetricTile(
            label: 'Focus room',
            value: '${(summary.focusScore * 100).round()}%',
          ),
          _MetricTile(
            label: 'Recovery',
            value: '${(summary.recoveryScore * 100).round()}%',
          ),
          _MetricTile(
            label: 'Momentum',
            value: '${(summary.momentumScore * 100).round()}%',
          ),
        ],
      ),
    );
  }
}

class _PulseScorePanel extends StatelessWidget {
  const _PulseScorePanel({required this.summary});

  final _ReportSummary summary;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return _ReportPanel(
      title: 'Wellbeing Snapshot',
      subtitle: 'Ratings ORBIT uses to personalize support',
      icon: CupertinoIcons.sparkles,
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _PulseCard(
                  label: 'Happiness',
                  value: summary.happinessScore,
                  color: colorScheme.tertiary,
                  icon: CupertinoIcons.smiley,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _PulseCard(
                  label: 'Stress ease',
                  value: 1 - summary.averageStress,
                  color: colorScheme.error,
                  icon: CupertinoIcons.heart,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _PulseCard(
                  label: 'Focus',
                  value: summary.focusScore,
                  color: colorScheme.primary,
                  icon: CupertinoIcons.bolt_fill,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _PulseCard(
                  label: 'Support fit',
                  value: summary.supportScore,
                  color: colorScheme.secondary,
                  icon: CupertinoIcons.person_2,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _WellbeingOverviewPanel extends StatelessWidget {
  const _WellbeingOverviewPanel({
    required this.summary,
    required this.range,
  });

  final _ReportSummary summary;
  final _ReportRange range;

  @override
  Widget build(BuildContext context) {
    return _ReportPanel(
      title: 'How You Are Doing',
      subtitle: 'A human-readable view of ${range.label.toLowerCase()}',
      icon: CupertinoIcons.heart_fill,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _advisorSummary(summary),
            style:
                Theme.of(context).textTheme.bodyLarge?.copyWith(height: 1.42),
          ),
          const SizedBox(height: 14),
          _RatingBar(
            label: 'Happiness',
            value: summary.happinessScore,
            detail: 'How much room the day leaves for feeling okay.',
          ),
          _RatingBar(
            label: 'Stress level',
            value: 1 - summary.averageStress,
            detail: 'Higher means the load is feeling more manageable.',
          ),
          _RatingBar(
            label: 'Focus room',
            value: summary.focusScore,
            detail: 'How much uninterrupted attention the schedule supports.',
          ),
          _RatingBar(
            label: 'Recovery room',
            value: summary.recoveryScore,
            detail: 'How much space exists to reset before the next push.',
          ),
          _RatingBar(
            label: 'Momentum',
            value: summary.momentumScore,
            detail: 'Whether stress is trending toward easier next steps.',
          ),
        ],
      ),
    );
  }

  String _advisorSummary(_ReportSummary summary) {
    if (summary.averageStress >= 0.68) {
      return 'You are not behind as a person; your system is just carrying a heavy load. ORBIT would treat this as a care-first window: fewer commitments, clearer first steps, and a little protection around food, rest, and commute time.';
    }
    if (summary.averageStress >= 0.45) {
      return 'This looks like a busy but steerable stretch. The best move is not to do everything; it is to choose the next useful thing and keep enough slack that the day can still bend.';
    }
    return 'Your signals look steadier here. This is a good moment to build confidence: finish one meaningful task, keep the routine gentle, and avoid adding pressure just because there is space.';
  }
}

class _PressureMixPanel extends StatelessWidget {
  const _PressureMixPanel({required this.summary});

  final _ReportSummary summary;

  @override
  Widget build(BuildContext context) {
    return _ReportPanel(
      title: 'Pressure Mix',
      subtitle: 'What is contributing most right now',
      icon: CupertinoIcons.chart_pie_fill,
      child: Column(
        children: [
          _PressureRow(
            label: 'Stress',
            value: summary.averageStress,
            color: Theme.of(context).colorScheme.error,
          ),
          _PressureRow(
            label: 'Deadlines',
            value: (summary.averageDeadlines / 5).clamp(0.0, 1.0),
            color: Theme.of(context).colorScheme.tertiary,
          ),
          _PressureRow(
            label: 'Calendar density',
            value: (summary.averageCalendarHours / 8).clamp(0.0, 1.0),
            color: Theme.of(context).colorScheme.primary,
          ),
          _PressureRow(
            label: 'Overall balance',
            value: summary.balanceScore,
            color: Theme.of(context).colorScheme.secondary,
          ),
        ],
      ),
    );
  }
}

class _OutlookPanel extends StatelessWidget {
  const _OutlookPanel({
    required this.summary,
    required this.range,
  });

  final _ReportSummary summary;
  final _ReportRange range;

  @override
  Widget build(BuildContext context) {
    final outlook = summary.trend > 0.08
        ? 'The next few days deserve a lighter plan than your instinct may want. Protect one easy win and one recovery block.'
        : summary.averageStress >= 0.6
            ? 'You can still stabilize this. Start with the nearest deadline, then make food and transition time explicit.'
            : 'There is enough room to be thoughtful. Use the steadier window to prepare before the next busy patch.';

    return _ReportPanel(
      title: 'Advisor Outlook',
      subtitle: 'What ORBIT would watch next',
      icon: CupertinoIcons.compass,
      child: Text(
        outlook,
        style: Theme.of(context).textTheme.bodyLarge?.copyWith(height: 1.42),
      ),
    );
  }
}

class _CarePlanPanel extends StatelessWidget {
  const _CarePlanPanel({required this.summary});

  final _ReportSummary summary;

  @override
  Widget build(BuildContext context) {
    return _ReportPanel(
      title: 'Next Best Moves',
      subtitle: 'A care-first plan for the selected window',
      icon: CupertinoIcons.list_bullet,
      child: Column(
        children: [
          _CareStep(
            label: 'First',
            title: _firstMove(summary),
            detail:
                'Start with something small enough that you do not have to negotiate with yourself to begin.',
          ),
          const SizedBox(height: 10),
          _CareStep(
            label: 'Then',
            title: _secondMove(summary),
            detail:
                'Keep the plan honest about food, commute, work shifts, and the energy you actually have.',
          ),
          const SizedBox(height: 10),
          _CareStep(
            label: 'Watch',
            title: _watchSignal(summary),
            detail:
                'If this signal changes, ORBIT should adjust the agent path instead of giving you a generic pep talk.',
          ),
        ],
      ),
    );
  }

  String _firstMove(_ReportSummary summary) {
    if (summary.deadlinePressure >= 0.72) {
      return 'Open the nearest high-impact assignment and define one checkpoint.';
    }
    if (summary.averageStress >= 0.6) {
      return 'Pick the smallest stabilizing action before planning the whole day.';
    }
    return 'Use the steadier moment to finish one visible academic task.';
  }

  String _secondMove(_ReportSummary summary) {
    if (summary.calendarPressure >= 0.72) {
      return 'Add buffer around the busiest calendar block before adding work.';
    }
    if (summary.recoveryScore < 0.45) {
      return 'Schedule a real reset before the next study push.';
    }
    return 'Keep one open pocket so the day can flex without collapsing.';
  }

  String _watchSignal(_ReportSummary summary) {
    if (summary.trend > 0.08) {
      return 'Stress is climbing, so the plan should get simpler.';
    }
    if (summary.momentumScore >= 0.65) {
      return 'Momentum is usable, so protect it with a clear stopping point.';
    }
    return 'Balance is mixed, so avoid stacking commitments too tightly.';
  }
}

class _TrendPanel extends StatelessWidget {
  const _TrendPanel({
    required this.entries,
    required this.range,
  });

  final List<MonitorHistoryEntry> entries;
  final _ReportRange range;

  @override
  Widget build(BuildContext context) {
    return _ReportPanel(
      title: '${range.label} Trend',
      subtitle: 'Stress, deadlines, and calendar pressure',
      icon: CupertinoIcons.chart_bar_alt_fill,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            height: 180,
            child: entries.isEmpty
                ? const Center(child: Text('No report data yet'))
                : Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: entries
                        .takeLast(32)
                        .map(
                          (entry) => Expanded(
                            child: Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 2),
                              child: _ReportBar(entry: entry),
                            ),
                          ),
                        )
                        .toList(growable: false),
                  ),
          ),
          const SizedBox(height: 10),
          Text(
            'Bars show stress risk. The small marker indicates deadline pressure for that checkpoint.',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
        ],
      ),
    );
  }
}

class _RecommendationPanel extends StatelessWidget {
  const _RecommendationPanel({
    required this.recommendations,
    required this.range,
  });

  final List<_ReportRecommendation> recommendations;
  final _ReportRange range;

  @override
  Widget build(BuildContext context) {
    return _ReportPanel(
      title: '${range.label} Recommendations',
      subtitle: 'Actions based on the selected status window',
      icon: CupertinoIcons.lightbulb,
      child: Column(
        children: recommendations
            .map(
              (recommendation) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _RecommendationTile(recommendation: recommendation),
              ),
            )
            .toList(growable: false),
      ),
    );
  }
}

class _DataCoveragePanel extends StatelessWidget {
  const _DataCoveragePanel({
    required this.totalEntries,
    required this.selectedEntries,
    required this.range,
  });

  final int totalEntries;
  final int selectedEntries;
  final _ReportRange range;

  @override
  Widget build(BuildContext context) {
    return _ReportPanel(
      title: 'Data Coverage',
      subtitle: 'Local-only reporting',
      icon: CupertinoIcons.lock_shield,
      child: Text(
        'This report uses $selectedEntries checkpoint${selectedEntries == 1 ? '' : 's'} for ${range.label.toLowerCase()} and $totalEntries total local checkpoint${totalEntries == 1 ? '' : 's'}. Longer ranges fill in as the student keeps using ORBIT.',
        style: Theme.of(context).textTheme.bodyMedium,
      ),
    );
  }
}

class _PulseCard extends StatelessWidget {
  const _PulseCard({
    required this.label,
    required this.value,
    required this.color,
    required this.icon,
  });

  final String label;
  final double value;
  final Color color;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final percent = (value.clamp(0.0, 1.0) * 100).round();

    return Container(
      constraints: const BoxConstraints(minHeight: 112),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.28)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: color),
              const Spacer(),
              Text(
                '$percent%',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: colorScheme.onSurface,
                      fontWeight: FontWeight.w700,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(label, style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: value.clamp(0.0, 1.0),
              minHeight: 8,
              color: color,
              backgroundColor: color.withValues(alpha: 0.16),
            ),
          ),
        ],
      ),
    );
  }
}

class _RatingBar extends StatelessWidget {
  const _RatingBar({
    required this.label,
    required this.value,
    required this.detail,
  });

  final String label;
  final double value;
  final String detail;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final normalized = value.clamp(0.0, 1.0);

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  label,
                  style: Theme.of(context).textTheme.titleSmall,
                ),
              ),
              Text(
                '${(normalized * 100).round()}%',
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: normalized,
              minHeight: 9,
              color: normalized >= 0.66
                  ? colorScheme.secondary
                  : normalized >= 0.42
                      ? colorScheme.primary
                      : colorScheme.error,
              backgroundColor:
                  colorScheme.surfaceContainerHighest.withValues(alpha: 0.9),
            ),
          ),
          const SizedBox(height: 4),
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

class _PressureRow extends StatelessWidget {
  const _PressureRow({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final double value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final normalized = value.clamp(0.0, 1.0);

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          SizedBox(
            width: 112,
            child: Text(
              label,
              style: Theme.of(context).textTheme.labelLarge,
            ),
          ),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(999),
              child: LinearProgressIndicator(
                value: normalized,
                minHeight: 10,
                color: color,
                backgroundColor:
                    colorScheme.surfaceContainerHighest.withValues(alpha: 0.9),
              ),
            ),
          ),
          const SizedBox(width: 10),
          SizedBox(
            width: 40,
            child: Text(
              '${(normalized * 100).round()}%',
              textAlign: TextAlign.end,
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CareStep extends StatelessWidget {
  const _CareStep({
    required this.label,
    required this.title,
    required this.detail,
  });

  final String label;
  final String title;
  final String detail;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHigh.withValues(alpha: 0.68),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(alpha: 0.52),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 46,
            padding: const EdgeInsets.symmetric(vertical: 5),
            decoration: BoxDecoration(
              color: colorScheme.primaryContainer.withValues(alpha: 0.72),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              label,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: colorScheme.onPrimaryContainer,
                    fontWeight: FontWeight.w700,
                  ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: Theme.of(context).textTheme.titleSmall),
                const SizedBox(height: 4),
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

class _ReportPanel extends StatelessWidget {
  const _ReportPanel({
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
      width: 132,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHigh.withValues(alpha: 0.75),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
          ),
          const SizedBox(height: 4),
          Text(value, style: Theme.of(context).textTheme.titleLarge),
        ],
      ),
    );
  }
}

class _ReportBar extends StatelessWidget {
  const _ReportBar({required this.entry});

  final MonitorHistoryEntry entry;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final stressScore = _normalizedStressScore(entry.stressScore);
    final stressHeight = (stressScore.clamp(0.05, 1.0) * 150).toDouble();
    final deadlineHeight = math.min(28.0, entry.deadlines * 5.0);

    return Tooltip(
      message:
          '${entry.dayLabel}: ${(stressScore * 100).round()}% stress, ${entry.deadlines} deadlines, ${entry.calendarHours.toStringAsFixed(1)}h calendar',
      child: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Container(
            height: deadlineHeight,
            width: 8,
            decoration: BoxDecoration(
              color: colorScheme.tertiary.withValues(alpha: 0.8),
              borderRadius: BorderRadius.circular(999),
            ),
          ),
          const SizedBox(height: 4),
          Container(
            height: stressHeight,
            decoration: BoxDecoration(
              color: stressScore >= 0.68
                  ? colorScheme.error
                  : stressScore >= 0.42
                      ? colorScheme.primary
                      : colorScheme.secondary,
              borderRadius: BorderRadius.circular(999),
            ),
          ),
        ],
      ),
    );
  }
}

class _RecommendationTile extends StatelessWidget {
  const _RecommendationTile({required this.recommendation});

  final _ReportRecommendation recommendation;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHigh.withValues(alpha: 0.72),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(alpha: 0.55),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(recommendation.icon, size: 18, color: colorScheme.primary),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  recommendation.title,
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                const SizedBox(height: 4),
                Text(
                  recommendation.detail,
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

extension _EntryRangeHelpers on List<MonitorHistoryEntry> {
  List<MonitorHistoryEntry> takeLast(int count) {
    if (length <= count) {
      return this;
    }
    return sublist(length - count);
  }
}

extension _DoubleAverage on Iterable<double> {
  double average() {
    if (isEmpty) {
      return 0;
    }
    return reduce((left, right) => left + right) / length;
  }
}
