import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../models/conversation.dart';
import '../../../services/db_service.dart';

final conversationsProvider =
    AsyncNotifierProvider<ConversationsNotifier, List<Conversation>>(
  ConversationsNotifier.new,
);

class ConversationsNotifier extends AsyncNotifier<List<Conversation>> {
  @override
  Future<List<Conversation>> build() => DbService.getConversations();

  Future<void> addConversation(Conversation conversation) async {
    await DbService.insertConversation(conversation);
    state = AsyncData(await DbService.getConversations());
  }

  Future<void> deleteConversation(String id) async {
    await DbService.deleteConversation(id);
    state = AsyncData(await DbService.getConversations());
  }

  Future<void> updateConversation(Conversation updated) async {
    await DbService.updateConversation(updated);
    state = AsyncData(await DbService.getConversations());
  }
}
