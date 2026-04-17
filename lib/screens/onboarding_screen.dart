import 'package:chatbotapp/models/prompt_recommendation.dart';
import 'package:chatbotapp/providers/user_profile_provider.dart';
import 'package:chatbotapp/services/onboarding_label_ranker.dart';
import 'package:chatbotapp/utilities/app_snackbar.dart';
import 'package:chatbotapp/widgets/app_screen_scaffold.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final TextEditingController _nameController = TextEditingController();
  final Map<String, String> _answers = <String, String>{};
  bool _isSaving = false;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  bool get _canContinue =>
      _nameController.text.trim().isNotEmpty &&
      onboardingQuestions
          .every((question) => _answers.containsKey(question.id));

  int get _completedSteps =>
      (_nameController.text.trim().isNotEmpty ? 1 : 0) + _answers.length;

  double get _progress =>
      (_completedSteps / (onboardingQuestions.length + 1)).clamp(0, 1);

  List<SupportLabel> get _rankedLabels {
    if (!_canContinue) {
      return const <SupportLabel>[];
    }

    return rankSupportLabels(
      OnboardingAnswers(
        primaryGoalId: _answers['primary_goal']!,
        responseStyleId: _answers['response_style']!,
        blockerId: _answers['blocker']!,
      ),
    );
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
            preferredLabelKeys: _rankedLabels
                .map((label) => label.storageKey)
                .toList(growable: false),
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
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return AppScreenScaffold(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final wide = constraints.maxWidth >= 980;
          final introPanel = _IntroPanel(
            progress: _progress,
            completedSteps: _completedSteps,
            totalSteps: onboardingQuestions.length + 1,
            rankedLabels: _rankedLabels,
            canContinue: _canContinue,
          );

          final formColumn = Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 16),
              Text(
                'Welcome to Orbit',
                style: textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.8,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'Answer three quick questions so Orbit can prioritize the kinds of help you want first.',
                style: textTheme.bodyLarge?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 24),
              _QuestionSection(
                title: 'Identity',
                eyebrow: 'Step 1',
                child: TextField(
                  controller: _nameController,
                  textCapitalization: TextCapitalization.words,
                  onChanged: (_) => setState(() {}),
                  decoration: const InputDecoration(
                    labelText: 'What should we call you?',
                    hintText: 'Taylor',
                  ),
                ),
              ),
              const SizedBox(height: 16),
              ...onboardingQuestions.asMap().entries.map(
                    (entry) => Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: _QuestionSection(
                        title: entry.value.title,
                        eyebrow: 'Step ${entry.key + 2}',
                        child: _QuestionCard(
                          question: entry.value,
                          selectedOptionId: _answers[entry.value.id],
                          onSelected: (optionId) {
                            setState(() {
                              _answers[entry.value.id] = optionId;
                            });
                          },
                        ),
                      ),
                    ),
                  ),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 220),
                child: _rankedLabels.isEmpty
                    ? const SizedBox.shrink()
                    : Container(
                        key: const ValueKey('focus-preview'),
                        width: double.infinity,
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          color: colorScheme.surfaceContainerLow,
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(
                            color: colorScheme.outlineVariant
                                .withValues(alpha: 0.55),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Initial focus preview',
                              style: textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'Orbit will start by biasing suggestions toward these areas. You can refine them later from your activity and imports.',
                              style: textTheme.bodyMedium?.copyWith(
                                color: colorScheme.onSurfaceVariant,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: _rankedLabels
                                  .take(4)
                                  .map(
                                    (label) => Chip(
                                      label: Text(label.displayName),
                                    ),
                                  )
                                  .toList(growable: false),
                            ),
                          ],
                        ),
                      ),
              ),
              const SizedBox(height: 14),
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
              const SizedBox(height: 8),
              Text(
                'You can update your profile and imported signals later in Settings.',
                style: textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              SizedBox(height: homeIndicatorSpacing(context, base: 20)),
            ],
          );

          return SingleChildScrollView(
            child: wide
                ? Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(
                        width: 360,
                        child: Padding(
                          padding: const EdgeInsets.only(top: 16, right: 24),
                          child: introPanel,
                        ),
                      ),
                      Expanded(child: formColumn),
                    ],
                  )
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 12),
                      introPanel,
                      const SizedBox(height: 20),
                      formColumn,
                    ],
                  ),
          );
        },
      ),
    );
  }
}

