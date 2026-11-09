# PRF RP — Game Design Document (GDD) v0.1

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
