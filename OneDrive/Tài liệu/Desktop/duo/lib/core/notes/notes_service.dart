import 'dart:async';
import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

import '../api/api_client.dart';
import '../auth/auth_storage.dart';
import '../config/api_config.dart';
import '../crypto/crypto_service.dart';
import 'notes_models.dart';

final notesServiceProvider = Provider<NotesService>((ref) {
  final service = NotesService(
    ref.watch(apiClientProvider),
    ref.watch(cryptoServiceProvider),
    ref.watch(authStorageProvider),
  );
  
  ref.onDispose(() {
    service.dispose();
  });
  
  return service;
});

class NotesService {
  NotesService(this._dio, this._crypto, this._storage);

  final Dio _dio;
  final CryptoService _crypto;
  final AuthStorage _storage;

  WebSocketChannel? _channel;
  final _notesController = StreamController<List<Note>>.broadcast();
  
  List<Note> _cachedNotes = [];
  Stream<List<Note>> get notesStream => _notesController.stream;

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
      },
    );
  }

  void dispose() {
    _channel?.sink.close();
    _channel = null;
    _notesController.close();
  }

  Future<void> _handleWsPayload(Map<String, dynamic> payload) async {
    final type = payload['type'] as String?;
    
    if (type == 'note:new') {
      final noteJson = payload['note'] as Map<String, dynamic>;
      final note = await _decryptNote(Note.fromJson(noteJson));
      _cachedNotes = [note, ..._cachedNotes.where((n) => n.id != note.id)];
      _cachedNotes.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
      _notesController.add(_cachedNotes);
    } else if (type == 'note:update') {
      final noteJson = payload['note'] as Map<String, dynamic>;
      final updatedNote = await _decryptNote(Note.fromJson(noteJson));
      _cachedNotes = _cachedNotes.map((n) => n.id == updatedNote.id ? updatedNote : n).toList();
      _cachedNotes.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
      _notesController.add(_cachedNotes);
    } else if (type == 'note:delete') {
      final noteId = payload['noteId'] as String;
      _cachedNotes = _cachedNotes.where((n) => n.id != noteId).toList();
      _notesController.add(_cachedNotes);
    }
  }

  Future<Note> _decryptNote(Note note) async {
    try {
      final title = await _crypto.decrypt(note.encryptedTitle, note.titleIv);
      final content = await _crypto.decrypt(note.encryptedContent, note.contentIv);
      return note.copyWithDecrypted(title: title, content: content);
    } catch (e) {
      return note;
    }
  }

  Future<void> loadNotes() async {
    try {
      final response = await _dio.get<Map<String, dynamic>>('/notes');
      final items = response.data!['notes'] as List<dynamic>;
      
      final futures = items.map((item) => _decryptNote(Note.fromJson(item as Map<String, dynamic>)));
      final results = await Future.wait(futures);
      
      _cachedNotes = results;
      _notesController.add(_cachedNotes);
    } catch (e) {
      // Handle error
    }
  }

  Future<void> createNote({
    required String title,
    required String content,
    String color = 'rose',
    bool isPinned = false,
  }) async {
    final encTitle = await _crypto.encrypt(title);
    final encContent = await _crypto.encrypt(content);

    final response = await _dio.post<Map<String, dynamic>>(
      '/notes',
      data: {
        'encryptedTitle': encTitle['encryptedContent'],
        'titleIv': encTitle['iv'],
        'encryptedContent': encContent['encryptedContent'],
        'contentIv': encContent['iv'],
        'color': color,
        'isPinned': isPinned,
      },
    );
    final note = await _decryptNote(
      Note.fromJson(response.data!['note'] as Map<String, dynamic>),
    );
    _cachedNotes = [note, ..._cachedNotes.where((n) => n.id != note.id)];
    _cachedNotes.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    _notesController.add(_cachedNotes);
  }

  Future<void> updateNote({
    required String id,
    String? title,
    String? content,
    String? color,
    bool? isPinned,
  }) async {
    final data = <String, dynamic>{};
    
    if (title != null) {
      final enc = await _crypto.encrypt(title);
      data['encryptedTitle'] = enc['encryptedContent'];
      data['titleIv'] = enc['iv'];
    }
    if (content != null) {
      final enc = await _crypto.encrypt(content);
      data['encryptedContent'] = enc['encryptedContent'];
      data['contentIv'] = enc['iv'];
    }
    if (color != null) data['color'] = color;
    if (isPinned != null) data['isPinned'] = isPinned;

    final response = await _dio.patch<Map<String, dynamic>>('/notes/$id', data: data);
    final note = await _decryptNote(
      Note.fromJson(response.data!['note'] as Map<String, dynamic>),
    );
    _cachedNotes = _cachedNotes.map((n) => n.id == note.id ? note : n).toList();
    _cachedNotes.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    _notesController.add(_cachedNotes);
  }

  Future<void> deleteNote(String id) async {
    await _dio.delete<Map<String, dynamic>>('/notes/$id');
    _cachedNotes = _cachedNotes.where((n) => n.id != id).toList();
    _notesController.add(_cachedNotes);
  }
}
