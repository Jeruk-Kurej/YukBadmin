# YukBadmin: status dan konteks project

Terakhir diperbarui: 27 November 2026, oleh Hanzelius (dibantu Claude Code). Sebelumnya oleh Bryan.

Dokumen ini untuk anggota tim atau sesi Claude Code berikutnya yang melanjutkan pekerjaan. Isinya keputusan yang sudah diambil, apa yang sudah jadi, dan apa yang belum.

## 1. Produk

**YukBadmin**: "Your badminton buddy, from your first game to your home club." Tiga peran dalam satu aplikasi:

| Peran | Fungsi |
| --- | --- |
| Pemain | Cari PB yang cocok, tanya pengurus lewat WhatsApp, simpan PB, lihat perlengkapan dan saran |
| Pengurus PB | Daftarkan PB, kelola member, jadwal, kehadiran, iuran, kirim pengingat, impor catatan lama |
| Toko partner | Profil toko dan produk beserta stok, muncul di tab Perlengkapan |

Tim OHEB: Hanzelius (PM), Bryan Carlie L. S. (Software Engineer), Mario Ruby A. (QA), Filemon Jose H. (Backend), Jason Christopher (UI/UX), Anjello Siau (Frontend).

## 2. Keputusan produk (sudah final, jangan diubah tanpa diskusi tim)

- **Tidak ada role admin.** PB hanya komunitas; konten bermasalah dibereskan lewat dashboard database.
- **Satu akun untuk pemain dan pengurus.** Semua masuk sebagai pemain; menu Kelola PB muncul setelah mendaftarkan PB. Toko masuk lewat pintu terpisah di Akun.
- **Gabung PB = menghubungi pengurus lewat WhatsApp.** Tidak ada permintaan gabung di dalam app.
- **Daftar member PB bersifat opt-in** (diubah Hanzelius, 26 November 2026; sebelumnya nama member tidak pernah ditampilkan). Detail PB tetap menampilkan jumlah dan rentang level. Pemain yang menyalakan "Tampilkan profilku ke sesama member" di Akun muncul di daftar member PB beserta profilnya: nama, level, area, hari main, dan gaya main. Jenis member (tetap atau insidental) dan kontak tidak pernah ditampilkan. Pemain yang tidak menyalakannya hanya dihitung ("12 member lain memilih tidak menampilkan profilnya"). Desainnya ada di Figma, halaman "Final Design v2", layar P8c dan P8d. Kode di app belum mengikuti keputusan ini.
- **Level pemain F sampai S** (F baru mulai, S paling mahir).
- **Jenis member: tetap dan insidental.**
- **Iuran dicatat per sesi per orang**, nominal diisi pengurus. App hanya mencatat status bayar dan membantu mengirim pengingat; **tidak ada pembayaran di dalam app.** Sewa lapangan dan shuttlecock di luar app. **Booking lapangan bukan fokus.**
- **Impor catatan** untuk pengurus: teks dari chat atau Sheets diubah jadi daftar member, pengurus memeriksa dulu sebelum disimpan.
- **Saran perlengkapan memakai aturan, bukan AI.** Alasan tiap saran ditampilkan ke pemain (hasil UAT: pemain baru percaya kalau alasannya jelas). Logikanya ada di `lib/features/gear/data/advisor.dart` dan bisa diganti AI nanti tanpa mengubah layar.
- **Stack yang direncanakan:** Flutter + Supabase. Penyedia AI belum dipilih.
- **Cara masuk: Google atau email + kata sandi** (diputuskan Hanzelius, 21 November 2026; sebelumnya hanya Google). Tidak ada Apple atau nomor WhatsApp. Verifikasi email **tidak menahan** pengguna: setelah daftar langsung bisa memakai app, pengingat "Email belum diverifikasi" ada di Akun. Login Google memakai OAuth client dari Google Cloud Console yang disambungkan ke Supabase Auth.
  - Catatan kalau app dirilis ke App Store: aturan 4.8 Apple meminta pilihan masuk yang setara privasinya kalau app memakai login pihak ketiga seperti Google. Untuk tugas kuliah ini tidak masalah; untuk rilis publik, cek lagi apakah perlu "Sign in with Apple".

## 3. Struktur kode

```
lib/
  main.dart                 Titik masuk, membuka cache, tema terang/gelap, router
  app/
    theme.dart              Palet terang dan gelap (YbPalette), warna aktif (YbColors), teks (YbText), radius, tema Material
    theme_mode.dart         Pilihan tampilan: ikuti sistem, terang, gelap
    router.dart             Semua rute (go_router) dan aturan redirect per peran
    tours.dart              Isi tur pemain dan tur pengurus, kunci bagian yang disorot (TourKeys), status tur pemain
  core/data/local_store.dart  Cache lokal (shared_preferences) dan kunci cache
  core/widgets/             Komponen umum: YbCard, YbTag, YbChoiceChip, YbEmptyState, CourtArt,
                            foto (photo.dart: PhotoPicker, YbPhoto, PhotoCircle, PhotoStrip, PhotoGallery),
                            sampul (covers.dart: PbCover, ProductImage),
                            tur (tour.dart: startTour, TourBanner, overlay sorotan)
  features/
    auth/                   Layar Masuk dan Preferensi
    home/                   Beranda pemain dan tab bar pemain
    account/                Halaman Akun (pintu ke Kelola PB dan Kelola toko)
    pb/                     Cari PB, filter, detail PB, tanya pengurus, PB tersimpan, penjelasan level
    club/                   PB-ku: sisi member (jadwal, konfirmasi ikut, Iuranku, bukti transfer)
    manage/                 Semua fitur pengurus PB
    gear/                   Tab Perlengkapan, detail produk, detail toko, saran perlengkapan
    shop/                   Semua fitur toko partner
test/                       widget_test (logika filter), player_flow_test, manage_test, gear_test,
                            map_test, cache_test, photo_test, theme_test, club_test (PB-ku, bukti transfer, pengurus PB),
                            tour_test (tur pemain dan pengurus)
```

