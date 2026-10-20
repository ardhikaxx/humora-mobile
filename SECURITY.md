# 🛡️ Kebijakan Keamanan (Security Policy)

Keamanan aplikasi mobile, integritas transmisi data streaming, serta perlindungan privasi pengguna merupakan fondasi terpenting dalam pengembangan **HUMORA Mobile Application**.

Aplikasi ini dirancang dengan mematuhi prinsip-prinsip *Mobile Application Security Verification Standard (MASVS)*, panduan resmi Google Play Security, serta **Undang-Undang Perlindungan Data Pribadi (UU PDP No. 27 Tahun 2022)**.

---

## 📦 Versi yang Didukung Pembaruan Keamanan

Pembaruan keamanan dan perbaikan celah aktif dipelihara untuk versi rilis berikut:

| Versi | Status Keamanan |
| :--- | :--- |
| **v1.2.x** | ✅ **Didukung Penuh** (*Active Security Support*) |
| **v1.1.x** | ⚠️ Patch Kritis Saja |
| < 1.1.0 | ❌ Tidak Didukung |

---

## 🔒 Lapisan Keamanan Aplikasi Mobile

1. **Penyimpanan Lokal Terproteksi (Secure Local Storage)**:
   * Token sesi autentikasi dan status pengguna disimpan secara terenkripsi menggunakan mekanisme penyimpanan aman perangkat (SharedPreferences berizin privat).
   * Data sensitif seperti kata sandi tidak pernah disimpan dalam bentuk teks biasa (*plaintext*) pada memori perangkat.
2. **Komunikasi Jaringan Aman (Network Security)**:
   * Seluruh pertukaran data API dan streaming berkas video diarahkan melalui protokol aman **HTTPS / TLS 1.3**.
   * Penanganan *man-in-the-middle (MitM)* dan sanitasi input form untuk mencegah injeksi payload berbahaya ke server backend.
3. **Isolasi Izin Perangkat (Permission Sandboxing)**:
   * Aplikasi hanya meminta izin perangkat yang relevan secara minimal (*principle of least privilege*), seperti getaran haptic (`android.permission.VIBRATE`) dan penjaga layar aktif (`android.permission.WAKE_LOCK`).
   * Tidak ada akses ke lokasi pengguna, kontak, mikrofon, atau SMS yang tidak diperlukan oleh pemutar video.
4. **Isolasi Cache & Pembersihan Memori**:
   * Pengelolaan berkas cache video dan gambar diisolasi dalam direktori cache aplikasi khusus (`humora_video_cache`), serta menyediakan tombol pembersihan cache mandiri pada menu Akun Pengguna.
5. **Kepatuhan Privasi Data Pribadi (UU PDP No. 27 Tahun 2022)**:
   * Hak privasi pengguna dihormati dengan menyediakan opsi pengaturan akun, penghapusan riwayat tontonan, dan keterbukaan transparansi penggunaan data pada halaman Kebijakan Privasi di dalam aplikasi.

---

## 🚨 Pelaporan Celah Keamanan (Vulnerability Reporting)

Jika Anda menemukan kerentanan keamanan (*security vulnerability*) atau bug berisiko tinggi pada aplikasi HUMORA Mobile, mohon untuk **TIDAK mempublikasikannya secara terbuka** di forum atau media sosial publik.

Silakan sampaikan temuan Anda secara etis (*responsible disclosure*) ke:

* **Email Resmi Keamanan**: `ardhikayanuar58@gmail.com`
* **Subjek Email**: `[SECURITY] Laporan Kerentanan HUMORA Mobile - (Deskripsi Singkat)`

### Harap Sertakan:
1. Deskripsi potensi risiko kerentanan.
2. Langkah-langkah detail untuk mereproduksi celah (*proof of concept*).
3. Informasi perangkat (merek ponsel, versi Android/iOS, versi aplikasi HUMORA).
4. Usulan perbaikan atau mitigasi teknis jika memungkinkan.

Tim pengembang akan merespons dalam waktu **1x24 jam** dan segera merilis pembaruan perbaikan (*hotfix*) demi melindungi seluruh pengguna.

---

**Yanuar Ardhika Rahmadhani Ubaidillah (@ardhikaxx)**  
*Lead Software Architect & Security Maintainer*
