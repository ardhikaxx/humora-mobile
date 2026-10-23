import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../core/theme/app_colors.dart';
import '../../widgets/custom_pill_app_bar.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            CustomPillAppBar(
              title: 'Kebijakan Privasi',
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
                            Color(0xFF1E1B4B), // Deep navy purple
                            AppColors.primaryPurple,
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
                                  color: const Color(0xFF10B981), // Emerald green
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: const Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(LucideIcons.shieldCheck, size: 12, color: Colors.white),
                                    SizedBox(width: 4),
                                    Text(
                                      'KEPATUHAN UU PDP RI',
                                      style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w800,
                                        color: Colors.white,
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
                            'Kebijakan Privasi HUMORA',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w900,
                              color: Colors.white,
                              letterSpacing: -0.3,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Kami menghargai privasi Anda dan berkomitmen melindungi seluruh data pribadi serta transparan atas izin perangkat yang digunakan.',
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
                              _buildMetaTag(LucideIcons.lock, 'Enkripsi Data SSL/TLS'),
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
                        color: const Color(0xFFECFDF5),
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: const Color(0xFFA7F3D0), width: 1.2),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(LucideIcons.shieldAlert, size: 20, color: Color(0xFF059669)),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Jaminan Keamanan Data',
                                  style: TextStyle(
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.w800,
                                    color: Color(0xFF065F46),
                                  ),
                                ),
                                const SizedBox(height: 4),
                                const Text(
                                  'HUMORA tidak pernah menjual atau memperjualbelikan data pribadi Anda kepada pihak ketiga pengiklan. Seluruh kata sandi dienkripsi dengan standar tinggi.',
                                  style: TextStyle(
                                    fontSize: 11.5,
                                    color: Color(0xFF047857),
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
                      icon: LucideIcons.fileCheck,
                      iconBg: const Color(0xFFEEF2FF),
                      iconColor: AppColors.primaryPurple,
                      title: 'Komitmen Privasi & Landasan Regulasi',
                      content:
                          'PT Humora Digital Kreatif Indonesia ("HUMORA", "kami") mengoperasikan platform streaming video sketsa komedi HUMORA. Dokumen ini menjelaskan pengumpulan, pemrosesan, dan perlindungan data pribadi sesuai amanat Undang-Undang Republik Indonesia Nomor 27 Tahun 2022 tentang Perlindungan Data Pribadi (UU PDP).',
                    ),
                    const SizedBox(height: 12),

                    // Section 2
                    _buildSectionCard(
                      number: '02',
                      icon: LucideIcons.database,
                      iconBg: const Color(0xFFFEF3C7),
                      iconColor: const Color(0xFFD97706),
                      title: 'Data Pribadi yang Kami Kumpulkan',
                      content:
                          'Data yang kami proses meliputi:\n\n'
                          '• Identitas Akun: Nama lengkap, alamat email aktif, kata sandi yang telah di-hash, dan foto profil (avatar) yang Anda sediakan.\n'
                          '• Bukti Transaksi: Foto/berkas struk transfer pembayaran langganan VIP dan nominal pembayaran untuk keperluan verifikasi.\n'
                          '• Riwayat & Preferensi Tontonan: Riwayat video yang ditonton, durasi waktu putar, serial tersimpan (favorit), serta pencarian kata kunci.\n'
                          '• Informasi Teknis: Tipe perangkat, sistem operasi, resolusi layar, serta log crash aplikasi guna menjaga kestabilan sistem.',
                    ),
                    const SizedBox(height: 12),

                    // Section 3
                    _buildSectionCard(
                      number: '03',
                      icon: LucideIcons.sliders,
                      iconBg: AppColors.accentPurpleSoft,
                      iconColor: AppColors.accentPurple,
                      title: 'Penggunaan Izin Native Perangkat (Permissions)',
                      content:
                          'Aplikasi HUMORA hanya meminta perizinan native perangkat yang benar-benar esensial saat dibutuhkan:\n\n'
                          '• Izin Notifikasi (POST_NOTIFICATIONS): Untuk mengirimkan info episode sketsa terbaru, kabar video populer mingguan, update status verifikasi langganan VIP, dan pengingat masa aktif akun.\n'
                          '• Izin Kamera (CAMERA): Digunakan saat Anda memilih untuk mengambil foto struk transfer pembayaran atau foto profil secara langsung melalui kamera.\n'
                          '• Izin Galeri / Foto & Penyimpanan (READ_MEDIA_IMAGES / STORAGE): Digunakan untuk memilih berkas gambar struk pembayaran dari galeri ponsel Anda.\n\n'
                          'Catatan: HUMORA TIDAK PERNAH mengakses kontak, mikrofon, SMS, pelacakan lokasi fisik (GPS), atau berkas pribadi lain di luar perizinan di atas.',
                    ),
                    const SizedBox(height: 12),

                    // Section 4
                    _buildSectionCard(
                      number: '04',
                      icon: LucideIcons.cpu,
                      iconBg: const Color(0xFFE0F2FE),
                      iconColor: const Color(0xFF0284C7),
                      title: 'Tujuan Pemrosesan Data',
                      content:
                          'Kami memproses data Anda semata-mata untuk:\n\n'
                          '1. Menyediakan layanan streaming video komedi tanpa gangguan.\n'
                          '2. Memverifikasi keabsahan pembayaran transaksi langganan VIP.\n'
                          '3. Memfasilitasi alur keamanan akun seperti reset password / lupa sandi.\n'
                          '4. Menampilkan rekomendasi sketsa komedi yang relevan dan menghibur.\n'
                          '5. Meningkatkan performa aplikasi, memperbaiki bug, dan mendeteksi anomali keamanan.',
                    ),
                    const SizedBox(height: 12),

                    // Section 5
                    _buildSectionCard(
                      number: '05',
                      icon: LucideIcons.lock,
                      iconBg: const Color(0xFFECFDF5),
                      iconColor: AppColors.green,
                      title: 'Keamanan & Penyimpanan Data',
                      content:
                          'Kami menerapkan langkah-langkah pengamanan teknis dan organisasi yang ketat:\n\n'
                          '• Seluruh transmisi data dienkripsi dengan protokol aman SSL/TLS (HTTPS).\n'
                          '• Kata sandi Anda dilindungi menggunakan metode hashing satu arah standar industri (tidak pernah disimpan dalam bentuk teks biasa).\n'
                          '• Berkas bukti pembayaran disimpan pada server aman dengan hak akses terbatas yang hanya dibuka oleh staf verifikasi berwenang.',
                    ),
                    const SizedBox(height: 12),

                    // Section 6
                    _buildSectionCard(
                      number: '06',
                      icon: LucideIcons.share2,
                      iconBg: const Color(0xFFFEE2E2),
                      iconColor: const Color(0xFFDC2626),
                      title: 'Pembagian Data kepada Pihak Ketiga',
                      content:
                          'Kami memegang prinsip integritas privasi:\n\n'
                          '• Kami TIDAK PERNAH menjual, mempersewakan, atau membagikan data pribadi Anda kepada broker data atau agensi pihak ketiga manapun.\n'
                          '• Data hanya diproses oleh penyedia infrastruktur cloud berlisensi dan mitra gateway pembayaran resmi untuk operasional sistem.\n'
                          '• Data hanya dapat diungkapkan jika diwajibkan oleh proses hukum yang sah dari otoritas berwenang Republik Indonesia.',
                    ),
                    const SizedBox(height: 12),

                    // Section 7
                    _buildSectionCard(
                      number: '07',
                      icon: LucideIcons.userCheck,
                      iconBg: const Color(0xFFFEF9C3),
                      iconColor: const Color(0xFFCA8A04),
                      title: 'Hak-Hak Pemilik Data Pribadi',
                      content:
                          'Sebagai pemilik data, Anda memiliki hak penuh untuk:\n\n'
                          '• Mengakses dan memperbarui informasi akun Anda secara langsung melalui halaman Pengaturan Akun di aplikasi.\n'
                          '• Mengatur atau mencabut izin notifikasi dan galeri melalui pengaturan sistem perangkat ponsel Anda kapan saja.\n'
                          '• Mengajukan permohonan penonaktifan akun atau penghapusan data dengan menghubungi layanan pelanggan kami.',
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
                                  'Petugas Perlindungan Data (DPO)',
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
                            'Untuk pertanyaan, aspirasi, atau permintaan terkait pengelolaan data pribadi Anda di HUMORA:',
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
                                  'privacy@humora.id',
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
                        '© 2026 PT Humora Digital Kreatif Indonesia.\nPerlindungan Data Pribadi Terjamin.',
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
                      'BAGIAN $number',
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
