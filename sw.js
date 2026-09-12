const CACHE_NAME = "last-second-v3";

const ARQUIVOS = [
    "./",
    "./index.html",
    "./manifest.json"
];

self.addEventListener("install", function(evento) {

    evento.waitUntil(

        caches.open(CACHE_NAME)
            .then(function(cache) {

                return cache.addAll(ARQUIVOS);

            })

    );

    self.skipWaiting();

});


self.addEventListener("activate", function(evento) {

    evento.waitUntil(

        caches.keys().then(function(chaves) {

            return Promise.all(

                chaves.map(function(chave) {

                    if (chave !== CACHE_NAME) {

                        return caches.delete(chave);

                    }

                })

            );

        })

    );

    self.clients.claim();

});


self.addEventListener("fetch", function(evento) {

    evento.respondWith(

        caches.match(evento.request)
            .then(function(resposta) {

                return resposta ||
                       fetch(evento.request);

            })

    );

});
