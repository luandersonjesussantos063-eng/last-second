# PRF RP — FiveM Legacy (Nova Byte)

> **PADRÃO ATUAL: GTA V LEGACY + FiveM Legacy.** Use seu FXServer/txAdmin existente. O perfil padrão continua `C:\txData\FiveMBasicServerCFXDefault_F3288B.base`; não é necessário reinstalar o GTA ou o servidor.

## Atualização 0.9.0 em teste

**Apoio com quatro policiais por viatura, comboio e motorista NPC.** `apoio 3` acrescenta três viaturas para acompanhamento ou perseguição. `comboio 3` forma uma fila de viaturas para sua ronda. `motorista`, com a viatura parada, coloca um colega no volante e você no banco de passageiro; marque o destino no mapa e controle giroflex/sirene em L/O. Mire com Z numa pessoa ou veículo para parar/interceptar. Veja os [comandos de apoio e motorista](APOIO-E-MOTORISTA.md).

O COPOM agora oferece **dez tipos de atendimento, com variações e oito regiões**. A seleção percorre todos os tipos antes de repetir; a fila fica salva por jogador. Cada chamado monta uma cena com veículos, pessoas e objetos e exige resolver objetivos no mundo: socorro, sinalização, fiscalização, prisão, remoção ou retirada de obstáculos. Chegar e apertar E não conclui o chamado.

Use `chamado` ou F7 para receber uma ocorrência, e `copom` para consultar as pendências. `conversar`, `recolher` e `inspecionar` executam ações próximas com tempo de atendimento; também pode **segurar E**. Soltar E ou se afastar interrompe a ação. Serviços precisam chegar e atender o alvo. Veja os [tipos e instruções](COPOM.md).

Inclui correção da colisão do interior da base de Chumash, porta física e nascimento externo com chão verificado. A favela passa a ter integrantes em movimento, fugas e reação à presença policial. A revista reconhece e retira armas reais do NPC, guardando armas e munições no inventário de apreensões.

O progresso fica salvo por jogador no servidor: apreensões, prisões e totais de missões e ocorrências. As consultas usam um tablet, com inventário, progresso e serviços. Cones são colocados um a um pela mira; a equipe sinaliza, protege e atende a blitz. Há ambulância, mecânico, bombeiros, guincho, reforços e três ocorrências de guerra de facção. Veja os comandos e limites em [ATUALIZACAO-TESTE.md](ATUALIZACAO-TESTE.md).

As ações continuam no T e a mira fica no Z. Para prender: `prender` → `entrar no carro` → levar à base → desembarcar → `registrarprisao`. `prisoes` mostra seu histórico salvo. Um banco traseiro fica reservado para o detido. Motoristas obedientes continuam retidos até a liberação; alguns fogem e iniciam perseguição. Reforços repetidos mantêm o modelo e a pintura da sua viatura.

1. Baixe e extraia o ZIP completo desta branch.
2. Pare o servidor no txAdmin.
3. Execute **`fivem/scripts/setup-prf-update.cmd`**. Ele copia os recursos, verifica integridade e guarda backups fora de `resources`.
4. Inicie o servidor e reabra o FiveM. Confira a [atualização de teste](ATUALIZACAO-TESTE.md).

O instalador preserva o ACE individual e os demais recursos, guarda backups em `_prf_backups` e atualiza as linhas de início do `server.cfg`. Se o seu perfil tiver outro caminho, ajuste `SERVERDATA` no CMD. Mapa, viatura e favela iniciam antes do core. A Trailblazer completa já instalada é preservada; nos demais casos a Equinox incluída é instalada. Apenas um desses dois replaces fica ativo no slot `police`.

## Comandos no T

Abra o chat com **T**, digite a palavra e aperte Enter. Também aceita a barra: `/viatura`, `/revistar` etc.

