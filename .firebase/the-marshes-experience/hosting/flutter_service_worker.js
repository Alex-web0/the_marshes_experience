'use strict';
const MANIFEST = 'flutter-app-manifest';
const TEMP = 'flutter-temp-cache';
const CACHE_NAME = 'flutter-app-cache';

const RESOURCES = {"assets/AssetManifest.bin": "711f68f157e5170f32f9229c5025bacf",
"assets/AssetManifest.bin.json": "7987813ff4516f4d5643e9d4da1cd08d",
"assets/AssetManifest.json": "0baf772a01ffb8c57c5c404c1046490d",
"assets/assets/audio/music/bg_music_1.mp3": "7ae3bd29a5223d7abd77b3453d246964",
"assets/assets/audio/music/bg_music_2.mp3": "de44b5ff8f272361d377cbbbb3ad956f",
"assets/assets/audio/music/bg_music_game.mp3": "30549d04249aae2744d201868fcd6529",
"assets/assets/audio/sounds/bonus_1.mp3": "8f5bc30d87693395393a8c5747a09ef8",
"assets/assets/audio/sounds/bonus_2.mp3": "6e7f08f8b27e5e15131e75eaa224c425",
"assets/assets/audio/sounds/button_press_1.mp3": "41e083b10dd5900d539207af7284a1a4",
"assets/assets/audio/sounds/button_press_2.mp3": "ff129f39ddd6609d408a2df0c4688bab",
"assets/assets/audio/sounds/button_press_3.mp3": "41e083b10dd5900d539207af7284a1a4",
"assets/assets/audio/sounds/drowning.mp3": "c499ef89bcad95f14f13500959502e76",
"assets/assets/audio/sounds/item_collect.mp3": "56e3e4d9d740c274bf8641849457d2d7",
"assets/assets/audio/sounds/water_splash.mp3": "ba16db3e6b8b61051cebc64bd88f8dd0",
"assets/assets/images/bg_marshes_extended.png": "286d354b8d243de7a3dd48fe204b052e",
"assets/assets/images/boat_sprite.png": "a93e2fd83dfc1f44424d01948c520c5c",
"assets/assets/images/boat_sprites/sprite_boat_1.png": "61e45ceac305791a8a53ac7e63e96c0d",
"assets/assets/images/boat_sprites/sprite_boat_10.png": "4af411cd4b3f6c4407876b2be4de086d",
"assets/assets/images/boat_sprites/sprite_boat_11.png": "18f3f6305d914324f2f0c22533bf308a",
"assets/assets/images/boat_sprites/sprite_boat_12.png": "f168f78296e83bed3a5625dc3f40a8fe",
"assets/assets/images/boat_sprites/sprite_boat_13.png": "8bfa2ff3db632c484c51b9f3ff1941f5",
"assets/assets/images/boat_sprites/sprite_boat_2.png": "28e12d408f05940bc265c1d3d8026ea1",
"assets/assets/images/boat_sprites/sprite_boat_3.png": "3b8dd35e94f63f18a85a93ec92ff703a",
"assets/assets/images/boat_sprites/sprite_boat_4.png": "dcaa8d9c3d196cfd7064948a6d5edcff",
"assets/assets/images/boat_sprites/sprite_boat_5.png": "829e6e8971290ced5e2fcafe13e4d07a",
"assets/assets/images/boat_sprites/sprite_boat_6.png": "9bed0434313d4e9e6c9703d5d499ae47",
"assets/assets/images/boat_sprites/sprite_boat_7.png": "9bed0434313d4e9e6c9703d5d499ae47",
"assets/assets/images/boat_sprites/sprite_boat_8.png": "9bed0434313d4e9e6c9703d5d499ae47",
"assets/assets/images/boat_sprites/sprite_boat_9.png": "9bed0434313d4e9e6c9703d5d499ae47",
"assets/assets/images/box_open.png": "49065a959d79695b6b4446ea0805c224",
"assets/assets/images/chest.png": "3c708a037dc51d8ff294f9d8ee11dc1a",
"assets/assets/images/fish_salt.png": "64a3343406b6fe39c27b7f33529935c0",
"assets/assets/images/fish_sprite.png": "64a3343406b6fe39c27b7f33529935c0",
"assets/assets/images/Group%252053.png": "c0f62b5d5838919c77f2eeeddcb49208",
"assets/assets/images/idle_box.png": "f3337ea1dd174f58d7fc97b96c6a77c1",
"assets/assets/images/looped_extended.png": "ad26413a7fa7f332ac862f5e33aed666",
"assets/assets/images/mute_button.png": "e77e85431921c18b5969e237369dbda3",
"assets/assets/images/pause_button.png": "ba54286406c6d1b8938360b551c576f9",
"assets/assets/images/river_marshes_bg.png": "fb89771449551ca2c865bd46cc99d1fc",
"assets/assets/images/sprite%25201.png": "e3c1f818f1578fc2d9bed4c174eec7ef",
"assets/assets/images/sprite-2%25201.png": "b96661653e9be932999a4b4decd94d89",
"assets/assets/images/sprite-3%25201.png": "ddcccc6bb35ffdc3f38edf2aaeb173c0",
"assets/assets/images/sprite-4%25201.png": "61f8a6fbea206d1775c66cb930fc2a81",
"assets/assets/images/sprite-5%25201.png": "25f575fffff15bcde707d21814d63a1b",
"assets/assets/images/sprite-6%25201.png": "edf82150bbb3a264efa6231a48f069c8",
"assets/assets/images/sprite-7%25201.png": "a948ebbb95c434998301146bcff297be",
"assets/assets/images/sugar_cane.png": "e3cc9057b79733a70bba57540cae568d",
"assets/assets/images/sugar_cane_high.png": "597081dbca92084dd3fbba5185e5f6a5",
"assets/assets/images/unmute_button.png": "fc859f31a12a77193bb8eec0783d35ad",
"assets/FontManifest.json": "dc3d03800ccca4601324923c0b1d6d57",
"assets/fonts/MaterialIcons-Regular.otf": "75dc1160f5252a2efefab9018019b9f3",
"assets/NOTICES": "5cfcb77a3cd50924519dbd7554d17334",
"assets/packages/cupertino_icons/assets/CupertinoIcons.ttf": "e986ebe42ef785b27164c36a9abc7818",
"assets/shaders/ink_sparkle.frag": "ecc85a2e95f5e9f53123dcaf8cb9b6ce",
"canvaskit/canvaskit.js": "26eef3024dbc64886b7f48e1b6fb05cf",
"canvaskit/canvaskit.js.symbols": "efc2cd87d1ff6c586b7d4c7083063a40",
"canvaskit/canvaskit.wasm": "e7602c687313cfac5f495c5eac2fb324",
"canvaskit/chromium/canvaskit.js": "b7ba6d908089f706772b2007c37e6da4",
"canvaskit/chromium/canvaskit.js.symbols": "e115ddcfad5f5b98a90e389433606502",
"canvaskit/chromium/canvaskit.wasm": "ea5ab288728f7200f398f60089048b48",
"canvaskit/skwasm.js": "ac0f73826b925320a1e9b0d3fd7da61c",
"canvaskit/skwasm.js.symbols": "96263e00e3c9bd9cd878ead867c04f3c",
"canvaskit/skwasm.wasm": "828c26a0b1cc8eb1adacbdd0c5e8bcfa",
"canvaskit/skwasm.worker.js": "89990e8c92bcb123999aa81f7e203b1c",
"favicon.png": "5dcef449791fa27946b3d35ad8803796",
"flutter.js": "4b2350e14c6650ba82871f60906437ea",
"flutter_bootstrap.js": "44edbcad618403caf7ab16dcad302392",
"icons/Icon-192.png": "ac9a721a12bbc803b44f645561ecb1e1",
"icons/Icon-512.png": "96e752610906ba2a93c65f8abe1645f1",
"icons/Icon-maskable-192.png": "c457ef57daa1d16f64b27b786ec2ea3c",
"icons/Icon-maskable-512.png": "301a7604d45b3e739efc881eb04896ea",
"index.html": "bfba371a75c7a83103db7ed13a7752eb",
"/": "bfba371a75c7a83103db7ed13a7752eb",
"main.dart.js": "1a619c9d88fb59f86e4198f87f9eb544",
"manifest.json": "8ea2a017fd78b0b850ad356716b7d6c6",
"version.json": "c29f1e3216d6f98c330758a87ce07a51"};
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
