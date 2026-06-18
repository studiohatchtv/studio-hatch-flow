-- ============================================================
-- studioHATCH Flow — güncelleme (2026-06-18)
-- Supabase > SQL Editor > New query > yapıştır > Run
-- ============================================================

-- 1) İŞLER tablosuna "açıklama" alanı ekle
alter table public.isler add column if not exists aciklama text;

-- 2) Zaten giriş yapmış üyeleri Kişiler'e aktar (bir kerelik).
--    Tetikleyici sadece YENİ üyede çalıştığı için, daha önce
--    giriş yapanlar (sen dahil) bu komutla eklenir.
insert into public.kisiler (user_id, ad, email)
select u.id,
       coalesce(
         u.raw_user_meta_data->>'full_name',
         u.raw_user_meta_data->>'name',
         split_part(u.email, '@', 1)
       ),
       u.email
from auth.users u
where not exists (select 1 from public.kisiler k where k.user_id = u.id);

-- Bitti. Sayfayı yenile → adın Kişiler'de görünür, kartlarda Açıklama alanı çıkar.
