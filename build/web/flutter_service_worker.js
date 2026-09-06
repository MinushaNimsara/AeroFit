'use strict';
const MANIFEST = 'flutter-app-manifest';
const TEMP = 'flutter-temp-cache';
const CACHE_NAME = 'flutter-app-cache';

const RESOURCES = {"assets/AssetManifest.bin": "ba26786cb05bfd147d6202659599296e",
"assets/AssetManifest.bin.json": "2600a91bba6400c50e0de0d91042a0d7",
"assets/AssetManifest.json": "2610027e3ee444576cbccf8b888a0a88",
"assets/assets/AssetManifest.bin": "ba26786cb05bfd147d6202659599296e",
"assets/assets/AssetManifest.bin.json": "2600a91bba6400c50e0de0d91042a0d7",
"assets/assets/data/exercises/athletic_performance.json": "c1922d140f74385e06bdc2af7b9e7b24",
"assets/assets/data/exercises/back.json": "4d7e3bf147e7a6a179501deb6854fe69",
"assets/assets/data/exercises/biceps.json": "a4e276f75a00725ff913c6b1f0955109",
"assets/assets/data/exercises/calisthenics.json": "8f86d97479ee24fe6349d7d0e27489e0",
"assets/assets/data/exercises/cardio.json": "dbf7454fc9bf4e1139ecf8e4414142be",
"assets/assets/data/exercises/chest.json": "d54dee635bf125f5bcbaf727a249ba4b",
"assets/assets/data/exercises/core.json": "57681fa3f27557e583949f551babec80",
"assets/assets/data/exercises/forearms.json": "55978a514427fe2d26d18a767c53a9e2",
"assets/assets/data/exercises/full_body.json": "3a04f7673b635c0e5e1690d4688ad3ae",
"assets/assets/data/exercises/legs.json": "dbfa999c6c3d602d8043cb24a366aabe",
"assets/assets/data/exercises/mobility.json": "4cc895e8c11b43fbeb3d10d9c2a5bac9",
"assets/assets/data/exercises/shoulders.json": "db47eab9513c4acf60c81c7f3b3d115e",
"assets/assets/data/exercises/triceps.json": "50ead59bf681f70a61a6819ad2b3686d",
"assets/assets/FontManifest.json": "dc3d03800ccca4601324923c0b1d6d57",
"assets/assets/fonts/MaterialIcons-Regular.otf": "af5e9ee971e46d06a9fb1b4726dc5b27",
"assets/assets/images/app_icon_source.png": "719a95e14e18756ee4bf6f3a101f5062",
"assets/assets/NOTICES": "7a96b59787557c5747a3724bccbeb1c4",
"assets/assets/packages/cupertino_icons/assets/CupertinoIcons.ttf": "33b7d9392238c04c131b6ce224e13711",
"assets/assets/shaders/ink_sparkle.frag": "ecc85a2e95f5e9f53123dcaf8cb9b6ce",
"assets/assets/shaders/stretch_effect.frag": "40d68efbbf360632f614c731219e95f0",
"assets/FontManifest.json": "dc3d03800ccca4601324923c0b1d6d57",
"assets/fonts/MaterialIcons-Regular.otf": "af5e9ee971e46d06a9fb1b4726dc5b27",
"assets/NOTICES": "9781d59e4baf83597b66042d19b8e4f1",
"assets/packages/cupertino_icons/assets/CupertinoIcons.ttf": "33b7d9392238c04c131b6ce224e13711",
"assets/shaders/ink_sparkle.frag": "9bb2aaa0f9a9213b623947fa682efa76",
"assets/shaders/stretch_effect.frag": "a70217f9ceba606e287441a0df5be64d",
"canvaskit/canvaskit.js": "140ccb7d34d0a55065fbd422b843add6",
"canvaskit/canvaskit.js.symbols": "58832fbed59e00d2190aa295c4d70360",
"canvaskit/canvaskit.wasm": "07b9f5853202304d3b0749d9306573cc",
"canvaskit/chromium/canvaskit.js": "5e27aae346eee469027c80af0751d53d",
"canvaskit/chromium/canvaskit.js.symbols": "193deaca1a1424049326d4a91ad1d88d",
"canvaskit/chromium/canvaskit.wasm": "24c77e750a7fa6d474198905249ff506",
"canvaskit/skwasm.js": "1ef3ea3a0fec4569e5d531da25f34095",
"canvaskit/skwasm.js.symbols": "0088242d10d7e7d6d2649d1fe1bda7c1",
"canvaskit/skwasm.wasm": "264db41426307cfc7fa44b95a7772109",
"canvaskit/skwasm_heavy.js": "413f5b2b2d9345f37de148e2544f584f",
"canvaskit/skwasm_heavy.js.symbols": "3c01ec03b5de6d62c34e17014d1decd3",
"canvaskit/skwasm_heavy.wasm": "8034ad26ba2485dab2fd49bdd786837b",
"favicon.png": "782ece93b21763dfb2c555fa96d50a3d",
"flutter.js": "1c7e59be1cc906f8d37361ad32ed7e52",
"flutter_bootstrap.js": "c5326260c814e964fa08d3f7323f4cd3",
"flutter_bootstrap_v2.js": "8ee57be3f3a884cbe906fe0bf8855c5b",
"icons/Icon-192.png": "0aa4e06056397d9aafbca4dc9992c412",
"icons/Icon-512.png": "946a0f460c1e01544c36508d7f3d155b",
"icons/Icon-maskable-192.png": "2c85187ac6e34443cfcb43e1f09e5bf3",
"icons/Icon-maskable-512.png": "371798a4ad8ed621298fb528fca40bbb",
"index.html": "628fa1e59f5a10ad091e16c98c9f5adc",
"/": "628fa1e59f5a10ad091e16c98c9f5adc",
"main.dart.js": "2e9c5fe0614b9b5c90587138619f37f9",
"main_v2.dart.js": "5c0747c4ad3a3436b833c3500a3363a2",
"manifest.json": "98eb2b02c9442dba32f2714eb974e018",
"vercel.json": "4eb013c1002528f07646b69c943d7eb1",
"version.json": "d981daa79ebc08e5603b1f1acab8ef88"};
// The application shell files that are downloaded before a service worker can
// start.
const CORE = ["main.dart.js",
"index.html",
"flutter_bootstrap.js",
"assets/AssetManifest.bin.json",
"assets/FontManifest.json"];

