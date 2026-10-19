import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../providers/auth_provider.dart';
import '../../providers/settings_provider.dart';
import '../../widgets/custom_pill_app_bar.dart';
import '../auth/login_screen.dart';

class AccountSettingsScreen extends StatelessWidget {
  const AccountSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>();
    final auth = context.watch<AuthProvider>();

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              CustomPillAppBar(
                title: 'Pengaturan Akun',
                onBackTap: () => Navigator.of(context).pop(),
              ),
              const SizedBox(height: 12),

              // Card 1: Pemutaran Video
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppColors.border, width: 1.2),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildHeaderSection(
                        icon: LucideIcons.tv,
                        iconBg: AppColors.accentPurpleSoft,
                        iconColor: AppColors.accentPurple,
                        title: 'Pemutaran Video',
                        subtitle: 'Atur kenyamanan streaming dan kontrol pemutaran',
                      ),
                      const SizedBox(height: 16),
                      Divider(color: AppColors.border, height: 1),
                      const SizedBox(height: 14),

                      // Putar Otomatis Video
                      _buildSwitchRow(
                        title: 'Putar Otomatis Video',
                        subtitle: 'Lanjut otomatis ke video berikutnya saat pemutaran selesai',
                        value: settings.autoPlayNext,
                        onChanged: (val) => settings.toggleAutoPlay(val),
                      ),
                      const SizedBox(height: 16),

                      // Mode Hemat Kuota
                      _buildSwitchRow(
                        title: 'Mode Hemat Kuota Seluler',
                        subtitle: 'Gunakan resolusi standar 480p saat di jaringan seluler',
                        value: settings.dataSaverMode,
                        onChanged: (val) => settings.toggleDataSaver(val),
                      ),
                      const SizedBox(height: 16),

                      // Kecepatan Putar Default
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Kecepatan Putar Default',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                                SizedBox(height: 2),
                                Text(
                                  'Kecepatan video saat pertama kali dimainkan',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          Row(
                            children: [1.0, 1.25, 1.5].map((speed) {
                              final isSelected = settings.defaultPlaybackSpeed == speed;
                              return GestureDetector(
                                onTap: () => settings.setPlaybackSpeed(speed),
                                child: Container(
                                  margin: const EdgeInsets.only(left: 6),
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 10, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: isSelected
                                        ? AppColors.primaryDark
                                        : const Color(0xFFF4F4F5),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Text(
                                    '${speed}x',
                                    style: TextStyle(
                                      fontSize: 11.5,
                                      fontWeight: FontWeight.w700,
                                      color: isSelected ? Colors.white : AppColors.textSecondary,
                                    ),
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 14),

              // Card 2: Notifikasi
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppColors.border, width: 1.2),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildHeaderSection(
                        icon: LucideIcons.bell,
                        iconBg: const Color(0xFFFEF3C7),
                        iconColor: const Color(0xFFD97706),
                        title: 'Notifikasi',
                        subtitle: 'Pilih pemberitahuan yang ingin kamu terima',
                      ),
                      const SizedBox(height: 16),
                      Divider(color: AppColors.border, height: 1),
                      const SizedBox(height: 14),

                      _buildSwitchRow(
                        title: 'Video & Koleksi Baru',
                        subtitle: 'Dapatkan info rilis video komedi teranyar',
                        value: settings.notifNewReleases,
                        onChanged: (val) => settings.toggleNotifNewReleases(val),
                      ),
                      const SizedBox(height: 16),
                      _buildSwitchRow(
                        title: 'Promo & Langganan VIP',
                        subtitle: 'Pemberitahuan diskon paket dan event spesial',
                        value: settings.notifPromos,
                        onChanged: (val) => settings.toggleNotifPromos(val),
                      ),
                      const SizedBox(height: 16),
                      _buildSwitchRow(
                        title: 'Pengingat Lanjut Nonton',
                        subtitle: 'Ingatkan video yang belum selesai ditonton',
                        value: settings.notifContinueWatch,
                        onChanged: (val) => settings.toggleNotifContinueWatch(val),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 14),

              // Card 3: Penyimpanan & Cache
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppColors.border, width: 1.2),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildHeaderSection(
                        icon: LucideIcons.shield,
                        iconBg: const Color(0xFFE6F8F0),
                        iconColor: AppColors.green,
                        title: 'Penyimpanan & Cache',
                        subtitle: 'Kelola file cache dan data lokal',
                      ),
                      const SizedBox(height: 16),
                      Divider(color: AppColors.border, height: 1),
                      const SizedBox(height: 14),

                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Cache Aplikasi',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Ukuran file cache lokal: ${settings.cacheSizeMb.toStringAsFixed(1)} MB',
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                          GestureDetector(
                            onTap: () {
                              settings.clearCache();
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Cache aplikasi berhasil dibersihkan!'),
                                  backgroundColor: AppColors.primaryDark,
                                ),
                              );
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 14, vertical: 7),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF9F6FC),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: AppColors.border, width: 1),
                              ),
                              child: const Row(
                                children: [
                                  Icon(
                                    LucideIcons.trash2,
                                    size: 14,
                                    color: AppColors.accentPurple,
                                  ),
                                  SizedBox(width: 6),
                                  Text(
                                    'Bersihkan',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.accentPurple,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 14),

              // Card 4: Keamanan Akun
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppColors.border, width: 1.2),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildHeaderSection(
                        icon: LucideIcons.key,
                        iconBg: const Color(0xFFF3E8FF),
                        iconColor: AppColors.accentPurple,
                        title: 'Keamanan Akun',
                        subtitle: 'Kelola kata sandi dan kredensial akun',
                      ),
                      const SizedBox(height: 16),
                      Divider(color: AppColors.border, height: 1),
                      const SizedBox(height: 14),

                      if (auth.isGuest)
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Kamu sedang menggunakan akun Tamu. Masuk untuk mengelola kata sandi dan keamanan akun.',
                              style: TextStyle(
                                fontSize: 12,
                                color: AppColors.textSecondary,
                                height: 1.4,
                              ),
                            ),
                            const SizedBox(height: 12),
                            GestureDetector(
                              onTap: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(builder: (_) => const LoginScreen()),
                                );
                              },
                              child: const Text(
                                'Masuk ke Akun >',
                                style: TextStyle(
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.accentPurple,
                                ),
                              ),
                            ),
                          ],
                        )
                      else
                        const Text(
                          'Kredensial dan sesi login akunmu aktif dan terlindungi dengan enkripsi SHA-256.',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                            height: 1.4,
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Save Button
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Pengaturan berhasil disimpan!'),
                          backgroundColor: AppColors.primaryDark,
                        ),
                      );
                      Navigator.of(context).pop();
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
                        Icon(LucideIcons.save, size: 18, color: AppColors.primaryYellow),
                        SizedBox(width: 8),
                        Text(
                          'Simpan Pengaturan',
                          style: TextStyle(
                            fontSize: 14.5,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeaderSection({
    required IconData icon,
    required Color iconBg,
    required Color iconColor,
    required String title,
    required String subtitle,
  }) {
    return Row(
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: iconBg,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: iconColor, size: 18),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
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

  Widget _buildSwitchRow({
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Row(
      children: [
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
                subtitle,
                style: const TextStyle(
                  fontSize: 11,
                  color: AppColors.textSecondary,
                  height: 1.3,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        Switch.adaptive(
          value: value,
          onChanged: onChanged,
          activeThumbColor: AppColors.accentPurple,
          activeTrackColor: AppColors.accentPurpleSoft,
        ),
      ],
    );
  }
}
