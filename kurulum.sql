-- ============================================================
-- studioHATCH Flow — TEK DOSYA KURULUM (her şeyi yapar)
-- Supabase > SQL Editor > New query > hepsini yapıştır > RUN
-- Tekrar tekrar çalıştırılabilir, zarar vermez.
-- ============================================================

-- 1) Tablolar -------------------------------------------------
create table if not exists public.kisiler (
  id          uuid primary key default gen_random_uuid(),
  user_id     uuid unique references auth.users(id) on delete set null,
  ad          text not null,
  email       text,
  created_at  timestamptz not null default now()
);

create table if not exists public.isler (
  id               uuid primary key default gen_random_uuid(),
  baslik           text not null,
  aciklama         text,
  acil             boolean not null default false,
  is_kolu          text,
  durum            text not null default 'Yapılacak',
  yonetici         text,
  ana_sorumlu      text,
  yardimci_sorumlu text,
  ilk_tarih        date,
  son_tarih        date,
  created_by       uuid references auth.users(id) default auth.uid(),
  created_at       timestamptz not null default now(),
  updated_at       timestamptz not null default now()
);

-- daha önce eksik kurulmuşsa kolonları garantiye al
alter table public.isler add column if not exists aciklama text;
alter table public.isler add column if not exists acil boolean not null default false;

-- 2) updated_at otomatik ------------------------------------
create or replace function public.touch_updated_at()
returns trigger language plpgsql as $$
begin new.updated_at = now(); return new; end; $$;

drop trigger if exists trg_isler_touch on public.isler;
create trigger trg_isler_touch before update on public.isler
  for each row execute function public.touch_updated_at();

-- 3) Yeni üye -> otomatik Kişiler ---------------------------
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

-- 4) Güvenlik (RLS): sadece giriş yapmış ekip ---------------
alter table public.kisiler enable row level security;
alter table public.isler   enable row level security;

drop policy if exists kisiler_all on public.kisiler;
create policy kisiler_all on public.kisiler
  for all to authenticated using (true) with check (true);

drop policy if exists isler_all on public.isler;
create policy isler_all on public.isler
  for all to authenticated using (true) with check (true);

-- 5) Anlık senkron (zaten ekliyse atla) ---------------------
do $$
begin
  if not exists (select 1 from pg_publication_tables
                 where pubname='supabase_realtime' and schemaname='public' and tablename='isler') then
    alter publication supabase_realtime add table public.isler;
  end if;
  if not exists (select 1 from pg_publication_tables
                 where pubname='supabase_realtime' and schemaname='public' and tablename='kisiler') then
    alter publication supabase_realtime add table public.kisiler;
  end if;
end $$;

-- 6) Mevcut üyeleri (seni) Kişiler'e aktar ------------------
insert into public.kisiler (user_id, ad, email)
select u.id,
       coalesce(u.raw_user_meta_data->>'full_name',
                u.raw_user_meta_data->>'name',
                split_part(u.email, '@', 1)),
       u.email
from auth.users u
where not exists (select 1 from public.kisiler k where k.user_id = u.id);

-- 7) PostgREST şema önbelleğini tazele -----------------------
notify pgrst, 'reload schema';

-- ============================================================
-- Bitti. Uygulamayı yenile: işler yüklenir, adın Kişiler'de olur.
-- ============================================================
