# PRF • Patrulha Rodoviária — 2.5.0

Simulador de fiscalização rodoviária convertido do Last Second. Posto elevado com escritório acessível, cobertura sobre a rodovia inspirada na foto de referência, viatura PRF dirigível, três viaturas de apoio e oito veículos em circulação. Funciona como site estático, sem conta ou servidor de jogo. O agente principal é um GLB servido pelo próprio site.

O vídeo enviado orientou a câmera em terceira pessoa, a identidade da viatura e do agente, o radar e a abordagem no acostamento. O agente principal usa malha humana texturizada e animações por esqueleto; os demais personagens e o cenário continuam procedurais. A versão não reproduz a fidelidade gráfica nem a física de GTA V. O cenário e o comportamento podem evoluir sobre esta base jogável.

## Jogar

```sh
npm ci
npm run dev
```

Abra o endereço local indicado pelo servidor (porta 8080 por padrão; PORT permite alterar). Os arquivos publicados na raiz já incluem o engine local. Não abra index.html por file://.

No menu, **Começar patrulha** inicia na viatura; **Explorar posto** começa a pé. Ao olhar para a frente da viatura na vaga, o acesso à rodovia fica à direita. O trânsito e as abordagens seguem a mão direita nos dois sentidos. O alvo azul está identificado no cenário e no mapa.

1. Embarque, acesse a rodovia e localize o veículo marcado.
2. Ligue o giroflex e aproxime-se a menos de 45 m, no mesmo sentido.
3. Solicite parada com F; o trecho de sirene de ordem de parada toca automaticamente. Aguarde o veículo encostar à direita e o condutor desembarcar.
4. Estacione com espaço, desembarque e aproxime-se do condutor.
5. Confira a documentação e conclua a fiscalização. O condutor retorna ao veículo.
6. Retorne ao posto para receber outra fiscalização.

## Posto e blitz

A cobertura tem pilares, treliças e letreiro amarelo, junto ao escritório envidraçado. Asfalto e terreno usam texturas geradas localmente, com iluminação de fim de tarde. Computadores usam sombras; celular e modo econômico usam sombreamento simplificado.

A equipe tem agentes de sinalização, conferência de documentos, rádio e vigilância. A blitz seleciona um carro, sinaliza, conduz à área de inspeção e libera após a conferência. O painel do posto mostra o andamento. As manobras aguardam pedestres e viaturas; o veículo da missão do jogador não é selecionado pela equipe.

## Base em atividade

A plataforma fica 60 cm acima da pista, com três degraus, rampa lateral e canteiros. As vagas têm faixas brancas. Visitantes chegam com seis carros reutilizáveis, estacionam, desembarcam, registram seus relatos e saem; as manobras do estacionamento são coordenadas para evitar travamento entre entrada e saída. A viatura de apoio faz patrulhas e retorna ao posto.

O trânsito tem sedãs, hatchbacks, van, picape e motos com condutores. Duas motos PRF inspiradas na referência ficam de prontidão, com seus agentes. Em intervalos, um veículo pode evadir; a motopatrulha acompanha, conduz ao acostamento e retorna. O painel informa a ocorrência. Trata-se de comportamento simplificado do jogo, sem física real de motocicleta ou inteligência policial completa.

## Atendimento de ocorrências

Entre pela porta automática e siga para a sala envidraçada **COMANDO GERAL**, à esquerda. Aproxime-se da cadeira do computador e pressione **F** (ou toque em SENTAR NO COMPUTADOR). A porta da sala abre automaticamente por proximidade. Seu personagem usa uniforme tático camuflado com identificação COMANDO GERAL. A mesa fica de frente para a entrada, com o visitante sentado numa cadeira à frente e o monitor deslocado para o lado. Clique ou toque diretamente nos botões da tela 3D do computador: **CHAMAR PRÓXIMO**, espere a pessoa chegar e leia o relato antes de **REGISTRAR / LIBERAR**. Fila, relato e histórico aparecem no próprio monitor. Clique na área do relato para ampliar a visão do computador; clique novamente para voltar à sala. **E** ou LEVANTAR encerra seu atendimento e devolve a pessoa à fila se necessário. A janela lateral permite acompanhar a blitz; você pode arrastar a visão enquanto está sentado.

Seis visitantes reutilizáveis chegam em intervalos, aguardam, são atendidos e saem. Um agente atende paralelamente na recepção. O computador usa relatos fictícios predefinidos e guarda até 20 registros apenas durante o turno; reiniciar ou recarregar limpa o histórico. Não é um sistema real de boletim de ocorrência.

## Controles

| Comando | Função |
| --- | --- |
| W/S ou ↑/↓ | Andar; acelerar, frear e engatar ré na viatura |
| Shift (segurar) | Correr a pé; no celular, segure CORRER junto ao analógico |
| A/D ou ←/→ | Girar agente/câmera a pé; dirigir a viatura |
| Arrastar com mouse ou toque | Olhar a pé |
| E | Embarcar/desembarcar com a viatura parada |
| F | Solicitar parada, conferir documentos ou receber nova fiscalização |
| G / H | Giroflex / sirene de perseguição (liga/desliga) |
| B | Pedido curto de passagem |
| C | Alternar primeira/terceira pessoa; câmera interna/externa da viatura |
| J | Radar de velocidade a pé: aponte para o veículo |
| Espaço | Freio de mão |
| P / Esc | Pausar/continuar |
| R | Reiniciar turno e retornar ao posto |

