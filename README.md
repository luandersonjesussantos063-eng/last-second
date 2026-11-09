# Last Second — v1.11

Jogo espacial em primeira pessoa: cockpit 3D, decolagem automática, exploração, turbo, colisões e retorno à base. Arquivos estáticos, sem servidor de jogo ou conta de usuário.

## Jogar / desenvolver

Os arquivos de execução e modelos otimizados já estão no repositório. Sirva a pasta por HTTP; não abra index.html por file://, pois os módulos e o carregamento do modelo exigem HTTP.

```sh
npm ci
npm run dev
```

O servidor local usa a porta 8080 (variável PORT para alterar). Não precisa de CDN para jogar: Three.js e as dependências de execução são locais. O primeiro carregamento ainda exige baixar o modelo selecionado; falhas oferecem opção de recarregar.

## Controles

- Computador: WASD ou setas para pilotar; Shift para turbo; L para solicitar pouso quando a base estiver ao alcance e para decolar novamente; P/Esc para pausar/continuar; R após perder a nave.
- Celular: tela deitada; arrastar para pilotar, segurar TURBO e tocar no botão de pouso/decolagem quando disponível. Pausa e Tentar novamente têm botões próprios.
- Automático ajusta resolução conforme o tempo dos quadros. Econômico reduz a resolução e fica salvo neste navegador. Essa opção não muda a física ou a quantidade de objetos.
- Ao sair da aba, perder o foco ou girar o celular para retrato, o voo pausa. Volte para paisagem e toque Continuar.

## Reproduzir os assets

```sh
npm run build:engine
npm run build:models
```

O engine usa Three.js 0.186.0 e esbuild, com licença e hashes em vendor/. O modelo original models/cockpit_scifi.glb é preservado. Os derivados mobile (texturas até 1024 px) e desktop (até 2048 px) mantêm os oito meshes e os três painéis nomeados. A otimização é feita com glTF Transform e WebP, sem depender de serviços de conversão online. Os modelos derivados requerem navegador com WebP e WebGL2.

## Verificação

```sh
npm run check
npm test
npm run test:browser
```

O último comando usa Playwright e Chromium disponível em /usr/bin/chromium, ou CHROMIUM_PATH. Pode ser necessário instalar o navegador e suas bibliotecas no ambiente de desenvolvimento. O teste inicia e encerra o próprio servidor local; não acessa serviços externos. Instrumentação para acelerar a física existe apenas no teste via interceptação da resposta de main.js — não é incluída no jogo publicado. Acelerar essas verificações não mede FPS.

Consulte docs/performance-v1.11.md para resultados, metodologia e limites. O modelo original e demais materiais existentes mantêm sua origem; a licença do engine não transfere direitos sobre os modelos.
