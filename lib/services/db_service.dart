import 'dart:convert';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import '../models/chat_message.dart';
import '../models/citation.dart';
import '../models/conversation.dart';
import '../models/message_role.dart';

class DbService {
  static Database? _db;

  static Future<Database> get database async {
    if (_db != null) return _db!;
    _db = await _initDb();
    return _db!;
  }

  static Future<Database> _initDb() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'muslim_gpt.db');

    return openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE conversations (
            id TEXT PRIMARY KEY,
            title TEXT NOT NULL,
            lastMessagePreview TEXT NOT NULL DEFAULT '',
            updatedAt TEXT NOT NULL,
            messageCount INTEGER NOT NULL DEFAULT 0
          )
        ''');

        await db.execute('''
          CREATE TABLE messages (
            id TEXT PRIMARY KEY,
            conversationId TEXT NOT NULL,
            role TEXT NOT NULL,
            content TEXT NOT NULL,
            citations TEXT NOT NULL DEFAULT '[]',
            timestamp TEXT NOT NULL,
            FOREIGN KEY (conversationId) REFERENCES conversations(id) ON DELETE CASCADE
          )
        ''');
      },
    );
  }

  // --- Conversations ---

  static Future<List<Conversation>> getConversations() async {
    final db = await database;
    final rows = await db.query(
      'conversations',
      orderBy: 'updatedAt DESC',
    );

    return rows.map((row) {
      return Conversation(
        id: row['id'] as String,
        title: row['title'] as String,
        lastMessagePreview: row['lastMessagePreview'] as String,
        updatedAt: DateTime.parse(row['updatedAt'] as String),
        messageCount: row['messageCount'] as int,
      );
    }).toList();
  }

  static Future<void> insertConversation(Conversation c) async {
    final db = await database;
    await db.insert('conversations', {
      'id': c.id,
      'title': c.title,
      'lastMessagePreview': c.lastMessagePreview,
      'updatedAt': c.updatedAt.toIso8601String(),
      'messageCount': c.messageCount,
    });
  }

  static Future<void> updateConversation(Conversation c) async {
    final db = await database;
    await db.update(
      'conversations',
      {
        'title': c.title,
        'lastMessagePreview': c.lastMessagePreview,
        'updatedAt': c.updatedAt.toIso8601String(),
        'messageCount': c.messageCount,
      },
      where: 'id = ?',
      whereArgs: [c.id],
    );
  }

  static Future<void> deleteConversation(String id) async {
    final db = await database;
    await db.delete('messages', where: 'conversationId = ?', whereArgs: [id]);
    await db.delete('conversations', where: 'id = ?', whereArgs: [id]);
  }

  // --- Messages ---

  static Future<List<ChatMessage>> getMessages(String conversationId) async {
    final db = await database;
    final rows = await db.query(
      'messages',
      where: 'conversationId = ?',
      whereArgs: [conversationId],
      orderBy: 'timestamp ASC',
    );

    return rows.map((row) {
      final citationsJson = jsonDecode(row['citations'] as String) as List;
      final citations = citationsJson.map((c) {
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
        id: row['id'] as String,
        role: (row['role'] as String) == 'user'
            ? MessageRole.user
            : MessageRole.assistant,
        content: row['content'] as String,
        citations: citations,
        timestamp: DateTime.parse(row['timestamp'] as String),
      );
    }).toList();
  }

  static Future<void> insertMessage(
    String conversationId,
    ChatMessage message,
  ) async {
    final db = await database;
    final citationsJson = jsonEncode(
      message.citations
          .map((c) => {
                'source': c.source,
                'arabicText': c.arabicText,
                'translation': c.translation,
                'explanation': c.explanation,
                'reference': c.reference,
              })
          .toList(),
    );

    await db.insert('messages', {
      'id': message.id,
      'conversationId': conversationId,
      'role': message.role == MessageRole.user ? 'user' : 'assistant',
      'content': message.content,
      'citations': citationsJson,
      'timestamp': message.timestamp.toIso8601String(),
    });
  }
}
