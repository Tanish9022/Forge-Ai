import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';

class HomeShell extends StatelessWidget {
  const HomeShell({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  static const _tabs = [
    _TabData(
      path: '/home/chat',
      icon: Icons.chat_bubble_rounded,
      label: 'Chat',
    ),
    _TabData(
      path: '/home/snaps',
      icon: Icons.circle_rounded,
      label: 'Snaps',
    ),
    _TabData(
      path: '/home/together',
      icon: Icons.favorite_rounded,
      label: 'Together',
    ),
    _TabData(
      path: '/home/notes',
      icon: Icons.sticky_note_2_rounded,
      label: 'Notes',
    ),
    _TabData(
      path: '/home/profile',
      icon: Icons.person_rounded,
      label: 'You',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final currentIndex = navigationShell.currentIndex;

    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).bottomNavigationBarTheme.backgroundColor,
          border: Border(
            top: BorderSide(
              color: AppColors.gray700.withValues(alpha: 0.5),
            ),
          ),
        ),
        child: SafeArea(
          child: SizedBox(
            height: 64,
            child: Row(
              children: List.generate(_tabs.length, (index) {
                final tab = _tabs[index];
                final selected = index == currentIndex;
                return Expanded(
                  child: InkWell(
                    onTap: () => _onTap(context, index),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          tab.icon,
                          color: selected
                              ? AppColors.rose500
                              : AppColors.gray400,
                          size: 24,
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        Text(
                          tab.label,
                          style: AppTextStyles.labelSm.copyWith(
                            color: selected
                                ? AppColors.rose500
                                : AppColors.gray400,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          height: 4,
                          width: selected ? 24 : 0,
                          decoration: BoxDecoration(
                            color: AppColors.rose500,
                            borderRadius: BorderRadius.circular(
                              AppRadius.full,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }),
            ),
          ),
        ),
      ),
    );
  }

  void _onTap(BuildContext context, int index) {
    navigationShell.goBranch(
      index,
      initialLocation: index == navigationShell.currentIndex,
    );
  }
}

class _TabData {
  const _TabData({
    required this.path,
    required this.icon,
    required this.label,
  });

  final String path;
  final IconData icon;
  final String label;
}
