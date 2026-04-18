import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:chatbotapp/constants/constants.dart';
import 'package:chatbotapp/models/prompt_recommendation.dart';
import 'package:chatbotapp/models/support_intelligence.dart';
import 'package:chatbotapp/providers/chat_provider.dart';
import 'package:chatbotapp/providers/settings_provider.dart';
import 'package:chatbotapp/providers/user_profile_provider.dart';
import 'package:chatbotapp/providers/voice_input_provider.dart';
import 'package:chatbotapp/screens/chat_history_screen.dart';
import 'package:chatbotapp/screens/demo_status_screen.dart';
import 'package:chatbotapp/screens/intelligence_dashboard_screen.dart';
import 'package:chatbotapp/screens/settings_screen.dart';
import 'package:chatbotapp/services/prompt_router.dart';
import 'package:chatbotapp/services/skill_registry_service.dart';
import 'package:chatbotapp/utilities/animated_dialog.dart';
import 'package:chatbotapp/utilities/app_motion.dart';
import 'package:chatbotapp/utilities/app_snackbar.dart';
import 'package:chatbotapp/widgets/app_screen_scaffold.dart';
import 'package:chatbotapp/widgets/chat/chat_empty_state.dart';
import 'package:chatbotapp/widgets/chat/chat_header.dart';
import 'package:chatbotapp/widgets/chat_messages.dart';
import 'package:chatbotapp/widgets/bottom_chat_field.dart';
import 'package:provider/provider.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final PromptRouter _promptRouter = const PromptRouter();
  final SkillRegistryService _skillRegistryService =
      const SkillRegistryService();
  final TextEditingController _composerController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  int _lastMessageCount = 0;
  bool _showJumpToLatest = false;
  String _draftText = '';
  SupportLabel? _selectedLabel;
  PromptRecommendation? _selectedRecommendation;
  bool _isApplyingRecommendation = false;
  bool _didRequestExternalSignalSync = false;

  @override
  void initState() {
    _scrollController.addListener(_syncJumpToLatestButton);
    super.initState();
  }

  @override
  void dispose() {
    _scrollController.removeListener(_syncJumpToLatestButton);
    _scrollController.dispose();
    _composerController.dispose();
    super.dispose();
  }

  void _handleDraftChanged(String value) {
    if (_isApplyingRecommendation) {
      return;
    }

    final shouldClearSelection = _selectedRecommendation != null &&
        value.trim() != _selectedRecommendation!.promptTemplate.trim();

    setState(() {
      _draftText = value;
      if (shouldClearSelection) {
        _selectedRecommendation = null;
      }
    });
  }

  void _handleMessageSent() {
    setState(() {
      _draftText = '';
      _selectedLabel = null;
      _selectedRecommendation = null;
    });
  }

  void _requestExternalSignalSync() {
    if (_didRequestExternalSignalSync) {
      return;
    }
    _didRequestExternalSignalSync = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      context.read<UserProfileProvider>().refreshExternalStudentSignals();
    });
  }

  bool _shouldShowJumpToLatest() {
    if (!_scrollController.hasClients) {
      return false;
    }

    final position = _scrollController.position;
    final distanceToBottom = position.maxScrollExtent - position.pixels;
    return position.maxScrollExtent > 180 && distanceToBottom > 56;
  }

  void _syncJumpToLatestButton() {
    if (!mounted) {
      return;
    }

    final shouldShow = _shouldShowJumpToLatest();
    if (shouldShow != _showJumpToLatest) {
      setState(() {
        _showJumpToLatest = shouldShow;
      });
    }
  }

  void _refreshJumpToLatestButton() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _syncJumpToLatestButton();
    });
  }

  void _resetJumpToLatestState() {
    _lastMessageCount = 0;
    if (_showJumpToLatest && mounted) {
      setState(() {
        _showJumpToLatest = false;
      });
    } else {
      _showJumpToLatest = false;
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.jumpTo(0);
      }
    });
  }

  void _resetComposerRoutingState() {
    _isApplyingRecommendation = true;
    _composerController.clear();
    _isApplyingRecommendation = false;
    _draftText = '';
    _selectedLabel = null;
    _selectedRecommendation = null;
  }

  void _scrollToBottom() {
    final reduceMotion = context.read<SettingsProvider>().reduceMotion;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) {
        return;
      }

      final maxScrollExtent = _scrollController.position.maxScrollExtent;

      if (reduceMotion) {
        _scrollController.jumpTo(maxScrollExtent);
        _syncJumpToLatestButton();
        return;
      }

      _scrollController
          .animateTo(
            maxScrollExtent,
            duration: AppMotion.scroll,
            curve: AppMotion.curve,
          )
          .whenComplete(_syncJumpToLatestButton);
    });
  }

  void _syncAutoScroll({
    required ChatProvider chatProvider,
    required SettingsProvider settingsProvider,
  }) {
    if (!chatProvider.hasMessages) {
      _resetJumpToLatestState();
      return;
    }

    if (!settingsProvider.autoScroll) {
      _lastMessageCount = chatProvider.messageCount;
      _refreshJumpToLatestButton();
      return;
    }

    if (chatProvider.messageCount != _lastMessageCount) {
      _lastMessageCount = chatProvider.messageCount;
      if (chatProvider.messageCount > 0) {
        _scrollToBottom();
      }
    }

    _refreshJumpToLatestButton();
  }

  String _modelLabel(String modelType) {
    if (modelType == Constants.localAgentModel) {
      return 'Local';
    }
    return modelType.contains('flash') ? 'Flash' : 'Vision';
  }

  Future<void> _startNewChat(ChatProvider chatProvider) async {
    if (!chatProvider.hasMessages) {
      await chatProvider.prepareChatRoom(isNewChat: true, chatID: '');
      setState(_resetComposerRoutingState);
      return;
    }

    final confirmed = await showAnimatedConfirmationDialog(
      context: context,
      title: 'New chat',
      content: 'Start fresh?',
      actionText: 'Start',
    );

    if (!confirmed) {
      return;
    }

    await chatProvider.prepareChatRoom(isNewChat: true, chatID: '');
    _resetJumpToLatestState();
    setState(_resetComposerRoutingState);
  }

  void _selectLabel(SupportLabel? label) {
    setState(() {
      _selectedLabel = label;
      _selectedRecommendation = null;
    });
  }

  void _applyRecommendation(PromptRecommendation recommendation) {
    _applyPrompt(
      prompt: recommendation.promptTemplate,
      label: recommendation.label,
    );

    setState(() {
      _selectedRecommendation = recommendation;
    });
  }

  void _applyPrompt({
    required String prompt,
    SupportLabel? label,
  }) {
    _isApplyingRecommendation = true;
    _composerController.value = TextEditingValue(
      text: prompt,
      selection: TextSelection.collapsed(
        offset: prompt.length,
      ),
    );
    _isApplyingRecommendation = false;

    setState(() {
      _draftText = prompt;
      _selectedLabel = label;
      if (label == null) {
        _selectedRecommendation = null;
      }
    });
  }

  Future<void> _copySkillBlueprint(AgentSkillBlueprint skill) async {
    await Clipboard.setData(
      ClipboardData(text: skill.toMarkdown()),
    );
    if (!mounted) {
      return;
    }
    showAppSnackBar(context, 'Agent skill copied');
  }

  Future<void> _saveSkillBlueprint(SupportIntelligenceBundle bundle) async {
    final entry = await _skillRegistryService.saveBlueprint(
      blueprint: bundle.skill,
      sourceLabels: [
        bundle.primaryLabel.storageKey,
        bundle.secondaryLabel.storageKey,
      ],
      stressBand: bundle.stressReport.band,
    );
    if (!mounted) {
      return;
    }
    if (entry == null) {
      showAppSnackBar(context, 'Skill registry is not ready yet');
      return;
    }
    showAppSnackBar(
      context,
      'Saved ${entry.title} ${entry.versionLabel}',
    );
  }

  Future<T?> _openPage<T>(Widget page) async {
    final reduceMotion = context.read<SettingsProvider>().reduceMotion;
    final route = reduceMotion
        ? PageRouteBuilder<T>(
            pageBuilder: (context, animation, secondaryAnimation) => page,
            transitionDuration: Duration.zero,
            reverseTransitionDuration: Duration.zero,
          )
        : CupertinoPageRoute<T>(builder: (context) => page);

    return Navigator.of(context).push(route);
  }

  Future<void> _openDemoPath() async {
    final prompt = await _openPage<String>(const DemoStatusScreen());
    if (!mounted || prompt == null || prompt.trim().isEmpty) {
      return;
    }

    _applyPrompt(
      prompt: prompt,
      label: SupportLabel.planning,
    );
    showAppSnackBar(context, 'Demo prompt loaded');
  }

  @override
  Widget build(BuildContext context) {
    return Consumer3<ChatProvider, SettingsProvider, VoiceInputProvider>(
      builder: (context, chatProvider, settingsProvider, voiceProvider, child) {
        _syncAutoScroll(
          chatProvider: chatProvider,
          settingsProvider: settingsProvider,
        );
        final userProfile = context.watch<UserProfileProvider>();
        _requestExternalSignalSync();
        final userName = userProfile.firstName;
        final routingContext = RoutingContext(
          draftText: _draftText,
          selectedLabel: _selectedLabel,
          hasImages: chatProvider.imagesFileList?.isNotEmpty ?? false,
          recentLabels: supportLabelsFromKeys(chatProvider.recentLabelKeys()),
          preferredLabels: supportLabelsFromKeys(
            userProfile.routingLabelKeys,
          ),
        );
        final recommendations = _promptRouter.recommend(
          context: routingContext,
        );
        final supportBundle = userProfile.buildSupportIntelligence(
          recentLabelKeys: chatProvider.recentLabelKeys(),
        );
        final showJumpButton = chatProvider.hasMessages && _showJumpToLatest;
        final motionDuration =
            settingsProvider.reduceMotion ? Duration.zero : AppMotion.regular;
        final bottomInset = homeIndicatorSpacing(
          context,
          base: 12,
          factor: 0.12,
          maxExtra: 6,
        );
        final draftImages = chatProvider.imagesFileList?.isNotEmpty ?? false;
        final composerInset = bottomInset +
            92 +
            (draftImages ? 112 : 0) +
            (voiceProvider.isListening ? 44 : 0);
        final contentBottomPadding =
            composerInset > 24 ? composerInset - 24 : composerInset;

        return AppScreenScaffold(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
          child: Column(
            children: [
              ChatHeader(
                userName: userName,
                modelLabel: _modelLabel(chatProvider.modelType),
                canStartNewChat: chatProvider.hasMessages,
                onOpenHistory: () => _openPage<void>(const ChatHistoryScreen()),
                onOpenSettings: () => _openPage<void>(const SettingsScreen()),
                onOpenDemo: _openDemoPath,
                onOpenIntelligence: () =>
                    _openPage<void>(const IntelligenceDashboardScreen()),
                onNewChat: () => _startNewChat(chatProvider),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Positioned.fill(
                      child: AnimatedSwitcher(
                        duration: motionDuration,
                        child: chatProvider.hasMessages
                            ? ChatMessages(
                                key: const ValueKey('chat-messages'),
                                scrollController: _scrollController,
                                chatProvider: chatProvider,
                                bottomPadding: contentBottomPadding,
                              )
                            : Padding(
                                key: const ValueKey('chat-empty'),
                                padding: EdgeInsets.only(
                                  bottom: contentBottomPadding,
                                ),
                                child: ChatEmptyState(
                                  apiConfigured: true,
                                  showStarterPrompts:
                                      settingsProvider.showStarterPrompts,
                                  supportBundle: supportBundle,
                                  labels: _promptRouter.labels,
                                  recommendations: recommendations,
                                  selectedLabel: _selectedLabel,
                                  onSuggestionTap: _applyRecommendation,
                                  onInsightPromptTap: (prompt) =>
                                      _applyPrompt(prompt: prompt),
                                  onCopySkillTap: supportBundle == null
                                      ? null
                                      : () => _copySkillBlueprint(
                                            supportBundle.skill,
                                          ),
                                  onSaveSkillTap: supportBundle == null
                                      ? null
                                      : () => _saveSkillBlueprint(
                                            supportBundle,
                                          ),
                                  onLabelSelected: _selectLabel,
                                ),
                              ),
                      ),
                    ),
                    Positioned(
                      left: 0,
                      right: 0,
                      bottom: composerInset + 8,
                      child: Align(
                        alignment: Alignment.center,
                        child: IgnorePointer(
                          ignoring: !showJumpButton,
                          child: AnimatedSlide(
                            duration: motionDuration,
                            offset: showJumpButton
                                ? Offset.zero
                                : const Offset(0, 0.3),
                            child: AnimatedOpacity(
                              duration: motionDuration,
                              opacity: showJumpButton ? 1 : 0,
                              child: _JumpToLatestButton(
                                onTap: _scrollToBottom,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      left: 0,
                      right: 0,
                      bottom: bottomInset,
                      child: BottomChatField(
                        chatProvider: chatProvider,
                        textController: _composerController,
                        onDraftChanged: _handleDraftChanged,
                        onMessageSent: _handleMessageSent,
                        selectedLabel: _selectedLabel,
                        recommendedSkillId: _selectedRecommendation?.skillId,
                        templateId: _selectedRecommendation?.templateId,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _JumpToLatestButton extends StatelessWidget {
  const _JumpToLatestButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return IconButton.filledTonal(
      onPressed: onTap,
      style: IconButton.styleFrom(
        backgroundColor: isDark
            ? colorScheme.primaryContainer.withValues(alpha: 0.9)
            : colorScheme.surfaceContainerLow.withValues(alpha: 0.92),
        foregroundColor:
            isDark ? colorScheme.onPrimaryContainer : colorScheme.onSurface,
      ),
      tooltip: 'Jump to latest',
      icon: const Icon(CupertinoIcons.arrow_down),
    );
  }
}
