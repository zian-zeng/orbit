import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/cupertino.dart';
import 'package:chatbotapp/models/message.dart';
import 'package:chatbotapp/utilities/app_snackbar.dart';
import 'package:chatbotapp/widgets/chat/assistant_response_content.dart';

class AssistantMessageWidget extends StatelessWidget {
  const AssistantMessageWidget({
    super.key,
    required this.message,
  });

  final Message message;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final text = message.message.toString();
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
