-- YukBadmin: Row Level Security per peran.
--
-- Menggantikan keputusan "tanpa RLS" (27 November 2026). Setelah file ini
-- dijalankan, publishable key yang ada di dalam app tidak lagi cukup untuk
-- membaca atau mengubah data orang lain lewat API.
--
-- Peran yang dipakai:
-- - Pengunjung (anon): hanya membaca PB, jadwal PB, toko, dan produk.
-- - Pemain (akun yang masuk): profilnya sendiri, PB tersimpan dan riwayat
--   dihubungi miliknya, dan mendaftarkan PB baru.
-- - Member: data PB tempat ia jadi member (sesi, info pembayaran) dan
--   catatan miliknya sendiri (konfirmasi ikut, kehadiran, iuran). Tindakan
--   member tetap lewat fungsi member_set_rsvp, member_submit_proof, dan
--   member_request_refund.
-- - Pengurus aktif: semua data PB yang ia urus.
-- - Pemilik PB: seperti pengurus, ditambah menghapus PB dan pengurus lain.
-- - Pemilik toko: tokonya sendiri dan produknya. Toko baru hanya lewat
--   redeem_partner_invite.
--
-- Fungsi bantu (is_pb_manager, my_member_id, dll.) memakai security definer,
-- jadi policy tidak saling memanggil RLS tabel lain dan tidak berputar.
--
-- Jalankan setelah 20261127100000_hak_akses.sql. Aman dijalankan ulang.

begin;

-- ---------------------------------------------------------------------------
-- Fungsi bantu tambahan
-- ---------------------------------------------------------------------------

-- PB tempat sebuah member tercatat.
create or replace function public.member_pb(p_member text)
returns text
language sql
stable
security definer
set search_path = ''
as $$
  select pb_id from public.members where id = p_member;
$$;

-- Sesi dan member berada di PB yang sama, dan pengguna mengurus PB itu.
-- Dipakai untuk tabel yang kuncinya (event_id, member_id).
create or replace function public.manages_event_member(p_event text, p_member text)
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select public.event_pb(p_event) is not null
    and public.event_pb(p_event) = public.member_pb(p_member)
    and public.is_pb_manager(public.event_pb(p_event));
$$;

-- Pengguna lain satu PB dengan saya (sama-sama member atau pengurus aktif).
-- Untuk profil yang dibuka ke sesama member (profile_public).
create or replace function public.shares_pb_with(p_user uuid)
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  with mine as (
    select pb_id from public.members where user_id = auth.uid() and archived_at is null
    union
    select pb_id from public.pb_managers where user_id = auth.uid() and status = 'aktif'
  ), theirs as (
    select pb_id from public.members where user_id = p_user and archived_at is null
    union
    select pb_id from public.pb_managers where user_id = p_user and status = 'aktif'
  )
  select exists (select 1 from mine join theirs using (pb_id));
$$;

revoke execute on function
  public.member_pb(text),
  public.manages_event_member(text, text),
  public.shares_pb_with(uuid)
from public, anon;

grant execute on function
  public.member_pb(text),
  public.manages_event_member(text, text),
  public.shares_pb_with(uuid)
to authenticated;

-- ---------------------------------------------------------------------------
-- Nyalakan RLS di semua tabel
-- ---------------------------------------------------------------------------

alter table public.profiles enable row level security;
alter table public.pbs enable row level security;
alter table public.pb_private enable row level security;
alter table public.pb_sessions enable row level security;
alter table public.pb_managers enable row level security;
alter table public.members enable row level security;
alter table public.session_events enable row level security;
alter table public.attendance enable row level security;
alter table public.rsvps enable row level security;
alter table public.dues enable row level security;
alter table public.saved_pbs enable row level security;
alter table public.contacted_pbs enable row level security;
alter table public.shops enable row level security;
alter table public.products enable row level security;
-- Tanpa policy: tertutup untuk app, hanya bisa dipakai lewat fungsi.
alter table public.partner_invites enable row level security;

-- Supaya file ini bisa dijalankan ulang, hapus policy lama dengan nama yang sama.
do $$
declare
  p record;
begin
  for p in
    select schemaname, tablename, policyname from pg_policies
    where schemaname = 'public' and policyname like 'yb_%'
  loop
    execute format('drop policy %I on %I.%I', p.policyname, p.schemaname, p.tablename);
  end loop;
end;
$$;

-- ---------------------------------------------------------------------------
-- Profil
-- ---------------------------------------------------------------------------

create policy yb_profiles_select on public.profiles
  for select to authenticated
  using (
    id = (select auth.uid())
    or (profile_public and public.shares_pb_with(id))
  );

-- Insert dan delete dicabut di hak_akses.sql (dibuat trigger saat daftar).
create policy yb_profiles_update on public.profiles
  for update to authenticated
  using (id = (select auth.uid()))
  with check (id = (select auth.uid()));

-- ---------------------------------------------------------------------------
-- PB, info pembayaran, jadwal mingguan, dan pengurus
-- ---------------------------------------------------------------------------

