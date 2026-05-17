import 'dart:async';
import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

import '../api/api_client.dart';
import '../auth/auth_storage.dart';
import '../config/api_config.dart';
import 'games_models.dart';

final gamesServiceProvider = Provider<GamesService>((ref) {
  final service = GamesService(
    ref.watch(apiClientProvider),
    ref.watch(authStorageProvider),
  );
  
  ref.onDispose(() {
    service.dispose();
  });
  
  return service;
});

class GamesService {
  GamesService(this._dio, this._storage);

  final Dio _dio;
  final AuthStorage _storage;

  WebSocketChannel? _channel;
  
  final _gameStateControllers = <String, StreamController<GameState?>>{};
  
  Stream<GameState?> gameStateStream(String game) {
    if (!_gameStateControllers.containsKey(game)) {
      _gameStateControllers[game] = StreamController<GameState?>.broadcast();
    }
    return _gameStateControllers[game]!.stream;
  }

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
          if (payload['type'] == 'game:update') {
            final game = payload['game'] as String;
            final gameState = GameState.fromJson(payload['gameState'] as Map<String, dynamic>);
            
            if (_gameStateControllers.containsKey(game)) {
              _gameStateControllers[game]!.add(gameState);
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

  Future<void> loadGameState(String game) async {
    try {
      final res = await _dio.get<Map<String, dynamic>>('/games/$game');
      final gameState = GameState.fromJson(res.data!['gameState'] as Map<String, dynamic>);
      
      if (!_gameStateControllers.containsKey(game)) {
        _gameStateControllers[game] = StreamController<GameState?>.broadcast();
      }
      _gameStateControllers[game]!.add(gameState);
    } catch (e) {
      // Handle error
    }
  }

  Future<void> updateGameState(String game, Map<String, dynamic> state, {String? currentTurn}) async {
    try {
      await _dio.patch<Map<String, dynamic>>(
        '/games/$game',
        data: {
          'state': state,
          'currentTurn': ?currentTurn,
        },
      );
    } catch (e) {
      // Handle error
    }
  }

  void dispose() {
    _channel?.sink.close();
    _channel = null;
    for (final controller in _gameStateControllers.values) {
      controller.close();
    }
  }
}
