# PRF RP | Nova Byte — FiveM para GTA V Enhanced

**Objetivo:** jogar o núcleo PRF RP standalone já desenvolvido em um **servidor Cfx Enhanced** separado. Mantemos o servidor Legacy sem apagá-lo.

O recurso `prf_core` atual tem apenas código Lua, sem `stream/`, `yft`, `ydd`, `ymap`, `ytd` ou veículos personalizados. Portanto, **não precisamos converter modelos com Alchemist nesta etapa**. Porém, *compatibilidade ainda depende de teste prático no runtime Enhanced*: nenhum teste de GitHub Actions executa GTA V ou FiveM.

## 1. Conclua o GTA V Enhanced

- Termine o download do **GTA V Enhanced** pela loja/launcher original e abra-o pelo menos uma vez pelo Rockstar Games Launcher.
- Acesse [fivem.net](https://fivem.net/) e escolha **Download FiveM for GTAV Enhanced** (não o download FiveM Legacy). É um **cliente diferente**, ainda em acesso antecipado.
- Não aponte o instalador Legacy que pede `GTA5.exe` para arquivos do Enhanced. Instale o cliente Enhanced próprio.

Fonte: https://support.cfx.re/hc/en-us/articles/27623908811164-Downloading-and-installing-FiveM-for-GTAV-Enhanced

## 2. Instale o servidor Enhanced em pasta nova

1. Acesse [Server Download](https://docs.fivem.net/docs/server-download/), selecione **FiveM for GTAV Enhanced → Windows → Recommended** e baixe o artifact correspondente. **Não use o `server.7z` antigo.**
2. Instale ou repare o **Microsoft Visual C++ 2017 Redistributable x64** requerido pela documentação oficial. O pacote redistribuível Microsoft atual compatível com versões 2015–2022 está em https://aka.ms/vs/17/release/vc_redist.x64.exe .
3. Extraia o artifact do Enhanced, chamado `cfx-server_win_x64`, em **`C:\CfxServerEnhanced`**. Na pasta deve existir `cfx-server.exe`. Não extraia por cima de `C:\FXServer` (Legacy).
4. Baixe o ZIP deste projeto em https://github.com/luandersonjesussantos063-eng/last-second/archive/refs/heads/main.zip e extraia.
5. Abra a pasta do ZIP extraído e clique duas vezes em `fivem/scripts/start-prf-enhanced.cmd`. Ele inicia **`cfx-server.exe`** no perfil de dados novo `C:\txDataEnhanced`, txAdmin **http://localhost:40121**. Os caminhos ficam no começo do arquivo, para editar se desejar.
6. No txAdmin Enhanced, faça o cadastro inicial e escolha a receita básica `CFX Default FiveM`, caso esteja disponível na sua versão. Use a chave de registro no próprio painel, **nunca no GitHub**. Escolha um destino **dentro de `C:\txDataEnhanced`**, por exemplo `C:\txDataEnhanced\PRFRPEnhanced.base`, onde estarão `server.cfg` e `resources`.
7. Se o FXServer Legacy estiver executando o servidor de jogo, **pare o Legacy** antes de iniciar o Enhanced, porque os dois normalmente usam a mesma porta **30120**. Os painéis são diferentes: Legacy `40120`, Enhanced `40121`.

Referências: https://docs.fivem.net/docs/server-manual/setting-up-a-server-txadmin/ e https://docs.fivem.net/docs/developers/legacy-vs-enhanced/

## 3. Instale o recurso PRF RP

Depois que o txAdmin Enhanced criar o `server.cfg` e a pasta `resources`, abra PowerShell na pasta extraída deste projeto e execute:

```powershell
powershell -ExecutionPolicy Bypass -File .\fivem\scripts\install-prf-enhanced.ps1 -ServerDataPath "C:\txDataEnhanced\PRFRPEnhanced.base"
```

**Atenção:** altere o caminho de exemplo para o **diretório verdadeiro que contém o `server.cfg`** criado pelo txAdmin. O script copia somente `fxmanifest.lua`, `config.lua`, `client.lua` e `server.lua` para `resources/[prf]/prf_core`; faz backup do `server.cfg` antes de incluir `ensure prf_core`. Não sobrescreve licenças nem outros recursos.

No `server.cfg` do novo servidor Enhanced, autorize **somente seu jogador** (a instrução abaixo é um modelo, preencha o seu identificador diretamente no seu computador):

```cfg
ensure prf_core
add_ace identifier.fivem:SEU_ID prfrp.officer allow
```

**Nunca** use `add_ace builtin.everyone prfrp.officer allow` em servidores com terceiros. A instalação Enhanced não ativa essa permissão global automaticamente.

No Live Console do txAdmin Enhanced, digite **um comando por vez**:

```text
refresh
```

```text
ensure prf_core
```

A mensagem esperada é `Started resource prf_core`.

## 4. Conectar e testar

1. Inicie o **FiveM for GTAV Enhanced**, não o cliente FiveM Legacy.
2. Abra o console do cliente com **F8** e conecte ao servidor local: `connect 127.0.0.1:30120`, desde que o txAdmin Enhanced tenha iniciado o jogo na porta padrão.
3. No chat, execute `/prfservico`, `/prfviatura`, `/prfchamado`. Dirija até o ponto no GPS e pressione **E** para finalizar.
4. Verifique também `/prfstatus`, `/prfcancelar` e desligamento de turno.
5. Se aparecer “Sem permissao PRF”, confira o ACE no **`server.cfg` Enhanced** e o identificador da sua conta. O ACE antigo do Legacy não é importado automaticamente.
6. Em falhas de NPC/viatura/entidades ou scripts, envie **somente as mensagens de erro**, sem chaves, PIN, senhas ou tokens.

## Diferenças importantes

- Enhanced utiliza sincronização cliente-servidor e **OneSync big**. Evite scripts feitos para P2P/OneSync antigo e configurações `onesync legacy`. Não é necessário `sv_enforceGameBuild` para as missões básicas.
- Recursos com modelos personalizados futuramente precisarão de validação/possível conversão com [Alchemist](https://docs.fivem.net/docs/server-manual/onboarding-guide-fivem-for-gtav-enhanced/). O `prf_tablet` legado exige QBCore e **não é incluído** neste pacote standalone.
- O núcleo de FiveM tem somente três chamados iniciais, NPC demonstrativo e viatura padrão. Ele **não é uma conversão integral** do jogo web PRF RP; o simulador do navegador fica preservado.
- Nenhum arquivo do GTA V Enhanced nem servidor Cfx é redistribuído aqui; faça os downloads oficiais.

**Estado:** scripts preparados e testados estaticamente no GitHub, runtime Enhanced ainda sem validação prática no computador.
