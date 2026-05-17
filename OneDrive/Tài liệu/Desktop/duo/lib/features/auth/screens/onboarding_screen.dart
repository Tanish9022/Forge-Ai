import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../shared/widgets/app_button.dart';

class OnboardingScreen extends StatelessWidget {
  const OnboardingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () => context.go('/onboarding/login'),
                  child: Text('Skip', style: AppTextStyles.labelMd),
                ),
              ),
              const Spacer(),
              Container(
                height: 200,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppColors.plum700.withValues(alpha: 0.6),
                      AppColors.rose500.withValues(alpha: 0.3),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(AppRadius.xl),
                  border: Border.all(
                    color: AppColors.white.withValues(alpha: 0.1),
                  ),
                ),
                child: Center(
                  child: Icon(
                    Icons.favorite_rounded,
                    size: 80,
                    color: AppColors.rose500.withValues(alpha: 0.9),
                  ),
                ),
              )
                  .animate()
                  .fadeIn(duration: 500.ms)
                  .scale(begin: const Offset(0.9, 0.9)),
              const SizedBox(height: AppSpacing.xxl),
              Text(
                'Your private space',
                style: AppTextStyles.h1,
                textAlign: TextAlign.center,
              ).animate().fadeIn(delay: 200.ms),
              const SizedBox(height: AppSpacing.sm),
              Text(
                'Just the two of you.',
                style: AppTextStyles.bodyMd.copyWith(color: AppColors.gray400),
                textAlign: TextAlign.center,
              ).animate().fadeIn(delay: 300.ms),
              const Spacer(),
              AppButton(
                label: 'Get Started',
                icon: Icons.arrow_forward_rounded,
                onPressed: () => context.go('/onboarding/signup'),
              ).animate().fadeIn(delay: 400.ms).slideY(begin: 0.2),
              const SizedBox(height: AppSpacing.lg),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Already have an account? ',
                    style: AppTextStyles.bodySm,
                  ),
                  TextButton(
                    onPressed: () => context.go('/onboarding/login'),
                    child: Text(
                      'Sign In',
                      style: AppTextStyles.labelLg.copyWith(
                        color: AppColors.rose500,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.lg),
            ],
          ),
        ),
      ),
    );
  }
}