Tiap fitur dibagi `data/` (model, repository, logika murni), `state/` (provider Riverpod), dan `pages/` (layar).

**Sumber data saat ini.** Data pengguna disimpan di cache lokal perangkat (`shared_preferences`, lihat `core/data/local_store.dart`), jadi tidak hilang saat app ditutup. Data contoh (PB dan toko seed) tetap di kode. Tiap notifier membaca cache di `build()` dan menyimpan otomatis lewat `listenSelf`. Cache rusak diabaikan supaya app tetap bisa dibuka. Saat Supabase masuk, cache ini bisa diganti tanpa mengubah layar. Tes memakai `MemoryLocalStore` (bawaan `localStoreProvider`).

| Data | Tempat |
| --- | --- |
| PB contoh | `SeedPbRepository` di `pb/data/pb_repository.dart` |
| Toko dan produk contoh | `SeedGearRepository` di `gear/data/gear_repository.dart` |
| PB milik pengguna, member, sesi, iuran, konfirmasi ikut, bukti transfer, pengurus lain | `ManageNotifier` di `manage/state/manage_providers.dart` |
| PB tempat pengguna jadi member (PB-ku) | `MembershipNotifier` di `club/state/club_providers.dart`; data awal dari `SeedMembershipRepository` (akun demo jadi member PB Smash Surabaya). Cache per akun (email) |
| Toko milik pengguna dan produknya | `OwnShopNotifier` di `gear/state/gear_providers.dart` |
| Akun masuk, preferensi, PB tersimpan | `SessionNotifier` (`signInDemo()`, akun contoh), `PreferencesNotifier`, `SavedNotifier` di `pb/state/providers.dart` |
| Pilihan tampilan | `ThemeModeNotifier` di `app/theme_mode.dart` |
| Status tur | `PlayerTourSeenNotifier` di `app/tours.dart`, `ManagerGuideSeenNotifier` (tur pengurus) di `manage/state/manage_providers.dart` |
| Foto | Berkas disalin ke folder dokumen app (`foto/`); model hanya menyimpan path-nya (`logoPath`, `photoPaths`, `photoPath`, `coverPath`) |

## 4. Layar yang sudah jadi

Kode layar Figma ditulis di komentar tiap kelas halaman (misalnya `/// K9 Iuran sesi.`).

| Bagian | Layar | Rute |
| --- | --- | --- |
| Member | PB-ku (P18), halaman PB untuk member: jadwal, konfirmasi ikut, Iuranku, cara bayar (P19, P20) | `/pb-ku`, `/pb-ku/:pbId` |
| Pemain | Masuk (P1), Preferensi (P2), Beranda (P3), Cari PB daftar (P4) dan peta (P5, tombol "Peta"/"Daftar" di tab yang sama), Filter (P6), PB tersimpan (P7), Detail PB (P8+P9 digabung), Tanya pengurus (P10), Akun (P14) | `/masuk`, `/preferensi`, `/beranda`, `/cari`, `/tersimpan`, `/pb/:id`, `/akun` |
| Perlengkapan | Feed (P16), Detail produk (P17), Detail toko (P13), Saran (P11), Hasil saran (P12) | `/perlengkapan`, `/produk/:id`, `/toko/:id`, `/saran` |
| Pengurus | Daftarkan PB 3 langkah (K1–K3), Dashboard (K4), Tur pengurus (baru, bukan dari Figma), Member (K5), Tambah/detail member (K6), Jadwal (K7), Buat sesi (K15), Kehadiran (K8), Iuran sesi (K9) dengan Cek bukti transfer (K19), Kirim pengingat (K10), Impor catatan (K11–K13), Profil PB (K14), Pengurus PB dan Undang pengurus (K17, K18), Lihat sebagai member (K20, K21) | `/daftar-pb`, `/kelola/...` (termasuk `/kelola/pengurus`, `/kelola/lihat-member`), `/member/...`, `/sesi/:id/...`, `/impor` |
| Toko | Daftarkan toko (T1), Profil toko (T2), Produk (T3), Tambah/ubah produk (T4) | `/daftar-toko`, `/toko-saya/...` |

Rute pengurus dan toko dilindungi di `router.dart`: kalau belum punya PB atau toko, pengguna diarahkan ke halaman pendaftarannya.

Semua layar dari Figma sudah dibangun.

### Supabase tahap 1 (27 November 2026)

Project `nbmssaxkvrobuuvttjlf` sudah berisi skema, hak akses, dan data contoh. App memakai Supabase kalau dijalankan dengan `--dart-define-from-file=env/dev.json`; tanpa itu tetap memakai data lokal. Yang sudah lewat Supabase: daftar, masuk, keluar (Supabase Auth), preferensi di tabel `profiles`, daftar PB beserta jadwalnya, serta toko dan produk. Data pengurus dan member masih lokal (tahap 2). **RLS sengaja tidak dipakai** (keputusan tim); risikonya dan cara setup ada di [docs/SUPABASE.md](SUPABASE.md).

### Revisi DEPD: Beranda, tiket, dan toko partner (27 November 2026)

