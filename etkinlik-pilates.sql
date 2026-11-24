-- studio HATCH — Immersive Pilates · 13 Aralık 2026 Pazar 11:00 (Passo'dan)
-- Çalıştır: https://supabase.com/dashboard/project/uolmzykwvizhmycgymfi/sql/new · Tekrar çalıştırılabilir.
alter table public.etkinlikler disable trigger trg_etkinlik_site_koru;
insert into public.etkinlikler (baslik, tur, durum, tarih, baslangic_saat, alan, kisi_sayisi, notlar,
  site_yayinda, site_program, site_baslik_en, site_tur_en, site_ozet, site_ozet_en, site_aciklama, site_aciklama_en, site_bilgiler, site_bilgiler_en,
  site_bilet_url, site_fiyat, site_fiyat_en)
select 'Immersive Pilates', 'Wellness', 'Onaylandı', date '2026-12-13', time '11:00', 'Immersive oda', 25, $t$Passo'dan eklendi. Eğitmen: Tuğçe Yaraşır. Kapasite 25 kişi.$t$,
  true, 'wellness', 'Immersive Pilates', 'Wellness',
  'Pilates, müzik ve dijital sanatın buluştuğu yeni nesil bir hareket deneyimi.',
  'A new kind of movement experience where Pilates meets music and digital art.',
  $t$Pilates, müzik ve dijital sanatın buluştuğu yeni nesil bir hareket deneyimi.

Pilates eğitmeni Tuğçe Yaraşır eşliğinde, studio HATCH'in immersive dünyasında ışık, ses ve görsellerle bedeninle bağlantı kur, güçlen ve hareketin ritmini keşfet.

Klasik bir pilates dersinden fazlası: hareketin içinde, bambaşka bir deneyim.$t$,
  $t$A new kind of movement experience where Pilates meets music and digital art.

Led by Pilates instructor Tuğçe Yaraşır inside studio HATCH's immersive room, connect with your body through light, sound and visuals, build strength and find the rhythm of movement.

More than a classic Pilates class: a whole different experience from inside the movement.$t$,
  $t$Tuğçe Yaraşır eşliğinde.
Kapasite 25 kişi; 16 yaş ve üzeri.
Kıyafet kuralı: tamamen siyah spor kıyafeti.
Başlangıçtan 15 dakika önce alanda olun.
Matlar studio HATCH'ten; dileyen kendi matını getirebilir.
Farklı seviyelere uygun hareket alternatifleri sunulur.
Aktif sakatlık, kronik rahatsızlık, hamilelik veya egzersize engel bir sağlık durumunuz varsa önceden doktorunuza danışın ve eğitmeni bilgilendirin.$t$,
  $t$Led by Tuğçe Yaraşır.
Limited to 25 people; ages 16+.
Dress code: all-black sportswear.
Please arrive 15 minutes early.
Mats provided by studio HATCH; feel free to bring your own.
Movement options for different levels are offered.
If you have an injury, chronic condition, are pregnant or have any health condition that may affect exercise, consult your doctor and tell the instructor beforehand.$t$,
  'https://www.passo.com.tr/tr/etkinlik/immersive-pilates-studio-hatch-bursa-bilet-passo/14252319',
  '1.500 ₺', '₺1,500'
where not exists (select 1 from public.etkinlikler where baslik = 'Immersive Pilates' and tarih = date '2026-12-13');
alter table public.etkinlikler enable trigger trg_etkinlik_site_koru;
-- Bitti. Görsel/video: Flow → 🌐 Website → Immersive Pilates
