-- ============================================================
-- studio HATCH sitesi — Dijital Galeri (ücretsiz eserler)
-- Çalıştır: https://supabase.com/dashboard/project/uolmzykwvizhmycgymfi/sql/new
-- Tekrar çalıştırılabilir (aynı eser iki kez eklenmez).
-- ============================================================

-- 1) Gösterimlere tür + eser alanları
alter table public.gosterimler
  add column if not exists kategori text not null default 'immersive',
  add column if not exists sanatci text,
  add column if not exists sanatci_url text,
  add column if not exists konum text,
  add column if not exists konum_en text,
  add column if not exists teknik text,
  add column if not exists teknik_en text;
alter table public.gosterimler drop constraint if exists gosterimler_kategori_chk;
alter table public.gosterimler add constraint gosterimler_kategori_chk check (kategori in ('immersive','galeri'));

-- 2) KIVIL — Can Memişoğulları (giriş fuayesi)
insert into public.gosterimler (yayinda, one_cikan, sira, kategori, baslik, baslik_en, sanatci, sanatci_url, konum, konum_en, teknik, teknik_en,
  ozet, ozet_en, aciklama, aciklama_en, saatler, saatler_en, gorsel, galeri)
select true, false, 100, 'galeri', 'KIVIL', 'KIVIL', 'Can Memişoğulları', 'https://www.canmemisogullari.com/projects/kivil.html',
  'Giriş fuayesi · Dijital sanat alanı', 'Entrance foyer · Digital art area',
  'Görsel-işitsel yerleştirme · Tek kanal görsel, iki kanal ses, özel yazılım · 2024',
  'Audiovisual installation · Single-channel video, two-channel sound, custom software · 2024',
  $t$Bizi sınırlandıran görünmez bağları sorgulayan ve onları aşmaya davet eden görsel-işitsel bir yerleştirme.$t$,
  $t$An audiovisual installation on the invisible bonds that hold us back, and an invitation to break free from them.$t$,
  $t$"Kıvıl," hayatımız boyunca bizi sınırlandıran görünmez bağların, bireyin kendi potansiyelini keşfetmesinin önündeki en büyük engellerden biri olduğunu sorgulayan ve bu engelleri aşma sürecine davet eden bir eseridir.

Başarısızlıklar, karşılanamayacak olan beklentiler, ekonomik baskılar ve geleceğe dair belirsizliklerin ördüğü zincirler, bireyin kımıldamasını engelleyen ve içine hapseden görünmez bağlardır; ancak bu bağların ötesine geçebilmek için bireyin kendi gücünü fark etmesi ve bu gerçeklerle yüzleşmesi gerekir.$t$,
  $t$“Kıvıl” is a work that reflects on the invisible bonds that shape and constrain our lives, those subtle yet powerful forces that stand as some of the greatest obstacles to realizing one’s potential while inviting us into the process of breaking free from them.

Failures, unfulfilled expectations, economic pressures, and the uncertainties of the future weave chains that immobilize the individual and enclose them within. Yet moving beyond these bonds requires a recognition of one’s own strength and the courage to confront these realities.$t$,
  'Her gün 12:00–22:00', 'Daily 12pm–10pm',
  'assets/galeri/kivil.jpg', array['assets/galeri/kivil-2.jpg']
where not exists (select 1 from public.gosterimler where baslik = 'KIVIL' and kategori = 'galeri');

-- 3) Çininin Nefesi — studio HATCH (HATCH Shop)
insert into public.gosterimler (yayinda, one_cikan, sira, kategori, baslik, baslik_en, alt_baslik, alt_baslik_en, sanatci, konum, konum_en, teknik, teknik_en,
  ozet, ozet_en, aciklama, aciklama_en, saatler, saatler_en, gorsel, video, galeri)
select true, false, 110, 'galeri', 'Çininin Nefesi', 'The Breath of Tile', 'İznik üslubunun beş yüzyılı', 'Five centuries of the Iznik style', 'studio HATCH',
  'HATCH Shop', 'HATCH Shop',
  'Dijital animasyon · LED ekran · yaklaşık 6 dakikalık döngü',
  'Digital animation · LED screen · approx. 6-minute loop',
  $t$İznik çinisinin beş yüzyıllık motif dilini, nefes alıp veren dijital desenlere dönüştüren bir animasyon.$t$,
  $t$An animation that turns five centuries of Iznik tile motifs into patterns that breathe.$t$,
  $t$Çininin Nefesi, İznik çinisinin yüzyıllar içinde değişen üslubunu tek bir akışta anlatıyor. Her bölüm bir motifi ya da dönemi ele alıyor ve onu ekranda yavaşça açılıp kapanan, nefes alan bir desene dönüştürüyor.

Baba Nakkaş'ın kıvrımlarından Saz Yolu'nun uzun yapraklarına, Hatayi ve Penç'ten Balık Pulu'na, Şam İşi'nin morlarından Kalyon'a, Hayat Ağacı'ndan Rumi ve Şemse'ye uzanan yolculuk, HATCH Shop'taki LED ekranda sürekli döngüde oynuyor.$t$,
  $t$The Breath of Tile tells the changing style of Iznik tiles over the centuries in a single flow. Each chapter takes a motif or a period and turns it into a pattern that slowly opens, closes and breathes on screen.

From the curls of Baba Nakkaş and the long leaves of Saz Yolu, through Hatayi, Penç and Balık Pulu, the purples of Şam İşi and the Galleon, to the Tree of Life, Rumi and Şemse, the journey plays on a continuous loop on the LED screen in HATCH Shop.$t$,
  'Her gün 12:00–22:00', 'Daily 12pm–10pm',
  'assets/galeri/cininin-nefesi.jpg', 'assets/video/cininin-nefesi.mp4',
  array['assets/galeri/cini-01.jpg','assets/galeri/cini-02.jpg','assets/galeri/cini-03.jpg','assets/galeri/cini-04.jpg','assets/galeri/cini-05.jpg',
        'assets/galeri/cini-06.jpg','assets/galeri/cini-07.jpg','assets/galeri/cini-08.jpg','assets/galeri/cini-09.jpg','assets/galeri/cini-10.jpg']
where not exists (select 1 from public.gosterimler where baslik = 'Çininin Nefesi' and kategori = 'galeri');

notify pgrst, 'reload schema';
-- Bitti. Flow → 🌐 Website → Gösterimler'de "🎨 Dijital Galeri" etiketiyle görünür.