- **Beranda**: sapaan "Halo, … / Siap *smash* minggu ini?" dengan garis lapangan samar, strip angka (sesi 7 hari ke depan, jumlah PB-ku, main bulan ini dari catatan hadir), lalu **Jadwalmu**: tiket semua sesi mendatang dari semua PB-ku, bisa digeser ke samping (`lib/features/club/pages/session_ticket.dart`). Kalau belum ada sesi, muncul keterangan dan tautan ke PB-ku.
- **Latihan rutin** adalah jadwal mingguan PB. Satu PB bisa punya 0, 1, atau lebih sesi per minggu; semuanya kini tampil sebagai tiket, tidak lagi hanya satu sesi dari PB pertama.
- **Tombol ikut disederhanakan**: pasangan besar Ikut/Tidak ikut di Beranda diganti satu tombol kecil "Ikut" atau label status. Batal ikut tetap dari halaman PB-ku (aturan pembatalan dan pengembalian tetap berlaku di sana).
- **Tiket dengan foto PB tipis** dipilih tim; PB tanpa foto memakai garis lapangan.
- **Aksen sporty** di komponen bersama: garis limau di judul seksi, tab aktif biru malam dengan ikon limau.
- **Toko partner dipisah dari pengguna biasa**: peran "Toko partner" di Akun hanya muncul untuk akun yang sudah punya toko. Pengguna lain melihat "Punya toko perlengkapan?" yang meminta **kode undangan** dari tim (`lib/features/shop/data/partner_invite.dart`, kode contoh `MITRA-YB-2026`). Kontak tim menyusul saat rilis.
- Belum dicek di simulator. Tes: 129 lolos, termasuk tiket semua sesi, tombol Ikut, dan kode undangan toko.

### Akun lokal (27 November 2026, revisi DEPD)

Masukan tim: Google selalu masuk sebagai Bryan, email apa pun bisa masuk, verifikasi tidak terkirim, dan preferensi muncul tiap kali masuk. Tim memilih **akun lokal dulu**, Supabase Auth menyusul.

- Akun disimpan di HP (`lib/features/auth/`): daftar menolak email yang sudah ada, masuk menolak email yang belum terdaftar dan kata sandi yang salah, dengan pesan yang menjelaskan. Kata sandi disimpan sebagai hash SHA-256 dengan salt (paket `crypto`), bukan teks asli.
- Akun contoh `bryan@contoh.id` (kata sandi ada di `local_accounts.dart`) tetap ada untuk demo, dan hanya akun ini yang punya data PB-ku contoh.
- "Atur preferensi mainmu" hanya muncul sekali per akun, setelah diisi atau dilewati.
- "Lanjut dengan Google" tidak lagi masuk ke akun contoh; tombolnya memberi tahu bahwa Google menunggu server. Banner "Email belum diverifikasi" di Akun tidak lagi punya tombol "Kirim ulang" yang tidak mengirim apa pun.
- **Bukan pengaman:** akun hanya ada di satu HP dan siapa pun yang memegang HP bisa membuat akun. Google, verifikasi email, dan lupa kata sandi baru bisa dibuat setelah Supabase Auth.
- Tes: `test/auth_test.dart` (9 tes) dan `test/test_helpers.dart`; tes lain masuk lewat form email. 129 tes lolos.

### Final Design v4 di app (27 November 2026, front end saja, belum di-commit)

Acuan tampilan sekarang halaman Figma **"Final Design v4"** (node `654:3932`). Arah desainnya ditulis ulang di [DESIGN.md](DESIGN.md). Data tetap di memori; belum ada Supabase.

- **Tema baru** (`theme.dart`): palet "YukBadmin Warna v3" terang dan gelap (biru malam `#244B76`, hijau limau `#D5E88A`), huruf Inter, radius 8/14/22/pil, token baru `onError`, `onNight`, `pending`, `warning`.
- **Komponen baru** (`yb_widgets.dart`): `YbPageTitle`, `YbSectionTitle`, `YbGroup` + `YbListRow`, `YbSegmented`, `YbTabBar` (pil mengambang), chip terpilih dengan centang, kotak level bulat. `PageHeader` jadi bilah navigasi iOS (kembali, judul tengah, satu aksi). `AmountTile` dihapus.
- **Layar yang dirombak:** Masuk (P1, "Lanjut dengan Google" + "Masuk dengan email"), Beranda (P3), Cari PB (P4), Detail PB (P8), Akun (P14, satu layar untuk pemain, pengurus, dan toko), Bantuan (P26, baru), PB-ku member (P19–P28), Perlengkapan (P16), Dashboard (K4), Member (K5), Jadwal (K7), Iuran (K9), Pembatalan (K24). Layar lain ikut berubah lewat tema.
- **Fitur baru dari v4:**
  - Sistem iuran (K22): bayar sebelum main, setelah main harga tetap, atau dihitung per orang (match + kok), dengan batas pembatalan dan pengingat. Rute `/kelola/sistem-iuran`.
  - Pembatalan dan pengembalian (K24, P23, P25): member batal ikut; kalau sudah bayar dan masih di atas batas jam, uang dikembalikan; kalau lewat batas, member bisa mengajukan dengan alasan; pengurus menyetujui, menolak, atau menandai sudah dikembalikan (dengan "Batalkan"). Rute `/kelola/pembatalan`.
  - Catat pemakaian dan kirim tagihan (K23, K23b, K23c) untuk sistem per orang: per pemain atau per match (4 pemain). Rute `/sesi/:id/pemakaian`, `/sesi/:id/tagihan`. Masuk dari Jadwal ("Pemakaian"), Iuran ("Perlu ditindak"), dan Iuran sesi.
  - Masuk dengan email (P1a): Masuk/Daftar, validasi nama, email, dan kata sandi minimal 8 karakter. Akun baru ditandai belum terverifikasi sampai Supabase Auth dipasang; "Lupa kata sandi" menunggu server. Rute `/masuk/email`.
  - Privasi profil (Akun), tombol "Tanya <pengurus>" di PB-ku.
