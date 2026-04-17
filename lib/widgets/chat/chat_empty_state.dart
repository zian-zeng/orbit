import 'package:chatbotapp/models/prompt_recommendation.dart';
import 'package:chatbotapp/models/support_intelligence.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class ChatEmptyState extends StatelessWidget {
  const ChatEmptyState({
    super.key,
    required this.apiConfigured,
    required this.showStarterPrompts,
    required this.supportBundle,
    required this.labels,
    required this.recommendations,
    required this.selectedLabel,
    required this.onSuggestionTap,
    required this.onInsightPromptTap,
    required this.onCopySkillTap,
    required this.onLabelSelected,
  });

  final bool apiConfigured;
  final bool showStarterPrompts;
  final SupportIntelligenceBundle? supportBundle;
  final List<SupportLabel> labels;
  final List<PromptRecommendation> recommendations;
  final SupportLabel? selectedLabel;
  final ValueChanged<PromptRecommendation> onSuggestionTap;
  final ValueChanged<String> onInsightPromptTap;
  final VoidCallback? onCopySkillTap;
  final ValueChanged<SupportLabel?> onLabelSelected;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return SingleChildScrollView(
      child: Column(
        children: [
          const SizedBox(height: 44),
          Text(
            'How can I help?',
            style: Theme.of(context).textTheme.headlineSmall,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'Choose a focus or try a recommendation below',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
          if (supportBundle != null) ...[
            const SizedBox(height: 20),
            _SupportPulseCard(
              bundle: supportBundle!,
              onPromptTap: onInsightPromptTap,
              onCopySkillTap: onCopySkillTap,
            ),
          ],
          if (showStarterPrompts) ...[
            const SizedBox(height: 20),
            Wrap(
              alignment: WrapAlignment.center,
              spacing: 8,
              runSpacing: 8,
              children: [
                ChoiceChip(
                  label: const Text('Auto'),
                  selected: selectedLabel == null,
                  onSelected: (_) => onLabelSelected(null),
                ),
                ...labels.map(
                  (label) => ChoiceChip(
                    label: Text(label.displayName),
                    selected: selectedLabel == label,
                    onSelected: (_) => onLabelSelected(label),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Column(
              children: recommendations
                  .map(
                    (recommendation) => Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: _RecommendationCard(
                        recommendation: recommendation,
                        onTap: () => onSuggestionTap(recommendation),
                      ),
                    ),
                  )
                  .toList(),
            ),
          ],
          if (!apiConfigured) ...[
            const SizedBox(height: 18),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: colorScheme.secondaryContainer,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    CupertinoIcons.exclamationmark_triangle,
                    size: 16,
                    color: colorScheme.onSecondaryContainer,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Set API_KEY to start',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onSecondaryContainer,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _SupportPulseCard extends StatelessWidget {
  const _SupportPulseCard({
    required this.bundle,
    required this.onPromptTap,
    required this.onCopySkillTap,
  });

  final SupportIntelligenceBundle bundle;
  final ValueChanged<String> onPromptTap;
  final VoidCallback? onCopySkillTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(alpha: 0.6),
        ),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                CupertinoIcons.waveform_path_ecg,
                size: 18,
                color: colorScheme.primary,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Support pulse',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  '${bundle.stressReport.band.displayName} stress',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: colorScheme.onPrimaryContainer,
                      ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            bundle.stressReport.summary,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          if (bundle.stressReport.sourceBadges.isNotEmpty) ...[
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: bundle.stressReport.sourceBadges
                  .map((badge) => Chip(label: Text(badge)))
                  .toList(growable: false),
            ),
          ],
          const SizedBox(height: 14),
          Text(
            'Questions to ask next',
            style: Theme.of(context).textTheme.titleSmall,
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: bundle.questions
                .map(
                  (question) => ActionChip(
                    label: Text(question.title),
                    onPressed: () => onPromptTap(question.prompt),
                  ),
                )
                .toList(growable: false),
          ),
          const SizedBox(height: 14),
          Text(
            'Suggestions',
            style: Theme.of(context).textTheme.titleSmall,
          ),
          const SizedBox(height: 8),
          ...bundle.suggestions.map(
            (suggestion) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: OutlinedButton(
                onPressed: () => onPromptTap(suggestion.prompt),
                style: OutlinedButton.styleFrom(
                  alignment: Alignment.centerLeft,
                  padding: const EdgeInsets.all(14),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(suggestion.title),
                    const SizedBox(height: 4),
                    Text(
                      suggestion.detail,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: colorScheme.surface,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        bundle.skill.title,
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                    ),
                    TextButton(
                      onPressed: onCopySkillTap,
                      child: const Text('Copy skill'),
                    ),
                  ],
                ),
                Text(
                  bundle.skill.summary,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: bundle.skill.tools
                      .map(
                        (tool) => Chip(
                          label: Text(tool.label),
                        ),
                      )
                      .toList(growable: false),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _RecommendationCard extends StatelessWidget {
  const _RecommendationCard({
    required this.recommendation,
    required this.onTap,
  });

  final PromptRecommendation recommendation;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(22),
      child: Ink(
        width: double.infinity,
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerLow,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: colorScheme.outlineVariant.withValues(alpha: 0.6),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    CupertinoIcons.sparkles,
                    size: 16,
                    color: colorScheme.primary,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      recommendation.title,
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      recommendation.label.displayName,
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: colorScheme.onPrimaryContainer,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                recommendation.description,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 6),
              Text(
                recommendation.reason,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
