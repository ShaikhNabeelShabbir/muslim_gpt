import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../models/conversation.dart';
import '../../../mock/mock_conversations.dart';

final conversationsProvider =
    NotifierProvider<ConversationsNotifier, List<Conversation>>(
  ConversationsNotifier.new,
);

class ConversationsNotifier extends Notifier<List<Conversation>> {
  @override
  List<Conversation> build() => List.from(mockConversations);

  void addConversation(Conversation conversation) {
    state = [conversation, ...state];
  }

  void deleteConversation(String id) {
    state = state.where((c) => c.id != id).toList();
  }

  void updateConversation(Conversation updated) {
    state = state.map((c) => c.id == updated.id ? updated : c).toList();
  }
}
