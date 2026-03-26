import 'package:fllama/fllama.dart';
import '../models/chat_message.dart';
import '../models/citation.dart';
import '../models/message_role.dart';
import '../models/retrieval_result.dart';

class LocalLlmService {
  static LocalLlmService? _instance;
  static LocalLlmService get instance => _instance ??= LocalLlmService._();
  LocalLlmService._();

  double? _contextId;
  bool get isLoaded => _contextId != null;

  Future<void> load(String modelPath) async {
    if (_contextId != null) return;

    final fllama = Fllama.instance();
    if (fllama == null) {
      throw Exception('fllama not available on this platform');
    }

    print('LLM: Calling initContext...');
    final result = await fllama.initContext(modelPath, nCtx: 4096);
    _contextId = (result?['contextId'] as num?)?.toDouble();
    if (_contextId == null) {
      throw Exception('Failed to initialize model context');
    }
    print('LLM: initContext done, contextId=$_contextId');
  }

  Future<ChatMessage> generate({
    required String userMessage,
    required List<RetrievalResult> context,
  }) async {
    if (_contextId == null) {
      throw StateError('Model not loaded. Call load() first.');
    }

    final prompt = _buildPrompt(userMessage, context);
    print('LLM: Prompt length: ${prompt.length} chars');
    final rawResponse = await _runInference(prompt);
    print('LLM: Raw response length: ${rawResponse.length} chars');

    // Build citations from retrieval results (not from LLM output)
    final citations = context.map((r) => Citation(
      source: r.chunk.sourceName,
      arabicText: r.chunk.arabicText,
      translation: r.chunk.translation,
      explanation: r.chunk.explanation,
      reference: r.chunk.reference,
    )).toList();

    return _parseResponse(rawResponse, citations);
  }

  String _buildPrompt(String question, List<RetrievalResult> context) {
    final buffer = StringBuffer();

    buffer.writeln('Based on these Islamic sources, write a brief answer.');
    buffer.writeln();

    if (context.isNotEmpty) {
      buffer.writeln('Sources:');
      for (var i = 0; i < context.length; i++) {
        final chunk = context[i].chunk;
        final translation = chunk.translation.length > 200
            ? '${chunk.translation.substring(0, 200)}...'
            : chunk.translation;
        buffer.writeln('- ${chunk.reference}: $translation');
      }
      buffer.writeln();
    }

    buffer.writeln('Q: $question');
    buffer.write('A: According to the sources, ');

    return buffer.toString();
  }

  Future<String> _runInference(String prompt) async {
    final fllama = Fllama.instance()!;

    final stopwatch = Stopwatch()..start();
    print('LLM: Calling completion...');
    final result = await fllama.completion(
      _contextId!,
      prompt: prompt,
      emitRealtimeCompletion: false,
      nPredict: 200,
      temperature: 0.2,
      topP: 0.95,
      topK: 40,
      penaltyRepeat: 1.1,
    );
    stopwatch.stop();

    print('LLM: completion took ${stopwatch.elapsedMilliseconds}ms');
    print('LLM: completion returned: $result');
    print('LLM: result keys: ${result?.keys.toList()}');

    if (result == null) {
      return '';
    }

    // Try all possible key names for the generated text
    final text = result['text'] as String? ??
        result['content'] as String? ??
        result['result'] as String? ??
        result['token'] as String? ??
        '';

    print('LLM: Extracted text length: ${text.length}');
    if (text.isNotEmpty) {
      print('LLM: First 200 chars: ${text.substring(0, text.length > 200 ? 200 : text.length)}');
    }

    if (text.isEmpty) {
      return '';
    }

    return text;
  }

  ChatMessage _parseResponse(String raw, List<Citation> citations) {
    final content = _sanitizeResponse(raw);
    if (!_looksUsable(content)) {
      throw StateError('Model returned malformed output');
    }

    return ChatMessage(
      id: 'local-${DateTime.now().millisecondsSinceEpoch}',
      role: MessageRole.assistant,
      content: content,
      citations: citations,
      timestamp: DateTime.now(),
    );
  }

  String _sanitizeResponse(String raw) {
    var text = raw.trim();
    if (text.isEmpty) return '';

    // Remove special tokens
    text = text.replaceAll('<|endoftext|>', '');
    text = text.replaceAll('<|im_end|>', '');

    // Strip any echoed prompt fragments
    final answerIndex = text.lastIndexOf('A:');
    if (answerIndex >= 0 && answerIndex < 20) {
      text = text.substring(answerIndex + 2);
    }

    // Remove source reference lines the model may echo
    final cleanedLines = text
        .split('\n')
        .map((line) => line.trim())
        .where((line) {
          if (line.isEmpty) return false;
          if (line.startsWith('Sources:')) return false;
          if (line.startsWith('Q:')) return false;
          if (RegExp(r'^- \w+[\s:]').hasMatch(line) && line.contains(':')) return false;
          return true;
        })
        .toList();

    var result = cleanedLines.join('\n').trim();

    // Prepend the completion prefix for a natural reading experience
    if (result.isNotEmpty && !result.startsWith('According')) {
      result = 'According to the sources, $result';
    }

    return result;
  }

  bool _looksUsable(String text) {
    if (text.isEmpty) return false;
    if (text.contains('Question:') || text.contains('SOURCES:')) return false;
    if (RegExp(r'^\[\d+\]', multiLine: true).hasMatch(text)) return false;

    final words = text.split(RegExp(r'\s+')).where((word) => word.isNotEmpty);
    return words.length >= 6;
  }

  Future<void> dispose() async {
    if (_contextId != null) {
      Fllama.instance()?.releaseContext(_contextId!);
      _contextId = null;
    }
  }
}
