-- ============================================================
-- MizarLabs Flow — Mağaza (ürün, stok, satış, hakediş) — ERİŞİM KISITLI
-- YENİ projede çalıştır:
-- https://supabase.com/dashboard/project/uolmzykwvizhmycgymfi/sql/new
-- update-finans.sql çalıştırılmış olmalı (is_finance()).
-- ============================================================

-- 1) Kişilere mağaza erişim bayrağı
alter table public.kisiler add column if not exists magaza boolean not null default false;

-- 2) Mağaza erişimi: master admin, adminler, finans erişimi olanlar veya magaza=true
create or replace function public.is_magaza()
returns boolean language sql security definer stable as $$
  select coalesce((select k.magaza or k.is_admin or k.finans from public.kisiler k where k.user_id = auth.uid() limit 1), false)
      or coalesce((auth.jwt() ->> 'email') = 'samet@mizarlabs.com', false);
$$;

-- 3) Ürünler
create table if not exists public.magaza_urunler (
  id         uuid primary key default gen_random_uuid(),
  kod        text unique,              -- ör. CHK-001
  ad         text not null,
  marka      text not null,            -- tasarımcı / marka
  kategori   text,
  olcu       text,                     -- ölçü / renk / varyant
  fiyat      numeric not null default 0,   -- KDV dahil satış fiyatı
  stok       integer not null default 0 check (stok >= 0),
  foto_url   text,
  foto_yol   text,
  notlar     text,
  created_by uuid references auth.users(id) default auth.uid(),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

-- 4) Satışlar (kalemler jsonb: [{urun_id,kod,ad,marka,adet,fiyat}])
create sequence if not exists public.magaza_satis_no_seq;
create table if not exists public.magaza_satislar (
  id         uuid primary key default gen_random_uuid(),
  satis_no   text unique not null default ('S-' || lpad(nextval('public.magaza_satis_no_seq')::text, 5, '0')),
  tarih      timestamptz not null default now(),
  kalemler   jsonb not null default '[]'::jsonb,
  toplam     numeric not null default 0,
  odeme      text not null default 'Nakit',          -- Nakit | POS / Kart | IBAN / Havale
  fatura     text not null default 'not_requested',  -- not_requested | pending | issued
  musteri    jsonb,                                  -- {ad,soyad,tckn,adres,email,not}
  iptal      boolean not null default false,
  satan      text,
  created_by uuid references auth.users(id) default auth.uid(),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

-- 5) Stok hareketleri (her giriş/çıkışın kaydı)
create table if not exists public.magaza_stok_hareketleri (
  id         uuid primary key default gen_random_uuid(),
  urun_id    uuid not null references public.magaza_urunler(id) on delete cascade,
  degisim    integer not null,
  sebep      text not null,        -- İlk stok | Stok girişi | Satış | İptal | Düzeltme | Fire / Hasar | Marka iadesi
  satis_id   uuid references public.magaza_satislar(id) on delete set null,
  aciklama   text,
  yapan      text,
  created_by uuid references auth.users(id) default auth.uid(),
  created_at timestamptz not null default now()
);
create index if not exists magaza_hareket_urun_idx on public.magaza_stok_hareketleri(urun_id, created_at desc);
create index if not exists magaza_satis_tarih_idx on public.magaza_satislar(tarih desc);

drop trigger if exists trg_magaza_urunler_touch on public.magaza_urunler;
create trigger trg_magaza_urunler_touch before update on public.magaza_urunler
  for each row execute function public.touch_updated_at();
drop trigger if exists trg_magaza_satislar_touch on public.magaza_satislar;
create trigger trg_magaza_satislar_touch before update on public.magaza_satislar
  for each row execute function public.touch_updated_at();

-- 6) Güvenlik (RLS): SADECE mağaza erişimi olanlar
alter table public.magaza_urunler enable row level security;
alter table public.magaza_satislar enable row level security;
alter table public.magaza_stok_hareketleri enable row level security;
drop policy if exists magaza_urunler_all on public.magaza_urunler;
create policy magaza_urunler_all on public.magaza_urunler
  for all to authenticated using (public.is_magaza()) with check (public.is_magaza());
drop policy if exists magaza_satislar_all on public.magaza_satislar;
create policy magaza_satislar_all on public.magaza_satislar
  for all to authenticated using (public.is_magaza()) with check (public.is_magaza());
drop policy if exists magaza_hareket_all on public.magaza_stok_hareketleri;
create policy magaza_hareket_all on public.magaza_stok_hareketleri
  for all to authenticated using (public.is_magaza()) with check (public.is_magaza());

-- 7) Satış: stok kontrolü + düşüm + kayıt TEK işlemde (iki kişi aynı anda satarsa stok eksiye düşmez)
create or replace function public.magaza_satis_yap(p_kalemler jsonb, p_odeme text, p_fatura text, p_musteri jsonb, p_satan text)
returns uuid language plpgsql security definer as $$
declare
  k jsonb; u public.magaza_urunler; v_adet int; v_toplam numeric := 0; v_kalemler jsonb := '[]'::jsonb; v_id uuid;
