import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/chat_message.dart';
import '../models/citation.dart';
import '../models/message_role.dart';

class OpenRouterService {
  static const String _baseUrl =
      'https://muslimgpt-production.up.railway.app/api/chat';

  Future<ChatMessage> sendMessage({
    required List<ChatMessage> conversationHistory,
    required String userMessage,
  }) async {
    final messages = <Map<String, String>>[
      ...conversationHistory
          .where((m) => !m.isLoading && m.role != MessageRole.system)
          .map((m) => {
                'role': m.role == MessageRole.user ? 'user' : 'assistant',
                'content': m.role == MessageRole.assistant
                    ? _rebuildAssistantContent(m)
                    : m.content,
              }),
      {'role': 'user', 'content': userMessage},
    ];

    final response = await http.post(
      Uri.parse(_baseUrl),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'messages': messages}),
    );

    if (response.statusCode != 200) {
      final error = jsonDecode(response.body) as Map<String, dynamic>;
      throw Exception(error['error'] ?? 'Server error (${response.statusCode})');
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    return _parseResponse(data);
  }

  String _rebuildAssistantContent(ChatMessage message) {
    if (message.citations.isEmpty) return message.content;
    return jsonEncode({
      'content': message.content,
      'citations': message.citations
          .map((c) => {'source': c.source, 'arabicText': c.arabicText})
          .toList(),
    });
  }

  ChatMessage _parseResponse(Map<String, dynamic> data) {
    final content = data['content'] as String? ?? '';
    final citationsData = data['citations'] as List<dynamic>? ?? [];

    final citations = citationsData.map((c) {
      final map = c as Map<String, dynamic>;
      return Citation(
        source: map['source'] as String? ?? '',
        arabicText: map['arabicText'] as String? ?? '',
        translation: map['translation'] as String? ?? '',
        explanation: map['explanation'] as String? ?? '',
        reference: map['reference'] as String? ?? '',
      );
    }).toList();

    return ChatMessage(
      id: 'ai-${DateTime.now().millisecondsSinceEpoch}',
      role: MessageRole.assistant,
      content: content,
      citations: citations,
      timestamp: DateTime.now(),
    );
  }
}
