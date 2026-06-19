-- ============================================================
-- MizarLabs Flow — proje üyelikleri (kim hangi projeyi görür)
-- YENİ projede çalıştır:
-- https://supabase.com/dashboard/project/uolmzykwvizhmycgymfi/sql/new
-- Not: Bu sadece arayüz sadeliği içindir (gizlilik değil).
-- ============================================================

create table if not exists public.proje_uyeleri (
  proje_id   uuid not null references public.projeler(id) on delete cascade,
  kisiler_id uuid not null references public.kisiler(id)  on delete cascade,
  primary key (proje_id, kisiler_id)
);

alter table public.proje_uyeleri enable row level security;

drop policy if exists uyeler_read on public.proje_uyeleri;
create policy uyeler_read on public.proje_uyeleri for select to authenticated using (true);

drop policy if exists uyeler_admin on public.proje_uyeleri;
create policy uyeler_admin on public.proje_uyeleri for all to authenticated using (public.is_admin()) with check (public.is_admin());

do $$
begin
  if not exists (select 1 from pg_publication_tables where pubname='supabase_realtime' and schemaname='public' and tablename='proje_uyeleri') then
    alter publication supabase_realtime add table public.proje_uyeleri;
  end if;
end $$;

notify pgrst, 'reload schema';
-- Bitti. Yönetim → "Proje üyeleri" bölümünden kimin hangi projeyi göreceğini seç.
