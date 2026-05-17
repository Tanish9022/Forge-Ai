import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/auth/app_lock_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';

class AppLockScreen extends ConsumerStatefulWidget {
  const AppLockScreen({super.key, required this.targetPath});
  
  final String targetPath;

  @override
  ConsumerState<AppLockScreen> createState() => _AppLockScreenState();
}

class _AppLockScreenState extends ConsumerState<AppLockScreen> {
  String _pin = '';
  bool _isError = false;

  @override
  void initState() {
    super.initState();
    _checkBiometrics();
  }

  Future<void> _checkBiometrics() async {
    final success = await ref.read(appLockServiceProvider).authenticateBiometric();
    if (success && mounted) {
      context.go(widget.targetPath);
    }
  }

  void _addDigit(String digit) async {
    if (_pin.length < 4) {
      setState(() {
        _pin += digit;
        _isError = false;
      });

      if (_pin.length == 4) {
        final success = await ref.read(appLockServiceProvider).verifyPin(_pin);
        if (success && mounted) {
          context.go(widget.targetPath);
        } else {
          setState(() {
            _isError = true;
            _pin = '';
          });
        }
      }
    }
  }

  void _removeDigit() {
    if (_pin.isNotEmpty) {
      setState(() {
        _pin = _pin.substring(0, _pin.length - 1);
        _isError = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.lock_rounded, size: 64, color: AppColors.rose500),
            const SizedBox(height: AppSpacing.xl),
            Text('Enter PIN', style: AppTextStyles.h2),
            const SizedBox(height: AppSpacing.xxl),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(4, (index) {
                final isFilled = index < _pin.length;
                return Container(
                  margin: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isFilled ? AppColors.rose500 : Colors.transparent,
                    border: Border.all(
                      color: _isError ? AppColors.rose500 : (isFilled ? AppColors.rose500 : AppColors.gray400),
                      width: 2,
                    ),
                  ),
                );
              }),
            ),
            const SizedBox(height: 64),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 48),
              child: GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  childAspectRatio: 1.5,
                  mainAxisSpacing: 16,
                  crossAxisSpacing: 16,
                ),
                itemCount: 12,
                itemBuilder: (context, index) {
                  if (index == 9) return IconButton(icon: const Icon(Icons.fingerprint_rounded, size: 32), onPressed: _checkBiometrics);
                  if (index == 11) return IconButton(icon: const Icon(Icons.backspace_rounded, size: 28), onPressed: _removeDigit);
                  
                  final number = index == 10 ? 0 : index + 1;
                  return InkWell(
                    onTap: () => _addDigit(number.toString()),
                    borderRadius: BorderRadius.circular(40),
                    child: Center(
                      child: Text(number.toString(), style: AppTextStyles.display2),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
