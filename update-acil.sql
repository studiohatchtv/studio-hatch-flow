-- ============================================================
-- studioHATCH Flow — "Acil" alanı ekle
-- YENİ projede (uolmzykwvizhmycgymfi) SQL Editor'de çalıştır:
-- https://supabase.com/dashboard/project/uolmzykwvizhmycgymfi/sql/new
-- ============================================================

alter table public.isler add column if not exists acil boolean not null default false;

notify pgrst, 'reload schema';

-- Bitti. Uygulamayı yenile; acil işaretleme çalışır.
