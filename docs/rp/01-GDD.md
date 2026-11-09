# PRF RP — Game Design Document (GDD) v0.2

Estado: rascunho de pré-produção | Dono do produto: diretor do projeto | Atualizado: 2026-11-09

## Visão e diferenciais
Simulador de interpretação de papéis (RP) inspirado no policiamento rodoviário brasileiro, com operações cooperativas, civis, tráfego, chamadas dinâmicas, decisões com consequências e progressão. O objetivo é qualidade de experiência comparável à ambição de comunidades GTA RP, sem afirmar equivalência gráfica ou funcional já existente.

**Dois produtos distintos**: o simulador web atual (Three.js, single-player, publicado no GitHub Pages) continua funcionando; a futura instância FiveM é um produto separado que dependerá de um servidor GTA V compatível. Não portar arquivos de GTA V para o navegador.

## Experiência do jogador (loop)
1. Entrar no servidor com personagem fictício; receber turno e posto designados.
2. Consultar escala e chamadas, registrar início de serviço e equipar uniforme autorizado.
3. Escolher patrulhamento, fiscalização, atendimento, comunicação ou gestão.
4. Executar interações por regras verificáveis: abordagem, documentação fictícia, orientação, multa simulada, remoção e conclusão.
5. Preencher relatório, retornar ao posto, avaliar resultados, progredir na carreira.
6. Fora de serviço: participar como civil; missões nunca exigem conduta criminosa.

## Carreira ficcional do jogo
Os seguintes graus são **níveis de jogo, não patentes oficiais da PRF**:
Recruta (tutorial) → Agente (ocorrências assistidas) → Patrulheiro (patrulha autônoma) → Supervisor (coordena até uma equipe) → Coordenador (administra operações).
Progressão por participação, registro correto, treinamento e avaliação por pares; vedado sistema de pontos que premie infrações arbitrárias ou abordagens abusivas. Escalas por turnos e plantões; comandante não substitui permissão administrativa do servidor.

## Profissões e RP civil
Civis com entregas, transportes, viagens e atendimentos; equipes de resgate e mecânica. Facção criminosa ou perseguições somente com regras claras e consentimento da comunidade; nenhuma missão ensina crimes reais. NPCs para preencher mundo quando não há jogadores.

## Mecânicas prioritárias
- Radar e multa **fictícios**, com registro e possibilidade de contestação.
- Consulta fictícia local; jamais vender integração real com DETRAN, antecedentes ou governo sem contrato/API/autorizações.
- Garagem autorizada e viaturas por função; manutenção e abastecimento.
- Rádio com canais por equipe e permissão; gravação/log somente conforme políticas do servidor.
- Barreiras, sinalização, apreensão e guincho com cooldown e remoção de objetos para evitar congestionamento.
- COPOM: fila de chamados, prioridades, atribuição, encerramento e auditoria.
- NPCs com agenda e resposta contextual, pathfinding, sem atravessar paredes.
- Economia e reputação RP proporcionais; persistência e rollback contra duplicações.

## Regras de comunidade (proposta para aprovação)
- Safe zones: spawn, hospital, áreas de entrada/saída de serviço; sem agressão ou furto nestas zonas.
- Proibido metagaming, powergaming, antijogo, exploração de bugs, assédio e perseguição de jogadores.
- Abordagens precisam de justificativa dentro do RP; direito a defesa/contestação no sistema.
- Corrupção policial **desativada** no alfa; eventual RP de corrupção somente com regras e moderação explícitas.
- Não usar dados reais de pessoas, placas reais associadas a identidade, CPF real nem consulta governamental sem autorização.
- Moderação e apelações separadas do comando da PRF; logs auditáveis com retenção definida.
- Nome, uniformes e marcas oficiais: verificar autorização/licenciamento e adotar identidade fictícia se necessário.

## Critérios de aceite do primeiro marco jogável FiveM
- Servidor de desenvolvimento inicia com txAdmin sem erros críticos; login e personagem persistem no banco de teste.
- Jogador com emprego PRF autorizado entra em serviço e abre tablet; jogador civil não acessa dados policiais.
- Tablet mostra ocorrências **de teste**, permite fechar com Escape e não consulta dados reais.
- Comandos e eventos são validados no servidor (não confiar na NUI).
- Uma operação simulada é concluída e gravada em banco de teste; testes e plano de rollback documentados.

## Fora de escopo do primeiro marco
Mapa completo do Brasil, integração governamental real, assets de GTA distribuídos, economia complexa, aplicativo móvel externo, servidores públicos antes de testes e moderação.

