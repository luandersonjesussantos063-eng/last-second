# Trailblazer PRF — pacote recebido

O RAR `a1b534-Tailblazer PRF.rar` recebido do usuário contém o modelo e suas texturas para GTA V Legacy. Este resource transmite os três arquivos originais e substitui o veículo **`police`**. Não precisa de outro modelo-base nem de `vehicles.meta` novo: utiliza os metadados originais de `police`.

Extraia o ZIP completo do GitHub e execute `fivem/scripts/setup-prf-legacy.cmd`: ele monta os arquivos do modelo a partir das partes fornecidas em `source`, confere a integridade e instala o recurso. Não copie apenas a pasta deste recurso para o servidor antes dessa preparação. O `server.cfg` deve ter `ensure prf_trailblazer` antes de `ensure prf_core`. A frota do core deve usar `model = 'police'` e `resource = 'prf_trailblazer'`. Evite outro resource substituindo o mesmo slot `police` ao mesmo tempo.

O ZIP do GitHub inclui o manifesto, as partes do modelo, as texturas e os hashes de origem. A montagem produz `stream/police.yft` e `stream/police_hi.yft`, junto de `stream/police.ytd`. O instalador `fivem/scripts/setup-prf-legacy.cmd` copia este recurso junto ao core. Para recuperar os binários a partir do arquivo original, existe também `fivem/scripts/import-prf-mods.py --trailblazer CAMINHO`. `police.yft` e `police_hi.yft` são idênticos no RAR original; os nomes foram preservados.

O arquivo não traz licença, instruções de autoria, configurações de dirigibilidade ou sirenes. A origem está registrada em `origem.json`. A aparência, os LEDs e o comportamento ainda precisam ser conferidos dentro do GTA V/FiveM Legacy.
