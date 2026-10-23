-- Monthly +50 coin bonus (same rules as the app's _checkMonthlyBonus), server-side so app and website
-- can never double-credit: 30 days since last monthly_bonus, or since the welcome bonus if none yet.
create or replace function public.claim_monthly_bonus()
returns boolean
language plpgsql
security definer
set search_path to 'public', 'pg_temp'
as $$
declare
  v_uid uuid := auth.uid();
  v_last timestamptz;
  v_welcome timestamptz;
begin
  if v_uid is null then return false; end if;
  if not exists (select 1 from public.profiles where id = v_uid) then return false; end if;

  perform pg_advisory_xact_lock(hashtext('monthly_bonus:' || v_uid::text));

  select max(created_at) into v_last from public.coin_transactions
   where user_id = v_uid and type = 'monthly_bonus';

  if v_last is not null then
    if now() - v_last < interval '30 days' then return false; end if;
  else
    select max(created_at) into v_welcome from public.coin_transactions
     where user_id = v_uid and type = 'welcome';
    if v_welcome is not null and now() - v_welcome < interval '30 days' then return false; end if;
    -- Brand-new account with no coin history: the signup bonus handles it, not this.
    if v_welcome is null and not exists (select 1 from public.coin_transactions where user_id = v_uid) then
      return false;
    end if;
  end if;

  insert into public.user_coins (user_id, balance) values (v_uid, 50)
  on conflict (user_id) do update set balance = public.user_coins.balance + 50, updated_at = now();

  insert into public.coin_transactions (user_id, amount, type, description)
  values (v_uid, 50, 'monthly_bonus', 'Monthly recurring bonus');

  insert into public.notifications (user_id, title, body, type)
  values (v_uid, 'Monthly Bonus! 🪙', '+50 Coins credited to your wallet this month!', 'bonus');

  return true;
end;
$$;
revoke all on function public.claim_monthly_bonus() from public, anon;
grant execute on function public.claim_monthly_bonus() to authenticated;
