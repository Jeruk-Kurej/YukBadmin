# Hasil audit dan perbaikan (27 November 2026)

Dasar: zip YukBadmin berisi Final Design v4. Semua perubahan di bawah ini front end saja. Belum ada backend dan belum ada commit.

## Cara memakai

Pakai folder ini apa adanya, lalu:

```bash
flutter pub get
flutter analyze
flutter test
flutter run
```

Kalau kamu sudah mengubah kode setelah membuat zip lama, jangan menimpa foldermu. Gabungkan perubahannya satu per satu.

## Yang diperbaiki

### Iuran
- Ikut lagi setelah uang dikembalikan sekarang ditagih ulang.
- Batal dua kali tidak lagi membuka pengembalian baru.
- Batal saat bukti transfer menunggu dicek tidak lagi menghapus tagihan dan bukti.
- Iuran per orang: simpan ulang kehadiran tidak menghapus tagihan, pemain yang match-nya dihapus atau tidak hadir tidak ditagih, dan member yang sudah dihapus tidak mendapat tagihan.
- Hapus member tidak lagi menghapus catatan uang yang sudah dibayar.
- "Kirim tagihan otomatis" sekarang berpengaruh. Kalau dimatikan, ada tombol "Tagih N yang hadir" di Iuran sesi dan di "Perlu ditindak".
- Batal mendadak yang uangnya tidak dikembalikan masuk "Terkumpul".
- Iuran yang sedang dalam pengembalian tidak lagi tampil dengan tombol "Lunas".
- Bayar di muka sekarang mencatat waktu bayar.

### Data dan privasi
- Data PB, toko, PB tersimpan, riwayat dihubungi, preferensi, status tur, dan privasi disimpan per akun. Keluar tidak menghapus data. Data dari versi lama dipindahkan ke akun pertama yang membukanya.
- "Tampilkan profilku ke sesama member" mati sejak awal, sesuai keputusan opt-in.
- Hanya akun contoh (`bryan@contoh.id`) yang punya data member contoh. Sebelumnya semua akun baru langsung punya tunggakan.
- Foto dicari lagi berdasarkan nama berkas kalau letak folder app berubah (diuji untuk logika path, belum lewat update app sungguhan).

### Galat dan input
- Mengubah nominal iuran dan memperbaiki baris impor bisa melempar `A TextEditingController was used after being disposed` (dibuktikan lewat tes).
- Tautan WhatsApp dan peta yang gagal dibuka sekarang memunculkan pesan. Tautan Google Maps toko divalidasi.
- Impor: nomor HP dan jam tidak lagi terbaca sebagai nominal atau nama. Baris judul ditandai perlu dicek.
- Kehadiran yang sudah disimpan bisa dikosongkan lagi.
- Peringatan hapus sesi menyebut iuran yang sudah tercatat.

### Tampilan
- Kotak pilihan (hari, ukuran sepatu, level) tidak lagi selebar layar.
- Tombol "Catat kehadiran" di Jadwal tidak lagi terpotong dua baris.
- Lampu ilustrasi lapangan tidak lagi menimpa lencana di kartu PB.
- Label "Terdekat" dihapus karena hanya hiasan. Urutan berdasarkan jarak belum ada.
- Member yang batal tidak lagi diberi label "bayar di muka".

## Aturan yang perlu disetujui tim

Ini pilihan yang dibuat saat memperbaiki. Ubah kalau tim memutuskan lain.

1. Ikut lagi atau hadir setelah uang dikembalikan: ditagih dari awal, dan catatan pengembalian lama di sesi itu diganti (satu member hanya punya satu catatan iuran per sesi). Kalau uang belum dikembalikan, tetap lunas.
2. Batal saat bukti menunggu dicek: bukti tetap bisa dicek dan tidak dihitung tunggakan. Kalau disetujui, pengembalian mengikuti batas jam berdasarkan waktu batal. Kalau ditolak, member bisa kirim ulang dan tidak diingatkan.
3. Hapus member: tagihan belum lunas terhapus, uang yang sudah dibayar atau sedang dikembalikan tetap tercatat. Namanya tidak tampil di daftar iuran per sesi.
4. Data per akun menggantikan "keluar menghapus data".
5. Filter dan urutan "Terdekat" dihilangkan sampai ada lokasi pengguna.

Catatan: Figma "Final Design v4" belum disesuaikan dengan perubahan ini.

## Yang belum aman untuk rilis (menunggu backend)

- Login Google masih tiruan, dan masuk dengan email menerima kata sandi apa pun yang minimal 8 karakter. Data per akun hanya memisahkan tampilan, **bukan pengaman**: siapa pun yang mengetik email yang sama melihat datanya.
- Hak ubah data hanya dijaga UI. Di Supabase wajib pakai Row Level Security, termasuk untuk status lunas dan pengembalian.
- Tidak ada sinkron antar-HP. "Tagihan dikirim" dan bukti transfer hanya tercatat di HP yang sama.
- "Ingatkan yang belum bayar" belum berjalan (layarnya sudah memberi keterangan).
- Daftar member yang opt-in (P8c, P8d) belum dibuat.
- Android release masih ditandatangani kunci debug.
- Peta memakai server ubin OpenStreetMap yang punya batas pemakaian.

## Yang sudah dan belum dicek

- Tes otomatis: 120 tes, termasuk tes baru di `dues_regression_test.dart`, `audit_regression_test.dart`, dan `dialog_test.dart`. `player_flow_test.dart` dan `club_test.dart` disesuaikan, `cache_test.dart` diganti untuk data per akun, `photo_test.dart` ditambah satu tes.
- Dilihat di simulator iPhone 17 Pro: Masuk, Preferensi, Beranda, Cari PB (daftar dan peta), Akun, Daftarkan PB langkah 1, PB-ku, dashboard pengurus, Member, Tambah member, Jadwal, Kehadiran, Iuran sesi, tab Iuran, Pembatalan, Sistem iuran, Profil PB, Pengurus PB, Produk toko, Tambah produk, Detail toko, Perlengkapan, Saran. Mode gelap: dashboard, Iuran sesi, PB-ku.
- Layar pengurus dan toko dibuka lewat data contoh sementara. Sebagian besar hanya dilihat, tombolnya tidak diketuk satu per satu.
- `flutter analyze` seluruh folder bersih. `pembagian_commit/**` dikecualikan lewat `analysis_options.yaml`. Zip di folder itu masih versi 22 November, jadi tidak memuat v4 maupun perbaikan ini.
- Build: iOS simulator (debug) dan Android APK (debug) berhasil. APK belum dijalankan di emulator atau HP.
- Belum dicoba di perangkat atau simulator: kamera dan galeri, membuka WhatsApp, tur, kirim form sampai selesai.
- Kode belum dibaca seluruhnya, jadi audit ini tidak menjamin tidak ada bug lain.
