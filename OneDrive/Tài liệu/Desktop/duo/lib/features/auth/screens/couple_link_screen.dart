import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../shared/widgets/app_button.dart';
import '../../../shared/widgets/app_input.dart';
import '../../../shared/widgets/glass_card.dart';
import '../../../core/couple/couple_service.dart';

class CoupleLinkScreen extends ConsumerStatefulWidget {
  const CoupleLinkScreen({super.key});

  @override
  ConsumerState<CoupleLinkScreen> createState() => _CoupleLinkScreenState();
}

class _CoupleLinkScreenState extends ConsumerState<CoupleLinkScreen> {
  final _codeController = TextEditingController();
  String? _myCode;
  bool _isLoadingCode = true;
  bool _isLinking = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchMyCode();
  }

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _fetchMyCode() async {
    try {
      final code = await ref.read(coupleServiceProvider).generateCode();
      if (mounted) {
        setState(() {
          _myCode = code;
          _isLoadingCode = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Failed to generate code';
          _isLoadingCode = false;
        });
      }
    }
  }

  Future<void> _linkPartner() async {
    final code = _codeController.text.trim();
    if (code.length != 6) {
      setState(() => _error = 'Code must be 6 characters');
      return;
    }

    setState(() {
      _isLinking = true;
      _error = null;
    });

    try {
      await ref.read(coupleServiceProvider).linkPartner(code);
      if (mounted) {
        context.go('/home/chat');
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Failed to link partner. Invalid code?';
          _isLinking = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.go('/onboarding/profile'),
        ),
        title: const Text('Link Partner'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('Step 3 of 3', style: AppTextStyles.labelMd),
              const SizedBox(height: AppSpacing.sm),
              LinearProgressIndicator(
                value: 1.0,
                backgroundColor: AppColors.gray800,
                color: AppColors.rose500,
                borderRadius: BorderRadius.circular(AppRadius.full),
              ),
              const SizedBox(height: AppSpacing.xxl),
              Text('Link with your partner', style: AppTextStyles.h1)
                  .animate()
                  .fadeIn(),
              const SizedBox(height: AppSpacing.xl),
              GlassCard(
                child: Column(
                  children: [
                    Text('Your code', style: AppTextStyles.labelMd),
                    const SizedBox(height: AppSpacing.lg),
                    if (_isLoadingCode)
                      const CircularProgressIndicator(color: AppColors.rose500)
                    else if (_myCode != null)
                      Text(
                        _myCode!.split('').join('  '),
                        style: AppTextStyles.display2.copyWith(
                          letterSpacing: 4,
                          fontFeatures: const [FontFeature.tabularFigures()],
                        ),
                      )
                    else
                      Text('Error loading code', style: AppTextStyles.bodyMd),
                    const SizedBox(height: AppSpacing.xl),
                    AppButton(
                      label: 'Copy code',
                      variant: AppButtonVariant.secondary,
                      expand: false,
                      onPressed: _myCode == null
                          ? null
                          : () {
                              Clipboard.setData(
                                ClipboardData(text: _myCode!),
                              );
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Code copied')),
                              );
                            },
                    ),
                  ],
                ),
              ),
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
              Text('Have a code?', style: AppTextStyles.labelLg),
              const SizedBox(height: AppSpacing.md),
              AppInput(
                controller: _codeController,
                hintText: "Enter partner's code",
              ),
              if (_error != null) ...[
                const SizedBox(height: AppSpacing.sm),
                Text(
                  _error!,
                  style: AppTextStyles.bodySm.copyWith(color: AppColors.rose500),
                ),
              ],
              const SizedBox(height: AppSpacing.xxl),
              AppButton(
                label: _isLinking ? 'Linking...' : 'Link Partner',
                onPressed: _isLinking ? null : _linkPartner,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

