-- Homaclo admin dashboard: admin access policies (NOT applied automatically).
-- Review, then run once in the Supabase SQL editor. Safe to re-run.
-- Uses the existing public.is_admin_user() helper, same as the policies already on bookings/profiles/reviews.

do $$
declare t text;
begin
  -- full control: tickets, contact messages, coin history, services/pricing
  foreach t in array array['support_tickets','contact_messages','coin_transactions','services'] loop
    execute format('drop policy if exists admin_manage_all_%1$s on public.%1$I', t);
    execute format('create policy admin_manage_all_%1$s on public.%1$I for all using (public.is_admin_user()) with check (public.is_admin_user())', t);
  end loop;

  -- read-only for admins: payments, saved locations, review locks, clerk identities
  foreach t in array array['payments','user_locations','review_locks','clerk_identities'] loop
    execute format('drop policy if exists admin_read_all_%1$s on public.%1$I', t);
    execute format('create policy admin_read_all_%1$s on public.%1$I for select using (public.is_admin_user())', t);
  end loop;
end $$;
