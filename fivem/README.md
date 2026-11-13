# PRF RP — FiveM Legacy (Nova Byte)

> **PADRÃO ATUAL: GTA V LEGACY + FiveM Legacy.** Use seu FXServer/txAdmin existente. O perfil padrão continua `C:\txData\FiveMBasicServerCFXDefault_F3288B.base`; não é necessário reinstalar o GTA ou o servidor.

## Atualização 0.3.0 em teste

Esta branch inclui uma variante da base Chumash com interior restaurado, nascimento na base, equipe com fuzil, blitz e rondas. Também inclui a conversão da Favela Realista e população de gangue limitada por proximidade. **Ainda é necessário conferir aparência, colisões, navegação e estabilidade dentro do FiveM.**

1. Baixe e extraia o ZIP completo desta branch.
2. Pare o servidor no txAdmin.
3. Execute **`fivem/scripts/setup-prf-update.cmd`**. Ele copia os recursos, verifica integridade e guarda backups fora de `resources`.
4. Inicie o servidor e reabra o FiveM. Confira a [atualização de teste](ATUALIZACAO-TESTE.md).

O instalador preserva o `server.cfg`, o ACE individual e os demais recursos. Se o seu perfil tiver outro caminho, ajuste `SERVERDATA` no CMD. Depois de instalar, a ordem é `ensure prfMiniLN3d3v`, `ensure prf_favela_realista`, `ensure prf_core`.

## Controles

| Tecla / comando | Ação |
| --- | --- |
| F5 | Entrar/sair de serviço com permissão ACE |
| F6 | Menu original: farda, viatura, COPOM e equipe |
| F7 | Solicitar uma ocorrência COPOM com etapas |
| F9 | Próxima viatura da frota |
| F10 / `/prfbase` | GPS da base Chumash, quando o mapa estiver ativo |
| F11 | Abordagem, documentos, revista, guincho, reforço, blitz e rondas |
| J | Reagrupar os três colegas |
| K | Sacar/guardar carabina de serviço |
| L / O | Giroflex / sirene |
| `/prffavela` | GPS da Favela Realista |
| `/prfcancelarronda` | Encerrar a ronda atual |

O personagem reaparece na entrada da base quando o mapa está iniciado e o piso carrega. Sandy Shores permanece como alternativa se a base estiver desligada. O nascimento não concede serviço policial. Os três colegas são NPCs locais: mantêm carabina a pé, guardam no veículo e recebem a mesma farda PRF quando o recurso da roupa está ativo.

Os documentos e resultados de revista são **fictícios**, sem consulta a DETRAN, inventário ou banco externo. Guincho aguarda o veículo parar e jogadores desembarcarem. Rondas exigem chegada aos pontos; algumas têm confronto, e a ocorrência de apoio sob ataque tem confronto garantido. As seis ocorrências COPOM anteriores continuam disponíveis.

## Permissão individual

Salve no `server.cfg` local, com o identificador da sua conta:

```cfg
add_ace identifier.fivem:SEU_ID prfrp.officer allow
```

Também pode usar seu identificador `license`. Mantenha identificadores e chaves Cfx no seu computador. O instalador padrão não libera acesso policial global. O parâmetro `-LocalTestEveryone` existe apenas no instalador antigo para testes privados; não é necessário nesta atualização.

## Roupa e veículos

O recurso `prf_skin_replace` da roupa enviada é instalado por **`setup-prf-skin.cmd`**, a partir de `GTA 5 Skin PRF.rar` ou `PRF_Farda_FiveM_Legacy.zip` em Downloads. Ele valida os hashes e substitui `s_m_y_sheriff_01`. Seus binários não são republicados nesta branch. Depois de instalado, F6 → 4 alterna a farda fora da viatura.

A Equinox de Martinelli substitui `police` e continua disponível em `/prfviatura police`, quando o recurso opcional está instalado. Os modelos `police3`, `police2`, `sheriff2` e `policeb` continuam sendo veículos nativos de teste. A instalação anterior é descrita em [assets/README.md](assets/README.md).

## Atualização apenas do core / retomada

`setup-prf-legacy.cmd` e `install-prf.ps1` continuam disponíveis para copiar somente os dez arquivos do core no perfil existente. Para atualizar todos os componentes desta entrega, use o instalador de atualização acima.

No Live Console, os comandos são individuais: `refresh`, `ensure prfMiniLN3d3v`, `ensure prf_favela_realista`, `ensure prf_core`. Um reinício completo pelo txAdmin também carrega as linhas salvas. Entre pelo FiveM com F8 → `connect 127.0.0.1:30120` no servidor local padrão.

A alternativa Enhanced permanece em [enhanced/README.md](enhanced/README.md). O tablet antigo depende de QBCore e não é instalado pelo core standalone. Este é um simulador fictício, sem vínculo com a PRF real, economia, banco de dados ou carreira persistente.
