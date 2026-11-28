-- YukBadmin: hak akses tabel untuk app.
--
-- Project Supabase baru tidak lagi memberi hak tabel otomatis ke peran app
-- (`anon` untuk pengunjung tanpa akun, `authenticated` untuk akun yang
-- masuk). Ini bukan Row Level Security: hak di sini berlaku per tabel,
-- tidak per baris.
--
-- - Pengunjung tanpa akun hanya bisa membaca data publik (PB, jadwal PB,
--   toko, produk).
-- - Akun yang masuk bisa membaca dan menulis tabel lain yang dipakai app.
-- - Kode undangan toko tidak bisa diakses langsung; hanya lewat fungsi
--   redeem_partner_invite.

begin;

grant usage on schema public to anon, authenticated;

grant select on public.pbs, public.pb_sessions, public.shops, public.products
  to anon;

grant select, insert, update, delete on
  public.profiles,
  public.pbs,
  public.pb_private,
  public.pb_sessions,
  public.pb_managers,
  public.members,
  public.session_events,
  public.attendance,
  public.rsvps,
  public.dues,
  public.saved_pbs,
  public.contacted_pbs,
  public.shops,
  public.products
to authenticated;

-- Profil dibuat trigger saat daftar dan ikut terhapus bersama akunnya.
revoke insert, delete on public.profiles from authenticated;

revoke all on public.partner_invites from anon, authenticated;

commit;
