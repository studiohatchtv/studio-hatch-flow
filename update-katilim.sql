-- ============================================================
-- MizarLabs Flow — "Hatch'e Katıl" başvuruları (Tasarımcı / Atölye / Etkinlik)
-- Dijital Art'ın "basvurular" tablosundan tamamen AYRIDIR.
-- Çalıştır: https://supabase.com/dashboard/project/uolmzykwvizhmycgymfi/sql/new
-- Tekrar çalıştırılabilir.
-- ============================================================

-- 1) update-basvurular.sql yanlışlıkla "basvurular" tablosuna dokunduysa geri al.
--    Sadece o dosyanın eklediği kolon/policy/fonksiyonlar kaldırılır; eser kayıtları korunur.
drop policy if exists basvurular_admin_all on public.basvurular;
drop policy if exists basvurular_insert_public on public.basvurular;
drop policy if exists basvurular_select_owner on public.basvurular;
drop function if exists public.basvuru_gonder(text, text, text, text, text, text, jsonb);
drop function if exists public.basvuru_guncelle(uuid, text, text);
drop index if exists public.basvurular_tarih_idx;

do $$
declare dolu boolean := false;
begin
  if exists (select 1 from information_schema.columns where table_schema='public' and table_name='basvurular' and column_name='ad_soyad') then
    execute $q$select exists(select 1 from public.basvurular where coalesce(ad_soyad,'') <> '')$q$ into dolu;
    if dolu then
      raise notice 'basvurular.ad_soyad dolu kayıt içeriyor; kolonlar silinmedi.';
    else
      alter table public.basvurular
        drop column if exists basvuru_turu, drop column if exists ad_soyad, drop column if exists email,
        drop column if exists telefon, drop column if exists instagram, drop column if exists website,
        drop column if exists alanlar, drop column if exists durum, drop column if exists not_admin;
    end if;
  end if;
end $$;

-- 2) Yeni tablo
create table if not exists public.katilim_basvurulari (
  id         uuid primary key default gen_random_uuid(),
  tur        text not null,                 -- Tasarımcı & Marka | Atölye | Etkinlik & İş Birliği
  ad         text not null,
  email      text not null,
  telefon    text,
  sosyal     text,
  website    text,
  alanlar    jsonb not null default '[]',   -- [{etiket, deger}] (sıra korunsun diye dizi)
  dosyalar   jsonb not null default '[]',   -- [{ad, yol, url, tur, boyut}]
  durum      text not null default 'Yeni',  -- Yeni | İletişime geçildi | Seçildi | Reddedildi
  not_admin  text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);
create index if not exists katilim_tarih_idx on public.katilim_basvurulari(created_at desc);

drop trigger if exists trg_katilim_touch on public.katilim_basvurulari;
create trigger trg_katilim_touch before update on public.katilim_basvurulari
  for each row execute function public.touch_updated_at();

-- 3) Güvenlik: tabloyu sadece adminler görür/yönetir. Dışarıdan tabloya doğrudan erişim yok.
alter table public.katilim_basvurulari enable row level security;
drop policy if exists katilim_admin_all on public.katilim_basvurulari;
create policy katilim_admin_all on public.katilim_basvurulari
  for all to authenticated using (public.is_admin()) with check (public.is_admin());

-- 4) Dış form yalnızca bu fonksiyonla kayıt ekler
create or replace function public.katilim_basvuru_gonder(
  p_tur text, p_ad text, p_email text, p_telefon text, p_sosyal text, p_website text,
  p_alanlar jsonb, p_dosyalar jsonb
)
returns uuid language plpgsql security definer set search_path = public as $$
declare v_id uuid;
begin
  if p_tur not in ('Tasarımcı & Marka','Atölye','Etkinlik & İş Birliği') then raise exception 'Geçersiz başvuru türü'; end if;
  if length(trim(coalesce(p_ad,''))) = 0 or length(p_ad) > 200 then raise exception 'Ad soyad / marka adı gerekli'; end if;
  if coalesce(p_email,'') !~ '^[^@[:space:]]+@[^@[:space:]]+\.[^@[:space:]]+$' or length(p_email) > 200 then raise exception 'Geçerli bir e-posta girin'; end if;
  if length(coalesce(p_telefon,'')) > 50 or length(coalesce(p_sosyal,'')) > 300 or length(coalesce(p_website,'')) > 300 then raise exception 'Alan çok uzun'; end if;
  if jsonb_typeof(coalesce(p_alanlar,'[]'::jsonb)) <> 'array' or jsonb_typeof(coalesce(p_dosyalar,'[]'::jsonb)) <> 'array' then raise exception 'Geçersiz veri'; end if;
  if pg_column_size(coalesce(p_alanlar,'[]'::jsonb)) > 100000 or jsonb_array_length(coalesce(p_dosyalar,'[]'::jsonb)) > 30 then raise exception 'Başvuru çok büyük'; end if;
  insert into public.katilim_basvurulari (tur, ad, email, telefon, sosyal, website, alanlar, dosyalar)
    values (p_tur, trim(p_ad), trim(p_email), nullif(trim(p_telefon),''), nullif(trim(p_sosyal),''), nullif(trim(p_website),''),
            coalesce(p_alanlar,'[]'::jsonb), coalesce(p_dosyalar,'[]'::jsonb))
    returning id into v_id;
  return v_id;
end $$;
revoke all on function public.katilim_basvuru_gonder(text,text,text,text,text,text,jsonb,jsonb) from public;
grant execute on function public.katilim_basvuru_gonder(text,text,text,text,text,text,jsonb,jsonb) to anon, authenticated;

-- 5) Anlık senkron
do $$
begin
  if not exists (select 1 from pg_publication_tables where pubname='supabase_realtime' and schemaname='public' and tablename='katilim_basvurulari') then
    alter publication supabase_realtime add table public.katilim_basvurulari;
  end if;
end $$;

notify pgrst, 'reload schema';
-- Bitti. Flow → 📨 Başvurular. Dış form: https://studiohatchtv.github.io/studio-hatch-flow/katil
