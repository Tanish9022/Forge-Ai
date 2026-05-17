import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/auth/auth_service.dart';
import '../../../core/snaps/snaps_models.dart';
import '../../../core/snaps/snaps_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';

class SnapsTabScreen extends ConsumerStatefulWidget {
  const SnapsTabScreen({super.key});

  @override
  ConsumerState<SnapsTabScreen> createState() => _SnapsTabScreenState();
}

class _SnapsTabScreenState extends ConsumerState<SnapsTabScreen> {
  List<Snap>? _snaps;
  bool _isLoading = true;
  int _streakCount = 0;

  @override
  void initState() {
    super.initState();
    _loadSnaps();
  }

  Future<void> _loadSnaps() async {
    try {
      final feed = await ref.read(snapsServiceProvider).getSnapFeed();
      if (mounted) {
        setState(() {
          _snaps = feed.snaps;
          _streakCount = feed.streakCount;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authStateProvider).value;

    return Scaffold(
      appBar: AppBar(
        title: Text('Snaps  $_streakCount day streak'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _loadSnaps,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.rose500))
          : (_snaps == null || _snaps!.isEmpty)
              ? Center(child: Text('No snaps yet', style: AppTextStyles.bodyMd))
              : GridView.builder(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    crossAxisSpacing: AppSpacing.sm,
                    mainAxisSpacing: AppSpacing.sm,
                  ),
                  itemCount: _snaps!.length,
                  itemBuilder: (context, index) {
                    final snap = _snaps![index];
                    final isMine = snap.senderId == user?.id;
                    final unseen = !snap.viewed && !isMine;
                    final saved = user != null && snap.savedBy.contains(user.id);

                    return GestureDetector(
                      onTap: () {
                        if (unseen) {
                          context.push('/home/snaps/view', extra: snap).then((_) => _loadSnaps());
                        }
                      },
                      onLongPress: () {
                        showModalBottomSheet<void>(
                          context: context,
                          backgroundColor: AppColors.gray900,
                          builder: (context) => SafeArea(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                ListTile(
                                  leading: Icon(
                                    saved ? Icons.bookmark_remove_rounded : Icons.bookmark_add_rounded,
                                    color: AppColors.gold500,
                                  ),
                                  title: Text(saved ? 'Unsave snap' : 'Save snap'),
                                  onTap: () async {
                                    context.pop();
                                    await ref.read(snapsServiceProvider).toggleSaveSnap(snap.id);
                                    await _loadSnaps();
                                  },
                                ),
                                ListTile(
                                  leading: const Icon(Icons.delete_forever_rounded, color: AppColors.rose500),
                                  title: const Text('Delete for both'),
                                  onTap: () async {
                                    context.pop();
                                    await ref.read(snapsServiceProvider).deleteSnapForBoth(snap.id);
                                    await _loadSnaps();
                                  },
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              isMine ? AppColors.gray800 : AppColors.plum700,
                              isMine
                                  ? AppColors.gray700
                                  : AppColors.plum500.withValues(alpha: 0.8),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(AppRadius.md),
                          border: unseen
                              ? Border.all(color: AppColors.rose500, width: 2)
                              : null,
                        ),
                          child: unseen
                            ? Align(
                                alignment: Alignment.topRight,
                                child: Padding(
                                  padding: const EdgeInsets.all(AppSpacing.sm),
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      if (saved)
                                        const Icon(Icons.bookmark_rounded, color: AppColors.gold500, size: 18),
                                      Container(
                                        width: 12,
                                        height: 12,
                                        decoration: const BoxDecoration(
                                          color: AppColors.rose500,
                                          shape: BoxShape.circle,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              )
                            : Center(
                                child: Stack(
                                  alignment: Alignment.center,
                                  children: [
                                    Icon(
                                      isMine ? Icons.send_rounded : Icons.visibility_rounded,
                                      color: AppColors.gray400,
                                    ),
                                    if (saved)
                                      const Positioned(
                                        right: 8,
                                        top: 8,
                                        child: Icon(Icons.bookmark_rounded, color: AppColors.gold500, size: 18),
                                      ),
                                  ],
                                ),
                              ),
                      ).animate().fadeIn(delay: (index * 50).ms).scale(
                            begin: const Offset(0.95, 0.95),
                          ),
                    );
                  },
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          context.push('/home/snaps/camera').then((_) => _loadSnaps());
        },
        backgroundColor: AppColors.rose500,
        child: const Icon(Icons.camera_alt_rounded, color: AppColors.white),
      ),
    );
  }
}
