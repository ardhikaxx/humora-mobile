import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../core/theme/app_colors.dart';

class CustomPillAppBar extends StatelessWidget {
  final String title;
  final bool showBackButton;
  final VoidCallback? onBackTap;
  final Widget? trailing;
  final Widget? leading;
  final Widget? titleWidget;

  const CustomPillAppBar({
    super.key,
    required this.title,
    this.showBackButton = true,
    this.onBackTap,
    this.trailing,
    this.leading,
    this.titleWidget,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 56,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: AppColors.border, width: 1.2),
        boxShadow: const [
          BoxShadow(
            color: Color(0x08000000),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          if (leading != null)
            leading!
          else if (showBackButton)
            GestureDetector(
              onTap: onBackTap ?? () => Navigator.of(context).maybePop(),
              behavior: HitTestBehavior.opaque,
              child: const Padding(
                padding: EdgeInsets.only(right: 12),
                child: Icon(
                  LucideIcons.chevronLeft,
                  color: AppColors.textPrimary,
                  size: 22,
                ),
              ),
            ),
          Expanded(
            child: titleWidget ??
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                    letterSpacing: -0.2,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
          ),
          ?trailing,
        ],
      ),
    );
  }
}