class _IntroPanel extends StatelessWidget {
  const _IntroPanel({
    required this.progress,
    required this.completedSteps,
    required this.totalSteps,
    required this.rankedLabels,
    required this.canContinue,
  });

  final double progress;
  final int completedSteps;
  final int totalSteps;
  final List<SupportLabel> rankedLabels;
  final bool canContinue;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: colorScheme.surface.withValues(alpha: 0.78),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(alpha: 0.55),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Orbit',
            style: textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w800,
              letterSpacing: -0.8,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Initial label setup',
            style: textTheme.titleMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 18),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 8,
              backgroundColor: colorScheme.surfaceContainerHighest,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            '$completedSteps of $totalSteps steps completed',
            style: textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'This intake gives Orbit the first read on what kind of support to prioritize before your history and imports start enriching it.',
            style: textTheme.bodyMedium,
          ),
          const SizedBox(height: 16),
          const Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              Chip(label: Text('Questions')),
              Chip(label: Text('Initial labels')),
              Chip(label: Text('Later refinement')),
            ],
          ),
          if (rankedLabels.isNotEmpty) ...[
            const SizedBox(height: 18),
            Text(
              'Likely first routes',
              style: textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            ...rankedLabels.take(3).toList().asMap().entries.map(
                  (entry) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Row(
                      children: [
                        Text(
                          '0${entry.key + 1}',
                          style: textTheme.labelLarge?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            entry.value.displayName,
                            style: textTheme.bodyLarge,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
          ],
          const SizedBox(height: 10),
          Text(
            canContinue
                ? 'Ready to create your starting profile.'
                : 'Answer all fields to unlock your starting profile.',
            style: textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

class _QuestionSection extends StatelessWidget {
  const _QuestionSection({
    required this.title,
    required this.eyebrow,
    required this.child,
  });

  final String title;
  final String eyebrow;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: colorScheme.surface.withValues(alpha: 0.66),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(alpha: 0.5),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            eyebrow,
            style: textTheme.labelLarge?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            title,
            style: textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }
}

class _QuestionCard extends StatelessWidget {
  const _QuestionCard({
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
    final textTheme = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          question.description,
          style: textTheme.bodyMedium?.copyWith(
            color: colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 14),
        ...question.options.map(
          (option) => Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: InkWell(
              borderRadius: BorderRadius.circular(20),
              onTap: () => onSelected(option.id),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                curve: Curves.easeOutCubic,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: selectedOptionId == option.id
                        ? colorScheme.primary
                        : colorScheme.outlineVariant,
                    width: selectedOptionId == option.id ? 1.8 : 1,
                  ),
                  color: selectedOptionId == option.id
                      ? colorScheme.primaryContainer.withValues(alpha: 0.72)
                      : colorScheme.surfaceContainerLow,
                ),
                padding: const EdgeInsets.all(14),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      width: 22,
                      height: 22,
                      margin: const EdgeInsets.only(top: 2),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: selectedOptionId == option.id
                            ? colorScheme.primary
                            : Colors.transparent,
                        border: Border.all(
                          color: selectedOptionId == option.id
                              ? colorScheme.primary
                              : colorScheme.outline,
                        ),
                      ),
                      child: selectedOptionId == option.id
                          ? Icon(
                              Icons.check,
                              size: 14,
                              color: colorScheme.onPrimary,
                            )
                          : null,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            option.title,
                            style: textTheme.titleSmall,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            option.description,
                            style: textTheme.bodySmall?.copyWith(
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
        ),
      ],
    );
  }
}
