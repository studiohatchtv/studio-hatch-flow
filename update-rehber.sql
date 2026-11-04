-- ============================================================
-- MizarLabs Flow — Rehber (Kontaklar'ın detaylı hali: influencer, partner, sponsor...)
-- YENİ projede çalıştır:
-- https://supabase.com/dashboard/project/uolmzykwvizhmycgymfi/sql/new
-- Mevcut kontaklar korunur; sadece yeni alanlar eklenir. Tekrar çalıştırılabilir.
-- ============================================================

-- 1) Kontaklara yeni alanlar
alter table public.kontaklar add column if not exists kategori      text not null default 'Diğer';
alter table public.kontaklar add column if not exists durum         text not null default 'Aktif';   -- Aktif | Görüşülüyor | Potansiyel | Pasif
alter table public.kontaklar add column if not exists unvan         text;
alter table public.kontaklar add column if not exists sehir         text;
alter table public.kontaklar add column if not exists instagram     text;
alter table public.kontaklar add column if not exists tiktok        text;
alter table public.kontaklar add column if not exists youtube       text;
alter table public.kontaklar add column if not exists website       text;
alter table public.kontaklar add column if not exists takipci       integer;
alter table public.kontaklar add column if not exists ucret_notu    text;     -- ör. "Reels 15.000 ₺ + story"
alter table public.kontaklar add column if not exists etiketler     text[] not null default '{}';
alter table public.kontaklar add column if not exists sorumlu       text;     -- ekipten ilişkiyi takip eden
alter table public.kontaklar add column if not exists son_temas     date;
alter table public.kontaklar add column if not exists sonraki_temas date;     -- takip hatırlatma
alter table public.kontaklar add column if not exists created_by    uuid references auth.users(id) default auth.uid();
alter table public.kontaklar add column if not exists updated_at    timestamptz not null default now();

drop trigger if exists trg_kontaklar_touch on public.kontaklar;
create trigger trg_kontaklar_touch before update on public.kontaklar
  for each row execute function public.touch_updated_at();

-- 2) Görüşme / iş birliği geçmişi
create table if not exists public.kontak_kayitlari (
  id         uuid primary key default gen_random_uuid(),
  kontak_id  uuid not null references public.kontaklar(id) on delete cascade,
  tarih      date not null default current_date,
  tur        text not null default 'Not',   -- Not | Arama | Mesaj | E-posta | Toplantı | İş birliği | Teklif
  metin      text,
  tutar      numeric,                       -- iş birliği / teklif tutarı (isteğe bağlı)
  yazan      text,
  created_by uuid references auth.users(id) default auth.uid(),
  created_at timestamptz not null default now()
);
create index if not exists kontak_kayit_idx on public.kontak_kayitlari(kontak_id, tarih desc);

-- kayıt eklenince kontağın "son temas" tarihi güncellenir
create or replace function public.kontak_son_temas()
returns trigger language plpgsql security definer as $$
begin
  update public.kontaklar set son_temas = greatest(coalesce(son_temas, new.tarih), new.tarih) where id = new.kontak_id;
  return new;
end $$;
drop trigger if exists trg_kontak_son_temas on public.kontak_kayitlari;
create trigger trg_kontak_son_temas after insert on public.kontak_kayitlari
  for each row execute function public.kontak_son_temas();

-- 3) Güvenlik: giriş yapmış ekip (kontaklar gibi)
alter table public.kontak_kayitlari enable row level security;
drop policy if exists kontak_kayitlari_all on public.kontak_kayitlari;
create policy kontak_kayitlari_all on public.kontak_kayitlari
  for all to authenticated using (true) with check (true);

-- 4) Anlık senkron
do $$
begin
  if not exists (select 1 from pg_publication_tables where pubname='supabase_realtime' and schemaname='public' and tablename='kontak_kayitlari') then
    alter publication supabase_realtime add table public.kontak_kayitlari;
  end if;
end $$;

notify pgrst, 'reload schema';
-- Bitti. Menü → 📇 Rehber.