## Medição de qualidade
Acompanhar: crash de recursos, lag de servidor, FPS client, bugs críticos, retenção em sessões, taxa de chamados concluídos, tempo de onboarding e avaliações da comunidade. Não inferir taxa de sucesso sem telemetria.

## Proposta de operação dinâmica de blitz (protótipo web; aprovação pendente)
A blitz **não funciona 24 horas**. Cada dia simulado sorteia uma janela de início e duração, usando relógio do jogo e semente reproduzível em testes; a agenda é interna e não corresponde a operações reais. Estados: `inativa → mobilização → montagem → ativa → encerramento → inativa`. Na montagem, agentes deslocam-se até o ponto, estacionam viaturas e instalam cones em sequência; só então podem parar civis. No encerramento, deixam de selecionar novos veículos, liberam com segurança qualquer veículo já em atendimento, recolhem cones e retornam viaturas. Não remover objetos sob veículos nem bloquear o único acesso à base. Exibir o estado e a previsão aproximada no HUD, sem prometer horário exato.

**Critérios de aceite web:** (1) em um dia simulado completo existe período sem blitz; (2) a mesma semente produz a mesma janela; (3) cones e viaturas mudam de estado visivelmente na montagem/desmontagem; (4) nenhuma nova fiscalização começa no encerramento; (5) fiscalização em curso termina sem perder o histórico; (6) pausa congela cronograma e animações. Limite inicial: uma operação por dia; alterações de probabilidade e duração dependem de playtest.

## Proposta de patrulha do comandante e reforço (protótipo web)
Ao embarcar na viatura da equipe, o comandante aciona o agrupamento de **três NPCs** disponíveis. Eles caminham até as portas, ocupam três assentos e só após o embarque completo a patrulha pode partir. Se faltar agente ou houver caminho obstruído, mostrar o motivo e permitir cancelar sem teletransportar NPCs. Desembarque e retorno à base liberam os assentos e restauram as funções anteriores. O pedido de reforço pelo rádio cria uma ocorrência fictícia com cooldown, uma viatura de apoio disponível e estado de despacho → deslocamento → chegada → liberação; não gera agentes ilimitados.

**Critérios de aceite web:** (1) exatamente três acompanhantes embarcam, além do comandante; (2) ocupação visível e estado consistente ao entrar/sair; (3) reforço só pode ser solicitado durante patrulha ou ocorrência; (4) não duplica viatura ao solicitar repetidamente; (5) não atravessa objetos nem quebra a missão principal; (6) HUD explica indisponibilidade. Aumentar o mapa por trechos navegáveis, com limites, colisões, tráfego e minimapa sincronizados; evitar apenas ampliar terreno decorativo.

## Três fluxos RP completos para revisão do diretor
**Fluxo A — fiscalização sem infração:** início do turno → despacho de blitz → montagem segura → sinalização e parada de veículo fictício → conferência de documentos simulados → orientação → liberação → relatório de serviço → desmontagem. Falha aceitável: pista ocupada adia manobra; nunca força colisão. Aceite: relatório registra decisão e veículo liberado, sem consulta externa.

**Fluxo B — patrulha com reforço:** comandante recebe chamado fictício → convoca três agentes → embarque sequencial → deslocamento → pedido de reforço pelo rádio → apoio despachado com limite de unidades → atendimento sem violência obrigatória → encerramento → retorno e desembarque. Falha aceitável: apoio indisponível gera mensagem e não cria unidade fantasma. Aceite: quatro ocupantes totais na viatura do comandante e no máximo um reforço ativo por chamado.

**Fluxo C — atendimento civil e contestação:** civil fictício relata situação na recepção → registro de ocorrência com protocolo local fictício → atribuição a equipe → abordagem respeitosa e decisão simulada → cidadão pode contestar → revisão por papel independente do agente que registrou → decisão e fechamento auditáveis. Falha aceitável: sessão interrompida no web single-player não implica persistência online. Aceite: nenhum CPF real, placa real identificável ou integração governamental; texto distingue claramente simulação de autoridade pública.

**Limites de entrega:** estes são requisitos e critérios propostos, não funcionalidades já implementadas. O GitHub Pages executa cliente web estático e não fornece por si só servidor persistente, autenticação multiplayer ou moderação. Nenhuma mecânica acima deve ser anunciada como publicada antes de implementação, testes e merge. Regras de comunidade e uso de identidade visual dependem de aprovação do diretor.
