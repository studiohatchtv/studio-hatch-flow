-- ============================================================
-- studio HATCH sitesi — etkinlik ve gösterim sayfalarına fotoğraf galerisi
-- Çalıştır: https://supabase.com/dashboard/project/uolmzykwvizhmycgymfi/sql/new
-- update-video.sql çalıştırılmış olmalı. Tekrar çalıştırılabilir.
-- ============================================================

-- 1) Galeri alanları (sıralı fotoğraf adresleri, en fazla 12)
alter table public.etkinlikler add column if not exists site_galeri text[] not null default '{}';
alter table public.gosterimler add column if not exists galeri text[] not null default '{}';
alter table public.etkinlikler drop constraint if exists etkinlikler_site_galeri_max;
alter table public.etkinlikler add constraint etkinlikler_site_galeri_max check (cardinality(site_galeri) <= 12);
alter table public.gosterimler drop constraint if exists gosterimler_galeri_max;
alter table public.gosterimler add constraint gosterimler_galeri_max check (cardinality(galeri) <= 12);

-- 2) Etkinlik site alanlarının korunmasına galeri de dahil
create or replace function public.etkinlik_site_koru()
returns trigger language plpgsql security definer set search_path = public as $fn$
begin
  if public.is_website() then return new; end if;
  if tg_op = 'INSERT' then
    if new.site_yayinda or new.site_one_cikan or new.site_video is not null or cardinality(new.site_galeri) > 0 then raise exception 'Sitede yayınlama yetkiniz yok'; end if;
    return new;
  end if;
  if (new.site_yayinda, new.site_one_cikan, new.site_program, new.site_baslik_en, new.site_tur_en, new.site_ozet, new.site_ozet_en,
      new.site_aciklama, new.site_aciklama_en, new.site_bilgiler, new.site_bilgiler_en, new.site_gorsel, new.site_bilet_url,
      new.site_fiyat, new.site_fiyat_en, new.site_seanslar, new.site_sure_dk, new.site_video, new.site_galeri)
     is distinct from
     (old.site_yayinda, old.site_one_cikan, old.site_program, old.site_baslik_en, old.site_tur_en, old.site_ozet, old.site_ozet_en,
      old.site_aciklama, old.site_aciklama_en, old.site_bilgiler, old.site_bilgiler_en, old.site_gorsel, old.site_bilet_url,
      old.site_fiyat, old.site_fiyat_en, old.site_seanslar, old.site_sure_dk, old.site_video, old.site_galeri) then
    raise exception 'Site bilgilerini değiştirme yetkiniz yok';
  end if;
  return new;
end $fn$;

-- 3) Sitenin okuduğu fonksiyon galeriyi de döndürsün
drop function if exists public.site_etkinlikler();
create function public.site_etkinlikler()
returns table (
  id uuid, baslik text, baslik_en text, tur text, tur_en text, program text,
  ozet text, ozet_en text, aciklama text, aciklama_en text, bilgiler text, bilgiler_en text,
  tarih date, bitis_tarih date, baslangic_saat time, bitis_saat time, seanslar text[], sure_dk integer,
  gorsel text, bilet_url text, fiyat text, fiyat_en text, one_cikan boolean, video text, galeri text[]
)
language sql security definer stable set search_path = public as $fn$
  select e.id, e.baslik, e.site_baslik_en, e.tur, e.site_tur_en, e.site_program,
         e.site_ozet, e.site_ozet_en, e.site_aciklama, e.site_aciklama_en, e.site_bilgiler, e.site_bilgiler_en,
         e.tarih, e.bitis_tarih, e.baslangic_saat, e.bitis_saat, e.site_seanslar, e.site_sure_dk,
         e.site_gorsel, e.site_bilet_url, e.site_fiyat, e.site_fiyat_en, e.site_one_cikan, e.site_video, e.site_galeri
  from public.etkinlikler e
  where e.site_yayinda
    and e.durum in ('Onaylandı','Tamamlandı')
    and coalesce(e.bitis_tarih, e.tarih) >= (now() at time zone 'Europe/Istanbul')::date - 1
    and e.tarih <= (now() at time zone 'Europe/Istanbul')::date + 180
  order by e.tarih, e.baslangic_saat nulls first;
$fn$;
revoke all on function public.site_etkinlikler() from public;
grant execute on function public.site_etkinlikler() to anon, authenticated;

notify pgrst, 'reload schema';
-- Bitti. Flow → 🌐 Website → etkinlik / gösterim → "Galeri"
