'use strict';
const MANIFEST = 'flutter-app-manifest';
const TEMP = 'flutter-temp-cache';
const CACHE_NAME = 'flutter-app-cache';

const RESOURCES = {"assets/AssetManifest.bin": "062096413752a379b601ef1d42b75cf0",
"assets/AssetManifest.bin.json": "433cf30f4960c63bee1b951bf2aa9a7e",
"assets/assets/audio/bold_text_swell.mp3": "0fd05bb3459d5219d6f80102038b750e",
"assets/assets/audio/bouncy_arrow.mp3": "12b8f4a01e1d8530c4ae8ed060bba828",
"assets/assets/audio/do.mp3": "d80e87a3d1b53ea13e6203cf764f10a3",
"assets/assets/audio/enter_sound.mp3": "3396208a2b5674ed13ceaaa698c1197b",
"assets/assets/audio/fa.mp3": "384ea4650d2f585c87540172d7a0b832",
"assets/assets/audio/glass_break.mp3": "73f613edcbee8d8f938390bfb37a3378",
"assets/assets/audio/mi.mp3": "83d7b5dc6728ef98ad55b92354ad7483",
"assets/assets/audio/re.mp3": "91c1a338a191e0c129bf7c8e4e00ca55",
"assets/assets/audio/si.mp3": "275dcc0e6d340b122adf0138e0fefcbe",
"assets/assets/audio/slide_in.mp3": "228c934e838678a2c627ec007f8e6017",
"assets/assets/audio/sol.mp3": "0b57e6b26111ba61f3623a5d340bb501",
"assets/assets/audio/thunder_crack.mp3": "03bec08bd6d6f4011073eb8f37cd39de",
"assets/assets/audio/thunder_roll.mp3": "553d032fd838de59b6ac767a52ec2ba1",
"assets/assets/audio/ting.mp3": "c3c9962a6f5258011bccb82a50cc96b8",
"assets/assets/audio/title_loaded.mp3": "0319f0fa6968a01a0445f6e1a3c8f4da",
"assets/assets/audio/waterdrop.mp3": "4109e93e758cf607f1561de6c9f10d36",
"assets/assets/calming_circle_white.json": "f6482f974fd79355aefe368582b0a252",
"assets/assets/decal_glossiness.png": "1c8435d3e048803c55750d333ed7fcec",
"assets/assets/decal_normal.png": "995aa55b836a0ec84860306aa5696bc9",
"assets/assets/decal_opacity.png": "66a3c049537af1954176f54a4ce2076a",
"assets/assets/fonts/deecode_regular.json": "e19e96f31d3e01adb5c2b0ca8289ac2e",
"assets/assets/fonts/helvetiker.json": "6b00b467943ab5767a425dfb2e461927",
"assets/assets/fonts/monoblock_bold.json": "249caff69cc50b1fc28413035203e347",
"assets/assets/fonts/pixel_code.json": "8342f00ed016eb2b5a6813bb32d230f4",
"assets/assets/fonts/trt_artnik.json": "3bd1fd6edd1773c06ab49f8be459bbf1",
"assets/assets/images/ic_book.png": "03e200b9d82743b56bd27b705690f627",
"assets/assets/images/ic_chalice.png": "a4a8b233c07dcc1853ea9318f296a94f",
"assets/assets/images/ic_crystal.png": "b94665b7e1feb204e7888fa3949aa961",
"assets/assets/images/ic_sword.png": "7cc46df04138f3698d8732307a173aef",
"assets/assets/images/logo.png": "54badd0a2391a921ba02709b1fc1ff5a",
"assets/assets/planet.jpg": "609ae9ab985f638eb094f09aa52fb169",
"assets/assets/shaders/background_run_v2.frag": "4b354b6b0e1102af26707dc7173600dc",
"assets/assets/shaders/beach.frag": "330c9b02ab5b1f1e8c8e5352f1a24cfd",
"assets/assets/shaders/bold_text_entrance.frag": "1f831818b7ec59eee7057b08c81b0094",
"assets/assets/shaders/flash_transition.frag": "aa174e8094c11e10fe8b4e98f9f564f0",
"assets/assets/shaders/god_rays.frag": "10a7424c2e37ef899c9e3393f7d1e959",
"assets/assets/shaders/logo.frag": "6a4190dc7728ba37f890622a2e8176bf",
"assets/assets/shaders/metallic_text.frag": "fe94f00bc5dae7ab49878aec2a8a9d70",
"assets/assets/shaders/orbiting_lights.frag": "b02f545e2659416e48fca24eaef407e6",
"assets/assets/shaders/rain.frag": "c2fe1970660a13c11daef74743708c7b",
"assets/assets/shaders/shine_text.frag": "e23d7124deabbe1964f1deb9d710d5f1",
"assets/assets/stars.jpg": "6119599d42c93420cc7dada0a119834a",
"assets/assets/vectors/down_arrow.svg": "4d3947b0224c2f737187c610daa2ba78",
"assets/FontManifest.json": "495b67ef0d9b0c12e009e7c32d25c9c7",
"assets/fonts/broadway.ttf": "1061e922ac6d0f148514c785c4e46721",
"assets/fonts/dune_rise.ttf": "bca5da28daa9ee1c2ca8bc9f8b15ee28",
"assets/fonts/inconsolata_nerd_mono_bold.ttf": "3b5e537dae419a0d674c4ac0b7556d04",
"assets/fonts/inconsolata_nerd_mono_regular.ttf": "6353d17821ba6308a5c3354318943066",
"assets/fonts/MaterialIcons-Regular.otf": "3762952bfa9f38167066e85fbc9416cb",
"assets/fonts/modrnt_urban.otf": "dd3526aa49ab77ba49105fb0f46d6e78",
"assets/fonts/poseidon.otf": "3151f07303f2512d0d47e6c44e46367d",
"assets/NOTICES": "b49a274fc0570b56664103d81b2ffafe",
"assets/shaders/ink_sparkle.frag": "ecc85a2e95f5e9f53123dcaf8cb9b6ce",
"assets/shaders/stretch_effect.frag": "40d68efbbf360632f614c731219e95f0",
"canvaskit/canvaskit.js": "8331fe38e66b3a898c4f37648aaf7ee2",
"canvaskit/canvaskit.js.symbols": "a3c9f77715b642d0437d9c275caba91e",
"canvaskit/canvaskit.wasm": "9b6a7830bf26959b200594729d73538e",
"canvaskit/chromium/canvaskit.js": "a80c765aaa8af8645c9fb1aae53f9abf",
"canvaskit/chromium/canvaskit.js.symbols": "e2d09f0e434bc118bf67dae526737d07",
"canvaskit/chromium/canvaskit.wasm": "a726e3f75a84fcdf495a15817c63a35d",
"canvaskit/skwasm.js": "8060d46e9a4901ca9991edd3a26be4f0",
"canvaskit/skwasm.js.symbols": "3a4aadf4e8141f284bd524976b1d6bdc",
"canvaskit/skwasm.wasm": "7e5f3afdd3b0747a1fd4517cea239898",
"canvaskit/skwasm_heavy.js": "740d43a6b8240ef9e23eed8c48840da4",
"canvaskit/skwasm_heavy.js.symbols": "0755b4fb399918388d71b59ad390b055",
"canvaskit/skwasm_heavy.wasm": "b0be7910760d205ea4e011458df6ee01",
"favicon.png": "5dcef449791fa27946b3d35ad8803796",
"flutter.js": "24bc71911b75b5f8135c949e27a2984e",
"flutter_bootstrap.js": "36e379fb8e6483c011f103cb43614475",
"icons/Icon-192.png": "ac9a721a12bbc803b44f645561ecb1e1",
"icons/Icon-512.png": "96e752610906ba2a93c65f8abe1645f1",
"icons/Icon-maskable-192.png": "c457ef57daa1d16f64b27b786ec2ea3c",
"icons/Icon-maskable-512.png": "301a7604d45b3e739efc881eb04896ea",
"index.html": "067d251481f8d7d599b130c44cc3e39f",
"/": "067d251481f8d7d599b130c44cc3e39f",
"main.dart.js": "294dda2523760942f470bac5f8eab594",
"manifest.json": "a4b071773b106326b88f567f351ce652",
"version.json": "52a57603adb9193783e60ee14745a710"};
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
