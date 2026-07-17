-- ============================================================
-- MizarLabs Flow — Dijital Art (sanatçı eser başvuruları)
-- YENİ projede çalıştır:
-- https://supabase.com/dashboard/project/uolmzykwvizhmycgymfi/sql/new
-- ============================================================

create table if not exists public.basvurular (
  id          uuid primary key default gen_random_uuid(),
  eser_adi    text,
  aciklama    text,
  linkler     text,                                  -- her satırda bir link
  sanatci_id  uuid references public.kontaklar(id) on delete set null,  -- Kontaklar'dan sanatçı
  asama       text not null default 'Başvuru Yaptı', -- Başvuru Yaptı|Değerlendirme|Kabul Edildi|Red Edildi
  created_by  uuid references auth.users(id) default auth.uid(),
  created_at  timestamptz not null default now(),
  updated_at  timestamptz not null default now()
);

drop trigger if exists trg_basvurular_touch on public.basvurular;
create trigger trg_basvurular_touch before update on public.basvurular
  for each row execute function public.touch_updated_at();

alter table public.basvurular enable row level security;
drop policy if exists basvurular_all on public.basvurular;
create policy basvurular_all on public.basvurular for all to authenticated using (true) with check (true);

-- Eser dosyaları/görselleri — 'is-dosyalari' kovasını kullanır
create table if not exists public.basvuru_dosyalari (
  id          uuid primary key default gen_random_uuid(),
  basvuru_id  uuid not null references public.basvurular(id) on delete cascade,
  ad          text not null,
  yol         text not null,
  url         text not null,
  tur         text,
  boyut       int,
  created_by  uuid references auth.users(id) default auth.uid(),
  created_at  timestamptz not null default now()
);

alter table public.basvuru_dosyalari enable row level security;
drop policy if exists basvuru_dosya_all on public.basvuru_dosyalari;
create policy basvuru_dosya_all on public.basvuru_dosyalari for all to authenticated using (true) with check (true);

do $$
begin
  if not exists (select 1 from pg_publication_tables where pubname='supabase_realtime' and schemaname='public' and tablename='basvurular') then
    alter publication supabase_realtime add table public.basvurular;
  end if;
  if not exists (select 1 from pg_publication_tables where pubname='supabase_realtime' and schemaname='public' and tablename='basvuru_dosyalari') then
    alter publication supabase_realtime add table public.basvuru_dosyalari;
  end if;
end $$;

notify pgrst, 'reload schema';
-- Not: Dosyalar 'is-dosyalari' kovasını kullanır (update-dosya.sql ile kurulu olmalı).
-- Bitti. Üstte "🎨 Dijital Art" → "+ Eser / başvuru".
