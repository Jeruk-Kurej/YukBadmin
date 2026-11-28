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

1. **SQL Editor** → jalankan berurutan semua file di `supabase/migrations/` (urut nama: `…090000_skema_tabel_inti`, `…090100_skema_tabel_lain`, `…090200_skema_trigger`, `…090300_skema_fungsi_storage`, `…100000_hak_akses`), lalu `supabase/seed.sql`. Project baru Supabase tidak lagi memberi hak tabel otomatis ke app, jadi file hak akses wajib dijalankan. Sudah dijalankan di project `nbmssaxkvrobuuvttjlf` pada 27 November 2026 (waktu itu keempat bagian skema masih satu file; isinya sama).
2. Dashboard akan menandai tabel "RLS disabled". Itu sengaja; baca bagian Keamanan di bawah.
3. **Authentication → Sign In / Providers → Email**: biarkan **Confirm email** menyala. Pengguna baru harus membuka tautan verifikasi sebelum bisa masuk.
4. **Authentication → Policies / Attack Protection** (kalau tersedia di paket gratis): nyalakan perlindungan kata sandi bocor dan atur panjang minimal 8.
5. **Project Settings → API Keys**: salin **publishable key** (`sb_publishable_…`, atau anon key lama). **Jangan pernah** menaruh `service_role`/secret key di app atau di repo.
6. Salin `env/dev.example.json` menjadi `env/dev.json`, isi kuncinya. `env/dev.json` sudah di-gitignore.
7. Jalankan app:

   ```bash
   flutter run --dart-define-from-file=env/dev.json
   ```

## Keamanan: Row Level Security tidak dipakai

Atas keputusan tim (27 November 2026), RLS **tidak dinyalakan** di tabel mana pun. Dashboard Supabase akan memberi peringatan "RLS disabled"; itu memang disengaja.

**Risikonya.** Publishable key ikut di dalam app dan bisa diambil dari file APK. Dengan kunci itu ditambah akun apa pun (daftar itu gratis), siapa pun bisa memanggil API Supabase langsung, tanpa lewat app, dan:

- membaca semua tabel: nama dan WhatsApp member, nomor rekening PB (`pb_private`), iuran, bukti transfer, kode undangan toko (`partner_invites`);
- mengubah atau menghapus data apa pun, misalnya menandai iuran lunas atau menghapus PB orang lain;
- membuat toko tanpa kode undangan dengan menulis langsung ke tabel `shops`.

Karena itu, **jangan isi database ini dengan data sungguhan** (nomor rekening asli, nomor WhatsApp member asli) selama RLS mati. Untuk demo dan data contoh, risikonya dapat diterima.

**Yang tetap dijaga di database:**

- Batasan kolom: format WhatsApp, rentang angka, dan nilai yang dikenal (level, jenis member, kategori produk).
- Trigger: pemilik PB, jumlah member, pemilik toko, dan PB sebuah member atau sesi tidak bisa diubah lewat app; pemilik PB tidak bisa dihapus dari daftar pengurus; hapus member mengarsipkan yang masih punya catatan uang.
- Fungsi untuk tindakan member (`member_set_rsvp`, `member_submit_proof`, `member_request_refund`) dan `redeem_partner_invite` (kode sekali pakai, satu akun satu toko) tetap memeriksa aturan iuran dan hak member. Tapi karena tabel terbuka, aturan ini bisa dilewati dengan menulis langsung ke tabel.
- Storage: ketiga bucket hanya menerima gambar maksimal 5 MB, dan hanya akun yang masuk yang boleh mengunggah.
- Hak tabel (bukan RLS): pengunjung tanpa akun hanya bisa **membaca** PB, jadwal PB, toko, dan produk; tidak bisa menulis apa pun. Profil, iuran, member, dan lainnya hanya untuk akun yang masuk. `partner_invites` tertutup untuk app, hanya lewat fungsi. Sudah dicek lewat API: pengunjung membaca 6 PB dan ditolak saat membuat PB atau membaca profil.

**Kalau nanti RLS mau dinyalakan,** rancangan policy lengkapnya (per peran: pengunjung, pemain, member, pengurus, pemilik toko) sudah pernah dibuat dan bisa dipulihkan dari riwayat percakapan atau dibuat ulang sebagai migrasi baru. Nyalakan sebelum app dipakai orang sungguhan.

## Batasan yang masih ada

- Masuk dengan Google belum disambungkan (butuh OAuth client di Google Cloud Console).
- Lupa kata sandi belum bisa dipakai dari app: tautannya butuh deep link ke layar "Buat kata sandi baru".
- Undangan pengurus dan menghubungkan member dengan akun pemain belum punya fungsi server; itu bagian tahap 2.
