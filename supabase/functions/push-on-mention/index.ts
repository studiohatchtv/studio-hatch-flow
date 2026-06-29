// MizarLabs Flow — yorumda @etiketlenince push gönderen Edge Function
// Database Webhook (yorumlar: INSERT) bunu çağırır.
import webpush from "npm:web-push@3.6.7";
import { createClient } from "npm:@supabase/supabase-js@2";

const VAPID_PUBLIC   = Deno.env.get("VAPID_PUBLIC")!;
const VAPID_PRIVATE  = Deno.env.get("VAPID_PRIVATE")!;
const WEBHOOK_SECRET = Deno.env.get("WEBHOOK_SECRET") || "";
const SUPABASE_URL   = Deno.env.get("SUPABASE_URL")!;
const SERVICE_ROLE   = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;

webpush.setVapidDetails("mailto:hello@studiohatch.tv", VAPID_PUBLIC, VAPID_PRIVATE);
const admin = createClient(SUPABASE_URL, SERVICE_ROLE);
const APP_URL = "https://studiohatchtv.github.io/studio-hatch-flow/";

Deno.serve(async (req) => {
  try {
    if (WEBHOOK_SECRET && req.headers.get("x-webhook-secret") !== WEBHOOK_SECRET) {
      return new Response("unauthorized", { status: 401 });
    }
    const body = await req.json();
    const rec = body.record || {};

    // etiketlenenler (yazan hariç)
    const ids = (rec.etiketliler || []).filter((id: string) => id && id !== rec.yazan_id);
    if (ids.length === 0) return new Response("no-op", { status: 200 });

    const { data: subs } = await admin.from("push_subscriptions").select("*").in("user_id", ids);
    if (!subs || subs.length === 0) return new Response("no-subs", { status: 200 });

    const payload = JSON.stringify({
      title: `${rec.yazan || "Biri"} seni bir yorumda etiketledi`,
      body: rec.metin || "",
      url: APP_URL,
    });

    await Promise.all(subs.map(async (s) => {
      try {
        await webpush.sendNotification(
          { endpoint: s.endpoint, keys: { p256dh: s.p256dh, auth: s.auth } },
          payload
        );
      } catch (err) {
        const code = (err && (err as any).statusCode) || 0;
        if (code === 404 || code === 410) {
          await admin.from("push_subscriptions").delete().eq("endpoint", s.endpoint);
        }
      }
    }));

    return new Response("ok", { status: 200 });
  } catch (e) {
    console.error(e);
    return new Response("err: " + (e as Error).message, { status: 200 });
  }
});
