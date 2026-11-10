## Operações jogáveis v2.17.0

O menu oferece **TESTAR COPOM 3D** (isolamento, equipe de apoio, guincho e relatório) e **TESTAR BALANÇA 3D** (caminhão, conferência e registro de pesagem fictícia). Há também três carretas no trânsito. Os testes rápidos abrem o cenário diretamente; chamados normais ficam no painel **T → COPOM**. As operações são fictícias e não usam dados públicos nem IA paga.

# PRF • Patrulha Rodoviária — 2.8.0

Simulador de fiscalização rodoviária convertido do Last Second. Posto elevado com escritório acessível, cobertura sobre a rodovia inspirada na foto de referência, viatura PRF dirigível, três viaturas de apoio e oito veículos em circulação. Funciona como site estático, sem conta ou servidor de jogo. O agente principal é um GLB servido pelo próprio site.

O vídeo enviado orientou a câmera em terceira pessoa, a identidade da viatura e do agente, o radar e a abordagem no acostamento. O agente principal usa malha humana texturizada e animações por esqueleto; os demais policiais também usam modelos com esqueleto. Os civis continuam procedurais. A versão não reproduz a fidelidade gráfica nem a física de GTA V. O cenário e o comportamento podem evoluir sobre esta base jogável.

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

## Comando Geral, rádio e turno

O cartão inicial mostra missões de comando. **T** ou **RÁDIO / COMANDO** abre a central. Inicie a missão, selecione o agente pelo nome e envie a ordem. **F**, a até 3 m de um agente disponível, abre ordens presenciais. Funções compatíveis aparecem para cada policial: Silva e Souza intensificam a blitz; Lima informa a situação; Costa reforça Almeida na recepção; Rocha faz a ronda ou caminha até a viatura para embarcar, patrulhar e retornar; Santos e Oliveira confirmam prontidão e respondem a evasões. Durante uma operação externa, os agentes continuam respondendo a informes pelo rádio, sem interromper o atendimento. Rocha pode receber ordem de retorno enquanto a viatura está no trecho; tarefas a pé aguardam o retorno.

Há quatro missões em sequência: coordenar a blitz, despachar patrulha, organizar atendimento e garantir a segurança da base. Os objetivos exigem o resultado efetivo: fiscalização liberada depois das ordens, patrulha no trecho e informe recebido, cidadão atendido após a chegada do reforço, ou ronda física e confirmação das duas motos. Ao concluir, solicite a próxima no comando. Ordens, confirmações e informes têm histórico limitado às últimas 12 transmissões do turno. O rádio tem retorno sonoro e confirmações em texto; as ordens são selecionadas pelo menu.

O serviço continua enquanto o painel está aberto; o jogador fica parado. O rádio aparece na mão e o fuzil fica guardado durante a comunicação. O relógio começa às 16:30 e avança **um minuto de jogo por segundo** (24 minutos por dia), com contagem de dias. Pausa e inspeção de documentos congelam o horário. Reiniciar restaura o turno. Céu, sol, lua, estrelas e luz ambiente acompanham o relógio; refletores da cobertura, escritório e estacionamento acendem automaticamente à noite. São quatro luzes locais fixas sem mapas de sombra adicionais.

**VER FISCALIZAÇÃO** alterna para a missão individual e seu marcador; o comando e a equipe continuam ativos. A simulação usa estado local, rotinas e trajetos delimitados, sem serviço remoto de IA ou reconhecimento de voz.

## Posto e blitz

A cobertura tem pilares, treliças e letreiro amarelo, junto ao escritório envidraçado. Asfalto e terreno usam texturas geradas localmente, com ciclo contínuo de manhã, tarde e noite. Computadores usam sombras; celular e modo econômico usam sombreamento simplificado.

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
| V | Guardar/empunhar o fuzil; botão FUZIL no celular |
| Shift (segurar) | Correr a pé; no celular, segure CORRER junto ao analógico |
| A/D ou ←/→ | Girar agente/câmera a pé; dirigir a viatura |
| Arrastar com mouse ou toque | Olhar a pé |
| E | Embarcar/desembarcar com a viatura parada |
| F | Dar ordens a um agente próximo; solicitar parada, conferir documentos ou usar o computador |
| T | Rádio, seleção de agente pelo nome e missões de comando |
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

