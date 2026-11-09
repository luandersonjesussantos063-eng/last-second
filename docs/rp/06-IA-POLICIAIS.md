# PRF v2.9.0 — Primeira IA dos policiais

## Tipo de IA
**IA comportamental local**: avaliação de sinais do simulador e seleção de prioridades, memória curta e diálogos contextuais. Não há modelo de linguagem externo, áudio generativo ou conexão com servidor. Tudo funciona no GitHub Pages, offline após carregar os recursos.

## Capacidades entregues
- Perfil de comportamento diferente por policial (comunicação, vigilância, atendimento, motopatrulha).
- Observação de eventos simulados: blitz em preparação/operação/desmontagem, evasão, reforço e fila de atendimento.
- Memória por policial: até seis acontecimentos recentes durante **a partida atual**. Não grava dados pessoais, placas reais ou histórico em servidor.
- Escolha de ações e textos contextualizada por função, plantão e estado da ocorrência, com intervalos por agente.
- Diálogos de Lima/Rocha e Santos/Oliveira deixam de ser só três frases fixas; escolhem assuntos relacionados a ocorrências recentes.
- Prioridade absoluta de ordens do comandante e sistemas já existentes; NPCs não iniciam fiscalizações, perseguições ou buscas governamentais não autorizadas.
- Perfis e últimas memórias visíveis no painel de comando para o comandante.

## Limites atuais
- São decisões por regras/avaliação de contexto, **não** conversas abertas com LLM.
- Os policiais não aprendem com treinamento externo; memórias somem quando a partida é reiniciada.
- Não inserimos dados de cidadãos reais, não usamos API policial governamental.
- Próximas etapas possíveis: percepção por distância/campo de visão, navegação com desvio de obstáculos, diálogo por voz e memória persistente protegida.

## Testes
`npm run check`, `npm test`, `npm run build:site`, além dos cenários de prioridade das ordens, eventos, memória limitada e variação de diálogo.
