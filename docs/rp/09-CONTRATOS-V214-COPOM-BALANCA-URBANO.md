# PRF RP — contrato jogável v2.14+ (IA-01, issue #30)

Status: **especificação de integração, NÃO gameplay entregue**. Base auditada: `main` 4e571960 (v2.14.0). Programa #29; entregas IA-02 #31, IA-03 #32 e IA-04 #33. Coordenadas em unidades do mundo Three.js, `x,z`; heading 0 = +Z. Todos os números de massa e limites são **ficcionais e configuráveis**, não normas brasileiras.

## 1. Escolta: estados e trajetos verificáveis

Fonte de verdade: `escort-sim.js`. IDs 18 Ferreira, 19 Mendes, 20 Nogueira. Estados da equipe: `idle → boarding → aboard → returning → idle`; `startEscort` tem precedência sobre pausa/tarefa, `stopEscort` fora da base mantém equipe na viatura. Em `idle`, somente destinos internos; não mover NPCs pela saída externa. Circuitos atualmente implementados:

- Ferreira: `[39.5,27.9] → [37.7,27.8] → [38.5,26.3] → [39.7,27.2]` (inspeção).
- Mendes: `[40.8,28.0] → [40.6,25.6] → [40.0,24.4] → [40.7,27.2]` (água).
- Nogueira: `[42.0,27.9] → [43.0,27.7] → [42.4,26.3] → [41.7,27.2]` (equipamentos).

Esses pontos são rotas existentes, **não** garantem interação animada com bebedouro/armário. Para tarefas físicas novas, definir `taskId`, `target`, `duration`, `animation` e `interruptible:true`, validar distância ao prop antes de tocar animação. Saída para embarque: `EXIT_ROUTE` existente, via `[40.5,27.8]`, `[35,9]`, `[26.5,-4]`, depois `VEHICLE_APPROACH` até cada porta. Verificar porta desobstruída, sem atravessar paredes ou agentes. Exatamente 3 assentos ocupados; ao voltar à base, retornar às posições de prontidão.

**Aceite:** em 60 s sem comando, 3 agentes completam circuitos distintos e permanecem dentro; convocar durante deslocamento interrompe rotinas e embarca exatamente três; desembarque dentro da base devolve os três; sair da viatura longe da base não os teleporta; testes desktop e celular.

## 2. COPOM: cena e estados

Estado atual `copom-sim.js`: `available → dispatched → on_scene → complete`, chamados fictícios `COP-001 (-9.3,-180)` e `COP-002 (-9.3,280)`. Hoje a conclusão exige apenas aproximar-se a <=10 unidades a pé e pressionar F: **ainda não comprova cena física**.

Contrato incremental: `incident={id,type,position,stage,sceneObjects[],requiredActions[],completedActions[],backupRequired,backupArrived}`. Estados propostos `available → dispatched → approaching → secured → interacting → resolved → complete`. Criar/destruir props conforme estágio e distância com id estável; nunca concluir só pela chegada. Exemplos:

- Veículo imobilizado: automóvel visível no acostamento em `(-9.3,-180)`, motorista NPC, triângulo/cones; aproximar com segurança, desembarcar, interagir com motorista, sinalizar e liberar/solicitar apoio.
- Objeto na pista: objeto 3D e cones em `(-9.3,280)`; isolar, inspecionar e remover objeto simulado, depois liberar pista.
- Carreta parada (novo tipo): carreta no acostamento, motorista, luzes de alerta; sinalizar, registrar situação e solicitar reforço; quando `backupRequired`, conclusão só após `escort.backup.stage === "onScene"` e ações necessárias.

**Aceite:** jogador vê objetos ao chegar; não há duplicação após novo despacho; F fora do raio não conclui; reforço ausente impede encerramento quando obrigatório; ao finalizar objetos não ficam obstruindo tráfego; histórico registra tipo, ações e desfecho fictícios.

## 3. Carretas e balança

`traffic.kind` atual não contém carreta; implementar `truck` com comprimento, largura, raio de colisão e distância de seguimento próprios. Modelos/implementos originais: baú, tanque fictício e plataforma, sem marcas. Não aplicar geometria de SUV a carreta. Caminhões devem desacelerar em acesso e parar antes de pesagem.

Contrato proposto `weighing={stage,vehicleId,weightKg,limitKg,toleranceKg,measuredAt,displaySerial}`; estados `idle → queued → entering → positioned → measuring → result → exiting → idle`. `weightKg` é dado **simulado** determinístico por veículo; `limitKg` e `toleranceKg` são parâmetros do cenário. Regra: `excessKg=Math.max(0,weightKg-limitKg-toleranceKg)`; `overLimit=excessKg>0`. Monitor e HUD leem **o mesmo objeto de estado**, mostram kg e `(weightKg/1000).toFixed(1)` t, com rótulo `SIMULADO`. Exemplo de teste: 51.600 kg = 51,6 t; limite fictício 50.000 kg e margem fictícia 1.000 kg → excedente 600 kg. Nunca chamar esses valores de limite legal.

**Aceite:** sem veículo posicionado não medir; leitura estável ao pausar; monitor 3D coincide com UI; entrada e saída não atravessam barreiras; segundo caminhão aguarda liberação; não registrar placa/CPF real.

## 4. Expansão urbana em trechos jogáveis

