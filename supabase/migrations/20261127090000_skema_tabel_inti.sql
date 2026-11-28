-- YukBadmin: skema awal Supabase, bagian 1 dari 4: tabel inti (profil, PB, member, sesi, iuran).
--
-- Catatan: Row Level Security sengaja tidak dipakai (keputusan tim). Yang
-- tetap dijaga di database:
-- 1. Batasan kolom (format WhatsApp, rentang angka, nilai yang dikenal).
-- 2. Trigger yang mengunci pemilik PB, jumlah member, pemilik toko, dan
--    pemilik PB di daftar pengurus.
-- 3. Fungsi untuk tindakan member (konfirmasi ikut, batal, kirim bukti,
--    ajukan pengembalian) dan kode undangan toko, dengan aturan yang sama
--    dengan app.
--
-- Jalankan berurutan di SQL Editor Supabase: bagian 1 sampai 4, lalu
-- 20261127100000_hak_akses.sql, lalu supabase/seed.sql.

begin;

create extension if not exists pgcrypto;

-- ---------------------------------------------------------------------------
-- Fungsi bantu umum
-- ---------------------------------------------------------------------------

create or replace function public.new_id(prefix text)
returns text
language sql
volatile
set search_path = ''
as $$
  select prefix || '-' || replace(gen_random_uuid()::text, '-', '');
$$;

create or replace function public.touch_updated_at()
returns trigger
language plpgsql
set search_path = ''
as $$
begin
  new.updated_at := now();
  return new;
end;
$$;

-- ---------------------------------------------------------------------------
-- Profil pengguna (satu baris per akun Supabase Auth)
-- ---------------------------------------------------------------------------

