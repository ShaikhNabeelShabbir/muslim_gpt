import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import '../models/chat_message.dart';
import '../models/citation.dart';
import '../models/message_role.dart';

class OpenRouterService {
  static const String _baseUrl =
      'https://openrouter.ai/api/v1/chat/completions';
  static const String _model = 'moonshotai/kimi-k2.5';

  static const String _systemPrompt = '''
You are an Islamic knowledge assistant. Your ONLY purpose is to answer questions about Islam, including the Quran, Hadith, Fiqh (Islamic jurisprudence), Seerah (prophetic biography), Islamic history, and Islamic ethics.

STRICT RULES:
1. ONLY answer questions related to Islam. If a question is not related to Islam, respond EXACTLY with: "I'm sorry, I can only help with Islamic questions related to Quran, Hadith, Fiqh, and Islamic knowledge. Please ask an Islam-related question."
2. ALWAYS provide proper citations from authentic sources.
3. ALWAYS include the original Arabic text for Quran verses and Hadith narrations.
4. When the user describes a personal scenario, apply the Islamic ruling/wisdom specifically to their situation.

RESPONSE FORMAT:
You must respond in valid JSON format with the following structure:
{
  "content": "Your main explanation text here. Be thorough but concise.",
  "citations": [
    {
      "source": "Source name (e.g., 'Quran 2:255' or 'Sahih al-Bukhari 5010')",
      "arabicText": "The original Arabic text of the verse or hadith",
      "translation": "English translation of the Arabic text",
      "explanation": "Brief scholarly explanation of this specific citation and how it applies",
      "reference": "Full reference (e.g., 'Surah Al-Baqarah, Verse 255' or 'Sahih al-Bukhari, Book of Virtues of the Quran, Hadith 5010')"
    }
  ]
}

CITATION GUIDELINES:
- For Quran: cite as "Quran [Surah number]:[Ayah number]" (e.g., "Quran 2:255")
- For Hadith: cite the collection name and hadith number (e.g., "Sahih al-Bukhari 5010", "Sahih Muslim 810")
- Include the narrator chain when relevant (e.g., "Narrated by Abu Hurairah")
- Prioritize authentic (sahih) sources: Bukhari, Muslim, Abu Dawud, Tirmidhi, Nasa'i, Ibn Majah
- If multiple scholarly opinions exist, present them fairly and mention the madhab (school of thought)

IMPORTANT: Always respond in valid JSON. Do not include any text outside the JSON structure.
''';

  String get _apiKey {
    final key = dotenv.env['OPENROUTER_API_KEY'] ?? '';
    if (key.isEmpty || key == 'your_openrouter_api_key_here') {
      throw Exception('OpenRouter API key not configured in .env file');
    }
    return key;
  }

  Future<ChatMessage> sendMessage({
    required List<ChatMessage> conversationHistory,
    required String userMessage,
  }) async {
    final messages = <Map<String, String>>[
      {'role': 'system', 'content': _systemPrompt},
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
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $_apiKey',
      },
      body: jsonEncode({
        'model': _model,
        'messages': messages,
        'reasoning': {'enabled': true},
      }),
    );

    if (response.statusCode != 200) {
      throw Exception(
        'OpenRouter API error (${response.statusCode}): ${response.body}',
      );
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final choices = data['choices'] as List<dynamic>;
    if (choices.isEmpty) {
      throw Exception('No response from OpenRouter');
    }

    final rawContent =
        choices[0]['message']['content'] as String;

    return _parseResponse(rawContent);
  }

  String _rebuildAssistantContent(ChatMessage message) {
    // For conversation history, send back a simplified version
    if (message.citations.isEmpty) return message.content;
    return jsonEncode({
      'content': message.content,
      'citations': message.citations
          .map((c) => {'source': c.source, 'arabicText': c.arabicText})
          .toList(),
    });
  }

  ChatMessage _parseResponse(String rawContent) {
    try {
      // Try to extract JSON from the response
      final jsonStr = _extractJson(rawContent);
      final parsed = jsonDecode(jsonStr) as Map<String, dynamic>;

      final content = parsed['content'] as String? ?? rawContent;
      final citationsData = parsed['citations'] as List<dynamic>? ?? [];

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
    } catch (_) {
      // If JSON parsing fails, return the raw text as content
      return ChatMessage(
        id: 'ai-${DateTime.now().millisecondsSinceEpoch}',
        role: MessageRole.assistant,
        content: rawContent,
        timestamp: DateTime.now(),
      );
    }
  }

  String _extractJson(String text) {
    // Try to find JSON in the response (model might add markdown fences)
    final jsonMatch = RegExp(r'\{[\s\S]*\}').firstMatch(text);
    if (jsonMatch != null) {
      return jsonMatch.group(0)!;
    }
    return text;
  }
}
