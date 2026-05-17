import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/notes/notes_models.dart';
import '../../../core/notes/notes_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';

class NotesScreen extends ConsumerStatefulWidget {
  const NotesScreen({super.key});

  @override
  ConsumerState<NotesScreen> createState() => _NotesScreenState();
}

class _NotesScreenState extends ConsumerState<NotesScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final notesService = ref.read(notesServiceProvider);
      notesService.connect();
      notesService.loadNotes();
    });
  }

  Color _getColor(String colorName) {
    switch (colorName) {
      case 'plum': return AppColors.plum500;
      case 'mint': return AppColors.mint500;
      case 'gold': return AppColors.gold500;
      case 'rose':
      default: return AppColors.rose500;
    }
  }

  @override
  Widget build(BuildContext context) {
    final notesService = ref.watch(notesServiceProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notes'),
      ),
      body: StreamBuilder<List<Note>>(
        stream: notesService.notesStream,
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator(color: AppColors.rose500));
          }

          final notes = snapshot.data!;
          if (notes.isEmpty) {
            return Center(
              child: Text('No notes yet. Create one!', style: AppTextStyles.bodyMd),
            );
          }

          return GridView.builder(
            padding: const EdgeInsets.all(AppSpacing.lg),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: AppSpacing.md,
              mainAxisSpacing: AppSpacing.md,
              childAspectRatio: 0.8,
            ),
            itemCount: notes.length,
            itemBuilder: (context, index) {
              final note = notes[index];
              return GestureDetector(
                onTap: () {
                  context.push('/home/notes/compose', extra: note);
                },
                child: Container(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  decoration: BoxDecoration(
                    color: _getColor(note.color).withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(AppRadius.md),
                    border: Border.all(color: _getColor(note.color).withValues(alpha: 0.5)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          if (note.isPinned)
                            Icon(Icons.push_pin_rounded, size: 16, color: _getColor(note.color)),
                          Expanded(
                            child: Text(
                              note.decryptedTitle ?? 'Locked',
                              style: AppTextStyles.h3,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Expanded(
                        child: Text(
                          note.decryptedContent ?? '...',
                          style: AppTextStyles.bodySm,
                          maxLines: 6,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        DateFormat('MMM d, yyyy').format(note.updatedAt),
                        style: AppTextStyles.mono.copyWith(color: AppColors.gray400, fontSize: 10),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push('/home/notes/compose'),
        backgroundColor: AppColors.rose500,
        child: const Icon(Icons.add_rounded, color: AppColors.white),
      ),
    );
  }
}