- **Pindah rute:** Profil PB (`/kelola/profil`) dan Profil toko (`/toko-saya/profil`) sekarang layar dorongan dari Akun, bukan tab. Tab pengurus: Beranda, Member, Jadwal, Iuran, Akun. Tab toko: Produk, Akun.
- **Tur:** ajakan tur tetap di Beranda dan dashboard (gaya v4); tombol "?" di dashboard dan "Tur aplikasi" di Akun mengulang tur. Balon tur pindah ke bawah layar kalau bagian yang disorot terlalu besar.
- **Layar sekunder dicocokkan dengan frame v4** (27 November, lanjutan):
  - Preferensi (P2): tanpa titik progres, "Lewati" berupa teks, hari berupa kotak, label level memakai rentang ("Menengah · D–C"). Rentang mengikuti pembagian di Saran, bukan "D–B"/"A–S" di Figma, supaya sama di semua layar.
  - Filter (P6): kotak level F–S sama lebar, jenis member tiga tombol sama lebar, "Waktu dan hari" digabung, Reset berupa teks.
  - PB tersimpan (P7): bagian baru **"Sudah kamu hubungi"**. App mencatat PB yang dibuka lewat "Buka WhatsApp" (`contactedProvider`, tersimpan di HP). Status balasan pengurus tidak ditampilkan karena tidak bisa diketahui tanpa server.
  - Daftarkan PB (K1–K3): judul besar, bilah progres tiga bagian, langkah 3 menampilkan pratinjau kartu seperti di Cari PB lalu ringkasan yang bisa diketuk untuk mengubah.
  - Kehadiran (K8): ringkasan Dicek hadir / Bilang ikut / Member, daftar berkelompok dengan avatar, tombol "Simpan N hadir" (nonaktif kalau belum ada yang dicentang).
  - Impor catatan (K11, K13): pilihan Chat atau teks / Foto (segera), kartu tips, hasil dalam daftar berkelompok dengan ikon peringatan, "Ulangi dari awal". Pilihan "Poster" digabung ke "Foto (segera)".
  - Saran (P11, P12): pertanyaan bernomor, kotak info, kartu "Paling cocok" dengan skor 3/3, lalu "Pilihan lain". Pertanyaan anggaran dan tinggi/berat di Figma belum dibuat karena aturan saran belum memakainya.
  - Produk toko (T3): judul besar, cari berbentuk pil, daftar berkelompok. Label stok "Ready" diganti "Tersedia". Tombol "Beralih ke mode pemain" dihapus dari Produk dan Profil toko; beralih lewat Akun.
- **Bug yang ikut diperbaiki:** form Daftarkan PB, Masuk dengan email, Tambah member, dan Tambah produk memakai `ListView`, jadi kolom yang belum terlihat tidak ikut divalidasi (nomor WhatsApp kosong bisa lolos). Sekarang memakai `SingleChildScrollView` supaya semua kolom selalu dicek.
- **Tes:** 87 tes lolos, `flutter analyze lib test` bersih. Ditambah tes daftar dengan email dan tes "Sudah kamu hubungi". Belum dicek di simulator.
  - Detail toko (P13): header biru malam dengan logo, nama, dan kecamatan; tombol "Tanya stok via WhatsApp" langsung di bawahnya; Google Maps dan jam buka dalam daftar berkelompok.
  - Detail produk (P17): gambar penuh di atas dengan tombol kembali mengambang, label stok "Tersedia/Habis menurut toko" (stok diisi toko sendiri, jadi tidak diklaim pasti), harga besar, kartu toko, dan catatan "Beli dan cek stok lewat WhatsApp toko".
  - Daftarkan toko (T1) dan Tambah/ubah produk (T4): tombol kembali dan judul besar seperti layar lain; hapus produk memakai ikon merah.
- **Belum:** verifikasi email (M1–M5) dan atur ulang kata sandi menunggu Supabase Auth. Pertanyaan anggaran dan tinggi/berat di Saran belum dibuat. Semua perubahan v4 belum dicek di simulator.

### Pembaruan front end 20–21 November 2026 (menunggu persetujuan tim)

Dikerjakan Hanzelius dengan Claude Code. Fokusnya alur penuh tanpa backend, disesuaikan dengan Figma "Final Design" (`170:2`). Sudah dicoba di simulator iPhone 17 (21 November 2026): peta, pilih pin, "Cari di area ini", Akun, mode gelap, pilih foto dari galeri iOS, dan data tetap ada setelah app dibuka ulang. Layar pengurus dan toko dicek lewat render tes dalam mode terang dan gelap, belum diketuk satu per satu di simulator.

- **Peta PB (P5)**, `pb/pages/map_page.dart` (`PbMapView`). Mengikuti Figma: peta adalah tampilan di tab Cari PB (tombol "Peta" dan "Daftar"), dengan kolom cari dan chip filter yang sama. Pin berikon kok; pin terpilih merah dengan label nama, dan kartu PB muncul di bawah. Setelah peta digeser, tombol "Cari di area ini" menyaring PB di area yang terlihat. Ubin OpenStreetMap lewat `flutter_map`, tanpa kunci API. Tes mematikan ubin lewat `mapTilesEnabledProvider`.
  - Izin `INTERNET` ditambahkan ke manifest Android utama (sebelumnya hanya di debug, jadi build rilis tidak bisa memuat peta dan font Google).
  - Server ubin OpenStreetMap punya batas pemakaian. Aman untuk tugas kuliah; untuk rilis publik pindah ke penyedia ubin dengan kunci sendiri.
  - PB yang didaftarkan lewat app belum punya titik lokasi, jadi tidak muncul di peta (disebut di petunjuk bawah peta). Pin yang berdekatan bisa saling menutupi; belum ada cluster.
