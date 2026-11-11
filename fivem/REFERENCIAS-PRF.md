# Referências PRF e recursos integrados

| Item | Estado atual |
| --- | --- |
| Chevrolet Trailblazer PRF | Modelo e texturas do RAR `a1b534-Tailblazer PRF.rar` preparados em `prf_trailblazer`. Substitui `police` e é a escolha padrão de `/prfviatura`. |
| Uniformes PRF | Pacote `PRF v2 - by wlukaas.zip` adaptado em `prf_uniformes_wlukaas`: camisas, coletes e bonés masculinos/femininos, além de peças femininas. Aplicação no jogador pelo menu **F6 → 4** ou pelo vestiário. |
| BMW GS Adventure da primeira foto | Ausente nos arquivos recebidos. `/prfmoto` informa a pendência; a `policeb` de F9 continua sendo uma moto de teste do GTA. |
| Base fixa da segunda foto | Mapa e modelos ausentes. A referência tem cobertura metálica sobre a rodovia, testeira azul com letras amarelas, pilares e prédio de atendimento à esquerda. O posto continua provisoriamente em Sandy Shores; `/prfbase` apenas indica sua posição. |
| Equinox | O arquivo excedeu o limite de transferência de 32 MiB e não pôde ser analisado ou integrado. |

O usuário também enviou esta [prévia adicional da base PRF](https://ryzestore.com/img/w1200/storage/previews/webp/2026/05/5fcb19957ab0d1afb1cf06b38df7cfeb8ec43bf3bb331cc614ba9db7c2cbf69f.webp): posto sobre ponte/viaduto, prédio amarelo e azul à esquerda e cobertura larga sobre a pista com `PRF 191`. É uma imagem de referência, não um pacote de mapa instalável. Nenhum mapa foi adquirido ou instalado a partir dela.

O ZIP do GitHub inclui os dois recursos, os uniformes, as texturas e as partes do modelo da Trailblazer; o instalador prepara automaticamente os arquivos finais do veículo. Instale-o por `fivem/scripts/setup-prf-legacy.cmd`, conforme o [guia do servidor](README.md). Não é necessário modificar arquivos do GTA original com OpenIV. O `server.cfg` deve iniciar `prf_trailblazer` e `prf_uniformes_wlukaas` antes de `prf_core`.

As três fotos continuam sendo referências visuais. **Não foi realizado teste visual dentro do GTA V/FiveM neste ambiente, nem confirmada correspondência exata do modelo recebido com a viatura da foto.** Modelos e texturas não disponíveis não são gerados pela configuração.

## Configuração e origem

`prf_core/config.lua` contém a frota em `Config.Fleet`, a viatura padrão em `Config.Vehicle` e o fardamento em `Config.Uniform`. Os recursos preservam as texturas do autor; pinturas e extras dependem dos índices existentes no modelo. O uniforme utiliza coleções e índices locais, validando-os antes de trocar a aparência. Retirar o uniforme restaura o modelo anterior com roupas padrão, sem salvar toda a personalização.

Quando houver um mapa real, configure `Config.Base.name`, `mapResource`, `x`, `y`, `z` e `heading`, além dos pontos de garagem, vestiário, COPOM e armaria. Instale o recurso completo do mapa, com suas dependências e colisões, antes de `prf_core`. Um marcador no GPS não substitui a construção.

Crédito dos uniformes: **@wlukaas**. O README original contém “Compartilhe”; não acompanha licença formal adicional. O RAR da Trailblazer não contém README nem identificação de autoria, por isso não foi atribuído um autor presumido. Os arquivos `origem.json` de cada recurso registram os caminhos originais, tamanhos e hashes. Veja [Trailblazer](resources/[prf]/prf_trailblazer/README.md) e [uniformes](resources/[prf]/prf_uniformes_wlukaas/README.md).
