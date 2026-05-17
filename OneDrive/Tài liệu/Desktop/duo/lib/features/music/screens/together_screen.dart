import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/auth/auth_service.dart';
import '../../../core/music/music_models.dart';
import '../../../core/music/music_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../shared/widgets/glass_card.dart';
import '../../../shared/widgets/app_input.dart';

class TogetherScreen extends ConsumerStatefulWidget {
  const TogetherScreen({super.key});

  @override
  ConsumerState<TogetherScreen> createState() => _TogetherScreenState();
}

class _TogetherScreenState extends ConsumerState<TogetherScreen> {
  final _searchController = TextEditingController();
  List<YouTubeTrack> _searchResults = [];
  bool _isSearching = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final user = ref.read(authStateProvider).value;
      if (user != null) {
        ref.read(musicServiceProvider).connect(user.id);
      }
    });
  }

  Future<void> _performSearch(String query) async {
    if (query.trim().isEmpty) {
      setState(() => _searchResults = []);
      return;
    }
    
    setState(() => _isSearching = true);
    final results = await ref.read(musicServiceProvider).searchYouTube(query);
    if (mounted) {
      setState(() {
        _searchResults = results;
        _isSearching = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final musicService = ref.watch(musicServiceProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Together'),
      ),
      body: CustomScrollView(
        slivers: [
          // Music Player Section
          SliverToBoxAdapter(
            child: StreamBuilder<MusicSession?>(
              stream: musicService.sessionStream,
              builder: (context, snapshot) {
                final session = snapshot.data;
                
                return Padding(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  child: GlassCard(
                    child: Column(
                      children: [
                        Text('Listen Together', style: AppTextStyles.h3),
                        const SizedBox(height: AppSpacing.md),
                        if (session?.trackTitle != null) ...[
                          Text(
                            session!.trackTitle!,
                            style: AppTextStyles.bodyMd.copyWith(fontWeight: FontWeight.bold),
                            textAlign: TextAlign.center,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: AppSpacing.xs),
                          Text(
                            session.trackArtist ?? 'YouTube',
                            style: AppTextStyles.bodySm.copyWith(color: AppColors.gray400),
                          ),
                          const SizedBox(height: AppSpacing.md),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              IconButton(
                                icon: Icon(
                                  session.isPlaying ? Icons.pause_circle_filled_rounded : Icons.play_circle_fill_rounded,
                                  size: 48,
                                  color: AppColors.rose500,
                                ),
                                onPressed: () {
                                  musicService.updateSession(
                                    isPlaying: !session.isPlaying,
                                    position: session.position, // We should grab actual pos
                                  );
                                },
                              ),
                            ],
                          ),
                        ] else ...[
                          Text(
                            'No music playing',
                            style: AppTextStyles.bodyMd.copyWith(color: AppColors.gray400),
                          ),
                        ],
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          
          // Search Section
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
              child: AppInput(
                controller: _searchController,
                hintText: 'Search YouTube...',
                textInputAction: TextInputAction.search,
                onSubmitted: _performSearch,
              ),
            ),
          ),
          
          if (_isSearching)
            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.all(AppSpacing.xl),
                child: Center(child: CircularProgressIndicator(color: AppColors.rose500)),
              ),
            )
          else if (_searchResults.isNotEmpty)
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final track = _searchResults[index];
                  return ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.xs),
                    leading: track.thumbnailUrl != null 
                        ? Image.network(track.thumbnailUrl!, width: 50, height: 50, fit: BoxFit.cover)
                        : const Icon(Icons.music_note_rounded),
                    title: Text(track.title, maxLines: 1, overflow: TextOverflow.ellipsis),
                    subtitle: Text(track.channelTitle, maxLines: 1, overflow: TextOverflow.ellipsis),
                    trailing: IconButton(
                      icon: const Icon(Icons.play_arrow_rounded, color: AppColors.rose500),
                      onPressed: () {
                        musicService.updateSession(
                          trackId: track.videoId,
                          trackTitle: track.title,
                          trackArtist: track.channelTitle,
                          isPlaying: true,
                          position: 0.0,
                        );
                        _searchController.clear();
                        setState(() => _searchResults = []);
                      },
                    ),
                  );
                },
                childCount: _searchResults.length,
              ),
            ),
            
          // Games Hub Section
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: AppSpacing.lg),
                  Text('Games Hub', style: AppTextStyles.h2),
                  const SizedBox(height: AppSpacing.md),
                  _GameCard(
                    title: 'Chess',
                    icon: Icons.sports_esports_rounded,
                    color: AppColors.plum500,
                    onTap: () => context.push('/games/chess'),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  _GameCard(
                    title: 'Tic Tac Toe',
                    icon: Icons.close_rounded,
                    color: AppColors.mint500,
                    onTap: () => context.push('/games/tictactoe'),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  _GameCard(
                    title: 'Truth or Dare',
                    icon: Icons.question_mark_rounded,
                    color: AppColors.gold500,
                    onTap: () => context.push('/games/truth_or_dare'),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  _GameCard(
                    title: 'Love Quiz',
                    icon: Icons.favorite_rounded,
                    color: AppColors.rose500,
                    onTap: () => context.push('/games/love_quiz'),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _GameCard extends StatelessWidget {
  const _GameCard({
    required this.title,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  final String title;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: GlassCard(
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(AppRadius.md),
              ),
              child: Icon(icon, color: color, size: 32),
            ),
            const SizedBox(width: AppSpacing.md),
            Text(title, style: AppTextStyles.h3),
            const Spacer(),
            Icon(Icons.chevron_right_rounded, color: AppColors.gray400),
          ],
        ),
      ),
    );
  }
}
