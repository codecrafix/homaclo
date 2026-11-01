-- One review (and one +10 coin reward) per booking. Deleting the review does NOT free the slot.
-- Already applied to the live Supabase project; kept here so the repo matches the database.

create table if not exists public.review_locks (
  booking_id uuid primary key,
  user_id    uuid not null,
  review_id  uuid,
  rewarded   boolean not null default false,
  created_at timestamptz not null default now()
);
create index if not exists review_locks_user_idx on public.review_locks (user_id);
alter table public.review_locks enable row level security;
drop policy if exists "users read own review locks" on public.review_locks;
create policy "users read own review locks" on public.review_locks
  for select using (user_id = (select public.current_uid()));
revoke insert, update, delete on public.review_locks from anon, authenticated;

-- Existing state: lock the latest booking of everyone who already reviewed it (even if the review was deleted later)
insert into public.review_locks (booking_id, user_id, rewarded)
select b.id, b.user_id, true
from (select distinct on (user_id) id, user_id, created_at from public.bookings order by user_id, created_at desc) b
where exists (select 1 from public.reviews r where r.user_id = b.user_id and r.created_at > b.created_at)
   or exists (select 1 from public.coin_transactions t
               where t.user_id = b.user_id and t.type = 'reward'
                 and t.description like 'Review submitted%' and t.created_at > b.created_at)
on conflict (booking_id) do nothing;

-- Gate: a client may only write a review for its latest booking, and only once
create or replace function public.reviews_lock_once()
returns trigger
language plpgsql
security definer
set search_path to 'public', 'pg_temp'
as $$
declare b uuid;
begin
  if coalesce(current_setting('role', true), '') in ('authenticated', 'anon') and not public.is_admin_user() then
    if new.user_id is null then
      raise exception 'review_user_required';
    end if;
    select id into b from public.bookings where user_id = new.user_id order by created_at desc limit 1;
    if b is null then
      raise exception 'review_requires_booking';
    end if;
    begin
      insert into public.review_locks (booking_id, user_id, review_id) values (b, new.user_id, new.id);
    exception when unique_violation then
      raise exception 'review_already_submitted';
    end;
  end if;
  return new;
end;
$$;
drop trigger if exists reviews_lock_trg on public.reviews;
create trigger reviews_lock_trg before insert on public.reviews
  for each row execute function public.reviews_lock_once();

-- Reward: +10 coins exactly once per lock, only for reviews that passed the gate
create or replace function public.reviews_reward()
returns trigger
language plpgsql
security definer
set search_path to 'public', 'pg_temp'
as $$
declare v_b uuid;
begin
  update public.review_locks set rewarded = true
   where review_id = new.id and rewarded = false
   returning booking_id into v_b;
  if v_b is not null then
    insert into public.user_coins (user_id, balance) values (new.user_id, 10)
      on conflict (user_id) do update set balance = public.user_coins.balance + 10, updated_at = now();
    insert into public.coin_transactions (user_id, amount, type, description)
      values (new.user_id, 10, 'reward', 'Review submitted for ' || coalesce(new.service_name, 'service'));
  end if;
  return null;
end;
$$;
