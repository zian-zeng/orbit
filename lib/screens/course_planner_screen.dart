import 'package:chatbotapp/data_sources/planetterp_course_data_source.dart';
import 'package:chatbotapp/models/course_planning.dart';
import 'package:chatbotapp/providers/user_profile_provider.dart';
import 'package:chatbotapp/services/umd_course_planning_service.dart';
import 'package:chatbotapp/widgets/app_icon_button.dart';
import 'package:chatbotapp/widgets/app_screen_scaffold.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class CoursePlannerScreen extends StatefulWidget {
  const CoursePlannerScreen({super.key});

  @override
  State<CoursePlannerScreen> createState() => _CoursePlannerScreenState();
}

class _CoursePlannerScreenState extends State<CoursePlannerScreen> {
  static const UmdCoursePlanningService _service = UmdCoursePlanningService();
  final PlanetterpCourseDataSource _planetTerp = PlanetterpCourseDataSource();
  final TextEditingController _coursesController = TextEditingController(
    text: 'CMSC216, STAT400, INST201, ENGL101, COMM107',
  );
  int _targetCredits = 15;
  double _stressScore = 0.68;
  bool _isFetchingPlanetTerp = false;
  String _sourceStatus =
      'Using built-in UMD demo signals. Fetch PlanetTerp when network is available.';
  final Map<String, CourseCandidate> _liveCandidates = {};

  @override
  void dispose() {
    _coursesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final profile = context.watch<UserProfileProvider>();
    final labels = {
      ...profile.routingLabelKeys,
      ...profile.preferredLabelKeys,
      'stress_sensitive',
    };
    final courseIds = _courseIds(_coursesController.text);
    final candidates = _selectedCandidates(courseIds);
    final plan = _service.buildPlan(
      labels: labels,
      stressScore: _stressScore,
      targetCredits: _targetCredits,
      candidates: candidates.isEmpty && courseIds.isEmpty
          ? UmdCoursePlanningService.demoCandidates
          : candidates,
    );

    return AppScreenScaffold(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
      child: Column(
        children: [
          _Header(onUsePlan: () => _usePlan(plan)),
          const SizedBox(height: 16),
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.only(
                bottom: homeIndicatorSpacing(context, base: 24),
              ),
              child: Column(
                children: [
                  _PlannerControls(
                    controller: _coursesController,
                    targetCredits: _targetCredits,
                    stressScore: _stressScore,
                    onChanged: () => setState(() {}),
                    onCreditsChanged: (value) {
                      setState(() => _targetCredits = value);
                    },
                    onStressChanged: (value) {
                      setState(() => _stressScore = value);
                    },
                    onFetchPlanetTerp: _fetchPlanetTerpSignals,
                    isFetchingPlanetTerp: _isFetchingPlanetTerp,
                    liveSourceCount: _liveCandidates.length,
                    sourceStatus: _sourceStatus,
                  ),
                  const SizedBox(height: 12),
                  _PlanSummary(plan: plan),
                  const SizedBox(height: 12),
                  _ProfessorComparison(plan: plan),
                  const SizedBox(height: 12),
                  ...plan.recommendations.map(
                    (recommendation) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _RecommendationCard(
                        recommendation: recommendation,
                      ),
                    ),
                  ),
                  _SourceNotes(notes: plan.sourceNotes),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Set<String> _courseIds(String text) {
    return text
        .split(',')
        .map((item) => item.trim().toUpperCase())
        .where((item) => item.isNotEmpty)
        .toSet();
  }

  List<CourseCandidate> _selectedCandidates(Set<String> ids) {
    if (ids.isEmpty) {
      return const [];
    }
    return ids
        .map(
          (id) =>
              _liveCandidates[id] ??
              UmdCoursePlanningService.demoCandidates
                  .where((course) => course.courseId == id)
                  .cast<CourseCandidate?>()
                  .firstWhere((course) => course != null, orElse: () => null),
        )
        .whereType<CourseCandidate>()
        .toList(growable: false);
  }

  Future<void> _fetchPlanetTerpSignals() async {
    final ids = _courseIds(_coursesController.text);
    if (ids.isEmpty || _isFetchingPlanetTerp) {
      return;
    }
    setState(() {
      _isFetchingPlanetTerp = true;
      _sourceStatus =
          'Fetching live PlanetTerp course and professor signals...';
    });
    var loaded = 0;
    final failures = <String>[];
    try {
      for (final id in ids.take(8)) {
        try {
          final course =
              await _planetTerp.fetchCourseWithProfessorSignals(courseId: id);
          if (course != null) {
            _liveCandidates[course.courseId] = course;
            loaded++;
          } else {
            failures.add(id);
          }
        } catch (_) {
          failures.add(id);
        }
      }
      if (!mounted) {
        return;
      }
      setState(() {
        _sourceStatus = loaded == 0
            ? 'PlanetTerp fetch did not return usable courses. Keeping the offline UMD fixture.'
            : 'Loaded $loaded live PlanetTerp course signal(s)'
                '${failures.isEmpty ? '' : '; ${failures.join(', ')} stayed on fallback/demo data'}.';
      });
    } finally {
      if (mounted) {
        setState(() => _isFetchingPlanetTerp = false);
      }
    }
  }

  void _usePlan(SemesterPlanReport plan) {
    Navigator.of(context).pop(
      'Help me choose next semester courses using this UMD plan:\n\n'
      '${plan.agentPromptSummary}\n\n'
      'Please explain the tradeoffs, professor signals, workload risks, and what I should verify in Testudo or PlanetTerp before registering.',
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.onUsePlan});

  final VoidCallback onUsePlan;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Row(
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
                'Course Planner',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 4),
              Text(
                'UMD courses, professor signals, and workload balance',
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
              ),
            ],
          ),
        ),
        FilledButton.tonal(
          onPressed: onUsePlan,
          child: const Text('Use in chat'),
        ),
      ],
    );
  }
}

