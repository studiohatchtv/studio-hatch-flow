-- ============================================================
-- MizarLabs Flow — işe dosya/fotoğraf ekleme (Supabase Storage)
-- YENİ projede çalıştır:
-- https://supabase.com/dashboard/project/uolmzykwvizhmycgymfi/sql/new
-- ============================================================

-- 1) Depolama kovası (public okuma — iç araç; dosya yolları tahmin edilemez)
insert into storage.buckets (id, name, public)
values ('is-dosyalari', 'is-dosyalari', true)
on conflict (id) do nothing;

-- 2) Storage kuralları: herkes okur, giriş yapan yükler/siler
drop policy if exists dosya_read   on storage.objects;
create policy dosya_read   on storage.objects for select to public        using (bucket_id = 'is-dosyalari');
drop policy if exists dosya_insert on storage.objects;
create policy dosya_insert on storage.objects for insert to authenticated with check (bucket_id = 'is-dosyalari');
drop policy if exists dosya_update on storage.objects;
create policy dosya_update on storage.objects for update to authenticated using (bucket_id = 'is-dosyalari');
drop policy if exists dosya_delete on storage.objects;
create policy dosya_delete on storage.objects for delete to authenticated using (bucket_id = 'is-dosyalari');

-- 3) Dosya kayıtları (hangi iş, hangi dosya)
create table if not exists public.is_dosyalari (
  id         uuid primary key default gen_random_uuid(),
  is_id      uuid not null references public.isler(id) on delete cascade,
  ad         text not null,
  yol        text not null,
  url        text not null,
  tur        text,
  boyut      int,
  created_by uuid references auth.users(id) default auth.uid(),
  created_at timestamptz not null default now()
);

alter table public.is_dosyalari enable row level security;
drop policy if exists dosyalar_all on public.is_dosyalari;
create policy dosyalar_all on public.is_dosyalari for all to authenticated using (true) with check (true);

do $$
begin
  if not exists (select 1 from pg_publication_tables where pubname='supabase_realtime' and schemaname='public' and tablename='is_dosyalari') then
    alter publication supabase_realtime add table public.is_dosyalari;
  end if;
end $$;

notify pgrst, 'reload schema';
-- Bitti. İşi aç → "Dosyalar / fotoğraflar" alanından yükle.
