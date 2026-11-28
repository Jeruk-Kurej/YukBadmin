-- YukBadmin: skema awal Supabase, bagian 3 dari 4: trigger integritas dan RLS yang dimatikan.
--
-- Jalankan setelah bagian 2. Keempat bagian sama dengan skema yang sudah
-- dijalankan di project pada 27 November 2026.

begin;

-- ---------------------------------------------------------------------------
-- Trigger integritas
-- ---------------------------------------------------------------------------

-- Pendaftar PB otomatis jadi pemilik dan pengurus aktif.
create or replace function public.pb_after_insert()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  if new.owner_id is not null then
    insert into public.pb_managers (pb_id, user_id, role, status, name, whatsapp)
    values (new.id, new.owner_id, 'pemilik', 'aktif', new.manager_name, new.manager_whatsapp)
    on conflict (pb_id, user_id) do nothing;
  end if;
  insert into public.pb_private (pb_id) values (new.id) on conflict do nothing;
  return new;
end;
$$;

create trigger pbs_after_insert after insert on public.pbs
  for each row execute function public.pb_after_insert();

-- Pemilik dan jumlah member tidak bisa diubah dari app.
create or replace function public.pb_guard_update()
returns trigger
language plpgsql
set search_path = ''
as $$
begin
  if current_user in ('authenticated', 'anon') then
    new.owner_id := old.owner_id;
    new.member_count := old.member_count;
  end if;
  return new;
end;
$$;

create trigger pbs_guard before update on public.pbs
  for each row execute function public.pb_guard_update();

-- PB baru selalu dimiliki pendaftarnya, jumlah member mulai dari 0.
create or replace function public.pb_guard_insert()
returns trigger
language plpgsql
set search_path = ''
as $$
begin
  if current_user in ('authenticated', 'anon') then
    new.owner_id := auth.uid();
    new.member_count := 0;
  end if;
  return new;
end;
$$;

create trigger pbs_guard_insert before insert on public.pbs
  for each row execute function public.pb_guard_insert();

-- Jumlah member di kartu PB mengikuti tabel members.
create or replace function public.members_count_sync()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  if tg_op = 'INSERT' then
    update public.pbs set member_count = member_count + 1 where id = new.pb_id;
  elsif tg_op = 'DELETE' then
    update public.pbs set member_count = greatest(member_count - 1, 0) where id = old.pb_id;
  end if;
  return null;
end;
$$;

create trigger members_count after insert or delete on public.members
  for each row execute function public.members_count_sync();

-- Hapus member: tagihan belum lunas, kehadiran, dan konfirmasi ikut dibuang.
-- Kalau masih ada uang lunas atau pengembalian, member diarsipkan (tidak
-- dihapus) supaya catatan uangnya tetap ada. Sama dengan removeMember di app.
create or replace function public.members_before_delete()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  delete from public.dues
    where member_id = old.id and not paid and refund_status is null;
  delete from public.attendance where member_id = old.id;
  delete from public.rsvps where member_id = old.id;
  if exists (select 1 from public.dues where member_id = old.id) then
    if old.archived_at is null then
      update public.members set archived_at = now(), user_id = null where id = old.id;
      update public.pbs set member_count = greatest(member_count - 1, 0) where id = old.pb_id;
    end if;
    return null;
  end if;
  if old.archived_at is not null then
    -- Sudah tidak dihitung saat diarsipkan; batalkan pengurangan berikutnya.
    update public.pbs set member_count = member_count + 1 where id = old.pb_id;
  end if;
  return old;
end;
$$;

create trigger members_before_delete before delete on public.members
  for each row execute function public.members_before_delete();

-- Member tidak bisa dipindah ke PB lain atau dihubungkan ke akun lain
-- secara diam-diam oleh pengurus.
create or replace function public.members_guard_update()
returns trigger
language plpgsql
set search_path = ''
as $$
begin
  if current_user in ('authenticated', 'anon') then
    new.pb_id := old.pb_id;
    if old.user_id is not null then
      new.user_id := old.user_id;
    end if;
  end if;
  return new;
end;
$$;

create trigger members_guard before update on public.members
  for each row execute function public.members_guard_update();

-- Sesi tidak bisa dipindah ke PB lain.
create or replace function public.events_guard_update()
returns trigger
language plpgsql
set search_path = ''
as $$
begin
  new.pb_id := old.pb_id;
  return new;
end;
$$;

create trigger session_events_guard before update on public.session_events
  for each row execute function public.events_guard_update();

-- Pemilik toko tidak bisa diubah dari app.
create or replace function public.shops_guard_update()
returns trigger
language plpgsql
set search_path = ''
as $$
begin
  if current_user in ('authenticated', 'anon') then
    new.owner_id := old.owner_id;
  end if;
  return new;
end;
$$;

create trigger shops_guard before update on public.shops
  for each row execute function public.shops_guard_update();

-- Pemilik PB tidak bisa diturunkan atau dihapus lewat tabel pengurus.
create or replace function public.pb_managers_guard()
returns trigger
language plpgsql
set search_path = ''
as $$
begin
  if current_user in ('authenticated', 'anon') then
    if tg_op = 'DELETE' then
      if old.role = 'pemilik' then
        raise exception 'Pemilik PB tidak bisa dihapus dari daftar pengurus.';
      end if;
      return old;
    end if;
    if tg_op = 'INSERT' then
      -- Undangan selalu mulai sebagai pengurus yang belum aktif.
      new.role := 'pengurus';
      new.status := 'diundang';
      new.user_id := null;
      return new;
    end if;
    -- UPDATE
    new.pb_id := old.pb_id;
    new.role := old.role;
    new.user_id := old.user_id;
    new.status := old.status;
  end if;
  if tg_op = 'DELETE' then
    return old;
  end if;
  return new;
end;
$$;

create trigger pb_managers_guard before insert or update or delete on public.pb_managers
  for each row execute function public.pb_managers_guard();

-- ---------------------------------------------------------------------------
-- Row Level Security: SENGAJA TIDAK DIPAKAI (keputusan tim, 27 November 2026)
-- ---------------------------------------------------------------------------
-- Tanpa RLS, siapa pun yang memegang publishable key (ikut di dalam app) bisa
-- membaca dan mengubah semua tabel lewat API Supabase. Lihat docs/SUPABASE.md
-- untuk risikonya dan cara menyalakan RLS kalau nanti dibutuhkan.

-- Dimatikan eksplisit, kalau project menyalakan RLS otomatis untuk tabel baru.
alter table public.profiles disable row level security;
alter table public.pbs disable row level security;
alter table public.pb_private disable row level security;
alter table public.pb_sessions disable row level security;
alter table public.pb_managers disable row level security;
alter table public.members disable row level security;
alter table public.session_events disable row level security;
alter table public.attendance disable row level security;
alter table public.rsvps disable row level security;
alter table public.dues disable row level security;
alter table public.saved_pbs disable row level security;
alter table public.contacted_pbs disable row level security;
alter table public.shops disable row level security;
alter table public.products disable row level security;
alter table public.partner_invites disable row level security;

commit;
