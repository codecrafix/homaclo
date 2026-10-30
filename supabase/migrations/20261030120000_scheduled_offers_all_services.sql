-- Scheduled offer notifications for ALL services (already applied to Supabase:
-- scheduled_offers_all_services).
--
-- Extends public.send_scheduled_offers() from 20260921_scheduled_offer_notifications.sql.
-- Unchanged: pg_cron schedule (10:00, 14:00, 18:00 IST), the 3-hour dedupe,
-- new-user vs existing-user logic, WEL100 / 3-tank Rs 500 / wallet coins /
-- review reward / reminder messages (picks 0-3).
--
-- New: rotation is now 6 picks instead of 4.
--   pick 4 -> Solar Panel Cleaning (3kW-30kW, Rs 100 per panel) - all users
--   pick 5 -> Solar Maintenance & Repair (inverter, wiring, panel repair;
--             enquiry on WhatsApp) - all users
-- Notifications keep type = 'offer', so the push trigger, send-push-notification
-- Edge Function and the in-app notifications screen need no changes.

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
  pick integer;
  v_type text;
  v_title text;
  v_body text;
  sent integer := 0;
begin
  -- Rotates by 1 for every send (3 sends a day) so users see different offers.
  seq := (extract(doy from (now() at time zone 'Asia/Kolkata'))::bigint * 3) + p_slot;

  for r in
    select
      p.id as user_id,
      exists (select 1 from public.bookings b where b.user_id = p.id) as has_booking,
      coalesce((select c.balance from public.user_coins c where c.user_id = p.id), 0) as coins,
      (select max(b.created_at) from public.bookings b where b.user_id = p.id) as last_booking,
      (select max(rv.created_at) from public.reviews rv where rv.user_id = p.id) as last_review
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
    pick := ((seq + abs(hashtext(r.user_id::text)::bigint)) % 6)::integer;

    -- default text: 3-tank offer (valid for everyone, applied automatically)
    v_type  := 'offer';
    v_title := '🎉 3 tank book karein, ₹500 flat off!';
    v_body  := '3 ya usse zyada tank ek saath book karne par ₹500 ki flat chhoot apne aap mil jaati hai. Abhi apna slot book karein.';

    if pick = 4 then
      -- Solar Panel Cleaning (all users)
      v_title := '☀️ Solar panel saaf karwayein';
      v_body  := 'Dhool aur grime hatane se panel ki performance behtar rehti hai. 3kW se 30kW tak, sirf ₹100 per panel. Abhi apna slot book karein.';
    elsif pick = 5 then
      -- Solar Maintenance & Repair (all users, enquiry on WhatsApp)
      v_title := '🔧 Solar maintenance & repair';
      v_body  := 'Inverter check, wiring aur panel repair ke liye hamari team taiyaar hai. Enquiry ke liye WhatsApp par message karein.';
    elsif not r.has_booking then
      -- New users (no booking yet): WEL100 is valid only on the first booking.
      if pick = 0 or (pick = 2 and r.coins <= 0) then
        v_title := '🎁 Pehli booking par ₹100 off!';
        v_body  := 'Welcome offer: apni pehli water tank cleaning par ₹100 ki chhoot paayein. Checkout par code WEL100 lagayein.';
      elsif pick = 2 then
        v_title := format('🪙 Aapke wallet mein %s coins hain', r.coins);
        v_body  := 'Booking ke waqt wallet coins use karke aur bachat karein (ek booking par max 50 coins).';
      elsif pick = 3 then
        v_title := '🚰 Tank saaf karwane ka sahi time';
        v_body  := 'Saaf tank ka matlab saaf aur surakshit paani. Professional tank cleaning ka apna slot aaj hi book karein.';
      end if;
    else
      -- Existing users (have booked before)
      if pick = 1 and r.coins > 0 then
        v_title := format('🪙 Aapke wallet mein %s coins hain', r.coins);
        v_body  := 'Agli booking par wallet coins use karke aur bachat karein (ek booking par max 50 coins).';
      elsif pick = 2 and (r.last_review is null or r.last_review < r.last_booking) then
        v_type  := 'reward';
        v_title := '⭐ Review likhein, 10 coins paayein';
        v_body  := 'Apni service ka review likhkar 10 coins kamayein aur agli booking par use karein.';
      elsif pick >= 2 then
        v_title := '🚰 Tank dobara saaf karwane ka time?';
        v_body  := 'Regular cleaning se paani saaf rehta hai. Apna agla slot aaj hi book karein.';
      end if;
    end if;

    insert into public.notifications (user_id, title, body, type)
    values (r.user_id, v_title, v_body, v_type);
    sent := sent + 1;
  end loop;

  return sent;
end;
$function$;

revoke all on function public.send_scheduled_offers(integer, uuid, boolean) from public, anon, authenticated;
