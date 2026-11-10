# IA-01 — Operação COPOM: veículo imobilizado no acostamento

**Escopo:** ocorrência inteiramente fictícia para o simulador web PRF RP, sem qualquer integração governamental. Relacionada à [issue #21](https://github.com/luandersonjesussantos063-eng/last-second/issues/21), com implementação inicial planejada na [#22](https://github.com/luandersonjesussantos063-eng/last-second/issues/22) e UI na [#24](https://github.com/luandersonjesussantos063-eng/last-second/issues/24).

## Objetivo da primeira versão jogável
O comandante recebe um chamado do COPOM por veículo imobilizado no acostamento. Deve aceitar a chamada no painel [T], dirigir-se ao trecho do mapa, estacionar em segurança, sair da viatura e sinalizar o atendimento perto do marco. O rádio informa conclusão e armazena um histórico curto do turno.

## Etapas e estados testáveis
1. **Aguardando** — painel [T] oferece `ACEITAR CHAMADO`. Sem iniciar sozinho ou impedir a fiscalização já existente.
2. **Despachado** — recebe destino, quilometragem fictícia e distância, marcado no HUD. É possível continuar outras ações. Não há multa nem policial civil real.
3. **No local** — comandante chega a até 22 m do destino; recebe orientação para parar e desembarcar.
4. **Atendimento** — comandante a pé, perto do local, pressiona F, recebe uma confirmação de apoio fictício e encerra a ocorrência.
5. **Concluído** — o histórico do painel contabiliza atendimento, mantém registro fictício e permite receber outro chamado quando implementado.

## Diálogo de rádio (exemplos)
- COPOM: “Unidade, recebemos um veículo parado no acostamento. Verifique a segurança do local.”
- Comandante: “Recebido. Equipe em deslocamento.”
- Agente: “Trecho sinalizado. Sem feridos informados.”
- COPOM: “Ocorrência encerrada. Registro fictício efetuado.”

## Regras e riscos
- Não incentivar estacionar no meio da pista ou atropelar barreiras.
- Não usar nome, documento ou placa de cidadão real.
- Sem violência, perseguição, mandado ou penalidade automática nessa ocorrência.
- Reforço e blitz existentes não podem ser apagados nem atrasados.
- A chamada deve permanecer na sessão atual; não alegar persistência na nuvem.
- O botão não pode ficar ativo quando já há uma chamada em andamento.
- Todos os textos fornecidos pelo simulador são tratados como texto, sem injeção HTML.

## Critérios de aceite visíveis
- Abrir T, aceitar e visualizar destino.
- Ir ao local, parar, desembarcar e pressionar F para finalizar.
- Ver contagem e registro de conclusão no painel.
- Testes: não aceita duas chamadas iguais; não conclui fora do local, dirigindo, com jogo pausado ou inspeção aberta; pausa congela tempo.
- Build do jogo no GitHub Pages após PR web testado e versão SemVer superior à main.

**Definição de pronto:** a documentação não conta como entrega jogável; requer PR de código vinculado às issues #22 e #24 e publicação do Pages confirmada.
