-- studio HATCH — HATCH UP · creative pop-up market · vol-01 yılbaşı edition · 20 Aralık 2026 Pazar
-- Çalıştır: https://supabase.com/dashboard/project/uolmzykwvizhmycgymfi/sql/new · Tekrar çalıştırılabilir.
-- Saatler geçici (12:00–22:00); netleşince Flow → 🌐 Website'tan düzenlenir.
alter table public.etkinlikler disable trigger trg_etkinlik_site_koru;
insert into public.etkinlikler (baslik, tur, durum, tarih, baslangic_saat, bitis_saat, alan, notlar,
  site_yayinda, site_one_cikan, site_program, site_baslik_en, site_tur_en, site_ozet, site_ozet_en, site_aciklama, site_aciklama_en, site_bilgiler, site_bilgiler_en,
  site_gorsel, site_galeri)
select 'HATCH UP · Yılbaşı Edition', 'Topluluk buluşması', 'Onaylandı', date '2026-12-20', time '12:00', time '22:00', 'Immersive oda + HATCH Shop',
  $t$vol-01 yılbaşı edition. Üretici başvuruları 1 Aralık 23:59'a kadar (studiohatch.tv/hatch-up.html), sonuçlar 3 Aralık. Saatler geçici.$t$,
  true, false, 'nocturne', 'HATCH UP · New Year Edition', 'Pop-up market',
  'Bağımsız tasarımcı, sanatçı ve üreticilerin buluştuğu yılbaşı temalı creative pop-up market: Immersive oda + tasarım marketi.',
  'A New Year creative pop-up market of independent designers, artists and makers: the immersive room plus a design market.',
  $t$HATCH UP, studio HATCH'in creative pop-up market'i. İlk buluşma vol-01 "yılbaşı edition" 20 Aralık Pazar günü.

Bağımsız tasarımcılar, sanatçılar ve yaratıcı üreticiler immersive odada ve tasarım marketinde stant açıyor: el yapımı ürünler, tasarım objeler, yılbaşı hediyelikleri, atölyeler ve yeme-içme köşeleri. Dijital görsellerle çevrili immersive odada alışveriş yapabilir, atölyelere katılabilir ve üreticilerle tanışabilirsin.

Üretiyor, tasarlıyor ve paylaşmayı seviyorsan HATCH UP'ta buluşalım: üretici başvuruları sitemizdeki formdan yapılıyor.$t$,
  $t$HATCH UP is studio HATCH's creative pop-up market. The first edition, vol-01 "New Year edition", takes place on Sunday 20 December.

Independent designers, artists and makers set up stands in the immersive room and the design market: handmade goods, design objects, New Year gifts, workshops and food corners. Shop surrounded by digital visuals, join a workshop and meet the makers.

If you make, design and love to share, join us at HATCH UP: maker applications are open via the form on our website.$t$,
  $t$Ziyaretçi girişi ücretsizdir.
Yer: studio HATCH — Immersive oda + HATCH Shop.
Saatler ve katılımcı listesi yakında duyurulacak.
Üretici misin? Başvuru formu: studiohatch.tv/hatch-up.html — son başvuru 1 Aralık 23:59.$t$,
  $t$Free entry for visitors.
Venue: studio HATCH — immersive room + HATCH Shop.
Hours and maker list to be announced soon.
Are you a maker? Apply at studiohatch.tv/hatch-up.html — deadline 1 December, 11:59 pm.$t$,
  'assets/etkinlik/hatch-up.jpg', array['assets/etkinlik/hatch-up-2.jpg']
where not exists (select 1 from public.etkinlikler where baslik like 'HATCH UP%' and tarih = date '2026-12-20');
alter table public.etkinlikler enable trigger trg_etkinlik_site_koru;
-- Bitti.
