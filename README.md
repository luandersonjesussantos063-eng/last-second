# PRF • Patrulha Rodoviária — 2.0.0

Primeira versão funcional da conversão do Last Second para fiscalização rodoviária. Posto com escritório acessível, trecho de rodovia, viatura PRF dirigível, oito veículos em circulação, agentes e condutor abordável. Funciona como site estático, sem conta, servidor de jogo ou downloads de modelos.

O vídeo enviado orientou a câmera em terceira pessoa, a identidade da viatura e do agente, o radar e a abordagem no acostamento. Esta versão usa modelos procedurais simples: não reproduz a fidelidade gráfica, as animações ou a física de GTA V. O cenário e o comportamento podem evoluir sobre esta base jogável.

## Jogar

```sh
npm ci
npm run dev
```

Abra o endereço local indicado pelo servidor (porta 8080 por padrão; PORT permite alterar). Os arquivos publicados na raiz já incluem o engine local. Não abra index.html por file://.

No menu, **Começar patrulha** inicia na viatura; **Explorar posto** começa a pé. A rodovia fica à esquerda da vaga da viatura. O alvo azul está identificado no cenário e no mapa.

1. Embarque, acesse a rodovia e localize o veículo marcado.
2. Ligue o giroflex e aproxime-se a menos de 45 m, no mesmo sentido.
3. Solicite parada. Aguarde o veículo encostar e o condutor desembarcar.
4. Estacione com espaço, desembarque e aproxime-se do condutor.
5. Confira a documentação e conclua a fiscalização. O condutor retorna ao veículo.
6. Retorne ao posto para receber outra fiscalização.

## Controles

| Comando | Função |
| --- | --- |
| W/S ou ↑/↓ | Andar; acelerar, frear e engatar ré na viatura |
| A/D ou ←/→ | Girar agente/câmera a pé; dirigir a viatura |
| Arrastar com mouse ou toque | Olhar a pé |
| E | Embarcar/desembarcar com a viatura parada |
| F | Solicitar parada, conferir documentos ou receber nova fiscalização |
| G / H | Giroflex / sirene |
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
- Áudio sintetizado: contato suave da sola, motor, pneus, sirene, porta do posto, botões e rádio. Preferências de áudio/qualidade são locais.

## Verificação e rebuild

```sh
npm run check
npm test
npm run test:browser
npm run build:engine
```

O teste de navegador requer Chromium (`/usr/bin/chromium` ou CHROMIUM_PATH). Valida computador e celular emulado: deslocamento, direção, câmeras, radar, pausa, pedais, áudio, parada, documentação, liberação e reinício. Renderiza a cena real; a simulação é acelerada em partes do teste e não mede FPS. Capturas ficam em /tmp/prf-browser.

As versões espaciais anteriores continuam no histórico do Git. Seus arquivos e modelos foram retirados desta versão, inclusive dependências de otimização de GLB que não eram mais necessárias.