- **Tur pemain dan tur pengurus** (menggantikan halaman panduan 5 slide). Lihat "Revisi tampilan" di bawah.
- **Akun (P14)** mengikuti Figma: PB tersimpan, Preferensi main, bagian "Tampilan", dan "Peran lain" (Pemain "Sedang aktif", Pengurus PB "Beralih"/"Daftarkan PB", Toko partner "Masuk"/"Daftarkan toko").
- **Isian dari Figma**: tahun berdiri (K1, K14), pakai tes level (K2, K14; tampil sebagai tag di detail PB), jenis sesi Latihan rutin/Sparing/Main bareng (K15), kartu sesi hari ini bergaris merah (K7).
- **Cache lokal**: lihat "Sumber data saat ini" di atas.
- **Foto tanpa backend** (`image_picker`, disalin ke folder app): logo PB (K1, K14), foto PB sampai 6, foto pertama jadi sampul (K14), galeri di detail PB (P8), foto member (K6), logo dan sampul toko (T1, T2, tampil di P13 dan P17), foto produk (T4, tampil di feed, detail, dan saran). Menghapus foto selalu minta konfirmasi. Kalau akses kamera/galeri ditolak, muncul pesan cara memperbaikinya. Teks izin iOS sudah ada di `Info.plist`.
- **Dark theme**: palet gelap di `YbPalette.dark`. `YbColors` sekarang getter yang membaca palet aktif, jadi **tidak bisa dipakai di dalam `const`**. Saat tema berubah, `YukBadminApp` membangun ulang semua widget tanpa menghilangkan isian. Pilihan "Ikuti sistem / Terang / Gelap" ada di Akun dan tersimpan. Token baru: `night` (latar yang tetap gelap, misalnya hero dashboard), `onAccent` (teks di atas kuning), `warning`/`warningSoft` (pengganti kode warna oranye yang sebelumnya ditulis langsung).

### Revisi tampilan 21 November 2026 (masukan Hanzelius)

- **Kartu PB-ku di Beranda dan PB-ku** (`club/pages/club_pages.dart`). Judul "PB-ku" di luar kartu dengan tautan "Lihat"; di kartu ada kotak tanggal (RAB / 18 / Nov), judul sesi, jam dan nama PB, garis pemisah, lalu **satu ajakan saja** (`clubNextAction`): "Jawab n sesi mendatang", lalu "Bayar n iuran", lalu "n bukti menunggu dicek", lalu "Semua beres".
- **Hasil saran (P12)**. "Berdasarkan" jadi chip, tombol jadi "Ubah", dan kotak penjelasan panjang diganti satu baris "Kenapa saran ini?" yang membuka sheet berisi poin bernomor (judul + satu kalimat). Isi aturannya di `racketMethod`/`shoeMethod` (`gear/data/advisor.dart`), sekarang berbentuk judul dan isi. Keputusan "alasan saran ditampilkan" tetap dipegang.
- **Tur di halaman asli** (`core/widgets/tour.dart`, `app/tours.dart`). Layar digelapkan kecuali bagian yang disorot, balon berisi langkah, judul, satu kalimat, dan tombol Lewati/Lanjut. Tur pindah tab sendiri.
  - **Tur pemain**, dimulai dari kotak "Baru di YukBadmin?" di Beranda atau Akun → "Tur aplikasi": cari PB → filter → saran perlengkapan → PB-ku → berhenti di "Peran lain" dengan ajakan "Punya PB? Daftarkan PB" (atau "Kamu juga pengurus" kalau sudah punya PB).
  - **Tur pengurus**, hanya jalan kalau kotak "Baru jadi pengurus?" di dashboard (atau tombol tanda tanya) diketuk: member → catat kehadiran (atau Buat sesi kalau belum ada sesi) → tab Iuran (tandai lunas, cek bukti, pengingat) → Pengurus PB → Lihat halaman.
  - Status kedua tur disimpan terpisah di cache. Akun dan Profil PB memakai `SingleChildScrollView` (bukan `ListView`) supaya bagian bawahnya bisa disorot.
  - Halaman `ManagerGuidePage` dan rute `/kelola/panduan` dihapus.

### Fitur UAT "menunggu backend", versi tanpa backend (21 November 2026)

Empat revisi UAT yang tadinya menunggu backend sudah dibuat di front end dengan data lokal. Layar dan alurnya sudah final; yang belum hanya sinkron antar-HP (butuh Supabase). Keputusan produk tetap dipegang: gabung PB tetap lewat WhatsApp, nama member lain hanya tampil kalau pemain itu memilih menampilkan profilnya (opt-in, lihat Keputusan produk), dan pembayaran tetap di luar app.

