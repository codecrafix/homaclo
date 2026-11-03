-- Homaclo Refer & Earn.
-- ALREADY APPLIED to the live database (migration version 20261103144812, name "referral_system").
-- This file is a copy of what is live, kept in the repo so the repo and the database match. Safe to re-run.
--
-- How it works:
--   * every signed-in customer gets one personal 8-character code (get_my_referral_code)
--   * a friend opens the link, signs up, and claim_referral() records the referral as 'pending'
--   * when the friend's FIRST booking of Rs 500 or more is created (bookings are only created after payment),
--     the trigger referral_on_booking marks it 'rewarded' and gives 50 coins to BOTH people,
--     or marks it 'rejected' with a reject_reason (not_first_booking, referrer_missing, same_person,
--     same_address, monthly_limit = referrer already got 10 rewards in the last 30 days)
--   * admins can only read referrals in the dashboard; rewards are never given by hand

create table if not exists public.referral_codes (
  user_id    uuid primary key references public.profiles(id) on delete cascade,
  code       text not null unique check (code ~ '^[A-Z0-9]{8}$'),
  created_at timestamptz not null default now()
);

create table if not exists public.referrals (
  id            uuid primary key default gen_random_uuid(),
  referrer_id   uuid not null references public.profiles(id) on delete cascade,
  referred_id   uuid not null unique references public.profiles(id) on delete cascade,
  code          text not null,
  status        text not null default 'pending' check (status in ('pending','rewarded','rejected')),
  coins_each    integer not null default 50,
  booking_id    uuid,
  reject_reason text,
  created_at    timestamptz not null default now(),
  rewarded_at   timestamptz,
  check (referrer_id <> referred_id)
);

create index if not exists referrals_referrer_idx on public.referrals (referrer_id, status);

alter table public.referral_codes enable row level security;
alter table public.referrals enable row level security;

drop policy if exists referral_codes_read on public.referral_codes;
create policy referral_codes_read on public.referral_codes for select
  using (user_id = public.current_uid() or public.is_admin_user());

drop policy if exists referrals_read on public.referrals;
create policy referrals_read on public.referrals for select
  using (referrer_id = public.current_uid() or referred_id = public.current_uid() or public.is_admin_user());

drop policy if exists referrals_admin_update on public.referrals;
create policy referrals_admin_update on public.referrals for update
  using (public.is_admin_user()) with check (public.is_admin_user());

revoke all on public.referral_codes, public.referrals from anon, authenticated;
grant select on public.referral_codes to authenticated;
grant select, update on public.referrals to authenticated;

-- gmail-style normalisation so a + alias or dots cannot be used to refer yourself
create or replace function public._norm_email(e text)
returns text language sql immutable as $$
  select case when split_part(lower(trim(e)),'@',2) in ('gmail.com','googlemail.com')
    then replace(split_part(split_part(lower(trim(e)),'@',1),'+',1),'.','') || '@gmail.com'
    else split_part(split_part(lower(trim(e)),'@',1),'+',1) || '@' || split_part(lower(trim(e)),'@',2) end
$$;

create or replace function public._give_referral_coins(p_user uuid, p_n integer, p_desc text)
returns void language plpgsql security definer set search_path to 'public', 'pg_temp' as $$
begin
  insert into public.user_coins (user_id, balance) values (p_user, p_n)
    on conflict (user_id) do update set balance = public.user_coins.balance + p_n, updated_at = now();
  insert into public.coin_transactions (user_id, amount, type, description) values (p_user, p_n, 'referral', p_desc);
  insert into public.notifications (user_id, title, body, type)
    values (p_user, 'Referral reward 🎁', 'You received ' || p_n || ' coins (value ₹' || p_n || ') from Refer & Earn.', 'referral');
end $$;

create or replace function public.get_my_referral_code()
returns text language plpgsql security definer set search_path to 'public', 'pg_temp' as $$
declare uid uuid := public.current_uid(); v text; v2 text; alpha text := 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789'; i int; n int;
begin
  if uid is null then raise exception 'not signed in'; end if;
  select code into v from public.referral_codes where user_id = uid;
  if found then return v; end if;
  if not exists (select 1 from public.profiles where id = uid) then raise exception 'profile not ready'; end if;
  for n in 1..12 loop
    v := '';
    for i in 1..8 loop v := v || substr(alpha, 1 + floor(random() * length(alpha))::int, 1); end loop;
    begin
      insert into public.referral_codes (user_id, code) values (uid, v);
      return v;
    exception when unique_violation then
      select code into v2 from public.referral_codes where user_id = uid;
      if found then return v2; end if;
    end;
  end loop;
  raise exception 'could not create code';
end $$;

