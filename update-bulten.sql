-- ============================================================
-- MizarLabs Flow — Site bülten formu: isteğe bağlı ad soyad, telefon, ilgi alanları + KVKK metni
-- Çalıştır: https://supabase.com/dashboard/project/uolmzykwvizhmycgymfi/sql/new
-- update-website.sql çalıştırılmış olmalı. Tekrar çalıştırılabilir.
-- Kayıtlar yine Mağaza › Ziyaretçiler'e düşer (kaynak: web).
-- ============================================================

-- eski 2 parametreli sürüm kaldırılır; yenisi aynı çağrıyı da kabul eder (diğer alanlar isteğe bağlı)
drop function if exists public.site_bulten_kaydet(text, text);
drop function if exists public.site_bulten_kaydet(text, text, text, text, boolean, text[]);
create function public.site_bulten_kaydet(
  p_email text, p_izin_metni text,
  p_ad text default null, p_telefon text default null, p_izin_telefon boolean default false, p_ilgi text[] default '{}'
)
returns void language plpgsql security definer set search_path = public as $$
declare
  v_mail text := lower(trim(coalesce(p_email,'')));
  v_ad   text := nullif(trim(coalesce(p_ad,'')), '');
  v_tel  text := nullif(regexp_replace(coalesce(p_telefon,''), '\D', '', 'g'), '');
  v_ilgi text[] := coalesce(p_ilgi, '{}');
  v_id   uuid;
begin
  if v_mail !~ '^[^@[:space:]]+@[^@[:space:]]+\.[^@[:space:]]+$' or length(v_mail) > 200 then raise exception 'E-posta geçersiz'; end if;
  if v_ad is not null and length(v_ad) > 120 then raise exception 'Ad çok uzun'; end if;
  if v_tel is not null and length(v_tel) = 10 and left(v_tel,1) = '5' then v_tel := '0' || v_tel; end if;
  if v_tel is not null and length(v_tel) not between 10 and 13 then raise exception 'Telefon numarası geçersiz'; end if;
  if coalesce(p_izin_telefon,false) and v_tel is null then raise exception 'Telefon izni için telefon gerekli'; end if;
  if coalesce(array_length(v_ilgi,1),0) > 20 or exists (select 1 from unnest(v_ilgi) x where length(x) > 60) then raise exception 'Geçersiz veri'; end if;
  if length(coalesce(p_izin_metni,'')) > 2000 then raise exception 'Geçersiz veri'; end if;

  select id into v_id from public.magaza_ziyaretcileri where email = v_mail and kaynak = 'web' limit 1;
  if v_id is not null then
    -- aynı e-posta tekrar gelirse: yalnızca boş alanlar doldurulur, izinler/ilgiler eklenir (başkasının bilgisi ezilmez)
    update public.magaza_ziyaretcileri set
      ad           = case when ad = 'Web bülteni' and v_ad is not null then v_ad else ad end,
      telefon      = coalesce(telefon, v_tel),
      izin_eposta  = true,
      izin_telefon = izin_telefon or (coalesce(p_izin_telefon,false) and (telefon is null or telefon = v_tel)),
      ilgi         = (select coalesce(array_agg(distinct x), '{}') from unnest(ilgi || v_ilgi) x),
      izin_metni   = p_izin_metni
    where id = v_id;
    return;
  end if;
  insert into public.magaza_ziyaretcileri (ad, telefon, email, izin_eposta, izin_telefon, ilgi, izin_metni, kaynak)
    values (coalesce(v_ad,'Web bülteni'), v_tel, v_mail, true, coalesce(p_izin_telefon,false), v_ilgi, p_izin_metni, 'web');
end $$;
revoke all on function public.site_bulten_kaydet(text,text,text,text,boolean,text[]) from public;
grant execute on function public.site_bulten_kaydet(text,text,text,text,boolean,text[]) to anon, authenticated;

-- KVKK aydınlatma metni (Flow → Website → Site bilgileri'nden düzenlenir; boşsa sitedeki taslak görünür)
insert into public.site_ayarlar (anahtar, deger) values ('kvkk',''), ('kvkk_en','')
on conflict (anahtar) do nothing;

notify pgrst, 'reload schema';
-- Bitti.