create policy yb_pbs_select on public.pbs
  for select to anon, authenticated
  using (true);

-- owner_id diisi trigger pb_guard_insert dengan akun pendaftar.
create policy yb_pbs_insert on public.pbs
  for insert to authenticated
  with check (owner_id = (select auth.uid()));

create policy yb_pbs_update on public.pbs
  for update to authenticated
  using (public.is_pb_manager(id))
  with check (public.is_pb_manager(id));

create policy yb_pbs_delete on public.pbs
  for delete to authenticated
  using (public.is_pb_owner(id));

-- Nomor rekening: hanya pengurus dan member PB itu.
create policy yb_pb_private_select on public.pb_private
  for select to authenticated
  using (public.is_pb_manager(pb_id) or public.is_pb_member(pb_id));

create policy yb_pb_private_insert on public.pb_private
  for insert to authenticated
  with check (public.is_pb_manager(pb_id));

create policy yb_pb_private_update on public.pb_private
  for update to authenticated
  using (public.is_pb_manager(pb_id))
  with check (public.is_pb_manager(pb_id));

create policy yb_pb_sessions_select on public.pb_sessions
  for select to anon, authenticated
  using (true);

create policy yb_pb_sessions_insert on public.pb_sessions
  for insert to authenticated
  with check (public.is_pb_manager(pb_id));

create policy yb_pb_sessions_update on public.pb_sessions
  for update to authenticated
  using (public.is_pb_manager(pb_id))
  with check (public.is_pb_manager(pb_id));

create policy yb_pb_sessions_delete on public.pb_sessions
  for delete to authenticated
  using (public.is_pb_manager(pb_id));

-- Daftar pengurus terlihat oleh pengurus, member, dan pengurus yang diundang.
create policy yb_pb_managers_select on public.pb_managers
  for select to authenticated
  using (
    user_id = (select auth.uid())
    or public.is_pb_manager(pb_id)
    or public.is_pb_member(pb_id)
  );

-- Undangan baru selalu "diundang" tanpa akun (dipaksa trigger pb_managers_guard).
create policy yb_pb_managers_insert on public.pb_managers
  for insert to authenticated
  with check (public.is_pb_manager(pb_id));

create policy yb_pb_managers_update on public.pb_managers
  for update to authenticated
  using (public.is_pb_manager(pb_id))
  with check (public.is_pb_manager(pb_id));

-- Pemilik bisa mengeluarkan pengurus; pengurus bisa mundur sendiri.
-- Pemilik sendiri tidak bisa dihapus (trigger pb_managers_guard).
create policy yb_pb_managers_delete on public.pb_managers
  for delete to authenticated
  using (public.is_pb_owner(pb_id) or user_id = (select auth.uid()));

-- ---------------------------------------------------------------------------
-- Member
-- ---------------------------------------------------------------------------

-- Member lain (nama, WhatsApp) hanya terlihat pengurus. Member melihat
-- catatannya sendiri. Daftar member opt-in (P8c) nanti lewat fungsi khusus.
create policy yb_members_select on public.members
  for select to authenticated
  using (user_id = (select auth.uid()) or public.is_pb_manager(pb_id));

-- Pengurus tidak bisa menghubungkan member ke akun orang lain; menghubungkan
-- member dengan akun pemain akan lewat fungsi server (tahap 2).
create policy yb_members_insert on public.members
  for insert to authenticated
  with check (
    public.is_pb_manager(pb_id)
    and (user_id is null or user_id = (select auth.uid()))
  );

create policy yb_members_update on public.members
  for update to authenticated
  using (public.is_pb_manager(pb_id))
  with check (public.is_pb_manager(pb_id));

create policy yb_members_delete on public.members
  for delete to authenticated
  using (public.is_pb_manager(pb_id));

-- ---------------------------------------------------------------------------
-- Sesi, kehadiran, konfirmasi ikut, dan iuran
-- ---------------------------------------------------------------------------

create policy yb_session_events_select on public.session_events
  for select to authenticated
  using (public.is_pb_manager(pb_id) or public.is_pb_member(pb_id));

create policy yb_session_events_insert on public.session_events
  for insert to authenticated
  with check (public.is_pb_manager(pb_id));

create policy yb_session_events_update on public.session_events
  for update to authenticated
  using (public.is_pb_manager(pb_id))
  with check (public.is_pb_manager(pb_id));

create policy yb_session_events_delete on public.session_events
  for delete to authenticated
  using (public.is_pb_manager(pb_id));

create policy yb_attendance_select on public.attendance
  for select to authenticated
  using (public.is_member_self(member_id) or public.manages_event_member(event_id, member_id));

create policy yb_attendance_write on public.attendance
  for all to authenticated
  using (public.manages_event_member(event_id, member_id))
  with check (public.manages_event_member(event_id, member_id));