class _PlannerControls extends StatelessWidget {
  const _PlannerControls({
    required this.controller,
    required this.targetCredits,
    required this.stressScore,
    required this.onChanged,
    required this.onCreditsChanged,
    required this.onStressChanged,
    required this.onFetchPlanetTerp,
    required this.isFetchingPlanetTerp,
    required this.liveSourceCount,
    required this.sourceStatus,
  });

  final TextEditingController controller;
  final int targetCredits;
  final double stressScore;
  final VoidCallback onChanged;
  final ValueChanged<int> onCreditsChanged;
  final ValueChanged<double> onStressChanged;
  final VoidCallback onFetchPlanetTerp;
  final bool isFetchingPlanetTerp;
  final int liveSourceCount;
  final String sourceStatus;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return _PlannerPanel(
      title: 'Candidate Courses',
      subtitle: 'Start with what you are considering',
      icon: CupertinoIcons.square_list,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: controller,
            minLines: 1,
            maxLines: 3,
            onChanged: (_) => onChanged(),
            decoration: const InputDecoration(
              labelText: 'Course IDs',
              helperText: 'Example: CMSC216, STAT400, INST201, ENGL101',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: Text(
                  'Target credits',
                  style: Theme.of(context).textTheme.titleSmall,
                ),
              ),
              Text('$targetCredits credits'),
            ],
          ),
          Slider(
            value: targetCredits.toDouble(),
            min: 12,
            max: 18,
            divisions: 6,
            label: '$targetCredits credits',
            onChanged: (value) => onCreditsChanged(value.round()),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: Text(
                  'Current stress pressure',
                  style: Theme.of(context).textTheme.titleSmall,
                ),
              ),
              Text('${(stressScore * 100).round()}%'),
            ],
          ),
          Slider(
            value: stressScore,
            min: 0,
            max: 1,
            divisions: 20,
            label: '${(stressScore * 100).round()}%',
            activeColor: stressScore >= 0.7
                ? colorScheme.error
                : stressScore >= 0.45
                    ? colorScheme.tertiary
                    : colorScheme.primary,
            onChanged: onStressChanged,
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: Text(
                  sourceStatus,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                ),
              ),
              const SizedBox(width: 12),
              FilledButton.tonalIcon(
                onPressed: isFetchingPlanetTerp ? null : onFetchPlanetTerp,
                icon: isFetchingPlanetTerp
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(CupertinoIcons.cloud_download),
                label: Text(
                  liveSourceCount > 0 ? 'Refresh live' : 'Fetch PlanetTerp',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ProfessorComparison extends StatelessWidget {
  const _ProfessorComparison({required this.plan});

  final SemesterPlanReport plan;

  @override
  Widget build(BuildContext context) {
    return _PlannerPanel(
      title: 'Professor Comparison',
      subtitle: 'Rating, review confidence, and grade signal',
      icon: CupertinoIcons.person_2_square_stack,
      child: plan.recommendations.isEmpty
          ? const Text('Add UMD course IDs to compare professor signals.')
          : Column(
              children: plan.recommendations
                  .map(
                    (recommendation) => Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: _ProfessorRow(recommendation: recommendation),
                    ),
                  )
                  .toList(growable: false),
            ),
    );
  }
}

class _ProfessorRow extends StatelessWidget {
  const _ProfessorRow({required this.recommendation});

  final CoursePlanRecommendation recommendation;

  @override
  Widget build(BuildContext context) {
    final professor = recommendation.professor;
    final rating = professor?.averageRating == null
        ? 'rating TBD'
        : '${professor!.averageRating!.toStringAsFixed(1)}/5';
    final gpa = professor?.averageGpa ?? recommendation.course.averageGpa;
    final gpaText =
        gpa == null ? 'GPA signal TBD' : 'GPA ${gpa.toStringAsFixed(2)}';
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 2,
          child: Text(
            recommendation.course.courseId,
            style: Theme.of(context).textTheme.titleSmall,
          ),
        ),
        Expanded(
          flex: 4,
          child: Text(professor?.name ?? 'Verify current section'),
        ),
        Expanded(
          flex: 3,
          child: Text('$rating | ${professor?.reviewCount ?? 0} reviews'),
        ),
        Expanded(
          flex: 3,
          child: Text(gpaText),
        ),
      ],
    );
  }
}