- **Beberapa pengurus per PB** (`manage/pages/managers_page.dart`, K17/K18). Profil PB → "Pengurus PB": pemilik dan pengurus lain, undang lewat WhatsApp (nama + nomor, nomor ganda ditolak), kirim ulang, batalkan/keluarkan dengan konfirmasi. Status "Menunggu diterima" baru bisa jadi "Aktif" setelah ada server.
- **Hanya pengurus yang bisa mengedit.** Tampilan member (`club/pages/club_view.dart`) tidak punya kontrol ubah sama sekali, ada catatan bahwa jadwal dan iuran diatur pengurus. Aturan siapa bisa apa ditampilkan di halaman Pengurus PB; penegakannya nanti lewat Row Level Security.
- **Member melihat jadwal dan konfirmasi ikut.** Pemain: Beranda (kartu PB-ku) dan Akun → PB-ku → halaman PB (P18/P19). Pengurus melihat "Konfirmasi member: x ikut · y tidak ikut" di Jadwal dan dashboard, dan saat mencatat kehadiran yang konfirmasi ikut sudah dicentang (K7, K8).
- **Status iuran terlihat oleh member** (Iuranku): belum bayar, menunggu dicek, ditolak (dengan alasan), lunas. Cara bayar diisi pengurus di Profil PB (isian baru "Cara bayar iuran", `Pb.paymentInfo`).
- **Lunas dari bukti transfer.** Member mengirim foto bukti → pengurus melihat "x bukti transfer menunggu dicek" di dashboard dan tombol "Cek bukti" di Iuran sesi → Setujui (jadi lunas, bisa dibatalkan dari snackbar) atau Tolak dengan alasan (member bisa kirim ulang). Pengecekan manual oleh pengurus; otomatis penuh butuh integrasi bank/pembaca bukti. Yang sudah mengirim bukti tidak ikut dikirimi pengingat.
- **Satu HP, dua sisi.** Karena belum ada server, pengurus bisa membuka "Lihat sebagai member" (dashboard) untuk mencoba sisi member PB-nya sendiri; jawaban dan bukti dari pratinjau tercatat atas nama member itu. PB-ku milik akun demo memakai data contoh PB Smash Surabaya; pengurusnya ada di HP lain, jadi bukti di sana tetap "Menunggu dicek".
- `openWhatsApp` sekarang mengembalikan `false` (bukan melempar galat) kalau WhatsApp tidak bisa dibuka.

### Figma: halaman "Implementasi Nov 2026"

Di file Figma tim ada halaman baru "Implementasi Nov 2026" (node `430:4`) yang memuat semua layar seperti di app sekarang. Halaman "Final Design" tidak diubah.

- Semua 35 layar Final Design disalin dengan susunan baris yang sama. K4 Dashboard diberi kartu "Baru jadi pengurus?" dan tombol panduan, kartu impor memakai teks app. P14 Akun diberi bagian "Tampilan".
- Baris y=5000 (dulu K16 Panduan pengurus): sekarang frame tur, "Tur pemain 1–5" di kiri dan "Tur pengurus 1–5" di kanan. Tiap frame adalah salinan layar asli dengan lapisan gelap, sorotan, dan balon; tombol Lanjut/Lewati/Selesai tersambung.
- Semua layar bisa digulir di prototype. Layar yang punya tab bar atau bar tombol bawah dibagi dua: frame "Konten gulir" (isi, bisa digulir) dan bar di bawahnya dalam alur biasa, bukan melayang, jadi tab bar selalu terlihat. P19 atas/bawah dan K14 bawah sudah digabung ke satu layar.
- **Figma lebih dulu dari app (21 November 2026):** atas permintaan Hanzelius, kotak ajakan tur dihapus dari P3 (Beranda) dan K4 (dashboard), dan jarak antarblok di P3 dirapikan (24 px sebelum judul seksi). Tur pemain dimulai dari Akun → "Tur aplikasi"; tur pengurus dari tombol tanda tanya di dashboard atau menu baru "Tur pengurus" di Profil PB (K14). **App belum disamakan**: di app, `TourBanner` masih tampil di Beranda dan dashboard, dan menu "Tur pengurus" di Profil PB belum ada.
- Set lengkap mode gelap di sebelah kanan (awalan "Gelap ·"), memakai mode variabel "Gelap" yang ditambahkan ke koleksi "YukBadmin Color", beserta variabel baru `night` dan `on-accent`.
- Semua link prototype mengarah ke layar di halaman ini. Ada 14 flow (7 terang, 7 gelap). Chip Tampilan di Akun berpindah antara Akun terang dan gelap.
- Beberapa warna di Final Design masih ditulis langsung, tidak diikat ke variabel (misalnya hero Beranda dan chip filter Peta). Di set gelap sudah diikat; di Final Design belum.
- Isi layar disamakan dengan app per 21 November 2026: K9 iuran per sesi dan bagian "Bayar di muka"; K10 pengingat per penerima (WhatsApp / Salin pesan) tanpa jadwal kirim; K11 impor dari teks; K12 diganti keadaan "Baca foto catatan belum tersedia"; K13 "Periksa hasil"; P11 tanpa tinggi/berat; P12 "Cocok x dari y", alasan, cara saran dibuat, serta senar dan tarikan; K7 tombol Catat kehadiran dan Iuran; K15 isian Buat sesi seperti app; serta teks tombol di P8–P10, P13, P16, P17, K8, dan T2.
- Baris baru "Member dan pengurus" (y=6000), dibuat 21 November 2026 sesuai app: P18 PB-ku, P19 PB-ku atas dan bawah, P20 bukti terkirim, K17 Pengurus PB, K18 Undang pengurus (sheet), K19 Cek bukti transfer (sheet) dan versi menolak, K20 Lihat sebagai member, K21 Pratinjau, K14 Profil PB bagian bawah (cara bayar dan pintu ke Pengurus PB). Layar lama yang ikut berubah: P3 (kartu PB-ku), P14 (menu PB-ku), K4 (kartu bukti transfer, menu Pengurus dan Lihat sebagai member; kartu impor disembunyikan karena PB sudah punya member), K7 (jumlah konfirmasi), K8 (sudah dicentang), K9 (tombol Cek bukti). Set gelap dibuat ulang dari set terang setiap kali set terang berubah.
- Masuk dan daftar, dibuat 21 November 2026 di Figma saja (**app belum**). P1 Masuk punya "Lanjut dengan Google" (gaya resmi Google), "Masuk dengan email", dan tautan "Daftar".
  - **Google (G1–G4, y=8000):** pilih akun → izin (pertama kali saja) → "Masuk…" (pindah otomatis setelah 1,2 detik ke Preferensi) → atau "dibatalkan" kembali ke P1. Ini hanya gambaran alur: di app sungguhan layar pilih akun dan izin dibuat oleh Google, tidak perlu didesain tim (ada catatan di bawah tiap frame).
  - **Masuk dengan email per ketukan (M1–M5, y=8000):** kosong → ketik email (dengan keyboard) → ketik kata sandi → terisi (tombol aktif) → memuat → Beranda. Prototype Figma tidak bisa menerima ketikan sungguhan, jadi mengetik disimulasikan dengan ketukan.
  - **Daftar per ketukan (D1–D8, y=9000):** kosong → nama → email → kata sandi → galat isian ("Format email belum benar", "Kata sandi minimal 8 karakter") → diperbaiki → centang syarat → memuat → Preferensi.
  - **Lainnya (y=7000):** galat "Email atau kata sandi salah", "Email ini sudah terdaftar", Lupa kata sandi, "Cek email kamu", Buat kata sandi baru, dan Akun dengan pengingat "Email belum diverifikasi".
  - Komponen **Keyboard** (properti teks "Aksi": Lanjut/Masuk/Selesai) dipakai di semua layar yang sedang mengetik.
