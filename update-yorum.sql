-- ============================================================
-- MizarLabs Flow — kart içi yorumlar/notlar
-- YENİ projede çalıştır:
-- https://supabase.com/dashboard/project/uolmzykwvizhmycgymfi/sql/new
-- ============================================================

create table if not exists public.yorumlar (
  id         uuid primary key default gen_random_uuid(),
  is_id      uuid not null references public.isler(id) on delete cascade,
  yazan      text,
  yazan_id   uuid references auth.users(id) default auth.uid(),
  metin      text not null,
  etiketliler uuid[] default '{}',
  created_at timestamptz not null default now()
);
-- daha önce kurulmuşsa etiket kolonunu ekle
alter table public.yorumlar add column if not exists etiketliler uuid[] default '{}';

alter table public.yorumlar enable row level security;

drop policy if exists yorum_read   on public.yorumlar;
create policy yorum_read   on public.yorumlar for select to authenticated using (true);
drop policy if exists yorum_insert on public.yorumlar;
create policy yorum_insert on public.yorumlar for insert to authenticated with check (true);
-- yorumu sadece yazan ya da admin silebilir
drop policy if exists yorum_delete on public.yorumlar;
create policy yorum_delete on public.yorumlar for delete to authenticated using (yazan_id = auth.uid() or public.is_admin());

do $$
begin
  if not exists (select 1 from pg_publication_tables where pubname='supabase_realtime' and schemaname='public' and tablename='yorumlar') then
    alter publication supabase_realtime add table public.yorumlar;
  end if;
end $$;

notify pgrst, 'reload schema';
-- Bitti. İşi aç → "Yorumlar / notlar" bölümünden yaz.
