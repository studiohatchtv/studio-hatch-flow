-- ============================================================
-- MizarLabs Flow — Etkinlik Takvimi (ekip içi koordinasyon)
-- Çalıştır: https://supabase.com/dashboard/project/uolmzykwvizhmycgymfi/sql/new
-- update-katilim.sql çalıştırılmış olmalı. Tekrar çalıştırılabilir.
-- ============================================================

create table if not exists public.etkinlikler (
  id              uuid primary key default gen_random_uuid(),
  baslik          text not null,
  tur             text not null default 'Diğer',
  durum           text not null default 'Talep',     -- Talep | Opsiyon | Onaylandı | Tamamlandı | İptal
  tarih           date not null,
  bitis_tarih     date,                              -- çok günlü etkinlik (boşsa tek gün)
  baslangic_saat  time,
  bitis_saat      time,
  alan            text,                              -- mekân / salon
  sorumlu         text,                              -- ekipten ana sorumlu (ad)
  ekip            text[] not null default '{}',      -- görevli diğer kişiler (ad)
  talep_eden      text,
  talep_iletisim  text,
  kisi_sayisi     integer,
  notlar          text,
  katilim_id      uuid references public.katilim_basvurulari(id) on delete set null,
  created_by      uuid default auth.uid(),
  created_at      timestamptz not null default now(),
  updated_at      timestamptz not null default now(),
  constraint etkinlik_bitis_ck check (bitis_tarih is null or bitis_tarih >= tarih)
);
create index if not exists etkinlik_tarih_idx on public.etkinlikler(tarih);

drop trigger if exists trg_etkinlik_touch on public.etkinlikler;
create trigger trg_etkinlik_touch before update on public.etkinlikler
  for each row execute function public.touch_updated_at();

-- Tüm ekip görür ve düzenler (işler gibi)
alter table public.etkinlikler enable row level security;
drop policy if exists etkinlik_all on public.etkinlikler;
create policy etkinlik_all on public.etkinlikler
  for all to authenticated using (true) with check (true);

do $$
begin
  if not exists (select 1 from pg_publication_tables where pubname='supabase_realtime' and schemaname='public' and tablename='etkinlikler') then
    alter publication supabase_realtime add table public.etkinlikler;
  end if;
end $$;

notify pgrst, 'reload schema';
-- Bitti. Flow → 📅 Etkinlik Takvimi
