-- ============================================================
-- MizarLabs Flow — çok-projeli yapıya geçiş (migration)
-- YENİ projede çalıştır:
-- https://supabase.com/dashboard/project/uolmzykwvizhmycgymfi/sql/new
-- Tekrar çalıştırılabilir, zarar vermez. Mevcut studioHATCH verisi korunur.
-- ============================================================

-- 1) Projeler ve projeye özel iş kolları
create table if not exists public.projeler (
  id         uuid primary key default gen_random_uuid(),
  ad         text not null,
  sira       int  not null default 0,
  created_at timestamptz not null default now()
);

create table if not exists public.is_kollari (
  id         uuid primary key default gen_random_uuid(),
  proje_id   uuid not null references public.projeler(id) on delete cascade,
  ad         text not null,
  renk       text not null default 'gray',
  sira       int  not null default 0,
  created_at timestamptz not null default now()
);

-- 2) İşlere proje bağlantısı, kişilere admin bayrağı
alter table public.isler   add column if not exists proje_id uuid references public.projeler(id) on delete cascade;
alter table public.kisiler add column if not exists is_admin boolean not null default false;

-- 3) Admin kontrol fonksiyonu (master admin her zaman yetkili)
create or replace function public.is_admin()
returns boolean language sql security definer stable as $$
  select coalesce((select k.is_admin from public.kisiler k where k.user_id = auth.uid() limit 1), false)
      or coalesce((auth.jwt() ->> 'email') = 'samet@mizarlabs.com', false);
$$;

-- 4) Güvenlik (RLS): herkes okur, sadece admin yazar
alter table public.projeler   enable row level security;
alter table public.is_kollari enable row level security;

drop policy if exists projeler_read  on public.projeler;
create policy projeler_read  on public.projeler  for select to authenticated using (true);
drop policy if exists projeler_admin on public.projeler;
create policy projeler_admin on public.projeler  for all to authenticated using (public.is_admin()) with check (public.is_admin());

drop policy if exists iskollari_read  on public.is_kollari;
create policy iskollari_read  on public.is_kollari for select to authenticated using (true);
drop policy if exists iskollari_admin on public.is_kollari;
create policy iskollari_admin on public.is_kollari for all to authenticated using (public.is_admin()) with check (public.is_admin());

-- 5) Anlık senkron
do $$
begin
  if not exists (select 1 from pg_publication_tables where pubname='supabase_realtime' and schemaname='public' and tablename='projeler') then
    alter publication supabase_realtime add table public.projeler;
  end if;
  if not exists (select 1 from pg_publication_tables where pubname='supabase_realtime' and schemaname='public' and tablename='is_kollari') then
    alter publication supabase_realtime add table public.is_kollari;
  end if;
end $$;

-- 6) Mevcut studioHATCH verisini ilk projeye taşı (yalnızca ilk kez)
do $$
declare pid uuid;
begin
  if not exists (select 1 from public.projeler) then
    insert into public.projeler (ad, sira) values ('studioHATCH', 0) returning id into pid;
    insert into public.is_kollari (proje_id, ad, renk, sira) values
      (pid,'Immersive','blue',1),(pid,'Dijital Art','pink',2),(pid,'hatch Shop','teal',3),
      (pid,'İnşaat','coral',4),(pid,'Sponsorluk','purple',5),(pid,'Dijital İşler','amber',6);
    update public.isler set proje_id = pid where proje_id is null;
  end if;
end $$;

-- 7) Master admin'i admin yap (kaydı varsa)
update public.kisiler set is_admin = true where email = 'samet@mizarlabs.com';

notify pgrst, 'reload schema';
-- ============================================================
-- Bitti. Uygulamayı yenile: üstte proje seçici + ⚙️ Yönetim gelir.
-- ============================================================
