-- ============================================================
-- studioHATCH projesini + iş kollarını yeniden oluştur
-- (yanlışlıkla silindiyse). İşler geri gelmez; yedek varsa onu kullan.
-- https://supabase.com/dashboard/project/uolmzykwvizhmycgymfi/sql/new
-- ============================================================
do $$
declare pid uuid;
begin
  if not exists (select 1 from public.projeler where ad = 'studioHATCH') then
    insert into public.projeler (ad, sira) values ('studioHATCH', 0) returning id into pid;
    insert into public.is_kollari (proje_id, ad, renk, sira) values
      (pid,'Immersive','blue',1),(pid,'Dijital Art','pink',2),(pid,'hatch Shop','teal',3),
      (pid,'İnşaat','coral',4),(pid,'Sponsorluk','purple',5),(pid,'Dijital İşler','amber',6);
  end if;
end $$;
notify pgrst, 'reload schema';
