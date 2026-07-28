-- ============================================================
-- MizarLabs Flow — Avanslar (kişiye verilen nakit/kart/çek avansları)
-- YENİ projede çalıştır:
-- https://supabase.com/dashboard/project/uolmzykwvizhmycgymfi/sql/new
-- Finans erişimi olanlar görür (is_finance). update-finans.sql çalıştırılmış olmalı.
-- ============================================================

create table if not exists public.avanslar (
  id         uuid primary key default gen_random_uuid(),
  kisi       text not null,     -- kime verildi (ör. Musa)
  tutar      numeric not null default 0,
  tip        text not null default 'Nakit',   -- Nakit | Kredi Kartı | ÇEK | Havale / EFT | Diğer
  tarih      date,
  aciklama   text,
  created_by uuid references auth.users(id) default auth.uid(),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

drop trigger if exists trg_avanslar_touch on public.avanslar;
create trigger trg_avanslar_touch before update on public.avanslar
  for each row execute function public.touch_updated_at();

-- Güvenlik: SADECE finans erişimi olanlar
alter table public.avanslar enable row level security;
drop policy if exists avanslar_finance on public.avanslar;
create policy avanslar_finance on public.avanslar
  for all to authenticated using (public.is_finance()) with check (public.is_finance());

do $$
begin
  if not exists (select 1 from pg_publication_tables where pubname='supabase_realtime' and schemaname='public' and tablename='avanslar') then
    alter publication supabase_realtime add table public.avanslar;
  end if;
end $$;

notify pgrst, 'reload schema';
-- Bitti. Finans → "Avanslar" sekmesi → "+ Avans".
