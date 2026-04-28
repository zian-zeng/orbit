import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:chatbotapp/models/prompt_recommendation.dart';
import 'package:chatbotapp/providers/user_profile_provider.dart';
import 'package:chatbotapp/services/onboarding_label_ranker.dart';
import 'package:chatbotapp/utilities/app_snackbar.dart';
import 'package:chatbotapp/widgets/startup/startup_stage_shell.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final TextEditingController _nameController = TextEditingController();
  final Map<String, String> _answers = <String, String>{};
  bool _isSaving = false;

  List<OnboardingQuestion> get _visibleQuestions =>
      visibleOnboardingQuestions(_answers);

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  bool get _canContinue =>
      _nameController.text.trim().isNotEmpty &&
      _visibleQuestions.every((question) => _answers.containsKey(question.id));

  int get _answeredCount => _visibleQuestions
      .where((question) => _answers.containsKey(question.id))
      .length;

  int get _completedSteps =>
      (_nameController.text.trim().isNotEmpty ? 1 : 0) + _answeredCount;

  double get _progress =>
      (_completedSteps / (_visibleQuestions.length + 1)).clamp(0, 1);

  List<SupportLabel> get _rankedLabels {
    if (!_canContinue) {
      return const <SupportLabel>[];
    }

    return rankSupportLabels(
      OnboardingAnswers.fromSelectedOptions(_answers),
    );
  }

  List<String> get _profileLabels {
    if (!_canContinue) {
      return const <String>[];
    }

    return onboardingProfileLabels(
      OnboardingAnswers.fromSelectedOptions(_answers),
    );
  }

  List<String> get _storedLabels {
    final supportLabels = _rankedLabels.map((label) => label.storageKey);
    return {
      ...supportLabels,
      ..._profileLabels,
    }.toList(growable: false);
  }

  Future<void> _save() async {
    if (!_canContinue || _isSaving) {
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      await context.read<UserProfileProvider>().saveProfile(
            name: _nameController.text,
            imagePath: '',
            hasCompletedOnboarding: true,
            preferredLabelKeys: _storedLabels,
          );
    } catch (_) {
      if (!mounted) {
        return;
      }
      showAppSnackBar(context, 'Could not finish setup');
      setState(() {
        _isSaving = false;
      });
      return;
    }

    if (!mounted) {
      return;
    }

    setState(() {
      _isSaving = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final userProfile = context.watch<UserProfileProvider>();
    final colorScheme = Theme.of(context).colorScheme;

    return StartupStageShell(
      stageLabel: 'Setup',
      stageTitle: 'Finish your support profile',
      stageDescription:
          'Tell Orbit a little about your school, life, and support context so the workspace can start with useful labels instead of generic advice.',
      leadingPanel: _OnboardingAside(
        progress: _progress,
        completedSteps: _completedSteps,
        totalSteps: _visibleQuestions.length + 1,
        email: userProfile.email.isEmpty ? 'Local session' : userProfile.email,
        rankedLabels: _rankedLabels,
        profileLabels: _profileLabels,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionFrame(
            eyebrow: 'Identity',
            title: 'Who is this workspace for?',
            description:
                'Your authorized email is already attached to this device. Add the name Orbit should use in chat.',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: _nameController,
                  textCapitalization: TextCapitalization.words,
                  onChanged: (_) => setState(() {}),
                  decoration: const InputDecoration(
                    labelText: 'What should we call you?',
                    hintText: 'Taylor',
                  ),
                ),
                const SizedBox(height: 14),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: colorScheme.surface,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: colorScheme.outlineVariant.withValues(alpha: 0.48),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        CupertinoIcons.checkmark_seal,
                        size: 18,
                        color: colorScheme.primary,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          userProfile.email.isEmpty
                              ? 'Authorized locally on this device'
                              : 'Authorized as ${userProfile.email}',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          ..._visibleQuestions.asMap().entries.map(
                (entry) => Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: _SectionFrame(
                    eyebrow: 'Step ${entry.key + 1}',
                    title: entry.value.title,
                    description: entry.value.description,
                    child: _QuestionOptions(
                      question: entry.value,
                      selectedOptionId: _answers[entry.value.id],
                      onSelected: (optionId) {
                        setState(() {
                          _answers[entry.value.id] = optionId;
                          _pruneHiddenAnswers();
                        });
                      },
                    ),
                  ),
                ),
              ),
          if (_rankedLabels.isNotEmpty) ...[
            _SectionFrame(
              eyebrow: 'Preview',
              title: 'Your starting support mix',
              description:
                  'Orbit will bias suggestions toward these lanes first. The mix can shift later as you use the workspace and import more signals.',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _rankedLabels
                        .take(4)
                        .map((label) => Chip(label: Text(label.displayName)))
                        .toList(growable: false),
                  ),
                  if (_profileLabels.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Text(
                      'Profile tags',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _profileLabels
                          .take(8)
                          .map((label) => Chip(label: Text(label)))
                          .toList(growable: false),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: _canContinue && !_isSaving ? _save : null,
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: Text(_isSaving ? 'Saving...' : 'Continue'),
            ),
          ),
        ],
      ),
    );
  }

  void _pruneHiddenAnswers() {
    var changed = true;
    while (changed) {
      changed = false;
      final visibleIds =
          visibleOnboardingQuestions(_answers).map((item) => item.id).toSet();
      final hiddenAnsweredIds = _answers.keys
          .where((questionId) => !visibleIds.contains(questionId))
          .toList(growable: false);
      if (hiddenAnsweredIds.isNotEmpty) {
        changed = true;
        for (final questionId in hiddenAnsweredIds) {
          _answers.remove(questionId);
        }
      }
    }
  }
}

