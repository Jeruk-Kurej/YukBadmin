# YukBadmin: arah desain

Dibaca sebelum mengubah tampilan, di app (Flutter) maupun di Figma. Acuan sejak 28 November 2026 adalah halaman Figma **"Final Design V5"** (node `748:4344`), terutama baris "V5 Final" (Beranda, Cari PB, Perlengkapan, Akun, Riwayat transaksi, Notifikasi, terang dan gelap). "Final Design v4" (node `654:3932`) tinggal arsip.

## 1. Arah: sporty dan hidup, tetap jelas

UAT menilai tampilan v4 terlalu polos. V5 memberi energi olahraga tanpa mengorbankan kejelasan: YukBadmin tetap dipakai di sela urusan lain (cek jadwal, konfirmasi ikut, kirim bukti transfer).

- **Hero biru malam di atas layar tab.** Beranda dan Akun memakai hero dengan tepi bawah melengkung seperti busur (`YbArcHero`); Cari PB, Perlengkapan, dan layar dorongan memakai kepala biru malam dengan lembar terang bersudut atas melengkung (`YbSheetHeader`).
- **Limau sebagai aksen yang jelas:** tombol utama di hero, tab aktif, label sorotan di kartu PB, garis miring di pojok hero. Kartu dan tiket diketuk seluruhnya, tanpa tombol panah atau tombol kecil di dalamnya. Di luar hero, limau tetap hemat.
- **Judul dan angka tebal miring** (`YbText.hero`, `YbText.score`) seperti papan skor.
- **Daftar berkelompok** untuk menu, pengaturan, dan daftar orang.
- **Privasi di depan:** jumlah yang ikut ditampilkan sebagai ikon orang tanpa nama.

## 2. Warna

Hanya dari `YbColors` di `lib/app/theme.dart` (variabel Figma "YukBadmin Warna v3", mode Terang dan Gelap). Tidak ada kode warna langsung di layar.

| Peran | Token app | Terang | Gelap | Aturan |
| --- | --- | --- | --- | --- |
| Latar halaman | `bg` | #F7F7F2 | #101820 | |
| Kartu | `surface` | #FFFFFF | #1C2835 | |
| Teks | `ink`, `muted` | #192533, #526173 | #F0F3F6, #BCC8D4 | `muted` hanya keterangan, minimal 12 px |
| Aksi utama | `primary`, `onPrimary` | #244B76, putih | #A9C8EF, #10263E | Tombol utama, tautan, pilihan aktif. Teks di atasnya selalu `onPrimary`, bukan `Colors.white` |
| Pilihan | `primarySoft` | #E4EEF9 | #2C425C | Latar chip terpilih |
| Garis | `control`, `line` | #6A7888, #E2E5E9 | #8592A2, #2C3846 | `control` untuk kolom isian dan tombol kedua |
| Kartu gelap | `night`, `onNight` | #13283F, putih | sama | Hero dan kepala halaman. Sama di kedua mode |
| Merek | `YbBrand.nightRaised`, `nightGlow`, warna bulu logo | #1E3A5C, #244B76 | sama | Chip dan panel di atas hero, logo |
| Sorotan | `accent`, `onAccent`, `accentSoft` | #D5E88A | #D5E88A | Satu sorotan per layar |
| Status | `success`, `warning`, `error`, `pending` + `…Soft` | | | Hanya untuk arti. Teks di atas `error` memakai `onError` |

Dilarang: ungu, gradasi warna-warni, teks bergradasi, `Colors.white` di atas `primary` atau `error` (di mode gelap keduanya terang).

## 3. Tipografi

Satu keluarga huruf: **Inter** (`google_fonts`).

- `YbText.hero`: judul hero dan nama PB di kartu, Inter 800 miring (34 di Beranda, 32 judul layar tab, 22 nama PB).
- `YbText.display`: judul seksi 20 semi tebal, judul kartu 17–18, judul layar dorongan 22.
- `YbText.score`: angka papan skor (tanggal, jam sesi), Inter 800 miring dengan angka tabular.
- `YbText.body`: isi 15, keterangan 13 `muted`.
- Tombol 16 semi tebal, kalimat biasa. Angka format Indonesia ("Rp150.000"), elipsis "…".

## 4. Bentuk dan jarak

- Tepi layar 16 px. Jarak antarseksi 24–28 px, judul seksi ke isinya 10 px.
- Radius: `sm` 8, `md` 14 (kolom isian, kotak tanggal), `lg` 22 (kartu, daftar berkelompok, sheet), `pill` (tombol, kolom cari, tab bar).
- Kartu tanpa garis tepi; kedalaman dari beda warna `surface` dan `bg`. Bayangan hanya untuk hero berbusur dan chip pintasan di tepinya.
- Hero berbusur: selisih tinggi sisi dan tengah busur 26–34 px. Lembar terang: sudut atas 28 px.
- Area ketuk minimal 44 × 44 px.

## 5. Komponen (di `yb_widgets.dart` dan `manage_widgets.dart`)

