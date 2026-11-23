-- ============================================================
-- studio HATCH sitesi — ilk gerçek içerik (Passo'daki aktif etkinlikler)
-- Çalıştır: https://supabase.com/dashboard/project/uolmzykwvizhmycgymfi/sql/new
-- update-website.sql ve update-gosterim.sql çalıştırılmış olmalı. Tekrar çalıştırılabilir (aynı kayıt iki kez eklenmez).
-- Bilgiler Passo sayfalarından alındı (23 Kasım 2026). Sonradan Flow → 🌐 Website'tan düzenlenebilir.
-- ============================================================

-- Gösterimlere "Saatler" alanı (seans yerine açık saat aralığı olan gösterimler için)
alter table public.gosterimler add column if not exists saatler text, add column if not exists saatler_en text;

-- 1) Immersive gösterim: Kökler ve İzler: Frida Kahlo
insert into public.gosterimler (yayinda, one_cikan, sira, baslik, baslik_en, alt_baslik, alt_baslik_en, ozet, ozet_en, aciklama, aciklama_en,
  nedir, nedir_en, ne_degildir, ne_degildir_en, sss, sss_en, saatler, saatler_en, sure_dk, fiyat, fiyat_en, bilet_url)
select true, true, 10, 'Frida Kahlo', 'Frida Kahlo', 'Kökler ve İzler', 'Roots and Traces',
  $t$Frida Kahlo'nun yaşamını, kimliğini ve köklerini dijital sanatla yeniden ele alan, içinde dolaşılan immersive bir deneyim.$t$,
  $t$An immersive experience you walk through, revisiting Frida Kahlo's life, identity and roots through digital art.$t$,
  $t$Frida Kahlo'nun dünyasına, eserlerinden çok daha yakından bakmaya hazır mısın?

“Kökler ve İzler: Frida Kahlo”, sanatçının yaşamı, kimliği, bedeni ve kökleriyle kurduğu ilişkiyi dijital sanatın anlatım olanaklarıyla yeniden ele alan immersive bir deneyim.

studio HATCH'in Culture programının ilk biletli içeriği olan deneyim, Frida'nın izlerini yalnızca izlenen değil, içinde dolaşılan bir anlatıya dönüştürüyor.$t$,
  $t$Ready to look at Frida Kahlo's world far more closely than her paintings allow?

“Roots and Traces: Frida Kahlo” is an immersive experience that revisits the artist's relationship with her life, identity, body and roots through the language of digital art.

The first ticketed experience of studio HATCH's Culture program turns Frida's traces into a story you don't just watch, but walk through.$t$,
  $t$Görüntülerin dört bir yanını sardığı dijital bir deneyim
Frida'nın yaşamını, kimliğini ve köklerini anlatan bir hikâye
İzlediğin değil, içinde dolaştığın bir anlatı$t$,
  $t$A digital experience with images all around you
A story of Frida's life, identity and roots
A story you walk through, not just watch$t$,
  $t$Orijinal tabloların sergilendiği bir müze sergisi değil
Gözlük takılan bir sanal gerçeklik (VR) deneyimi değil$t$,
  $t$Not a museum exhibition of original paintings
Not a virtual reality (VR) experience with a headset$t$,
  $t$Deneyim ne kadar sürüyor?
Yaklaşık 40 dakika.

Hangi saatlerde açık?
Her gün 13:00–22:00 arasında.

Biletleri nereden alabilirim?
Biletler Passo'da satışta. Bu sayfadaki “Passo'dan bilet al” düğmesiyle gün seçebilirsin.$t$,
  $t$How long is the experience?
About 40 minutes.

When is it open?
Every day, 1pm–10pm.

Where can I buy tickets?
Tickets are on sale on Passo. Use the “Get tickets on Passo” button on this page to choose a day.$t$,
  'Her gün 13:00–22:00', 'Daily 1pm–10pm', 40, $t$Passo'da', 'On Passo$t$,
  'https://www.passo.com.tr/tr/etkinlik-grubu/kokler-ve-izler-frida-kahlo-studio-hatch-bursa-bilet-passo/1395613'
where not exists (select 1 from public.gosterimler where baslik = 'Frida Kahlo');

-- Etkinliklere "sitede yayınla" alanlarını yalnızca website yetkisi olan değiştirebilir; bu betik SQL Editor'den çalıştığı için koruma bu ekleme süresince kapatılıp hemen açılır.
alter table public.etkinlikler disable trigger trg_etkinlik_site_koru;

-- 2) Wellness: Immersive Yoga — 28 Kasım 2026, 10:00
insert into public.etkinlikler (baslik, tur, durum, tarih, baslangic_saat, bitis_saat, alan, kisi_sayisi, notlar,
  site_yayinda, site_program, site_baslik_en, site_tur_en, site_ozet, site_ozet_en, site_aciklama, site_aciklama_en, site_bilgiler, site_bilgiler_en,
  site_bilet_url, site_fiyat, site_fiyat_en, site_sure_dk)
select 'Immersive Yoga', 'Wellness', 'Onaylandı', date '2026-11-28', time '10:00', time '11:00', 'Immersive oda', 20, $t$Passo'dan eklendi. Kapasite 20 kişi.$t$,
  true, 'wellness', 'Immersive Yoga', 'Wellness',
  'Yoga pratiğini müzik, ses ve mekânı çevreleyen dijital görsellerle buluşturan çok duyulu bir deneyim.',
  'A multi-sensory yoga practice with music, sound and digital visuals all around the room.',
  $t$Immersive Yoga, yoga pratiğini müzik, ses ve mekânı çevreleyen dijital görsellerle buluşturan çok duyulu bir deneyimdir.

