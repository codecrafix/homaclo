-- Server-side, idempotent 50-coin signup bonus so App and Website behave identically.
-- Root cause: both clients only awarded the bonus when the profile row did not exist yet,
-- but the on_auth_user_created trigger already creates it, so the bonus never fired.

create or replace function public._grant_signup_bonus(p_user uuid)
returns boolean
language plpgsql
security definer
set search_path to 'public', 'pg_temp'
as $$
declare
  v_claimed uuid;
begin
  -- Atomic claim: only users with the flag unset AND no coin history at all are eligible.
  update public.profiles
     set signup_bonus_awarded = true
   where id = p_user
     and signup_bonus_awarded = false
     and not exists (select 1 from public.coin_transactions t where t.user_id = p_user)
  returning id into v_claimed;

  if v_claimed is null then
    return false;
  end if;

  insert into public.user_coins (user_id, balance)
  values (p_user, 50)
  on conflict (user_id) do update
    set balance = public.user_coins.balance + 50, updated_at = now();

  insert into public.coin_transactions (user_id, amount, type, description)
  values (p_user, 50, 'welcome', 'Welcome signup bonus');

  insert into public.notifications (user_id, title, body, type) values
    (p_user, 'Welcome to Homaclo! 🚰', 'Book your professional water tank cleaning slot today.', 'welcome'),
    (p_user, 'Welcome Bonus! 🪙', 'You received 50 Coins on signup! (Value ₹50)', 'welcome'),
    (p_user, 'Welcome Offer! 🎁', 'Get ₹100 Flat Discount on your first booking using code WEL100!', 'coupon');

  return true;
end;
$$;
revoke all on function public._grant_signup_bonus(uuid) from public, anon, authenticated;

create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer
set search_path to 'public', 'pg_temp'
as $$
declare
  v_rows integer := 0;
begin
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
      -- Never block signup because of the bonus; clients retry via claim_signup_bonus().
      raise warning 'signup bonus failed for %: %', new.id, sqlerrm;
    end;
  end if;

  return new;
end;
$$;

-- Safe fallback the website/app can call after login (own account only, one-time, atomic).
create or replace function public.claim_signup_bonus()
returns boolean
language plpgsql
security definer
set search_path to 'public', 'pg_temp'
as $$
begin
  if auth.uid() is null then
    return false;
  end if;
  return public._grant_signup_bonus(auth.uid());
end;
$$;
revoke all on function public.claim_signup_bonus() from public, anon;
grant execute on function public.claim_signup_bonus() to authenticated;

-- Metadata parity: profiles created by the old trigger had an empty email.
update public.profiles p
   set email = u.email
  from auth.users u
 where u.id = p.id and coalesce(p.email, '') = '' and u.email is not null;
