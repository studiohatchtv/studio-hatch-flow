-- ============================================================
-- studioHATCH Flow — veritabanı kurulumu
-- Supabase panelinde: SQL Editor > New query > yapıştır > Run
-- Mevcut "studio-hatch-web" projesine sadece YENİ tablolar ekler,
-- var olan newsletter/içerik tablolarına dokunmaz.
-- ============================================================

-- 1) KİŞİLER --------------------------------------------------
-- Ekip üyeleri. user_id dolu olanlar = giriş yapmış gerçek hesap.
-- Manuel eklenenler (user_id boş) da olabilir.
create table if not exists public.kisiler (
  id          uuid primary key default gen_random_uuid(),
  user_id     uuid unique references auth.users(id) on delete set null,
  ad          text not null,
  email       text,
  created_at  timestamptz not null default now()
);

-- 2) İŞLER ----------------------------------------------------
create table if not exists public.isler (
  id               uuid primary key default gen_random_uuid(),
  baslik           text not null,
  is_kolu          text,                       -- Immersive | Dijital Art | hatch Shop | İnşaat
  durum            text not null default 'Yapılacak',  -- Yapılacak | Devam ediyor | Tamamlandı
  yonetici         text,
  ana_sorumlu      text,
  yardimci_sorumlu text,
  ilk_tarih        date,
  son_tarih        date,
  created_by       uuid references auth.users(id) default auth.uid(),
  created_at       timestamptz not null default now(),
  updated_at       timestamptz not null default now()
);

-- updated_at otomatik güncellensin
create or replace function public.touch_updated_at()
returns trigger language plpgsql as $$
begin new.updated_at = now(); return new; end; $$;

drop trigger if exists trg_isler_touch on public.isler;
create trigger trg_isler_touch before update on public.isler
  for each row execute function public.touch_updated_at();

-- 3) Yeni üye giriş yapınca otomatik Kişiler'e eklensin -------
create or replace function public.handle_new_user()
returns trigger language plpgsql security definer as $$
begin
  insert into public.kisiler (user_id, ad, email)
  values (
    new.id,
    coalesce(
      new.raw_user_meta_data->>'full_name',
      new.raw_user_meta_data->>'name',
      new.raw_user_meta_data->>'ad',
      split_part(new.email, '@', 1)
    ),
    new.email
  )
  on conflict (user_id) do nothing;
  return new;
end; $$;

drop trigger if exists trg_new_user on auth.users;
create trigger trg_new_user after insert on auth.users
  for each row execute function public.handle_new_user();

-- 4) Güvenlik (RLS): sadece giriş yapmış ekip görebilir/yazabilir
alter table public.kisiler enable row level security;
alter table public.isler   enable row level security;

drop policy if exists kisiler_all on public.kisiler;
create policy kisiler_all on public.kisiler
  for all to authenticated using (true) with check (true);

drop policy if exists isler_all on public.isler;
create policy isler_all on public.isler
  for all to authenticated using (true) with check (true);

-- 5) (İsteğe bağlı) Anlık senkron için realtime aç
alter publication supabase_realtime add table public.isler;
alter publication supabase_realtime add table public.kisiler;

-- ============================================================
-- Bitti. Ayrıca panelde: Authentication > Providers > Email açık olmalı
-- (magic link / e-posta ile giriş için). Varsayılan olarak açıktır.
-- ============================================================
