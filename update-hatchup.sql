-- ============================================================
-- studio HATCH — HATCH Up · Immersive Pop-Up (20 Aralık 2026) başvuruları
-- Çalıştır: https://supabase.com/dashboard/project/uolmzykwvizhmycgymfi/sql/new
-- update-katilim.sql çalıştırılmış olmalı. Tekrar çalıştırılabilir.
-- Başvurular Flow → 📨 Başvurular'a "HATCH Up · Pop-Up" türüyle düşer.
-- ============================================================

create or replace function public.katilim_basvuru_gonder(
  p_tur text, p_ad text, p_email text, p_telefon text, p_sosyal text, p_website text,
  p_alanlar jsonb, p_dosyalar jsonb
)
returns uuid language plpgsql security definer set search_path = public as $fn$
declare v_id uuid;
begin
  if p_tur not in ('Tasarımcı & Marka','Atölye','Etkinlik & İş Birliği','HATCH Up · Pop-Up') then raise exception 'Geçersiz başvuru türü'; end if;
  -- HATCH Up: son başvuru 1 Aralık 2026 23:59 (Türkiye saati)
  if p_tur = 'HATCH Up · Pop-Up' and now() >= timestamptz '2026-12-02 00:00:00+03' then raise exception 'HATCH Up başvuruları kapandı'; end if;
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
end $fn$;
revoke all on function public.katilim_basvuru_gonder(text,text,text,text,text,text,jsonb,jsonb) from public;
grant execute on function public.katilim_basvuru_gonder(text,text,text,text,text,text,jsonb,jsonb) to anon, authenticated;

notify pgrst, 'reload schema';
-- Bitti. Form: https://www.studiohatch.tv/hatch-up.html