No celular, use o analógico à esquerda e os pedais à direita; os comandos de interação têm botões próprios. Há volume/mute, modo econômico e tela cheia na pausa. Perder o foco pausa o turno; na conferência de documentos, o trânsito também fica pausado.

## Agente principal GLB

O Comando Geral usa `assets/models/prf-agent.glb`, adaptado do **Military_Male_01** da [Microsoft Rocketbox](https://github.com/microsoft/Microsoft-Rocketbox), sob licença MIT. A licença está junto ao modelo; origem, revisão, alterações e hash ficam em `assets/models/manifest.json`. Uniforme oliva/camuflado, colete, capacete, luvas, botas e rosto vêm da malha e das texturas originais adaptadas. As identificações foram alteradas para PRF/Comando Geral. Não é uma reprodução do personagem da imagem de referência.

A malha corporal tem aproximadamente 10 mil triângulos, 80 ossos, mapas PBR de cor e normal de 512/1024 pixels e seis animações incorporadas: Idle, Walk, Run, Documents, Seated e Signal. Andar/correr usa o movimento real do jogador; as transições têm mistura de 180 ms. A sinalização ocorre ao se aproximar a pé do condutor parado; a conferência anima durante o diálogo, mantendo a simulação de trânsito pausada. O modelo fica oculto na primeira pessoa e na viatura.

O GLB (~3,3 MB) é carregado uma vez, de forma assíncrona, com limite de tamanho e tempo. Há preparação de shaders antes da troca; se falhar, o personagem procedural permanece disponível. Só o personagem principal foi substituído. Testes em celular são emulados; não há medição de FPS num aparelho físico.

Para reconstruir, obtenha a revisão de origem indicada no manifesto, incluindo a pasta `Military_Male_01` e os seis FBX de animação listados em `scripts/build-prf-agent.py`. Com Blender 4.3 instalado:

```sh
npm run build:agent -- /caminho/Microsoft-Rocketbox
npm run test:avatar
```

O script preserva a proporção dos membros, retargeta as rotações, remove o deslocamento horizontal das animações e incorpora as texturas no GLB. Fontes FBX/TGA não fazem parte do download do jogo.

## Base técnica e limites

- Three.js 0.186.0 com exports limitados ao cenário atual, fixado e servido localmente. GLTFLoader e AnimationMixer incluídos no engine local; sem Draco, modelos espaciais ou CDNs de execução.
- Veículos usam modelo cinemático com aceleração, freio, ré, esterçamento, atrito e detecção de obstáculos em pequenos passos. É uma física simplificada; não simula suspensão ou dinâmica real completa de pneus.
- Tráfego em duas mãos, distância de seguimento, redução para pedestres e parada programada no acostamento. Trecho com limites e sinalização, não um mapa de mundo aberto.
- Radar lê a velocidade simulada e a distância dos veículos dentro do cone frontal. Documentos e placas são dados fictícios do jogo.
- Geometria estática agrupada por material; árvores e pessoas usam instâncias. Resolução adaptativa limita o custo em dispositivos mais lentos. Não há medição de FPS em celular físico.
- Sirenes usam a gravação videoplayback.m4a, enviada e autorizada pelo usuário, dividida em perseguição, parada e passagem. Trechos MP3 leves são carregados e decodificados uma vez; alternar comandos interrompe o anterior. H mantém a perseguição, F dá a ordem de parada e B emite um pedido breve de passagem, retomando a perseguição se ainda estava ligada.
- Demais efeitos são sintetizados: sola, motor, pneus, porta do posto, botões e rádio. Pausa, volume/mute e atenuação valem também para os trechos gravados. Origem, cortes e hashes estão em assets/audio/manifest.json.

## Verificação e rebuild

```sh
npm run check
npm test
npm run test:browser
npm run build:engine
```

O teste de navegador requer Chromium (`/usr/bin/chromium` ou CHROMIUM_PATH). Valida computador e celular emulado: deslocamento, direção, câmeras, radar, pausa, pedais, áudio, parada, documentação, liberação, reinício e ciclo autônomo da blitz. Renderiza a cena real; a simulação é acelerada em partes do teste e não mede FPS. Capturas ficam em /tmp/prf-browser.

As versões espaciais anteriores continuam no histórico do Git. Seus arquivos e modelos foram retirados desta versão, inclusive dependências de otimização de GLB que não eram mais necessárias.

Os recortes de sirene são reconstruídos com `npm run build:sirens -- /caminho/videoplayback.m4a` (requer FFmpeg). A ferramenta recorta e zera os timestamps antes dos fades e verifica o sinal PCM antes e depois da compressão. Os testes de navegador medem também cada sirene isolada, evitando confundir som de motor com a gravação.

## Publicação no GitHub Pages

O workflow `Verificar e publicar PRF` valida o código, prepara `dist/` com `npm run build:site`, envia o artefato e publica com `actions/deploy-pages`. Pull requests validam e montam o site, sem publicar. O pacote contém somente os módulos usados, HTML, ícone, assets e licenças; o GLB é conferido pelo hash antes do envio.

O jogo é estático e dispensa Jekyll. `release.json` na raiz publicada informa a versão, o commit e o hash do modelo. O Pages deve estar configurado para GitHub Actions em Settings → Pages → Build and deployment → Source. A configuração é feita pelo administrador; o workflow apenas valida e publica os arquivos. O deploy usa o ambiente `prf-pages`, separado do ambiente legado `github-pages`; continua restrito à branch `main`. O endereço público permanece o mesmo.
