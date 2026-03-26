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
  }) {
    if (retrievalResults.isEmpty) {
      return 'I could not find relevant references for "$userMessage". '
          'Try rephrasing, or ask about a specific Quran verse, hadith, or Islamic topic.';
    }

    final topic = _extractTopic(userMessage);
    final lines = <String>[
      'Here is what the Islamic sources say about $topic:',
      '',
    ];

    for (final result in retrievalResults) {
      final chunk = result.chunk;
      final excerpt = chunk.translation.length > 150
          ? '${chunk.translation.substring(0, 150)}...'
          : chunk.translation;
      lines.add('${chunk.reference} (${chunk.sourceName}):');
      lines.add('"$excerpt"');
      lines.add('');
    }

    lines.add('Expand the citations below for the full text including the original Arabic.');

    return lines.join('\n');
  }

  /// Extract a readable topic from the user's question.
  String _extractTopic(String message) {
    var topic = message.trim();

    // Remove question marks and trailing punctuation
    topic = topic.replaceAll(RegExp(r'[?!.]+$'), '').trim();

    // Remove common question prefixes
    final prefixes = [
      'what is', 'what are', 'what does', 'what do',
      'how to', 'how do i', 'how do you', 'how can i',
      'tell me about', 'explain', 'describe',
      'give me', 'show me', 'find me',
      'can you tell me about', 'can you explain',
      'i want to know about',
    ];

    final lower = topic.toLowerCase();
    for (final prefix in prefixes) {
      if (lower.startsWith(prefix)) {
        topic = topic.substring(prefix.length).trim();
        break;
      }
    }

    return topic.isEmpty ? 'this topic' : topic;
  }
}
