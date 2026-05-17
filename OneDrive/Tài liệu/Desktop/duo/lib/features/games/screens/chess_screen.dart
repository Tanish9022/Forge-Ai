import 'package:flutter/material.dart';
import 'package:flutter_chess_board/flutter_chess_board.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../shared/widgets/app_button.dart';
import '../../../shared/widgets/glass_card.dart';

class ChessScreen extends ConsumerStatefulWidget {
  const ChessScreen({super.key});

  @override
  ConsumerState<ChessScreen> createState() => _ChessScreenState();
}

class _ChessScreenState extends ConsumerState<ChessScreen> {
  final ChessBoardController _controller = ChessBoardController();

  @override
  void initState() {
    super.initState();
    // For MVP, we'll just initialize a local board.
    // Real implementation would sync with GameService/WebSocket.
  }

  void _resetBoard() {
    _controller.resetBoard();
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Chess'),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Column(
            children: [
              GlassCard(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Partner', style: AppTextStyles.h3),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.sm,
                        vertical: AppSpacing.xs,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.gray800,
                        borderRadius: BorderRadius.circular(AppRadius.sm),
                      ),
                      child: Text('00:00', style: AppTextStyles.mono),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.xl),
              Expanded(
                child: Center(
                  child: AspectRatio(
                    aspectRatio: 1.0,
                    child: Container(
                      decoration: BoxDecoration(
                        border: Border.all(color: AppColors.gray700, width: 2),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: ChessBoard(
                        controller: _controller,
                        boardColor: BoardColor.brown,
                        boardOrientation: PlayerColor.white,
                        onMove: () {
                          // Handle move, sync to WebSocket
                          setState(() {});
                        },
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.xl),
              GlassCard(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('You', style: AppTextStyles.h3),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.sm,
                        vertical: AppSpacing.xs,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.gray800,
                        borderRadius: BorderRadius.circular(AppRadius.sm),
                      ),
                      child: Text('00:00', style: AppTextStyles.mono),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.xl),
              AppButton(
                label: 'Reset Game',
                variant: AppButtonVariant.secondary,
                onPressed: _resetBoard,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
