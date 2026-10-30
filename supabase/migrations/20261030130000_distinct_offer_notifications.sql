-- Distinct promo notification for every service/promotion (already applied to
-- Supabase: offer_pool_distinct_notifications).
--
-- Builds on 20261030120000_scheduled_offers_all_services.sql.
-- Unchanged: pg_cron schedule (10:00, 14:00, 18:00 IST), 3-hour dedupe,
-- notification type ('offer' / 'reward'), push trigger and Edge Function.
--
-- Now every send picks ONE message from a per-user pool of distinct messages
-- (9-11 per user) instead of 4-6 repeating ones. The rotation moves by one on
-- every send, so a user sees a different notification each time.
--
-- Messages: 3-tank Rs 500, WEL100 (new users), wallet coins, review reward,
-- monthly 50-coin bonus, water tank quality (5-stage / TDS / certified),
-- tank reminder, Solar Panel Cleaning (+ re-clean reminder for solar users),
-- solar sizes / tank->solar cross-sell, Solar Maintenance & Repair (2 variants),
-- all-services overview.

create or replace function public.offer_pool_for_user(
  p_has_booking boolean,
  p_coins integer,
  p_has_solar boolean,
  p_has_tank boolean,
  p_needs_review boolean
)
returns jsonb
language plpgsql
immutable
set search_path to 'public'
as $function$
declare
  v jsonb := '[]'::jsonb;
begin
  -- Water tank: 3-tank flat offer
  v := v || jsonb_build_object('t','offer',
    'h','🎉 3 tank book karein, ₹500 flat off!',
    'b','3 ya usse zyada tank ek saath book karne par ₹500 ki flat chhoot apne aap mil jaati hai. Abhi apna slot book karein.');

  -- Solar panel cleaning
  if p_has_solar then
    v := v || jsonb_build_object('t','offer',
      'h','☀️ Solar panel dobara saaf karwane ka time?',
      'b','Dhool jamne se panel ki performance kam hoti hai. Apna agla solar cleaning slot book karein, sirf ₹100 per panel.');
  else
    v := v || jsonb_build_object('t','offer',
      'h','☀️ Solar panel saaf karwayein',
      'b','Dhool aur grime hatane se panel ki performance behtar rehti hai. 3kW se 30kW tak, sirf ₹100 per panel. Abhi apna slot book karein.');
  end if;

  -- First-booking coupon (new users) / wallet coins
  if not p_has_booking then
    v := v || jsonb_build_object('t','offer',
      'h','🎁 Pehli booking par ₹100 off!',
      'b','Welcome offer: apni pehli water tank cleaning par ₹100 ki chhoot paayein. Checkout par code WEL100 lagayein.');
  elsif p_coins > 0 then
    v := v || jsonb_build_object('t','offer',
      'h',format('🪙 Aapke wallet mein %s coins hain', p_coins),
      'b','Agli booking par wallet coins use karke aur bachat karein (ek booking par max 50 coins).');
  end if;

  -- Solar maintenance & repair
  v := v || jsonb_build_object('t','offer',
    'h','🔧 Solar maintenance & repair',
    'b','Inverter check, wiring aur panel repair ke liye hamari team taiyaar hai. Enquiry ke liye WhatsApp par message karein.');

  -- Water tank quality
  v := v || jsonb_build_object('t','offer',
    'h','💧 5-Stage Tank Cleaning, TDS Tested',
    'b','Hamari water tank cleaning me 5-Stage Clean, TDS testing aur certification milta hai. 500L se 2000L tak, sirf ₹1,000 se shuru.');

  -- Review reward (existing users who have not reviewed their latest booking)
  if p_has_booking and p_needs_review then
    v := v || jsonb_build_object('t','reward',
      'h','⭐ Review likhein, 10 coins paayein',
      'b','Apni service ka review likhkar 10 coins kamayein aur agli booking par use karein.');
  end if;

  -- Monthly bonus
  v := v || jsonb_build_object('t','offer',
    'h','🎁 Har mahine 50 coins ka bonus',
    'b','Har 30 din me 50 coins ka monthly bonus aapke wallet me aata hai. Coins se booking par bachat karein (ek booking par max 50 coins).');

  -- All services overview
  v := v || jsonb_build_object('t','offer',
    'h','🏠 Homaclo par saari services ek jagah',
    'b','Water Tank Cleaning, Solar Panel Cleaning aur Solar Maintenance & Repair. Apni zaroorat ki service abhi book karein.');

  -- Cross-sell / solar sizes
  if p_has_tank and not p_has_solar then
    v := v || jsonb_build_object('t','offer',
      'h','☀️ Tank ke saath solar panel bhi saaf karwayein',
      'b','Paani ke saath bijli bhi bachayein. Solar panel cleaning 3kW se 30kW tak, sirf ₹100 per panel.');
  else
    v := v || jsonb_build_object('t','offer',
      'h','☀️ 3kW se 30kW, har solar system ke liye',
      'b','Chhota ho ya bada system, dhool aur grime ki safai ₹100 per panel par. Apna slot aaj hi book karein.');
  end if;

  -- Water tank reminder
  if p_has_booking then
    v := v || jsonb_build_object('t','offer',
      'h','🚰 Tank dobara saaf karwane ka time?',
      'b','Regular cleaning se paani saaf rehta hai. Apna agla slot aaj hi book karein.');
  else
    v := v || jsonb_build_object('t','offer',
      'h','🚰 Tank saaf karwane ka sahi time',
      'b','Saaf tank ka matlab saaf aur surakshit paani. Professional tank cleaning ka apna slot aaj hi book karein.');
  end if;

  -- Solar repair (inverter / wiring)
  v := v || jsonb_build_object('t','offer',
    'h','⚡ Inverter ya wiring me problem?',
    'b','Inverter check, wiring ya panel repair chahiye? WhatsApp par enquiry karein, hamari team madad karegi.');

  -- Wallet coins for new users who also hold coins (welcome bonus)
  if not p_has_booking and p_coins > 0 then
    v := v || jsonb_build_object('t','offer',
      'h',format('🪙 Aapke wallet mein %s coins hain', p_coins),
      'b','Booking ke waqt wallet coins use karke aur bachat karein (ek booking par max 50 coins).');
  end if;

  return v;
