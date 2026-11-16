-- ============================================================
-- MizarLabs Flow — Mağaza ziyaretçileri (dokunmatik ekran / kiosk)
-- Çalıştır: https://supabase.com/dashboard/project/uolmzykwvizhmycgymfi/sql/new
-- update-magaza.sql çalıştırılmış olmalı (is_magaza()). Tekrar çalıştırılabilir.
-- ============================================================

create table if not exists public.magaza_ziyaretcileri (
  id            uuid primary key default gen_random_uuid(),
  ad            text not null,
  telefon       text,
  email         text,
  izin_eposta   boolean not null default false,
  izin_telefon  boolean not null default false,
  ilgi          text[] not null default '{}',
  izin_metni    text,                          -- ekranda gösterilen onay metni (kanıt için)
  kaynak        text not null default 'kiosk',
  durum         text not null default 'Yeni',  -- Yeni | İletişime geçildi | Ulaşılamadı
  notlar        text,
  created_at    timestamptz not null default now(),
  updated_at    timestamptz not null default now()
);
create index if not exists ziyaretci_tarih_idx on public.magaza_ziyaretcileri(created_at desc);

drop trigger if exists trg_ziyaretci_touch on public.magaza_ziyaretcileri;
create trigger trg_ziyaretci_touch before update on public.magaza_ziyaretcileri
  for each row execute function public.touch_updated_at();

-- Listeyi sadece Mağaza erişimi olanlar görür/yönetir
alter table public.magaza_ziyaretcileri enable row level security;
drop policy if exists ziyaretci_magaza_all on public.magaza_ziyaretcileri;
create policy ziyaretci_magaza_all on public.magaza_ziyaretcileri
  for all to authenticated using (public.is_magaza()) with check (public.is_magaza());

-- Kiosk yalnızca bu fonksiyonla kayıt ekler (tabloyu okuyamaz)
create or replace function public.ziyaretci_kaydet(
  p_ad text, p_telefon text, p_email text, p_izin_eposta boolean, p_izin_telefon boolean,
  p_ilgi text[], p_izin_metni text
)
returns uuid language plpgsql security definer set search_path = public as $$
declare v_id uuid; v_tel text := nullif(regexp_replace(coalesce(p_telefon,''), '[^0-9+]', '', 'g'), ''); v_mail text := nullif(lower(trim(coalesce(p_email,''))), '');
begin
  if length(trim(coalesce(p_ad,''))) < 2 or length(p_ad) > 120 then raise exception 'Ad soyad gerekli'; end if;
  if v_tel is null and v_mail is null then raise exception 'Telefon veya e-posta gerekli'; end if;
  if v_tel is not null and length(regexp_replace(v_tel,'\D','','g')) not between 10 and 13 then raise exception 'Telefon numarası geçersiz'; end if;
  if v_mail is not null and (v_mail !~ '^[^@[:space:]]+@[^@[:space:]]+\.[^@[:space:]]+$' or length(v_mail) > 200) then raise exception 'E-posta geçersiz'; end if;
  if coalesce(p_izin_eposta,false) and v_mail is null then raise exception 'E-posta izni için e-posta gerekli'; end if;
  if coalesce(p_izin_telefon,false) and v_tel is null then raise exception 'Telefon izni için telefon gerekli'; end if;
  if coalesce(array_length(p_ilgi,1),0) > 20 or length(coalesce(p_izin_metni,'')) > 2000 then raise exception 'Geçersiz veri'; end if;
  insert into public.magaza_ziyaretcileri (ad, telefon, email, izin_eposta, izin_telefon, ilgi, izin_metni)
    values (trim(p_ad), v_tel, v_mail, coalesce(p_izin_eposta,false), coalesce(p_izin_telefon,false), coalesce(p_ilgi,'{}'), p_izin_metni)
    returning id into v_id;
  return v_id;
end $$;
revoke all on function public.ziyaretci_kaydet(text,text,text,boolean,boolean,text[],text) from public;
grant execute on function public.ziyaretci_kaydet(text,text,text,boolean,boolean,text[],text) to anon, authenticated;

do $$
begin
  if not exists (select 1 from pg_publication_tables where pubname='supabase_realtime' and schemaname='public' and tablename='magaza_ziyaretcileri') then
    alter publication supabase_realtime add table public.magaza_ziyaretcileri;
  end if;
end $$;

notify pgrst, 'reload schema';
-- Bitti. Ekran: https://studiohatchtv.github.io/studio-hatch-flow/kiosk · Liste: Flow → Mağaza → Ziyaretçiler
