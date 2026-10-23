# 📱 HUMORA — Aplikasi Mobile Streaming Serial Komedi

<p align="center">
  <img src="./assets/logo-humora.png" alt="HUMORA Logo" width="130"/>
</p>

<p align="center">
  <strong>Aplikasi Mobile Streaming Video Serial Sketsa Komedi Vertikal Pendek (~2 Menit)</strong><br>
  <em>"scroll, laugh, repeat"</em>
</p>

<p align="center">
  <a href="https://flutter.dev"><img src="https://img.shields.io/badge/Flutter-3.x-02569B?style=for-the-badge&logo=flutter&logoColor=white" alt="Flutter 3.x"/></a>
  <a href="https://dart.dev"><img src="https://img.shields.io/badge/Dart-3.x-0175C2?style=for-the-badge&logo=dart&logoColor=white" alt="Dart 3.x"/></a>
  <img src="https://img.shields.io/badge/Android-SDK%2021+-3DDC84?style=for-the-badge&logo=android&logoColor=white" alt="Android SDK 21+"/>
  <img src="https://img.shields.io/badge/State-Provider-FF6F00?style=for-the-badge" alt="Provider"/>
  <a href="./LICENSE"><img src="https://img.shields.io/badge/License-Proprietary-43135C?style=for-the-badge" alt="License"/></a>
  <a href="https://github.com/ardhikaxx"><img src="https://img.shields.io/badge/Author-Yanuar%20Ardhika%20Rahmadhani%20Ubaidillah-181717?style=for-the-badge&logo=github&logoColor=white" alt="Author"/></a>
</p>

---

## 📖 Tentang HUMORA Mobile

**HUMORA Mobile** adalah aplikasi pemutar video serial komedi pendek berbasis Flutter yang menghadirkan pengalaman hiburan humor modern berdurasi ringkas (~2 menit per episode). Dirancang dengan antarmuka yang bersih, intuitif, dan responsif, aplikasi ini mengadaptasi kebiasaan scrolling pengguna masa kini agar dapat tertawa kapan saja dan di mana saja.

Aplikasi ini dilengkapi dengan fitur-fitur mutakhir seperti *haptic feedback* interaktif, panduan sorotan pengguna baru (*spotlight walkthrough*), pemutaran video berkecepatan tinggi dengan proteksi layar tetap menyala (*wakelock*), deteksi status jaringan *real-time*, serta manajemen *cache* lokal untuk menghemat kuota internet pengguna.

---

## ⚡ Fitur Utama Aplikasi

### 1. 🎬 Pemutar Video Cerdas & Responsif
* **Pemutaran Vertikal Halus**: Pengalaman menonton serial sketsa yang dioptimalkan untuk rasio layar ponsel (16:9 & 9:16) dengan kontrol gestur sentuh yang responsif.
* **Layar Tetap Menyala (`wakelock_plus`)**: Layar ponsel otomatis dicegah meredup atau terkunci saat video sedang diputar, dan kembali ke setelan tidur normal saat dijeda atau halaman ditutup.

### 2. 📳 Interaksi Haptic Feedback (`vibration`)
* Memberikan respon getaran fisik halus (*haptic feedback*) saat pengguna memberikan tanda Suka (*Like/Hati*), menyimpan ke daftar tontonan (*Bookmark*), mengetuk tombol pemutar, berpindah episode, maupun saat memilih paket langganan VIP.

### 3. 🌟 Panduan Sorotan Interaktif (`showcaseview`)
* Menampilkan tur panduan visual (*interactive spotlight walkthrough*) saat pertama kali pengguna membuka aplikasi untuk memperkenalkan fitur unggulan (Logo Beranda, Serial Unggulan Hero Card, dan Katalog Serial Populer). Status panduan tersimpan otomatis sehingga tidak mengganggu di kemudian hari.

### 4. 🔤 Tipografi Adaptif Anti-Overflow (`auto_size_text`)
* Menyesuaikan ukuran font secara dinamis pada judul serial, sinopsis, nomor episode, dan kartu paket langganan, memastikan teks tidak pernah terpotong (*overflow*) di berbagai ukuran layar ponsel atau saat pengguna mengaktifkan font besar di pengaturan HP.

### 5. 🌐 Penanganan Jaringan & Kuota Pintar
* **Deteksi Jaringan Real-Time (`connectivity_plus`)**: Memantau koneksi internet secara langsung; menampilkan banner peringatan ramah saat offline dan otomatis memuat ulang saat internet kembali terhubung.
* **Manajemen Cache Cerdas (`flutter_cache_manager`)**: Menyimpan sementara data poster dan file video serial yang pernah ditonton agar pengguna dapat memutar ulang (*instant play*) tanpa menghabiskan kuota internet berulang kali.

