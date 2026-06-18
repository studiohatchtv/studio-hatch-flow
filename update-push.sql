-- ============================================================
-- studioHATCH Flow — Push bildirim abonelik tablosu
-- YENİ projede çalıştır:
-- https://supabase.com/dashboard/project/uolmzykwvizhmycgymfi/sql/new
-- ============================================================

create table if not exists public.push_subscriptions (
  endpoint   text primary key,
  user_id    uuid references auth.users(id) on delete cascade,
  ad         text,
  p256dh     text not null,
  auth       text not null,
  created_at timestamptz not null default now()
);

alter table public.push_subscriptions enable row level security;

-- giriş yapmış kullanıcı kendi aboneliğini ekleyip silebilsin
drop policy if exists push_all on public.push_subscriptions;
create policy push_all on public.push_subscriptions
  for all to authenticated using (true) with check (true);

notify pgrst, 'reload schema';

-- Bitti.
