import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../../models/chat_message.dart';
import '../../../models/conversation.dart';
import '../../../models/message_role.dart';
import '../../../models/retrieval_result.dart';
import '../../../services/corpus_loader_service.dart';
import '../../../services/db_service.dart';
import '../../../services/embedding_service.dart';
import '../../../services/local_llm_service.dart';
import '../../../services/model_extractor_service.dart';
import '../../../services/rag_answer_service.dart';
import 'conversations_provider.dart';

const _uuid = Uuid();
const _localLlmTimeout = Duration(seconds: 20);

final chatMessagesProvider =
    NotifierProvider<ChatNotifier, List<ChatMessage>>(ChatNotifier.new);

class ChatNotifier extends Notifier<List<ChatMessage>> {
  String? _conversationId;
  final RagAnswerService _ragAnswerService = const RagAnswerService();

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
      // Load corpus and embeddings on first use
      await CorpusLoaderService.instance.load();
      await EmbeddingService.instance.load();

      // Retrieve top-5 relevant chunks from local corpus
      final retrievalResults = EmbeddingService.instance.retrieve(content, topK: 5);

      final response = await _buildAssistantResponse(
        userMessage: content,
        retrievalResults: retrievalResults,
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

  Future<ChatMessage> _buildAssistantResponse({
    required String userMessage,
    required List<RetrievalResult> retrievalResults,
  }) async {
    try {
      if (!LocalLlmService.instance.isLoaded) {
        final modelPath = await ModelExtractorService.modelPath;
        await LocalLlmService.instance.load(modelPath);
      }

      return await LocalLlmService.instance
          .generate(
            userMessage: userMessage,
            context: retrievalResults,
          )
          .timeout(_localLlmTimeout);
    } catch (error) {
      return _ragAnswerService.buildResponse(
        userMessage: userMessage,
        retrievalResults: retrievalResults,
        fallbackReason: 'The on-device model is unavailable right now, so this answer is based directly on local sources.',
      );
    }
  }
}
