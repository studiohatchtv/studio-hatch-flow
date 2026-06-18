-- ============================================================
-- studioHATCH Flow — "Kontaklar" ekle
-- YENİ projede çalıştır:
-- https://supabase.com/dashboard/project/uolmzykwvizhmycgymfi/sql/new
-- Tekrar çalıştırılabilir, zarar vermez.
-- ============================================================

-- 1) Kontaklar tablosu (tedarikçi / dış kişi)
create table if not exists public.kontaklar (
  id          uuid primary key default gen_random_uuid(),
  ad          text not null,
  firma       text,
  telefon     text,
  email       text,
  notlar      text,
  created_at  timestamptz not null default now()
);

-- 2) İşe "ilgili kontak" bağlantısı
alter table public.isler add column if not exists kontak_id uuid references public.kontaklar(id) on delete set null;

-- 3) Güvenlik (sadece giriş yapmış ekip)
alter table public.kontaklar enable row level security;
drop policy if exists kontaklar_all on public.kontaklar;
create policy kontaklar_all on public.kontaklar
  for all to authenticated using (true) with check (true);

-- 4) Anlık senkron
do $$
begin
  if not exists (select 1 from pg_publication_tables
                 where pubname='supabase_realtime' and schemaname='public' and tablename='kontaklar') then
    alter publication supabase_realtime add table public.kontaklar;
  end if;
end $$;

-- 5) Şema önbelleğini tazele
notify pgrst, 'reload schema';

-- Bitti. Uygulamayı yenile → Kontaklar butonu + iş kartında kontak alanı çalışır.