Nefes çalışmalarıyla başlayan seans, her seviyeye uygun yoga akışlarıyla devam eder. Hareketin ritmine eşlik eden müzik ve değişen görsel atmosfer, alışılmışın dışında bir yoga deneyimi sunar.

Pratiğin sonunda bedenin dinlenmesine ve zihnin sakinleşmesine alan açan bir gevşeme bölümü yer alır.$t$,
  $t$Immersive Yoga brings your practice together with music, sound and digital visuals that surround the room.

The session opens with breathwork and continues with yoga flows suitable for all levels, with music and shifting visuals following the rhythm of the movement.

It closes with a relaxation section that lets the body rest and the mind settle.$t$,
  $t$Süre 60 dakika, her seviyeye uygun; yoga deneyimi gerekmez.
Seans başlangıcından en az 20 dakika önce alanda olun.
Kapasite 20 kişi; 16 yaş ve üzeri.
Mat, minder ve tüm ekipman bizden; rahat kıyafet önerilir.
Dijital görseller, değişken ışık ve ses efektleri kullanılır; ışığa duyarlılığı olanlar önceden değerlendirmeli.
Biletler başka bir seansa aktarılamaz.$t$,
  $t$60 minutes, all levels; no yoga experience needed.
Please arrive at least 20 minutes before the session.
Limited to 20 people; ages 16+.
Mats, cushions and all equipment provided; wear comfortable clothes.
Digital visuals, changing light and sound effects are used; please consider this if you are light-sensitive.
Tickets cannot be moved to another session.$t$,
  'https://www.passo.com.tr/tr/etkinlik/immersive-yoga-studio-hatch-wellness-bursa-bilet-passo/13954330',
  '1.500 ₺', '₺1,500', 60
where not exists (select 1 from public.etkinlikler where baslik = 'Immersive Yoga' and tarih = date '2026-11-28');

-- 3) Atölye: Find Your Balance — Handstand (Amut) Deneyimi — 4 Aralık 2026, 19:30
insert into public.etkinlikler (baslik, tur, durum, tarih, baslangic_saat, alan, notlar,
  site_yayinda, site_program, site_baslik_en, site_tur_en, site_ozet, site_ozet_en, site_aciklama, site_aciklama_en, site_bilgiler, site_bilgiler_en,
  site_bilet_url, site_fiyat, site_fiyat_en)
select 'Find Your Balance – Handstand (Amut) Deneyimi', 'Atölye', 'Onaylandı', date '2026-12-04', time '19:30', 'Immersive oda', $t$Passo'dan eklendi. Eğitmen: Veysel Eldek.$t$,
  true, 'nocturne', 'Find Your Balance – Handstand Workshop', 'Workshop',
  'Handstand (amut) pratiğini denge, güç ve beden farkındalığıyla buluşturan, immersive atmosferde bir deneyim atölyesi.',
  'A handstand workshop on balance, strength and body awareness, inside the immersive room.',
  $t$Bedeninin sınırlarını keşfetmeye, yerçekimine farklı bir açıdan bakmaya ve dengenin gücünü hissetmeye hazır mısın?

Find Your Balance, handstand (amut) pratiğini hareket, denge, güç ve beden farkındalığıyla buluşturan özel bir deneyim atölyesi. studio HATCH'in dijital görsellerle çevrili immersive atmosferinde bedenimizi tanıyacak, omuz ve merkez bölge kuvvetimizi geliştirecek, denge becerilerimizi keşfedecek ve amutun temel tekniklerini adım adım deneyimleyeceğiz.

Atölyede: bilek, omuz ve eklem hazırlığı; core aktivasyonu; denge ve koordinasyon çalışmaları; handstand temel teknikleri; eşli ve destekli amut çalışmaları; esneklik ve beden farkındalığı.

Biraz cesaret, biraz güç ve bolca keşif… Çünkü bazen dengeni bulmak için dünyaya başka bir açıdan bakman gerekir.$t$,
  $t$Ready to explore your body's limits, see gravity from a new angle and feel the power of balance?

Find Your Balance is a workshop that brings handstand practice together with movement, balance, strength and body awareness. Inside studio HATCH's immersive room, surrounded by digital visuals, we'll build shoulder and core strength, explore balance and learn the basics of the handstand step by step.

Includes: wrist, shoulder and joint prep; core activation; balance and coordination drills; handstand fundamentals; partner and assisted handstands; flexibility and body awareness.$t$,
  $t$Her seviyeye uygun; daha önce amut deneyimi gerekmez.
Veysel Eldek rehberliğinde.
Başlangıçtan en az 20 dakika önce alanda olun.
Kıyafet kuralı: tamamen siyah, rahat spor kıyafeti.
Hareketi kısıtlayan bir sağlık durumunuz varsa eğitmeni önceden bilgilendirin.$t$,
  $t$All levels; no handstand experience needed.
Led by Veysel Eldek.
Please arrive at least 20 minutes early.
Dress code: all-black, comfortable sportswear.
If you have a health condition that limits movement, please tell the instructor beforehand.$t$,
  'https://www.passo.com.tr/tr/etkinlik/find-your-balance-handstand-deneyimi-atolyesi-studio-hatch-bursa-bilet-passo/14202319',
  '1.500 ₺', '₺1,500'
where not exists (select 1 from public.etkinlikler where baslik like 'Find Your Balance%' and tarih = date '2026-12-04');

alter table public.etkinlikler enable trigger trg_etkinlik_site_koru;

notify pgrst, 'reload schema';
-- Bitti. Kontrol: Flow → 🌐 Website → Gösterimler / Etkinlikler
