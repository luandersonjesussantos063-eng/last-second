# PRF RP — servidor local FiveM gratuito (Nova Byte)

> **PADRÃO ATUAL: GTA V LEGACY + FiveM Legacy.** Este é o servidor que já está funcionando no Windows, com `FXServer.exe`, `C:\FXServer` e o perfil txAdmin `C:\txData\FiveMBasicServerCFXDefault_F3288B.base`. O GTA V Enhanced **não é necessário**. A opção [Enhanced](enhanced/README.md) foi preservada separadamente, mas não é a instalação recomendada para este projeto agora.

## Retomar o servidor Legacy que já criamos

Se o txAdmin já mostrou `Started resource prf_core`, **não reinstale o servidor**: basta abrir `fivem/scripts/start-prf-legacy.cmd` (ou continuar iniciando seu `C:\FXServer\FXServer.exe`) e usar seu perfil txAdmin existente. Quando o GTA V Legacy terminar de instalar, abra o FiveM Legacy, pressione **F8** e execute `connect 127.0.0.1:30120`.

Para atualizar os quatro scripts Lua do GitHub no servidor Legacy existente, baixe o ZIP mais recente deste repositório e execute **`fivem/scripts/setup-prf-legacy.cmd`** dentro do ZIP extraído. O instalador confere o perfil que você já criou, copia somente `prf_core` para `resources\[prf]\prf_core`, faz backup do `server.cfg` antes de modificá-lo e não concede acesso policial a todos. No **txAdmin → Live Console**, execute `refresh` e depois `ensure prf_core`, **cada comando separado**. Se a pasta do seu perfil mudou, edite a variável `SERVERDATA` no início do .cmd ou use o PowerShell com `-ServerDataPath`.

**Segurança:** mantenha a liberação individual `add_ace identifier.fivem:SEU_ID prfrp.officer allow` diretamente no `server.cfg`, sem colocar identificadores privados ou chave Cfx no GitHub. O servidor local precisa continuar aberto durante o jogo; com 8 GB de RAM, o desempenho pode ficar limitado.


Primeira versão jogável standalone para **GTA V Legacy + FiveM**, sem QBCore, sem SQL, sem hospedagem paga e sem necessidade de modificar a versão web. Scripts de simulação fictícia, não vinculados à PRF real.

## O que funciona

- `/prfajuda`: consulta comandos.
- `/prfservico`: começa/encerra o turno PRF (permissão ACE obrigatória).
- `/prfviatura`: gera a viatura configurada; por padrão usa o `police3` original do GTA V.
- `/prfmoto`: gera a moto configurada, após instalar e configurar seu recurso externo; desativada por padrão.
- `/prfbase`: aponta para a base configurada no GPS. A construção depende de um recurso de mapa instalado.
- `/prfchamado`: recebe uma das três ocorrências fictícias, com NPC no local, marcação no GPS e rota.
- Chegar ao marcador e apertar **E** para finalizar; o **servidor** confere jogador, ocorrência e distância.
- `/prfcancelar`: cancela a ocorrência em andamento.
- `/prfstatus`: consulta status e total de ocorrências concluídas naquela sessão.

Esta é uma **base inicial de demonstração**, não um servidor aberto 24h, nem um RP multiplayer completo. Não há banco de dados, inventário, economia ou persistência de carreira. O `prf_tablet` antigo **não é instalado**, pois requer QBCore.

## Moto, base fixa e viatura das fotos

As referências são uma BMW GS Adventure da PRF, uma unidade com cobertura sobre a rodovia e uma Chevrolet Trailblazer da PRF. **Os modelos 3D, as pinturas e o mapa das fotos ainda não estão neste repositório.** A configuração da frota e da base prepara a integração, mas não reproduz esses itens sozinha.

Siga [Referências e integração PRF](REFERENCIAS-PRF.md) para instalar recursos compatíveis com **FiveM Legacy**, iniciá-los antes de `prf_core` e configurar os modelos, pinturas, extras e coordenadas reais. `/prfmoto`, `/prfviatura` e `/prfbase` exigem permissão policial e turno ativo.

## 1. Instale gratuitamente o FXServer e o FiveM

