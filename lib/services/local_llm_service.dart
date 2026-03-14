import 'dart:async';
import 'dart:convert';

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

    final result = await fllama.initContext(modelPath);
    _contextId = (result?['contextId'] as num?)?.toDouble();
    if (_contextId == null) {
      throw Exception('Failed to initialize model context');
    }
  }

  Future<ChatMessage> generate({
    required String userMessage,
    required List<RetrievalResult> context,
  }) async {
    if (_contextId == null) {
      throw StateError('Model not loaded. Call load() first.');
    }

    final prompt = _buildPrompt(userMessage, context);
    final rawResponse = await _runInference(prompt);
    return _parseResponse(rawResponse);
  }

  String _buildPrompt(String question, List<RetrievalResult> context) {
    final buffer = StringBuffer();

    buffer.writeln('You are an Islamic knowledge assistant. '
        'Answer ONLY questions about Islam using the provided sources.');
    buffer.writeln();
    buffer.writeln('RULES:');
    buffer.writeln('1. Answer using ONLY the provided sources below.');
    buffer.writeln('2. Include the original Arabic text for Quran verses and Hadith.');
    buffer.writeln('3. If the sources do not answer the question, say so.');
    buffer.writeln('4. Respond in valid JSON format.');
    buffer.writeln();

    if (context.isNotEmpty) {
      buffer.writeln('PROVIDED SOURCES:');
      for (var i = 0; i < context.length; i++) {
        final chunk = context[i].chunk;
        buffer.writeln('[${i + 1}] ${chunk.reference} (${chunk.sourceName})');
        if (chunk.arabicText.isNotEmpty) {
          buffer.writeln('    Arabic: ${chunk.arabicText}');
        }
        if (chunk.translation.isNotEmpty) {
          buffer.writeln('    Translation: ${chunk.translation}');
        }
        buffer.writeln();
      }
    }

    buffer.writeln('USER QUESTION: $question');
    buffer.writeln();
    buffer.writeln('Respond in this JSON format:');
    buffer.writeln('{"content": "Your answer", "citations": ['
        '{"source": "Quran 2:255", "arabicText": "...", '
        '"translation": "...", "explanation": "...", "reference": "..."}]}');

    return buffer.toString();
  }

  Future<String> _runInference(String prompt) async {
    final fllama = Fllama.instance()!;
    final completer = Completer<String>();
    final responseBuffer = StringBuffer();

    final subscription = fllama.onTokenStream?.listen((data) {
      if (data['function'] == 'completion') {
        final result = data['result'];
        if (result != null && result['token'] != null) {
          responseBuffer.write(result['token']);
        }
      }
    });

    // Start completion and wait for it to finish
    await fllama.completion(_contextId!, prompt: prompt, emitRealtimeCompletion: true);

    // Give a brief moment for final tokens to arrive
    await Future<void>.delayed(const Duration(milliseconds: 100));

    await subscription?.cancel();

    final response = responseBuffer.toString();
    if (response.isEmpty) {
      completer.complete('{"content": "I could not generate a response.", "citations": []}');
    } else if (!completer.isCompleted) {
      completer.complete(response);
    }

    return completer.future;
  }

  ChatMessage _parseResponse(String raw) {
    String content;
    List<Citation> citations;

    try {
      // Extract JSON from response (model may include extra text)
      final jsonMatch = RegExp(r'\{[\s\S]*\}').firstMatch(raw);
      if (jsonMatch != null) {
        final data = jsonDecode(jsonMatch.group(0)!) as Map<String, dynamic>;
        content = data['content'] as String? ?? raw;
        final citationsData = data['citations'] as List<dynamic>? ?? [];
        citations = citationsData.map((c) {
          final map = c as Map<String, dynamic>;
          return Citation(
            source: map['source'] as String? ?? '',
            arabicText: map['arabicText'] as String? ?? '',
            translation: map['translation'] as String? ?? '',
            explanation: map['explanation'] as String? ?? '',
            reference: map['reference'] as String? ?? '',
          );
        }).toList();
      } else {
        content = raw;
        citations = [];
      }
    } catch (_) {
      content = raw;
      citations = [];
    }

    return ChatMessage(
      id: 'local-${DateTime.now().millisecondsSinceEpoch}',
      role: MessageRole.assistant,
      content: content,
      citations: citations,
      timestamp: DateTime.now(),
    );
  }

  Future<void> dispose() async {
    if (_contextId != null) {
      Fllama.instance()?.releaseContext(_contextId!);
      _contextId = null;
    }
  }
}
