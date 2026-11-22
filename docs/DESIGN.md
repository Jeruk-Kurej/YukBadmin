# YukBadmin: arah desain

Dibaca sebelum mengubah tampilan, di app (Flutter) maupun di Figma. Arah ini dipilih 22 November 2026 karena tampilan lama terasa terlalu polos. Contoh penerapannya ada di Figma, halaman "Implementasi Nov 2026": layar P1, P3, P4, P8, K4, P14, dan papan "Komponen desain baru".

Sumber yang dibaca lalu disesuaikan (bukan disalin): Taste Skill (prinsip anti tampilan "buatan AI"), Web Interface Guidelines dari Vercel (diterjemahkan ke Flutter), dan DESIGN.md Nike, Airbnb, Spotify dari awesome-design-md (hanya pola, bukan identitas merek).

## 1. Arah: sporty, energik, tetap hangat

YukBadmin terasa seperti malam di GOR: lapangan, lampu, papan skor, orang yang datang rutin. Bukan toko, bukan dasbor kantor.

- **Foto asli memimpin.** Lapangan, GOR, orang bermain. Foto mengisi kartu dari tepi ke tepi, teks penting ditaruh di atas gradasi gelap di bagian bawah foto.
- **Angka besar seperti papan skor.** Jumlah PB, iuran, hadir, skor kecocokan: angka besar miring tebal, label kecil huruf kapital di bawahnya.
- **Satu aksen untuk satu hal.** Merah hanya untuk aksi utama dan keadaan aktif. Kuning shuttlecock untuk sorotan (hari ini, angka papan skor, label penting). Tidak ada warna dekoratif lain.
- **Hangat lewat orang.** Avatar member, "9 orang ikut", nama pengurus. Komunitas, bukan katalog.

## 2. Warna

Token tetap dari `YbColors` (app) dan koleksi variabel "YukBadmin Color" (Figma). Tidak ada kode warna langsung di layar.

| Peran | Token | Aturan |
| --- | --- | --- |
| Aksi utama, keadaan aktif | `primary` | Satu tombol utama per layar. Tidak dipakai untuk hiasan. |
| Sorotan | `accent` | Angka papan skor, tag "Hari ini", garis aktif. Maksimal dua sorotan per layar. |
| Latar gelap bertekstur lapangan | `night` | Hero Beranda, kartu papan skor, header dashboard. |
| Latar halaman | `bg` | Hangat, bukan putih murni. |
| Kartu | `surface` | Kartu di atas `bg`. |
| Teks | `ink`, `muted` | `muted` hanya untuk keterangan, minimal 12 px. |
| Status | `success`, `warning`, `error` | Hanya untuk arti, tidak untuk hiasan. |

Dilarang: ungu atau lavender, gradasi warna-warni, teks bergradasi, kaca buram bertumpuk (glassmorphism).

## 3. Tipografi

- **Judul:** Archivo ExtraBold Italic (di app `YbText.display`). Ukuran: 32 judul layar utama, 24 judul halaman, 20 judul seksi, 17 judul kartu.
- **Angka papan skor:** Archivo ExtraBold Italic 40 sampai 56, `tabularFigures` di app.
- **Label seksi:** huruf kapital, 12 px, tebal 700, jarak huruf 1,2 px, warna `muted` atau `accent` di atas `night`. Contoh: "PB TERDEKAT", "IURANKU".
- **Isi:** Red Hat Display (app) atau Plus Jakarta Sans (Figma) 14 sampai 16, tinggi baris 1,4 sampai 1,5.
- **Tombol:** 16, tebal 700, kalimat biasa (bukan kapital semua).
- Teks memuat pakai "…" bukan "...". Angka pakai format Indonesia ("Rp150.000").

## 4. Bentuk, jarak, kedalaman

- **Grid 8 px.** Tepi layar 20 px. Jarak antarseksi 28 sampai 32 px. Jarak judul seksi ke isinya 12 px.
- **Radius:** tombol dan chip berbentuk pil (`radius/pill`), kartu `radius/lg`, kolom isian `radius/md`, foto di dalam kartu ikut radius kartu.
- **Satu tingkat bayangan** untuk kartu yang bisa diketuk: lembut, y 4, blur 16, hitam 8 %. Lembar bawah (sheet) dan dialog memakai bayangan lebih kuat. Di mode gelap, kedalaman dari beda warna permukaan, bukan bayangan.
- Maksimal dua kotak bertumpuk (kartu di dalam kartu di dalam kartu dilarang).
- Area ketuk minimal 44 × 44 px, jarak antar area ketuk minimal 8 px.

## 5. Komponen