begin
  if not public.is_magaza() then raise exception 'Mağaza erişiminiz yok'; end if;
  if p_kalemler is null or jsonb_array_length(p_kalemler) = 0 then raise exception 'Sepet boş'; end if;
  for k in select * from jsonb_array_elements(p_kalemler) loop
    v_adet := (k->>'adet')::int;
    if v_adet is null or v_adet <= 0 then raise exception 'Geçersiz adet'; end if;
    select * into u from public.magaza_urunler where id = (k->>'urun_id')::uuid for update;
    if not found then raise exception 'Ürün bulunamadı'; end if;
    if u.stok < v_adet then raise exception 'Stok yetersiz: % (kalan %)', u.ad, u.stok; end if;
    if u.fiyat <= 0 then raise exception 'Fiyatı girilmemiş ürün: %', u.ad; end if;
    v_kalemler := v_kalemler || jsonb_build_object('urun_id', u.id, 'kod', u.kod, 'ad', u.ad, 'olcu', u.olcu, 'marka', u.marka, 'adet', v_adet, 'fiyat', u.fiyat);
    v_toplam := v_toplam + v_adet * u.fiyat;
  end loop;
  insert into public.magaza_satislar (kalemler, toplam, odeme, fatura, musteri, satan)
    values (v_kalemler, v_toplam, coalesce(p_odeme,'Nakit'), coalesce(p_fatura,'not_requested'), p_musteri, p_satan)
    returning id into v_id;
  for k in select * from jsonb_array_elements(v_kalemler) loop
    update public.magaza_urunler set stok = stok - (k->>'adet')::int where id = (k->>'urun_id')::uuid;
    insert into public.magaza_stok_hareketleri (urun_id, degisim, sebep, satis_id, yapan)
      values ((k->>'urun_id')::uuid, -((k->>'adet')::int), 'Satış', v_id, p_satan);
  end loop;
  return v_id;
end $$;

-- 8) Satış iptali: stok iade
create or replace function public.magaza_satis_iptal(p_satis uuid, p_yapan text)
returns void language plpgsql security definer as $$
declare s public.magaza_satislar; k jsonb;
begin
  if not public.is_magaza() then raise exception 'Mağaza erişiminiz yok'; end if;
  select * into s from public.magaza_satislar where id = p_satis for update;
  if not found then raise exception 'Satış bulunamadı'; end if;
  if s.iptal then return; end if;
  update public.magaza_satislar set iptal = true where id = p_satis;
  for k in select * from jsonb_array_elements(s.kalemler) loop
    if exists (select 1 from public.magaza_urunler where id = (k->>'urun_id')::uuid) then
      update public.magaza_urunler set stok = stok + (k->>'adet')::int where id = (k->>'urun_id')::uuid;
      insert into public.magaza_stok_hareketleri (urun_id, degisim, sebep, satis_id, yapan)
        values ((k->>'urun_id')::uuid, (k->>'adet')::int, 'İptal', p_satis, p_yapan);
    end if;
  end loop;
end $$;

-- 9) Stok giriş / çıkış (elle)
create or replace function public.magaza_stok_degistir(p_urun uuid, p_degisim int, p_sebep text, p_aciklama text, p_yapan text)
returns integer language plpgsql security definer as $$
declare v_yeni int;
begin
  if not public.is_magaza() then raise exception 'Mağaza erişiminiz yok'; end if;
  if p_degisim is null or p_degisim = 0 then raise exception 'Değişim 0 olamaz'; end if;
  update public.magaza_urunler set stok = stok + p_degisim where id = p_urun returning stok into v_yeni;
  if not found then raise exception 'Ürün bulunamadı'; end if;
  if v_yeni < 0 then raise exception 'Stok eksiye düşemez'; end if;
  insert into public.magaza_stok_hareketleri (urun_id, degisim, sebep, aciklama, yapan)
    values (p_urun, p_degisim, coalesce(p_sebep,'Düzeltme'), p_aciklama, p_yapan);
  return v_yeni;
end $$;

grant usage, select on sequence public.magaza_satis_no_seq to authenticated;
grant execute on function public.magaza_satis_yap(jsonb, text, text, jsonb, text) to authenticated;
grant execute on function public.magaza_satis_iptal(uuid, text) to authenticated;
grant execute on function public.magaza_stok_degistir(uuid, int, text, text, text) to authenticated;

-- 10) Anlık senkron
do $$
declare t text;
begin
  foreach t in array array['magaza_urunler','magaza_satislar','magaza_stok_hareketleri'] loop
    if not exists (select 1 from pg_publication_tables where pubname='supabase_realtime' and schemaname='public' and tablename=t) then
      execute format('alter publication supabase_realtime add table public.%I', t);
    end if;
  end loop;
end $$;

notify pgrst, 'reload schema';
-- ============================================================
-- Bitti. Üstte "🛍️ Mağaza" görünür (admin + finans erişimi olanlar otomatik).
-- Başka kişilere: Yönetim → "Mağaza erişimi".
-- Ürünleri almak için: Mağaza → Ürünler → "İçe aktar" → studio_hatch_shop_...html
-- ============================================================
