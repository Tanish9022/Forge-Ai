import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../shared/widgets/app_avatar.dart';
import '../../../shared/widgets/app_button.dart';
import '../../../shared/widgets/app_input.dart';

class ProfileSetupScreen extends StatelessWidget {
  const ProfileSetupScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.go('/onboarding/signup'),
        ),
        title: const Text('Profile Setup'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('Step 2 of 3', style: AppTextStyles.labelMd),
              const SizedBox(height: AppSpacing.sm),
              LinearProgressIndicator(
                value: 0.66,
                backgroundColor: AppColors.gray800,
                color: AppColors.rose500,
                borderRadius: BorderRadius.circular(AppRadius.full),
              ),
              const SizedBox(height: AppSpacing.xxl),
              Center(
                child: Column(
                  children: [
                    const AppAvatar(
                      initials: 'A',
                      size: AppAvatarSize.xl,
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Text(
                      'Upload your photo',
                      style: AppTextStyles.bodySm.copyWith(
                        color: AppColors.rose500,
                      ),
                    ),
                  ],
                ),
              ).animate().fadeIn().scale(begin: const Offset(0.95, 0.95)),
              const SizedBox(height: AppSpacing.xxl),
              const AppInput(hintText: 'Your name'),
              const SizedBox(height: AppSpacing.lg),
              const AppInput(hintText: 'Bio (optional)'),
              const SizedBox(height: AppSpacing.lg),
              const AppInput(hintText: 'Status emoji + text'),
              const SizedBox(height: AppSpacing.lg),
              Text('Anniversary date (optional)', style: AppTextStyles.labelMd),
              const SizedBox(height: AppSpacing.sm),
              OutlinedButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.calendar_today_rounded, size: 18),
                label: const Text('Jan 14, 2023'),
                style: OutlinedButton.styleFrom(
                  alignment: Alignment.centerLeft,
                  foregroundColor: AppColors.gray400,
                  side: BorderSide(color: AppColors.gray700),
                ),
              ),
              const SizedBox(height: AppSpacing.xxl),
              AppButton(
                label: 'Continue',
                icon: Icons.arrow_forward_rounded,
                onPressed: () => context.go('/onboarding/link'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