- **`YbLogo` / `YbLogoMark`** (`yb_brand.dart`): logo kok lima bulu (biru malam, dua biru, dua limau), sama dengan komponen "V5 / Logo" di Figma. `onDark: true` di atas biru malam.
- **`YbArcHero`**: hero biru malam berbusur dengan garis lapangan samar dan garis miring limau. Dipakai Beranda (logo, sapaan, judul, area + Cari PB, pintasan `YbHeroChip` di tepi busur) dan Akun (profil, panel Level dan Mode).
- **`YbSheetHeader`**: kepala biru malam dengan lembar terang melengkung di bawahnya (Cari PB, Perlengkapan, Riwayat transaksi, Notifikasi). Tombol ikon di atasnya memakai `YbNightIconButton`.
- **`YbPageTitle`**: judul besar 32 di layar tanpa hero, dengan subjudul dan satu tombol bulat 44 di kanan.
- **`PageHeader`**: bilah navigasi layar dorongan: tombol kembali bulat, judul 17 di tengah, satu aksi teks di kanan (misalnya "Simpan", "Lihat").
- **`YbGroup` + `YbListRow`**: daftar berkelompok. Baris: ikon dalam lingkaran atau avatar, judul, subjudul, lalu tag atau panah.
- **`YbSectionTitle`**: judul seksi 20 dengan tautan opsional di kanan, tanpa garis aksen.
- **`YbSegmented`**: pilihan 2–3 opsi tetap (Ikut/Tidak ikut, Mendatang/Riwayat, Masuk/Daftar, Sistem/Terang/Gelap).
- **`YbChoiceChip`**: chip pil; terpilih = `primarySoft`, garis `primary`, tanda centang. `round: true` untuk kotak level F–S.
- **`YbTabBar`**: tab bar pil mengambang dengan latar buram; tab aktif kapsul `accent` dengan ikon dan teks `onAccent`, sama di semua mode. Layar yang tombolnya dekat tepi bawah harus tetap bisa digulir sampai tombol itu terlihat.
- **Kartu PB** (`PbPhotoCard`): foto dengan gradasi, label kuota di kiri atas, level `YbText.hero` di kanan atas, nama miring; di bawahnya jadwal, iuran `YbText.score`, jumlah dan jenis member.
- **Tombol:** utama pil 52 `primary`; kedua bergaris `control` 44. Satu tombol utama per kartu.
- **`TourBanner`**: kartu putih dengan ikon lampu limau, tombol "Mulai tur" dan tutup.
- **Kotak tanggal**: latar `accent`, hari singkat kapital kecil + tanggal `YbText.score` (Jadwal pengurus).
- **Tiket sesi** (`SessionTicket`, Beranda): potongan tanggal limau, garis sobekan putus-putus dengan dua lubang, badan `night` berisi foto PB sangat tipis (opasitas ±0,34, ditutup gradasi `night` dari kiri supaya teks terbaca; tanpa foto, garis lapangan putih samar). Isi: jenis sesi dan PB kapital kecil, jam `YbText.score`, tempat, jumlah yang ikut, dan label status kalau sudah menjawab ("Kamu ikut", "Bayar Rp…", "Tidak ikut"). Tanpa tombol: seluruh tiket diketuk untuk menjawab ikut atau batal di halaman PB-ku.
- **Aksen sporty**: hero berbusur, garis miring limau, judul miring, tab aktif limau, strip angka papan skor. Semua angka dari data asli.

## 6. Gerak

- Pindah layar bawaan platform. Tidak ada kartu yang memudar saat digulir, paralaks, atau carousel otomatis.
- Hormati "kurangi gerak" (`MediaQuery.disableAnimations`).

## 7. Foto dan ikon

- Foto GOR atau sesi PB sungguhan (dengan izin). Teks di atas foto memakai gradasi gelap di bagian bawah.
- Ikon Material versi `_rounded`/`_outlined`, satu gaya. Tidak memakai emoji sebagai ikon.

## 8. Teks

- Kalimat aktif, sapaan "kamu", Bahasa Indonesia yang wajar.
- Tombol kata kerja + benda. Pesan galat menyebut cara memperbaiki.
- Tidak mengarang nomor kontak, ulasan, atau jumlah. Fitur yang menunggu server diberi tahu lewat pesan, bukan dipura-purakan jalan.

## 9. Aksesibilitas di Flutter

- Tombol ikon punya `tooltip`. Judul seksi `Semantics(header: true)`.
- Isian: `keyboardType` dan `autofillHints` yang sesuai, galat di bawah kolom.
- Tindakan menghapus selalu minta konfirmasi (`confirmDestructive`) atau ada "Batalkan" di snackbar.
- Lolos tes layar 320 × 640 dengan skala teks 1,3, termasuk balon tur.

## 10. Yang tidak boleh

- Meniru identitas merek lain.
- Limau sebagai latar area luas di luar hero, atau lebih dari satu tombol utama limau di luar hero.
- Teks contoh yang tertinggal atau data karangan yang terlihat asli.
