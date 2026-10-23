const CACHE_NAME = "thai-glass-inventory-v5";
const FILES = ["./", "./index.html", "./manifest.json"];
self.addEventListener("install", event => {
  event.waitUntil(caches.open(CACHE_NAME).then(cache => cache.addAll(FILES)));
  self.skipWaiting();
});
self.addEventListener("activate", event => event.waitUntil((async () => {
  const keys = await caches.keys();
  await Promise.all(keys.filter(k => k.startsWith("thai-glass-inventory-") && k !== CACHE_NAME).map(k => caches.delete(k)));
  await self.clients.claim();
})()));
self.addEventListener("fetch", event => {
  const req = event.request;
  if (req.method !== "GET") return;
  const url = new URL(req.url);
  // Do not intercept Supabase/API requests or third-party libraries.
  if (url.origin !== self.location.origin) return;
  event.respondWith((async () => {
    const cached = await caches.match(req);
    if (cached) return cached;
    try {
      const response = await fetch(req);
      if (response.ok && (url.pathname.endsWith(".html") || url.pathname.endsWith(".js") || url.pathname.endsWith(".json") || url.pathname.endsWith("/"))) {
        const cache = await caches.open(CACHE_NAME);
        cache.put(req, response.clone());
      }
      return response;
    } catch (err) {
      if (req.mode === "navigate") return (await caches.match("./index.html")) || Response.error();
      return Response.error();
    }
  })());
});