- Catatan perawatan Figma: set gelap dibuat ulang dari set terang (salin, mode "Gelap", petakan warna, sambung ulang link). Setelah itu, lapisan "Latar redup" di set gelap harus diikat ke `night`, bukan `ink`, supaya sheet tetap menggelapkan layar.
- Revisi tampilan 21 November juga sudah di Figma: P3 (ajakan tur, kartu PB-ku baru), P18, P12 (chip, "Kenapa saran ini?", "Ubah"), P14 ("Tur aplikasi"), K4 (ajakan tur), K14 (tombol "Lihat halaman" sesuai app). Sekarang ada 488 link prototype dan 14 flow (7 terang, 7 gelap), termasuk "Pemain: masuk dan daftar", "Tur pemain", "Tur pengurus", dan "Member: PB-ku".
- Satu perbedaan yang tersisa: di app, Buat sesi (K15) adalah sheet di atas Jadwal, sedangkan di Figma tetap satu layar penuh.

### Arah desain baru (22 November 2026)

Tampilan lama dinilai terlalu polos. Arah baru ("sporty energik, tetap hangat") ditulis di [docs/DESIGN.md](DESIGN.md) dan sudah dirujuk dari CLAUDE.md, jadi dibaca sebelum mengubah tampilan. Sumbernya Taste Skill, Web Interface Guidelines dari Vercel (diterjemahkan ke Flutter), dan pola dari DESIGN.md Nike, Airbnb, Spotify; tidak ada skill yang dipasang dan tidak ada identitas merek yang disalin.

- Figma, langsung di halaman **"Implementasi Nov 2026"** (atas permintaan Hanzelius, tidak di halaman terpisah): P1 Masuk, P3 Beranda, P4 Cari PB, P8 Detail PB, K4 Dashboard, dan P14 Akun sudah memakai desain baru, menggantikan versi lamanya di posisi yang sama. Semua link ke layar itu dialihkan, tombol di layar baru disambung ke layar lain seperti sebelumnya, frame tur yang memakai layar itu dibangun ulang, dan set gelap dibuat ulang (518 link, 14 flow).
- Komponen desain baru ada di papan **"Komponen desain baru"** (y=10200, hanya mode terang): tombol pil utama/kedua/gelap, chip aktif/biasa, judul seksi berlabel kapital, papan skor, kartu PB berfoto kecil dan besar, tab bar pemain dan pengurus, gaya efek "Bayangan/Kartu" dan "Bayangan/Lembar".
- **Seluruh halaman Implementasi sudah memakai gaya baru** (22 November 2026): semua tombol jadi pil, chip aktif terbalik (gelap), kartu memakai radius besar dan efek "Bayangan/Kartu", kolom isian `radius/md`, dan semua tab bar lama diganti komponen tab bar baru dengan link yang sama. Isi, alur, dan link dari semua revisi tetap. Kesepuluh frame tur dan Akun "email belum diverifikasi" dibangun ulang dari layar baru. Set gelap dibuat ulang: 554 link, 14 flow, tidak ada link yang keluar halaman. Halaman Lo-Fi, Hi-Fi, dan Final Design tidak disentuh.
- Revisi lanjutan 22 November 2026: chip pilihan di semua layar memakai gaya "terpilih" baru (merah muda, garis merah, tanda centang) dan pasangan chip lama dengan salinan `~aktif` dari prototype UAT digabung jadi satu chip; pilihan 2–3 opsi sama lebar. Tampilan di Akun jadi segmented control (Sistem / Terang / Gelap); tombol di Peran lain sama ukuran. Urutan level di Saran (P11) dibetulkan jadi Baru mulai, Menengah, Mahir, dan ikon Sepatu diganti ikon sepatu. Kategori saran perlengkapan dan chatbot tidak diubah (chatbot menyalahi keputusan "saran memakai aturan, bukan AI"). Set gelap dibuat ulang: 546 link, 14 flow.
- Perbaikan tampilan 24 November 2026 (halaman Implementasi, terang, gelap, dan frame tur ikut diubah lewat nama layer): tombol "Catat kehadiran"/"Iuran" di kartu sesi K7 tidak lagi gepeng (tinggi 41); label "Ready" diganti "Tersedia" di semua layar; sampul toko P13 dan T2 yang masih kotak wireframe diganti sampul `night` berisi foto produk; komponen baru **Tab bar toko** (Profil, Produk, sesuai `ShopShell`) dipasang di T2 dan T3 menggantikan tab bar pemain; baris iuran K9 tidak lagi bergaris tebal dan "Cek bukti" jadi tombol kedua; "Impor dari catatan" di K5 jadi tombol kedua; teks banner saran di P16 dibungkus dua baris; pilihan level di P2 jadi grid 2×2 sama lebar; garis lapangan di hero P3 disamarkan. Sorotan dan balon Tur pengurus 2 dan Tur pemain 3 disesuaikan dengan ukuran baru.
- Catatan teknis Figma: beberapa node merender warna cadangan paint, bukan nilai variabelnya. Saat mengikat warna ke variabel, isi warna cadangan dengan nilai mode terang (bukan hitam) supaya tidak tampil hitam.
- Saat membuat ulang set gelap: lewati papan komponen, jangan ubah warna `ink` di dalam instance komponen (tombol gelap dan chip aktif memang terbalik), dan ikat "Latar redup" ke `night`.
- Arah 22 November ini sudah diganti Final Design v4 (lihat bagian di atas); app tidak memakainya.
- Foto yang dipakai hanya tiga foto GOR yang sudah ada di file. Foto orang bermain belum ada; sebaiknya tim memotret sesi PB sungguhan (dengan izin) daripada memakai foto stok.

