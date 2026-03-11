const CACHE_NAME = 'testflutter-v1';
const OFFLINE_URL = '/';

// Files to cache immediately on install
const PRECACHE_URLS = [
  '/',
  '/index.html',
  '/manifest.json',
  '/favicon.png',
  '/icons/Icon-192.png',
  '/icons/Icon-512.png',
];

// Install event - cache essential files
self.addEventListener('install', event => {
  console.log('[ServiceWorker] Installing...');
  event.waitUntil(
    caches.open(CACHE_NAME).then(cache => {
      console.log('[ServiceWorker] Caching essential files');
      return cache.addAll(PRECACHE_URLS).catch(err => {
        console.warn('[ServiceWorker] Cache addAll failed:', err);
        // Continue anyway - network will be used
      });
    }).then(() => self.skipWaiting())
  );
});

// Activate event - clean up old caches
self.addEventListener('activate', event => {
  console.log('[ServiceWorker] Activating...');
  event.waitUntil(
    caches.keys().then(cacheNames => {
      return Promise.all(
        cacheNames.map(cacheName => {
          if (cacheName !== CACHE_NAME) {
            console.log('[ServiceWorker] Deleting old cache:', cacheName);
            return caches.delete(cacheName);
          }
        })
      );
    }).then(() => self.clients.claim())
  );
});

// Fetch event - serve from cache, fallback to network
self.addEventListener('fetch', event => {
  const { request } = event;
  const url = new URL(request.url);

  // Skip non-GET requests
  if (request.method !== 'GET') {
    return;
  }

  // Skip cross-origin requests
  if (url.origin !== location.origin) {
    console.log('[ServiceWorker] Skipping cross-origin:', url.href);
    return;
  }

  // Network-first for HTML/JS (for development convenience)
  if (request.destination === 'document' || request.destination === 'script') {
    event.respondWith(
      fetch(request)
        .then(response => {
          // Cache successful responses
          if (response && response.status === 200) {
            const clonedResponse = response.clone();
            caches.open(CACHE_NAME).then(cache => {
              cache.put(request, clonedResponse);
            });
          }
          return response;
        })
        .catch(() => {
          // Fallback to cache if network unavailable
          return caches.match(request).then(cachedResponse => {
            if (cachedResponse) {
              console.log('[ServiceWorker] Serving from cache:', request.url);
              return cachedResponse;
            }
            console.warn('[ServiceWorker] No cache for:', request.url);
            return new Response('Offline - resource not available', {
              status: 503,
              statusText: 'Service Unavailable',
            });
          });
        })
    );
    return;
  }

  // Cache-first for assets (images, fonts, etc.)
  event.respondWith(
    caches.match(request)
      .then(cachedResponse => {
        if (cachedResponse) {
          console.log('[ServiceWorker] Serving from cache:', request.url);
          return cachedResponse;
        }

        return fetch(request)
          .then(response => {
            // Cache successful responses
            if (response && response.status === 200) {
              const clonedResponse = response.clone();
              caches.open(CACHE_NAME).then(cache => {
                cache.put(request, clonedResponse);
              });
            }
            return response;
          })
          .catch(err => {
            console.warn('[ServiceWorker] Fetch failed for:', request.url, err);
            // Return offline placeholder
            return new Response('Offline - resource not cached', {
              status: 503,
              statusText: 'Service Unavailable',
            });
          });
      })
  );
});

console.log('[ServiceWorker] Loaded');
