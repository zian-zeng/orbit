import 'package:chatbotapp/agents/orbit_models.dart';
import 'package:chatbotapp/data_sources/integration_config.dart';
import 'package:chatbotapp/providers/settings_provider.dart';
import 'package:chatbotapp/providers/user_profile_provider.dart';
import 'package:chatbotapp/services/connected_apps_service.dart';
import 'package:chatbotapp/widgets/app_icon_button.dart';
import 'package:chatbotapp/widgets/app_screen_scaffold.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class ConnectedAppsScreen extends StatelessWidget {
  const ConnectedAppsScreen({super.key});

  static const ConnectedAppsService _service = ConnectedAppsService();

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>();
    final profile = context.watch<UserProfileProvider>();
    final config = IntegrationConfig.fromEnvironment();
    final apps = _service.build(
      config: config,
      allowExternalData: settings.allowExternalStudentData,
      preferDemoFixture: settings.preferDemoFixture,
      labels: {
        ...profile.routingLabelKeys,
        ...profile.preferredLabelKeys,
      },
    );
    final connectedCount = apps.where((app) => app.isConnected).length;

    return AppScreenScaffold(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
      child: Column(
        children: [
          _Header(connectedCount: connectedCount),
          const SizedBox(height: 16),
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.only(
                bottom: homeIndicatorSpacing(context, base: 24),
              ),
              child: Column(
                children: [
                  _PrivacySummary(
                    allowExternalData: settings.allowExternalStudentData,
                    preferDemoFixture: settings.preferDemoFixture,
                    hasAnyRealData: config.hasAnyRealData,
                  ),
                  const SizedBox(height: 12),
                  ...apps.map(
                    (app) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _ConnectedAppCard(app: app),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.connectedCount});

  final int connectedCount;

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
                'Connected Apps',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 4),
              Text(
                '$connectedCount live source(s), approval-gated tools',
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _PrivacySummary extends StatelessWidget {
  const _PrivacySummary({
    required this.allowExternalData,
    required this.preferDemoFixture,
    required this.hasAnyRealData,
  });

  final bool allowExternalData;
  final bool preferDemoFixture;
  final bool hasAnyRealData;

  @override
  Widget build(BuildContext context) {
    final mode = preferDemoFixture
        ? 'Demo fixture mode'
        : allowExternalData && hasAnyRealData
            ? 'Live data mode'
            : 'Local-first mode';
    final detail = preferDemoFixture
        ? 'ORBIT skips live connectors and uses deterministic UMD demo signals.'
        : allowExternalData
            ? 'ORBIT may use configured connectors, but external tools still require approval when sensitive.'
            : 'ORBIT stays local unless the student enables live data consent.';
    return _Panel(
      title: mode,
      subtitle: 'Data mode and consent',
      icon: CupertinoIcons.lock_shield,
      child: Text(detail),
    );
  }
}

class _ConnectedAppCard extends StatelessWidget {
  const _ConnectedAppCard({required this.app});

  final ConnectedStudentApp app;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return _Panel(
      title: app.name,
      subtitle: app.status.label,
      icon: _iconFor(app.id),
      trailing: _StatusPill(status: app.status),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(app.description),
          const SizedBox(height: 12),
          _LabelWrap(
            title: 'Data used',
            values: app.dataUsed,
          ),
          const SizedBox(height: 12),
          _PermissionList(decisions: app.permissionDecisions),
          const SizedBox(height: 12),
          Text(
            'Next: ${app.nextStep}',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
          ),
        ],
      ),
    );
  }

  IconData _iconFor(String id) {
    return switch (id) {
      'student_data_proxy' => CupertinoIcons.link_circle,
      'canvas' => CupertinoIcons.doc_text,
      'google_calendar' => CupertinoIcons.calendar,
      'maps_places' => CupertinoIcons.map,
      'planetterp' => CupertinoIcons.person_2_square_stack,
      'testudo_umd_io' => CupertinoIcons.building_2_fill,
      'device_activity' => CupertinoIcons.device_laptop,
      'notifications' => CupertinoIcons.bell,
      _ => CupertinoIcons.link,
    };
  }
}

class _LabelWrap extends StatelessWidget {
  const _LabelWrap({
    required this.title,
    required this.values,
  });

  final String title;
  final List<String> values;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: Theme.of(context).textTheme.titleSmall),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: values.map((value) => _SmallChip(label: value)).toList(),
        ),
      ],
    );
  }
}

class _PermissionList extends StatelessWidget {
  const _PermissionList({required this.decisions});

  final List<ToolPermissionDecision> decisions;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Tool permissions', style: Theme.of(context).textTheme.titleSmall),
        const SizedBox(height: 8),
        ...decisions.map(
          (decision) => Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _PermissionDot(level: decision.level),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '${decision.toolId}: ${decision.level.label}',
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _PermissionDot extends StatelessWidget {
  const _PermissionDot({required this.level});

  final OrbitToolPermissionLevel level;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final color = switch (level) {
      OrbitToolPermissionLevel.autoAllowed => colorScheme.primary,
      OrbitToolPermissionLevel.approvalRequired => colorScheme.tertiary,
      OrbitToolPermissionLevel.blocked => colorScheme.error,
    };
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Icon(CupertinoIcons.circle_fill, size: 8, color: color),
    );
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.status});

  final ConnectedAppStatus status;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final color = switch (status) {
      ConnectedAppStatus.connected => colorScheme.primaryContainer,
      ConnectedAppStatus.available => colorScheme.secondaryContainer,
      ConnectedAppStatus.demoOnly => colorScheme.tertiaryContainer,
      ConnectedAppStatus.planned => colorScheme.surfaceContainerHighest,
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(status.label, style: Theme.of(context).textTheme.labelSmall),
    );
  }
}

class _Panel extends StatelessWidget {
  const _Panel({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.child,
    this.trailing,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final Widget child;
  final Widget? trailing;

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
              if (trailing != null) trailing!,
            ],
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}

class _SmallChip extends StatelessWidget {
  const _SmallChip({required this.label});

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
