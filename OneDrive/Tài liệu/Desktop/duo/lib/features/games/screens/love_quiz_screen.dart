import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/auth/auth_service.dart';
import '../../../core/games/games_models.dart';
import '../../../core/games/games_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../shared/widgets/app_button.dart';
import '../../../shared/widgets/glass_card.dart';

class LoveQuizScreen extends ConsumerStatefulWidget {
  const LoveQuizScreen({super.key});

  @override
  ConsumerState<LoveQuizScreen> createState() => _LoveQuizScreenState();
}

class _LoveQuizScreenState extends ConsumerState<LoveQuizScreen> {
  final _answerController = TextEditingController();

  static const _questions = [
    "What is my favorite comfort food?",
    "Where did we go on our first date?",
    "What's my dream vacation destination?",
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
      gamesService.loadGameState('love_quiz');
    });
  }

  @override
  Widget build(BuildContext context) {
    final gamesService = ref.watch(gamesServiceProvider);
    final user = ref.watch(authStateProvider).value;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Love Quiz'),
      ),
      body: StreamBuilder<GameState?>(
        stream: gamesService.gameStateStream('love_quiz'),
        builder: (context, snapshot) {
          if (!snapshot.hasData || user == null) {
            return const Center(child: CircularProgressIndicator(color: AppColors.rose500));
          }

          final state = snapshot.data?.state ?? {};
          final qIndex = (state['qIndex'] as int?) ?? 0;
          final lastAnswer = state['lastAnswer'] as String?;

          return Padding(
            padding: const EdgeInsets.all(AppSpacing.xl),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                GlassCard(
                  padding: const EdgeInsets.all(AppSpacing.xxl),
                  child: Column(
                    children: [
                      Text('Question ${qIndex + 1}', style: AppTextStyles.labelMd.copyWith(color: AppColors.rose500)),
                      const SizedBox(height: AppSpacing.md),
                      Text(_questions[qIndex % _questions.length], style: AppTextStyles.h2, textAlign: TextAlign.center),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.xxl),
                if (lastAnswer != null) ...[
                  Text('Last Answer: $lastAnswer', style: AppTextStyles.bodyMd, textAlign: TextAlign.center),
                  const SizedBox(height: AppSpacing.xxl),
                ],
                TextField(
                  controller: _answerController,
                  decoration: const InputDecoration(hintText: 'Write your answer'),
                ),
                const SizedBox(height: AppSpacing.md),
                AppButton(
                  label: 'Share Answer',
                  variant: AppButtonVariant.secondary,
                  onPressed: () {
                    final answer = _answerController.text.trim();
                    if (answer.isEmpty) return;
                    ref.read(gamesServiceProvider).updateGameState(
                      'love_quiz',
                      {
                        'qIndex': qIndex,
                        'lastAnswer': answer,
                        'answeredBy': user.id,
                      },
                    );
                    _answerController.clear();
                  },
                ),
                const SizedBox(height: AppSpacing.md),
                AppButton(
                  label: 'Next Question',
                  onPressed: () {
                    ref.read(gamesServiceProvider).updateGameState(
                      'love_quiz',
                      {'qIndex': (qIndex + 1) % _questions.length, 'lastAnswer': null},
                    );
                  },
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
