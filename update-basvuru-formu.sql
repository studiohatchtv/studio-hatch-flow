-- ============================================================
-- MizarLabs Flow — Dış başvuru formu (sanatçı doldurur, login yok)
-- YENİ projede çalıştır:
-- https://supabase.com/dashboard/project/uolmzykwvizhmycgymfi/sql/new
-- ============================================================

-- 1) Başvurana ait iletişim alanları (Kontaklar'da olmayabilir)
alter table public.basvurular add column if not exists basvuru_ad    text;
alter table public.basvurular add column if not exists basvuru_email text;
alter table public.basvurular add column if not exists basvuru_tel   text;

-- 2) Dışarıdan (anonim) SADECE EKLEME izni
--    Not: anon yalnızca ekler; mevcut başvuruları GÖREMEZ/güncelleyemez.
drop policy if exists basvurular_anon_insert on public.basvurular;
create policy basvurular_anon_insert on public.basvurular
  for insert to anon with check (true);

drop policy if exists basvuru_dosya_anon_insert on public.basvuru_dosyalari;
create policy basvuru_dosya_anon_insert on public.basvuru_dosyalari
  for insert to anon with check (true);

-- 3) Storage: anonim yükleme (yalnızca 'is-dosyalari' kovası)
drop policy if exists dosya_anon_insert on storage.objects;
create policy dosya_anon_insert on storage.objects
  for insert to anon with check (bucket_id = 'is-dosyalari');

notify pgrst, 'reload schema';
-- Bitti. Dış form: .../basvuru.html
