# YukBadmin: arah desain

Dibaca sebelum mengubah tampilan, di app (Flutter) maupun di Figma. Acuan sejak 27 November 2026 adalah halaman Figma **"Final Design v4"** (node `654:3932`), dan app sudah mengikutinya. Arah sebelumnya ("sporty, merah bata, Archivo miring", 22 November 2026) tidak dipakai lagi; halaman "Implementasi Nov 2026" tinggal arsip.

## 1. Arah: tenang, jelas, rapi seperti app bawaan iOS

YukBadmin dipakai di sela urusan lain: cek jadwal, konfirmasi ikut, kirim bukti transfer. Tampilannya tidak perlu ramai.

- **Biru malam sebagai warna utama**, hijau limau hanya untuk satu sorotan (tanggal sesi, tombol di kartu gelap).
- **Daftar berkelompok** (kartu putih bersudut besar dengan garis pemisah) untuk menu, pengaturan, dan daftar orang.
- **Satu kartu gelap per layar** paling banyak: hero dashboard, ajakan cari PB, saran perlengkapan.
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
| Kartu gelap | `night`, `onNight` | #13283F, putih | sama | Sama di kedua mode |
| Sorotan | `accent`, `onAccent`, `accentSoft` | #D5E88A | #D5E88A | Satu sorotan per layar |
| Status | `success`, `warning`, `error`, `pending` + `…Soft` | | | Hanya untuk arti. Teks di atas `error` memakai `onError` |

Dilarang: ungu, gradasi warna-warni, teks bergradasi, `Colors.white` di atas `primary` atau `error` (di mode gelap keduanya terang).

## 3. Tipografi

Satu keluarga huruf: **Inter** (`google_fonts`).

- `YbText.display`: judul besar layar 32 tebal, judul seksi 20 semi tebal, judul kartu 17–18.
- `YbText.score`: angka papan skor (tanggal, jam sesi), Inter 800 miring dengan angka tabular.
- `YbText.body`: isi 15, keterangan 13 `muted`.
- Tombol 16 semi tebal, kalimat biasa. Angka format Indonesia ("Rp150.000"), elipsis "…".

## 4. Bentuk dan jarak

- Tepi layar 16 px. Jarak antarseksi 24–28 px, judul seksi ke isinya 10 px.
- Radius: `sm` 8, `md` 14 (kolom isian, kotak tanggal), `lg` 22 (kartu, daftar berkelompok, sheet), `pill` (tombol, kolom cari, tab bar).
- Kartu tanpa garis tepi dan tanpa bayangan; kedalaman dari beda warna `surface` dan `bg`.
- Area ketuk minimal 44 × 44 px.

## 5. Komponen (di `yb_widgets.dart` dan `manage_widgets.dart`)

- **`YbPageTitle`**: judul besar 32 di layar tab, dengan subjudul dan satu tombol bulat 44 di kanan.
- **`PageHeader`**: bilah navigasi layar dorongan: tombol kembali bulat, judul 17 di tengah, satu aksi teks di kanan (misalnya "Simpan", "Lihat").
- **`YbGroup` + `YbListRow`**: daftar berkelompok. Baris: ikon dalam lingkaran atau avatar, judul, subjudul, lalu tag atau panah.
- **`YbSectionTitle`**: judul seksi 20 dengan tautan opsional di kanan.
- **`YbSegmented`**: pilihan 2–3 opsi tetap (Ikut/Tidak ikut, Mendatang/Riwayat, Masuk/Daftar, Sistem/Terang/Gelap).
- **`YbChoiceChip`**: chip pil; terpilih = `primarySoft`, garis `primary`, tanda centang. `round: true` untuk kotak level F–S.
- **`YbTabBar`**: tab bar pil mengambang dengan latar buram; tab aktif kapsul `night` + ikon limau. Layar yang tombolnya dekat tepi bawah harus tetap bisa digulir sampai tombol itu terlihat.
- **Tombol:** utama pil 52 `primary`; kedua bergaris `control` 44. Satu tombol utama per kartu.
- **`TourBanner`**: kartu putih dengan ikon lampu limau, tombol "Mulai tur" dan tutup.
- **Kotak tanggal**: latar `accent`, hari singkat kapital kecil + tanggal `YbText.score` (Jadwal pengurus).
- **Tiket sesi** (`SessionTicket`, Beranda): potongan tanggal limau, garis sobekan putus-putus dengan dua lubang, badan `night` berisi foto PB sangat tipis (opasitas ±0,34, ditutup gradasi `night` dari kiri supaya teks terbaca; tanpa foto, garis lapangan putih samar). Isi: jenis sesi dan PB kapital kecil, jam `YbText.score`, tempat, jumlah yang ikut, lalu satu kontrol saja: tombol limau "Ikut" kalau belum menjawab, atau label status ("Kamu ikut", "Bayar Rp…", "Tidak ikut"). Batal ikut dari halaman PB-ku.
- **Aksen sporty**: garis limau kecil di depan tiap `YbSectionTitle`, tab aktif berupa kapsul `night` dengan ikon limau, sapaan Beranda dengan garis lapangan samar, strip angka papan skor (angka miring tebal). Semua angka dari data asli.

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
- Lebih dari satu kartu gelap atau satu sorotan limau per layar.
- Teks contoh yang tertinggal atau data karangan yang terlihat asli.
