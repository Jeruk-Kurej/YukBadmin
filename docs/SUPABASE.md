# Supabase YukBadmin

Project: `nbmssaxkvrobuuvttjlf` (https://nbmssaxkvrobuuvttjlf.supabase.co).

## Yang sudah tersambung (tahap 1)

| Bagian | Sumber data |
| --- | --- |
| Daftar, masuk, keluar, verifikasi email | Supabase Auth |
| Preferensi main dan tanda "preferensi sudah diisi" | tabel `profiles` |
| Daftar PB dan jadwal mingguannya (Beranda, Cari PB, Detail PB) | `pbs`, `pb_sessions` |
| Toko partner dan produk (Perlengkapan) | `shops`, `products` |

Masih lokal di HP (tabelnya sudah ada, app belum menulis ke sana): PB yang didaftarkan pengguna, member, jadwal sesi, kehadiran, konfirmasi ikut, iuran, bukti transfer, PB tersimpan, riwayat dihubungi, toko milik pengguna, dan foto. Itu tahap 2.

Tanpa `--dart-define`, app tetap memakai data lokal seperti sebelumnya, dan tes otomatis tidak menyentuh jaringan.

## Menyiapkan project (sekali)

1. **SQL Editor** → jalankan berurutan semua file di `supabase/migrations/` (urut nama: `…090000_skema_tabel_inti`, `…090100_skema_tabel_lain`, `…090200_skema_trigger`, `…090300_skema_fungsi_storage`, `…100000_hak_akses`, `…20261128090000_rls_per_peran`), lalu `supabase/seed.sql`. Project baru Supabase tidak lagi memberi hak tabel otomatis ke app, jadi file hak akses wajib dijalankan. Lima file pertama sudah dijalankan di project `nbmssaxkvrobuuvttjlf` pada 27 November 2026. **File RLS (`20261128090000_rls_per_peran.sql`) belum dijalankan di project**; jalankan sekali di SQL Editor. File itu aman dijalankan ulang.
2. Setelah file RLS dijalankan, dashboard tidak lagi menandai tabel "RLS disabled". Kalau masih ada, berarti file RLS belum masuk.
3. **Authentication → Sign In / Providers → Email**: biarkan **Confirm email** menyala. Pengguna baru harus membuka tautan verifikasi sebelum bisa masuk.
4. **Authentication → Policies / Attack Protection** (kalau tersedia di paket gratis): nyalakan perlindungan kata sandi bocor dan atur panjang minimal 8.
5. **Project Settings → API Keys**: salin **publishable key** (`sb_publishable_…`, atau anon key lama). **Jangan pernah** menaruh `service_role`/secret key di app atau di repo.
6. Salin `env/dev.example.json` menjadi `env/dev.json`, isi kuncinya. `env/dev.json` sudah di-gitignore.
7. Jalankan app:

   ```bash
   flutter run --dart-define-from-file=env/dev.json
   ```

## Keamanan: Row Level Security per peran

Keputusan 27 November 2026 untuk mematikan RLS diganti pada 28 November 2026. Semua tabel memakai RLS lewat `supabase/migrations/20261128090000_rls_per_peran.sql`. Publishable key di dalam app tidak lagi cukup untuk membaca atau mengubah data orang lain.

| Peran | Boleh membaca | Boleh mengubah |
| --- | --- | --- |
| Pengunjung tanpa akun | PB, jadwal PB, toko, produk | Tidak ada |
| Pemain (akun yang masuk) | Yang di atas, profilnya sendiri, profil sesama member yang dibuka (`profile_public`) | Profil sendiri, PB tersimpan, riwayat dihubungi, mendaftarkan PB baru |
| Member PB | Sesi PB itu, info rekening PB itu, catatan member, kehadiran, konfirmasi, dan iuran **miliknya sendiri**, daftar pengurus | Hanya lewat fungsi: `member_set_rsvp`, `member_submit_proof`, `member_request_refund`, dan unggah bukti ke folder miliknya |
| Pengurus aktif | Semua data PB yang ia urus, termasuk bukti transfer | PB, rekening, jadwal, member, sesi, kehadiran, iuran (termasuk lunas), undangan pengurus |
| Pemilik PB | Sama dengan pengurus | Ditambah menghapus PB dan mengeluarkan pengurus |
| Pemilik toko | Tokonya | Toko dan produknya sendiri. Toko baru hanya lewat `redeem_partner_invite` |

Hal penting:

- `partner_invites` tertutup sepenuhnya untuk app; hanya fungsi `redeem_partner_invite` yang memakainya.
- Member tidak bisa melihat nama dan WhatsApp member lain. Daftar member opt-in (P8c, P8d) nanti dibuat lewat fungsi khusus.
- Pengurus tidak bisa menghubungkan member ke akun orang lain. Menghubungkan member dengan akun pemain dan menerima undangan pengurus nanti lewat fungsi server (tahap 2).
- Batasan kolom, trigger integritas, dan fungsi member tetap berlaku seperti sebelumnya.

**Letak berkas di Storage** (wajib dipakai app saat foto dipindah ke Storage):

- `pb-media/<pb_id>/<berkas>`: hanya pengurus PB itu yang boleh menulis.
- `toko-media/<shop_id>/<berkas>`: hanya pemilik toko yang boleh menulis.
- `bukti-transfer/<pb_id>/<event_id>/<akun>/<berkas>`: member mengunggah ke folder akunnya sendiri; yang bisa membaca hanya pengirim dan pengurus PB itu.

`pb-media` dan `toko-media` adalah bucket publik, jadi isinya bisa dilihat siapa pun lewat URL.

**Menguji policy** tanpa menyentuh project: `supabase/tests/` berisi tiruan minimal Supabase (`00_tiruan_supabase.sql`) dan 42 skenario per peran (`rls_test.sql`). Jalankan di Postgres lokal yang kosong: tiruan, semua migrasi, `seed.sql`, lalu `rls_test.sql`. Hasil terakhir (28 November 2026, Postgres 17): 42 lolos, 0 gagal. Tiruan ini bukan Supabase sungguhan, jadi setelah file RLS dijalankan di project, tetap coba alur masuk, preferensi, Beranda, dan Perlengkapan di app.

## Batasan yang masih ada

- Masuk dengan Google belum disambungkan (butuh OAuth client di Google Cloud Console).
- Lupa kata sandi belum bisa dipakai dari app: tautannya butuh deep link ke layar "Buat kata sandi baru".
- Undangan pengurus dan menghubungkan member dengan akun pemain belum punya fungsi server; itu bagian tahap 2.
