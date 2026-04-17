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

    return AppScreenScaffold(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 16),
            Text(
              'Welcome to Orbit',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
            ),
            const SizedBox(height: 10),
            Text(
              'Answer three quick questions so Orbit can prioritize the kinds of help you want first.',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
            ),
            const SizedBox(height: 24),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
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
            ),
            const SizedBox(height: 16),
            ...onboardingQuestions.map(
              (question) => Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: _QuestionCard(
                  question: question,
                  selectedOptionId: _answers[question.id],
                  onSelected: (optionId) {
                    setState(() {
                      _answers[question.id] = optionId;
                    });
                  },
                ),
              ),
            ),
            if (_rankedLabels.isNotEmpty)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Your starting focus',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: _rankedLabels
                            .take(3)
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
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _canContinue && !_isSaving ? _save : null,
                child: Text(_isSaving ? 'Saving...' : 'Continue'),
              ),
            ),
            SizedBox(height: homeIndicatorSpacing(context, base: 20)),
          ],
        ),
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

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              question.title,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 6),
            Text(
              question.description,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
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
                  child: Ink(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: selectedOptionId == option.id
                            ? colorScheme.primary
                            : colorScheme.outlineVariant,
                        width: selectedOptionId == option.id ? 1.8 : 1,
                      ),
                      color: selectedOptionId == option.id
                          ? colorScheme.primaryContainer.withValues(alpha: 0.6)
                          : colorScheme.surfaceContainerLow,
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            option.title,
                            style: Theme.of(context).textTheme.titleSmall,
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
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
