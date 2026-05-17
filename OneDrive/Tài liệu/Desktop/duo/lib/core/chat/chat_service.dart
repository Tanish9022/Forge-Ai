import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:web_socket_channel/web_socket_channel.dart';

import '../api/api_client.dart';
import '../auth/auth_storage.dart';
import '../config/api_config.dart';
import '../crypto/crypto_service.dart';
import 'chat_models.dart';
import 'chat_cache_service.dart';

final chatCacheServiceProvider = Provider<ChatCacheService>((ref) {
  return ChatCacheService();
});

final chatServiceProvider = Provider<ChatService>((ref) {
  final service = ChatService(
    ref.watch(apiClientProvider),
    ref.watch(cryptoServiceProvider),
    ref.watch(authStorageProvider),
    ref.watch(chatCacheServiceProvider),
  );
  
  ref.onDispose(() {
    service.dispose();
  });
  
  return service;
});

class ChatService {
  ChatService(this._dio, this._crypto, this._storage, this._cache);

  final Dio _dio;
  final CryptoService _crypto;
  final AuthStorage _storage;
  final ChatCacheService _cache;

  WebSocketChannel? _channel;
  final _messagesController = StreamController<List<ChatMessage>>.broadcast();
  final _typingController = StreamController<String>.broadcast();
  
  List<ChatMessage> _cachedMessages = [];

  Stream<List<ChatMessage>> get messagesStream => _messagesController.stream;
  Stream<String> get typingStream => _typingController.stream;

  Future<void> connect() async {
    if (_channel != null) return;

    final token = await _storage.getToken();
    if (token == null) return;

    final wsUrl = Uri.parse(ApiConfig.baseUrl).replace(scheme: ApiConfig.baseUrl.startsWith('https') ? 'wss' : 'ws');
    final url = '${wsUrl.toString()}/ws?token=$token';
    
    _channel = WebSocketChannel.connect(Uri.parse(url));

    _channel!.stream.listen(
      (data) {
        try {
          final payload = jsonDecode(data as String) as Map<String, dynamic>;
          _handleWsPayload(payload);
        } catch (e) {
          // ignore parsing errors
        }
      },
      onDone: () {
        _channel = null;
        // Optionally implement reconnection logic here
      },
    );
  }

  void dispose() {
    _channel?.sink.close();
    _channel = null;
    _messagesController.close();
    _typingController.close();
  }

  Future<void> _handleWsPayload(Map<String, dynamic> payload) async {
    final type = payload['type'] as String?;
    
    switch (type) {
      case 'message:new':
        final messageJson = payload['message'] as Map<String, dynamic>;
        final message = await _parseAndDecrypt(messageJson);
        if (message != null) {
          _cachedMessages = [message, ..._cachedMessages];
          _messagesController.add(_cachedMessages);
        }
        break;
      case 'message:status':
        final messageId = payload['messageId'] as String;
        final status = payload['status'] as String;
        _cachedMessages = _cachedMessages.map((m) {
          if (m.id == messageId) {
            return m.copyWith(status: status);
          }
          return m;
        }).toList();
        _messagesController.add(_cachedMessages);
        break;
      case 'message:reactions':
        final messageId = payload['messageId'] as String;
        final reactions = payload['reactions'] as Map<String, dynamic>;
        _cachedMessages = _cachedMessages.map((m) {
          if (m.id == messageId) {
            return m.copyWith(reactions: reactions);
          }
          return m;
        }).toList();
        _messagesController.add(_cachedMessages);
        break;
      case 'message:delete':
        final messageId = payload['messageId'] as String;
        _cachedMessages = _cachedMessages.map((m) {
          if (m.id == messageId) {
            return m.copyWith(isDeleted: true, decryptedContent: 'This message was deleted');
          }
          return m;
        }).toList();
        _messagesController.add(_cachedMessages);
        break;
      case 'typing:start':
        _typingController.add(payload['userId'] as String);
        break;
      case 'typing:stop':
        _typingController.add('');
        break;
    }
  }

  Future<ChatMessage?> _parseAndDecrypt(Map<String, dynamic> json) async {
    try {
      final isDeleted = json['isDeleted'] as bool? ?? false;
      final encryptedContent = json['encryptedContent'] as String;
      final iv = json['iv'] as String;
      
      String decrypted = 'This message was deleted';
      if (!isDeleted) {
        if (iv == 'media') {
          decrypted = encryptedContent;
        } else {
          decrypted = await _crypto.decrypt(encryptedContent, iv);
        }
      }
      
      return ChatMessage(
        id: json['id'] as String,
        coupleId: json['coupleId'] as String,
        type: json['type'] as String,
        senderId: json['senderId'] as String,
        status: json['status'] as String,
        replyTo: json['replyTo'] as String?,
        reactions: json['reactions'] as Map<String, dynamic>? ?? {},
        isDeleted: isDeleted,
        createdAt: DateTime.parse(json['createdAt'] as String).toLocal(),
        decryptedContent: decrypted,
      );
    } catch (e) {
      return null;
    }
  }

