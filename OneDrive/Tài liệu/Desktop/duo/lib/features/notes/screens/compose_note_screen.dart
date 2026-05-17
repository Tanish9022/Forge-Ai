import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/notes/notes_models.dart';
import '../../../core/notes/notes_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';

class ComposeNoteScreen extends ConsumerStatefulWidget {
  const ComposeNoteScreen({super.key, this.note});
  final Note? note;

  @override
  ConsumerState<ComposeNoteScreen> createState() => _ComposeNoteScreenState();
}

class _ComposeNoteScreenState extends ConsumerState<ComposeNoteScreen> {
  late TextEditingController _titleController;
  late TextEditingController _contentController;
  
  String _selectedColor = 'rose';
  bool _isPinned = false;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.note?.decryptedTitle ?? '');
    _contentController = TextEditingController(text: widget.note?.decryptedContent ?? '');
    _selectedColor = widget.note?.color ?? 'rose';
    _isPinned = widget.note?.isPinned ?? false;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  Future<void> _saveNote() async {
    final title = _titleController.text.trim();
    final content = _contentController.text.trim();
    
    if (title.isEmpty && content.isEmpty) {
      context.pop();
      return;
    }
    
    setState(() => _isSaving = true);
    
    try {
      if (widget.note == null) {
        await ref.read(notesServiceProvider).createNote(
          title: title,
          content: content,
          color: _selectedColor,
          isPinned: _isPinned,
        );
      } else {
        await ref.read(notesServiceProvider).updateNote(
          id: widget.note!.id,
          title: title,
          content: content,
          color: _selectedColor,
          isPinned: _isPinned,
        );
      }
      if (mounted) context.pop();
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to save note')),
        );
      }
    }
  }

  Future<void> _deleteNote() async {
    if (widget.note == null) return;
    
    setState(() => _isSaving = true);
    try {
      await ref.read(notesServiceProvider).deleteNote(widget.note!.id);
      if (mounted) context.pop();
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to delete note')),
        );
      }
    }
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
    final colorVal = _getColor(_selectedColor);

    return Scaffold(
      appBar: AppBar(
        actions: [
          IconButton(
            icon: Icon(
              _isPinned ? Icons.push_pin_rounded : Icons.push_pin_outlined,
              color: _isPinned ? colorVal : AppColors.gray400,
            ),
            onPressed: () => setState(() => _isPinned = !_isPinned),
          ),
          if (widget.note != null)
            IconButton(
              icon: const Icon(Icons.delete_outline_rounded, color: AppColors.gray400),
              onPressed: _deleteNote,
            ),
          IconButton(
            icon: _isSaving 
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.rose500))
                : const Icon(Icons.check_rounded, color: AppColors.mint500),
            onPressed: _isSaving ? null : _saveNote,
          ),
        ],
      ),
      body: Column(
        children: [
          // Color picker
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.md),
            child: Row(
              children: ['rose', 'plum', 'mint', 'gold'].map((colorName) {
                final isSelected = _selectedColor == colorName;
                final c = _getColor(colorName);
                return GestureDetector(
                  onTap: () => setState(() => _selectedColor = colorName),
                  child: Container(
                    margin: const EdgeInsets.only(right: AppSpacing.sm),
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: c,
                      shape: BoxShape.circle,
                      border: isSelected ? Border.all(color: AppColors.white, width: 2) : null,
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Column(
                children: [
                  TextField(
                    controller: _titleController,
                    style: AppTextStyles.h2.copyWith(color: colorVal),
                    decoration: const InputDecoration(
                      hintText: 'Title',
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                    ),
                  ),
                  TextField(
                    controller: _contentController,
                    style: AppTextStyles.bodyMd,
                    maxLines: null,
                    decoration: const InputDecoration(
                      hintText: 'Note content...',
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                    ),
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
