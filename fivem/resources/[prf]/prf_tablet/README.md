# PRF Tablet • prova de conceito FiveM

Recurso próprio, inicial, **não publicado em servidor** e sem integração governamental ou dados reais. Não altera nem substitui o jogo de navegador. Interface NUI de demonstração e duas ocorrências fictícias.

## Requisitos
FXServer/txAdmin rodando em ambiente de desenvolvimento e QBCore com um **job de teste chamado `prf`**. O jogador precisa ter `job.name = prf` e `job.onduty = true` para o servidor permitir a abertura. É necessário criar/configurar esse job no servidor de desenvolvimento; não existe neste repositório.

## Instalação (depois de configurar o servidor)
1. Copiar `prf_tablet` para `resources/[prf]/`.
2. Adicionar `ensure prf_tablet` depois de `ensure qb-core` em `server.cfg`.
3. Reiniciar o servidor; como personagem PRF em serviço, digitar `/prftablet`.
4. Abrir o tablet, conferir os chamados fictícios, fechar com Esc ou X.
5. Repetir como civil/fora de serviço: deve negar acesso.
6. Testar reload do resource e verificar liberação do foco NUI.

## Segurança
Servidor valida o job e a escala antes de enviar as informações; não há ações privilegiadas via NUI. Acesso limitado por intervalo, NUI callback strict mode ativo, sem PII ou chaves em arquivos. **Ainda faltam testes no runtime FiveM**, auditoria de permissões, integração SQL, limites de abuso e QA multiplayer antes de qualquer uso real.