end;
$function$;

revoke all on function public.offer_pool_for_user(boolean, integer, boolean, boolean, boolean) from public, anon, authenticated;

-- Same schedule, dedupe and delivery path; now picks one distinct message per send from the pool.
create or replace function public.send_scheduled_offers(
  p_slot integer default 0,
  p_only_user uuid default null,
  p_force boolean default false
)
returns integer
language plpgsql
security definer
set search_path to 'public'
as $function$
declare
  r record;
  seq bigint;
  v_pool jsonb;
  v_item jsonb;
  sent integer := 0;
begin
  -- Rotates by 1 for every send (3 sends a day) so users see different offers.
  seq := (extract(doy from (now() at time zone 'Asia/Kolkata'))::bigint * 3) + p_slot;

  for r in
    select
      p.id as user_id,
      exists (select 1 from public.bookings b where b.user_id = p.id) as has_booking,
      exists (select 1 from public.bookings b where b.user_id = p.id and b.service_category = 'solar') as has_solar,
      exists (select 1 from public.bookings b where b.user_id = p.id and b.service_category = 'water_tank') as has_tank,
      coalesce((select c.balance from public.user_coins c where c.user_id = p.id), 0) as coins,
      (
        (select max(rv.created_at) from public.reviews rv where rv.user_id = p.id) is null
        or (select max(rv.created_at) from public.reviews rv where rv.user_id = p.id)
           < (select max(b.created_at) from public.bookings b where b.user_id = p.id)
      ) as needs_review
    from public.profiles p
    where (p_only_user is null or p.id = p_only_user)
      and (
        p_force
        or not exists (
          select 1 from public.notifications n
          where n.user_id = p.id
            and n.type in ('offer', 'coupon')
            and n.created_at > now() - interval '3 hours'
        )
      )
  loop
    v_pool := public.offer_pool_for_user(r.has_booking, r.coins, r.has_solar, r.has_tank, r.needs_review);
    v_item := v_pool -> (((seq + abs(hashtext(r.user_id::text)::bigint)) % jsonb_array_length(v_pool))::integer);

    insert into public.notifications (user_id, title, body, type)
    values (r.user_id, v_item->>'h', v_item->>'b', v_item->>'t');
    sent := sent + 1;
  end loop;

  return sent;
end;
$function$;

revoke all on function public.send_scheduled_offers(integer, uuid, boolean) from public, anon, authenticated;
