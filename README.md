# PRF • Patrulha Rodoviária — 2.3.1

Simulador de fiscalização rodoviária convertido do Last Second. Posto com escritório acessível, cobertura sobre a rodovia inspirada na foto de referência, viatura PRF dirigível, três viaturas de apoio e oito veículos em circulação. Funciona como site estático, sem conta, servidor de jogo ou downloads de modelos.

O vídeo enviado orientou a câmera em terceira pessoa, a identidade da viatura e do agente, o radar e a abordagem no acostamento. Esta versão usa modelos procedurais simples: não reproduz a fidelidade gráfica, as animações ou a física de GTA V. O cenário e o comportamento podem evoluir sobre esta base jogável.

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

## Atendimento de ocorrências

Entre pela porta automática e siga para a sala envidraçada à esquerda. Aproxime-se da cadeira do computador e pressione **F** (ou toque em SENTAR NO COMPUTADOR). A mesa fica de frente para a entrada. Clique ou toque diretamente nos botões da tela 3D do computador: **CHAMAR PRÓXIMO**, espere a pessoa chegar e leia o relato antes de **REGISTRAR / LIBERAR**. Fila, relato e histórico aparecem no próprio monitor. **E** ou LEVANTAR encerra seu atendimento e devolve a pessoa à fila se necessário. A janela lateral permite acompanhar a blitz; você pode arrastar a visão enquanto está sentado.

Seis visitantes reutilizáveis chegam em intervalos, aguardam, são atendidos e saem. Um agente atende paralelamente na recepção. O computador usa relatos fictícios predefinidos e guarda até 20 registros apenas durante o turno; reiniciar ou recarregar limpa o histórico. Não é um sistema real de boletim de ocorrência.

## Controles

| Comando | Função |
| --- | --- |
| W/S ou ↑/↓ | Andar; acelerar, frear e engatar ré na viatura |
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

## Base técnica e limites

- Three.js 0.186.0 com exports limitados ao cenário atual, fixado e servido localmente. Sem GLTF, Draco, modelos espaciais ou CDNs de execução.
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
