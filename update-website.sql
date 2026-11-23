-- ============================================================
-- MizarLabs Flow — Website (www.studiohatch.tv) yönetimi
-- Çalıştır: https://supabase.com/dashboard/project/uolmzykwvizhmycgymfi/sql/new
-- update-etkinlik.sql ve update-ziyaretci.sql çalıştırılmış olmalı. Tekrar çalıştırılabilir.
--
-- Güvenlik özeti:
--  * Site (anonim ziyaretçi) etkinlikler tablosunu OKUYAMAZ. Yalnızca site_etkinlikler()
--    fonksiyonu üzerinden, "sitede yayınla" işaretli ve ONAYLANMIŞ etkinliklerin
--    herkese açık alanlarını görür. Talep eden, iletişim, iç notlar asla dışarı çıkmaz.
--  * Site alanlarını yalnızca admin + "website" yetkisi verilen kişiler değiştirebilir.
-- ============================================================

-- 1) Yetki: kisiler.website
alter table public.kisiler add column if not exists website boolean not null default false;
create or replace function public.is_website()
returns boolean language sql security definer stable set search_path = public as $$
  select coalesce((select k.website or k.is_admin from public.kisiler k where k.user_id = auth.uid() limit 1), false)
      or coalesce((auth.jwt() ->> 'email') = 'samet@mizarlabs.com', false);
$$;

-- 2) Etkinliğe site alanları
alter table public.etkinlikler
  add column if not exists site_yayinda    boolean not null default false,
  add column if not exists site_one_cikan  boolean not null default false,
  add column if not exists site_program    text not null default 'culture',
  add column if not exists site_baslik_en  text,
  add column if not exists site_tur_en     text,
  add column if not exists site_ozet       text,
  add column if not exists site_ozet_en    text,
  add column if not exists site_aciklama   text,
  add column if not exists site_aciklama_en text,
  add column if not exists site_bilgiler   text,      -- her satır bir madde
  add column if not exists site_bilgiler_en text,
  add column if not exists site_gorsel     text,
  add column if not exists site_bilet_url  text,
  add column if not exists site_fiyat      text,
  add column if not exists site_fiyat_en   text,
  add column if not exists site_seanslar   text[] not null default '{}',   -- birden çok seans: {"11:00","13:00"}
  add column if not exists site_sure_dk    integer;
alter table public.etkinlikler drop constraint if exists etkinlik_site_program_ck;
alter table public.etkinlikler add constraint etkinlik_site_program_ck check (site_program in ('culture','wellness','nocturne'));
alter table public.etkinlikler drop constraint if exists etkinlik_site_bilet_ck;
alter table public.etkinlikler add constraint etkinlik_site_bilet_ck check (site_bilet_url is null or site_bilet_url ~* '^https://');

-- Takvimi tüm ekip düzenler; ama site alanlarına yalnızca website yetkisi olan dokunabilir
create or replace function public.etkinlik_site_koru()
returns trigger language plpgsql security definer set search_path = public as $$
begin
  if public.is_website() then return new; end if;
  if tg_op = 'INSERT' then
    if new.site_yayinda or new.site_one_cikan then raise exception 'Sitede yayınlama yetkiniz yok'; end if;
    return new;
  end if;
  if (new.site_yayinda, new.site_one_cikan, new.site_program, new.site_baslik_en, new.site_tur_en, new.site_ozet, new.site_ozet_en,
      new.site_aciklama, new.site_aciklama_en, new.site_bilgiler, new.site_bilgiler_en, new.site_gorsel, new.site_bilet_url,
      new.site_fiyat, new.site_fiyat_en, new.site_seanslar, new.site_sure_dk)
     is distinct from
     (old.site_yayinda, old.site_one_cikan, old.site_program, old.site_baslik_en, old.site_tur_en, old.site_ozet, old.site_ozet_en,
      old.site_aciklama, old.site_aciklama_en, old.site_bilgiler, old.site_bilgiler_en, old.site_gorsel, old.site_bilet_url,
      old.site_fiyat, old.site_fiyat_en, old.site_seanslar, old.site_sure_dk) then
    raise exception 'Site bilgilerini değiştirme yetkiniz yok';
  end if;
  return new;
end $$;
drop trigger if exists trg_etkinlik_site_koru on public.etkinlikler;
create trigger trg_etkinlik_site_koru before insert or update on public.etkinlikler
  for each row execute function public.etkinlik_site_koru();

