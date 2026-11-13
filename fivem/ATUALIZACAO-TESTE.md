# Atualização de teste — base, operações e Favela Realista

## Instalar

1. Pare o servidor no txAdmin.
2. Extraia o ZIP completo desta branch do GitHub.
3. Abra `fivem/scripts/setup-prf-update.cmd`. O perfil padrão é `C:\txData\FiveMBasicServerCFXDefault_F3288B.base`; ajuste `SERVERDATA` no CMD se o seu caminho for diferente.
4. O instalador atualiza a base com interior, o core e a Favela Realista, valida integridade e guarda backups em `_prf_backups`, fora de `resources`. As permissões ACE e os outros recursos são preservados.
5. Inicie o servidor e feche/reabra o FiveM. Confira primeiro a base e depois a favela.

Essa versão restaura o interior da base com o tipo de instância MLO e os limites ajustados. A variante exterior anterior permanece em `fivem/diagnostics` para reversão caso o travamento volte. Ainda não há validação gráfica dentro do GTA neste ambiente.

## Jogar

- O personagem nasce na entrada da base ao conectar e ao reaparecer. O piso é conferido antes de soltá-lo. Se o mapa estiver parado ou o piso não carregar, o posto de Sandy Shores continua como alternativa. O nascimento não concede permissão policial; F5 continua exigindo o ACE individual.
- F5 inicia o serviço. Os três colegas mantêm fuzil em mãos a pé e o guardam embarcados. K equipa/guarda o fuzil do jogador; L e O continuam controlando giroflex e sirene.
- **F11** abre operações: abordar o carro à frente, documentos, revista, liberar, guincho, reforço, cones da blitz e rondas. F6 mantém o menu original; os dois menus não ficam abertos juntos.
- Para abordar, aproxime-se e olhe para o veículo. Espere o condutor NPC encostar e desembarque para fiscalizar. Documentos e conteúdo da revista são fictícios. Um motorista jogador precisa colaborar com a parada.
- O guincho aguarda o carro parado e os jogadores desembarcados. O reforço traz uma viatura com dois policiais. NPCs e veículos criados pelas operações são limpos ao terminar serviço ou parar o recurso.
- As rondas marcam os pontos no GPS e exigem chegada física. Algumas têm confronto; a missão de apoio sob ataque tem confronto garantido. Não concedem dinheiro, itens ou acesso a dados reais.
- `/prffavela` marca a Favela Realista. Ela mantém até 12 integrantes de gangue próximos, sem recriar os 64 do Map Editor de uma vez. O menu F11 inclui ronda nessa região, além de Davis e Rancho.
- `/prfcancelarronda` encerra a ronda atual. `/prfabordar`, `/prfdocumentos`, `/prfrevistar`, `/prfguincho`, `/prfreforco` e `/prfblitz` também estão disponíveis.

O arquivo `55916f-Favela 01.rar` ultrapassou o limite de transferência e não foi integrado. Esta entrega usa o ZIP posterior `Favela Realista BETA 1.0`.

## Limites do teste

Não foi executado FXServer/GTA V neste ambiente. Testes de código e integridade não garantem estabilidade gráfica. O sistema é standalone, sem inventário ou banco de dados; documentos, revista e remoção são simulações. A população ambiente da favela é local ao cliente. O mapa e a roupa personalizados precisam estar iniciados; a autorização ACE individual permanece obrigatória para o serviço.