create or replace function public.claim_referral(p_code text)
returns jsonb language plpgsql security definer set search_path to 'public', 'pg_temp' as $$
declare uid uuid := public.current_uid(); c text := upper(trim(coalesce(p_code, ''))); v_ref uuid; v_created timestamptz; e1 text; e2 text;
begin
  if uid is null then return jsonb_build_object('ok', false, 'final', false, 'message', 'Please sign in first'); end if;
  if c !~ '^[A-Z0-9]{8}$' then return jsonb_build_object('ok', false, 'final', true, 'message', 'This referral link is not valid'); end if;
  if exists (select 1 from public.referrals where referred_id = uid) then return jsonb_build_object('ok', true, 'final', true, 'already', true, 'message', 'Referral already applied'); end if;
  if not exists (select 1 from public.profiles where id = uid) then return jsonb_build_object('ok', false, 'final', false, 'message', 'Setting up your account'); end if;
  select user_id into v_ref from public.referral_codes where code = c;
  if v_ref is null then return jsonb_build_object('ok', false, 'final', true, 'message', 'This referral link is not valid'); end if;
  if v_ref = uid then return jsonb_build_object('ok', false, 'final', true, 'message', 'You cannot use your own referral link'); end if;
  if exists (select 1 from public.bookings where user_id = uid) then return jsonb_build_object('ok', false, 'final', true, 'message', 'Referral rewards are only for new customers on their first booking'); end if;
  select created_at into v_created from auth.users where id = uid;
  if v_created is not null and v_created < now() - interval '7 days' then return jsonb_build_object('ok', false, 'final', true, 'message', 'Referral rewards are only for newly created accounts'); end if;
  select email into e1 from public.profiles where id = uid;
  select email into e2 from public.profiles where id = v_ref;
  if e1 is not null and e2 is not null and public._norm_email(e1) = public._norm_email(e2) then return jsonb_build_object('ok', false, 'final', true, 'message', 'You cannot use your own referral link'); end if;
  insert into public.referrals (referrer_id, referred_id, code) values (v_ref, uid, c) on conflict (referred_id) do nothing;
  return jsonb_build_object('ok', true, 'final', true, 'message', 'Referral applied! You and your friend get 50 coins each after your first booking of ₹500 or more.');
end $$;

create or replace function public.my_referral_summary()
returns jsonb language plpgsql security definer set search_path to 'public', 'pg_temp' as $$
declare uid uuid := public.current_uid(); v_code text;
begin
  if uid is null then raise exception 'not signed in'; end if;
  v_code := public.get_my_referral_code();
  return jsonb_build_object(
    'code', v_code,
    'invited', (select count(*) from public.referrals where referrer_id = uid),
    'pending', (select count(*) from public.referrals where referrer_id = uid and status = 'pending'),
    'rewarded', (select count(*) from public.referrals where referrer_id = uid and status = 'rewarded'),
    'rejected', (select count(*) from public.referrals where referrer_id = uid and status = 'rejected'),
    'coins_earned', (select coalesce(sum(coins_each), 0) from public.referrals where referrer_id = uid and status = 'rewarded'),
    'items', coalesce((select jsonb_agg(jsonb_build_object('name', coalesce(nullif(left(trim(r.full_name), 1), ''), 'U') || '***', 'status', r.status, 'joined', r.created_at, 'rewarded_at', r.rewarded_at, 'coins', case when r.status = 'rewarded' then r.coins_each else 0 end) order by r.created_at desc)
        from (select r0.*, p.full_name from public.referrals r0 left join public.profiles p on p.id = r0.referred_id where r0.referrer_id = uid order by r0.created_at desc limit 50) r), '[]'::jsonb),
    'referred_by', (select jsonb_build_object('status', r.status, 'coins', r.coins_each) from public.referrals r where r.referred_id = uid)
  );
end $$;

create or replace function public.referral_on_booking()
returns trigger language plpgsql security definer set search_path to 'public', 'pg_temp' as $$
declare r public.referrals%rowtype; e_new text; e_ref text; v_cnt int; v_reason text;
begin
  begin
    if coalesce(new.price, 0) < 500 then return null; end if;
    select * into r from public.referrals where referred_id = new.user_id and status = 'pending' for update;
    if not found then return null; end if;
    select email into e_new from public.profiles where id = new.user_id;
    select email into e_ref from public.profiles where id = r.referrer_id;
    if exists (select 1 from public.bookings b where b.user_id = new.user_id and b.id <> new.id) then
      v_reason := 'not_first_booking';
    elsif e_ref is null then
      v_reason := 'referrer_missing';
    elsif public._norm_email(e_new) = public._norm_email(e_ref) then
      v_reason := 'same_person';
    elsif nullif(regexp_replace(lower(coalesce(new.address, '')), '[^a-z0-9]', '', 'g'), '') is not null
      and exists (select 1 from public.bookings b where b.user_id = r.referrer_id
        and regexp_replace(lower(coalesce(b.address, '')), '[^a-z0-9]', '', 'g') = regexp_replace(lower(coalesce(new.address, '')), '[^a-z0-9]', '', 'g')) then
      v_reason := 'same_address';
    else
      select count(*) into v_cnt from public.referrals where referrer_id = r.referrer_id and status = 'rewarded' and rewarded_at > now() - interval '30 days';
      if v_cnt >= 10 then v_reason := 'monthly_limit'; end if;
    end if;
    if v_reason is not null then
      update public.referrals set status = 'rejected', reject_reason = v_reason, booking_id = new.id where id = r.id;
      return null;
    end if;
    update public.referrals set status = 'rewarded', booking_id = new.id, rewarded_at = now() where id = r.id;
    perform public._give_referral_coins(r.referrer_id, r.coins_each, 'Referral reward: your friend made a booking');
    perform public._give_referral_coins(new.user_id, r.coins_each, 'Referral reward: booking via a friend''s link');
  exception when others then
    raise warning 'referral reward skipped: %', sqlerrm;
  end;
  return null;
end $$;

drop trigger if exists referral_on_booking_trg on public.bookings;
create trigger referral_on_booking_trg after insert on public.bookings
  for each row execute function public.referral_on_booking();

revoke all on function public._give_referral_coins(uuid, integer, text) from public, anon, authenticated;
revoke all on function public.referral_on_booking() from public, anon, authenticated;
revoke all on function public.get_my_referral_code() from public, anon;
revoke all on function public.claim_referral(text) from public, anon;
revoke all on function public.my_referral_summary() from public, anon;
grant execute on function public.get_my_referral_code() to authenticated;
grant execute on function public.claim_referral(text) to authenticated;
grant execute on function public.my_referral_summary() to authenticated;
