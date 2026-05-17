import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/auth/auth_service.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../shared/widgets/app_button.dart';
import '../../../shared/widgets/app_input.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _signIn() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final session = await ref.read(authServiceProvider).login(
            email: _emailController.text.trim(),
            password: _passwordController.text,
          );
      ref.invalidate(authStateProvider);
      if (!mounted) return;
      final dest = session.user.coupleId != null
          ? '/home/chat'
          : '/onboarding/link';
      context.go(dest);
    } on DioException catch (e) {
      setState(() {
        _error = e.response?.data?['error']?.toString() ??
            'Sign in failed. Check your connection.';
      });
    } catch (_) {
      setState(() => _error = 'Sign in failed.');
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
        title: const Text('Sign In'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('Welcome back', style: AppTextStyles.h1)
                  .animate()
                  .fadeIn()
                  .slideX(begin: -0.1),
              const SizedBox(height: AppSpacing.sm),
              Text(
                'Sign in to continue your private space.',
                style: AppTextStyles.bodyMd.copyWith(
                  color: Theme.of(context).colorScheme.onSurface.withValues(
                        alpha: 0.6,
                      ),
                ),
              ),
              const SizedBox(height: AppSpacing.xxl),
              AppInput(
                controller: _emailController,
                hintText: 'Email address',
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: AppSpacing.lg),
              AppInput(
                controller: _passwordController,
                hintText: 'Password',
                obscureText: true,
                onSubmitted: (_) => _signIn(),
              ),
              if (_error != null) ...[
                const SizedBox(height: AppSpacing.md),
                Text(
                  _error!,
                  style: AppTextStyles.bodySm.copyWith(
                    color: Theme.of(context).colorScheme.error,
                  ),
                ),
              ],
              const SizedBox(height: AppSpacing.xxl),
              AppButton(
                label: _loading ? 'Signing in…' : 'Sign In',
                onPressed: _loading ? null : _signIn,
              ),
              const SizedBox(height: AppSpacing.lg),
              AppButton(
                label: 'Continue with Google',
                variant: AppButtonVariant.secondary,
                icon: Icons.g_mobiledata_rounded,
                onPressed: () {},
              ),
              const SizedBox(height: AppSpacing.xl),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text("Don't have an account? ", style: AppTextStyles.bodySm),
                  TextButton(
                    onPressed: () => context.go('/onboarding/signup'),
                    child: const Text('Sign Up'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