class _OnboardingAside extends StatelessWidget {
  const _OnboardingAside({
    required this.progress,
    required this.completedSteps,
    required this.totalSteps,
    required this.email,
    required this.rankedLabels,
    required this.profileLabels,
  });

  final double progress;
  final int completedSteps;
  final int totalSteps;
  final String email;
  final List<SupportLabel> rankedLabels;
  final List<String> profileLabels;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Orbit',
          style: textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w800,
            letterSpacing: -0.8,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          'Personalize the workspace once, then let the routes adapt.',
          style: textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          'The adaptive questionnaire stays local and only shows follow-ups when your earlier answers make them useful.',
          style: textTheme.bodyLarge?.copyWith(
            color: colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 22),
        LinearProgressIndicator(
          value: progress,
          minHeight: 10,
          borderRadius: BorderRadius.circular(999),
        ),
        const SizedBox(height: 10),
        Text(
          '$completedSteps of $totalSteps steps complete',
          style: textTheme.labelLarge?.copyWith(
            color: colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 18),
        StartupMetricCard(label: 'Authorized session', value: email),
        if (rankedLabels.isNotEmpty) ...[
          const SizedBox(height: 12),
          StartupMetricCard(
            label: 'Top focus',
            value: rankedLabels.first.displayName,
          ),
        ],
        if (profileLabels.isNotEmpty) ...[
          const SizedBox(height: 16),
          Text(
            'Signals in play',
            style: textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: profileLabels
                .take(6)
                .map((label) => Chip(label: Text(label)))
                .toList(growable: false),
          ),
        ],
      ],
    );
  }
}

class _SectionFrame extends StatelessWidget {
  const _SectionFrame({
    required this.eyebrow,
    required this.title,
    required this.description,
    required this.child,
  });

  final String eyebrow;
  final String title;
  final String description;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLow.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(alpha: 0.55),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            eyebrow,
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(height: 10),
          Text(
            title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(height: 6),
          Text(
            description,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }
}

class _QuestionOptions extends StatelessWidget {
  const _QuestionOptions({
    required this.question,
    required this.selectedOptionId,
    required this.onSelected,
  });

  final OnboardingQuestion question;
  final String? selectedOptionId;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: question.options.map((option) {
        final selected = selectedOptionId == option.id;
        return Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: InkWell(
            key: ValueKey('option-${question.id}-${option.id}'),
            borderRadius: BorderRadius.circular(32),
            onTap: () => onSelected(option.id),
            child: Ink(
              width: double.infinity,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(32),
                border: Border.all(
                  color: selected
                      ? colorScheme.primary
                      : colorScheme.outlineVariant.withValues(alpha: 0.8),
                  width: selected ? 2 : 1.2,
                ),
                color: selected
                    ? colorScheme.primaryContainer.withValues(alpha: 0.78)
                    : colorScheme.surfaceContainerHigh.withValues(alpha: 0.78),
                boxShadow: [
                  BoxShadow(
                    color: colorScheme.shadow.withValues(
                      alpha: selected ? 0.08 : 0.03,
                    ),
                    blurRadius: selected ? 18 : 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 18,
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: selected
                            ? colorScheme.primary
                            : colorScheme.surface,
                        border: Border.all(
                          color: selected
                              ? colorScheme.primary
                              : colorScheme.outline,
                          width: selected ? 0 : 1.4,
                        ),
                      ),
                      child: selected
                          ? Icon(
                              CupertinoIcons.check_mark,
                              size: 15,
                              color: colorScheme.onPrimary,
                            )
                          : null,
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            option.title,
                            style: Theme.of(context)
                                .textTheme
                                .titleSmall
                                ?.copyWith(
                                  fontWeight: FontWeight.w700,
                                ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            option.description,
                            style:
                                Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: colorScheme.onSurfaceVariant,
                                    ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      }).toList(growable: false),
    );
  }
}
