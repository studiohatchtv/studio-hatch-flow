-- ============================================================
-- MizarLabs Flow — Finans (ödeme takibi) — ERİŞİM KISITLI
-- YENİ projede çalıştır:
-- https://supabase.com/dashboard/project/uolmzykwvizhmycgymfi/sql/new
-- ============================================================

-- 1) Kişilere finans erişim bayrağı
alter table public.kisiler add column if not exists finans boolean not null default false;

-- 2) Finans erişim kontrolü (master admin her zaman; ya da finans=true)
create or replace function public.is_finance()
returns boolean language sql security definer stable as $$
  select coalesce((select k.finans from public.kisiler k where k.user_id = auth.uid() limit 1), false)
      or coalesce((auth.jwt() ->> 'email') = 'samet@mizarlabs.com', false);
$$;

-- 3) Ödemeler tablosu
create table if not exists public.odemeler (
  id         uuid primary key default gen_random_uuid(),
  baslik     text,
  tutar      numeric not null default 0,
  tarih      date,
  tip        text,        -- Nakit | Havale / EFT | ÇEK | Senet | Kredi Kartı | Otomatik Ödeme | Diğer
  yon        text not null default 'Giden',  -- Giden | Gelen
  tekrar     text not null default 'Tek seferlik',  -- Tek seferlik | Aylık
  durum      text not null default 'Bekliyor',      -- Bekliyor | Ödendi
  created_by uuid references auth.users(id) default auth.uid(),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

drop trigger if exists trg_odemeler_touch on public.odemeler;
create trigger trg_odemeler_touch before update on public.odemeler
  for each row execute function public.touch_updated_at();

-- 4) Güvenlik (RLS): SADECE finans erişimi olanlar görür/yazar
alter table public.odemeler enable row level security;
drop policy if exists odemeler_finance on public.odemeler;
create policy odemeler_finance on public.odemeler
  for all to authenticated using (public.is_finance()) with check (public.is_finance());

-- 5) Anlık senkron
do $$
begin
  if not exists (select 1 from pg_publication_tables where pubname='supabase_realtime' and schemaname='public' and tablename='odemeler') then
    alter publication supabase_realtime add table public.odemeler;
  end if;
end $$;

notify pgrst, 'reload schema';
-- ============================================================
-- Bitti. Yönetim → "Finans erişimi"nden kişilere yetki ver.
-- Yetki verilenlerde üstte "🏦 Finans" görünür.
-- ============================================================
