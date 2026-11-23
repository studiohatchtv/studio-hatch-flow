-- ============================================================
-- studio HATCH sitesi — saat düzeltmesi
-- Çalıştır: https://supabase.com/dashboard/project/uolmzykwvizhmycgymfi/sql/new
-- Tekrar çalıştırılabilir. Sonradan Flow → 🌐 Website'tan da düzenlenebilir.
-- ============================================================

-- 1) Frida: son seans 21:00, kapanış 22:00
update public.gosterimler set
  saatler    = $t$Her gün 13:00–22:00 · son seans 21:00$t$,
  saatler_en = $t$Daily 1pm–10pm · last entry 9pm$t$,
  sss    = replace(sss,    $t$Her gün 13:00–22:00 arasında.$t$, $t$Her gün 13:00–22:00 arasında açık; son seans 21:00'de başlar.$t$),
  sss_en = replace(sss_en, $t$Every day, 1pm–10pm.$t$,         $t$Every day, 1pm–10pm; the last session starts at 9pm.$t$)
where baslik = 'Frida Kahlo';

-- 2) Ziyaret kartındaki çalışma saatleri (Hatch Shop 12:00'de açılır)
insert into public.site_ayarlar (anahtar, deger) values
  ('saatler',    $t$Hatch Shop: her gün 12:00'de açılır
Immersive gösterim: her gün 13:00–22:00 · son seans 21:00$t$),
  ('saatler_en', $t$Hatch Shop: opens daily at 12pm
Immersive show: daily 1pm–10pm · last entry 9pm$t$)
on conflict (anahtar) do update set deger = excluded.deger, updated_at = now();

-- Bitti.
