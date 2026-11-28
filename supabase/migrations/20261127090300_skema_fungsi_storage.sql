-- YukBadmin: skema awal Supabase, bagian 4 dari 4: fungsi tindakan member, toko partner, hak fungsi, dan storage.
--
-- Jalankan setelah bagian 3. Keempat bagian sama dengan skema yang sudah
-- dijalankan di project pada 27 November 2026.

begin;

-- ---------------------------------------------------------------------------
-- Fungsi untuk tindakan member (aturan iuran ditegakkan di server)
-- ---------------------------------------------------------------------------

-- Konfirmasi ikut atau tidak ikut untuk sesi mendatang. Sama dengan
-- SessionEvent.confirm dan SessionEvent.cancel di app.
create or replace function public.member_set_rsvp(p_event text, p_status text)
returns void
language plpgsql
security definer
set search_path = ''
as $$
declare
  ev public.session_events;
  pb public.pbs;
  me text;
  d public.dues;
  before_play boolean;
  cancel_hours integer;
begin
  if auth.uid() is null then
    raise exception 'Masuk dulu untuk menjawab.' using errcode = '28000';
  end if;
  if p_status not in ('ikut', 'tidak') then
    raise exception 'Jawaban tidak dikenal.' using errcode = '22023';
  end if;
  select * into ev from public.session_events where id = p_event;
  if not found then
    raise exception 'Sesi tidak ditemukan.' using errcode = 'P0002';
  end if;
  me := public.my_member_id(ev.pb_id);
  if me is null then
    raise exception 'Kamu bukan member PB ini.' using errcode = '42501';
  end if;
  if ev.start_at <= now() then
    raise exception 'Sesi sudah dimulai.' using errcode = '22023';
  end if;
  select * into pb from public.pbs where id = ev.pb_id;
  before_play := coalesce(pb.dues_system ->> 'timing', 'sebelum') = 'sebelum';
  cancel_hours := coalesce((pb.dues_system ->> 'cancelHours')::integer, 24);

  insert into public.rsvps (event_id, member_id, status, updated_at)
  values (p_event, me, p_status, now())
  on conflict (event_id, member_id) do update set status = excluded.status, updated_at = now();

  select * into d from public.dues where event_id = p_event and member_id = me for update;

  if p_status = 'ikut' then
    if not found then
      if before_play then
        insert into public.dues (event_id, member_id, amount) values (p_event, me, pb.fee_per_session);
      end if;
    elsif d.refund_status = 'selesai' then
      if before_play then
        -- Uang sudah kembali: tagihan dibuat ulang dari awal.
        delete from public.dues where event_id = p_event and member_id = me;
        insert into public.dues (event_id, member_id, amount) values (p_event, me, pb.fee_per_session);
      else
        delete from public.dues where event_id = p_event and member_id = me;
      end if;
    else
      update public.dues set
        cancelled_at = null,
        refund_status = null, refund_cancelled_at = null, refund_reason = null,
        refund_requested = false, refund_rejected = false, refund_done_at = null
      where event_id = p_event and member_id = me;
    end if;
  else
    if found and d.refund_status is null then
      if d.paid then
        update public.dues set
          refund_status = case
            when ev.start_at - now() >= make_interval(hours => cancel_hours) then 'perlu'
            else 'tidakKembali' end,
          refund_cancelled_at = now()
        where event_id = p_event and member_id = me;
      elsif d.proof_status = 'menunggu' then
        update public.dues set cancelled_at = now()
        where event_id = p_event and member_id = me;
      elsif d.cancelled_at is null then
        delete from public.dues where event_id = p_event and member_id = me;
      end if;
    end if;
  end if;
end;
$$;

-- Member mengirim bukti transfer untuk iurannya yang belum lunas. Berkas
-- diunggah dulu ke bucket bukti-transfer di folder miliknya.
create or replace function public.member_submit_proof(p_event text, p_path text)
returns void
language plpgsql
security definer
set search_path = ''
as $$
declare
  ev public.session_events;
  me text;
begin
  select * into ev from public.session_events where id = p_event;
  if not found then
    raise exception 'Sesi tidak ditemukan.' using errcode = 'P0002';
  end if;
  me := public.my_member_id(ev.pb_id);
  if me is null then
    raise exception 'Kamu bukan member PB ini.' using errcode = '42501';
  end if;
  -- Path wajib di folder milik pengirim: <pb>/<sesi>/<akun>/<berkas>.
  if p_path is null
     or split_part(p_path, '/', 1) <> ev.pb_id
     or split_part(p_path, '/', 2) <> p_event
     or split_part(p_path, '/', 3) <> auth.uid()::text then
    raise exception 'Letak berkas bukti tidak sesuai.' using errcode = '22023';
  end if;
  update public.dues set
    proof_path = p_path, proof_status = 'menunggu', proof_reason = null, proof_sent_at = now()
  where event_id = p_event and member_id = me and not paid and refund_status is null;
  if not found then
    raise exception 'Tidak ada iuran yang perlu dibayar di sesi ini.' using errcode = 'P0002';
  end if;
