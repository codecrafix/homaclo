-- ============================================================
-- Solar Panel Cleaning service activation
-- Adds a service category to bookings and reviews so water tank
-- and solar bookings/reviews coexist with distinct formats.
-- Fully backward compatible: existing rows default to 'water_tank'.
-- (Already applied to the live database on 2026-10-29.)
-- ============================================================

-- 1. BOOKINGS: category + solar details
ALTER TABLE public.bookings
  ADD COLUMN IF NOT EXISTS service_category TEXT NOT NULL DEFAULT 'water_tank';

ALTER TABLE public.bookings
  ADD COLUMN IF NOT EXISTS solar_kw INTEGER;

ALTER TABLE public.bookings
  ADD COLUMN IF NOT EXISTS solar_panel_count INTEGER;

ALTER TABLE public.bookings
  DROP CONSTRAINT IF EXISTS bookings_service_category_chk;
ALTER TABLE public.bookings
  ADD CONSTRAINT bookings_service_category_chk
  CHECK (service_category IN ('water_tank', 'solar'));

-- 2. REVIEWS: category (solar reviews get their own format client-side)
ALTER TABLE public.reviews
  ADD COLUMN IF NOT EXISTS service_category TEXT NOT NULL DEFAULT 'water_tank';

ALTER TABLE public.reviews
  DROP CONSTRAINT IF EXISTS reviews_service_category_chk;
ALTER TABLE public.reviews
  ADD CONSTRAINT reviews_service_category_chk
  CHECK (service_category IN ('water_tank', 'solar'));

-- 3. Index for category filtering
CREATE INDEX IF NOT EXISTS idx_bookings_service_category
  ON public.bookings(service_category);
CREATE INDEX IF NOT EXISTS idx_reviews_service_category
  ON public.reviews(service_category);
