import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:just_audio/just_audio.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';

import '../../../core/auth/auth_service.dart';
import '../../../core/couple/couple_service.dart';
import '../../../core/chat/chat_models.dart';
import '../../../core/chat/chat_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../shared/widgets/app_avatar.dart';
import '../../../shared/widgets/glass_card.dart';
import '../../../shared/widgets/online_dot.dart';

class ChatScreen extends ConsumerStatefulWidget {
  const ChatScreen({super.key});

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  static const _themeColors = {
    'rose': AppColors.rose500,
    'plum': AppColors.plum500,
    'blue': Color(0xFF3B82F6),
    'mint': AppColors.mint500,
    'gold': AppColors.gold500,
  };

  final _textController = TextEditingController();
  final _picker = ImagePicker();
  final _audioRecorder = AudioRecorder();
  
  String _currentTheme = 'rose';
  ChatMessage? _replyingTo;
  bool _isRecording = false;
  String _partnerName = 'Partner';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final chatService = ref.read(chatServiceProvider);
      chatService.connect();
      chatService.loadMessages();
      _loadPartnerName();
    });
  }

  @override
  void dispose() {
    _textController.dispose();
    _audioRecorder.dispose();
    super.dispose();
  }

  Future<void> _loadPartnerName() async {
    try {
      final couple = await ref.read(coupleServiceProvider).getCouple();
      final nickname = couple?['partnerNickname'] as String?;
      final partner = couple?['partner'] as Map<String, dynamic>?;
      final displayName = partner?['displayName'] as String?;
      if (mounted) {
        setState(() {
          _partnerName = (nickname?.trim().isNotEmpty ?? false)
              ? nickname!.trim()
              : (displayName?.trim().isNotEmpty ?? false)
                  ? displayName!.trim()
                  : 'Partner';
        });
      }
    } catch (_) {
      // Keep default label.
    }
  }

  Future<void> _editPartnerNickname() async {
    final controller = TextEditingController(text: _partnerName == 'Partner' ? '' : _partnerName);
    final nickname = await showDialog<String?>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.gray900,
        title: const Text('Partner nickname'),
        content: TextField(
          controller: controller,
          autofocus: true,
          maxLength: 40,
          decoration: const InputDecoration(hintText: 'Nickname'),
        ),
        actions: [
          TextButton(onPressed: () => context.pop(null), child: const Text('Cancel')),
          TextButton(onPressed: () => context.pop(''), child: const Text('Clear')),
          TextButton(onPressed: () => context.pop(controller.text.trim()), child: const Text('Save')),
        ],
      ),
    );
    controller.dispose();
    if (nickname == null) return;

    final saved = await ref.read(coupleServiceProvider).updatePartnerNickname(
          nickname.isEmpty ? null : nickname,
        );
    if (mounted) {
      setState(() => _partnerName = (saved?.isNotEmpty ?? false) ? saved! : 'Partner');
    }
  }

  void _sendMessage() {
    final text = _textController.text.trim();
    if (text.isEmpty) return;

    final user = ref.read(authStateProvider).value;
    if (user == null) return;

    ref.read(chatServiceProvider).sendMessage(
      text, 
      user.id, 
      replyTo: _replyingTo?.id,
    );
    
    _textController.clear();
    setState(() => _replyingTo = null);
    ref.read(chatServiceProvider).sendTypingEvent(false);
  }

  Future<void> _sendImage() async {
    final user = ref.read(authStateProvider).value;
    if (user == null) return;

    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      await ref.read(chatServiceProvider).sendMediaMessage(
        File(pickedFile.path),
        user.id,
        'image',
        replyTo: _replyingTo?.id,
      );
      setState(() => _replyingTo = null);
    }
  }

  Future<void> _toggleVoiceRecording() async {
    final user = ref.read(authStateProvider).value;
    if (user == null) return;

    if (_isRecording) {
      final path = await _audioRecorder.stop();
      if (mounted) setState(() => _isRecording = false);
      if (path == null) return;

      await ref.read(chatServiceProvider).sendMediaMessage(
            File(path),
            user.id,
            'voice',
            replyTo: _replyingTo?.id,
          );
      setState(() => _replyingTo = null);
      return;
    }

    if (!await _audioRecorder.hasPermission()) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Microphone permission is required')),
        );
      }
      return;
    }

    final tempDir = await getTemporaryDirectory();
    final path = p.join(tempDir.path, 'voice_${DateTime.now().millisecondsSinceEpoch}.m4a');
    await _audioRecorder.start(
      const RecordConfig(encoder: AudioEncoder.aacLc),
      path: path,
    );
    if (mounted) setState(() => _isRecording = true);
  }

  void _insertEmoji(String emoji) {
    final selection = _textController.selection;
    final text = _textController.text;
    final start = selection.start < 0 ? text.length : selection.start;
    final end = selection.end < 0 ? text.length : selection.end;
    _textController.text = text.replaceRange(start, end, emoji);
    _textController.selection = TextSelection.collapsed(offset: start + emoji.length);
    ref.read(chatServiceProvider).sendTypingEvent(_textController.text.isNotEmpty);
  }

  void _changeTheme(String themeKey) {
    setState(() => _currentTheme = themeKey);
    ref.read(coupleServiceProvider).updateTheme(themeKey);
  }

  void _showMessageOptions(BuildContext context, ChatMessage message, bool isOwn, String currentUserId) {
    if (message.isDeleted) return;

    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.gray900,
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: ['❤️', '😂', '🔥', '😢', '👍'].map((emoji) {
                    return GestureDetector(
                      onTap: () {
                        context.pop();
                        ref.read(chatServiceProvider).toggleReaction(message.id, currentUserId, emoji);
                      },
                      child: Text(emoji, style: const TextStyle(fontSize: 32)),
                    );
                  }).toList(),
                ),
              ),
              const Divider(color: AppColors.gray800),
              ListTile(
                leading: const Icon(Icons.reply_rounded, color: AppColors.white),
                title: Text('Reply', style: AppTextStyles.bodyMd),
                onTap: () {
                  context.pop();
                  setState(() => _replyingTo = message);
                },
              ),
              if (isOwn)
                ListTile(
                  leading: const Icon(Icons.delete_outline_rounded, color: AppColors.rose500),
                  title: Text('Delete', style: AppTextStyles.bodyMd.copyWith(color: AppColors.rose500)),
                  onTap: () {
                    context.pop();
                    ref.read(chatServiceProvider).deleteMessage(message.id);
                  },
                ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final chatService = ref.watch(chatServiceProvider);
    final authState = ref.watch(authStateProvider);
    final currentUser = authState.value;
    
    final themeColor = _themeColors[_currentTheme] ?? AppColors.rose500;
    
    final partnerName = _partnerName; 
    final partnerInitials = partnerName[0];

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 0,
        title: Row(
          children: [
            AppAvatar(
              initials: partnerInitials,
              size: AppAvatarSize.md,
              showOnline: true,
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(partnerName, style: AppTextStyles.h2),
                  StreamBuilder<String>(
                    stream: chatService.typingStream,
                    builder: (context, snapshot) {
                      final typingUserId = snapshot.data;
                      final isTyping = typingUserId != null &&
                          typingUserId.isNotEmpty &&
                          typingUserId != currentUser?.id;
                      
                      return Row(
                        children: [
                          const OnlineDot(size: 8),
                          const SizedBox(width: AppSpacing.xs),
                          Text(
                            isTyping ? 'Typing...' : 'Online',
                            style: AppTextStyles.bodySm.copyWith(
                              color: isTyping ? AppColors.mint500 : AppColors.gray400,
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ],
              ),
            ),
            IconButton(
              tooltip: 'Set nickname',
              icon: const Icon(Icons.edit_rounded),
              onPressed: _editPartnerNickname,
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          _ChatThemeBar(
            colors: _themeColors,
            activeTheme: _currentTheme,
            onThemeSelected: _changeTheme,
          ),
          Expanded(
            child: StreamBuilder<List<ChatMessage>>(
              stream: chatService.messagesStream,
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return Center(child: CircularProgressIndicator(color: themeColor));
                }

                final messages = snapshot.data!;
                if (messages.isEmpty) {
                  return Center(
                    child: Text('Say hi! 👋', style: AppTextStyles.bodyMd),
                  );
                }

                return ListView.separated(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  reverse: true,
                  itemCount: messages.length,
                  separatorBuilder: (context, index) => const SizedBox(height: AppSpacing.md),
                  itemBuilder: (context, index) {
                    final message = messages[index];
                    final isOwn = message.senderId == currentUser?.id;
                    final time = DateFormat('h:mm a').format(message.createdAt);
                    
                    final repliedMessage = message.replyTo != null 
                        ? messages.where((m) => m.id == message.replyTo).firstOrNull 
                        : null;

                    if (message.type == 'text' || message.type == 'image' || message.type == 'voice') {
                      Widget bubble = isOwn 
                        ? _OwnBubble(
                            message: message,
                            time: time,
                            themeColor: themeColor,
                            repliedMessage: repliedMessage,
                          ).animate().fadeIn().slideX(begin: 0.1)
                        : _PartnerBubble(
                            message: message,
                            time: time,
                            initials: partnerInitials,
                            repliedMessage: repliedMessage,
                          ).animate().fadeIn().slideX(begin: -0.1);

                      if (!isOwn && message.status != 'read') {
                        chatService.markAsRead(message.id);
                      }

                      return GestureDetector(
                        onLongPress: () {
                          if (currentUser != null) {
                            _showMessageOptions(context, message, isOwn, currentUser.id);
                          }
                        },
                        child: bubble,
                      );
                    }
                    return const SizedBox.shrink();
                  },
                );
              },
            ),
          ),
          if (_replyingTo != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.sm),
              color: AppColors.gray800,
              child: Row(
                children: [
                  const Icon(Icons.reply_rounded, color: AppColors.gray400, size: 20),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text(
                      'Replying to: ${_replyingTo!.decryptedContent}',
                      style: AppTextStyles.bodySm.copyWith(color: AppColors.gray400),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, color: AppColors.gray400, size: 20),
                    onPressed: () => setState(() => _replyingTo = null),
                  ),
                ],
              ),
            ),
          _ChatInputBar(
            controller: _textController,
            onSend: _sendMessage,
            onSendImage: _sendImage,
            onSendVoice: _toggleVoiceRecording,
            onEmojiSelected: _insertEmoji,
            themeColor: themeColor,
            isRecording: _isRecording,
            onChanged: (val) {
              chatService.sendTypingEvent(val.isNotEmpty);
            },
          ),
        ],
      ),
    );
  }
}

