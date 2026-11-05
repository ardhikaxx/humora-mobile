import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../core/services/vibration_service.dart';
import '../core/theme/app_colors.dart';
import '../screens/subscription/subscription_plans_screen.dart';

class PaywallModal extends StatelessWidget {
  const PaywallModal({super.key});

  static Future<bool?> show(BuildContext context) {
    VibrationService.mediumImpact();
    return showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const PaywallModal(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: SingleChildScrollView(
        child: Container(
          decoration: const BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Drag Handle
              Container(
                width: 44,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFFD4D4D8),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 8),

              // Close Button
              Align(
                alignment: Alignment.topRight,
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () {
                    VibrationService.lightImpact();
                    Navigator.of(context).pop(false);
                  },
                  child: Container(
                    width: 30,
                    height: 30,
                    decoration: const BoxDecoration(
                      color: Color(0xFFF4F4F5),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      LucideIcons.x,
                      size: 15,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
              ),

          // Crown Icon with Sparkle Badge
          Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                width: 58,
                height: 58,
                decoration: BoxDecoration(
                  color: AppColors.primaryPurple,
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primaryPurple.withValues(alpha: 0.3),
                      blurRadius: 14,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: const Center(
                  child: Icon(
                    LucideIcons.crown,
                    color: AppColors.primaryYellow,
                    size: 30,
                  ),
                ),
              ),
              Positioned(
                top: -3,
                right: -3,
                child: Container(
                  width: 22,
                  height: 22,
                  decoration: const BoxDecoration(
                    color: AppColors.primaryYellow,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    LucideIcons.sparkles,
                    color: AppColors.primaryDark,
                    size: 12,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // HUMORA PREMIUM Pill
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.accentPurpleSoft,
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Text(
              'HUMORA PREMIUM',
              style: TextStyle(
                fontSize: 10.5,
                fontWeight: FontWeight.w800,
                color: AppColors.accentPurple,
                letterSpacing: 0.8,
              ),
            ),
          ),
          const SizedBox(height: 10),

          // Title & Subtitle
          const Text(
            'Ceritanya Belum Selesai!',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
              letterSpacing: -0.4,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Video ini khusus member VIP. Buka akses video serial komedi pilihan Anda.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12.5,
              color: AppColors.textSecondary,
              height: 1.35,
            ),
          ),
          const SizedBox(height: 14),

          // Features Card
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: AppColors.border, width: 1.2),
            ),
            child: Column(
              children: [
                _buildFeatureRow(
                  icon: LucideIcons.playCircle,
                  iconBg: const Color(0xFFFEF3C7),
                  iconColor: const Color(0xFFD97706),
                  title: 'Akses Video Episode VIP',
                  subtitle: 'Nonton episode video serial pilihan tanpa gembok',
                ),
                const SizedBox(height: 10),
                _buildFeatureRow(
                  icon: LucideIcons.clapperboard,
                  iconBg: const Color(0xFFFFF7ED),
                  iconColor: const Color(0xFFEA580C),
                  title: 'Paket Akses & Add-on',
                  subtitle: 'Tersedia paket mingguan 15 video dan add-on kuota',
                ),
                const SizedBox(height: 10),
                _buildFeatureRow(
                  icon: LucideIcons.sparkles,
                  iconBg: const Color(0xFFFCE7F3),
                  iconColor: const Color(0xFFDB2777),
                  title: 'Cerita Baru Tiap Minggu',
                  subtitle: 'Nikmati video terbaru lebih awal',
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Price Banner
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: const Color(0xFFF5F0FC),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Mulai dari',
                  style: TextStyle(
                    fontSize: 12.5,
                    color: AppColors.textSecondary,
                  ),
                ),
                RichText(
                  text: const TextSpan(
                    text: 'Rp15.000 ',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: AppColors.primaryPurple,
                    ),
                    children: [
                      TextSpan(
                        text: '/ 7 hari (15 Video)',
                        style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w500,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // CTA Button
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              onPressed: () {
                VibrationService.mediumImpact();
                Navigator.of(context).pop(true);
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const SubscriptionPlansScreen(),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryDark,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 0,
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Lihat Paket Premium',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  SizedBox(width: 8),
                  Icon(LucideIcons.arrowRight, size: 18),
                ],
              ),
            ),
          ),
          const SizedBox(height: 10),

          // Dismiss Button ("Nanti saja, lanjut jelajahi")
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () {
              VibrationService.lightImpact();
              Navigator.of(context).pop(false);
            },
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 12),
              alignment: Alignment.center,
              child: const Text(
                'Nanti saja, lanjut jelajahi',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary,
                ),
              ),
            ),
          ),
        ],
      ),
    ),
  ),
);
  }

  Widget _buildFeatureRow({
    required IconData icon,
    required Color iconBg,
    required Color iconColor,
    required String title,
    required String subtitle,
  }) {
    return Row(
      children: [
        Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: iconBg,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: iconColor, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 1),
              Text(
                subtitle,
                style: const TextStyle(
                  fontSize: 11,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
