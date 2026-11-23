-- ============================================================
-- MizarLabs Flow — Immersive gösterimler (sitede ayrı bölüm + her biri için alt sayfa)
-- Çalıştır: https://supabase.com/dashboard/project/uolmzykwvizhmycgymfi/sql/new
-- update-website.sql çalıştırılmış olmalı (is_website(), site-gorselleri). Tekrar çalıştırılabilir.
-- Bu tablodaki her şey sitede herkese görünecek içeriktir (iç not alanı yok).
-- ============================================================

create table if not exists public.gosterimler (
  id            uuid primary key default gen_random_uuid(),
  yayinda       boolean not null default false,
  one_cikan     boolean not null default false,   -- ana sayfanın büyük alanında
  sira          integer not null default 0,       -- slider sırası (küçük önce)
  baslik        text not null,
  baslik_en     text,
  alt_baslik    text,                             -- ör. "Kökler ve İzler"
  alt_baslik_en text,
  ozet          text,
  ozet_en       text,
  aciklama      text,                             -- paragraflar arasında boş satır
  aciklama_en   text,
  nedir         text,                             -- "Bu nedir?" maddeleri (her satır)
  nedir_en      text,
  ne_degildir   text,                             -- "Ne değildir?" maddeleri (her satır)
  ne_degildir_en text,
  sss           text,                             -- S/C blokları: ilk satır soru, alt satırlar cevap, bloklar arası boş satır
  sss_en        text,
  baslangic     date,
  bitis         date,
  seanslar      text[] not null default '{}',
  sure_dk       integer,
  yas           text,                             -- ör. "7+", "Her yaş"
  yas_en        text,
  fiyat         text,
  fiyat_en      text,
  bilet_url     text,
  gorsel        text,
  created_at    timestamptz not null default now(),
  updated_at    timestamptz not null default now(),
  constraint gosterim_bilet_ck check (bilet_url is null or bilet_url ~* '^https://'),
  constraint gosterim_tarih_ck check (bitis is null or baslangic is null or bitis >= baslangic)
);
create index if not exists gosterim_sira_idx on public.gosterimler(sira, baslangic);

drop trigger if exists trg_gosterim_touch on public.gosterimler;
create trigger trg_gosterim_touch before update on public.gosterimler
  for each row execute function public.touch_updated_at();

alter table public.gosterimler enable row level security;
-- site: yalnızca yayındakileri okur
drop policy if exists gosterim_site_oku on public.gosterimler;
create policy gosterim_site_oku on public.gosterimler for select to anon using (yayinda and coalesce(bitis, current_date) >= current_date - 1);
-- ekip: hepsini görür; website yetkisi olan düzenler
drop policy if exists gosterim_ekip_oku on public.gosterimler;
create policy gosterim_ekip_oku on public.gosterimler for select to authenticated using (true);
drop policy if exists gosterim_yaz on public.gosterimler;
create policy gosterim_yaz on public.gosterimler for all to authenticated using (public.is_website()) with check (public.is_website());

-- genel "Immersive nedir?" ve genel SSS (her gösterim sayfasının altında)
insert into public.site_ayarlar (anahtar, deger) values
  ('immersive_nedir',''), ('immersive_nedir_en',''), ('genel_sss',''), ('genel_sss_en','')
on conflict (anahtar) do nothing;

do $$
begin
  if not exists (select 1 from pg_publication_tables where pubname='supabase_realtime' and schemaname='public' and tablename='gosterimler') then
    alter publication supabase_realtime add table public.gosterimler;
  end if;
end $$;

notify pgrst, 'reload schema';
-- Bitti. Flow → 🌐 Website → Gösterimler