| Palavra | Ação |
| --- | --- |
| `servico` | Entrar/sair de serviço com permissão ACE |
| `viatura` | Pegar o SUV PRF com a pintura original |
| `farda`, `fuzil`, `equipe` | Alternar farda, sacar/guardar fuzil, reagrupar colegas |
| `abordar` | Abordar a pessoa ou o carro à frente |
| `documento`, `antecedentes` | Documento e passagem fictícios da pessoa; documentos do carro na abordagem de veículo |
| `revistar`, `liberar` | Revistar ou encerrar a abordagem atual |
| `guincho`, `apoio 3`, `reforco`, `blitz` | Guincho, apoio com quatro policiais por viatura e cones |
| `comboio 3`, `pararcomboio`, `retomarcomboio` | Criar, pausar e retomar o comboio |
| `desembarcarapoio`, `encerrarcomboio`, `dispensarapoio` | Apoio a pé e liberação de unidades |
| `motorista`, `continuar`, `pararviatura`, `embarcar`, `assumir` | NPC dirige pelo GPS; você controla a sirene e aborda pela mira |
| `ronda`, `cancelarronda`, `chamado` | Patrulha, cancelar ronda e receber ocorrência COPOM |
| `copom`, `conversar`, `recolher`, `inspecionar` | Pendências e ações do atendimento atual |
| `giroflex`, `sirene` | Ligar/desligar luzes e som |
| `base`, `favela`, `ajuda` | GPS e lista de comandos |
| `inventario`, `progresso`, `salvar`, `tablet` | Apreensões, registros e consultas salvos |
| `cone`, `guardarcone`, `recolhercones` | Equipar cones; Z ou botão direito + clique para colocar |
| `ambulancia`, `mecanico`, `bombeiros`, `servicos` | Acionar atendimento no local |
| `guerradefaccao`, `porta` | Ocorrência de confronto e entrada da base |

| Ordem no T | Ação |
| --- | --- |
| `desce do carro` ou `descer` | Desembarcar os ocupantes do carro abordado e parado |
| `mao na cabeca`, `maos pra cima` | Mudar a posição das mãos da pessoa abordada |
| `deita no chao`, `ajoelhar`, `levantar` | Deitar, ajoelhar ou levantar |
| `algemar`, `desalgemar` | Aplicar ou retirar algemas; exige proximidade |
| `prender` | Prender o NPC abordado, algemar e marcar a entrega na base |
| `registrarprisao` ou `entregar preso` | Concluir a entrega do NPC na base, com a viatura parada e o policial a pé |
| `prisoes` | Ver os últimos protocolos de prisão salvos |
| `seguir`, `parar` | Conduzir a pessoa a pé ou fazê-la aguardar |
| `entrar no carro` | Colocar a pessoa em um assento livre da sua viatura próxima |
| `bafometro` | Resultado fictício e estável na abordagem atual |
| `reforco 3` | Acrescentar três viaturas iguais à sua; pode repetir |
| `dispensar reforco` | Retirar unidades de apoio e cancelar a fila |
| `liberarcarro`, `liberar` | Soltar o carro selecionado ou encerrar a abordagem com pessoas e veículos |
| `cancelarperseguicao` | Encerrar a perseguição ativa |

O reforço copia o modelo, a pintura, as cores, os extras do giroflex e o vidro da viatura usada na chamada. Cada unidade traz quatro policiais; chamadas novas preservam as anteriores. Não há cota fixa de unidades ativas: o script cria uma por vez e aguarda espaço na via. Use `dispensar reforco` para retirar o apoio. O apoio acompanha a perseguição, desembarca quando necessário e embarca novamente para seguir outra fuga ou sua viatura. O comboio aguarda embarcado quando você desce, com desembarque para defesa se houver agressão.

Ao mandar um carro parar, espere o motorista encostar. Ele continua parado enquanto você conversa, revista ou aborda o motorista a pé. Selecionar outro carro também conserva a parada anterior. Somente `liberarcarro`/`liberar`, o encerramento do serviço ou a limpeza da sessão encerram essas paradas. Ocasionalmente um NPC desobedece: o GPS marca a fuga; imobilizar o veículo por alguns segundos perto da equipe encerra a perseguição e mantém o carro sob abordagem até liberação. A chance é configurável em `operations_config.lua`.

