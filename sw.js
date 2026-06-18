// studioHATCH Flow — service worker (web push)
self.addEventListener("push", function(event){
  let data = {};
  try { data = event.data ? event.data.json() : {}; }
  catch(e){ data = { title: "studioHATCH Flow", body: event.data ? event.data.text() : "" }; }
  const title = data.title || "studioHATCH Flow";
  const options = {
    body: data.body || "",
    icon: "icon-192.png",
    badge: "icon-192.png",
    data: { url: data.url || "./" },
    tag: data.tag || undefined,
  };
  event.waitUntil(self.registration.showNotification(title, options));
});

self.addEventListener("notificationclick", function(event){
  event.notification.close();
  const url = (event.notification.data && event.notification.data.url) || "./";
  event.waitUntil(
    clients.matchAll({ type: "window", includeUncontrolled: true }).then(function(list){
      for (const c of list){ if ("focus" in c) { c.navigate(url); return c.focus(); } }
      if (clients.openWindow) return clients.openWindow(url);
    })
  );
});