`ROAD_LIMIT=1490` e faixa principal `laneX(+1)=-3.4`, `laneX(-1)=3.4`; preservar rodovia e blitz existente `CHECKPOINT.stopZ=0`. Planejar 1º ramal urbano em trecho livre após validar colisões existentes, conectado por acesso explícito, com no mínimo 2 cruzamentos, 4 ruas navegáveis, calçadas, retorno, sinalização fictícia, tráfego que respeite prioridade e minimapa com rotas conectadas. 2º ramal só após testes do primeiro. Usar nomes fictícios e legenda `escala comprimida`, sem declarar quilômetros reais. Definir grafo `nodes:[{id,x,z}],edges:[{from,to,lanes,speedSimulated}]` e `spawnZones`; nunca apenas aumentar plano decorativo.

**Aceite:** sair da rodovia, atravessar dois cruzamentos, contornar um quarteirão e voltar sem atravessar prédios; NPCs circulam, colisões coerentes; não regressão de radar, COPOM, blitz, FPS em celular.

## 5. Handoff e sequência de implementação

- **IA-02 #31:** estados, interrupções, NPCs, caminhões e ações COPOM; testes de transição e idempotência.
- **IA-03 #32:** props 3D originais de incidentes, caminhões, plataforma/monitor e grafo urbano, com colisões e licença.
- **IA-04 #33:** painel de despacho, leitura da balança e histórico, UI e testes de navegador mobile/desktop.
- **IA-01 #30:** revisar entregas reais, conferir coerência dos contratos e documentar casos que falharem.

Checklist de integração: `npm run check`, `npm test`, `npm run build:site`, teste de navegador com prova de cena visível, sem regressão de 3 escoltas/blitz/radar/COPOM; versão SemVer incrementada por PR de gameplay e imports sincronizados. **Este documento não altera versão nem jogo publicado**. Merge e deploy somente após CI verde; declarar publicado somente com Pages confirmado.

## 6. Auditoria de integração — 10/11/2026, main v2.17.0

Esta seção é **posterior** ao levantamento v2.14 acima e não reclassifica os requisitos antigos como código entregue. Fonte conferida: `main@49bd8527a2f511c24d6f4210b3a7d23bcabdf71a`, `incident-sim.js`, `weighbridge-sim.js`, `escort-sim.js`. O workflow "Verificar e publicar PRF" desse SHA concluiu com sucesso; isso comprova CI, não inspeção visual manual nem confirmação de propagação do Pages.

### COPOM — diferença entre contrato e implementação

O fluxo físico implementado em `incident-sim.js` é `dispatched → arrival → secured → surveyed → towCalled → towReady → recovering → resolved` para veículo; para objeto: `dispatched → arrival → secured → surveyed → clearing → resolved`. O apoio progride `idle → enroute → onScene → deployed`; dois agentes saem do apoio e alcançam posições de sinalização. O jogador a pé usa F no raio de 13 unidades para isolar, ouvir/inspecionar e autorizar remoção. Há cena de guincho e liberação de objeto. **Carreta avariada como terceiro tipo COPOM ainda não está nesse contrato de execução**; não confundir carreta do tráfego com ocorrência de carreta.

**Teste de aceite adicional:** chamar COP-001, entrar na área, isolar, vistoriar, aguardar `support.stage=deployed`, solicitar guincho, autorizar e aguardar `resolved`, concluir pelo COPOM. Repetir com COP-002 sem guincho. Durante espera, tentar F fora do raio, pausado e dentro da viatura; nenhum deve pular etapa. Confirmar no navegador os objetos e os dois agentes; testes unitários não substituem essa inspeção.

### Balança — contrato real e dívida de design

`weighbridge-sim.js` implementa `ready → weighed → released → ready`, não o fluxo detalhado `queued → entering → positioned → measuring → result → exiting` originalmente proposto. A massa é determinística (`51600,40800,47250,43980` kg); `referenceKg=45000` é um parâmetro fictício inicial. O cálculo atual é `differenceKg=Math.max(0,grossKg-referenceKg)`: **a tolerância configurável ainda não foi implementada**. Não apresentar a regra de 50.000 kg + 1.000 kg do exemplo como se já fosse a regra jogável. O jogador pesa a pé, perto da balança, sem verificação explícita de caminhão posicionado em `weighbridgeActionLabel`; a carreta nasce sobre a plataforma no início. O monitor 3D e a UI devem ser conferidos para consistência de unidade.

**Critério para próxima entrega IA-02/04:** incluir `toleranceKg>=0`, `effectiveLimitKg=referenceKg+toleranceKg`, `excessKg=Math.max(0,grossKg-effectiveLimitKg)` e teste de fronteira em `grossKg=effectiveLimitKg` (sem excesso), `+1` (excesso 1 kg). Validar ação F somente com caminhão parado e alinhado; congelar massa ao pausar. Mostrar `SIMULADO` no monitor e no relatório.

### Escolta e expansão urbana

`escort-sim.js` contém três circuitos internos distintos, interrupção pela convocação, caminhada até as portas, embarque e retorno; **os textos de água/armário não provam uso físico dos props**. Teste de regressão: convocar durante a rotina de Mendes, embarcar três, desembarcar dentro da unidade, retornar ao `idle` e reiniciar rotinas sem duplicação. O PR urbano #45 está aberto: não contabilizar ruas novas como gameplay em `main` antes do merge, CI e teste de navegação.

### Registro de integração

PRs abertos na consulta: #36 (este documento), #39 (regressão da escolta), #45 (bairro urbano), #46 (QA da balança). Priorizar análise dos PRs de código e evitar duplicar alterações concorrentes. Para validar a publicação, conferir workflow de Pages associado ao SHA de `main` e abrir o link público; CI verde por si só não é garantia de que o navegador já serve a versão.
