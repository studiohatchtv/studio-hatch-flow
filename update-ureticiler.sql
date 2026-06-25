-- ============================================================
-- MizarLabs Flow — Üreticiler (mağaza için yerel üretici/tedarikçi takibi)
-- YENİ projede çalıştır:
-- https://supabase.com/dashboard/project/uolmzykwvizhmycgymfi/sql/new
-- ============================================================

create table if not exists public.ureticiler (
  id          uuid primary key default gen_random_uuid(),
  magaza      text not null,
  urun_grubu  text,
  instagram   text,
  website     text,
  asama       text not null default 'Teklif İletildi',
  kisi1_ad    text,
  kisi1_tel   text,
  kisi2_ad    text,
  kisi2_tel   text,
  created_by  uuid references auth.users(id) default auth.uid(),
  created_at  timestamptz not null default now(),
  updated_at  timestamptz not null default now()
);

drop trigger if exists trg_ureticiler_touch on public.ureticiler;
create trigger trg_ureticiler_touch before update on public.ureticiler
  for each row execute function public.touch_updated_at();

alter table public.ureticiler enable row level security;
drop policy if exists ureticiler_all on public.ureticiler;
create policy ureticiler_all on public.ureticiler for all to authenticated using (true) with check (true);

do $$
begin
  if not exists (select 1 from pg_publication_tables where pubname='supabase_realtime' and schemaname='public' and tablename='ureticiler') then
    alter publication supabase_realtime add table public.ureticiler;
  end if;
end $$;

notify pgrst, 'reload schema';
-- Bitti. Üstte "🏭 Üreticiler" → "+ Üretici" ile ekle. Aşamalar kanban kolonları.