-- 3) Sitenin okuduğu tek kapı: yayınlanmış + onaylanmış etkinliklerin açık alanları
drop function if exists public.site_etkinlikler();
create function public.site_etkinlikler()
returns table (
  id uuid, baslik text, baslik_en text, tur text, tur_en text, program text,
  ozet text, ozet_en text, aciklama text, aciklama_en text, bilgiler text, bilgiler_en text,
  tarih date, bitis_tarih date, baslangic_saat time, bitis_saat time, seanslar text[], sure_dk integer,
  gorsel text, bilet_url text, fiyat text, fiyat_en text, one_cikan boolean
)
language sql security definer stable set search_path = public as $$
  select e.id, e.baslik, e.site_baslik_en, e.tur, e.site_tur_en, e.site_program,
         e.site_ozet, e.site_ozet_en, e.site_aciklama, e.site_aciklama_en, e.site_bilgiler, e.site_bilgiler_en,
         e.tarih, e.bitis_tarih, e.baslangic_saat, e.bitis_saat, e.site_seanslar, e.site_sure_dk,
         e.site_gorsel, e.site_bilet_url, e.site_fiyat, e.site_fiyat_en, e.site_one_cikan
  from public.etkinlikler e
  where e.site_yayinda
    and e.durum in ('Onaylandı','Tamamlandı')
    and coalesce(e.bitis_tarih, e.tarih) >= (now() at time zone 'Europe/Istanbul')::date - 1
    and e.tarih <= (now() at time zone 'Europe/Istanbul')::date + 180
  order by e.tarih, e.baslangic_saat nulls first;
$$;
revoke all on function public.site_etkinlikler() from public;
grant execute on function public.site_etkinlikler() to anon, authenticated;

-- 4) Site ayarları (çalışma saatleri, duyuru bandı…) — içerik zaten herkese açık
create table if not exists public.site_ayarlar (
  anahtar    text primary key,
  deger      text,
  updated_at timestamptz not null default now()
);
alter table public.site_ayarlar enable row level security;
drop policy if exists site_ayar_oku on public.site_ayarlar;
create policy site_ayar_oku on public.site_ayarlar for select to anon, authenticated using (true);
drop policy if exists site_ayar_yaz on public.site_ayarlar;
create policy site_ayar_yaz on public.site_ayarlar for all to authenticated using (public.is_website()) with check (public.is_website());
insert into public.site_ayarlar (anahtar, deger) values
  ('saatler',''), ('saatler_en',''), ('duyuru',''), ('duyuru_en',''), ('instagram','studiohatchtv'), ('eposta','hello@studiohatch.tv')
on conflict (anahtar) do nothing;

-- 5) Site görselleri: herkese açık kova; yalnızca website yetkisi yükler/siler
insert into storage.buckets (id, name, public) values ('site-gorselleri','site-gorselleri', true)
on conflict (id) do nothing;
drop policy if exists site_gorsel_oku on storage.objects;
create policy site_gorsel_oku on storage.objects for select to public using (bucket_id = 'site-gorselleri');
drop policy if exists site_gorsel_yukle on storage.objects;
create policy site_gorsel_yukle on storage.objects for insert to authenticated with check (bucket_id = 'site-gorselleri' and public.is_website());
drop policy if exists site_gorsel_guncelle on storage.objects;
create policy site_gorsel_guncelle on storage.objects for update to authenticated using (bucket_id = 'site-gorselleri' and public.is_website());
drop policy if exists site_gorsel_sil on storage.objects;
create policy site_gorsel_sil on storage.objects for delete to authenticated using (bucket_id = 'site-gorselleri' and public.is_website());

-- 6) Siteden bülten kaydı → Mağaza › Ziyaretçiler (kaynak: web)
create or replace function public.site_bulten_kaydet(p_email text, p_izin_metni text)
returns void language plpgsql security definer set search_path = public as $$
declare v_mail text := lower(trim(coalesce(p_email,'')));
begin
  if v_mail !~ '^[^@[:space:]]+@[^@[:space:]]+\.[^@[:space:]]+$' or length(v_mail) > 200 then raise exception 'E-posta geçersiz'; end if;
  if length(coalesce(p_izin_metni,'')) > 1000 then raise exception 'Geçersiz veri'; end if;
  if exists (select 1 from public.magaza_ziyaretcileri where email = v_mail and kaynak = 'web') then return; end if;
  insert into public.magaza_ziyaretcileri (ad, email, izin_eposta, izin_metni, kaynak)
    values ('Web bülteni', v_mail, true, p_izin_metni, 'web');
end $$;
revoke all on function public.site_bulten_kaydet(text,text) from public;
grant execute on function public.site_bulten_kaydet(text,text) to anon, authenticated;

do $$
begin
  if not exists (select 1 from pg_publication_tables where pubname='supabase_realtime' and schemaname='public' and tablename='site_ayarlar') then
    alter publication supabase_realtime add table public.site_ayarlar;
  end if;
end $$;

notify pgrst, 'reload schema';
-- Bitti. Flow → 🌐 Website
