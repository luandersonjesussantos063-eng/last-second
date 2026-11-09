# Squad de desenvolvimento PRF RP

## Direção
- **Proprietário / Diretor do produto:** usuário; decisões sobre nome, orçamento, hospedagem, regras finais e lançamento.
- **Coordenação técnica:** ChatGPT, com histórico rastreado por issues, commits e PRs no GitHub.
- **Gerente de qualidade:** função de supervisão e relatórios recorrentes. Relatórios NÃO substituem testes em FiveM.

## Quatro especialidades de IA (frentes de trabalho)
| Trilha | Escopo | Primeira entrega verificável |
| --- | --- | --- |
| IA-01 — GDD/PM | Lore, regras, career loop, missões, backlog e riscos | GDD v0.1 e critérios de aceite |
| IA-02 — Backend/FiveM | Lua, validações servidor, estados, SQL e integração QBCore | recurso piloto PRF Tablet com permissão |
| IA-03 — 3D/Map | Sede, viaturas, fardas, otimização e licenças | inventário de assets necessários e mapa funcional planejado |
| IA-04 — Frontend/QA | NUI, acessibilidade, COPOM, design, testes de uso | NUI protótipo do tablet e testes da interface |

Essas trilhas **não são quatro funcionários humanos ou processos permanentemente executando**: somente sessões/automações configuradas e ferramentas conectadas podem executar trabalho em horários definidos.

## Regras de execução
1. Cada demanda deve virar issue com responsável/trilha, critério de aceite, dependências e risco.
2. Cada mudança de código entra em branch própria e pull request; o CI precisa passar.
3. Bugs críticos bloqueiam merge/deploy; nunca “corrigir de qualquer jeito”. Corrigir causa, testar, e registrar evidência.
4. Separar desenvolvimento web do novo FiveM; não apagar o protótipo.
5. Nenhum segredo, dados reais de cidadãos nem chaves de servidor em arquivos versionados.
6. Não declarar funcionamento em runtime FiveM sem servidor e teste real.
7. A gerente verifica a cada cinco horas (quando a automação estiver ativa): commits, PRs, CI, erros, tarefas concluídas, bloqueios, próximo alvo.
8. Ciclos recorrentes executam trabalhos limitados; não representam desenvolvimento contínuo garantido.

## Definição de concluído (DoD)
Código revisável + teste automatizado verde + demonstração do comportamento onde disponível + risco documentado + link do commit/PR + rollback conhecido.
Para liberar produção FiveM: testes manuais em servidor, permissões, persistência e moderação funcionando.

## Convenções
- Issues: `[IA-01]`, `[IA-02]`, `[IA-03]`, `[IA-04]`, `[GERÊNCIA]`.
- Branches: `feat/prf-rp-...`, `fix/prf-rp-...`.
- PRs nunca escondem quebra de teste; indicar `tested`, `not-tested`, `blocked` explicitamente.
