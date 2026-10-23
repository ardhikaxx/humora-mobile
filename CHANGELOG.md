# 📝 Catatan Perubahan (Changelog)

Semua perubahan penting pada proyek aplikasi **HUMORA Mobile** dicatat secara berkala dalam dokumen ini.

Format pencatatan berpedoman pada [Keep a Changelog](https://keepachangelog.com/id/1.1.0/) dan mengikuti standar [Semantic Versioning (SemVer)](https://semver.org/spec/v2.0.0.html).

---

## [1.3.0] - 2026-10-23

### Ditambahkan (Added)
- **Animasi Kerangka Shimmer Halaman Pencarian (`skeletonizer: ^3.0.0`)**:
  - Implementasi animasi kerangka memuat (*loading shimmer skeleton*) pada halaman Pencarian ([`SearchScreen`](file:///D:/Projek%20Flutter/humora_mobile/lib/screens/search/search_screen.dart)), selaras dengan desain Beranda.
  - Menampilkan shimmer bertingkat pada kartu horizontal Katalog Lengkap dan susunan kartu video Bento Grid (rasio 16:9), menggunakan palet warna shimmer lavender khas HUMORA (`baseColor: #EADBFA`, `highlightColor: #FBF9FD`).
  - Mencegah kedipan tampilan kosong (*empty state flash*) saat data video maupun hasil pencarian sedang diambil.
  - Integrasi tarikan muat ulang maskot ceria [`HumoraMascotRefreshIndicator`](file:///D:/Projek%20Flutter/humora_mobile/lib/widgets/humora_mascot_refresh_indicator.dart) pada halaman pencarian.
- **Notifikasi Mengambang Halus di Sisi Atas Layar (`delightful_toast: ^1.1.0`)**:
  - Implementasi service terpadu [`HumoraToast`](file:///D:/Projek%20Flutter/humora_mobile/lib/widgets/humora_toast.dart) dengan penempatan melayang elegan di bagian atas layar (*top position*), menghilangkan gangguan terhalangnya bilah navigasi bawah (*bottom navigation bar*).
  - Tipe konfirmasi khusus:
    - **Daftar Tonton (Watchlist)**: Notifikasi instan saat serial ditambahkan atau dihapus dari Daftar Tonton (`HumoraToast.showWatchlist`).
    - **Apresiasi Suka (Likes)**: Notifikasi ramah saat serial maupun episode disukai atau batal disukai (`HumoraToast.showLike`).
    - **Penyimpanan & Pengaturan**: Notifikasi pembersihan cache aplikasi dan pembaruan profil pengguna (`HumoraToast.showSuccess`).
  - Fitur gestur usap (*swipe-to-dismiss*), auto-dismiss halus, serta kartu berbayang modern beraksen palet warna HUMORA.
- **Fitur Daftar Tonton (Watchlist)**:
  - Tombol aksi simpan tontonan pada halaman detail serial ([`SeriesDetailScreen`](file:///D:/Projek%20Flutter/humora_mobile/lib/screens/video/series_detail_screen.dart)) dan pemutar video ([`VideoPlayerScreen`](file:///D:/Projek%20Flutter/humora_mobile/lib/screens/video/video_player_screen.dart)).
  - Manajemen state lokal reaktif pada [`SeriesProvider`](file:///D:/Projek%20Flutter/humora_mobile/lib/providers/series_provider.dart).
- **Tarik Layar untuk Muat Ulang Interaktif Maskot "Si Humo" (`custom_refresh_indicator: ^4.0.2`)**:
  - Komponen `HumoraMascotRefreshIndicator` pada Beranda (`HomeScreen`) menggantikan animasi putaran standar.
  - Menampilkan animasi maskot Si Humo (`logo-humora-rounded.png`) yang mengintip ceria dengan rotasi kemiringan dinamis saat ditarik, melompat/bouncing gembira saat proses refresh berlangsung, serta umpan balik getaran haptic (*haptic feedback*) saat status *armed* dan *complete*.
  - Menampilkan badge status informatif: *"Tarik untuk tawa segar..."*, *"Lepas untuk Si Humo! 🎉"*, *"Menyiapkan tawa segar..."*, dan *"Tawa siap disajikan! ✨"*.
- **Splash Screen Native Instan (`flutter_native_splash: ^2.4.4`)**:
  - Konfigurasi splash screen native OS milidetik pertama dengan logo bulat presisi (`logo-humora-rounded.png`) pada Android 12+ dan Android standar, menghilangkan kedipan layar putih saat cold start.

---

## [1.2.0] - 2026-10-20

### Ditambahkan (Added)
- **Fitur Layar Tetap Aktif (`wakelock_plus: ^1.5.2`)**:
  - Implementasi `WakelockService` untuk mencegah layar ponsel meredup atau mengunci otomatis saat memutar serial video sketsa, dan otomatis kembali normal saat video dijeda atau ditutup.
- **Tur Panduan Sorotan Interaktif (`showcaseview: ^5.1.0`)**:
  - Implementasi spotlight walkthrough di Beranda (`HomeScreen`) yang menyorot Logo, Serial Unggulan Hero Card, dan Serial Populer pada pengguna baru.
  - Penyimpanan status selesai melalui `SharedPreferences` agar panduan hanya muncul sekali.
- **Tipografi Adaptif Anti-Overflow (`auto_size_text: ^3.0.0`)**:
  - Integrasi penyesuaian font otomatis pada kartu poster serial (`SeriesPosterCard`), judul hero card, judul episode, badge durasi, dan kartu paket langganan VIP.
- **Mode Picture-in-Picture (`floating: ^6.0.0`)**:
  - Penambahan tombol PiP pada kontrol atas `VideoPlayerScreen` dan konfigurasi `android:supportsPictureInPicture="true"` pada Android Manifest.
  - Komponen `PiPSwitcher` untuk menampilkan video bersih tanpa tombol kontrol saat berada dalam mode melayang.
- **Respon Getaran Interaktif (`vibration: ^3.2.1`)**:
  - Implementasi `VibrationService` yang memberikan sensasi getaran haptic halus (*light impact*) pada tombol Like, Simpan, Play/Pause, PiP toggle, navigasi tab, dan seleksi paket VIP; serta *medium impact* pada perpindahan episode dan pembukaan Paywall.
- **Perbaikan Copywriting Lupa Kata Sandi**:
  - Penyesuaian kalimat penjelasan menjadi ramah orang awam: *"Email Anda akan dicocokkan secara otomatis dengan akun HUMORA yang sudah terdaftar."*

---

## [1.1.0] - 2026-10-18

### Ditambahkan (Added)
- **Deteksi Jaringan Real-Time (`connectivity_plus`)**:
  - Pemantauan status koneksi internet langsung dengan banner notifikasi offline yang ramah dan aksi reload otomatis saat koneksi aktif kembali.
- **Pengelolaan Cache Cerdas (`flutter_cache_manager`)**:
  - Layanan `HumoraCacheService` untuk mengelola penyimpanan sementara poster dan berkas video serial sehingga hemat kuota dan mendukung pemutaran instan.
- **Efek Shimmer Shimmerizer (`skeletonizer`)**:
  - Tampilan loading berkelas saat memuat katalog serial di halaman Beranda.
- **Header Mengambang Presisi (Fixed Floating Header)**:
  - Header beranda yang tetap terlihat dengan efek latar belakang blur saat daftar serial digulir.

---

## [1.0.0] - 2026-10-15

### Ditambahkan (Added)
- Rilis perdana aplikasi mobile HUMORA berbasis Flutter 3.x.
- Navigasi utama dengan 4 tab: Beranda, Cari, Riwayat Tontonan, dan Akun Profil.
- Pemutar video kustom dengan kontrol rasio layar, status durasi, tombol Like, dan daftar episode.
- Sistem otentikasi multi-tier (Guest, Free User, VIP Subscriber).
- Desain antarmuka berstandar palet warna resmi HUMORA (`#43135C`, `#FFD52E`, `#21865B`, `#D94152`).

---

**Yanuar Ardhika Rahmadhani Ubaidillah (@ardhikaxx)**
