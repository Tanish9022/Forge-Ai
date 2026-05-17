import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';

enum AppAvatarSize { sm, md, lg, xl }

class AppAvatar extends StatelessWidget {
  const AppAvatar({
    super.key,
    required this.initials,
    this.photoUrl,
    this.size = AppAvatarSize.md,
    this.showOnline = false,
  });

  final String initials;
  final String? photoUrl;
  final AppAvatarSize size;
  final bool showOnline;

  double get _diameter => switch (size) {
        AppAvatarSize.sm => 28,
        AppAvatarSize.md => 40,
        AppAvatarSize.lg => 60,
        AppAvatarSize.xl => 80,
      };

  @override
  Widget build(BuildContext context) {
    final avatar = CircleAvatar(
      radius: _diameter / 2,
      backgroundColor: AppColors.rose500,
      backgroundImage: photoUrl != null ? NetworkImage(photoUrl!) : null,
      child: photoUrl == null
          ? Text(
              initials,
              style: AppTextStyles.labelLg.copyWith(
                color: AppColors.white,
                fontSize: _diameter * 0.35,
              ),
            )
          : null,
    );

    if (!showOnline) return avatar;

    return Stack(
      clipBehavior: Clip.none,
      children: [
        avatar,
        Positioned(
          bottom: 0,
          right: 0,
          child: Container(
            width: _diameter * 0.28,
            height: _diameter * 0.28,
            decoration: BoxDecoration(
              color: AppColors.mint500,
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.gray900, width: 2),
            ),
          ),
        ),
      ],
    );
  }
}
