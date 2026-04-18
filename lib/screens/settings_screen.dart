import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:chatbotapp/data_sources/integration_config.dart';
import 'package:chatbotapp/models/prompt_recommendation.dart';
import 'package:flutter/services.dart';
import 'package:chatbotapp/providers/chat_provider.dart';
import 'package:chatbotapp/providers/settings_provider.dart';
import 'package:chatbotapp/providers/user_profile_provider.dart';
import 'package:chatbotapp/services/label_enrichment_service.dart';
import 'package:chatbotapp/utilities/animated_dialog.dart';
import 'package:chatbotapp/utilities/app_motion.dart';
import 'package:chatbotapp/utilities/app_snackbar.dart';
import 'package:chatbotapp/widgets/app_icon_button.dart';
import 'package:chatbotapp/widgets/app_screen_scaffold.dart';
import 'package:chatbotapp/widgets/build_display_image.dart';
import 'package:chatbotapp/widgets/profile_avatar.dart';
import 'package:chatbotapp/widgets/settings_tile.dart';
import 'package:chatbotapp/widgets/theme_mode_selector.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _calendarTokenController =
      TextEditingController();
  final TextEditingController _calendarIdController = TextEditingController(
    text: 'primary',
  );
  final TextEditingController _canvasBaseUrlController =
      TextEditingController();
  final TextEditingController _canvasTokenController = TextEditingController();
  final ImagePicker _picker = ImagePicker();
  final LabelEnrichmentService _labelEnrichmentService =
      const LabelEnrichmentService();
  File? _draftImageFile;
  bool _isEditingProfile = false;
  bool _isRefreshingSignals = false;
  bool _isImportingCalendar = false;
  bool _isImportingCanvas = false;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _calendarTokenController.dispose();
    _calendarIdController.dispose();
    _canvasBaseUrlController.dispose();
    _canvasTokenController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    try {
      final pickedImage = await _picker.pickImage(
        source: ImageSource.gallery,
        maxHeight: 1200,
        maxWidth: 1200,
        imageQuality: 95,
      );
      if (pickedImage == null) {
        return;
      }

      setState(() {
        _draftImageFile = File(pickedImage.path);
      });
    } catch (_) {
      if (!mounted) {
        return;
      }
      showAppSnackBar(context, 'Could not open photos');
    }
  }

  void _beginEditing(UserProfileProvider userProfile) {
    setState(() {
      _isEditingProfile = true;
      _nameController.text = userProfile.name;
      _emailController.text = userProfile.email;
      _draftImageFile = null;
    });
  }

  void _cancelEditing() {
    setState(() {
      _isEditingProfile = false;
      _draftImageFile = null;
    });
  }

  Future<void> _saveProfile(UserProfileProvider userProfile) async {
    final enableHaptics = context.read<SettingsProvider>().enableHaptics;
    final imagePath = _draftImageFile?.path ?? userProfile.imagePath;

    await userProfile.saveProfile(
      name: _nameController.text,
      email: _emailController.text.trim(),
      imagePath: imagePath,
    );

    if (!mounted) {
      return;
    }

    if (enableHaptics) {
      await HapticFeedback.selectionClick();
    }

    _cancelEditing();
    if (mounted) {
      showAppSnackBar(context, 'Saved');
    }
  }

  Future<void> _confirmClearHistory() async {
    final chatProvider = context.read<ChatProvider>();
    final userProfile = context.read<UserProfileProvider>();
    final confirmed = await showAnimatedConfirmationDialog(
      context: context,
      title: 'Clear history',
      content: 'Remove all chats?',
      actionText: 'Clear',
    );

    if (!mounted || !confirmed) {
      return;
    }

    await chatProvider.clearAllChats();
    await userProfile.refreshEnrichedLabels();
    if (mounted) {
      showAppSnackBar(context, 'History cleared');
    }
  }

  Future<void> _refreshSignals(UserProfileProvider userProfile) async {
    if (_isRefreshingSignals) {
      return;
    }

    setState(() {
      _isRefreshingSignals = true;
    });

    try {
      await userProfile.refreshEnrichedLabels();
      if (!mounted) {
        return;
      }
      showAppSnackBar(context, 'Refreshed label signals');
    } finally {
      if (mounted) {
        setState(() {
          _isRefreshingSignals = false;
        });
      }
    }
  }

  Future<void> _importGoogleCalendar(UserProfileProvider userProfile) async {
    final accessToken = _calendarTokenController.text.trim();
    final calendarId = _calendarIdController.text.trim().isEmpty
        ? 'primary'
        : _calendarIdController.text.trim();

    if (accessToken.isEmpty) {
      showAppSnackBar(context, 'Enter a Google Calendar access token');
      return;
    }

    setState(() {
      _isImportingCalendar = true;
    });

    try {
      final snapshot = await _labelEnrichmentService.fetchGoogleCalendarLabels(
        accessToken: accessToken,
        calendarId: calendarId,
      );
      if (snapshot.rankedLabels.isEmpty) {
        await userProfile.mergeImportedLabelSignals(
          labelKeys: const [],
          sourceName: snapshot.sourceName,
        );
        if (!mounted) {
          return;
        }
        showAppSnackBar(context, 'No calendar signals found; import cleared');
        return;
      }
      await userProfile.mergeImportedLabelSignals(
        labelKeys: snapshot.labelKeys,
        sourceName: snapshot.sourceName,
      );
      if (!mounted) {
        return;
      }
      showAppSnackBar(
        context,
        'Imported ${snapshot.itemCount} Google Calendar events',
      );
    } catch (error) {
      if (!mounted) {
        return;
      }
      showAppSnackBar(context, '$error');
    } finally {
      if (mounted) {
        setState(() {
          _isImportingCalendar = false;
        });
      }
    }
  }

  Future<void> _importCanvas(UserProfileProvider userProfile) async {
    final baseUrl = _canvasBaseUrlController.text.trim();
    final accessToken = _canvasTokenController.text.trim();

    if (baseUrl.isEmpty || accessToken.isEmpty) {
      showAppSnackBar(context, 'Enter both Canvas base URL and access token');
      return;
    }

    setState(() {
      _isImportingCanvas = true;
    });

    try {
      final snapshot = await _labelEnrichmentService.fetchCanvasLabels(
        baseUrl: baseUrl,
        accessToken: accessToken,
      );
      if (snapshot.rankedLabels.isEmpty) {
        await userProfile.mergeImportedLabelSignals(
          labelKeys: const [],
          sourceName: snapshot.sourceName,
        );
        if (!mounted) {
          return;
        }
        showAppSnackBar(context, 'No Canvas signals found; import cleared');
        return;
      }
      await userProfile.mergeImportedLabelSignals(
        labelKeys: snapshot.labelKeys,
        sourceName: snapshot.sourceName,
      );
      if (!mounted) {
        return;
      }
      showAppSnackBar(
        context,
        'Imported ${snapshot.itemCount} Canvas items',
      );
    } catch (error) {
      if (!mounted) {
        return;
      }
      showAppSnackBar(context, '$error');
    } finally {
      if (mounted) {
        setState(() {
          _isImportingCanvas = false;
        });
      }
    }
  }

  Future<void> _clearImportedSignals(UserProfileProvider userProfile) async {
    await userProfile.clearImportedLabelSignals();
    if (!mounted) {
      return;
    }
    showAppSnackBar(context, 'Cleared imported label signals');
  }

  @override
  Widget build(BuildContext context) {
    final settingsProvider = context.watch<SettingsProvider>();
    final userProfile = context.watch<UserProfileProvider>();
    final colorScheme = Theme.of(context).colorScheme;
    final integrationConfig = IntegrationConfig.fromEnvironment();
    final motionDuration =
        settingsProvider.reduceMotion ? Duration.zero : AppMotion.regular;

    return AppScreenScaffold(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                AppIconButton(
                  icon: CupertinoIcons.back,
                  tooltip: 'Back',
                  onTap: () => Navigator.of(context).pop(),
                ),
                const SizedBox(width: 12),
                Text('Settings', style: Theme.of(context).textTheme.titleLarge),
              ],
            ),
            const SizedBox(height: 16),
            Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(28),
                side: BorderSide(
                  color: colorScheme.outlineVariant.withValues(alpha: 0.72),
                ),
              ),
              child: AnimatedSize(
                duration: motionDuration,
                curve: AppMotion.curve,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          _isEditingProfile
                              ? BuildDisplayImage(
                                  file: _draftImageFile,
                                  userImage: userProfile.imagePath,
                                  onPressed: _pickImage,
                                  radius: 34,
                                )
                              : ProfileAvatar(
                                  name: userProfile.name,
                                  imagePath: userProfile.imagePath,
                                  radius: 34,
                                ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  userProfile.name,
                                  style: Theme.of(context)
                                      .textTheme
                                      .titleLarge
                                      ?.copyWith(fontWeight: FontWeight.w700),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  userProfile.email.isEmpty
                                      ? 'Profile'
                                      : userProfile.email,
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodyMedium
                                      ?.copyWith(
                                        color: colorScheme.onSurfaceVariant,
                                      ),
                                ),
                              ],
                            ),
                          ),
                          AppIconButton(
                            onTap: _isEditingProfile
                                ? _cancelEditing
                                : () => _beginEditing(userProfile),
                            tooltip: _isEditingProfile ? 'Cancel' : 'Edit',
                            icon: _isEditingProfile
                                ? CupertinoIcons.xmark
                                : CupertinoIcons.pencil,
                          ),
                        ],
                      ),
                      if (_isEditingProfile) ...[
                        const SizedBox(height: 16),
                        TextField(
                          controller: _nameController,
                          textCapitalization: TextCapitalization.words,
                          decoration: const InputDecoration(labelText: 'Name'),
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: _emailController,
                          keyboardType: TextInputType.emailAddress,
                          decoration: const InputDecoration(
                            labelText: 'Email',
                            hintText: 'name@umd.edu',
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton(
                                onPressed: _cancelEditing,
                                child: const Text('Cancel'),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: FilledButton(
                                onPressed: () => _saveProfile(userProfile),
                                child: const Text('Save'),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 22),
            const _SectionLabel(title: 'Label Signals'),
            const SizedBox(height: 10),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Routing focus',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: supportLabelsFromKeys(
                        userProfile.routingLabelKeys,
                      )
                          .take(3)
                          .map(
                            (label) => Chip(
                              label: Text(label.displayName),
                            ),
                          )
                          .toList(growable: false),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Orbit combines signup answers, chat history, and optional imports to keep these labels fresh.',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                    ),
                    if (userProfile.labelSignalSources.isNotEmpty) ...[
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: userProfile.labelSignalSources
                            .map(
                              (source) => Chip(
                                label: Text(source),
                              ),
                            )
                            .toList(growable: false),
                      ),
                    ],
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: _isRefreshingSignals
                                ? null
                                : () => _refreshSignals(userProfile),
                            child: Text(
                              _isRefreshingSignals
                                  ? 'Refreshing...'
                                  : 'Refresh from history',
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: OutlinedButton(
                            onPressed: userProfile.importedLabelKeys.isEmpty
                                ? null
                                : () => _clearImportedSignals(userProfile),
                            child: const Text('Clear imports'),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),
                    Text(
                      'Google Calendar import',
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _calendarTokenController,
                      obscureText: true,
                      decoration: const InputDecoration(
                        labelText: 'Access token',
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: _calendarIdController,
                      decoration: const InputDecoration(
                        labelText: 'Calendar ID',
                        hintText: 'primary',
                      ),
                    ),
                    const SizedBox(height: 10),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        onPressed: _isImportingCalendar
                            ? null
                            : () => _importGoogleCalendar(userProfile),
                        child: Text(
                          _isImportingCalendar
                              ? 'Importing calendar...'
                              : 'Import Google Calendar',
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),
                    Text(
                      'Canvas import',
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _canvasBaseUrlController,
                      decoration: const InputDecoration(
                        labelText: 'Canvas base URL',
                        hintText: 'https://canvas.school.edu',
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: _canvasTokenController,
                      obscureText: true,
                      decoration: const InputDecoration(
                        labelText: 'Canvas access token',
                      ),
                    ),
                    const SizedBox(height: 10),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        onPressed: _isImportingCanvas
                            ? null
                            : () => _importCanvas(userProfile),
                        child: Text(
                          _isImportingCanvas
                              ? 'Importing Canvas...'
                              : 'Import Canvas',
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 18),
            const _SectionLabel(title: 'Real Data Consent'),
            const SizedBox(height: 10),
            Card(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SettingsTile(
                    icon: CupertinoIcons.lock_shield,
                    title: 'Canvas/Google live data',
                    subtitle:
                        'Let Orbit use connected proxy, Canvas, Calendar, Maps, and Places signals for assistant context.',
                    value: settingsProvider.allowExternalStudentData,
                    onChanged: (value) {
                      settingsProvider.toggleExternalStudentData(value: value);
                    },
                  ),
                  const Divider(height: 1),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Connector readiness',
                          style: Theme.of(context).textTheme.titleSmall,
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            _ReadinessChip(
                              label: 'Proxy',
                              ready: integrationConfig.hasStudentDataProxy,
                            ),
                            _ReadinessChip(
                              label: 'Canvas',
                              ready: integrationConfig.hasCanvas,
                            ),
                            _ReadinessChip(
                              label: 'Calendar',
                              ready: integrationConfig.hasGoogleCalendar,
                            ),
                            _ReadinessChip(
                              label: 'Maps/Places',
                              ready: integrationConfig.hasGoogleMaps,
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Text(
                          settingsProvider.allowExternalStudentData
                              ? integrationConfig.hasAnyRealData
                                  ? 'Live connectors are allowed. Orbit will still fall back cleanly when a source fails or times out.'
                                  : 'Consent is on, but no live connector credentials are configured for this build.'
                              : 'Live connector calls stay off until the student opts in here. Manual imports remain available below.',
                          style: Theme.of(context)
                              .textTheme
                              .bodySmall
                              ?.copyWith(color: colorScheme.onSurfaceVariant),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            const _SectionLabel(title: 'Appearance'),
            const SizedBox(height: 10),
            Card(
              child: ThemeModeSelector(
                value: settingsProvider.appThemeMode,
                onChanged: (value) {
                  settingsProvider.setThemeMode(value: value);
                },
              ),
            ),
            const SizedBox(height: 18),
            const _SectionLabel(title: 'Interaction'),
            const SizedBox(height: 10),
            Card(
              child: Column(
                children: [
                  SettingsTile(
                    icon: CupertinoIcons.hand_raised_fill,
                    title: 'Haptics',
                    subtitle: 'Feedback on actions',
                    value: settingsProvider.enableHaptics,
                    onChanged: (value) {
                      settingsProvider.toggleHaptics(value: value);
                    },
                  ),
                  const Divider(height: 1),
                  SettingsTile(
                    icon: CupertinoIcons.waveform,
                    title: 'Voice input',
                    subtitle: 'Use speech in chat',
                    value: settingsProvider.enableVoiceInput,
                    onChanged: (value) {
                      settingsProvider.toggleVoiceInput(value: value);
                    },
                  ),
                  const Divider(height: 1),
                  SettingsTile(
                    icon: CupertinoIcons.arrow_down_to_line,
                    title: 'Auto-scroll',
                    subtitle: 'Follow new messages',
                    value: settingsProvider.autoScroll,
                    onChanged: (value) {
                      settingsProvider.toggleAutoScroll(value: value);
                    },
                  ),
                  const Divider(height: 1),
                  SettingsTile(
                    icon: CupertinoIcons.return_icon,
                    title: 'Send with Return',
                    subtitle: 'Press enter to send',
                    value: settingsProvider.sendWithEnter,
                    onChanged: (value) {
                      settingsProvider.toggleSendWithEnter(value: value);
                    },
                  ),
                  const Divider(height: 1),
                  SettingsTile(
                    icon: CupertinoIcons.arrow_2_circlepath,
                    title: 'Reduce motion',
                    subtitle: 'Use simpler transitions',
                    value: settingsProvider.reduceMotion,
                    onChanged: (value) {
                      settingsProvider.toggleReduceMotion(value: value);
                    },
                  ),
                  const Divider(height: 1),
                  SettingsTile(
                    icon: CupertinoIcons.keyboard_chevron_compact_down,
                    title: 'Auto-focus composer',
                    subtitle: 'Focus message box on open',
                    value: settingsProvider.autoFocusComposer,
                    onChanged: (value) {
                      settingsProvider.toggleAutoFocusComposer(value: value);
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            const _SectionLabel(title: 'Monitor'),
            const SizedBox(height: 10),
            Card(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(CupertinoIcons.timer, size: 20),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Break threshold',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                        ),
                        Text('${settingsProvider.focusBreakMinutes} min'),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'When a focus block reaches this duration, Orbit recommends a walk or reset.',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                    ),
                    Slider(
                      min: 15,
                      max: 180,
                      divisions: 11,
                      value: settingsProvider.focusBreakMinutes
                          .clamp(15, 180)
                          .toDouble(),
                      label: '${settingsProvider.focusBreakMinutes} min',
                      onChanged: (value) {
                        settingsProvider.setFocusBreakMinutes(
                          value: value.round(),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 18),
            const _SectionLabel(title: 'Data'),
            const SizedBox(height: 10),
            Card(
              child: Column(
                children: [
                  SettingsTile(
                    icon: CupertinoIcons.archivebox_fill,
                    title: 'Save history',
                    subtitle: 'Keep chats on this device',
                    value: settingsProvider.saveChatHistory,
                    onChanged: (value) {
                      settingsProvider.toggleSaveChatHistory(value: value);
                    },
                  ),
                  const Divider(height: 1),
                  SettingsTile(
                    icon: CupertinoIcons.square_grid_2x2,
                    title: 'Suggestions',
                    subtitle: 'Show recommended prompts',
                    value: settingsProvider.showStarterPrompts,
                    onChanged: (value) {
                      settingsProvider.toggleShowStarterPrompts(value: value);
                    },
                  ),
                  const Divider(height: 1),
                  _ActionTile(
                    icon: CupertinoIcons.trash,
                    title: 'Clear history',
                    subtitle: 'Delete local chats',
                    isDestructive: true,
                    onTap: _confirmClearHistory,
                  ),
                ],
              ),
            ),
            SizedBox(
              height: homeIndicatorSpacing(
                context,
                base: 10,
                factor: 0.1,
                maxExtra: 4,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ReadinessChip extends StatelessWidget {
  const _ReadinessChip({
    required this.label,
    required this.ready,
  });

  final String label;
  final bool ready;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final backgroundColor =
        ready ? colorScheme.primaryContainer : colorScheme.surfaceContainerHigh;
    final foregroundColor =
        ready ? colorScheme.onPrimaryContainer : colorScheme.onSurfaceVariant;

    return Chip(
      avatar: Icon(
        ready ? CupertinoIcons.checkmark_circle_fill : CupertinoIcons.clock,
        size: 16,
        color: foregroundColor,
      ),
      label: Text(label),
      backgroundColor: backgroundColor,
      labelStyle: TextStyle(color: foregroundColor),
      side: BorderSide(color: backgroundColor),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Text(title, style: Theme.of(context).textTheme.titleMedium);
  }
}

class _ActionTile extends StatelessWidget {
  const _ActionTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.isDestructive = false,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final bool isDestructive;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final iconColor =
        isDestructive ? colorScheme.error : colorScheme.onPrimaryContainer;
    final iconBackground = isDestructive
        ? colorScheme.errorContainer
        : colorScheme.primaryContainer;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(11),
              decoration: BoxDecoration(
                color: iconBackground,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, color: iconColor),
            ),
            const SizedBox(width: 14),
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
            Icon(
              CupertinoIcons.chevron_right,
              size: 18,
              color: colorScheme.onSurfaceVariant,
            ),
          ],
        ),
      ),
    );
  }
}