  Future<void> loadMessages() async {
    try {
      // First load from cache
      _cachedMessages = _cache.getCachedMessages();
      if (_cachedMessages.isNotEmpty) {
        _messagesController.add(_cachedMessages);
      }

      final response = await _dio.get<Map<String, dynamic>>('/messages');
      final items = response.data!['messages'] as List<dynamic>;
      
      final futures = items.map((item) => _parseAndDecrypt(item as Map<String, dynamic>));
      final results = await Future.wait(futures);
      
      _cachedMessages = results.whereType<ChatMessage>().toList();
      _messagesController.add(_cachedMessages);
      
      // Update cache
      await _cache.cacheMessages(_cachedMessages);
    } catch (e) {
      // Handle error
    }
  }

  Future<void> sendMessage(String text, String senderId, {String? replyTo}) async {
    try {
      final encrypted = await _crypto.encrypt(text);
      
      await _dio.post<Map<String, dynamic>>(
        '/messages',
        data: {
          'encryptedContent': encrypted['encryptedContent'],
          'iv': encrypted['iv'],
          'type': 'text',
          'senderId': senderId,
          'replyTo': ?replyTo,
        },
      );
    } catch (e) {
      // Handle error
    }
  }

  Future<void> sendMediaMessage(File file, String senderId, String mediaType, {String? replyTo}) async {
    try {
      final bytes = await file.readAsBytes();
      final encryptedMap = await _crypto.encryptBytes(bytes);
      final encryptedBase64 = encryptedMap['encryptedContent']!;
      final ivBase64 = encryptedMap['iv']!;

      final fileContent = '$ivBase64:$encryptedBase64';
      
      final tempDir = await getTemporaryDirectory();
      final tempFile = File(p.join(tempDir.path, 'chat_upload.enc'));
      await tempFile.writeAsString(fileContent);

      final formData = FormData.fromMap({
        'file': await MultipartFile.fromFile(tempFile.path, filename: 'chat_$mediaType.enc'),
      });

      final uploadRes = await _dio.post<Map<String, dynamic>>(
        '/media/upload',
        data: formData,
      );

      final storageRef = uploadRes.data!['url'] as String;

      await _dio.post<Map<String, dynamic>>(
        '/messages',
        data: {
          'encryptedContent': storageRef,
          'iv': 'media', // Use 'media' as a placeholder since IV is in the file
          'type': mediaType,
          'senderId': senderId,
          'replyTo': ?replyTo,
        },
      );
      
      if (await tempFile.exists()) {
        await tempFile.delete();
      }
    } catch (e) {
      // Handle error
    }
  }

  Future<File> downloadAndDecryptMedia(String storageRef, {String extension = '.bin'}) async {
    final base = Uri.parse(ApiConfig.baseUrl);
    final origin = '${base.scheme}://${base.authority}';
    final url = storageRef.startsWith('http')
        ? storageRef
        : storageRef.startsWith('/api/')
            ? '$origin$storageRef'
            : '${ApiConfig.baseUrl}$storageRef';

    final response = await _dio.get<String>(url);
    final fileContent = response.data!;
    final parts = fileContent.split(':');
    if (parts.length != 2) throw Exception('Invalid media format');

    final decryptedBytes = await _crypto.decryptBytes(parts[1], parts[0]);
    final tempDir = await getTemporaryDirectory();
    final tempFile = File(
      p.join(tempDir.path, 'chat_media_${DateTime.now().millisecondsSinceEpoch}$extension'),
    );
    await tempFile.writeAsBytes(decryptedBytes);
    return tempFile;
  }

  void sendTypingEvent(bool isTyping) {
    if (_channel != null) {
      _channel!.sink.add(jsonEncode({
        'type': isTyping ? 'typing:start' : 'typing:stop'
      }));
    }
  }

  Future<void> markAsRead(String messageId) async {
    try {
      await _dio.patch<Map<String, dynamic>>(
        '/messages/$messageId/status',
        data: {'status': 'read'},
      );
    } catch (e) {
      // Handle error
    }
  }

  Future<void> toggleReaction(String messageId, String userId, String emoji) async {
    try {
      // Optimistic update
      final index = _cachedMessages.indexWhere((m) => m.id == messageId);
      if (index != -1) {
        final message = _cachedMessages[index];
        final currentReactions = Map<String, dynamic>.from(message.reactions);
        
        if (currentReactions[userId] == emoji) {
          currentReactions.remove(userId);
        } else {
          currentReactions[userId] = emoji;
        }
        
        _cachedMessages[index] = message.copyWith(reactions: currentReactions);
        _messagesController.add(_cachedMessages);

        await _dio.patch<Map<String, dynamic>>(
          '/messages/$messageId/reactions',
          data: {'reactions': currentReactions},
        );
      }
    } catch (e) {
      // Rollback on error could be implemented here
    }
  }

  Future<void> deleteMessage(String messageId) async {
    try {
      await _dio.delete<Map<String, dynamic>>('/messages/$messageId');
    } catch (e) {
      // Handle error
    }
  }
}
