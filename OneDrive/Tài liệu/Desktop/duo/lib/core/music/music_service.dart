import 'dart:async';
import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio/just_audio.dart';
import 'package:youtube_explode_dart/youtube_explode_dart.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

import '../api/api_client.dart';
import '../auth/auth_storage.dart';
import '../config/api_config.dart';
import 'music_models.dart';

final musicServiceProvider = Provider<MusicService>((ref) {
  final service = MusicService(
    ref.watch(apiClientProvider),
    ref.watch(authStorageProvider),
  );
  
  ref.onDispose(() {
    service.dispose();
  });
  
  return service;
});

class MusicService {
  MusicService(this._dio, this._storage) {
    _initPlayer();
  }

  final Dio _dio;
  final AuthStorage _storage;
  
  final AudioPlayer _player = AudioPlayer();
  final YoutubeExplode _yt = YoutubeExplode();

  WebSocketChannel? _channel;
  
  final _sessionController = StreamController<MusicSession?>.broadcast();
  Stream<MusicSession?> get sessionStream => _sessionController.stream;
  
  MusicSession? _currentSession;
  String? _currentUserId;

  Future<void> _initPlayer() async {
    _player.positionStream.listen((pos) {
      // Sync position to server periodically if we are the ones playing it
    });
  }

  Future<void> connect(String userId) async {
    _currentUserId = userId;
    
    // 1. Fetch initial state
    try {
      final res = await _dio.get<Map<String, dynamic>>('/music');
      _currentSession = MusicSession.fromJson(res.data!['musicSession'] as Map<String, dynamic>);
      _sessionController.add(_currentSession);
      _syncPlayerWithSession();
    } catch (e) {
      // Handle error
    }

    // 2. Connect WebSocket for live updates
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
          if (payload['type'] == 'music:update') {
            _currentSession = MusicSession.fromJson(payload['musicSession'] as Map<String, dynamic>);
            _sessionController.add(_currentSession);
            
            // Only apply remote changes if we didn't make them
            if (_currentSession?.updatedBy != _currentUserId) {
               _syncPlayerWithSession();
            }
          }
        } catch (e) {
          // ignore parsing errors
        }
      },
      onDone: () {
        _channel = null;
      },
    );
  }

  Future<void> _syncPlayerWithSession() async {
    if (_currentSession == null) return;
    
    if (_currentSession!.trackId != null) {
      try {
        final manifest = await _yt.videos.streamsClient.getManifest(_currentSession!.trackId);
        final audioStream = manifest.audioOnly.withHighestBitrate();
        
      await _player.setUrl(audioStream.url.toString());
        
        if (_currentSession!.isPlaying) {
          await _player.seek(Duration(seconds: _currentSession!.position.toInt()));
          _player.play();
        } else {
          await _player.seek(Duration(seconds: _currentSession!.position.toInt()));
          _player.pause();
        }
      } catch (e) {
        // failed to get stream
      }
    }
  }

  Future<List<YouTubeTrack>> searchYouTube(String query) async {
    try {
      final res = await _dio.get<Map<String, dynamic>>(
        '/youtube/search',
        queryParameters: {'q': query},
      );
      final items = res.data!['items'] as List<dynamic>;
      return items.map((e) => YouTubeTrack.fromJson(e as Map<String, dynamic>)).toList();
    } catch (e) {
      return [];
    }
  }

  Future<void> updateSession({
    String? trackId,
    String? trackTitle,
    String? trackArtist,
    bool? isPlaying,
    double? position,
    List<dynamic>? queue,
  }) async {
    try {
      final response = await _dio.patch<Map<String, dynamic>>(
        '/music',
        data: {
          'trackId': trackId,
          'trackTitle': trackTitle,
          'trackArtist': trackArtist,
          'isPlaying': isPlaying,
          'position': position,
          'queue': queue,
        }..removeWhere((key, value) => value == null),
      );

      _currentSession = MusicSession.fromJson(
        response.data!['musicSession'] as Map<String, dynamic>,
      );
      _sessionController.add(_currentSession);

      if (trackId != null || isPlaying != null || position != null) {
        await _syncPlayerWithSession();
      }
    } catch (e) {
      // Handle error
    }
  }

  void dispose() {
    _channel?.sink.close();
    _channel = null;
    _player.dispose();
    _yt.close();
    _sessionController.close();
  }
}
