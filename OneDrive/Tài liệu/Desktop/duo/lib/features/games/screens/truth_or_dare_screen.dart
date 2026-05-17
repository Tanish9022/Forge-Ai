import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/games/games_models.dart';
import '../../../core/games/games_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../shared/widgets/app_button.dart';
import '../../../shared/widgets/glass_card.dart';

class TruthOrDareScreen extends ConsumerStatefulWidget {
  const TruthOrDareScreen({super.key});

  @override
  ConsumerState<TruthOrDareScreen> createState() => _TruthOrDareScreenState();
}

class _TruthOrDareScreenState extends ConsumerState<TruthOrDareScreen> {
  final _answerController = TextEditingController();

  static const _truths = [
    "What's a secret you've never told me?",
    "What was your first impression of me?",
    "What's your biggest fear about our future?",
  ];

  static const _dares = [
    "Send a 10s voice note singing your favorite song.",
    "Let me pick your outfit for our next date.",
    "Do 10 pushups right now on camera.",
  ];

  @override
  void dispose() {
    _answerController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final gamesService = ref.read(gamesServiceProvider);
      gamesService.connect();
      gamesService.loadGameState('truth_or_dare');
    });
  }

  void _pickOption(String type) {
    final list = type == 'Truth' ? _truths : _dares;
    final randomItem = list[Random().nextInt(list.length)];
    
    ref.read(gamesServiceProvider).updateGameState(
      'truth_or_dare',
      {
        'currentCard': randomItem,
        'type': type,
        'answer': null,
      },
    );
  }

  void _submitAnswer(Map<String, dynamic> state) {
    final answer = _answerController.text.trim();
    if (answer.isEmpty) return;
    ref.read(gamesServiceProvider).updateGameState(
      'truth_or_dare',
      {
        ...state,
        'answer': answer,
        'answeredAt': DateTime.now().toIso8601String(),
      },
    );
    _answerController.clear();
  }

  @override
  Widget build(BuildContext context) {
    final gamesService = ref.watch(gamesServiceProvider);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Truth or Dare'),
      ),
      body: StreamBuilder<GameState?>(
        stream: gamesService.gameStateStream('truth_or_dare'),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator(color: AppColors.rose500));
          }

          final gameState = snapshot.data;
          final state = gameState?.state ?? {};
          final currentCard = state['currentCard'] as String?;
          final type = state['type'] as String?;
          final answer = state['answer'] as String?;

          return Padding(
            padding: const EdgeInsets.all(AppSpacing.xl),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (currentCard != null) ...[
                  GlassCard(
                    padding: const EdgeInsets.all(AppSpacing.xxl),
                    child: Column(
                      children: [
                        Text(
                          type ?? '',
                          style: AppTextStyles.h2.copyWith(
                            color: type == 'Truth' ? AppColors.mint500 : AppColors.rose500,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.xl),
                        Text(
                          currentCard,
                          style: AppTextStyles.h3,
                          textAlign: TextAlign.center,
                        ),
                        if (answer != null && answer.isNotEmpty) ...[
                          const SizedBox(height: AppSpacing.xl),
                          Text('Answer', style: AppTextStyles.labelMd),
                          const SizedBox(height: AppSpacing.sm),
                          Text(answer, style: AppTextStyles.bodyMd, textAlign: TextAlign.center),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xxl),
                  TextField(
                    controller: _answerController,
                    minLines: 1,
                    maxLines: 3,
                    decoration: const InputDecoration(hintText: 'Write your answer for both of you to see'),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  AppButton(
                    label: 'Share Answer',
                    variant: AppButtonVariant.secondary,
                    onPressed: () => _submitAnswer(Map<String, dynamic>.from(state)),
                  ),
                  const SizedBox(height: AppSpacing.xxl),
                ],
                
                Row(
                  children: [
                    Expanded(
                      child: AppButton(
                        label: 'Truth',
                        onPressed: () => _pickOption('Truth'),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: AppButton(
                        label: 'Dare',
                        onPressed: () => _pickOption('Dare'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
