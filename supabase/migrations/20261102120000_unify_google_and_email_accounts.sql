-- One account per e-mail, whichever way the person signs in (email code or Google/Clerk, new or old, any order).
-- Already applied to the live Supabase project; kept here so the repo matches the database.

-- 1) A person may have several Clerk identities (dev -> production Clerk instance, re-created Google link, ...)
alter table public.clerk_identities drop constraint if exists clerk_identities_user_id_key;
drop index if exists public.clerk_identities_user_id_key;
create index if not exists clerk_identities_user_id_idx on public.clerk_identities (user_id);
create index if not exists profiles_email_lower_idx on public.profiles (lower(email));

-- 2) Move a profile (and everything attached to it) to another user id
create or replace function public._relink_profile(p_old uuid, p_new uuid)
returns void
language plpgsql
security definer
set search_path to 'public', 'pg_temp'
as $$
declare r public.profiles;
begin
  if p_old is null or p_new is null or p_old = p_new then return; end if;
  select * into r from public.profiles where id = p_old;
  if not found then return; end if;

  if not exists (select 1 from public.profiles where id = p_new) then
    insert into public.profiles
    select (jsonb_populate_record(null::public.profiles, to_jsonb(r) || jsonb_build_object('id', p_new))).*;
  end if;

  if exists (select 1 from public.user_coins where user_id = p_new) then
    update public.user_coins n set balance = n.balance + o.balance
      from public.user_coins o where n.user_id = p_new and o.user_id = p_old;
    delete from public.user_coins where user_id = p_old;
  else
    update public.user_coins set user_id = p_new where user_id = p_old;
  end if;

  update public.clerk_identities    set user_id = p_new where user_id = p_old;
  update public.bookings            set user_id = p_new where user_id = p_old;
  update public.payments            set user_id = p_new where user_id = p_old;
  update public.reviews             set user_id = p_new where user_id = p_old;
  update public.support_tickets     set user_id = p_new where user_id = p_old;
  update public.user_locations      set user_id = p_new where user_id = p_old;
  update public.notifications       set user_id = p_new where user_id = p_old;
  update public.coin_transactions   set user_id = p_new where user_id = p_old;
  update public.coupons             set allowed_user_id = p_new where allowed_user_id = p_old;
  update public.admin_broadcasts    set sent_by = p_new where sent_by = p_old;

  delete from public.profiles where id = p_old;
end;
$$;
revoke all on function public._relink_profile(uuid, uuid) from public, anon, authenticated;

-- 3) E-mail code sign-up: if this e-mail already has an account (created through Google first), adopt it instead of making a second one
create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer
set search_path to 'public', 'pg_temp'
as $$
declare
  v_rows integer := 0;
  v_em text := lower(nullif(new.email, ''));
  v_old uuid;
begin
  if v_em is not null then
    perform pg_advisory_xact_lock(hashtext('email_link:' || v_em));
    select p.id into v_old from public.profiles p
     where lower(p.email) = v_em and p.id <> new.id
     order by p.updated_at asc nulls last limit 1;
    if v_old is not null then
      begin
        perform public._relink_profile(v_old, new.id);
      exception when others then
        raise warning 'relink % -> % failed: %', v_old, new.id, sqlerrm;
      end;
    end if;
  end if;

  insert into public.profiles (id, email, full_name, phone_number, location, avatar_url, signup_bonus_awarded)
  values (
    new.id,
    coalesce(new.email, ''),
    coalesce(nullif(new.raw_user_meta_data->>'full_name', ''), split_part(coalesce(new.email, ''), '@', 1)),
    coalesce(new.raw_user_meta_data->>'phone_number', ''),
    coalesce(new.raw_user_meta_data->>'location', ''),
    new.raw_user_meta_data->>'avatar_url',
    false
  )
  on conflict (id) do nothing;

  get diagnostics v_rows = row_count;

  if v_rows = 1 then
    begin
      perform public._grant_signup_bonus(new.id);
    exception when others then
      raise warning 'signup bonus failed for %: %', new.id, sqlerrm;
    end;
  end if;

  return new;
end;
$$;

-- 4) Google (Clerk) sign-in: always join the account that already owns this e-mail (prefer the e-mail-code account), else create one
create or replace function public.ensure_clerk_profile()
returns uuid
language plpgsql
security definer
set search_path to 'public', 'pg_temp'
as $$
declare
  s text := auth.jwt() ->> 'sub';
  em text := lower(nullif(auth.jwt() ->> 'email', ''));
  nm text := nullif(auth.jwt() ->> 'full_name', '');
  av text := nullif(auth.jwt() ->> 'avatar', '');
  u uuid;
begin
  if s is null or s ~* '^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$' then
    return null;
  end if;
  select user_id into u from public.clerk_identities where clerk_id = s;
  if u is not null then return u; end if;
  if em is null then
    raise exception 'email claim missing in Clerk session token';
  end if;
  perform pg_advisory_xact_lock(hashtext('email_link:' || em));
  select user_id into u from public.clerk_identities where clerk_id = s;
  if u is not null then return u; end if;

  select p.id into u from public.profiles p
   where lower(p.email) = em
   order by exists (select 1 from auth.users a where a.id = p.id) desc, p.updated_at asc nulls last
   limit 1;

  if u is not null then
    insert into public.clerk_identities (clerk_id, user_id) values (s, u) on conflict (clerk_id) do nothing;
  else
    u := gen_random_uuid();
    insert into public.profiles (id, email, full_name, phone_number, location, avatar_url, signup_bonus_awarded)
    values (u, em, coalesce(nm, split_part(em, '@', 1)), '', '', av, false);
    insert into public.clerk_identities (clerk_id, user_id) values (s, u);
    begin
      perform public._grant_signup_bonus(u);
    exception when others then
      raise warning 'signup bonus failed for %: %', u, sqlerrm;
    end;
  end if;
  return u;
end;
$$;
