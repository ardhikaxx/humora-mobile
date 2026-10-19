import 'package:flutter/material.dart';
import '../core/theme/app_colors.dart';

class InitialsAvatar extends StatelessWidget {
  final String name;
  final String? initials;
  final double size;
  final double fontSize;
  final Color backgroundColor;
  final Color textColor;
  final bool showBorder;

  const InitialsAvatar({
    super.key,
    required this.name,
    this.initials,
    this.size = 44,
    this.fontSize = 15,
    this.backgroundColor = AppColors.primaryPurple,
    this.textColor = AppColors.primaryYellow,
    this.showBorder = true,
  });

  static String computeInitials(String name) {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return 'HU';

    final parts = trimmed.split(RegExp(r'\s+'));
    if (parts.length >= 2) {
      return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
    }
    return trimmed.substring(0, trimmed.length >= 2 ? 2 : 1).toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final displayInitials = (initials != null && initials!.isNotEmpty)
        ? initials!
        : computeInitials(name);

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: backgroundColor,
        shape: BoxShape.circle,
        border: showBorder
            ? Border.all(
                color: textColor.withValues(alpha: 0.6),
                width: 1.5,
              )
            : null,
        boxShadow: const [
          BoxShadow(
            color: Color(0x18000000),
            blurRadius: 6,
            offset: Offset(0, 2),
          ),
        ],
      ),
      alignment: Alignment.center,
      child: Text(
        displayInitials,
        style: TextStyle(
          color: textColor,
          fontSize: fontSize,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}
