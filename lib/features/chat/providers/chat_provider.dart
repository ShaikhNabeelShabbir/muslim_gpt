import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../../models/chat_message.dart';
import '../../../models/message_role.dart';
import '../../../mock/mock_messages.dart';
import '../../../services/openrouter_service.dart';

const _uuid = Uuid();
final _openRouter = OpenRouterService();

final chatMessagesProvider =
    NotifierProvider<ChatNotifier, List<ChatMessage>>(ChatNotifier.new);

class ChatNotifier extends Notifier<List<ChatMessage>> {
  @override
  List<ChatMessage> build() => [];

  void loadMessages(String conversationId) {
    state = List.from(mockMessages);
  }

  void sendMessage(String content) async {
    // Add user message
    final userMessage = ChatMessage(
      id: _uuid.v4(),
      role: MessageRole.user,
      content: content,
      timestamp: DateTime.now(),
    );
    state = [...state, userMessage];

    // Add loading indicator
    final loadingMessage = ChatMessage(
      id: 'loading-${_uuid.v4()}',
      role: MessageRole.assistant,
      content: '',
      timestamp: DateTime.now(),
      isLoading: true,
    );
    state = [...state, loadingMessage];

    try {
      // Get the conversation history (excluding the loading message)
      final history = state.where((m) => !m.isLoading).toList();

      final response = await _openRouter.sendMessage(
        conversationHistory: history.sublist(0, history.length - 1),
        userMessage: content,
      );

      // Remove loading and add real response
      state = [
        ...state.where((m) => !m.isLoading),
        response,
      ];
    } catch (e) {
      // Remove loading and add error message
      state = [
        ...state.where((m) => !m.isLoading),
        ChatMessage(
          id: 'error-${_uuid.v4()}',
          role: MessageRole.assistant,
          content: 'Sorry, something went wrong: ${e.toString()}',
          timestamp: DateTime.now(),
        ),
      ];
    }
  }

  void clearMessages() {
    state = [];
  }
}
