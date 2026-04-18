import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/cupertino.dart';
import 'package:chatbotapp/hive/agent_audit_log_entry.dart';
import 'package:chatbotapp/models/message.dart';
import 'package:chatbotapp/services/agent_audit_log_service.dart';
import 'package:chatbotapp/services/assistant_feedback_service.dart';
import 'package:chatbotapp/utilities/app_snackbar.dart';
import 'package:chatbotapp/widgets/chat/assistant_response_content.dart';

class AssistantMessageWidget extends StatefulWidget {
  const AssistantMessageWidget({
    super.key,
    required this.message,
  });

  final Message message;

  @override
  State<AssistantMessageWidget> createState() => _AssistantMessageWidgetState();
}

class _AssistantMessageWidgetState extends State<AssistantMessageWidget> {
  static const AssistantFeedbackService _feedbackService =
      AssistantFeedbackService();
  static const AgentAuditLogService _auditLogService = AgentAuditLogService();
  String? _selectedFeedback;
  AgentAuditLogEntry? _auditLog;

  @override
  void initState() {
    super.initState();
    _loadFeedback();
  }

  @override
  void didUpdateWidget(covariant AssistantMessageWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.message.messageId != widget.message.messageId ||
        oldWidget.message.chatId != widget.message.chatId) {
      _loadFeedback();
    }
  }

  void _loadFeedback() {
    _selectedFeedback =
        _feedbackService.loadForMessage(widget.message)?.feedbackType;
    _auditLog = _auditLogService.loadForMessage(widget.message);
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final text = widget.message.message.toString();
    final traceText = _extractOrbitTrace(text);
    final visibleText = _withoutOrbitTrace(text);
    final hasCodeBlocks = AssistantResponseContent.containsCodeBlocks(
      visibleText,
    );

    return Align(
      alignment: Alignment.centerLeft,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.94,
        ),
        child: Container(
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainerLow.withValues(alpha: 0.82),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: colorScheme.outlineVariant.withValues(alpha: 0.5),
            ),
          ),
          padding: const EdgeInsets.fromLTRB(16, 14, 12, 14),
          margin: const EdgeInsets.only(bottom: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 26,
                    height: 26,
                    decoration: BoxDecoration(
                      color: colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(9),
                    ),
                    child: Icon(
                      CupertinoIcons.sparkles,
                      size: 13,
                      color: colorScheme.onPrimaryContainer,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'AI',
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                  const Spacer(),
                  if (visibleText.isNotEmpty && !hasCodeBlocks)
                    IconButton(
                      tooltip: 'Copy',
                      visualDensity: VisualDensity.compact,
                      onPressed: () async {
                        await Clipboard.setData(
                          ClipboardData(text: visibleText),
                        );
                        if (context.mounted) {
                          showAppSnackBar(context, 'Copied', bottomOffset: 132);
                        }
                      },
                      icon: const Icon(CupertinoIcons.doc_on_doc, size: 18),
                    ),
                ],
              ),
              const SizedBox(height: 10),
              if (visibleText.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 4),
                  child: CupertinoActivityIndicator(),
                )
              else ...[
                AssistantResponseContent(text: visibleText),
                if (traceText != null) ...[
                  const SizedBox(height: 12),
                  _AgentTracePill(traceText: traceText),
                ],
                if (_auditLog != null) ...[
                  const SizedBox(height: 12),
                  _AgentAuditPanel(auditLog: _auditLog!),
                ],
                const SizedBox(height: 12),
                _FeedbackBar(
                  selectedFeedback: _selectedFeedback,
                  onSelected: (feedbackType) => _recordFeedback(
                    context: context,
                    feedbackType: feedbackType,
                    visibleText: visibleText,
                    agentTrace: traceText ?? '',
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  String? _extractOrbitTrace(String text) {
    final lines = text.split('\n');
    for (final line in lines.reversed) {
      final trimmed = line.trim();
      if (trimmed.startsWith('ORBIT trace:')) {
        return trimmed.substring('ORBIT trace:'.length).trim();
      }
    }
    return null;
  }

  String _withoutOrbitTrace(String text) {
    final lines = text.split('\n');
    while (lines.isNotEmpty &&
        (lines.last.trim().isEmpty ||
            lines.last.trim().startsWith('ORBIT trace:'))) {
      lines.removeLast();
    }
    return lines.join('\n').trimRight();
  }

  Future<void> _recordFeedback({
    required BuildContext context,
    required String feedbackType,
    required String visibleText,
    required String agentTrace,
  }) async {
    await _feedbackService.recordFeedback(
      message: widget.message,
      feedbackType: feedbackType,
      visibleText: visibleText,
      agentTrace: agentTrace,
    );
    if (!mounted || !context.mounted) {
      return;
    }
    setState(() {
      _selectedFeedback = feedbackType;
    });
    showAppSnackBar(context, 'Feedback saved', bottomOffset: 132);
  }
}

class _FeedbackBar extends StatelessWidget {
  const _FeedbackBar({
    required this.selectedFeedback,
    required this.onSelected,
  });

  static const _options = [
    _FeedbackOption(id: 'helpful', label: 'Helpful'),
    _FeedbackOption(id: 'not_helpful', label: 'Not helpful'),
    _FeedbackOption(id: 'wrong_context', label: 'Wrong context'),
    _FeedbackOption(id: 'too_much', label: 'Too much'),
  ];

  final String? selectedFeedback;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Was this useful?',
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _options
              .map(
                (option) => ChoiceChip(
                  label: Text(option.label),
                  selected: selectedFeedback == option.id,
                  onSelected: (_) => onSelected(option.id),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              )
              .toList(growable: false),
        ),
      ],
    );
  }
}

