import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/auth/auth_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _resolveRoute();
  }

  Future<void> _resolveRoute() async {
    await Future<void>.delayed(const Duration(milliseconds: 1200));
    final user = await ref.read(authServiceProvider).getCurrentUser();
    if (!mounted) return;

    if (user != null) {
      context.go(user.coupleId != null ? '/home/chat' : '/onboarding/link');
    } else {
      context.go('/onboarding');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [AppColors.plum900, AppColors.plum700],
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 12,
                  height: 12,
                  decoration: const BoxDecoration(
                    color: AppColors.rose500,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.rose500,
                        blurRadius: 12,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Text('Atmos', style: AppTextStyles.display2),
              ],
            )
                .animate()
                .fadeIn(duration: 600.ms)
                .moveY(begin: 8, end: 0, duration: 600.ms),
            const SizedBox(height: AppSpacing.xxl),
            Container(
              width: 120,
              height: 2,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppColors.rose500.withValues(alpha: 0),
                    AppColors.rose500,
                    AppColors.gold500,
                    AppColors.rose500.withValues(alpha: 0),
                  ],
                ),
              ),
            )
                .animate(onPlay: (c) => c.repeat())
                .shimmer(duration: 2.seconds, color: AppColors.gold500),
          ],
        ),
      ),
    );
  }
}
