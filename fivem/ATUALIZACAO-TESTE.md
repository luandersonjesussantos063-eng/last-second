# Atualização 0.7.0 — base, apreensões, progresso e operações

## Instalar

1. Pare o servidor no txAdmin e extraia o ZIP completo desta atualização.
2. Entre em `fivem/scripts` e abra **`setup-prf-update.cmd`**.
3. Aguarde terminar, inicie o servidor e feche/reabra o FiveM.

O perfil padrão é `C:\txData\FiveMBasicServerCFXDefault_F3288B.base`. O instalador preserva a permissão ACE, mantém sua Trailblazer completa ou instala a Equinox incluída, verifica os arquivos e faz backup em `_prf_backups`, fora de `resources`. Não é preciso reinstalar GTA ou FXServer.

## O que mudou

- **Base:** a colisão original do interior foi incorporada ao modelo e registrada no YTYP. A entrada recebe uma porta física que abre por aproximação; `porta` também abre/fecha. O nascimento procura um acostamento externo com chão e colisão verificados. Se a base não carregar, tenta Sandy Shores; se nenhum piso for seguro, preserva a posição anterior e destrava o personagem.
- **Favela:** os integrantes patrulham, reagem à aproximação policial armada, tiros ou agressão; alguns fogem e outros combatem. Quem estiver rendido, algemado ou acompanhando o policial mantém a ordem recebida, inclusive no transporte para fora da favela. Limite de 12 integrantes locais, criados aos poucos.
- **Revista real do NPC:** verifica suas armas nativas, retira o material e salva armas e munições no seu inventário. A munição compartilhada entre duas armas conta uma vez. Se não conseguir salvar, tenta devolver o material retirado. O porta-malas só informa itens efetivamente registrados: não inventa mercadoria aleatória. Para recolher a arma de um motorista, mande descer, aborde a pessoa e use `revistar`.
- **Progresso:** apreensões, munições, prisões entregues e totais de ocorrências/rondas são salvos automaticamente por jogador no KVP do FXServer. `salvar` grava novamente; `progresso`, `inventario` e `prisoes` consultam o registro. Atualizar os recursos não apaga esse armazenamento. Preserve a pasta de dados do servidor ao fazer backup ou mudar de máquina. Personagens, veículos, abordagens, missões em andamento, vida e turno não são restaurados: o jogador continua nascendo na base.
- **Cones:** digite `cone` ou `blitz`, segure **Z ou botão direito**, aponte para o chão e **clique esquerdo** para colocar cada cone. `guardarcone` encerra a colocação; `recolhercones` retira os colocados. Até 60 cones por blitz. A equipe sinaliza o trânsito, faz segurança e acompanha o carro parado. Com dois cones ou mais, um motorista próximo é selecionado por vez para fiscalização; permanece retido até sua liberação.
- **Tablet:** `documento` e `antecedentes` abrem a consulta com um tablet na mão. **Esc fecha**. Abas de inventário, progresso e chamadas de apoio. Ações de abordagem continuam no T.
- **Serviços:** `ambulancia` chama socorro e recupera a saúde; `mecanico` envia reparo ao veículo próximo selecionado ou à sua viatura; `bombeiros` atende fogo no veículo. Os NPCs chegam pela rua e precisam alcançar o alvo para atender. `guincho` e `reforco` continuam disponíveis. `servicos` abre as chamadas no tablet.
- **Ocorrências:** `guerradefaccao` aceita confrontos entre duas facções fictícias em Davis, Rancho ou na Favela Realista. Seis combatentes com pistolas, SMGs e fuzis; combatem entre si e reagem à equipe. `ronda` alterna essas ocorrências e as patrulhas anteriores. `cancelarronda` encerra a missão.
- **Conduzir pessoas:** após abordar, `seguir` faz a pessoa acompanhar você a pé; `parar` manda aguardar. `entrar no carro` usa um banco livre da viatura.

## Comandos no T

Digite a palavra e aperte Enter, com ou sem `/`.

| Comandos | Uso |
| --- | --- |
| `servico`, `viatura`, `farda`, `fuzil`, `equipe` | Turno, veículo, roupa e colegas |
| `abordar`, `documento`, `antecedentes`, `revistar` | Abordagem e fiscalização |
| `desce do carro`, `mao na cabeca`, `maos pra cima` | Desembarque e rendição |
| `deita no chao`, `ajoelhar`, `levantar` | Posições da pessoa |
| `algemar`, `desalgemar`, `seguir`, `parar`, `entrar no carro` | Custódia e condução |
| `prender`, `registrarprisao`, `prisoes` | Prisão de NPC, entrega na base e histórico salvo |
| `liberarcarro`, `liberar`, `cancelarperseguicao` | Liberação e fim de perseguição |
| `cone`, `guardarcone`, `recolhercones` | Equipar, guardar e recolher cones |
| `ambulancia`, `mecanico`, `bombeiros`, `guincho`, `reforco 3` | Serviços e apoio |
| `dispensar reforco`, `giroflex`, `sirene` | Apoio, luzes e som |
| `ronda`, `guerradefaccao`, `cancelarronda`, `chamado`, `cancelar` | Missões e COPOM |
| `tablet`, `inventario`, `progresso`, `salvar` | Consulta e salvamento |
| `base`, `favela`, `porta`, `ajuda` | GPS, entrada e ajuda |

Para prender: **abordar → prender → entrar no carro → levar à base → desembarcar → registrarprisao**. O NPC precisa estar vivo, algemado e próximo do policial no ponto de custódia. Um banco traseiro fica reservado para o preso. `liberar` cancela a custódia ainda não entregue. A entrega automática atende NPCs.

Reforços copiam o modelo, pintura, cores e extras da sua viatura. Pode chamar outras vezes sem apagar as anteriores. Motoristas obedientes permanecem parados até a liberação pelo T. Em 15% das primeiras abordagens de NPCs, o motorista foge e inicia uma perseguição no GPS.

## Validação

Os testes automatizados cobrem colisão binária da base/favela, nascimento seguro, comandos, revistas, persistência após recarregar o recurso, falhas de gravação, prisões, cones, funções dos colegas, serviços e ocorrências. O tablet também foi conferido em navegador, incluindo textos, abas, chamadas e Esc. Os instaladores foram executados com PowerShell em perfis temporários.

**GTA V/FXServer não estão disponíveis neste ambiente.** Piso e porta da base, navegação na favela, combate, chegada dos serviços e animações ainda precisam de conferência dentro do FiveM. Documentos e antecedentes são fictícios; não há consulta a sistemas governamentais. O inventário é de apreensões deste recurso, sem integração com inventários de outros frameworks. O tablet antigo de QBCore continua separado.
