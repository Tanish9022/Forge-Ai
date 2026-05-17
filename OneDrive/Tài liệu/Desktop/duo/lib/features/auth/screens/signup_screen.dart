import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/auth/auth_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../shared/widgets/app_button.dart';
import '../../../shared/widgets/app_input.dart';

class SignUpScreen extends ConsumerStatefulWidget {
  const SignUpScreen({super.key});

  @override
  ConsumerState<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends ConsumerState<SignUpScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  Future<void> _signUp() async {
    if (_passwordController.text != _confirmController.text) {
      setState(() => _error = 'Passwords do not match');
      return;
    }
    if (_passwordController.text.length < 8) {
      setState(() => _error = 'Password must be at least 8 characters');
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      await ref.read(authServiceProvider).signUp(
            email: _emailController.text.trim(),
            password: _passwordController.text,
            displayName: _emailController.text.trim().split('@').first,
          );
      ref.invalidate(authStateProvider);
      if (!mounted) return;
      context.go('/onboarding/profile');
    } on DioException catch (e) {
      setState(() {
        _error = e.response?.data?['error']?.toString() ??
            'Sign up failed. Check your connection.';
      });
    } catch (_) {
      setState(() => _error = 'Sign up failed.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.go('/onboarding'),
        ),
        title: const Text('Create Account'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AppInput(
                controller: _emailController,
                hintText: 'Email address',
                keyboardType: TextInputType.emailAddress,
              ).animate().fadeIn(delay: 100.ms),
              const SizedBox(height: AppSpacing.lg),
              AppInput(
                controller: _passwordController,
                hintText: 'Password',
                obscureText: true,
              ).animate().fadeIn(delay: 150.ms),
              const SizedBox(height: AppSpacing.lg),
              AppInput(
                controller: _confirmController,
                hintText: 'Confirm password',
                obscureText: true,
                onSubmitted: (_) => _signUp(),
              ).animate().fadeIn(delay: 200.ms),
              if (_error != null) ...[
                const SizedBox(height: AppSpacing.md),
                Text(
                  _error!,
                  style: AppTextStyles.bodySm.copyWith(
                    color: Theme.of(context).colorScheme.error,
                  ),
                ),
              ],
              const SizedBox(height: AppSpacing.xl),
              Row(
                children: [
                  Expanded(child: Divider(color: AppColors.gray700)),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.lg,
                    ),
                    child: Text('or', style: AppTextStyles.bodySm),
                  ),
                  Expanded(child: Divider(color: AppColors.gray700)),
                ],
              ),
              const SizedBox(height: AppSpacing.xl),
              AppButton(
                label: 'Continue with Google',
                variant: AppButtonVariant.secondary,
                icon: Icons.g_mobiledata_rounded,
                onPressed: () {},
              ),
              const SizedBox(height: AppSpacing.xl),
              AppButton(
                label: _loading ? 'Creating…' : 'Create Account',
                onPressed: _loading ? null : _signUp,
              ),
              const SizedBox(height: AppSpacing.lg),
              Text(
                'By continuing you agree to our Terms & Privacy',
                style: AppTextStyles.bodySm,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
