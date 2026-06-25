-- ============================================================
-- MizarLabs Flow — Üreticilere Sözleşme Durumu + sözleşme dosyaları
-- YENİ projede çalıştır:
-- https://supabase.com/dashboard/project/uolmzykwvizhmycgymfi/sql/new
-- ============================================================

-- 1) Sözleşme durumu alanı
alter table public.ureticiler add column if not exists sozlesme_durumu text;

-- 2) Üretici (sözleşme) dosyaları — aynı 'is-dosyalari' kovasını kullanır
create table if not exists public.uretici_dosyalari (
  id          uuid primary key default gen_random_uuid(),
  uretici_id  uuid not null references public.ureticiler(id) on delete cascade,
  ad          text not null,
  yol         text not null,
  url         text not null,
  tur         text,
  boyut       int,
  created_by  uuid references auth.users(id) default auth.uid(),
  created_at  timestamptz not null default now()
);

alter table public.uretici_dosyalari enable row level security;
drop policy if exists uretici_dosya_all on public.uretici_dosyalari;
create policy uretici_dosya_all on public.uretici_dosyalari for all to authenticated using (true) with check (true);

do $$
begin
  if not exists (select 1 from pg_publication_tables where pubname='supabase_realtime' and schemaname='public' and tablename='uretici_dosyalari') then
    alter publication supabase_realtime add table public.uretici_dosyalari;
  end if;
end $$;

notify pgrst, 'reload schema';
-- Not: Dosya depolama 'is-dosyalari' kovasını kullanır; o kovanın kuralları
-- update-dosya.sql ile zaten kurulmuş olmalı. Kurmadıysan önce onu çalıştır.
