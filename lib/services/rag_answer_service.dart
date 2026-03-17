import '../models/chat_message.dart';
import '../models/citation.dart';
import '../models/message_role.dart';
import '../models/retrieval_result.dart';

class RagAnswerService {
  const RagAnswerService();

  ChatMessage buildResponse({
    required String userMessage,
    required List<RetrievalResult> retrievalResults,
    String? fallbackReason,
  }) {
    final citations = retrievalResults
        .map(
          (result) => Citation(
            source: result.chunk.sourceName,
            arabicText: result.chunk.arabicText,
            translation: result.chunk.translation,
            explanation: result.chunk.explanation,
            reference: result.chunk.reference,
          ),
        )
        .toList(growable: false);

    final content = _buildContent(
      userMessage: userMessage,
      retrievalResults: retrievalResults,
      fallbackReason: fallbackReason,
    );

    return ChatMessage(
      id: 'rag-${DateTime.now().millisecondsSinceEpoch}',
      role: MessageRole.assistant,
      content: content,
      citations: citations,
      timestamp: DateTime.now(),
    );
  }

  String _buildContent({
    required String userMessage,
    required List<RetrievalResult> retrievalResults,
    String? fallbackReason,
  }) {
    if (retrievalResults.isEmpty) {
      return 'I could not find a grounded local reference for "$userMessage". '
          'Please try rephrasing the question or asking about a Quran verse, hadith, or Islamic topic.';
    }

    final top = retrievalResults.first.chunk;
    final lines = <String>[
      if (fallbackReason != null && fallbackReason.isNotEmpty)
        'Local retrieval response: $fallbackReason',
      'I found relevant local references for your question.',
      '',
      'Top source: ${top.sourceName} (${top.reference})',
      if (top.translation.isNotEmpty) top.translation,
      if (top.translation.isEmpty && top.arabicText.isNotEmpty) top.arabicText,
    ];

    if (retrievalResults.length > 1) {
      lines.add('');
      lines.add('See the attached citations for additional related sources.');
    }

    return lines.join('\n');
  }
}