Para abordar uma pessoa a pé, entre em serviço, saque o fuzil e mantenha a mira nela por meio segundo, a até 15 metros. Ela fica com as mãos na cabeça. Aproxime-se a até três metros para `documento` ou `revistar`; use `liberar` para soltá-la. Seus colegas e o reforço não são alvos. Identidade e antecedentes se mantêm nas consultas à mesma pessoa durante a sessão, sem banco de dados real.

Segure **Z** para mirar e solte para baixar a arma. Abrir o chat ou o pause suspende essa mira. Os atalhos diretos F5/F7/F9/J/K/L/O continuam disponíveis. F6/F11 antigos só mostram ajuda no chat; os números antigos não executam ações nem abrem painel.

O personagem reaparece em um acostamento externo da base quando o mapa e o piso carregam. Sandy Shores permanece como alternativa se a base estiver desligada. O nascimento não concede serviço policial. Os três colegas são NPCs locais: mantêm carabina a pé, guardam no veículo e recebem a mesma farda PRF quando o recurso da roupa está ativo.

Os documentos e antecedentes são **fictícios**, sem consulta a DETRAN ou banco externo. A revista verifica armas nativas reais dos NPCs e guarda as apreensões no inventário deste recurso. Guincho aguarda o veículo parar e jogadores desembarcarem. Rondas exigem chegada aos pontos; algumas têm confronto, e a ocorrência de apoio sob ataque tem confronto garantido. Os antigos chamados de três cliques foram substituídos pelas dez cenas descritas em [COPOM.md](COPOM.md).

## Permissão individual

Salve no `server.cfg` local, com o identificador da sua conta:

```cfg
add_ace identifier.fivem:SEU_ID prfrp.officer allow
```

Também pode usar seu identificador `license`. Mantenha identificadores e chaves Cfx no seu computador. O instalador padrão não libera acesso policial global. O parâmetro `-LocalTestEveryone` existe apenas no instalador antigo para testes privados; não é necessário nesta atualização.

## Roupa e veículos

O recurso `prf_skin_replace` da roupa enviada é instalado por **`setup-prf-skin.cmd`**, a partir de `GTA 5 Skin PRF.rar` ou `PRF_Farda_FiveM_Legacy.zip` em Downloads. Ele valida os hashes e substitui `s_m_y_sheriff_01`. Seus binários não são republicados nesta branch. Depois de instalado, `farda` no T alterna a roupa fora da viatura.

A Equinox de Martinelli substitui `police` e agora é incluída pelo atualizador quando não há Trailblazer completa instalada. O comando `viatura` e a primeira opção F9 usam esse slot; a pintura não recebe as cores temporárias dos carros nativos. Os modelos `police3`, `police2`, `sheriff2` e `policeb` continuam como opções de teste no F9. A instalação anterior é descrita em [assets/README.md](assets/README.md).

## Atualização apenas do core / retomada

`setup-prf-legacy.cmd` e `install-prf.ps1` continuam disponíveis para copiar os scripts e a interface do core no perfil existente. Para atualizar todos os componentes desta entrega, use o instalador de atualização acima.

No Live Console, os comandos são individuais: `refresh`, `ensure prfMiniLN3d3v`, `ensure prf_favela_realista`, `ensure prf_core`. Um reinício completo pelo txAdmin também carrega as linhas salvas. Entre pelo FiveM com F8 → `connect 127.0.0.1:30120` no servidor local padrão.

A alternativa Enhanced permanece em [enhanced/README.md](enhanced/README.md). O tablet antigo depende de QBCore e continua separado. O core agora inclui seu próprio tablet e progresso salvo via KVP do FXServer. Este é um simulador fictício, sem vínculo com a PRF real. As verificações de código não substituem a conferência no FiveM.
