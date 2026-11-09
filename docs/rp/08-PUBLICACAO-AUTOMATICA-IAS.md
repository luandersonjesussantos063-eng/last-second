# Entrega contínua de melhorias das quatro IAs para o PRF RP

## Onde o jogo é publicado
- Código: https://github.com/luandersonjesussantos063-eng/last-second
- Jogo web: https://luandersonjesussantos063-eng.github.io/last-second/
- URL com utm_source é somente um endereço com parâmetro de rastreamento; use o URL acima, sem "main.js" anexado.

## Funcionamento do pipeline
1. Cada IA cria uma branch no mesmo repositório com prefixo ia-01/, ia-02/, ia-03/ ou ia-04/.
2. Para uma entrega **realmente jogável no navegador** (arquivos JS na raiz ou interface HTML), a IA incrementa SemVer em package.json e package-lock.json e sincroniza imports usando npm run stamp:release.
3. A IA cria um PR contendo a linha exata AUTO-PUBLICAR-WEB: SIM na descrição. Isso constitui uma autorização de publicação automática apenas para alterações que passarem nas verificações.
4. O workflow "Verificar e publicar PRF" roda no PR: node --check, npm test e npm run build:site.
5. O workflow "Publicar automaticamente melhorias aprovadas das IAs" só lê código confiável de main, verifica que o último commit do PR é o que passou nos testes, exige PR do mesmo repositório, diff restrito, versão maior, importações consistentes e pacote sem mudanças de dependências.
6. Se a verificação for aprovada, o PR é integrado automaticamente por squash.
7. **Importante:** merges executados com GITHUB_TOKEN não iniciam automaticamente eventos push. O publicador chama workflow_dispatch do workflow original na main para iniciar verificação e deploy do GitHub Pages.
8. Se a versão estiver desatualizada, houver conflitos, falhas de teste, scripts e dependências modificados, código em FiveM, assets binários ou arquivos sensíveis, o PR fica para revisão humana/gerencial. Não é entregue silenciosamente ao site.

## Documentação e FiveM
- PR somente de docs/rp/*.md pode usar AUTO-PUBLICAR-DOCS: SIM e ser integrado sem alterar a versão do jogo. Ele não adiciona uma mecânica jogável.
- Recursos fivem/ não são publicados no jogo web. Devem ser validados no host FiveM e revisados separadamente.
- Mudanças em workflows, scripts de build, package dependencies, assets de terceiros e arquitetura sensível nunca são mescladas automaticamente.

## Responsabilidades
- IA-01: registrar regras e escopo; quando houver implementação web, produzir PR com código; documentação apenas melhora o planejamento.
- IA-02: priorizar sistema do jogo web e abrir PR por funcionalidade; FiveM em PR próprio.
- IA-03: aprimorar mapa e visual do navegador; assets novos que precisem de licença devem ser revisados antes do merge.
- IA-04: aprimorar interfaces, UX e testes web; projetos FiveM em PR separado.
- Gerente: a cada relatório, comparar commits da main, execução CI, publicação GitHub Pages, versão visível e PRs bloqueados; corrigir incompatibilidades de versão com outro PR e não declarar publicação sem deploy concluído.

## Limitações técnicas
- GitHub Pages hospeda uma aplicação estática; serviços FiveM, voz multiplayer e bancos precisam de host/serviço próprio quando necessários.
- O publicador não garante que mudanças de código estejam livres de bugs visuais. Nunca confundir testes automatizados com teste manual no navegador.
- GitHub Actions pode sofrer atrasos, restrições de permissão e falhas de infraestrutura. Se ocorrer, gerente registra o bloqueio e faz correção rastreável.
