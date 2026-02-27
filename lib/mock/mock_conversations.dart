import '../models/conversation.dart';

final List<Conversation> mockConversations = [
  Conversation(
    id: '1',
    title: 'Ayat al-Kursi Explanation',
    lastMessagePreview: 'Ayat al-Kursi is one of the most powerful verses...',
    updatedAt: DateTime.now().subtract(const Duration(hours: 2)),
    messageCount: 4,
  ),
  Conversation(
    id: '2',
    title: 'Hadith on Kindness',
    lastMessagePreview:
        'The Prophet (PBUH) said: "Allah is kind and loves kindness..."',
    updatedAt: DateTime.now().subtract(const Duration(days: 1)),
    messageCount: 6,
  ),
  Conversation(
    id: '3',
    title: 'Five Pillars of Islam',
    lastMessagePreview:
        'The five pillars are the foundation of Muslim life...',
    updatedAt: DateTime.now().subtract(const Duration(days: 3)),
    messageCount: 8,
  ),
];
