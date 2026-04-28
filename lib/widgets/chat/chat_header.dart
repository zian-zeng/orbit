import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:chatbotapp/widgets/app_icon_button.dart';

class ChatHeader extends StatelessWidget {
  const ChatHeader({
    super.key,
    required this.userName,
    required this.modelLabel,
    required this.canStartNewChat,
    required this.onOpenGuide,
    required this.onOpenHistory,
    required this.onOpenSettings,
    required this.onOpenDemo,
    required this.onOpenReport,
    required this.onOpenCoursePlanner,
    required this.onOpenIntelligence,
    required this.onNewChat,
  });

  final String userName;
  final String modelLabel;
  final bool canStartNewChat;
  final VoidCallback onOpenGuide;
  final VoidCallback onOpenHistory;
  final VoidCallback onOpenSettings;
  final VoidCallback onOpenDemo;
  final VoidCallback onOpenReport;
  final VoidCallback onOpenCoursePlanner;
  final VoidCallback onOpenIntelligence;
  final VoidCallback onNewChat;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 820;

        final titleBlock = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Orbit',
              style: theme.textTheme.titleLarge,
            ),
            const SizedBox(height: 4),
            Wrap(
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 8,
              runSpacing: 8,
              children: [
                Text(
                  userName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
                _CompactMetric(
                  icon: CupertinoIcons.sparkles,
                  label: modelLabel,
                ),
              ],
            ),
          ],
        );

        final actions = Wrap(
          spacing: 8,
          runSpacing: 8,
          alignment: WrapAlignment.end,
          children: [
            AppIconButton(
              icon: CupertinoIcons.square_pencil,
              tooltip: 'New chat',
              isEnabled: canStartNewChat,
              onTap: onNewChat,
            ),
            AppIconButton(
              icon: CupertinoIcons.book,
              tooltip: 'Guide',
              onTap: onOpenGuide,
            ),
            AppIconButton(
              icon: CupertinoIcons.clock,
              tooltip: 'History',
              onTap: onOpenHistory,
            ),
            AppIconButton(
              icon: CupertinoIcons.chart_bar_alt_fill,
              tooltip: 'Demo status',
              onTap: onOpenDemo,
            ),
            AppIconButton(
              icon: CupertinoIcons.waveform_path_ecg,
              tooltip: 'Report',
              onTap: onOpenReport,
            ),
            AppIconButton(
              icon: CupertinoIcons.calendar_badge_plus,
              tooltip: 'Course planner',
              onTap: onOpenCoursePlanner,
            ),
            AppIconButton(
              icon: CupertinoIcons.square_stack_3d_up_fill,
              tooltip: 'Intelligence dashboard',
              onTap: onOpenIntelligence,
            ),
            AppIconButton(
              icon: CupertinoIcons.settings,
              tooltip: 'Settings',
              onTap: onOpenSettings,
            ),
          ],
        );

        if (compact) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Align(
                alignment: Alignment.centerLeft,
                child: titleBlock,
              ),
              const SizedBox(height: 12),
              Align(
                alignment: Alignment.centerRight,
                child: actions,
              ),
            ],
          );
        }

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: titleBlock),
            const SizedBox(width: 16),
            Align(
              alignment: Alignment.topRight,
              child: actions,
            ),
          ],
        );
      },
    );
  }
}

class _CompactMetric extends StatelessWidget {
  const _CompactMetric({
    required this.icon,
    required this.label,
  });

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHigh.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(alpha: 0.65),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 13, color: colorScheme.onSurfaceVariant),
            const SizedBox(width: 5),
            Text(label, style: Theme.of(context).textTheme.labelSmall),
          ],
        ),
      ),
    );
  }
}
