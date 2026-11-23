-- studio HATCH sitesi — SSS'ye gişe bilgisi
-- Çalıştır: https://supabase.com/dashboard/project/uolmzykwvizhmycgymfi/sql/new  · Tekrar çalıştırılabilir.
-- Sonradan Flow → 🌐 Website → Site bilgileri → "Genel SSS" alanından düzenlenebilir.

-- 1) Genel SSS (tüm gösterim sayfalarının altında görünür): bilet sorusu en başa
insert into public.site_ayarlar (anahtar, deger) values
  ('genel_sss',    $t$Biletleri nereden alabilirim?
Passo uygulaması ve passo.com.tr’nin yanı sıra studio HATCH’teki gişeden de alabilirsiniz.

studio HATCH nerede?
High Garden AVM, Newline Konutları, Farabi Cd. E Blok No: 12-E, 16140 Nilüfer/Bursa.$t$),
  ('genel_sss_en', $t$Where can I buy tickets?
On the Passo app and passo.com.tr, and also at the box office at studio HATCH.

Where is studio HATCH?
High Garden AVM, Newline Konutları, Farabi Cd. E Blok No: 12-E, 16140 Nilüfer/Bursa.$t$)
on conflict (anahtar) do update
  set deger = case
      when coalesce(trim(site_ayarlar.deger),'') = '' then excluded.deger
      when site_ayarlar.deger ilike '%gişe%' or site_ayarlar.deger ilike '%box office%' then site_ayarlar.deger
      else split_part(excluded.deger, E'\n\n', 1) || E'\n\n' || site_ayarlar.deger end,
      updated_at = now();

-- 2) Frida'nın kendi SSS'sindeki bilet cevabı
update public.gosterimler set
  sss    = replace(sss,    $t$Biletler Passo'da satışta.$t$, $t$Biletler Passo uygulaması ve passo.com.tr’de satışta; studio HATCH’teki gişeden de alabilirsin.$t$),
  sss_en = replace(sss_en, $t$Tickets are on sale on Passo.$t$, $t$Tickets are on sale on the Passo app and passo.com.tr, and also at the box office at studio HATCH.$t$)
where baslik = 'Frida Kahlo';
-- Bitti.
