# PRF v2.10.0 — Rotina humana e troca de postos

Os policiais deixam de permanecer sempre em posição fixa e realizam atividades **durante a partida**, respeitando o serviço.

## Rotinas
- Beber água: deslocamento até bebedouros no prédio e no setor de fiscalização, gesto de beber e retorno sem teleporte.
- Banheiro: visita aos espaços de apoio sinalizados, pausa breve e privativa (NPC invisível apenas enquanto está no recinto), retorno pelo mesmo caminho.
- Troca de posto: cobertura temporária de setores e revezamento sincronizado entre Lima (rádio) e Rocha (vigilância).
- Escalas individualizadas: intervalos e ordem das atividades são diferentes por agente. A memória do turno registra os intervalos concluídos.
- Serviço prioritário: ordens do comandante interrompem a pausa; policiais de blitz não saem quando a fiscalização está montada; motopatrulha não faz pausa durante perseguições; atendimento ao público mantém cobertura.

## Implementação
Módulo `officer-life.js` define pontos de interesse, caminhos, máquina de estados (indo / pausa / voltando / em serviço), sequenciamento, cobertura e limites de concorrência. A integração em `command-sim.js` usa a posição do mesmo agente renderizado em `road-world.js`, sem duplicar avatares. Bebedouro e sanitário são objetos simples no cenário, não interiores de edifícios complexos.

## Escopo e limites
Funciona em modo navegador e GitHub Pages. Os NPCs **não** têm necessidades fisiológicas simuladas continuamente, nem diálogo generativo: as ações usam IA comportamental por estados e contextos. Ainda falta validação visual manual completa de colisões com veículos móveis e mobiliário em diferentes momentos da partida.

## Testes
`npm run check`, `npm test`, `npm run build:site`; cenários adicionais cobrem rotas estáticas, intervalos, banheiro, água, trocas, prioridade de ordens, motopatrulha e pausa do jogo.
