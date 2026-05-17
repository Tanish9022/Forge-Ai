import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/api/api_client.dart';
import '../../../core/auth/auth_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/theme/theme_provider.dart';
import '../../../shared/widgets/app_avatar.dart';
import '../../../shared/widgets/glass_card.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  Map<String, dynamic>? _stats;
  bool _isLoadingStats = true;

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    try {
      final dio = ref.read(apiClientProvider);
      final res = await dio.get<Map<String, dynamic>>('/stats');
      if (mounted) {
        setState(() {
          _stats = res.data!['stats'] as Map<String, dynamic>;
          _isLoadingStats = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingStats = false;
        });
      }
    }
  }

  Future<void> _deleteAccount() async {
    try {
      final dio = ref.read(apiClientProvider);
      await dio.delete<Map<String, dynamic>>('/auth/me');
      await ref.read(authStateProvider.notifier).signOut();
      if (mounted) context.go('/');
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to delete account')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authStateProvider).value;
    
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Column(
              children: [
                Container(
                  height: 140,
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [AppColors.plum700, AppColors.rose500],
                    ),
                  ),
                ),
                Transform.translate(
                  offset: const Offset(0, -40),
                  child: Column(
                    children: [
                      AppAvatar(
                        initials: user?.displayName?[0].toUpperCase() ?? 'U',
                        size: AppAvatarSize.xl,
                      ),
                      const SizedBox(height: AppSpacing.md),
                      Text(user?.displayName ?? 'User', style: AppTextStyles.h1),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        user?.email ?? '',
                        style: AppTextStyles.bodyMd.copyWith(
                          color: AppColors.gray400,
                        ),
                      ),
                    ],
                  ),
                ).animate().fadeIn().slideY(begin: 0.1),
                
                if (_isLoadingStats)
                   const Center(child: CircularProgressIndicator(color: AppColors.rose500))
                else if (_stats != null)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
                    child: Row(
                      children: [
                        _StatTile(value: _stats!['totalSnaps'].toString(), label: 'Snaps'),
                        const SizedBox(width: AppSpacing.md),
                        _StatTile(value: _stats!['totalMessages'].toString(), label: 'Msgs'),
                        const SizedBox(width: AppSpacing.md),
                        _StatTile(value: _stats!['totalGamesPlayed'].toString(), label: 'Games'),
                      ],
                    ),
                  ).animate().fadeIn(delay: 150.ms),
                  
                const SizedBox(height: AppSpacing.xl),
              ],
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                Padding(
                  padding: const EdgeInsets.only(
                    left: AppSpacing.sm,
                    bottom: AppSpacing.md,
                  ),
                  child: Text('SETTINGS', style: AppTextStyles.labelSm),
                ),
                const _SettingsTile(title: 'App Lock (PIN/Biometric)', icon: Icons.lock_rounded, route: '/lock'),
                const _SettingsTile(title: 'Chat Theme', icon: Icons.palette_rounded),
                const _SettingsTile(title: 'Notifications', icon: Icons.notifications_rounded),
                ListTile(
                  leading: const Icon(Icons.dark_mode_rounded, color: AppColors.gray400),
                  title: Text('Appearance (Light/Dark/System)', style: AppTextStyles.bodyMd),
                  trailing: const Icon(Icons.chevron_right_rounded, color: AppColors.gray400),
                  onTap: () {
                    final current = ref.read(themeModeProvider);
                    if (current == ThemeMode.system) {
                      ref.read(themeModeProvider.notifier).state = ThemeMode.dark;
                    } else if (current == ThemeMode.dark) {
                      ref.read(themeModeProvider.notifier).state = ThemeMode.light;
                    } else {
                      ref.read(themeModeProvider.notifier).state = ThemeMode.system;
                    }
                  },
                ),
                const SizedBox(height: AppSpacing.lg),
                ListTile(
                  leading: const Icon(Icons.logout_rounded, color: AppColors.rose500),
                  title: Text('Sign Out', style: AppTextStyles.labelLg.copyWith(color: AppColors.rose500)),
                  onTap: () async {
                    await ref.read(authStateProvider.notifier).signOut();
                    if (context.mounted) context.go('/');
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.delete_forever_rounded, color: AppColors.rose500),
                  title: Text('Delete Account', style: AppTextStyles.labelLg.copyWith(color: AppColors.rose500)),
                  onTap: () {
                    showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        backgroundColor: AppColors.gray900,
                        title: const Text('Delete Account?', style: TextStyle(color: Colors.white)),
                        content: const Text('This will permanently delete your account and unlink your couple. This action cannot be undone.', style: TextStyle(color: AppColors.gray400)),
                        actions: [
                          TextButton(onPressed: () => context.pop(), child: const Text('Cancel')),
                          TextButton(
                            onPressed: () {
                              context.pop();
                              _deleteAccount();
                            }, 
                            child: const Text('Delete', style: TextStyle(color: AppColors.rose500)),
                          ),
                        ],
                      )
                    );
                  },
                ),
                const SizedBox(height: AppSpacing.xxxl),
              ]),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({required this.value, required this.label});

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GlassCard(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
        child: Column(
          children: [
            Text(
              value,
              style: AppTextStyles.display2.copyWith(fontSize: 22),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(label, style: AppTextStyles.bodySm),
          ],
        ),
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  const _SettingsTile({required this.title, required this.icon, this.route});

  final String title;
  final IconData icon;
  final String? route;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: AppColors.gray400),
      title: Text(title, style: AppTextStyles.bodyMd),
      trailing: const Icon(
        Icons.chevron_right_rounded,
        color: AppColors.gray400,
      ),
      onTap: () {
        if (route != null) {
          context.push(route!);
        }
      },
    );
  }
}
