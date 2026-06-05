import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_colors.dart';
import '../utils/greeting.dart';

/// ส่วนหัวแบบ Soulive — ใช้ร่วมทุกแท็บ
class SouliveHeader extends StatelessWidget {
  const SouliveHeader({
    super.key,
    this.pageTitle,
    this.showGreeting = false,
    this.showLikesBanner = false,
    this.likesCount = 12,
    this.trailing,
    this.onSettings,
  });

  final String? pageTitle;
  final bool showGreeting;
  final bool showLikesBanner;
  final int likesCount;
  final Widget? trailing;
  final VoidCallback? onSettings;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 12, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Expanded(child: _LogoBlock()),
              if (onSettings != null) ...[
                _HeaderActionButton(
                  icon: Icons.settings_rounded,
                  onTap: onSettings!,
                  filled: true,
                ),
                const SizedBox(width: 4),
              ],
              _HeaderActionButton(
                icon: Icons.notifications_none_rounded,
                onTap: () {},
              ),
            ],
          ),
          if (showGreeting) ...[
            const SizedBox(height: 16),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              timeGreetingTh(),
                              style: const TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.w800,
                                color: AppColors.textPrimary,
                                height: 1.2,
                              ),
                            ),
                          ),
                          const Text(' ✨', style: TextStyle(fontSize: 20)),
                        ],
                      ),
                    ],
                  ),
                ),
                if (showLikesBanner) _LikesBanner(count: likesCount),
              ],
            ),
          ] else if (pageTitle != null) ...[
            const SizedBox(height: 12),
            Text(
              pageTitle!,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
              ),
            ),
          ],
          if (trailing != null) ...[
            const SizedBox(height: 12),
            trailing!,
          ],
        ],
      ),
    );
  }
}

class _HeaderActionButton extends StatelessWidget {
  const _HeaderActionButton({
    required this.icon,
    required this.onTap,
    this.filled = false,
  });

  final IconData icon;
  final VoidCallback onTap;
  final bool filled;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: filled ? AppColors.accentSoft : AppColors.surface,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          width: 44,
          height: 44,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: filled
                ? Border.all(color: AppColors.brandPink.withValues(alpha: 0.25))
                : Border.all(color: AppColors.border),
          ),
          child: Icon(
            icon,
            size: 22,
            color: filled ? AppColors.brandPink : AppColors.textPrimary,
          ),
        ),
      ),
    );
  }
}

class _LogoBlock extends StatelessWidget {
  const _LogoBlock();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Image.asset(
          'assets/logos/logo-text-dating-one.png',
          height: 42,
          fit: BoxFit.contain,
        ),
      ],
    );
  }
}

class _LikesBanner extends StatelessWidget {
  const _LikesBanner({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {},
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.border),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: const BoxDecoration(
                  color: AppColors.accentSoft,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.favorite,
                  size: 16,
                  color: AppColors.heartRed,
                ),
              ),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'คนที่ถูกใจคุณ',
                    style: TextStyle(
                      fontSize: 10,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  Text(
                    '$count คน',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 4),
              const Icon(
                Icons.chevron_right,
                size: 18,
                color: AppColors.textMuted,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
