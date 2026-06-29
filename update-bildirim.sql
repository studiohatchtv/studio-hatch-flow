-- ============================================================
-- MizarLabs Flow — kalıcı Bildirimler kutusu
-- YENİ projede çalıştır:
-- https://supabase.com/dashboard/project/uolmzykwvizhmycgymfi/sql/new
-- ============================================================

create table if not exists public.bildirimler (
  id         uuid primary key default gen_random_uuid(),
  user_id    uuid not null references auth.users(id) on delete cascade,  -- alıcı
  tur        text not null default 'atama',  -- 'atama' | 'yorum'
  metin      text not null,
  is_id      uuid,                            -- ilgili iş
  okundu     boolean not null default false,
  created_at timestamptz not null default now()
);

alter table public.bildirimler enable row level security;

-- herkes (giriş yapmış) başkasına bildirim oluşturabilir
drop policy if exists bildirim_insert on public.bildirimler;
create policy bildirim_insert on public.bildirimler for insert to authenticated with check (true);
-- kişi yalnızca kendi bildirimlerini görür/günceller/siler
drop policy if exists bildirim_select on public.bildirimler;
create policy bildirim_select on public.bildirimler for select to authenticated using (user_id = auth.uid());
drop policy if exists bildirim_update on public.bildirimler;
create policy bildirim_update on public.bildirimler for update to authenticated using (user_id = auth.uid());
drop policy if exists bildirim_delete on public.bildirimler;
create policy bildirim_delete on public.bildirimler for delete to authenticated using (user_id = auth.uid());

do $$
begin
  if not exists (select 1 from pg_publication_tables where pubname='supabase_realtime' and schemaname='public' and tablename='bildirimler') then
    alter publication supabase_realtime add table public.bildirimler;
  end if;
end $$;

notify pgrst, 'reload schema';
-- Bitti. Üstteki 🔔 ile bildirimler açılır.
