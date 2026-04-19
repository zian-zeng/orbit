import 'package:flutter/material.dart';
import 'package:chatbotapp/utilities/app_motion.dart';
import 'package:chatbotapp/widgets/app_screen_scaffold.dart';

class StartupStageShell extends StatelessWidget {
  const StartupStageShell({
    super.key,
    required this.stageLabel,
    required this.stageTitle,
    required this.stageDescription,
    required this.leadingPanel,
    required this.child,
  });

  final String stageLabel;
  final String stageTitle;
  final String stageDescription;
  final Widget leadingPanel;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return AppScreenScaffold(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final wide = constraints.maxWidth >= 980;
          final introPanel = Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  colorScheme.primaryContainer.withValues(alpha: 0.92),
                  colorScheme.surfaceContainerLow.withValues(alpha: 0.84),
                  colorScheme.secondaryContainer.withValues(alpha: 0.76),
                ],
              ),
              borderRadius: BorderRadius.circular(32),
              border: Border.all(
                color: colorScheme.outlineVariant.withValues(alpha: 0.58),
              ),
            ),
            padding: const EdgeInsets.all(24),
            child: leadingPanel,
          );

          final content = Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 7,
                ),
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerHighest
                      .withValues(alpha: 0.72),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(
                    color: colorScheme.outlineVariant.withValues(alpha: 0.55),
                  ),
                ),
                child: Text(
                  stageLabel,
                  style: textTheme.labelLarge?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Text(
                stageTitle,
                style: textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                  letterSpacing: -1,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                stageDescription,
                style: textTheme.bodyLarge?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 24),
              child,
              SizedBox(height: homeIndicatorSpacing(context, base: 20)),
            ],
          );

          return TweenAnimationBuilder<double>(
            tween: Tween<double>(begin: 0, end: 1),
            duration: AppMotion.regular,
            curve: AppMotion.curve,
            builder: (context, value, animatedChild) {
              return Opacity(
                opacity: value,
                child: Transform.translate(
                  offset: Offset(0, (1 - value) * 18),
                  child: animatedChild,
                ),
              );
            },
            child: SingleChildScrollView(
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
                        Expanded(child: content),
                      ],
                    )
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 12),
                        introPanel,
                        const SizedBox(height: 20),
                        content,
                      ],
                    ),
            ),
          );
        },
      ),
    );
  }
}

class StartupSectionFrame extends StatelessWidget {
  const StartupSectionFrame({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(18),
  });

  final Widget child;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLow.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(alpha: 0.55),
        ),
      ),
      child: child,
    );
  }
}

class StartupMetricCard extends StatelessWidget {
  const StartupMetricCard({
    super.key,
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return StartupSectionFrame(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
          ),
        ],
      ),
    );
  }
}