A malha corporal tem aproximadamente 10 mil triângulos, 80 ossos, mapas PBR de cor e normal de 512/1024 pixels e nove animações incorporadas: Idle, Walk, Run, Documents, Seated, Signal e três variações de porte do fuzil. Andar/correr usa o movimento real do jogador; as transições têm mistura de 180 ms. A sinalização ocorre ao se aproximar a pé do condutor parado; a conferência anima durante o diálogo, mantendo a simulação de trânsito pausada. O modelo fica oculto na primeira pessoa e na viatura.

O GLB do comandante (~3,8 MB) é carregado uma vez, de forma assíncrona, com limite de tamanho e tempo. Há preparação de shaders antes da troca; se falhar, o personagem procedural permanece disponível. Os policiais de apoio usam um segundo modelo compartilhado; os civis mantêm os modelos anteriores. Testes em celular são emulados; não há medição de FPS num aparelho físico.

Para reconstruir, obtenha a revisão de origem indicada no manifesto, incluindo a pasta `Military_Male_01` e os seis FBX de animação listados em `scripts/build-prf-agent.py`. Com Blender 4.3 instalado:

```sh
npm run build:agent -- /caminho/Microsoft-Rocketbox
npm run test:avatar
```

O script preserva a proporção dos membros, retargeta as rotações, remove o deslocamento horizontal das animações e incorpora as texturas no GLB. Fontes FBX/TGA não fazem parte do download do jogo.

## Policiais, frota e porte do fuzil (2.6)

Oito agentes usam o `prf-officer.glb`, adaptado do Police_Male_01 da mesma biblioteca MIT: farda azul-marinho, calça cáqui e boné. Os agentes da blitz têm coletes refletivos; os motociclistas têm capacetes. Cada clone possui seu esqueleto e animação, compartilhando malhas, materiais e texturas. As funções de recepção, sinalização, conferência, rádio e motopatrulha usam suas poses correspondentes. O modelo é baixado uma vez (~1,7 MB); a animação dos agentes distantes atualiza com frequência reduzida no celular. Fora da distância de detalhe, continuam disponíveis as figuras leves.

As quatro viaturas usam uma SUV genérica original em GLB (~0,83 MB), com carroceria curva, janelas, cabine, rodas, grade, quebra-mato, identificação PRF e LEDs. As duas motos usam outro modelo original (~0,36 MB), com motor, quadro, rodas raiadas, suspensão e malas laterais. Rodas, direção e giroflex continuam ligados à simulação existente. Os arquivos compartilham geometria e materiais entre as instâncias. Os veículos e personagens civis não foram substituídos.

O comandante porta um fuzil visual original com poses para ficar parado, andar e correr. **V** ou **FUZIL** alterna o porte e a posição nas costas. Há braços e arma na câmera em primeira pessoa; ao usar radar, conferir documentos, sentar no computador ou embarcar, a apresentação muda conforme a atividade. Não foram adicionadas mecânicas de disparo.

Reconstrução e testes específicos:

```sh
npm run build:officer -- /caminho/Microsoft-Rocketbox
npm run build:fleet
npm run test:fleet
```

