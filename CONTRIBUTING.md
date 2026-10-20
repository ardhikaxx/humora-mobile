# 🤝 Panduan Kontribusi (Contributing Guidelines)

Terima kasih atas minat Anda untuk berkontribusi pada pengembangan **HUMORA Mobile Application**!

Aplikasi ini dirancang dan dikembangkan dengan standar rekayasa perangkat lunak mobile tingkat tinggi oleh **Yanuar Ardhika Rahmadhani Ubaidillah (@ardhikaxx)**. Agar kualitas dan performa aplikasi tetap prima di berbagai perangkat Android, seluruh kontributor diharapkan mematuhi panduan di bawah ini.

---

## 📌 Ketentuan Kepemilikan & Hak Cipta

1. **Hak Cipta**: Seluruh kode sumber, desain UI/UX, dan aset visual aplikasi ini dilindungi hak cipta atas nama **Yanuar Ardhika Rahmadhani Ubaidillah**.
2. **Karya Orisinal**: Setiap kode yang dikontribusikan wajib merupakan karya orisinal Anda atau bersumber dari pustaka open-source yang memiliki lisensi kompatibel.
3. **Penggabungan Kode**: Dengan mengajukan *Pull Request*, Anda menyetujui kode Anda digabungkan ke dalam basis kode resmi proyek di bawah ketentuan lisensi yang berlaku.

---

## 🛠️ Standar Pengembangan Flutter & Dart

* **Versi Flutter & Dart**: Gunakan Flutter 3.24+ dan Dart 3.5+.
* **Pedoman Gaya Kode**: Patuhi aturan linter resmi pada `analysis_options.yaml` (`package:flutter_lints`).
* **Manajemen State**:
  * Gunakan **Provider** / **ChangeNotifier** yang terstruktur pada folder `lib/providers/`.
  * Pisahkan logika bisnis dari UI widget; widget layar hanya berfokus pada rendering dan interaksi pengguna.
* **Performa & Animasi Mobile**:
  * Hindari *re-rendering* yang tidak perlu dengan memanfaatkan `Consumer`, `Selector`, atau memecah widget menjadi komponen kecil yang konstan (`const`).
  * Pastikan pemutaran video melepaskan sumber daya memori (*dispose*) dengan benar saat berpindah halaman.
  * Lindungi interaksi haptic dan wakelock agar tidak memicu exception saat pengujian headless.
* **Pengujian Mutu (Testing)**:
  * Setiap penambahan fitur baru wajib disertai widget test atau unit test di `test/widget_test.dart`.
  * Jalankan analisis dan pengujian sebelum mengirimkan PR:
    ```bash
    flutter analyze
    flutter test
    ```
    *Seluruh tes harus lulus 100% tanpa warning atau error!*

---

## 🌿 Alur Kerja Git (Git Workflow)

1. **Fork & Clone Repositori**:
   ```bash
   git clone https://github.com/ardhikaxx/humora_mobile.git
   cd humora_mobile
   ```
2. **Buat Branch Fitur Baru**:
   ```bash
   git checkout -b feature/nama-fitur-baru
   # atau
   git checkout -b fix/perbaikan-bug-mobile
   ```
3. **Format Komit Standar (Conventional Commits)**:
   ```text
   feat: tambah mode picture-in-picture pada pemutar video
   fix: perbaiki teks judul agar tidak overflow di layar kecil
   perf: optimasi penggunaan memori cache manajer video
   docs: perbarui panduan kontribusi dan dokumentasi dukungan
   ```
4. **Verifikasi Linter & Build**:
   ```bash
   flutter analyze
   flutter test
   ```
5. **Kirimkan Pull Request (PR)**:
   Sertakan penjelasan rinci mengenai perubahan yang dilakukan, tangkapan layar antarmuka sebelum/sesudah, dan hasil pengujian perangkat nyata/emulator.

---

## 💬 Kanal Komunikasi

* **GitHub Issues**: [https://github.com/ardhikaxx/humora_mobile/issues](https://github.com/ardhikaxx/humora_mobile/issues)
* **Email Resmi**: `ardhikayanuar58@gmail.com`

---

**Yanuar Ardhika Rahmadhani Ubaidillah (@ardhikaxx)**
