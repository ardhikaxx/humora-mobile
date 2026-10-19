import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';

class HumoraEmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final String? buttonText;
  final VoidCallback? onButtonPressed;
  final IconData? buttonIcon;
  final double iconSize;
  final double verticalPadding;
  final bool compact;

  const HumoraEmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    this.buttonText,
    this.onButtonPressed,
    this.buttonIcon,
    this.iconSize = 34,
    this.verticalPadding = 40,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: compact ? 16 : 24,
          vertical: compact ? 20 : verticalPadding,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Icon in circular tinted badge
            Container(
              width: compact ? 56 : 74,
              height: compact ? 56 : 74,
              decoration: BoxDecoration(
                color: AppColors.accentPurpleSoft,
                shape: BoxShape.circle,
                border: Border.all(
                  color: AppColors.accentPurple.withValues(alpha: 0.18),
                  width: 2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.accentPurple.withValues(alpha: 0.08),
                    blurRadius: 14,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Center(
                child: Icon(
                  icon,
                  size: compact ? 26 : iconSize,
                  color: AppColors.accentPurple,
                ),
              ),
            ),
            SizedBox(height: compact ? 12 : 16),

            // Header keterangan (Title)
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: compact ? 14 : 16,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
                letterSpacing: -0.2,
              ),
            ),
            SizedBox(height: compact ? 4 : 6),

            // Sub header keterangan (Subtitle / Description)
            ConstrainedBox(
              constraints: BoxConstraints(maxWidth: compact ? 280 : 320),
              child: Text(
                subtitle,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: compact ? 12 : 13,
                  fontWeight: FontWeight.w400,
                  color: AppColors.textSecondary,
                  height: 1.45,
                ),
              ),
            ),

            // Action Button (Optional)
            if (buttonText != null && onButtonPressed != null) ...[
              SizedBox(height: compact ? 12 : 18),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 220),
                child: ElevatedButton(
                  onPressed: onButtonPressed,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.accentPurple,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: EdgeInsets.symmetric(
                      horizontal: compact ? 12 : 16,
                      vertical: compact ? 7 : 9,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(24),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (buttonIcon != null) ...[
                        Icon(buttonIcon, size: 14, color: AppColors.primaryYellow),
                        const SizedBox(width: 6),
                      ],
                      Flexible(
                        child: Text(
                          buttonText!,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
