# Arquitetura técnica PRF RP

## Situação atual
- **Web:** Three.js + JavaScript em `main`, GitHub Pages, single-player com agentes locais, missões, viaturas e ciclo dia/noite. **Continuar suportando esse produto.**
- **FiveM:** em pré-produção; recurso piloto isolado em `fivem/resources/[prf]/prf_tablet/`. Ainda **não existe servidor FiveM configurado, hospedado ou testado em runtime** neste repositório.

## Direção
- Servidor FXServer gerenciado pelo txAdmin usando a receita **QBCore** mantida, em ambiente de teste separado.
- Banco MySQL/MariaDB de desenvolvimento com usuário de menor privilégio (conexões via configuração privada, nunca no GitHub).
- Lua para eventos de servidor/cliente; NUI HTML/CSS/JS para tablet/COPOM.
- Futuro MySQL/oxmysql, sincronização servidor-autoritativa e backups.
- Usuários com cargo PRF fictício `prf` e `onduty` validado no servidor antes de qualquer ação restrita.
- Não exigir login de governo real; APIs externas somente com autenticação, permissão e contratos válidos.
- Criar arquivos de recursos próprios; nunca distribuir texturas, modelos ou sons proprietários de terceiros sem direitos.

## Integração com GTA V
FiveM depende do cliente/jogo e de um servidor FXServer; **não é possível converter diretamente o jogo do navegador em GTA V RP**. Modelos do protótipo podem servir como referência conceitual, mas não implicam licença para importação. Reescrever interações para entidades e natives de FiveM.

## Organização
```
docs/rp/
  01-GDD.md
  02-ARQUITETURA.md
  03-EQUIPE.md
  04-ROADMAP.md
fivem/resources/[prf]/prf_tablet/
  fxmanifest.lua
  client.lua
  server.lua
  html/index.html
  html/style.css
  html/app.js
```

## Preparar host (dependência externa)
1. Cadastrar e manter Cfx.re e chave do servidor em **ambiente protegido**.
2. Baixar artefato FXServer suportado e iniciar txAdmin.
3. No txAdmin, implantar a receita QBCore oficial **numa pasta e banco vazios**.
4. Definir emprego `prf` no framework de teste com permissões corretas.
5. Copiar o recurso `prf_tablet` para `resources/[prf]` e adicionar `ensure prf_tablet` **após `qb-core`**.
6. Testar entrada, permissões, NUI e fechamento; rever logs e reiniciar.
7. Confirmar backup e rollback antes de acesso público.

## Regras de segurança e integração
- Toda permissão tem validação no servidor; cliente/NUI só pede, não autoriza.
- Respostas sempre são enviadas nos callbacks NUI, inclusive em falha.
- Habilitar `nui_callback_strict_mode 'true'` e usar URLs de callback do próprio recurso.
- Nenhuma informação sensível em logs da UI ou GitHub.
- Em multas, apreensões, rádio e inventário: usar autorização, cooldown, validação da entidade e auditoria no servidor.
- Não publicar scripts externos sem revisão de licença e segurança.

## Pipeline
- Pull request por funcionalidade; checagem de sintaxe, testes unitários e build do web.
- `main` publica apenas o site do simulador web; recursos FiveM **não** são publicados como um servidor FiveM no GitHub Pages.
- Publicação de FiveM requer host/txAdmin, testes em ambiente de staging, aprovação de dependências e rollback.

Referências:
- https://docs.fivem.net/docs/getting-started/setup-fivem-server/
- https://docs.fivem.net/docs/scripting-reference/resource-manifest/
- https://docs.fivem.net/docs/scripting-manual/nui-development/nui-callbacks/
- https://github.com/qbcore-fivem/txAdminRecipe
