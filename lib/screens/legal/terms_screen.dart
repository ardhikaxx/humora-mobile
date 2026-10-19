import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../core/theme/app_colors.dart';
import '../../widgets/custom_pill_app_bar.dart';

class TermsScreen extends StatelessWidget {
  const TermsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            CustomPillAppBar(
              title: 'Syarat & Ketentuan',
              onBackTap: () => Navigator.of(context).pop(),
            ),
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 10),

                    // Hero Banner Card
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [
                            AppColors.primaryPurple,
                            Color(0xFF7E22CE),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(22),
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0x205E17EB),
                            blurRadius: 16,
                            offset: Offset(0, 6),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: AppColors.primaryYellow,
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: const Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(LucideIcons.fileText, size: 12, color: AppColors.primaryDark),
                                    SizedBox(width: 4),
                                    Text(
                                      'DOKUMEN HUKUM RESMI',
                                      style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w800,
                                        color: AppColors.primaryDark,
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const Spacer(),
                              const Text(
                                'v1.0 • 2026',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white70,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 14),
                          const Text(
                            'Syarat & Ketentuan Layanan',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w900,
                              color: Colors.white,
                              letterSpacing: -0.3,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Harap membaca ketentuan penggunaan platform HUMORA secara saksama sebelum menikmati konten streaming sketsa komedi kami.',
                            style: TextStyle(
                              fontSize: 12.5,
                              color: Colors.white.withValues(alpha: 0.9),
                              height: 1.4,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Wrap(
                            spacing: 8,
                            runSpacing: 6,
                            children: [
                              _buildMetaTag(LucideIcons.calendar, 'Efektif: 1 Okt 2026'),
                              _buildMetaTag(LucideIcons.building, 'PT Humora Digital Kreatif'),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Quick Highlight Box
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFFBEB),
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: const Color(0xFFFDE68A), width: 1.2),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(LucideIcons.info, size: 20, color: Color(0xFFD97706)),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Poin Inti yang Perlu Diketahui',
                                  style: TextStyle(
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.w800,
                                    color: Color(0xFF92400E),
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Aplikasi HUMORA ditujukan untuk hiburan komedi digital legal. Dilarang mendistribusikan ulang, merekam layar untuk komersial, atau melanggar hak cipta karya kreator.',
                                  style: TextStyle(
                                    fontSize: 11.5,
                                    color: Colors.brown.shade800,
                                    height: 1.35,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Section 1
                    _buildSectionCard(
                      number: '01',
                      icon: LucideIcons.checkCircle,
                      iconBg: const Color(0xFFEEF2FF),
                      iconColor: AppColors.primaryPurple,
                      title: 'Penerimaan Ketentuan',
                      content:
                          'Dengan mengunduh, memasang, mendaftar akun, atau menggunakan aplikasi HUMORA ("Layanan"), Anda menyatakan bahwa Anda telah membaca, memahami, dan menyetujui untuk terikat secara hukum oleh Syarat dan Ketentuan ini. Jika Anda tidak menyetujui salah satu poin di sini, mohon untuk tidak melanjutkan penggunaan Layanan.',
                    ),
                    const SizedBox(height: 12),

                    // Section 2
                    _buildSectionCard(
                      number: '02',
                      icon: LucideIcons.userCheck,
                      iconBg: const Color(0xFFFEF3C7),
                      iconColor: const Color(0xFFD97706),
                      title: 'Pendaftaran Akun & Keamanan',
                      content:
                          'Untuk mengakses fitur tertentu seperti langganan VIP dan interaksi tontonan, Anda perlu membuat akun dengan alamat email yang valid.\n\n'
                          '• Anda bertanggung jawab penuh untuk menjaga kerahasiaan kata sandi dan kredensial akun Anda.\n'
                          '• Segala aktivitas dan transaksi yang terjadi di bawah akun Anda adalah tanggung jawab Anda sepenuhnya.\n'
                          '• Anda setuju untuk segera memberitahukan kami jika menemukan indikasi penggunaan akun tanpa izin.',
                    ),
                    const SizedBox(height: 12),

                    // Section 3
                    _buildSectionCard(
                      number: '03',
                      icon: LucideIcons.film,
                      iconBg: AppColors.accentPurpleSoft,
                      iconColor: AppColors.accentPurple,
                      title: 'Hak Kekayaan Intelektual & Lisensi Konten',
                      content:
                          'Seluruh konten yang tersedia di HUMORA—termasuk serial video komedi, sketsa, audio grafis, nama karakter, maskot "Si Humo", dan logo—merupakan hak milik eksklusif PT Humora Digital Kreatif Indonesia dan kreator mitra kami yang dilindungi undang-undang hak cipta.\n\n'
                          '• Anda diberikan lisensi terbatas, personal, non-eksklusif, dan tidak dapat dipindahtangankan untuk menonton streaming konten HUMORA untuk keperluan pribadi.\n'
                          '• Dilarang keras merekam layar (screen recording), mengunduh secara ilegal, memodifikasi, mempublikasikan ulang (re-upload), atau menyiarkan ulang ke platform lain tanpa persetujuan tertulis resmi dari HUMORA.',
                    ),
                    const SizedBox(height: 12),

                    // Section 4
                    _buildSectionCard(
                      number: '04',
                      icon: LucideIcons.crown,
                      iconBg: const Color(0xFFFEF9C3),
                      iconColor: const Color(0xFFCA8A04),
                      title: 'Langganan VIP & Verifikasi Pembayaran',
                      content:
                          'HUMORA menawarkan paket langganan VIP berbayar (Mingguan, Bulanan, Tahunan) untuk membuka akses katalog video eksklusif tanpa batas.\n\n'
                          '• Pengguna melakukan pembayaran melalui metode resmi (transfer bank / QRIS) dan mengunggah bukti transfer yang valid.\n'
                          '• Verifikasi bukti transaksi dilakukan oleh tim admin HUMORA. Masa aktif paket dihitung sejak status transaksi disetujui.\n'
                          '• Pembayaran yang telah diverifikasi dan paket yang telah aktif bersifat final dan tidak dapat dikembalikan (non-refundable).',
                    ),
                    const SizedBox(height: 12),

                    // Section 5
                    _buildSectionCard(
                      number: '05',
                      icon: LucideIcons.messageSquare,
                      iconBg: const Color(0xFFE0F2FE),
                      iconColor: const Color(0xFF0284C7),
                      title: 'Pedoman Komunitas & Perilaku Pengguna',
                      content:
                          'Kami berkomitmen menjaga ruang hiburan yang menyenangkan, aman, dan inklusif bagi semua orang.\n\n'
                          '• Dilarang mengirimkan komentar yang mengandung ujaran kebencian, diskriminasi SARA, konten pornografi, pelecehan, intimidasi, atau spam promosi komersial.\n'
                          '• HUMORA berhak memoderasi, menghapus komentar, atau menangguhkan akun pengguna yang melanggar norma komunitas tanpa pemberitahuan sebelumnya.',
                    ),
                    const SizedBox(height: 12),

                    // Section 6
                    _buildSectionCard(
                      number: '06',
                      icon: LucideIcons.shieldAlert,
                      iconBg: const Color(0xFFFEE2E2),
                      iconColor: const Color(0xFFDC2626),
                      title: 'Penafian Humor & Batasan Tanggung Jawab',
                      content:
                          'Konten HUMORA adalah karya seni komedi, parodi, dan sketsa fiktif yang murni ditujukan untuk tujuan rekreasi dan hiburan.\n\n'
                          '• Tokoh, nama, tempat, atau alur cerita dalam video adalah fiksi dan dramatisasi satir. Kesamaan dengan kenyataan tidak bermaksud menyinggung pihak mana pun.\n'
                          '• Layanan disediakan "sebagaimana adanya" (as is). HUMORA tidak bertanggung jawab atas kerugian tidak langsung atau gangguan sinyal internet dari penyedia telekomunikasi pengguna.',
                    ),
                    const SizedBox(height: 12),

                    // Section 7
                    _buildSectionCard(
                      number: '07',
                      icon: LucideIcons.refreshCw,
                      iconBg: const Color(0xFFECFDF5),
                      iconColor: AppColors.green,
                      title: 'Perubahan Ketentuan Layanan',
                      content:
                          'HUMORA berhak memperbarui atau memodifikasi Syarat & Ketentuan ini sewaktu-waktu sesuai perkembangan hukum dan peningkatan fitur. Perubahan akan berlaku seketika setelah diterbitkan di aplikasi. Penggunaan berkelanjutan setelah pembaruan menandakan persetujuan Anda terhadap ketentuan yang diperbarui.',
                    ),
                    const SizedBox(height: 16),

                    // Contact Card
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
                          Row(
                            children: const [
                              Icon(LucideIcons.mail, size: 18, color: AppColors.accentPurple),
                              SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Hubungi Tim Hukum HUMORA',
                                  style: TextStyle(
                                    fontSize: 13.5,
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Jika Anda memiliki pertanyaan mengenai Syarat & Ketentuan ini atau ingin melaporkan dugaan pelanggaran lisensi:',
                            style: TextStyle(
                              fontSize: 12,
                              color: AppColors.textSecondary,
                              height: 1.4,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                            decoration: BoxDecoration(
                              color: AppColors.background,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Row(
                              children: [
                                Icon(LucideIcons.atSign, size: 14, color: AppColors.primaryPurple),
                                SizedBox(width: 8),
                                Text(
                                  'legal@humora.id',
                                  style: TextStyle(
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.primaryPurple,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Footer
                    const Center(
                      child: Text(
                        '© 2026 PT Humora Digital Kreatif Indonesia.\nSeluruh hak cipta dilindungi.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 11,
                          color: AppColors.textMuted,
                          height: 1.4,
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetaTag(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 11, color: Colors.white),
          const SizedBox(width: 5),
          Text(
            text,
            style: const TextStyle(
              fontSize: 10.5,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionCard({
    required String number,
    required IconData icon,
    required Color iconBg,
    required Color iconColor,
    required String title,
    required String content,
  }) {
    return Container(
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
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: iconBg,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: iconColor, size: 18),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'PASAL $number',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        color: iconColor,
                        letterSpacing: 0.6,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(height: 1, color: AppColors.border),
          const SizedBox(height: 12),
          Text(
            content,
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.textSecondary,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}
