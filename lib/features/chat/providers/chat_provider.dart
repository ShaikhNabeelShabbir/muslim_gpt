import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../../models/chat_message.dart';
import '../../../models/conversation.dart';
import '../../../models/message_role.dart';
import '../../../services/db_service.dart';
import '../../../services/openrouter_service.dart';
import 'conversations_provider.dart';

const _uuid = Uuid();
final _openRouter = OpenRouterService();

final chatMessagesProvider =
    NotifierProvider<ChatNotifier, List<ChatMessage>>(ChatNotifier.new);

class ChatNotifier extends Notifier<List<ChatMessage>> {
  String? _conversationId;

  String? get conversationId => _conversationId;

  @override
  List<ChatMessage> build() => [];

  Future<void> loadMessages(String conversationId) async {
    _conversationId = conversationId;
    state = await DbService.getMessages(conversationId);
  }

  Future<void> sendMessage(String content) async {
    final isNew = _conversationId == null;

    if (isNew) {
      _conversationId = _uuid.v4();

      final title = content.length > 40 ? '${content.substring(0, 40)}...' : content;
      await ref.read(conversationsProvider.notifier).addConversation(
            Conversation(
              id: _conversationId!,
              title: title,
              lastMessagePreview: content,
              updatedAt: DateTime.now(),
              messageCount: 0,
            ),
          );
    }

    // Add user message
    final userMessage = ChatMessage(
      id: _uuid.v4(),
      role: MessageRole.user,
      content: content,
      timestamp: DateTime.now(),
    );
    state = [...state, userMessage];
    await DbService.insertMessage(_conversationId!, userMessage);

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
      final history = state.where((m) => !m.isLoading).toList();

      final response = await _openRouter.sendMessage(
        conversationHistory: history.sublist(0, history.length - 1),
        userMessage: content,
      );

      state = [
        ...state.where((m) => !m.isLoading),
        response,
      ];

      await DbService.insertMessage(_conversationId!, response);

      // Update conversation metadata
      final messageCount = state.length;
      final preview = response.content.length > 60
          ? '${response.content.substring(0, 60)}...'
          : response.content;

      await ref.read(conversationsProvider.notifier).updateConversation(
            Conversation(
              id: _conversationId!,
              title: isNew
                  ? (content.length > 40
                      ? '${content.substring(0, 40)}...'
                      : content)
                  : (await DbService.getConversations())
                      .firstWhere((c) => c.id == _conversationId)
                      .title,
              lastMessagePreview: preview,
              updatedAt: DateTime.now(),
              messageCount: messageCount,
            ),
          );
    } catch (e) {
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
    _conversationId = null;
    state = [];
  }
}