-- Member menjawab lewat fungsi member_set_rsvp; tulis langsung hanya pengurus.
create policy yb_rsvps_select on public.rsvps
  for select to authenticated
  using (public.is_member_self(member_id) or public.manages_event_member(event_id, member_id));

create policy yb_rsvps_write on public.rsvps
  for all to authenticated
  using (public.manages_event_member(event_id, member_id))
  with check (public.manages_event_member(event_id, member_id));

-- Status lunas dan pengembalian hanya bisa diubah pengurus. Member mengirim
-- bukti dan mengajukan pengembalian lewat fungsi.
create policy yb_dues_select on public.dues
  for select to authenticated
  using (public.is_member_self(member_id) or public.manages_event_member(event_id, member_id));

create policy yb_dues_write on public.dues
  for all to authenticated
  using (public.manages_event_member(event_id, member_id))
  with check (public.manages_event_member(event_id, member_id));

-- ---------------------------------------------------------------------------
-- Data pribadi pemain
-- ---------------------------------------------------------------------------

create policy yb_saved_pbs_own on public.saved_pbs
  for all to authenticated
  using (user_id = (select auth.uid()))
  with check (user_id = (select auth.uid()));

create policy yb_contacted_pbs_own on public.contacted_pbs
  for all to authenticated
  using (user_id = (select auth.uid()))
  with check (user_id = (select auth.uid()));

-- ---------------------------------------------------------------------------
-- Toko partner dan produk
-- ---------------------------------------------------------------------------

create policy yb_shops_select on public.shops
  for select to anon, authenticated
  using (true);

-- Tidak ada policy insert: toko baru hanya lewat redeem_partner_invite.
create policy yb_shops_update on public.shops
  for update to authenticated
  using (owner_id = (select auth.uid()))
  with check (owner_id = (select auth.uid()));

create policy yb_shops_delete on public.shops
  for delete to authenticated
  using (owner_id = (select auth.uid()));

create policy yb_products_select on public.products
  for select to anon, authenticated
  using (true);

create policy yb_products_insert on public.products
  for insert to authenticated
  with check (public.is_shop_owner(shop_id));

create policy yb_products_update on public.products
  for update to authenticated
  using (public.is_shop_owner(shop_id))
  with check (public.is_shop_owner(shop_id));

create policy yb_products_delete on public.products
  for delete to authenticated
  using (public.is_shop_owner(shop_id));

-- ---------------------------------------------------------------------------
-- Storage
-- ---------------------------------------------------------------------------
-- Letak berkas yang wajib dipakai app saat foto dipindah ke Storage:
-- - pb-media/<pb_id>/<berkas>          (logo dan foto PB, foto member)
-- - toko-media/<shop_id>/<berkas>      (logo, sampul, dan foto produk)
-- - bukti-transfer/<pb_id>/<event_id>/<akun>/<berkas>
--   (sama dengan yang diperiksa member_submit_proof)
-- pb-media dan toko-media adalah bucket publik, jadi siapa pun bisa melihat
-- isinya lewat URL publik; policy di bawah mengatur siapa yang boleh menulis.

drop policy if exists "berkas yukbadmin dikelola akun" on storage.objects;
drop policy if exists yb_pb_media_write on storage.objects;
drop policy if exists yb_toko_media_write on storage.objects;
drop policy if exists yb_bukti_select on storage.objects;
drop policy if exists yb_bukti_insert on storage.objects;
drop policy if exists yb_bukti_delete on storage.objects;

create policy yb_pb_media_write on storage.objects
  for all to authenticated
  using (bucket_id = 'pb-media' and public.is_pb_manager((storage.foldername(name))[1]))
  with check (bucket_id = 'pb-media' and public.is_pb_manager((storage.foldername(name))[1]));

create policy yb_toko_media_write on storage.objects
  for all to authenticated
  using (bucket_id = 'toko-media' and public.is_shop_owner((storage.foldername(name))[1]))
  with check (bucket_id = 'toko-media' and public.is_shop_owner((storage.foldername(name))[1]));

-- Bukti transfer: pengirimnya sendiri dan pengurus PB itu.
create policy yb_bukti_select on storage.objects
  for select to authenticated
  using (
    bucket_id = 'bukti-transfer'
    and (
      (storage.foldername(name))[3] = (select auth.uid())::text
      or public.is_pb_manager((storage.foldername(name))[1])
    )
  );

create policy yb_bukti_insert on storage.objects
  for insert to authenticated
  with check (
    bucket_id = 'bukti-transfer'
    and (storage.foldername(name))[3] = (select auth.uid())::text
    and public.is_pb_member((storage.foldername(name))[1])
    and public.event_pb((storage.foldername(name))[2]) = (storage.foldername(name))[1]
  );

-- Pengirim bisa menghapus bukti yang salah unggah sebelum dicek.
create policy yb_bukti_delete on storage.objects
  for delete to authenticated
  using (
    bucket_id = 'bukti-transfer'
    and (storage.foldername(name))[3] = (select auth.uid())::text
  );

commit;
