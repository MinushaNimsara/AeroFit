'use strict';
const MANIFEST = 'flutter-app-manifest';
const TEMP = 'flutter-temp-cache';
const CACHE_NAME = 'flutter-app-cache';

const RESOURCES = {"assets/AssetManifest.bin": "2d50e5bc57073beb77b02aea4cc99ef8",
"assets/AssetManifest.bin.json": "572d738c9d71239bdff75246e88d23ed",
"assets/AssetManifest.json": "5bb4f65aea279b87988a3ff19dbf5cb4",
"assets/assets/AssetManifest.bin": "ba26786cb05bfd147d6202659599296e",
"assets/assets/AssetManifest.bin.json": "2600a91bba6400c50e0de0d91042a0d7",
"assets/assets/data/exercises/athletic_performance.json": "5e31d8b1ef8ff6afd1596c32b8be989a",
"assets/assets/data/exercises/back.json": "5e2ac34975c86c2b19b302a85a6e1c01",
"assets/assets/data/exercises/biceps.json": "fdd84d4467eca5bfca5ec13319bb6e1a",
"assets/assets/data/exercises/calisthenics.json": "95f1baafc43da55271b16bb746e6ef90",
"assets/assets/data/exercises/cardio.json": "be468f90a0a84b564554cc743ebbab85",
"assets/assets/data/exercises/chest.json": "df320a42f5be925485853a9349c2a966",
"assets/assets/data/exercises/core.json": "adf7da2aa5cff0b28ec75027474cc324",
"assets/assets/data/exercises/forearms.json": "5977ae50ac8c4f091c0a88593ec18920",
"assets/assets/data/exercises/full_body.json": "c75176d877857dc36375da715af6d0f1",
"assets/assets/data/exercises/legs.json": "edb0a33cd73625c055c1022389d53913",
"assets/assets/data/exercises/mobility.json": "135910c684770f9c5c5170d8d240c7c6",
"assets/assets/data/exercises/shoulders.json": "427c8094c340983df74cf73a7c42d6b0",
"assets/assets/data/exercises/triceps.json": "21f1e2cb8cf6c72caecc30324c6a8dc9",
"assets/assets/exercises/images/back/assisted_pull_up_machine.gif": "9ae714037caa5d9a4eb37fa175b1cfbd",
"assets/assets/exercises/images/back/barbell_bent_over_row.gif": "6983e626deed571887c11ea264a70645",
"assets/assets/exercises/images/back/barbell_romanian_deadlift.gif": "16c99c2528cc7532a3521d46134364ce",
"assets/assets/exercises/images/back/cable_face_pull.gif": "66d7d30ef9e6b7984aab6e8f635074ae",
"assets/assets/exercises/images/back/chest_supported_row_machine.gif": "2f126c4725542d09e4342a0e9db9fe75",
"assets/assets/exercises/images/back/chin_up.gif": "047196d31fe3d979192b7c310bd214c1",
"assets/assets/exercises/images/back/conventional_barbell_deadlift.gif": "79c47a16f003cabf215d7b803a4f0e04",
"assets/assets/exercises/images/back/dumbbell_romanian_deadlift.gif": "13b5f60c6412387c8ecbd327e0335c84",
"assets/assets/exercises/images/back/face_pull_band.gif": "b89c742940a862ae7a241022cb28889b",
"assets/assets/exercises/images/back/inverted_row.gif": "c3b8e273357a4f3b4ab8bb026f5c065c",
"assets/assets/exercises/images/back/kroc_row.gif": "f6032c772d41d6422321a96bc3534f1a",
"assets/assets/exercises/images/back/lat_pulldown_close_grip.gif": "fd81b07aa56a90633d90cc07e5239b6d",
"assets/assets/exercises/images/back/lat_pulldown_reverse_grip.gif": "f30289fc1309c97b525f415404a4392b",
"assets/assets/exercises/images/back/lat_pulldown_wide_grip.gif": "8b3594feac7d1c5e0d745bcb586d1ec8",
"assets/assets/exercises/images/back/meadows_row.gif": "1a00ed5eddac4dd3b8b429c687c21983",
"assets/assets/exercises/images/back/neutral_grip_pull_up.gif": "d15850eb59476e72eb15e444ed719325",
"assets/assets/exercises/images/back/pendlay_row.gif": "42c7c5428919c407f0a84a270ef9ff3d",
"assets/assets/exercises/images/back/pull_up.gif": "33c4e7f40fa8e808ff2586291288eea0",
"assets/assets/exercises/images/back/rack_pull.gif": "267532e2ad5278ae550bd0612bfbd2a6",
"assets/assets/exercises/images/back/renegade_row.gif": "f6bf86db5df32938e47a5a9fb16eb1d6",
"assets/assets/exercises/images/back/seated_cable_row_close_grip.gif": "d2187d0c46370f0666aca5add4d41bf5",
"assets/assets/exercises/images/back/seated_cable_row_wide_grip.gif": "ea012109bc83dd6f084d054e938075a0",
"assets/assets/exercises/images/back/single_arm_dumbbell_row.gif": "8ef5a3530a8f05799da7e7dff99b8684",
"assets/assets/exercises/images/back/single_arm_lat_pulldown.gif": "a692ed23b43ba4d69365d4a267903eb8",
"assets/assets/exercises/images/back/single_arm_seated_cable_row.gif": "8be090597bfff9d5f3b79be89f7c8919",
"assets/assets/exercises/images/back/straight_arm_pulldown.gif": "6506a8f852d18e4ce1245845a242ab99",
"assets/assets/exercises/images/back/sumo_deadlift.gif": "5d90475cc85f56007be341e76b6daca4",
"assets/assets/exercises/images/back/two_arm_dumbbell_row.gif": "7b28443ddef933b71ba5c7c2dd67a44d",
"assets/assets/exercises/images/back/t_bar_row.gif": "9d9256e37c4a87fee1ceefce5b27d0bc",
"assets/assets/exercises/images/back/wide_grip_pull_up.gif": "539db12c65b45e7f978e9fa167df299c",
"assets/assets/exercises/images/chest/barbell_bench_press.gif": "45bb59cc3df26031087c05e82945ed46",
"assets/assets/exercises/images/chest/barbell_floor_press.gif": "d604347901d48008f41744971a459c73",
"assets/assets/exercises/images/chest/cable_crossover_high_to_low.gif": "0b489c69ed7320bf49da1ed10cbfae04",
"assets/assets/exercises/images/chest/cable_crossover_low_to_high.gif": "3e4073fb0b3ec945be37de06239fa358",
"assets/assets/exercises/images/chest/cable_fly_standing.gif": "914872d6e69c561fe91d699b79279af5",
"assets/assets/exercises/images/chest/chest_dip.gif": "4805c1796e2707bfecb8c618420c3e41",
"assets/assets/exercises/images/chest/chest_press_machine.gif": "498a657cbd4ea1016b05726c0cc3568f",
"assets/assets/exercises/images/chest/decline_barbell_bench_press.gif": "d62ccb7dc9ae446f2d66b8afc7ac0cc2",
"assets/assets/exercises/images/chest/decline_dumbbell_bench_press.gif": "2e6e94c90329cb7ea7152ced3f31c0b9",
"assets/assets/exercises/images/chest/decline_push_up.gif": "272f3fd601d654dfa679e1d9e2411557",
"assets/assets/exercises/images/chest/diamond_push_up.gif": "e6a6b3479b73e50761312c49b9dab5a8",
"assets/assets/exercises/images/chest/dumbbell_bench_press.gif": "7eeb40de5c90776d6ced6082435eeff0",
"assets/assets/exercises/images/chest/dumbbell_fly.gif": "67a9d9b55f477fb0e998cfa6d07c114e",
"assets/assets/exercises/images/chest/incline_barbell_bench_press.gif": "9ec487cb3c74449d98321a1a54e73f3c",
"assets/assets/exercises/images/chest/incline_chest_press_machine.gif": "c416f989fddf95e8e8dd99d1acd2eacc",
"assets/assets/exercises/images/chest/incline_dumbbell_bench_press.gif": "5802c8be4e982e3a2472fd3349f75806",
"assets/assets/exercises/images/chest/incline_dumbbell_fly.gif": "793333ef89585f47ce66b07b6b973554",
"assets/assets/exercises/images/chest/incline_push_up.gif": "042b3c3dcf8e96194d670d983d799bf3",
"assets/assets/exercises/images/chest/landmine_press.gif": "3ea11dc9669562727073f7b249e31762",
"assets/assets/exercises/images/chest/pec_deck_fly.gif": "ba5d47b2a801134233ebdac56e76f733",
"assets/assets/exercises/images/chest/push_up.gif": "ad14e05da8be4d0c8ed38a63adeec543",
"assets/assets/exercises/images/chest/resistance_band_chest_press.gif": "7a21c08b072fc3d041837b821b3e5178",
"assets/assets/exercises/images/chest/single_arm_cable_fly.gif": "68b8fab18554b0b5b5b10888c58d1ac1",
"assets/assets/exercises/images/chest/smith_machine_bench_press.gif": "dc653beb469d6ca7b14b81babb8652e9",
"assets/assets/exercises/images/chest/svend_press.gif": "de5f73f0bb119152a9ddf8c3b39b4f56",
"assets/assets/exercises/images/chest/weighted_push_up.gif": "07d121bbb9f8bd70be01c3e8a5ba2c3f",
"assets/assets/FontManifest.json": "dc3d03800ccca4601324923c0b1d6d57",
"assets/assets/fonts/MaterialIcons-Regular.otf": "af5e9ee971e46d06a9fb1b4726dc5b27",
"assets/assets/images/app_icon_source.png": "719a95e14e18756ee4bf6f3a101f5062",
"assets/assets/images/splash_logo.png": "798aee0bdfe8e918ccd9224893ab3ea0",
"assets/assets/NOTICES": "7a96b59787557c5747a3724bccbeb1c4",
"assets/assets/packages/cupertino_icons/assets/CupertinoIcons.ttf": "33b7d9392238c04c131b6ce224e13711",
"assets/assets/shaders/ink_sparkle.frag": "ecc85a2e95f5e9f53123dcaf8cb9b6ce",
"assets/assets/shaders/stretch_effect.frag": "40d68efbbf360632f614c731219e95f0",
"assets/FontManifest.json": "dc3d03800ccca4601324923c0b1d6d57",
"assets/fonts/MaterialIcons-Regular.otf": "3be5e6b0d8e0bd5ff5210eadfd2c3eb8",
"assets/NOTICES": "4a2caef36164be8084d1b7ffd794f342",
"assets/packages/cupertino_icons/assets/CupertinoIcons.ttf": "33b7d9392238c04c131b6ce224e13711",
"assets/shaders/ink_sparkle.frag": "ecc85a2e95f5e9f53123dcaf8cb9b6ce",
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
"flutter.js": "888483df48293866f9f41d3d9274a779",
"flutter_bootstrap.js": "e5166089e8f80d087f29b6bfc1ee3405",
"flutter_bootstrap_v2.js": "0c053136ccb77ea80dd55f52a5126657",
"flutter_bootstrap_v3.js": "0c053136ccb77ea80dd55f52a5126657",
"flutter_bootstrap_v4.js": "0c053136ccb77ea80dd55f52a5126657",
"flutter_bootstrap_v5.js": "0c053136ccb77ea80dd55f52a5126657",
"flutter_bootstrap_v6.js": "0c053136ccb77ea80dd55f52a5126657",
"flutter_bootstrap_v7.js": "0c053136ccb77ea80dd55f52a5126657",
"flutter_bootstrap_v8.js": "0c053136ccb77ea80dd55f52a5126657",
"flutter_bootstrap_v9.js": "0c053136ccb77ea80dd55f52a5126657",
"icons/Icon-192.png": "0aa4e06056397d9aafbca4dc9992c412",
"icons/Icon-512.png": "946a0f460c1e01544c36508d7f3d155b",
"icons/Icon-maskable-192.png": "2c85187ac6e34443cfcb43e1f09e5bf3",
"icons/Icon-maskable-512.png": "371798a4ad8ed621298fb528fca40bbb",
"index.html": "9e613cb73b621eedd6a4a1cf71845e5f",
"/": "9e613cb73b621eedd6a4a1cf71845e5f",
"index.html.new": "1ac1e2eba1925786ac5229da4e62f146",
"main.dart.js": "d5c57f6933927b33843579da138ffa86",
"main_v2.dart.js": "0e0cf0136bb5ba8aa66b74a671e6fddb",
"main_v3.dart.js": "0e0cf0136bb5ba8aa66b74a671e6fddb",
"main_v4.dart.js": "0e0cf0136bb5ba8aa66b74a671e6fddb",
"main_v5.dart.js": "0e0cf0136bb5ba8aa66b74a671e6fddb",
"main_v6.dart.js": "0e0cf0136bb5ba8aa66b74a671e6fddb",
"main_v7.dart.js": "0e0cf0136bb5ba8aa66b74a671e6fddb",
"main_v8.dart.js": "0e0cf0136bb5ba8aa66b74a671e6fddb",
"main_v9.dart.js": "0e0cf0136bb5ba8aa66b74a671e6fddb",
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