- **Tombol utama:** pil merah tinggi 52, teks putih, satu per layar. Kata kerja + benda ("Cari PB", "Catat kehadiran", "Kirim bukti").
- **Tombol kedua:** pil `surface` bergaris `line`.
- **Chip pilihan:** pil. Yang dipilih: isian `primary-soft`, garis `primary` 1,5 px, teks `primary-dark`, dan tanda centang kecil (supaya tidak hanya mengandalkan warna). Yang tidak dipilih: isian `surface`, garis `line`. Pilihan dalam satu pertanyaan yang hanya 2–3 opsi dibuat sama lebar. Jangan memakai blok hitam pekat untuk pilihan jawaban.
- **Segmented control** untuk pengaturan dengan 2–3 pilihan tetap (misalnya Tampilan: Sistem / Terang / Gelap): satu wadah `line` berbentuk pil, bagian sama lebar dengan ikon dan teks, bagian terpilih timbul (`surface` + bayangan) dengan teks dan ikon `primary`.
- **Tombol kecil dalam satu daftar** (misalnya "Aktif", "Beralih", "Daftarkan" di Peran lain) ukurannya sama (sekitar 104 × 40); yang berbeda hanya keadaannya.
- **Kartu PB:** foto 16:9 di atas, nama dan jadwal di atas gradasi gelap bawah foto, baris info di bawah foto (level, iuran, jarak). Tag status ("Kuota penuh", "Ada tes level") di pojok foto.
- **Kartu papan skor:** latar `night`, angka besar `accent`, label kapital kecil.
- **Judul seksi:** label kapital kecil di atas, judul display di bawahnya, tautan "Lihat semua" di kanan.
- **Tab bar:** ikon + label, item aktif berwarna `primary` dengan garis kecil di atas.
- **Kolom isian:** label di atas, tinggi 52, garis `primary` 1,5 px saat aktif, galat di bawah kolom dengan cara memperbaikinya.

## 6. Gerak

- Ketukan: kartu dan tombol mengecil ke 0,97 selama 120 ms, lalu kembali.
- Pindah layar: geser atau pudar 200 sampai 250 ms.
- Dilarang: kartu muncul memudar saat digulir, paralaks, carousel otomatis, gerak lebih dari 5 detik tanpa tombol jeda.
- Hormati "kurangi gerak" (`MediaQuery.disableAnimations`): semua gerak berhenti, isi tetap terlihat.

## 7. Foto dan ikon

- Foto asli GOR dan orang bermain. Jangan foto stok yang dipura-purakan sebagai PB tertentu.
- Tidak ada keterangan di bawah foto. Kredit foto (kalau perlu) di satu baris di Akun.
- Ikon garis 2 px, sudut membulat, satu gaya di semua layar. Tidak memakai emoji sebagai ikon.
- Ilustrasi lapangan (`CourtArt`) hanya cadangan kalau PB belum punya foto.

## 8. Teks

- Kalimat aktif, sapaan "kamu". Judul menyebut benda ("PB terdekat", bukan "Jelajahi").
- Tombol kata kerja + benda. Pesan galat menyebut cara memperbaiki.
- Angka ditulis angka ("9 orang ikut").
- Tidak mengarang ulasan, rating, atau jumlah. Data contoh ditandai sebagai contoh.

## 9. Aksesibilitas di Flutter

Dari Web Interface Guidelines, yang berlaku untuk app:

- Tombol ikon punya `tooltip` atau `Semantics(label:)`. Foto punya `semanticLabel`; foto hiasan dibungkus `ExcludeSemantics`.
- Judul seksi `Semantics(header: true)`.
- Isian: `keyboardType`, `autofillHints` (email, kata sandi), `autocorrect: false` untuk email; galat di bawah kolom dan fokus pindah ke galat pertama.
- Tombol kirim tetap aktif sampai permintaan berjalan, lalu menampilkan "Memuat…".
- Tindakan menghapus selalu minta konfirmasi atau ada "Batalkan".
- Teks panjang dipotong dengan `maxLines` dan `TextOverflow.ellipsis`; lolos tes layar 320 px dan skala teks 1,3.
- `SafeArea` di layar penuh. Warna status bar mengikuti tema.

## 10. Yang tidak boleh

- Meniru identitas merek lain (logo, font berlisensi seperti Futura atau SF Pro, ciri khas Nike, Spotify, Airbnb).
- Tampilan "buatan AI": gradasi ungu, emoji sebagai ikon, teks bergradasi, kartu kaca bertumpuk, semua seksi memudar saat digulir.
- Lebih dari satu tombol utama per layar, atau warna aksen untuk hiasan.
- Keterangan di bawah foto, teks contoh yang tertinggal ("Lorem", "Judul"), atau data karangan yang terlihat asli.
