# YukBadmin

Teman badmintonmu, dari game pertama sampai PB-mu sendiri.

YukBadmin adalah aplikasi mobile (Flutter) yang menghubungkan orang yang ingin mulai bermain badminton dengan PB (Persatuan Bulutangkis / klub komunitas), sekaligus membantu pengurus PB mengelola klubnya.

Proyek mata kuliah DEPD, Universitas Ciputra, oleh Team OHEB.

## Fitur yang direncanakan

- **Pemain:** cari PB berdasarkan area, hari, dan level; lihat jadwal, biaya per sesi, dan jumlah anggota; hubungi pengurus lewat WhatsApp.
- **Pengurus PB:** daftarkan PB, kelola member (tetap / insidental), sesi, kehadiran, dan iuran; kirim pengingat.
- **Impor AI:** foto catatan, chat, atau poster diubah menjadi data member dan iuran, dengan konfirmasi pengurus sebelum disimpan.
- **Toko mitra:** profil toko, produk, dan stok; saran perlengkapan untuk pemain.

## Teknologi

- Flutter (Android dan iOS)
- Supabase (database, autentikasi, storage)
- Google sign-in

## Status dan cara melanjutkan

- Status, keputusan produk, dan langkah berikutnya: [docs/PROGRESS.md](docs/PROGRESS.md)
- Prompt siap tempel untuk melanjutkan dengan Claude Code: [docs/PROMPT_LANJUTAN.md](docs/PROMPT_LANJUTAN.md)

## Menjalankan project

```bash
flutter pub get
flutter run
```

## Tim OHEB

| Nama | Peran |
| --- | --- |
| Hanzelius | Project Manager |
| Bryan Carlie L. S. | Software Engineer |
| Mario Ruby A. | Quality Assurance |
| Filemon Jose H. | Backend Developer |
| Jason Christopher | UI/UX Designer |
| Anjello Siau | Frontend Developer |

## Alur kerja

- Setiap anggota bekerja di branch atas namanya sendiri.
- Perubahan digabung ke `main` lewat pull request.