## 5. Hasil UAT (9–15 November 2026)

10 penguji (9 pemain, 1 pengurus) di prototype Figma. Rating terendah: Saran AI 3,9, Lihat toko 4,0, Daftarkan PB 4,0.

**Sudah diterapkan di kode:**
- Penjelasan arti level F–S (tombol "Apa arti level?")
- Layar Masuk menjelaskan tujuan app, termasuk "bukan untuk booking lapangan"
- Tombol "Tanya pengurus" berwarna netral, dengan kalimat penenang di sheet-nya
- Kartu "Cocok untukmu?" di detail PB
- Tombol tutup di sheet filter
- Tombol beralih pemain/pengurus/toko yang selalu terlihat
- Petunjuk di tiap langkah pendaftaran PB
- Status lunas bisa dibatalkan (snackbar) dan ada konfirmasi
- Bayar di muka sebelum kehadiran dicatat
- Saran perlengkapan: cara kerja dijelaskan, alasan per kriteria, sepatu ditanya ukuran, pilihan "Belum tahu", saran senar dan tarikan
- Alamat toko lengkap dengan jam buka dan tombol peta

**Tadinya menunggu backend, sekarang sudah ada versi front end** (lihat bagian 4; sinkron antar-HP tetap menunggu Supabase):
- Beberapa owner per PB, dan hanya pengurus yang bisa mengedit
- Member bisa melihat jadwal dan konfirmasi ikut
- Status iuran terlihat oleh member
- Lunas dari bukti transfer (dicek pengurus; otomatis penuh butuh integrasi bank)

**Belum, lainnya:**
- ~~Dark theme~~ (sudah, lihat bagian 4)
- ~~Tutorial singkat untuk pengurus~~ (sudah, lihat bagian 4)
- ~~Unggah foto produk, logo toko, dan foto PB~~ (sudah di perangkat; ke Supabase Storage menunggu backend)

**Sengaja berbeda dari Figma karena keputusan produk:** impor catatan dari teks, bukan foto + AI (K11–K13); saran perlengkapan berbasis aturan dengan alasan, bukan "Cocok 94%" (P12) dan "Tanya AI" (P16); iuran per sesi, bukan baris bulanan (K9); pengingat dikirim langsung, belum bisa dijadwalkan "Besok pagi" (K10, butuh server).

## 6. Langkah berikutnya (urutan yang disarankan)

1. **Supabase.** Buat project (akun Supabase tim terhubung lewat GitHub Bryan, organisasi "Jeruk-Kurej's Org"), rancang tabel (pb, pb_session, pb_manager, member, session_event, attendance, rsvp, due, payment_proof, shop, product), aktifkan Row Level Security per peran, lalu ganti implementasi repository dan notifier supaya membaca dan menulis ke Supabase.
2. **Masuk dengan Google dan email** lewat Supabase Auth, menggantikan `signInDemo()`. Google: buat OAuth client di Google Cloud Console (Android, iOS, dan web client untuk Supabase), lalu isi di Supabase. Email: aktifkan provider email, matikan "Confirm email" supaya pengguna langsung masuk, dan siapkan tautan atur ulang kata sandi (deep link ke layar "Buat kata sandi baru"). Layar masuk dan daftar dengan email sudah ada di app (`/masuk/email`, tanpa server); verifikasi email dan atur ulang kata sandi belum.
3. **Pindahkan foto** dari folder app ke Supabase Storage. Ganti `DevicePhotoPicker` (`core/widgets/photo.dart`) supaya mengunggah dan mengembalikan URL; `YbPhoto` perlu bisa menampilkan URL.
4. **Sambungkan fitur member ke server.** Hubungkan member ke akun (lewat nomor WhatsApp atau undangan), ganti `SeedMembershipRepository` dengan data Supabase, simpan foto bukti transfer di Storage, dan aktifkan undangan pengurus (status "Aktif" saat diterima). Layar PB-ku, Pengurus PB, dan Cek bukti tidak perlu diubah.
5. **Penyedia AI** untuk impor foto catatan dan poster (layar sudah ada, tinggal ganti `NoteParser`).
6. **Lokasi PB** untuk peta: tambahkan isian titik lokasi di pendaftaran dan profil PB, supaya PB baru muncul di peta.

## 7. Cara kerja tim di GitHub

- Repo tim: `https://github.com/Jeruk-Kurej/YukBadmin`. Isinya baru scaffold Flutter (init commit).
- Folder project ini adalah build lengkap di laptop Bryan. Repo tim diisi bertahap per anggota sesuai jadwal di Google Docs tim.
- Branch per nama anggota.
- Pesan commit tanpa atribusi Claude.
