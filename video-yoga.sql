-- studio HATCH sitesi — Immersive Yoga (28 Kasım) tanıtım videosu
-- Çalıştır: https://supabase.com/dashboard/project/uolmzykwvizhmycgymfi/sql/new  · Tekrar çalıştırılabilir.
alter table public.etkinlikler disable trigger trg_etkinlik_site_koru;
update public.etkinlikler set site_video = 'assets/video/immersive-yoga.mp4'
 where id = 'd5669b81-be23-4205-abcf-03f979bbbfd1';
alter table public.etkinlikler enable trigger trg_etkinlik_site_koru;
-- Bitti.