### 6. ✨ Animasi Loading Berkelas (`skeletonizer`)
* Tampilan efek kilau (*shimmer placeholder*) yang rapi dan elegan saat data katalog sedang dimuat, menggantikan *spinner* melingkar konvensional.

### 7. 👑 Model Akses VIP & Paywall Otomatis
* Episode 1 & 2 dari setiap serial dapat ditonton secara gratis oleh seluruh pengguna (*Free Preview*).
* Episode 3 ke atas secara otomatis dikunci dengan modal *Paywall* premium yang mengarahkan pengguna ke katalog paket langganan VIP (1 Bulan, 3 Bulan, 1 Tahun).

---

## 💻 Prasyarat Lingkungan Pengembangan

Sebelum menjalankan aplikasi mobile, pastikan perangkat pengembang telah terpasang:

| Komponen | Versi Minimal | Keterangan |
| :--- | :--- | :--- |
| **Flutter SDK** | `v3.24.0` atau lebih tinggi | Saluran stabil (*stable channel*) |
| **Dart SDK** | `v3.5.0` atau lebih tinggi | Terpasang otomatis bersama Flutter |
| **Android Studio / VS Code** | Versi terbaru | Dilengkapi plugin Flutter & Dart |
| **Android SDK / NDK** | Min SDK: `21` (Android 5.0), Target SDK: `34` | Emulator atau perangkat fisik Android |

---

## 🚀 Panduan Menjalankan Aplikasi

### 1. Kloning Repositori
```bash
git clone https://github.com/ardhikaxx/humora_mobile.git
cd humora_mobile
```

### 2. Mengunduh Paket Dependensi
```bash
flutter pub get
```

### 3. Memeriksa Kesiapan Perangkat & Simulator
```bash
flutter doctor
flutter devices
```

### 4. Menjalankan Aplikasi di Emulator / Perangkat Nyata
```bash
flutter run
```

### 5. Membangun Berkas APK / App Bundle (Release)
```bash
# Debug APK
flutter build apk --debug

# Production APK
flutter build apk --release
```

---

## 🧪 Pengujian & Analisis Kode

Aplikasi HUMORA Mobile dilengkapi rangkaian pengujian widget dan unit test yang ketat:

```bash
# Menjalankan seluruh rangkaian tes (19+ widget test suites)
flutter test

# Memeriksa standar kode dan linter Flutter
flutter analyze
```

---

## 💖 Dukungan & Donasi

Jika proyek aplikasi **HUMORA Mobile** ini bermanfaat bagi Anda, memberikan inspirasi dalam belajar Flutter, atau membantu mempermudah pengembangan aplikasi streaming Anda, Anda dapat menunjukkan apresiasi dan traktiran kopi (donasi sukarela) kepada pengembang melalui pemindaian kode **QRIS** di bawah ini:

<p align="center">
  <img src="./qris.png" alt="QRIS Donasi Pengembang HUMORA" width="280"/>
</p>

> *Donasi sepenuhnya bersifat sukarela dan tidak mengikat. Seluruh fitur aplikasi HUMORA Mobile tetap dapat dijalankan secara optimal tanpa donasi.*

---

## 📄 Dokumen Pendukung Lainnya

* [`CHANGELOG.md`](./CHANGELOG.md) — Riwayat pembaruan dan penambahan fitur aplikasi mobile.
* [`CITATION.md`](./CITATION.md) — Format sitasi akademik karya.
* [`CODE_OF_CONDUCT.md`](./CODE_OF_CONDUCT.md) — Pedoman etika dan standar komunitas.
* [`CONTRIBUTING.md`](./CONTRIBUTING.md) — Standar kontribusi kode Flutter dan alur kerja Git.
* [`SECURITY.md`](./SECURITY.md) — Kebijakan keamanan aplikasi mobile dan perlindungan privasi.
* [`SUPPORT.md`](./SUPPORT.md) — Kanal bantuan teknis, FAQ, dan dukungan donasi.
* [`LICENSE`](./LICENSE) — Ketentuan lisensi resmi **Proprietary Software License (All Rights Reserved)**.

---

## ⚠️ Ketentuan Penggunaan

Proyek ini dilindungi lisensi **Proprietary Software License (All Rights Reserved)**. Anda **dilarang** menyalin, memodifikasi, mendistribusikan ulang, atau menjual kode ini tanpa izin tertulis dari pemilik hak cipta. Lihat [LICENSE](./LICENSE) untuk detail lengkap.

---

## 👨‍💻 Pengembang & Hak Cipta

Dirancang dan dikembangkan dengan penuh dedikasi oleh:  
**[Yanuar Ardhika Rahmadhani Ubaidillah (@ardhikaxx)](https://github.com/ardhikaxx)**  
*Lead Software Architect & Maintainer*  
Email Resmi: `ardhikayanuar58@gmail.com`

> **Copyright (c) 2026 Yanuar Ardhika Rahmadhani Ubaidillah (@ardhikaxx). All Rights Reserved.**