class _FeedbackOption {
  const _FeedbackOption({
    required this.id,
    required this.label,
  });

  final String id;
  final String label;
}

class _AgentTracePill extends StatelessWidget {
  const _AgentTracePill({required this.traceText});

  final String traceText;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: colorScheme.primaryContainer.withValues(alpha: 0.45),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: colorScheme.primary.withValues(alpha: 0.18),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            CupertinoIcons.chart_bar_alt_fill,
            size: 16,
            color: colorScheme.onPrimaryContainer,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Agent trace: $traceText',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: colorScheme.onPrimaryContainer,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AgentAuditPanel extends StatelessWidget {
  const _AgentAuditPanel({required this.auditLog});

  final AgentAuditLogEntry auditLog;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final modelStatus =
        auditLog.usedLocalModel ? 'Local model' : 'Deterministic fallback';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.62),
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
              Icon(
                CupertinoIcons.doc_text_search,
                size: 16,
                color: colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Agent audit',
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                        fontWeight: FontWeight.w700,
                      ),
                ),
              ),
              Text(
                '${auditLog.latencyMs} ms',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          _AuditLine(
              label: 'Mode', value: '$modelStatus: ${auditLog.modelName}'),
          _AuditLine(
            label: 'Roles',
            value: _shortList(auditLog.activatedRoles),
          ),
          _AuditLine(
            label: 'Tools',
            value: auditLog.toolNames.isEmpty
                ? 'No tool priority'
                : _shortList(auditLog.toolNames),
          ),
          _AuditLine(
            label: 'Sources',
            value: auditLog.dataSources.isEmpty
                ? 'Local labels/history'
                : _shortList(auditLog.dataSources),
          ),
          if (auditLog.fallbackReason.isNotEmpty)
            _AuditLine(label: 'Fallback', value: auditLog.fallbackReason),
        ],
      ),
    );
  }

  String _shortList(List<String> values) {
    if (values.isEmpty) {
      return 'None';
    }
    if (values.length <= 4) {
      return values.join(', ');
    }
    return '${values.take(4).join(', ')} +${values.length - 4}';
  }
}

class _AuditLine extends StatelessWidget {
  const _AuditLine({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: RichText(
        text: TextSpan(
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
          children: [
            TextSpan(
              text: '$label: ',
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
            TextSpan(text: value),
          ],
        ),
      ),
    );
  }
}
