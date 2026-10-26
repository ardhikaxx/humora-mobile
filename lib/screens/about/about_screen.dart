import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../core/theme/app_colors.dart';
import '../../core/constants/app_assets.dart';
import '../../widgets/custom_pill_app_bar.dart';
import '../legal/terms_screen.dart';
import '../legal/privacy_policy_screen.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            CustomPillAppBar(
              title: 'Tentang HUMORA',
              onBackTap: () => Navigator.of(context).pop(),
            ),

            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  children: [
                    const SizedBox(height: 10),

                    // Main App Intro Card
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(22),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: AppColors.border, width: 1.2),
                      ),
                      child: Column(
                        children: [
                          // App Logo Full Rounded (No Yellow Background)
                          ClipOval(
                            child: Image.asset(
                              AppAssets.logoHumora,
                              width: 88,
                              height: 88,
                              fit: BoxFit.cover,
                            ),
                          ),
                          const SizedBox(height: 16),

                          // Version Pill
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppColors.yellowSoft,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: AppColors.primaryYellow, width: 1),
                            ),
                            child: const Text(
                              'VERSI 1.0.0',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                                color: AppColors.primaryPurple,
                                letterSpacing: 0.6,
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),

                          const Text(
                            '“Scroll. laugh. repeat.”',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                              color: AppColors.primaryPurple,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                          const SizedBox(height: 10),

                          const Text(
                            'HUMORA adalah platform streaming digital karya anak bangsa yang didedikasikan untuk menghadirkan video sketsa komedi pendek berkualitas tinggi, dekat dengan keseharian, dan siap menghibur di sela-sela rutinitasmu.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 12.5,
                              color: AppColors.textSecondary,
                              height: 1.45,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Maskot Resmi Card
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFF9E5),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: const Color(0xFFFFE082), width: 1.2),
                      ),
                      child: Row(
                        children: [
                          // Mascot Logo Full Rounded (No Yellow Background)
                          ClipOval(
                            child: Image.asset(
                              AppAssets.logoHumora,
                              width: 50,
                              height: 50,
                              fit: BoxFit.cover,
                            ),
                          ),
                          const SizedBox(width: 14),
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'MASKOT RESMI',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w800,
                                    color: Color(0xFFB45309),
                                    letterSpacing: 0.5,
                                  ),
                                ),
                                SizedBox(height: 2),
                                Text(
                                  'Si Humo — The Laughing Play Button',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                                SizedBox(height: 2),
                                Text(
                                  'Simbol keceriaan dan tawa instan di setiap klik tombol putar.',
                                  style: TextStyle(
                                    fontSize: 11,
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

                    // 3 Stat Counters Row
                    Row(
                      children: [
                        Expanded(
                          child: _buildStatCard('6+', 'Koleksi Video'),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _buildStatCard('24+', 'Video Tayang'),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _buildStatCard('100%', 'Karya Kreator RI'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),

                    // Mengapa Memilih HUMORA? Card
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: AppColors.border, width: 1.2),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Mengapa Memilih HUMORA?',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 16),
                          _buildValueProp(
                            icon: LucideIcons.zap,
                            iconBg: const Color(0xFFFEF3C7),
                            iconColor: const Color(0xFFD97706),
                            title: 'Format Cepat & Ringkas',
                            description: 'Durasi ~+2 menit per video dirancang pas untuk dinikmati saat rehat kerja, perjalanan komuter, atau waktu santai.',
                          ),
                          const SizedBox(height: 14),
                          _buildValueProp(
                            icon: LucideIcons.clapperboard,
                            iconBg: AppColors.accentPurpleSoft,
                            iconColor: AppColors.accentPurple,
                            title: 'Cerita Dekat & Relatable',
                            description: 'Dari drama kos-kosan, romansa kantor, hingga lika-liku kehidupan sehari-hari khas Indonesia yang mengocok perut.',
                          ),
                          const SizedBox(height: 14),
                          _buildValueProp(
                            icon: LucideIcons.shieldCheck,
                            iconBg: const Color(0xFFE6F8F0),
                            iconColor: AppColors.green,
                            title: 'Bebas Iklan Pop-up',
                            description: 'Streaming tanpa interupsi banner iklan yang mengganggu agar fokus menikmati gelak tawa dari awal sampai tamat.',
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Legal Links Card
                    Container(
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: AppColors.borderSubtle, width: 1.0),
                      ),
                      child: Column(
                        children: [
                          _buildLegalItem(
                            context,
                            'Syarat & Ketentuan Layanan',
                            icon: LucideIcons.fileText,
                            onTap: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => const TermsScreen(),
                                ),
                              );
                            },
                          ),
                          const Divider(
                            height: 1,
                            thickness: 0.8,
                            color: AppColors.dividerSubtle,
                            indent: 56,
                            endIndent: 16,
                          ),
                          _buildLegalItem(
                            context,
                            'Kebijakan Privasi',
                            icon: LucideIcons.shieldCheck,
                            onTap: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => const PrivacyPolicyScreen(),
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Footer Copyright
                    const Text(
                      '© 2026 PT Global Mobile Content.',
                      style: TextStyle(
                        fontSize: 11,
                        color: AppColors.textMuted,
                      ),
                    ),
                    const SizedBox(height: 30),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(String value, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border, width: 1.2),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: AppColors.accentPurple,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 10.5,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildValueProp({
    required IconData icon,
    required Color iconBg,
    required Color iconColor,
    required String title,
    required String description,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: iconBg,
            borderRadius: BorderRadius.circular(12),
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
              const SizedBox(height: 2),
              Text(
                description,
                style: const TextStyle(
                  fontSize: 11,
                  color: AppColors.textSecondary,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildLegalItem(
    BuildContext context,
    String title, {
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                icon,
                size: 16,
                color: AppColors.accentPurple,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
            const Icon(
              LucideIcons.chevronRight,
              size: 16,
              color: AppColors.textMuted,
            ),
          ],
        ),
      ),
    );
  }
}
