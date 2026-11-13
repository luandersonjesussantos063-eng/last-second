# PRF RP — FiveM Legacy (Nova Byte)

> **PADRÃO ATUAL: GTA V LEGACY + FiveM Legacy.** Use seu FXServer/txAdmin existente. O perfil padrão continua `C:\txData\FiveMBasicServerCFXDefault_F3288B.base`; não é necessário reinstalar o GTA ou o servidor.

## Atualização 0.5.0 em teste

Inclui base Chumash com interior, nascimento na base, equipe com fuzil, blitz, rondas e Favela Realista. Corrige o registro da física dos quinze modelos da favela e inclui a viatura no atualizador. Pessoas a pé se rendem ao apontar uma arma; documento, antecedentes fictícios e revista pessoal saem no chat. **As ações usam o T, sem painéis F6/F11. Ainda é necessário conferir animações, colisões e estabilidade no FiveM.**

Esta versão acrescenta mira no **Z**, reforços repetidos com a mesma viatura do jogador, ordens de abordagem e transporte. Motoristas que obedecem encostam e ficam parados até liberação pelo T. Em 15% das primeiras abordagens de motoristas NPC, o condutor foge e inicia uma perseguição marcada no GPS.

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
| `guincho`, `reforco`, `blitz` | Guincho, apoio policial e cones |
| `ronda`, `cancelarronda`, `chamado` | Missão de patrulha, cancelar ronda e ocorrência COPOM |
| `giroflex`, `sirene` | Ligar/desligar luzes e som |
| `base`, `favela`, `ajuda` | GPS e lista de comandos |

| Ordem no T | Ação |
| --- | --- |
| `desce do carro` ou `descer` | Desembarcar os ocupantes do carro abordado e parado |
| `mao na cabeca`, `maos pra cima` | Mudar a posição das mãos da pessoa abordada |
| `deita no chao`, `ajoelhar`, `levantar` | Deitar, ajoelhar ou levantar |
| `algemar`, `desalgemar` | Aplicar ou retirar algemas; exige proximidade |
| `seguir`, `parar` | Conduzir a pessoa a pé ou fazê-la aguardar |
| `entrar no carro` | Colocar a pessoa em um assento livre da sua viatura próxima |
| `bafometro` | Resultado fictício e estável na abordagem atual |
| `reforco 3` | Acrescentar três viaturas iguais à sua; pode repetir |
| `dispensar reforco` | Retirar unidades de apoio e cancelar a fila |
| `liberarcarro`, `liberar` | Soltar o carro selecionado ou encerrar a abordagem com pessoas e veículos |
| `cancelarperseguicao` | Encerrar a perseguição ativa |

O reforço copia o modelo, a pintura, as cores, os extras do giroflex e o vidro da viatura usada na chamada. Cada unidade traz dois policiais; chamadas novas preservam as anteriores. Não há cota fixa de unidades ativas: o script cria uma por vez e aguarda espaço na via. Use `dispensar reforco` para retirar o apoio. Unidades chamadas durante uma perseguição acompanham o alvo antes de desembarcar.

Ao mandar um carro parar, espere o motorista encostar. Ele continua parado enquanto você conversa, revista ou aborda o motorista a pé. Selecionar outro carro também conserva a parada anterior. Somente `liberarcarro`/`liberar`, o encerramento do serviço ou a limpeza da sessão encerram essas paradas. Ocasionalmente um NPC desobedece: o GPS marca a fuga; imobilizar o veículo por alguns segundos perto da equipe encerra a perseguição e mantém o carro sob abordagem até liberação. A chance é configurável em `operations_config.lua`.

Para abordar uma pessoa a pé, entre em serviço, saque o fuzil e mantenha a mira nela por meio segundo, a até 15 metros. Ela fica com as mãos na cabeça. Aproxime-se a até três metros para `documento` ou `revistar`; use `liberar` para soltá-la. Seus colegas e o reforço não são alvos. Identidade e antecedentes se mantêm nas consultas à mesma pessoa durante a sessão, sem banco de dados real.

Segure **Z** para mirar e solte para baixar a arma. Abrir o chat ou o pause suspende essa mira. Os atalhos diretos F5/F7/F9/J/K/L/O continuam disponíveis. F6/F11 antigos só mostram ajuda no chat; os números antigos não executam ações nem abrem painel.

O personagem reaparece na entrada da base quando o mapa está iniciado e o piso carrega. Sandy Shores permanece como alternativa se a base estiver desligada. O nascimento não concede serviço policial. Os três colegas são NPCs locais: mantêm carabina a pé, guardam no veículo e recebem a mesma farda PRF quando o recurso da roupa está ativo.

Os documentos e resultados de revista são **fictícios**, sem consulta a DETRAN, inventário ou banco externo. Guincho aguarda o veículo parar e jogadores desembarcarem. Rondas exigem chegada aos pontos; algumas têm confronto, e a ocorrência de apoio sob ataque tem confronto garantido. As seis ocorrências COPOM anteriores continuam disponíveis.

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

`setup-prf-legacy.cmd` e `install-prf.ps1` continuam disponíveis para copiar os dezessete arquivos do core no perfil existente. Para atualizar todos os componentes desta entrega, use o instalador de atualização acima.

No Live Console, os comandos são individuais: `refresh`, `ensure prfMiniLN3d3v`, `ensure prf_favela_realista`, `ensure prf_core`. Um reinício completo pelo txAdmin também carrega as linhas salvas. Entre pelo FiveM com F8 → `connect 127.0.0.1:30120` no servidor local padrão.

A alternativa Enhanced permanece em [enhanced/README.md](enhanced/README.md). O tablet antigo depende de QBCore e não é instalado pelo core standalone. Este é um simulador fictício, sem vínculo com a PRF real, economia, banco de dados ou carreira persistente.
