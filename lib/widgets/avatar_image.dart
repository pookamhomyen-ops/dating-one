import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class AvatarImage extends StatelessWidget {
  const AvatarImage({
    super.key,
    required this.url,
    this.size = 48,
    this.borderColor,
  });

  final String url;
  final double size;
  final Color? borderColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: borderColor != null
            ? Border.all(color: borderColor!, width: 2)
            : null,
        boxShadow: [
          BoxShadow(
            color: AppColors.textPrimary.withValues(alpha: 0.06),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipOval(
        child: url.isEmpty
            ? ColoredBox(
                color: AppColors.textSecondary,
                child: Icon(Icons.person, size: size * 0.5, color: AppColors.textSecondary),
              )
            : CachedNetworkImage(
                imageUrl: url,
                fit: BoxFit.cover,
                placeholder: (context, url) => ColoredBox(
                  color: AppColors.textSecondary,
                  child: Icon(Icons.person, size: size * 0.5, color: AppColors.textSecondary),
                ),
                errorWidget: (context, url, error) => ColoredBox(
                  color: AppColors.textSecondary,
                  child: Icon(Icons.person, size: size * 0.5),
                ),
              ),
      ),
    );
  }
}