// Keep the rest of the widgets (_ChatThemeBar, _OwnBubble, _PartnerBubble, _ChatInputBar) similar but add reactions display

class _OwnBubble extends StatelessWidget {
  const _OwnBubble({
    required this.message,
    required this.time,
    required this.themeColor,
    this.repliedMessage,
  });

  final ChatMessage message;
  final String time;
  final Color themeColor;
  final ChatMessage? repliedMessage;

  @override
  Widget build(BuildContext context) {
    IconData statusIcon = Icons.check_rounded;
    if (message.status == 'delivered') statusIcon = Icons.done_all_rounded;
    if (message.status == 'read') statusIcon = Icons.done_all_rounded;

    return Align(
      alignment: Alignment.centerRight,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.sizeOf(context).width * 0.75,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            if (repliedMessage != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 4.0, right: 8.0),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.gray800,
                    borderRadius: BorderRadius.circular(AppRadius.md),
                  ),
                  child: Text(
                    repliedMessage!.decryptedContent,
                    style: AppTextStyles.bodySm.copyWith(color: AppColors.gray400),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
            Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.lg,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: message.isDeleted ? AppColors.gray800 : themeColor,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(AppRadius.lg),
                      topRight: Radius.circular(AppRadius.lg),
                      bottomLeft: Radius.circular(AppRadius.lg),
                      bottomRight: Radius.circular(4),
                    ),
                  ),
                  child: message.isDeleted
                      ? Text('This message was deleted', style: AppTextStyles.bodyMd.copyWith(color: AppColors.gray400, fontStyle: FontStyle.italic))
                      : (message.type == 'image'
                          ? const Icon(Icons.image_rounded, color: AppColors.white)
                          : message.type == 'voice'
                              ? Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(Icons.mic_rounded, color: AppColors.white, size: 18),
                                    const SizedBox(width: AppSpacing.xs),
                                    _VoiceMessagePlayer(
                                      storageRef: message.decryptedContent,
                                      foregroundColor: AppColors.white,
                                    ),
                                  ],
                                )
                              : Text(
                                  message.decryptedContent,
                                  style: AppTextStyles.bodyMd.copyWith(color: AppColors.white),
                                )),
                ),
                if (message.reactions.isNotEmpty && !message.isDeleted)
                  Positioned(
                    bottom: -10,
                    left: 10,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.gray900,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.gray700),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: message.reactions.values.map((e) => Text(e.toString(), style: const TextStyle(fontSize: 12))).toList(),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(time, style: AppTextStyles.mono),
                const SizedBox(width: AppSpacing.xs),
                Icon(
                  statusIcon,
                  size: 14,
                  color: message.status == 'read' ? AppColors.mint500 : AppColors.gray400,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _PartnerBubble extends StatelessWidget {
  const _PartnerBubble({
    required this.message,
    required this.time,
    required this.initials,
    this.repliedMessage,
  });

  final ChatMessage message;
  final String time;
  final String initials;
  final ChatMessage? repliedMessage;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          AppAvatar(initials: initials, size: AppAvatarSize.sm),
          const SizedBox(width: AppSpacing.sm),
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (repliedMessage != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 4.0, left: 8.0),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.gray800,
                        borderRadius: BorderRadius.circular(AppRadius.md),
                      ),
                      child: Text(
                        repliedMessage!.decryptedContent,
                        style: AppTextStyles.bodySm.copyWith(color: AppColors.gray400),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    GlassCard(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.lg,
                        vertical: 10,
                      ),
                      borderRadius: AppRadius.lg,
                      child: message.isDeleted
                          ? Text('This message was deleted', style: AppTextStyles.bodyMd.copyWith(color: AppColors.gray400, fontStyle: FontStyle.italic))
                          : (message.type == 'image'
                              ? const Icon(Icons.image_rounded, color: AppColors.white)
                              : message.type == 'voice'
                                  ? Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Icon(Icons.mic_rounded, color: AppColors.white, size: 18),
                                        const SizedBox(width: AppSpacing.xs),
                                        _VoiceMessagePlayer(
                                          storageRef: message.decryptedContent,
                                          foregroundColor: AppColors.white,
                                        ),
                                      ],
                                    )
                                  : Text(message.decryptedContent, style: AppTextStyles.bodyMd)),
                    ),
                    if (message.reactions.isNotEmpty && !message.isDeleted)
                      Positioned(
                        bottom: -10,
                        right: 10,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.gray900,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppColors.gray700),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: message.reactions.values.map((e) => Text(e.toString(), style: const TextStyle(fontSize: 12))).toList(),
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(time, style: AppTextStyles.mono),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ChatThemeBar extends StatelessWidget {
  const _ChatThemeBar({
    required this.colors,
    required this.activeTheme,
    required this.onThemeSelected,
  });

  final Map<String, Color> colors;
  final String activeTheme;
  final ValueChanged<String> onThemeSelected;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 36,
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: AppColors.gray700.withValues(alpha: 0.5)),
        ),
      ),
      child: Row(
        children: [
          Text('Theme', style: AppTextStyles.labelSm),
          const SizedBox(width: AppSpacing.md),
          ...colors.entries.map((entry) {
            final active = entry.key == activeTheme;
            return GestureDetector(
              onTap: () => onThemeSelected(entry.key),
              child: Padding(
                padding: const EdgeInsets.only(right: AppSpacing.sm),
                child: Container(
                  width: active ? 20 : 16,
                  height: active ? 20 : 16,
                  decoration: BoxDecoration(
                    color: entry.value,
                    shape: BoxShape.circle,
                    border: active
                        ? Border.all(color: AppColors.white, width: 2)
                        : null,
                    boxShadow: active
                        ? [
                            BoxShadow(
                              color: entry.value.withValues(alpha: 0.5),
                              blurRadius: 8,
                            ),
                          ]
                        : null,
                  ),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}

class _VoiceMessagePlayer extends ConsumerStatefulWidget {
  const _VoiceMessagePlayer({
    required this.storageRef,
    required this.foregroundColor,
  });

  final String storageRef;
  final Color foregroundColor;

  @override
  ConsumerState<_VoiceMessagePlayer> createState() => _VoiceMessagePlayerState();
}

class _VoiceMessagePlayerState extends ConsumerState<_VoiceMessagePlayer> {
  final _player = AudioPlayer();
  bool _isLoading = false;
  bool _isPlaying = false;
  File? _tempFile;

  @override
  void initState() {
    super.initState();
    _player.playerStateStream.listen((state) {
      if (!mounted) return;
      setState(() => _isPlaying = state.playing);
    });
  }

  @override
  void dispose() {
    _player.dispose();
    if (_tempFile != null && _tempFile!.existsSync()) {
      _tempFile!.deleteSync();
    }
    super.dispose();
  }

  Future<void> _toggle() async {
    if (_isPlaying) {
      await _player.pause();
      return;
    }

    if (_tempFile == null) {
      setState(() => _isLoading = true);
      try {
        _tempFile = await ref
            .read(chatServiceProvider)
            .downloadAndDecryptMedia(widget.storageRef, extension: '.m4a');
        await _player.setFilePath(_tempFile!.path);
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
    }

    await _player.seek(Duration.zero);
    await _player.play();
  }

  @override
  Widget build(BuildContext context) {
    return TextButton.icon(
      style: TextButton.styleFrom(
        foregroundColor: widget.foregroundColor,
        padding: EdgeInsets.zero,
        minimumSize: const Size(0, 32),
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
      onPressed: _isLoading ? null : _toggle,
      icon: _isLoading
          ? SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: widget.foregroundColor,
              ),
            )
          : Icon(_isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded),
      label: const Text('Voice message'),
    );
  }
}

class _ChatInputBar extends StatelessWidget {
  const _ChatInputBar({
    required this.controller,
    required this.onSend,
    required this.onSendImage,
    required this.onSendVoice,
    required this.onEmojiSelected,
    required this.themeColor,
    required this.isRecording,
    required this.onChanged,
  });

  final TextEditingController controller;
  final VoidCallback onSend;
  final VoidCallback onSendImage;
  final VoidCallback onSendVoice;
  final ValueChanged<String> onEmojiSelected;
  final Color themeColor;
  final bool isRecording;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.gray900,
        border: Border(
          top: BorderSide(color: AppColors.gray700.withValues(alpha: 0.5)),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            SizedBox(
              width: AppSpacing.minTouchTarget,
              height: AppSpacing.minTouchTarget,
              child: IconButton(
                icon: const Icon(Icons.camera_alt_rounded),
                color: AppColors.gray400,
                onPressed: onSendImage,
              ),
            ),
            SizedBox(
              width: AppSpacing.minTouchTarget,
              height: AppSpacing.minTouchTarget,
              child: IconButton(
                icon: const Icon(Icons.mood_rounded),
                color: AppColors.gray400,
                onPressed: () {
                  showModalBottomSheet<void>(
                    context: context,
                    backgroundColor: AppColors.gray900,
                    builder: (context) => SafeArea(
                      child: Padding(
                        padding: const EdgeInsets.all(AppSpacing.lg),
                        child: Wrap(
                          spacing: AppSpacing.md,
                          runSpacing: AppSpacing.md,
                          children: ['❤️', '😂', '🔥', '🥺', '😍', '😘', '😭', '✨', '💕', '👍', '🥰', '😎']
                              .map(
                                (emoji) => GestureDetector(
                                  onTap: () {
                                    context.pop();
                                    onEmojiSelected(emoji);
                                  },
                                  child: Text(emoji, style: const TextStyle(fontSize: 30)),
                                ),
                              )
                              .toList(),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            Expanded(
              child: TextField(
                controller: controller,
                onChanged: onChanged,
                onSubmitted: (_) => onSend(),
                textInputAction: TextInputAction.send,
                decoration: const InputDecoration(
                  hintText: 'Message...',
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: AppSpacing.lg,
                    vertical: AppSpacing.md,
                  ),
                ),
                maxLines: 4,
                minLines: 1,
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Material(
              color: isRecording ? AppColors.rose500 : AppColors.gray800,
              shape: const CircleBorder(),
              child: SizedBox(
                width: AppSpacing.minTouchTarget,
                height: AppSpacing.minTouchTarget,
                child: IconButton(
                  icon: Icon(
                    isRecording ? Icons.stop_rounded : Icons.mic_rounded,
                    color: AppColors.white,
                  ),
                  onPressed: onSendVoice,
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Material(
              color: themeColor,
              shape: const CircleBorder(),
              child: SizedBox(
                width: AppSpacing.minTouchTarget,
                height: AppSpacing.minTouchTarget,
                child: IconButton(
                  icon: const Icon(Icons.send_rounded, color: AppColors.white),
                  onPressed: onSend,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
