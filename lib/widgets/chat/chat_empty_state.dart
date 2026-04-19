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
    required this.onSaveSkillTap,
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
  final VoidCallback? onSaveSkillTap;
  final ValueChanged<SupportLabel?> onLabelSelected;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 28),
          Text(
            'Workspace',
            style: textTheme.labelLarge?.copyWith(
              color: colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'How can I help?',
            style: textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.w800,
              letterSpacing: -0.8,
            ),
          ),
          const SizedBox(height: 8),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 540),
            child: Text(
              'Start with one routed prompt, or choose a focus lane to shape the first response.',
              style: textTheme.bodyLarge?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          if (supportBundle != null) ...[
            const SizedBox(height: 24),
            _SupportPulseCard(
              bundle: supportBundle!,
              onPromptTap: onInsightPromptTap,
              onCopySkillTap: onCopySkillTap,
              onSaveSkillTap: onSaveSkillTap,
            ),
          ],
          if (showStarterPrompts) ...[
            const SizedBox(height: 24),
            Text(
              'Focus lane',
              style: textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Use a lane to narrow the first reply before you send anything.',
              style: textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 12),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  ChoiceChip(
                    label: const Text('Auto'),
                    selected: selectedLabel == null,
                    onSelected: (_) => onLabelSelected(null),
                  ),
                  const SizedBox(width: 8),
                  ...labels.expand(
                    (label) => [
                      ChoiceChip(
                        label: Text(label.displayName),
                        selected: selectedLabel == label,
                        onSelected: (_) => onLabelSelected(label),
                      ),
                      const SizedBox(width: 8),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            Text(
              'Suggested starts',
              style: textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Choose one to start with a routed draft.',
              style: textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
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
                  .toList(growable: false),
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
    required this.onSaveSkillTap,
  });

  final SupportIntelligenceBundle bundle;
  final ValueChanged<String> onPromptTap;
  final VoidCallback? onCopySkillTap;
  final VoidCallback? onSaveSkillTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

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
            style: textTheme.bodyMedium,
          ),
          const SizedBox(height: 8),
          Text(
            'Use a question or action to draft the next prompt.',
            style: textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
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
            'Quick check-ins',
            style: textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Choose one to start a grounded follow-up.',
            style: textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: bundle.questions
                .map(
                  (question) => _PromptPillButton(
                    icon: CupertinoIcons.chat_bubble_text,
                    label: question.title,
                    onPressed: () => onPromptTap(question.prompt),
                  ),
                )
                .toList(growable: false),
          ),
          const SizedBox(height: 14),
          Text(
            'Next actions',
            style: textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'These turn the pulse into something concrete right now.',
            style: textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 10),
          ...bundle.suggestions.map(
            (suggestion) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: _SupportActionTile(
                onPressed: () => onPromptTap(suggestion.prompt),
                title: suggestion.title,
                detail: suggestion.detail,
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
                        style: textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    Wrap(
                      spacing: 6,
                      children: [
                        TextButton(
                          onPressed: onCopySkillTap,
                          child: const Text('Copy'),
                        ),
                        TextButton(
                          onPressed: onSaveSkillTap,
                          child: const Text('Save'),
                        ),
                      ],
                    ),
                  ],
                ),
                Text(
                  bundle.skill.summary,
                  style: textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Copy or save this workflow if you want to reuse it later.',
                  style: textTheme.bodySmall?.copyWith(
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

class _RecommendationCard extends StatefulWidget {
  const _RecommendationCard({
    required this.recommendation,
    required this.onTap,
  });

  final PromptRecommendation recommendation;
  final VoidCallback onTap;

  @override
  State<_RecommendationCard> createState() => _RecommendationCardState();
}

class _RecommendationCardState extends State<_RecommendationCard> {
  bool _isHovering = false;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _isHovering = true),
      onExit: (_) => setState(() => _isHovering = false),
      child: AnimatedScale(
        duration: const Duration(milliseconds: 160),
        scale: _isHovering ? 1.01 : 1,
        child: InkWell(
          onTap: widget.onTap,
          borderRadius: BorderRadius.circular(32),
          child: Ink(
            width: double.infinity,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  _isHovering
                      ? colorScheme.primaryContainer.withValues(alpha: 0.42)
                      : colorScheme.surfaceContainerLow,
                  _isHovering
                      ? colorScheme.secondaryContainer.withValues(alpha: 0.32)
                      : colorScheme.surface,
                ],
              ),
              borderRadius: BorderRadius.circular(32),
              border: Border.all(
                color: _isHovering
                    ? colorScheme.primary.withValues(alpha: 0.5)
                    : colorScheme.outlineVariant.withValues(alpha: 0.6),
              ),
              boxShadow: [
                BoxShadow(
                  color: colorScheme.shadow.withValues(
                    alpha: _isHovering ? 0.08 : 0.04,
                  ),
                  blurRadius: _isHovering ? 22 : 16,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: colorScheme.primaryContainer.withValues(alpha: 0.85),
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Icon(
                      CupertinoIcons.sparkles,
                      size: 18,
                      color: colorScheme.primary,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Text(
                                widget.recommendation.title,
                                style: textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
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
                                widget.recommendation.label.displayName,
                                style: textTheme.labelSmall?.copyWith(
                                  color: colorScheme.onPrimaryContainer,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          widget.recommendation.description,
                          style: textTheme.bodyMedium,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          widget.recommendation.reason,
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
    );
  }
}

class _PromptPillButton extends StatelessWidget {
  const _PromptPillButton({
    required this.icon,
    required this.label,
    required this.onPressed,
  });

  final IconData icon;
  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return TextButton.icon(
      onPressed: onPressed,
      style: TextButton.styleFrom(
        foregroundColor: colorScheme.onSurface,
        backgroundColor: colorScheme.surface,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(999),
          side: BorderSide(
            color: colorScheme.outlineVariant.withValues(alpha: 0.7),
          ),
        ),
      ),
      icon: Icon(icon, size: 16, color: colorScheme.primary),
      label: Text(label),
    );
  }
}

class _SupportActionTile extends StatelessWidget {
  const _SupportActionTile({
    required this.onPressed,
    required this.title,
    required this.detail,
  });

  final VoidCallback onPressed;
  final String title;
  final String detail;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(20),
      child: Ink(
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: colorScheme.outlineVariant.withValues(alpha: 0.7),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: colorScheme.primary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      detail,
                      style: textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 7,
                ),
                decoration: BoxDecoration(
                  color: colorScheme.primaryContainer.withValues(alpha: 0.92),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  'Use',
                  style: textTheme.labelSmall?.copyWith(
                    color: colorScheme.onPrimaryContainer,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
