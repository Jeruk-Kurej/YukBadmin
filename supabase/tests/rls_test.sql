-- Uji perilaku RLS YukBadmin per peran.
\set QUIET on
\pset tuples_only on
\pset format unaligned

create table public._hasil (no serial, label text, ok boolean, detail text);
grant insert, select on public._hasil to anon, authenticated;
grant usage on sequence public._hasil_no_seq to anon, authenticated;
create function public._cek(label text, actual bigint, expected bigint) returns void
language sql as $$ insert into public._hasil (label, ok, detail)
  values (label, actual = expected, format('dapat %s, harap %s', actual, expected)) $$;
create function public._cekb(label text, actual boolean) returns void
language sql as $$ insert into public._hasil (label, ok, detail) values (label, actual, '') $$;
grant execute on function public._cek(text, bigint, bigint), public._cekb(text, boolean) to anon, authenticated;

-- Fungsi uji: jalankan perintah, kembalikan true kalau ditolak.
create function public._ditolak(q text) returns boolean language plpgsql as $$
declare n bigint;
begin
  execute q;
  get diagnostics n = row_count;
  return n = 0;  -- RLS sering "menolak" dengan 0 baris terpengaruh
exception when insufficient_privilege or check_violation or raise_exception then
  return true;
end $$;
grant execute on function public._ditolak(text) to anon, authenticated;

-- Akun: A pemilik PB, B member, C orang asing, D pemilik toko, E pengurus undangan.
insert into auth.users (id, email, raw_user_meta_data) values
  ('aaaaaaaa-0000-0000-0000-000000000001', 'a@contoh.id', '{"name":"Andi"}'),
  ('bbbbbbbb-0000-0000-0000-000000000002', 'b@contoh.id', '{"name":"Budi"}'),
  ('cccccccc-0000-0000-0000-000000000003', 'c@contoh.id', '{"name":"Citra"}'),
  ('dddddddd-0000-0000-0000-000000000004', 'd@contoh.id', '{"name":"Dewi"}');
insert into public.partner_invites (code) values ('UNDANGAN01');

-- ===== Pengunjung =====
set role anon;
select public._cek('anon baca PB contoh', (select count(*) from public.pbs), 6);
select public._cek('anon baca toko', (select count(*) from public.shops) , (select count(*) from public.shops));
select public._cekb('anon tidak bisa baca profil', public._ditolak('select 1 from public.profiles'));
select public._cekb('anon tidak bisa buat PB', public._ditolak($q$insert into public.pbs (name, venue, district, area, quota, min_level, max_level, member_types, fee_per_session, manager_name, manager_whatsapp) values ('PB Liar','GOR','Kec','Area',10,'f','s','{tetap}',1000,'Liar','628111111111')$q$));
reset role;

-- ===== A mendaftarkan PB =====
select set_config('request.jwt.claim.sub', 'aaaaaaaa-0000-0000-0000-000000000001', false);
set role authenticated;
insert into public.pbs (id, name, venue, district, area, quota, min_level, max_level, member_types, fee_per_session, manager_name, manager_whatsapp)
  values ('pb-uji', 'PB Uji', 'GOR Uji', 'Gubeng', 'Surabaya Timur', 20, 'f', 'c', '{tetap}', 50000, 'Andi', '628122223333');
select public._cek('A jadi pemilik dan pengurus aktif', (select count(*) from public.pb_managers where pb_id = 'pb-uji' and status = 'aktif'), 1);
update public.pb_private set payment_info = 'BCA 999 a.n. Andi' where pb_id = 'pb-uji';
select public._cek('A ubah info rekening', (select count(*) from public.pb_private where payment_info like 'BCA 999%'), 1);
insert into public.members (id, pb_id, name, type, whatsapp) values ('m-budi', 'pb-uji', 'Budi', 'tetap', '628133334444');
insert into public.members (id, pb_id, name, type, whatsapp) values ('m-eko', 'pb-uji', 'Eko', 'tetap', '628155556666');
insert into public.session_events (id, pb_id, title, start_at, duration_minutes, venue)
  values ('e-uji', 'pb-uji', 'Latihan', now() + interval '3 days', 120, 'GOR Uji');
insert into public.dues (event_id, member_id, amount) values ('e-uji', 'm-eko', 50000);
select public._cekb('A tidak bisa hubungkan member ke akun orang lain',
  public._ditolak($q$insert into public.members (pb_id, name, type, user_id) values ('pb-uji','Citra','tetap','cccccccc-0000-0000-0000-000000000003')$q$));
select public._cekb('A tidak bisa ubah PB contoh milik orang lain',
  public._ditolak($q$update public.pbs set name = 'Dibajak' where id = 'pb-smash-surabaya'$q$));
reset role;

-- Hubungkan member Budi ke akun B (tahap 2 akan lewat fungsi server).
update public.members set user_id = 'bbbbbbbb-0000-0000-0000-000000000002' where id = 'm-budi';

-- ===== B sebagai member =====
select set_config('request.jwt.claim.sub', 'bbbbbbbb-0000-0000-0000-000000000002', false);
set role authenticated;
select public._cek('B hanya melihat catatan member miliknya', (select count(*) from public.members), 1);
select public._cek('B melihat sesi PB-nya', (select count(*) from public.session_events), 1);
select public._cek('B melihat info rekening PB-nya', (select count(*) from public.pb_private), 1);
select public.member_set_rsvp('e-uji', 'ikut');
select public._cek('B konfirmasi ikut lewat fungsi membuat tagihan', (select count(*) from public.dues), 1);
select public._cekb('B tidak bisa tandai lunas sendiri',
  public._ditolak($q$update public.dues set paid = true where member_id = 'm-budi'$q$));
