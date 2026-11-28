# YukBadmin: panduan untuk Claude Code

File ini dibaca otomatis oleh Claude Code setiap sesi di folder ini. Konteks lengkap (keputusan produk, status, hasil UAT, langkah berikutnya) ada di [docs/PROGRESS.md](docs/PROGRESS.md). Baca file itu dulu sebelum mengerjakan apa pun.

## Tentang project

Aplikasi Flutter (Android dan iOS) untuk mata kuliah DEPD, Universitas Ciputra, Team OHEB. Menghubungkan orang yang baru mau main badminton dengan PB (klub komunitas), membantu pengurus PB mengelola member, kehadiran, dan iuran, serta menampilkan perlengkapan dari toko partner.

Desain referensi (bukan spek kaku): Figma file `tHtwD5zOj78nGucjBPecnc`, halaman "Final Design V5" (node `748:4344`), terutama baris "V5 Final". "Final Design v4" (node `654:3932`) dan "Final Design" lama (node `170:2`) tinggal arsip.

## Perintah

```bash
flutter pub get
flutter analyze
flutter test
flutter run
```

Sebelum menyatakan pekerjaan selesai: `flutter analyze` harus "No issues found!" dan `flutter test` harus lolos semua.

## Aturan kerja

- **Bahasa:** semua teks di app dan komentar kode memakai Bahasa Indonesia yang wajar, bukan bahasa gaul.
- **Jangan menambahkan atribusi Claude** (`Co-Authored-By: Claude`, "Generated with Claude Code", dan sejenisnya) di pesan commit atau PR. Tim tidak mau Claude muncul sebagai contributor.
- **Jangan commit atau push** kecuali pengguna memintanya.
- **Data masih di memori.** Layar hanya membaca lewat provider Riverpod dan antarmuka repository (`PbRepository`, `GearRepository`, `NoteParser`). Saat menyambungkan Supabase, ganti implementasi repository, jangan ubah layar.
- **Pakai komponen yang sudah ada** sebelum membuat yang baru: lihat `lib/core/widgets/yb_widgets.dart` dan `lib/features/manage/pages/manage_widgets.dart` (`PageHeader`, `LabeledField`, `BottomActionBar`, `RoleSwitchButton`, `confirmDestructive`, dll.).
- **Arah desain** ada di [docs/DESIGN.md](docs/DESIGN.md). Baca sebelum mengubah tampilan, di app maupun di Figma.
- **Warna dan teks** hanya dari `lib/app/theme.dart` (`YbColors`, `YbText`, `YbRadius`). Jangan menulis kode warna langsung di layar.
- **Setiap layar baru** butuh: keadaan kosong, keadaan galat, validasi isian dengan pesan yang menjelaskan cara memperbaiki, dan konfirmasi untuk tindakan yang menghapus data.
- **Tes:** tambah tes untuk logika dan alur baru. Ada tes "layar kecil dan teks besar" (320×640, skala teks 1,3) di tiap file tes; pastikan layar baru juga lolos tanpa luberan.

## Jebakan yang sudah diketahui

- **Tes widget:** panggil `pumpAndSettle()` setelah setiap `tap` atau `ensureVisible` sebelum `enterText`. Kalau tidak, ketikan bisa masuk ke kolom yang salah. Item di `ListView` yang belum terlihat belum dibangun, jadi gulir dulu (`scrollUntilVisible` atau `drag`) sebelum mencari teksnya.
- **Folder `build`:** di laptop Bryan, `build` adalah symlink ke luar folder Documents karena iCloud merusak codesign iOS. Kalau `build` di laptopmu berupa symlink yang rusak, hapus saja (`rm build`) lalu jalankan `flutter pub get`.