Origem e hashes dos agentes estão nos manifestos de `assets/models/`; os veículos e o fuzil são gerados pelos scripts locais, sem modelos comerciais de marcas de automóveis. `build:site` confere todos os quatro GLBs antes de publicar.

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
npm run test:command
npm run build:engine
```

O teste de navegador requer Chromium (`/usr/bin/chromium` ou CHROMIUM_PATH). Valida computador e celular emulado: deslocamento, direção, câmeras, radar, pausa, pedais, áudio, parada, documentação, liberação, reinício e ciclo autônomo da blitz. Renderiza a cena real; a simulação é acelerada em partes do teste e não mede FPS. Capturas ficam em /tmp/prf-browser. `test:command` confere ordens por nome e proximidade, progresso da missão, deslocamento de Rocha, rádio na mão, dia/noite e refletores em computador e celular emulado; capturas em /tmp/prf-command.

As versões espaciais anteriores continuam no histórico do Git. Seus arquivos e modelos foram retirados desta versão, inclusive dependências de otimização de GLB que não eram mais necessárias.

Os recortes de sirene são reconstruídos com `npm run build:sirens -- /caminho/videoplayback.m4a` (requer FFmpeg). A ferramenta recorta e zera os timestamps antes dos fades e verifica o sinal PCM antes e depois da compressão. Os testes de navegador medem também cada sirene isolada, evitando confundir som de motor com a gravação.

## Publicação no GitHub Pages

O workflow `Verificar e publicar PRF` valida o código, prepara `dist/` com `npm run build:site`, envia o artefato e publica com `actions/deploy-pages`. Pull requests validam e montam o site, sem publicar. O pacote contém somente os módulos usados, HTML, ícone, assets e licenças; o GLB é conferido pelo hash antes do envio.

O jogo é estático e dispensa Jekyll. `release.json` na raiz publicada informa a versão, o commit e o hash do modelo. O Pages deve estar configurado para GitHub Actions em Settings → Pages → Build and deployment → Source. A configuração é feita pelo administrador; o workflow apenas valida e publica os arquivos. O deploy usa o ambiente `prf-pages`, separado do ambiente legado `github-pages`; continua restrito à branch `main`. O endereço público permanece o mesmo.

## Atualização v2.8.0 — Operação por escala e patrulha ampliada

- Blitz não permanece montada o dia inteiro: há um horário diário variável (determinístico por dia de jogo), fase de montagem de cones/posicionamento das viaturas, operação de fiscalização e desmontagem antes de voltar à rotina normal. Relógio simulado: um segundo real por minuto do jogo.
- Rodovia expandida de aproximadamente 1,1 km para 3 km de extensão, com placas de distância e áreas laterais de parada. A simulação web permanece simplificada.
- Ao embarcar na viatura do comandante, três agentes identificados como Ferreira, Mendes e Nogueira se aproximam e ocupam os assentos; a saída da viatura aguarda a equipe embarcar.
- O comando **K** / **PEDIR REFORÇO** aciona outra viatura com dois agentes; após o atendimento ela retorna e há intervalo de reutilização.
- Cada publicação deve incrementar a versão SemVer em `package.json`, sincronizar os imports JS (`npm run stamp:release`) e versão em `index.html`, executar `npm run check`, `npm test` e `npm run build:site` e confirmar GitHub Pages após merge.

## v2.9.0 — IA comportamental dos policiais

Policiais agora possuem perfis individuais, memória curta por sessão de ocorrências fictícias, percepção de situações no posto e na rodovia, decisões contextualizadas para sua função e conversas entre colegas sobre acontecimentos recentes. Ordens do comandante continuam prioritárias. Inteligência **local por regras**, sem IA generativa externa, dados reais ou custo de API. Consulte [documentação](docs/rp/06-IA-POLICIAIS.md).

## Atualização v2.10.0 — Vida no posto

Policiais da unidade receberam rotinas mais humanas: ida ao bebedouro, banheiro com pausa privativa, cobertura de outros postos e revezamento de rádio/vigilância, com deslocamentos físicos e retorno ao trabalho. Dois pontos de apoio foram adicionados ao cenário (unidade e setor de fiscalização). As pausas têm durações e escalas distintas, são suspensas em ocorrências, e as ordens do comandante seguem prioritárias. Os estados de cada agente podem ser vistos pelo rádio [T]. IA local sem API externa. Consulte `docs/rp/07-ROTINA-HUMANA.md`.

## v2.11.0 — Acompanhantes aguardam no prédio

Ferreira, Mendes e Nogueira (NPCs 18, 19 e 20) permanecem no interior do posto enquanto o comandante não entra na viatura. Ao embarcar, os três saem caminhando pela entrada de pedestres e ocupam seus lugares; a viatura aguarda a equipe concluir o embarque. Ao sair da viatura dentro da base, os agentes desembarcam e retornam a pé para a sala de prontidão. Durante abordagem longe do posto, os três permanecem embarcados e retomam a patrulha quando o comandante volta. Versão sincronizada, testes de deslocamento/retorno e regressão.

## v2.12.0 — Publicação automática e indicador de versão no jogo

O HUD exibe agora a versão publicada para conferência durante a partida. Entregas web das quatro IAs, quando marcadas com `AUTO-PUBLICAR-WEB: SIM`, são integradas automaticamente após testes e verificação de versão, seguidas de publicação no GitHub Pages. Atualizações exclusivas do FiveM permanecem fora da hospedagem web. Consulte `docs/rp/08-PUBLICACAO-AUTOMATICA-IAS.md`.

## v2.13.0 — Primeira ocorrência COPOM + área de descanso

Abrir o **Comando Geral [T]** e usar **ACEITAR CHAMADO COPOM**. O HUD indica a distância até o ponto de atendimento fictício no acostamento; ao chegar, parar, desembarcar e pressionar **F** perto do local para sinalizar e concluir. O painel mostra o registro e impede chamadas duplicadas. O posto também ganhou um espaço visual simples de descanso, com mesa, banco, armário e café. Essas são mecânicas web locais, sem dados governamentais nem multiplayer. Trabalhos integrados das frentes IA-02 (lógica), IA-03 (cenário) e IA-04 (interface e QA), a partir do escopo da IA-01 (documento PR #27).

## v2.14.0 — Início do programa: rotina da escolta dentro da unidade

Os três policiais de escolta (Ferreira, Mendes e Nogueira) agora fazem pequenas rondas individuais e intercaladas **dentro do prédio** quando aguardam o comandante, em vez de ficar alinhados e imóveis. A convocação para patrulha interrompe imediatamente a rotina, os agentes caminham até a viatura e o retorno ao posto preserva o fluxo anterior. Esta versão é a **primeira etapa** do programa #29: trânsito pesado, balança e cenas COPOM com objetos, bem como expansão urbana, continuam em desenvolvimento pelas issues #30–33; não foram declaradas entregues nesta etapa.

## v2.15.0 — Inteligência individual para todos os NPCs e conversa local gratuita

- Policiais, seis cidadãos da recepção e 14 motoristas recebem **mentes individuais** com personalidade, percepção local, memória curta e seleção de objetivos por utilidade e prioridade — sem tráfego de dados para serviço externo.
- Motoristas reduzem sua velocidade pretendida ao perceber viatura com sirene ou fiscalização, preservando a lógica original de freios, distância e colisão; o sistema não toma controle da viatura do jogador.
- Ordens do comandante, blitz, embarque da escolta, atendimento e patrulhas permanecem prioritários; metas dos NPCs não alteram diretamente as ordens do sistema.
- **Conversar com NPC [N]** abre diálogos com policiais pelo rádio e cidadãos/motoristas próximos. Sem modelo de linguagem, há resposta contextual gratuita baseada em fatos e memória do jogo.
- **ATIVAR MODELO GENERATIVO LOCAL** é opção explícita. Usa `LanguageModel` disponibilizado por alguns navegadores de computador; quando compatível, permite respostas livres geradas no dispositivo, sem chave de API ou cobrança por token. O primeiro uso pode baixar um modelo volumoso. Outros navegadores e celulares podem não oferecer a API. Não existe promessa de que todos os NPCs rodem uma LLM simultaneamente.
- Nenhum modelo, conta, chave, serviço de backend ou dependência nova foi incluído; o recurso não oferece IA de voz e não registra conversas remotamente.

## v2.15.1 — Ajuste de digitação na conversa com IA local

Corrige o atalho N: durante uma conversa, a letra pode ser digitada normalmente no campo de texto sem fechar a janela. O Escape continua fechando o diálogo. Preserva a v2.15.0: inteligência para todos os 33 NPCs, memória individual, comportamento dos motoristas e modelo generativo local opcional.

## v2.16.0 — NPCs cooperam fisicamente por conta própria

- **Costa (recepção)** percebe quando há fila suficiente, caminha por uma rota interna até o ponto de apoio, presta atendimento por 12 s e retorna ao posto. Durante o apoio presente, o atendimento de outro agente acelera em 35% (desde que não haja uma ordem manual de reforço já ativa).
- **Lima (rádio)** reconhece evasão, chamado COPOM, chegada de reforço ou montagem da blitz. Ele se desloca até posição de comunicação, acompanha a situação, registra a iniciativa e volta ao posto.
- **Rocha (acesso ao pátio)** toma posição de sinalização na saída da base enquanto o COPOM está ativo ou ocorre uma evasão. Retorna fisicamente quando termina. Seu patrulhamento ou ordem explícita tem prioridade.
- **Memória e continuidade:** cada agente lembra o evento atendido e não repete a mesma iniciativa em loop. Apoios ficam registrados no Comando Geral [T], com contagem e nomes dos responsáveis.
- **Sem teleporte, custo de API, backend ou coleta de dados reais.** Rotas são limitadas à base e usam as mesmas verificações de presença e bloqueio dos agentes existentes; não se promete apoio presencial dentro da cena distante do COPOM nesta etapa.
- **Segurança:** ordens do comandante, pausa, tarefas humanas, conversa entre NPCs e embarque da escolta prevalecem. Testes unitários cobrem movimento, fila, retorno e interrupção.
