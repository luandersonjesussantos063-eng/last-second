# IA-01 — Aceite operacional v2.21 (issue #30, programa #29)

Data da auditoria: 2026-11-10. Base observada: main `387c2d72d7a4ba67315402dee71250a38784e9f0`, package.json `2.21.0`.
Este documento registra comportamento **implementado em código**, pendências e roteiros de aceite. Não certifica que o Pages esteja servindo este SHA.

## Matriz de estados e verificações

| Sistema | Código observado | Critério para aceite manual e automatizado |
| --- | --- | --- |
| Escoltas Ferreira/Mendes/Nogueira | `escort-sim.js` | Cada agente permanece no prédio, com circuitos próprios, enquanto o comandante não embarcar. Convocação interrompe pausa e hidratação. Após desembarque, retoma rota interna sem duplicar ator. |
| COPOM | `copom-sim.js`, `incident-sim.js` | COP-001 (pane), COP-002 (objeto), COP-003 (colisão) e COP-004 (carreta) devem gerar objetos físicos distintos; nenhum pode concluir antes das ações obrigatórias. Testar a pé, dentro da viatura, pausado e fora do raio. |
| Carretas | `traffic-operations.js` | Implementos visíveis na pista e na aproximação da balança, distância de frenagem adequada, colisão com largura real do implemento e redução de velocidade na cena COPOM. |
| Balança | `weighbridge-sim.js` | Sequência `ready → weighing → weighed → released → waiting → approach → ready`; medir apenas parado/alinhado; congelar na pausa; massa kg e t idêntica no HUD, monitor e relatório; liberar sem excesso ou reter com excesso simulado. |
| Bairro | `urban-layout.js` | Entradas e saídas da rodovia, cruzamentos transitáveis, obstáculos coerentes, sem teletransporte e sem bloqueio do retorno à base. |

## Defeito de UX verificável — balança

`weighbridgeActionLabel(s)` oferece **PESAR CAMINHÃO** no estado `ready` quando o jogador está perto, mesmo se a carreta não estiver alinhada ou parada. `interactWeighbridge(s)` então retorna `false` silenciosamente. Isso parece botão quebrado.

**Contrato mínimo:** introduzir `canStartWeighing(s)` compartilhado pela UI e pela ação, exigindo `stage === "ready"`, carreta visível, distância ao centro da plataforma <= 0,3 m, velocidade <= 0,1 m/s e orientação dentro da tolerância visual. Se a UI optar por exibir botão desabilitado, explicar qual requisito falta. O teste deve mover a carreta 1 m, verificar ausência de ação, reposicionar e verificar início de pesagem; a simulação não pode avançar quando pausada.

## Regra de peso fictícia — versão a implementar

O código atual usa `differenceKg = max(0, grossKg - referenceKg)`. Isso **não** representa tolerância configurável. Proposta de contrato sem pretensão legal:

```js
referenceKg = 48500; // exemplo interno, nunca limite legal
toleranceKg = 500; // parâmetro do cenário, >= 0
effectiveLimitKg = referenceKg + toleranceKg;
excessKg = Math.max(0, grossKg - effectiveLimitKg);
tonnes = grossKg / 1000;
```

Casos: 49.000 kg -> 0 kg de excesso; 49.001 kg -> 1 kg; 51.600 kg -> 2.600 kg. Relatório, monitor e histórico devem indicar **SIMULAÇÃO FICTÍCIA**. Mudança de configuração deve ser aplicada ao próximo veículo, nunca alterar retroativamente pesagens registradas.

## Contrato COPOM com objetos

| Chamado | Objeto | Interações obrigatórias | Resultado |
| --- | --- | --- | --- |
| COP-001 | automóvel imobilizado, condutor, cones, apoio, guincho | chegar, isolar, ouvir, aguardar apoio, chamar guincho, autorizar remoção | acostamento desobstruído |
| COP-002 | objeto na faixa de segurança, cones, apoio | chegar, isolar, avaliar, aguardar apoio, remover | objeto invisível após retirada |
| COP-003 | dois veículos avariados, vítima fictícia, apoio, resgate | proteger local, avaliar vítima, solicitar apoio/resgate, liberar veículos somente após atendimento | nenhum encerramento precoce |
| COP-004 | carreta com implemento, condutor, cones, apoio, guincho pesado | isolar, avaliar pane, apoio, remoção compatível com comprimento da carreta | sem atravessar guarda-corpo ou trânsito |

Critério visual: o veículo de apoio deve **chegar fisicamente**, parar, permitir que dois agentes desembarquem e assumam postos. A remoção não deve desaparecer instantaneamente ao pressionar F. Não utilizar identidade ou cadastro real de pessoas.

## Especificação mínima do distrito

O bairro é um mapa comprimido fictício. Usar `urban-layout.js` como fonte única de faixas e colisões. Rotas de aceite: **base → acesso rodoviário → rua principal → cruzamento → rua secundária → retorno à BR → base**. Verificar em desktop e celular; caminhões não podem ocupar o mesmo espaço que NPCs. Os limites físicos precisam coincidir com os limites usados por `urbanDriveableArea` e `urbanWalkableArea`.

## Handoff

- IA-02: alinhar estado e interação da balança; preservar regressão das escoltas (#47).
- IA-03: testar cenas COP-003/004 e geometria das carretas e ruas (#45).
- IA-04: exibir estado e bloqueio da pesagem, garantir HUD/monitor coerentes (#48).
- IA-01: revisar PRs, testes e link público; documentação e CI não são prova de publicação.