1. Você precisa ter **GTA V original compatível** e o cliente FiveM instalado para jogar; o servidor em si é gratuito.
2. Crie uma conta Cfx.re e uma **chave de registro gratuita** no [Cfx Portal](https://portal.cfx.re/). **Não salve nem envie essa chave ao GitHub ou ChatGPT.**
3. Baixe o **artifact Windows recomendado para FiveM Legacy** pelo guia oficial [Servidor FiveM + txAdmin](https://docs.fivem.net/docs/server-manual/setting-up-a-server-txadmin/). Para o GTA V Legacy, o executável é `FXServer.exe` (Enhanced usa outro artifact).
4. Extraia para `C:\FXServer` (ou reutilize o que já instalou). Abra `C:\FXServer\FXServer.exe` **sem** `+exec`.
5. Abra o endereço informado pelo console, normalmente `http://localhost:40120`. Vincule sua conta usando o PIN privado e crie a senha administrativa.
6. No assistente, escolha **Popular Recipes → CFX Default FiveM**. Não precisa instalar QBCore nem banco SQL. Insira a chave Cfx.re **somente no txAdmin**. Use **Save & Run Server**.
7. Use seu perfil existente `C:\txData\FiveMBasicServerCFXDefault_F3288B.base`, que contém `server.cfg` e `resources`. O nome pode variar em outras instalações.

## 2. Instale o pacote PRF RP no servidor

### Opção mais simples (manual)

1. Baixe este repositório como ZIP no GitHub: **Code → Download ZIP** e extraia. Se o `prf_core` já está instalado, você pode apenas atualizá-lo.
2. Copie a pasta `fivem/resources/[prf]/prf_core` para `resources/[prf]/prf_core` **dentro da pasta de dados do servidor txAdmin**, junto ao `server.cfg`.
3. Abra o `server.cfg` existente no txAdmin e acrescente **apenas** estas linhas no final:

```cfg
# Simulador PRF RP (standalone)
ensure prf_core

# Acesso policial somente para sua conta (coloque seu ID no Windows, nao no GitHub).
add_ace identifier.fivem:SEU_ID prfrp.officer allow
```

4. No txAdmin, reinicie o servidor ou execute `refresh` e, **na linha seguinte**, `ensure prf_core` no console.

### Opção automática no Windows (PowerShell)

Abra o PowerShell **na pasta extraída deste repositório** e execute:

```powershell
powershell -ExecutionPolicy Bypass -File .\fivem\scripts\install-prf.ps1 -ServerDataPath "C:\txData\FiveMBasicServerCFXDefault_F3288B.base"
```

Troque o exemplo pelo caminho **real da pasta com `server.cfg`**. O script copia apenas quatro arquivos do recurso, faz backup do `server.cfg` antes de alterá-lo e adiciona `ensure prf_core`. O parâmetro opcional `-LocalTestEveryone` libera o trabalho policial para todos e **não deve ser usado** neste servidor. A execução padrão preserva permissões individuais.

### Quando for abrir para outras pessoas

Remova `add_ace builtin.everyone prfrp.officer allow` e permita apenas um identificador privado autorizado no `server.cfg`:

```cfg
add_ace identifier.fivem:SEU_ID prfrp.officer allow
```

Descubra seu identificador pelos comandos e registros administrativos do servidor. Não cole identificadores privados, senhas ou chaves de registro no GitHub. Proteja o painel txAdmin; ele usa uma porta administrativa diferente da porta do jogo.

## 3. Entre e jogue

1. Inicie o FiveM no **mesmo computador** e pressione **F8**.
2. Digite `connect 127.0.0.1:30120` (se o txAdmin usa a porta padrão).
3. Já no jogo, digite `/prfservico`. Na configuração padrão, o personagem vai para a base de teste de Sandy Shores. `/prfbase` indica a base configurada no GPS.
4. Digite `/prfviatura` para pegar a viatura.
5. Digite `/prfchamado` e siga a rota amarela no GPS.
6. Ao chegar, pressione **E** perto do marcador; o servidor valida e conclui a ocorrência.
7. Repita `/prfchamado` para outra missão. Use `/prfstatus` para acompanhar.

## Avisos e próximos passos

- Uso local gratuito: computador precisa ficar ligado enquanto quiser jogar. Não existe servidor 24h hospedado automaticamente por este repositório.
- Abertura para internet requer configurar firewall/roteador, inclusive a porta de jogo usada pelo FiveM (normalmente 30120 TCP/UDP). **Não** exponha o txAdmin (normalmente 40120) publicamente.
- As coordenadas e missões ficam no arquivo `config.lua`; são pontos iniciais de teste a ajustar no mapa.
- Todo tráfego e funções dependem do FXServer estar instalado e iniciado; os testes de CI do repositório validam o pacote, **não substituem** um teste prático dentro do GTA V/FiveM.
- Não use nomes, uniformes e símbolos oficiais como se o servidor fosse serviço institucional ou afiliado à PRF; este projeto é um simulador fictício.

Fonte oficial: https://docs.fivem.net/docs/server-manual/setting-up-a-server-txadmin/
