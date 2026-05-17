import 'dart:convert';
import 'package:hive_flutter/hive_flutter.dart';
import 'chat_models.dart';

class ChatCacheService {
  static const String _boxName = 'chat_messages';

  Future<void> init() async {
    await Hive.initFlutter();
    await Hive.openBox<String>(_boxName);
  }

  Future<void> cacheMessages(List<ChatMessage> messages) async {
    final box = Hive.box<String>(_boxName);
    
    // We only need to cache the last 500 messages
    final messagesToCache = messages.take(500).toList();
    
    final map = <String, String>{};
    for (final m in messagesToCache) {
      final jsonStr = jsonEncode({
        'id': m.id,
        'coupleId': m.coupleId,
        'type': m.type,
        'senderId': m.senderId,
        'status': m.status,
        'replyTo': m.replyTo,
        'reactions': m.reactions,
        'isDeleted': m.isDeleted,
        'createdAt': m.createdAt.toIso8601String(),
        'decryptedContent': m.decryptedContent,
      });
      map[m.id] = jsonStr;
    }
    
    await box.clear(); // Overwrite cache for simplicity
    await box.putAll(map);
  }

  List<ChatMessage> getCachedMessages() {
    if (!Hive.isBoxOpen(_boxName)) return [];
    
    final box = Hive.box<String>(_boxName);
    final messages = <ChatMessage>[];
    
    for (final value in box.values) {
      try {
        final map = jsonDecode(value) as Map<String, dynamic>;
        messages.add(
          ChatMessage(
            id: map['id'] as String,
            coupleId: map['coupleId'] as String,
            type: map['type'] as String,
            senderId: map['senderId'] as String,
            status: map['status'] as String,
            replyTo: map['replyTo'] as String?,
            reactions: map['reactions'] as Map<String, dynamic>? ?? {},
            isDeleted: map['isDeleted'] as bool? ?? false,
            createdAt: DateTime.parse(map['createdAt'] as String),
            decryptedContent: map['decryptedContent'] as String,
          ),
        );
      } catch (e) {
        // ignore parse errors
      }
    }
    
    messages.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return messages;
  }
}
