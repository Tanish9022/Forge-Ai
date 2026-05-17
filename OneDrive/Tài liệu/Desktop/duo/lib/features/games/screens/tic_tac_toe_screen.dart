import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/auth/auth_service.dart';
import '../../../core/games/games_models.dart';
import '../../../core/games/games_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../shared/widgets/app_button.dart';

class TicTacToeScreen extends ConsumerStatefulWidget {
  const TicTacToeScreen({super.key});

  @override
  ConsumerState<TicTacToeScreen> createState() => _TicTacToeScreenState();
}

class _TicTacToeScreenState extends ConsumerState<TicTacToeScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final gamesService = ref.read(gamesServiceProvider);
      gamesService.connect();
      gamesService.loadGameState('tictactoe');
    });
  }

  void _handleTap(int index, GameState? gameState, String userId) {
    if (gameState == null) return;
    
    final state = Map<String, dynamic>.from(gameState.state);
    final board = List<String>.from((state['board'] as List?) ?? List.filled(9, ''));
    final xUser = state['xUser'] as String?;
    final oUser = state['oUser'] as String?;
    
    if (board[index].isNotEmpty) return;
    
    // Auto-assign roles on first moves if empty
    String role = '';
    if (xUser == userId) {
      role = 'X';
    } else if (oUser == userId) {
      role = 'O';
    } else if (xUser == null) {
      state['xUser'] = userId;
      role = 'X';
    } else if (oUser == null) {
      state['oUser'] = userId;
      role = 'O';
    } else {
      return; // Can't play
    }
    
    final assignedXUser = state['xUser'] as String?;
    final assignedOUser = state['oUser'] as String?;
    final currentTurn = gameState.currentTurn ??
        (assignedXUser != null && assignedOUser == null ? userId : assignedXUser);
    if (currentTurn != userId) return; // Not our turn
    
    board[index] = role;
    state['board'] = board;
    
    final nextTurn = role == 'X' ? state['oUser'] : state['xUser'];
    
    ref.read(gamesServiceProvider).updateGameState(
      'tictactoe',
      state,
      currentTurn: nextTurn as String?,
    );
  }

  void _resetGame() {
    ref.read(gamesServiceProvider).updateGameState(
      'tictactoe',
      {'board': List.filled(9, ''), 'xUser': null, 'oUser': null},
      currentTurn: null, // Let the first player be X
    );
  }

  @override
  Widget build(BuildContext context) {
    final gamesService = ref.watch(gamesServiceProvider);
    final user = ref.watch(authStateProvider).value;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Tic Tac Toe'),
      ),
      body: StreamBuilder<GameState?>(
        stream: gamesService.gameStateStream('tictactoe'),
        builder: (context, snapshot) {
          if (!snapshot.hasData || user == null) {
            return const Center(child: CircularProgressIndicator(color: AppColors.rose500));
          }

          final gameState = snapshot.data;
          final state = gameState?.state ?? {};
          final board = List<String>.from((state['board'] as List?) ?? List.filled(9, ''));
          final isMyTurn = (gameState?.currentTurn == null) || (gameState?.currentTurn == user.id);

          return Padding(
            padding: const EdgeInsets.all(AppSpacing.xl),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  isMyTurn ? 'Your Turn' : "Partner's Turn",
                  style: AppTextStyles.h2,
                ),
                const SizedBox(height: AppSpacing.xxl),
                AspectRatio(
                  aspectRatio: 1.0,
                  child: GridView.builder(
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      crossAxisSpacing: 8,
                      mainAxisSpacing: 8,
                    ),
                    itemCount: 9,
                    itemBuilder: (context, index) {
                      final cell = board[index];
                      return GestureDetector(
                        onTap: () => _handleTap(index, gameState, user.id),
                        child: Container(
                          decoration: BoxDecoration(
                            color: AppColors.gray800,
                            borderRadius: BorderRadius.circular(AppRadius.md),
                          ),
                          child: Center(
                            child: Text(
                              cell,
                              style: AppTextStyles.display1.copyWith(
                                color: cell == 'X' ? AppColors.mint500 : AppColors.rose500,
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: AppSpacing.xxl),
                AppButton(
                  label: 'Reset Game',
                  variant: AppButtonVariant.secondary,
                  onPressed: _resetGame,
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