// During install, the TEMP cache is populated with the application shell files.
self.addEventListener("install", (event) => {
  self.skipWaiting();
  return event.waitUntil(
    caches.open(TEMP).then((cache) => {
      return cache.addAll(
        CORE.map((value) => new Request(value, {'cache': 'reload'})));
    })
  );
});
// During activate, the cache is populated with the temp files downloaded in
// install. If this service worker is upgrading from one with a saved
// MANIFEST, then use this to retain unchanged resource files.
self.addEventListener("activate", function(event) {
  return event.waitUntil(async function() {
    try {
      var contentCache = await caches.open(CACHE_NAME);
      var tempCache = await caches.open(TEMP);
      var manifestCache = await caches.open(MANIFEST);
      var manifest = await manifestCache.match('manifest');
      // When there is no prior manifest, clear the entire cache.
      if (!manifest) {
        await caches.delete(CACHE_NAME);
        contentCache = await caches.open(CACHE_NAME);
        for (var request of await tempCache.keys()) {
          var response = await tempCache.match(request);
          await contentCache.put(request, response);
        }
        await caches.delete(TEMP);
        // Save the manifest to make future upgrades efficient.
        await manifestCache.put('manifest', new Response(JSON.stringify(RESOURCES)));
        // Claim client to enable caching on first launch
        self.clients.claim();
        return;
      }
      var oldManifest = await manifest.json();
      var origin = self.location.origin;
      for (var request of await contentCache.keys()) {
        var key = request.url.substring(origin.length + 1);
        if (key == "") {
          key = "/";
        }
        // If a resource from the old manifest is not in the new cache, or if
        // the MD5 sum has changed, delete it. Otherwise the resource is left
        // in the cache and can be reused by the new service worker.
        if (!RESOURCES[key] || RESOURCES[key] != oldManifest[key]) {
          await contentCache.delete(request);
        }
      }
      // Populate the cache with the app shell TEMP files, potentially overwriting
      // cache files preserved above.
      for (var request of await tempCache.keys()) {
        var response = await tempCache.match(request);
        await contentCache.put(request, response);
      }
      await caches.delete(TEMP);
      // Save the manifest to make future upgrades efficient.
      await manifestCache.put('manifest', new Response(JSON.stringify(RESOURCES)));
      // Claim client to enable caching on first launch
      self.clients.claim();
      return;
    } catch (err) {
      // On an unhandled exception the state of the cache cannot be guaranteed.
      console.error('Failed to upgrade service worker: ' + err);
      await caches.delete(CACHE_NAME);
      await caches.delete(TEMP);
      await caches.delete(MANIFEST);
    }
  }());
});
// The fetch handler redirects requests for RESOURCE files to the service
// worker cache.
self.addEventListener("fetch", (event) => {
  if (event.request.method !== 'GET') {
    return;
  }
  var origin = self.location.origin;
  var key = event.request.url.substring(origin.length + 1);
  // Redirect URLs to the index.html
  if (key.indexOf('?v=') != -1) {
    key = key.split('?v=')[0];
  }
  if (event.request.url == origin || event.request.url.startsWith(origin + '/#') || key == '') {
    key = '/';
  }
  // If the URL is not the RESOURCE list then return to signal that the
  // browser should take over.
  if (!RESOURCES[key]) {
    return;
  }
  // If the URL is the index.html, perform an online-first request.
  if (key == '/') {
    return onlineFirst(event);
  }
  event.respondWith(caches.open(CACHE_NAME)
    .then((cache) =>  {
      return cache.match(event.request).then((response) => {
        // Either respond with the cached resource, or perform a fetch and
        // lazily populate the cache only if the resource was successfully fetched.
        return response || fetch(event.request).then((response) => {
          if (response && Boolean(response.ok)) {
            cache.put(event.request, response.clone());
          }
          return response;
        });
      })
    })
  );
});
self.addEventListener('message', (event) => {
  // SkipWaiting can be used to immediately activate a waiting service worker.
  // This will also require a page refresh triggered by the main worker.
  if (event.data === 'skipWaiting') {
    self.skipWaiting();
    return;
  }
  if (event.data === 'downloadOffline') {
    downloadOffline();
    return;
  }
});
// Download offline will check the RESOURCES for all files not in the cache
// and populate them.
async function downloadOffline() {
  var resources = [];
  var contentCache = await caches.open(CACHE_NAME);
  var currentContent = {};
  for (var request of await contentCache.keys()) {
    var key = request.url.substring(origin.length + 1);
    if (key == "") {
      key = "/";
    }
    currentContent[key] = true;
  }
  for (var resourceKey of Object.keys(RESOURCES)) {
    if (!currentContent[resourceKey]) {
      resources.push(resourceKey);
    }
  }
  return contentCache.addAll(resources);
}
// Attempt to download the resource online before falling back to
// the offline cache.
function onlineFirst(event) {
  return event.respondWith(
    fetch(event.request).then((response) => {
      return caches.open(CACHE_NAME).then((cache) => {
        cache.put(event.request, response.clone());
        return response;
      });
    }).catch((error) => {
      return caches.open(CACHE_NAME).then((cache) => {
        return cache.match(event.request).then((response) => {
          if (response != null) {
            return response;
          }
          throw error;
        });
      });
    })
  );
}