class _PlanSummary extends StatelessWidget {
  const _PlanSummary({required this.plan});

  final SemesterPlanReport plan;

  @override
  Widget build(BuildContext context) {
    return _PlannerPanel(
      title: 'Balanced Plan',
      subtitle: '${plan.plannedCredits}/${plan.targetCredits} planned credits',
      icon: CupertinoIcons.chart_bar_alt_fill,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(plan.balanceSummary),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _SignalChip(label: '${plan.recommendations.length} courses'),
              _SignalChip(label: '${plan.plannedCredits} credits'),
              const _SignalChip(label: 'PlanetTerp signals'),
              const _SignalChip(label: 'Testudo verify'),
            ],
          ),
        ],
      ),
    );
  }
}

class _RecommendationCard extends StatelessWidget {
  const _RecommendationCard({required this.recommendation});

  final CoursePlanRecommendation recommendation;

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
              Expanded(
                child: Text(
                  '${recommendation.course.courseId} - ${recommendation.course.title}',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              _SignalChip(label: recommendation.scoreLabel),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Professor: ${recommendation.professor?.name ?? 'verify current section'}',
          ),
          const SizedBox(height: 10),
          ...recommendation.rationale.map(
            (reason) => Padding(
              padding: const EdgeInsets.only(bottom: 5),
              child: Text('- $reason'),
            ),
          ),
          if (recommendation.riskFlags.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              recommendation.riskFlags.join(' '),
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: colorScheme.tertiary,
                  ),
            ),
          ],
          const SizedBox(height: 8),
          Text(
            recommendation.nextAction,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
          ),
        ],
      ),
    );
  }
}

class _SourceNotes extends StatelessWidget {
  const _SourceNotes({required this.notes});

  final List<String> notes;

  @override
  Widget build(BuildContext context) {
    return _PlannerPanel(
      title: 'Source Policy',
      subtitle: 'Reviews inform, Testudo confirms',
      icon: CupertinoIcons.lock_shield,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: notes
            .map(
              (note) => Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Text('- $note'),
              ),
            )
            .toList(growable: false),
      ),
    );
  }
}

class _PlannerPanel extends StatelessWidget {
  const _PlannerPanel({
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
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}

class _SignalChip extends StatelessWidget {
  const _SignalChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(label, style: Theme.of(context).textTheme.labelSmall),
    );
  }
}