end;
$$;

-- Member yang batal mendadak mengajukan pengembalian dengan alasan.
create or replace function public.member_request_refund(p_event text, p_reason text)
returns void
language plpgsql
security definer
set search_path = ''
as $$
declare
  ev public.session_events;
  me text;
begin
  if p_reason is null or char_length(trim(p_reason)) not between 2 and 300 then
    raise exception 'Tulis alasan pengembalian.' using errcode = '22023';
  end if;
  select * into ev from public.session_events where id = p_event;
  if not found then
    raise exception 'Sesi tidak ditemukan.' using errcode = 'P0002';
  end if;
  me := public.my_member_id(ev.pb_id);
  if me is null then
    raise exception 'Kamu bukan member PB ini.' using errcode = '42501';
  end if;
  update public.dues set
    refund_status = 'diajukan', refund_reason = trim(p_reason), refund_requested = true
  where event_id = p_event and member_id = me and refund_status = 'tidakKembali';
  if not found then
    raise exception 'Pengembalian tidak bisa diajukan untuk sesi ini.' using errcode = '22023';
  end if;
end;
$$;

-- Jumlah yang ikut per sesi, tanpa nama. Untuk PB-ku dan Beranda.
create or replace function public.event_going_count(p_event text)
returns integer
language sql
stable
security definer
set search_path = ''
as $$
  select case
    when public.is_pb_manager(public.event_pb(p_event)) or public.is_pb_member(public.event_pb(p_event))
    then (select count(*)::integer from public.rsvps where event_id = p_event and status = 'ikut')
    else null end;
$$;

-- Toko partner dibuat dengan kode undangan sekali pakai.
create or replace function public.redeem_partner_invite(
  p_code text,
  p_name text,
  p_whatsapp text,
  p_address text,
  p_district text,
  p_hours text,
  p_description text default '',
  p_maps_url text default null
)
returns text
language plpgsql
security definer
set search_path = ''
as $$
declare
  shop_id text;
begin
  if auth.uid() is null then
    raise exception 'Masuk dulu untuk mendaftarkan toko.' using errcode = '28000';
  end if;
  if exists (select 1 from public.shops where owner_id = auth.uid()) then
    raise exception 'Akun ini sudah punya toko.' using errcode = '23505';
  end if;
  update public.partner_invites
    set used_by = auth.uid(), used_at = now()
    where code = upper(trim(p_code)) and used_by is null;
  if not found then
    raise exception 'Kode undangan tidak dikenal atau sudah dipakai.' using errcode = '22023';
  end if;
  insert into public.shops (owner_id, name, whatsapp, address, district, hours, description, maps_url)
  values (auth.uid(), p_name, p_whatsapp, p_address, p_district, p_hours, coalesce(p_description, ''), p_maps_url)
  returning id into shop_id;
  return shop_id;
end;
$$;

-- Fungsi hanya untuk akun yang masuk, bukan pengunjung tanpa akun.
revoke execute on all functions in schema public from public, anon;
grant execute on function
  public.member_set_rsvp(text, text),
  public.member_submit_proof(text, text),
  public.member_request_refund(text, text),
  public.event_going_count(text),
  public.redeem_partner_invite(text, text, text, text, text, text, text, text),
  public.is_pb_manager(text),
  public.is_pb_owner(text),
  public.is_pb_member(text),
  public.my_member_id(text),
  public.event_pb(text),
  public.is_member_self(text),
  public.is_shop_owner(text),
  public.new_id(text)
to authenticated;

-- ---------------------------------------------------------------------------
-- Storage
-- ---------------------------------------------------------------------------

insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values
  ('pb-media', 'pb-media', true, 5242880, array['image/jpeg', 'image/png', 'image/webp']),
  ('toko-media', 'toko-media', true, 5242880, array['image/jpeg', 'image/png', 'image/webp']),
  ('bukti-transfer', 'bukti-transfer', false, 5242880, array['image/jpeg', 'image/png', 'image/webp'])
on conflict (id) do nothing;

-- storage.objects selalu memakai RLS di Supabase (tidak bisa dimatikan), jadi
-- tanpa policy unggahan akan ditolak. Policy ini sengaja longgar, mengikuti
-- keputusan tanpa RLS: akun yang masuk boleh mengelola berkas di ketiga bucket.
create policy "berkas yukbadmin dikelola akun" on storage.objects
  for all to authenticated
  using (bucket_id in ('pb-media', 'toko-media', 'bukti-transfer'))
  with check (bucket_id in ('pb-media', 'toko-media', 'bukti-transfer'));

commit;
