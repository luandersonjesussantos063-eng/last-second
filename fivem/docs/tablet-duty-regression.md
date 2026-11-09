# PRF Tablet — roteiro de regressão (ambiente fictício)

Esta alteração não depende de dados reais. Execute em FXServer de desenvolvimento com QBCore, `qb-core` e `prf_tablet` iniciados, com personagens fictícios.

1. Civil: `/prftablet` deve ser negado pelo servidor e não abrir NUI.
2. PRF fora de serviço: comando deve ser negado.
3. PRF em serviço: comando deve abrir tablet e permitir fechar pelo botão NUI.
4. Com tablet aberto, mudar `onduty` para `false` via fluxo legítimo QBCore: NUI fecha e foco de mouse/teclado é liberado.
5. Com tablet aberto, trocar job para civil: mesmo resultado.
6. Com tablet aberto, descarregar personagem (`QBCore:Client:OnPlayerUnload`): mesmo resultado.
7. Com tablet aberto, reiniciar recurso: foco liberado; novo comando exige autorização do servidor.
8. Repetir comando rapidamente: servidor mantém limite de solicitações; não abre sessões duplicadas.

**Limite de segurança:** fechamento na interface é defesa de experiência, não autorização. Qualquer nova operação de escrita deverá validar job, serviço e payload novamente no **servidor**. O evento `prf_tablet:open` não concede permissão de executar ações.

**Ainda não executado:** testes reais exigem FXServer, client FiveM e QBCore em ambiente de desenvolvimento aprovado. Não configurar credenciais ou dados de produção no repositório.