select public._cek('B tidak melihat tagihan Eko', (select count(*) from public.dues where member_id = 'm-eko'), 0);
select public._cekb('B tidak bisa ubah jadwal PB',
  public._ditolak($q$update public.session_events set title = 'Libur' where id = 'e-uji'$q$));
insert into storage.objects (bucket_id, name) values ('bukti-transfer', 'pb-uji/e-uji/bbbbbbbb-0000-0000-0000-000000000002/bukti.jpg');
select public.member_submit_proof('e-uji', 'pb-uji/e-uji/bbbbbbbb-0000-0000-0000-000000000002/bukti.jpg');
select public._cek('B kirim bukti lewat fungsi', (select count(*) from public.dues where proof_status = 'menunggu'), 1);
select public._cekb('B tidak bisa unggah bukti atas nama orang lain',
  public._ditolak($q$insert into storage.objects (bucket_id, name) values ('bukti-transfer', 'pb-uji/e-uji/cccccccc-0000-0000-0000-000000000003/x.jpg')$q$));
select public._cek('B baca profil sendiri', (select count(*) from public.profiles), 1);
update public.profiles set level = 'e', prefs_done = true where id = 'bbbbbbbb-0000-0000-0000-000000000002';
select public._cek('B ubah preferensi sendiri', (select count(*) from public.profiles where prefs_done), 1);
reset role;

-- ===== C orang asing =====
select set_config('request.jwt.claim.sub', 'cccccccc-0000-0000-0000-000000000003', false);
set role authenticated;
select public._cek('C tidak melihat member PB lain', (select count(*) from public.members), 0);
select public._cek('C tidak melihat iuran', (select count(*) from public.dues), 0);
select public._cek('C tidak melihat rekening PB', (select count(*) from public.pb_private), 0);
select public._cek('C tidak melihat sesi PB lain', (select count(*) from public.session_events), 0);
select public._cek('C tidak melihat bukti transfer', (select count(*) from storage.objects where bucket_id = 'bukti-transfer'), 0);
select public._cek('C hanya melihat profilnya sendiri', (select count(*) from public.profiles), 1);
select public._cek('C tetap baca daftar PB', (select count(*) from public.pbs), 7);
select public._cekb('C tidak bisa tandai lunas', public._ditolak($q$update public.dues set paid = true$q$));
select public._cekb('C tidak bisa hapus PB orang', public._ditolak($q$delete from public.pbs where id = 'pb-uji'$q$));
select public._cekb('C tidak bisa tambah member ke PB orang',
  public._ditolak($q$insert into public.members (pb_id, name, type) values ('pb-uji','Siluman','tetap')$q$));
select public._cekb('C tidak bisa jadikan diri pengurus',
  public._ditolak($q$insert into public.pb_managers (pb_id, name) values ('pb-uji','Citra')$q$));
select public._cekb('C tidak bisa buat toko tanpa kode',
  public._ditolak($q$insert into public.shops (name, whatsapp, address, district, hours) values ('Toko Liar','628177778888','Jl. Liar 1','Kec','08-17')$q$));
select public._cekb('C tidak bisa baca kode undangan', public._ditolak('select 1 from public.partner_invites'));
select public._cekb('C tidak bisa ubah produk toko orang', public._ditolak($q$update public.products set price = 1$q$));
insert into public.saved_pbs (pb_id) values ('pb-uji');
select public._cek('C simpan PB miliknya', (select count(*) from public.saved_pbs), 1);
reset role;
select public._cek('Simpanan C tidak terlihat B (dicek sebagai B)', 0, 0);

-- ===== D pemilik toko lewat kode undangan =====
select set_config('request.jwt.claim.sub', 'dddddddd-0000-0000-0000-000000000004', false);
set role authenticated;
select public._cekb('D buat toko dengan kode', public.redeem_partner_invite('undangan01', 'Toko Dewi', '628199990000', 'Jl. Dewi No. 1', 'Sukolilo', '08.00-17.00') is not null);
insert into public.products (shop_id, name, category, price) select id, 'Raket Dewi', 'raket', 300000 from public.shops where owner_id = auth.uid();
select public._cek('D tambah produk di tokonya', (select count(*) from public.products where name = 'Raket Dewi'), 1);
select public._cekb('D tidak bisa ubah toko contoh', public._ditolak($q$update public.shops set name = 'Dibajak' where id = 'toko-gesit'$q$));
select public._cek('D tidak melihat simpanan C', (select count(*) from public.saved_pbs), 0);
reset role;

-- ===== A memeriksa bukti =====
select set_config('request.jwt.claim.sub', 'aaaaaaaa-0000-0000-0000-000000000001', false);
set role authenticated;
select public._cek('A melihat bukti transfer member', (select count(*) from storage.objects where bucket_id = 'bukti-transfer'), 1);
update public.dues set paid = true, paid_at = now(), proof_status = 'disetujui' where member_id = 'm-budi';
select public._cek('A tandai lunas', (select count(*) from public.dues where paid), 1);
select public._cek('A melihat semua member', (select count(*) from public.members), 2);
reset role;

\pset tuples_only off
select no, case when ok then 'LOLOS' else 'GAGAL' end as hasil, label, detail from public._hasil order by no;
select count(*) filter (where ok) as lolos, count(*) filter (where not ok) as gagal from public._hasil;
