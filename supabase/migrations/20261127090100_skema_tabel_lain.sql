-- YukBadmin: skema awal Supabase, bagian 2 dari 4: tabel lain (PB tersimpan, toko, produk, kode undangan) dan fungsi bantu.
--
-- Jalankan setelah bagian 1. Keempat bagian sama dengan skema yang sudah
-- dijalankan di project pada 27 November 2026.

begin;

-- ---------------------------------------------------------------------------
-- Data pribadi pemain: PB tersimpan dan riwayat dihubungi
-- ---------------------------------------------------------------------------

create table public.saved_pbs (
  user_id uuid not null default auth.uid() references auth.users (id) on delete cascade,
  pb_id text not null references public.pbs (id) on delete cascade,
  created_at timestamptz not null default now(),
  primary key (user_id, pb_id)
);

create table public.contacted_pbs (
  user_id uuid not null default auth.uid() references auth.users (id) on delete cascade,
  pb_id text not null references public.pbs (id) on delete cascade,
  contacted_at timestamptz not null default now(),
  primary key (user_id, pb_id)
);

-- ---------------------------------------------------------------------------
-- Toko partner dan produk
-- ---------------------------------------------------------------------------

create table public.shops (
  id text primary key default public.new_id('toko'),
  owner_id uuid unique references auth.users (id) on delete set null,
  name text not null check (char_length(name) between 3 and 80),
  whatsapp text not null check (whatsapp ~ '^62[0-9]{8,13}$'),
  address text not null check (char_length(address) between 5 and 200),
  district text not null check (char_length(district) between 2 and 60),
  hours text not null check (char_length(hours) between 2 and 120),
  description text not null default '' check (char_length(description) <= 1000),
  maps_url text check (maps_url is null or maps_url ~ '^https://'),
  logo_url text,
  cover_url text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create trigger shops_touch before update on public.shops
  for each row execute function public.touch_updated_at();

create table public.products (
  id text primary key default public.new_id('produk'),
  shop_id text not null references public.shops (id) on delete cascade,
  name text not null check (char_length(name) between 2 and 80),
  category text not null check (category in ('raket', 'sepatu', 'senar', 'grip')),
  price integer not null check (price between 0 and 100000000),
  in_stock boolean not null default true,
  description text not null default '' check (char_length(description) <= 1000),
  racket_weight text check (racket_weight is null or racket_weight in ('u3', 'u4', 'u5')),
  racket_balance text check (racket_balance is null or racket_balance in ('headLight', 'even', 'headHeavy')),
  racket_flex text check (racket_flex is null or racket_flex in ('flexible', 'medium', 'stiff')),
  shoe_sizes smallint[] not null default '{}',
  string_type text check (string_type is null or string_type in ('tipis', 'tebal')),
  photo_url text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index products_shop_idx on public.products (shop_id);

create trigger products_touch before update on public.products
  for each row execute function public.touch_updated_at();

-- Kode undangan toko partner, dipakai lewat fungsi redeem_partner_invite.
-- Tanpa RLS, isi tabel ini bisa dibaca lewat API; buat kode baru per toko
-- dan anggap kode yang sudah dibagikan bukan rahasia.
create table public.partner_invites (
  code text primary key check (code = upper(code) and char_length(code) between 6 and 40),
  note text,
  used_by uuid references auth.users (id) on delete set null,
  used_at timestamptz,
  created_at timestamptz not null default now()
);

-- ---------------------------------------------------------------------------
-- Fungsi bantu (dipakai fungsi tindakan member)
-- ---------------------------------------------------------------------------

create or replace function public.is_pb_manager(p_pb text)
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select exists (
    select 1 from public.pb_managers
    where pb_id = p_pb and user_id = auth.uid() and status = 'aktif'
  );
$$;

create or replace function public.is_pb_owner(p_pb text)
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select exists (
    select 1 from public.pbs where id = p_pb and owner_id = auth.uid()
  );
$$;

create or replace function public.my_member_id(p_pb text)
returns text
language sql
stable
security definer
set search_path = ''
as $$
  select id from public.members
  where pb_id = p_pb and user_id = auth.uid() and archived_at is null;
$$;

create or replace function public.is_pb_member(p_pb text)
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select public.my_member_id(p_pb) is not null;
$$;

create or replace function public.event_pb(p_event text)
returns text
language sql
stable
security definer
set search_path = ''
as $$
  select pb_id from public.session_events where id = p_event;
$$;

create or replace function public.is_member_self(p_member text)
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select exists (
    select 1 from public.members where id = p_member and user_id = auth.uid()
  );
$$;

create or replace function public.is_shop_owner(p_shop text)
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select exists (
    select 1 from public.shops where id = p_shop and owner_id = auth.uid()
  );
$$;

commit;
