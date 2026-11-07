-- ============================================================
-- MizarLabs Flow — Başvurular (Tasarımcı, Atölye, Etkinlik)
-- YENİ projede çalıştır:
-- https://supabase.com/dashboard/project/uolmzykwvizhmycgymfi/sql/new
-- ============================================================

-- 1) Başvurular tablosu
create table if not exists public.basvurular (
  id         uuid primary key default gen_random_uuid(),
  basvuru_turu text not null,      -- Tasarımcı & Marka | Atölye | Etkinlik & İş Birliği
  ad_soyad   text not null,
  email      text not null,
  telefon    text,
  instagram  text,
  website    text,
  alanlar    jsonb not null default '{}',  -- tür-spesifik alanlar
  durum      text not null default 'yeni',  -- yeni | kontakta_çıkıldı | seçildi | reddedildi
  not_admin  text,
  created_by uuid,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index if not exists basvurular_durum_idx on public.basvurular(durum);
create index if not exists basvurular_tarih_idx on public.basvurular(created_at desc);
create index if not exists basvurular_turu_idx on public.basvurular(basvuru_turu);

drop trigger if exists trg_basvurular_touch on public.basvurular;
create trigger trg_basvurular_touch before update on public.basvurular
  for each row execute function public.touch_updated_at();

-- 2) Güvenlik: admin-only okuma/yazma
alter table public.basvurular enable row level security;
drop policy if exists basvurular_admin_all on public.basvurular;
create policy basvurular_admin_all on public.basvurular
  for all to authenticated using (public.is_admin()) with check (public.is_admin());

drop policy if exists basvurular_insert_public on public.basvurular;
create policy basvurular_insert_public on public.basvurular
  for insert to authenticated, anon with check (true);

drop policy if exists basvurular_select_owner on public.basvurular;
create policy basvurular_select_owner on public.basvurular
  for select using (auth.uid() = created_by or public.is_admin());

-- 3) Başvuru gönderme (form submit → RPC)
create or replace function public.basvuru_gonder(
  p_turu text, p_ad_soyad text, p_email text, p_telefon text,
  p_instagram text, p_website text, p_alanlar jsonb
)
returns uuid language plpgsql security definer as $$
declare v_id uuid;
begin
  if p_ad_soyad is null or p_email is null then
    raise exception 'Ad/soyad ve e-posta zorunlu';
  end if;
  insert into public.basvurular (basvuru_turu, ad_soyad, email, telefon, instagram, website, alanlar, created_by)
    values (p_turu, p_ad_soyad, p_email, p_telefon, p_instagram, p_website, coalesce(p_alanlar, '{}'::jsonb), auth.uid())
    returning id into v_id;
  return v_id;
end $$;

-- 4) Başvuru not ekle / durum değiştir (admin)
create or replace function public.basvuru_guncelle(
  p_id uuid, p_durum text, p_not text
)
returns void language plpgsql security definer as $$
begin
  if not public.is_admin() then raise exception 'Yönetici erişimi gerekli'; end if;
  update public.basvurular set durum = coalesce(p_durum, durum), not_admin = coalesce(p_not, not_admin)
    where id = p_id;
end $$;

grant execute on function public.basvuru_gonder(text, text, text, text, text, text, jsonb) to authenticated, anon;
grant execute on function public.basvuru_guncelle(uuid, text, text) to authenticated;

-- 5) Anlık senkron
do $$
begin
  if not exists (select 1 from pg_publication_tables where pubname='supabase_realtime' and schemaname='public' and tablename='basvurular') then
    alter publication supabase_realtime add table public.basvurular;
  end if;
end $$;

notify pgrst, 'reload schema';
-- Bitti. Flow → 📋 Başvurular
