import 'package:flutter/material.dart';
import '../../../models/chat_message.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_text_styles.dart';
import 'citation_card.dart';

class AssistantMessageBubble extends StatelessWidget {
  final ChatMessage message;

  const AssistantMessageBubble({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.85,
        ),
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.assistantBubble,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(4),
            topRight: Radius.circular(18),
            bottomLeft: Radius.circular(18),
            bottomRight: Radius.circular(18),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              message.content,
              style: AppTextStyles.assistantMessage,
            ),
            if (message.citations.isNotEmpty) ...[
              const SizedBox(height: 8),
              ...message.citations.map(
                (citation) => CitationCard(citation: citation),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
