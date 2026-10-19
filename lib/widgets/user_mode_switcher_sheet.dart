import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';
import '../core/theme/app_colors.dart';
import '../data/models/user_model.dart';
import '../providers/auth_provider.dart';

class UserModeSwitcherSheet extends StatelessWidget {
  const UserModeSwitcherSheet({super.key});

  static void show(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => const UserModeSwitcherSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: const Color(0xFFD4D4D8),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),
          const Row(
            children: [
              Icon(LucideIcons.sliders, size: 20, color: AppColors.primaryDark),
              SizedBox(width: 8),
              Text(
                'Simulasi Mode Pengguna',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          const Text(
            'Pilih status pengguna untuk menguji tampilan & pembatasan akses video:',
            style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 16),
          _buildOption(
            context: context,
            title: '1. Tamu (Guest)',
            subtitle: 'Belum login. Nonton 2 video gratis, episode 3+ terkunci.',
            tier: UserTier.guest,
            icon: LucideIcons.userX,
            color: const Color(0xFF6B7280),
            isSelected: auth.isGuest,
          ),
          const SizedBox(height: 10),
          _buildOption(
            context: context,
            title: '2. User Gratis (Free Tier)',
            subtitle: 'Login tanpa langganan. Episode 1 & 2 gratis, ep 3+ terkunci.',
            tier: UserTier.free,
            icon: LucideIcons.userCheck,
            color: AppColors.green,
            isSelected: auth.isFree,
          ),
          const SizedBox(height: 10),
          _buildOption(
            context: context,
            title: '3. Premium Aktif (VIP)',
            subtitle: 'Langganan 3 Bulan aktif. Seluruh episode terbuka tanpa gembok.',
            tier: UserTier.premium,
            icon: LucideIcons.crown,
            color: AppColors.primaryPurple,
            isSelected: auth.isPremium,
          ),
          const SizedBox(height: 10),
          _buildOption(
            context: context,
            title: '4. Expired (Kedaluwarsa)',
            subtitle: 'Masa aktif habis. Banner jingga di profil, ep premium terkunci.',
            tier: UserTier.expired,
            icon: LucideIcons.alertTriangle,
            color: AppColors.orange,
            isSelected: auth.isExpired,
          ),
        ],
      ),
    );
  }

  Widget _buildOption({
    required BuildContext context,
    required String title,
    required String subtitle,
    required UserTier tier,
    required IconData icon,
    required Color color,
    required bool isSelected,
  }) {
    return GestureDetector(
      onTap: () {
        context.read<AuthProvider>().switchTier(tier);
        Navigator.of(context).pop();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? color.withValues(alpha: 0.08) : AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? color : AppColors.border,
            width: isSelected ? 2.0 : 1.0,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: isSelected ? color : AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
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
            if (isSelected)
              Icon(LucideIcons.checkCircle2, color: color, size: 22),
          ],
        ),
      ),
    );
  }
}
