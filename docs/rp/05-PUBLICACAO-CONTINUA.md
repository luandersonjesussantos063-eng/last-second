# PRF RP — Política de continuidade e publicação (decisão do diretor)
Atualizado em 2026-11-09.

## Diretriz aprovada
O projeto **continua no repositório atual** `luandersonjesussantos063-eng/last-second`. A equipe desenvolve e testa melhorias sem abandonar o jogo que já está publicado em:

- Repositório: https://github.com/luandersonjesussantos063-eng/last-second
- Jogo web: https://luandersonjesussantos063-eng.github.io/last-second/

A eventual necessidade de hospedar serviços multiplayer **não implica mudar de repositório GitHub**. Evitar migração prematura ou reinício do projeto.

## Linha de evolução
1. **Agora — jogo web (Three.js / GitHub Pages):** aprimorar NPCs, IA de comportamento, animações, ambiente, missões, interface, física simplificada e sistemas jogáveis no navegador; manter experiência de desktop e mobile.
2. **Em paralelo — FiveM experimental:** manter recursos em `fivem/` para testes e revisão; não afirmar que a pasta `fivem` publicada no GitHub Pages representa um servidor FiveM funcional.
3. **Quando exigido por funcionalidades concretas:** provisionar host de jogo/servidor, autenticação, banco de dados e sincronização de estado; validar custos, licenças, segurança e backups antes de ativar.
4. **Transição gradual:** conservar o protótipo web e o histórico do GitHub. Integrar ou migrar apenas as partes que efetivamente precisarem rodar no servidor, mediante aprovação do proprietário.

## Critérios para considerar infraestrutura externa
Um recurso exige processamento de servidor persistente (ex.: mundo multiplayer em tempo real, chat/rádio, contas e banco compartilhado, simulação de jogadores online, serviços que rodem fora do navegador). GitHub Pages é hospedagem estática e não executa FXServer; isso é uma limitação de execução e **não significa que o GitHub deixou de suportar nosso código**.

## Fluxo de entrega e segurança
- Cada especialidade trabalha por issue/branch/PR no mesmo repositório.
- Rodar CI (`npm run check`, `npm test` e `npm run build:site`) e corrigir falhas antes de integrar.
- Publicar o jogo web pela rotina de GitHub Actions somente após testes.
- Confirmar que o deploy finalizou com sucesso e registrar commit e link. Testes em ambiente FiveM devem ser descritos separadamente.
- Bugs críticos bloqueiam lançamento, nunca usar correções que encubram erros ou desativem segurança.
- Se o site não incorporar uma funcionalidade específica por limite técnico, explicar o motivo, registrar alternativa e obter aprovação antes de alterar a estratégia.

## Responsabilidades
- IA-01: manter o planejamento compatível com evolução contínua do jogo web.
- IA-02: aprimorar o código web jogável e preparar FiveM paralelamente.
- IA-03: evoluir assets e desempenho web; preparar assets próprios/licenciados para FiveM.
- IA-04: melhorar UI web, NUI do futuro FiveM e testes de regressão.
- Gerente: a cada relatório, separar explicitamente *jogo web publicado*, *PR aberto*, *recurso FiveM de laboratório* e *dependência externa*.

Decisão: **continuar aqui, publicar melhorias de forma segura e não trocar hospedagem/plataforma antes de haver necessidade real.**
