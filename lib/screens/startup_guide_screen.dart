import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:chatbotapp/providers/user_profile_provider.dart';
import 'package:chatbotapp/widgets/startup/startup_stage_shell.dart';

class StartupGuideScreen extends StatelessWidget {
  const StartupGuideScreen({
    super.key,
    this.isRevisit = false,
  });

  final bool isRevisit;

  Future<void> _handleContinue(BuildContext context) async {
    if (isRevisit) {
      Navigator.of(context).pop();
      return;
    }

    await context.read<UserProfileProvider>().completeGuide();
  }

  @override
  Widget build(BuildContext context) {
    final userProfile = context.watch<UserProfileProvider>();
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return StartupStageShell(
      stageLabel: 'Guide',
      stageTitle: 'How Orbit works',
      stageDescription:
          'Orbit combines profile preferences, recent history, and optional student signals to shape a calmer starting point before you open a chat.',
      leadingPanel: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'What you are unlocking',
            style: textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'The workspace is built to help with planning, writing, course logistics, and support triage without pretending to know more than the data available.',
            style: textTheme.bodyLarge?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 22),
          const Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              Chip(label: Text('Planning')),
              Chip(label: Text('Writing')),
              Chip(label: Text('Course signals')),
              Chip(label: Text('Wellbeing cues')),
            ],
          ),
          const SizedBox(height: 22),
          StartupMetricCard(
            label: 'Authorized session',
            value: userProfile.email.isEmpty ? 'Local device' : userProfile.email,
          ),
          const SizedBox(height: 12),
          const StartupMetricCard(
            label: 'Guide access',
            value: 'Available later from the workspace header',
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _GuideSection(
            icon: CupertinoIcons.sparkles,
            title: 'Recommendations stay explainable',
            detail:
                'Starter prompts and support suggestions come from visible routing labels, recent activity, and any imported data you explicitly allow.',
          ),
          const SizedBox(height: 12),
          const _GuideSection(
            icon: CupertinoIcons.link,
            title: 'Connected tools are optional',
            detail:
                'Canvas, Google Calendar, and other sources stay opt-in. Orbit should never imply live access unless those signals are present.',
          ),
          const SizedBox(height: 12),
          const _GuideSection(
            icon: CupertinoIcons.lock,
            title: 'Local-first by default',
            detail:
                'Profile details, onboarding answers, and guide state persist locally through Hive so the prototype remains inspectable and predictable.',
          ),
          const SizedBox(height: 12),
          const _GuideSection(
            icon: CupertinoIcons.arrow_turn_down_right,
            title: 'The next step is personalization',
            detail:
                'Setup asks a focused set of questions so Orbit can choose better planning, writing, and wellbeing entry points from the first chat.',
          ),
          const SizedBox(height: 18),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: () => _handleContinue(context),
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: Text(
                isRevisit ? 'Continue to chat' : 'Continue to setup',
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _GuideSection extends StatelessWidget {
  const _GuideSection({
    required this.icon,
    required this.title,
    required this.detail,
  });

  final IconData icon;
  final String title;
  final String detail;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return StartupSectionFrame(
      padding: const EdgeInsets.all(18),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: colorScheme.surface,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(icon, size: 18, color: colorScheme.primary),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
                const SizedBox(height: 6),
                Text(
                  detail,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
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