create table public.profiles (
  id uuid primary key references auth.users (id) on delete cascade,
  name text not null check (char_length(name) between 1 and 80),
  area text check (area is null or char_length(area) <= 60),
  level text check (level is null or level in ('f', 'e', 'd', 'c', 'b', 'a', 's')),
  weekdays smallint[] not null default '{}'
    check (weekdays <@ array[1, 2, 3, 4, 5, 6, 7]::smallint[]),
  prefs_done boolean not null default false,
  -- Opt-in: profil tampil ke sesama member hanya kalau dinyalakan sendiri.
  profile_public boolean not null default false,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create trigger profiles_touch before update on public.profiles
  for each row execute function public.touch_updated_at();

-- Profil dibuat otomatis saat akun dibuat, dengan nama dari metadata daftar.
create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
declare
  display_name text := left(coalesce(
    nullif(trim(new.raw_user_meta_data ->> 'name'), ''),
    split_part(new.email, '@', 1),
    'Pemain'
  ), 80);
begin
  insert into public.profiles (id, name) values (new.id, display_name);
  return new;
end;
$$;

create trigger on_auth_user_created
  after insert on auth.users
  for each row execute function public.handle_new_user();

-- ---------------------------------------------------------------------------
-- PB dan jadwal mingguannya
-- ---------------------------------------------------------------------------

create table public.pbs (
  id text primary key default public.new_id('pb'),
  owner_id uuid references auth.users (id) on delete set null default auth.uid(),
  name text not null check (char_length(name) between 3 and 80),
  venue text not null check (char_length(venue) between 2 and 120),
  district text not null check (char_length(district) between 2 and 60),
  area text not null check (char_length(area) between 2 and 60),
  -- Dihitung trigger dari tabel members; tidak bisa diubah dari app.
  member_count integer not null default 0 check (member_count >= 0),
  quota integer not null check (quota between 1 and 1000),
  min_level text not null check (min_level in ('f', 'e', 'd', 'c', 'b', 'a', 's')),
  max_level text not null check (max_level in ('f', 'e', 'd', 'c', 'b', 'a', 's')),
  member_types text[] not null
    check (cardinality(member_types) > 0 and member_types <@ array['tetap', 'insidental']),
  fee_per_session integer not null check (fee_per_session between 0 and 5000000),
  monthly_fee integer check (monthly_fee is null or monthly_fee between 0 and 50000000),
  about text not null default '' check (char_length(about) <= 2000),
  rules text[] not null default '{}' check (cardinality(rules) <= 30),
  manager_name text not null check (char_length(manager_name) between 2 and 80),
  manager_whatsapp text not null check (manager_whatsapp ~ '^62[0-9]{8,13}$'),
  open_for_new_members boolean not null default true,
  art_seed integer not null default 0,
  latitude double precision check (latitude is null or latitude between -90 and 90),
  longitude double precision check (longitude is null or longitude between -180 and 180),
  founded_year integer check (founded_year is null or founded_year between 1900 and 2100),
  level_test boolean not null default false,
  logo_url text,
  photo_urls text[] not null default '{}',
  -- Aturan iuran (cara bayar, batas pembatalan, harga per orang).
  dues_system jsonb not null default '{"timing": "sebelum", "cancelHours": 24}'::jsonb
    check (jsonb_typeof(dues_system) = 'object'),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create trigger pbs_touch before update on public.pbs
  for each row execute function public.touch_updated_at();

-- Info pembayaran (nomor rekening) dipisah dari tabel PB supaya mudah
-- ditutup kalau nanti RLS dinyalakan. Tanpa RLS, tabel ini tetap terbaca.
create table public.pb_private (
  pb_id text primary key references public.pbs (id) on delete cascade,
  payment_info text check (payment_info is null or char_length(payment_info) <= 500)
);

create table public.pb_sessions (
  id uuid primary key default gen_random_uuid(),
  pb_id text not null references public.pbs (id) on delete cascade,
  weekday smallint not null check (weekday between 1 and 7),
  start_time time not null,
  end_time time not null,
  venue text not null check (char_length(venue) between 2 and 120),
  check (end_time > start_time)
);

create index pb_sessions_pb_idx on public.pb_sessions (pb_id);

-- Pengurus PB: pemilik (yang mendaftarkan) dan pengurus yang diundang.
create table public.pb_managers (
  id uuid primary key default gen_random_uuid(),
  pb_id text not null references public.pbs (id) on delete cascade,
  user_id uuid references auth.users (id) on delete cascade,
  role text not null default 'pengurus' check (role in ('pemilik', 'pengurus')),
  status text not null default 'diundang' check (status in ('diundang', 'aktif')),
  name text not null check (char_length(name) between 2 and 80),
  whatsapp text check (whatsapp is null or whatsapp ~ '^62[0-9]{8,13}$'),
  created_at timestamptz not null default now(),
  unique (pb_id, user_id)
);

create index pb_managers_user_idx on public.pb_managers (user_id);

-- ---------------------------------------------------------------------------
-- Member, sesi, kehadiran, konfirmasi ikut, dan iuran
-- ---------------------------------------------------------------------------

create table public.members (
  id text primary key default public.new_id('m'),
  pb_id text not null references public.pbs (id) on delete cascade,
  -- Akun pemain yang terhubung. Null untuk member yang hanya dicatat pengurus.
  user_id uuid references auth.users (id) on delete set null,
  name text not null check (char_length(name) between 1 and 80),
  type text not null check (type in ('tetap', 'insidental')),
  level text check (level is null or level in ('f', 'e', 'd', 'c', 'b', 'a', 's')),
  whatsapp text check (whatsapp is null or whatsapp ~ '^62[0-9]{8,13}$'),
  photo_url text,
  -- Member yang dihapus tapi punya uang lunas atau sedang dikembalikan
  -- diarsipkan supaya catatan uangnya tetap ada.
  archived_at timestamptz,
  created_at timestamptz not null default now(),
  unique (pb_id, user_id)
);

create index members_pb_idx on public.members (pb_id);
create index members_user_idx on public.members (user_id);

create table public.session_events (
  id text primary key default public.new_id('e'),
  pb_id text not null references public.pbs (id) on delete cascade,
  title text not null check (char_length(title) between 2 and 60),
  start_at timestamptz not null,
  duration_minutes integer not null check (duration_minutes between 15 and 720),
  venue text not null check (char_length(venue) between 2 and 120),
  courts integer not null default 2 check (courts between 1 and 20),
  attendance_saved boolean not null default false,
  bills_sent boolean not null default false,
  -- Pemakaian per orang: {memberId: {"matches": n, "shuttles": n}}.
  usage jsonb not null default '{}'::jsonb check (jsonb_typeof(usage) = 'object'),
  -- Catatan per match: [{"court": n, "players": [...], "shuttles": n}].
  matches jsonb not null default '[]'::jsonb check (jsonb_typeof(matches) = 'array'),
  created_at timestamptz not null default now()
);

create index session_events_pb_idx on public.session_events (pb_id, start_at);

create table public.attendance (
  event_id text not null references public.session_events (id) on delete cascade,
  member_id text not null references public.members (id) on delete cascade,
  primary key (event_id, member_id)
);

create table public.rsvps (
  event_id text not null references public.session_events (id) on delete cascade,
  member_id text not null references public.members (id) on delete cascade,
  status text not null check (status in ('ikut', 'tidak')),
  updated_at timestamptz not null default now(),
  primary key (event_id, member_id)
);

-- Satu catatan iuran per member per sesi. Hapus member tidak menghapus
-- catatan uang yang sudah dibayar: lihat trigger members_before_delete.
create table public.dues (
  event_id text not null references public.session_events (id) on delete cascade,
  member_id text not null references public.members (id) on delete cascade,
  amount integer not null check (amount between 0 and 5000000),
  paid boolean not null default false,
  paid_at timestamptz,
  cancelled_at timestamptz,
  proof_path text,
  proof_status text check (proof_status is null or proof_status in ('menunggu', 'disetujui', 'ditolak')),
  proof_reason text check (proof_reason is null or char_length(proof_reason) <= 300),
  proof_sent_at timestamptz,
  refund_status text check (refund_status is null or refund_status in ('perlu', 'diajukan', 'tidakKembali', 'selesai')),
  refund_cancelled_at timestamptz,
  refund_reason text check (refund_reason is null or char_length(refund_reason) <= 300),
  refund_requested boolean not null default false,
  refund_rejected boolean not null default false,
  refund_done_at timestamptz,
  updated_at timestamptz not null default now(),
  primary key (event_id, member_id),
  check (refund_status is null or refund_cancelled_at is not null)
);

create trigger dues_touch before update on public.dues
  for each row execute function public.touch_updated_at();

commit;
