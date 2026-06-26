/* Service Worker — Control de Calidad MIGRIN
   Estrategia network-first: siempre intenta traer la version mas
   reciente; si no hay conexion sirve la copia en cache (la app ya
   maneja la cola de envios pendientes en localStorage). */
const CACHE = 'migrin-calidad-v11';
const PRECACHE = ['./calidad.html', './logo.png', './manifest.json'];

self.addEventListener('install', function (e) {
  e.waitUntil(
    caches.open(CACHE).then(function (c) { return c.addAll(PRECACHE); })
      .then(function () { return self.skipWaiting(); })
  );
});

self.addEventListener('activate', function (e) {
  e.waitUntil(
    caches.keys().then(function (keys) {
      return Promise.all(keys.filter(function (k) { return k !== CACHE; })
        .map(function (k) { return caches.delete(k); }));
    }).then(function () { return self.clients.claim(); })
  );
});

self.addEventListener('fetch', function (e) {
  // Solo GET; las llamadas a Supabase (POST/PATCH) pasan directo
  if (e.request.method !== 'GET') return;
  // No cachear la API de Supabase: datos siempre frescos
  if (e.request.url.indexOf('supabase.co') !== -1) return;
  e.respondWith(
    fetch(e.request).then(function (res) {
      var copy = res.clone();
      caches.open(CACHE).then(function (c) { c.put(e.request, copy); });
      return res;
    }).catch(function () {
      return caches.match(e.request);
    })
  );
});
