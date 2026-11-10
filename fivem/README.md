# PRF RP — servidor local FiveM gratuito (Nova Byte)

Primeira versão jogável standalone para **GTA V Legacy + FiveM**, sem QBCore, sem SQL, sem hospedagem paga e sem necessidade de modificar a versão web. Scripts de simulação fictícia, não vinculados à PRF real.

## O que funciona

- `/prfajuda`: consulta comandos.
- `/prfservico`: começa/encerra o turno PRF (permissão ACE obrigatória).
- `/prfviatura`: gera uma viatura GTA V original (`police3`), sem pacote de veículos externo.
- `/prfchamado`: recebe uma das três ocorrências fictícias, com NPC no local, marcação no GPS e rota.
- Chegar ao marcador e apertar **E** para finalizar; o **servidor** confere jogador, ocorrência e distância.
- `/prfcancelar`: cancela a ocorrência em andamento.
- `/prfstatus`: consulta status e total de ocorrências concluídas naquela sessão.

Esta é uma **base inicial de demonstração**, não um servidor aberto 24h, nem um RP multiplayer completo. Não há banco de dados, inventário, economia ou persistência de carreira. O `prf_tablet` antigo **não é instalado**, pois requer QBCore.

## 1. Instale gratuitamente o FXServer e o FiveM

1. Você precisa ter **GTA V original compatível** e o cliente FiveM instalado para jogar; o servidor em si é gratuito.
2. Crie uma conta Cfx.re e uma **chave de registro gratuita** no [Cfx Portal](https://portal.cfx.re/). **Não salve nem envie essa chave ao GitHub ou ChatGPT.**
3. Baixe o **artifact Windows recomendado** pelo guia oficial [Servidor FiveM + txAdmin](https://docs.fivem.net/docs/server-manual/setting-up-a-server-txadmin/). Para o GTA V Legacy, o executável é `FXServer.exe` (Enhanced usa outro artifact).
4. Extraia para uma pasta sua, por exemplo `C:\FXServer\server`. Abra `FXServer.exe` **sem** `+exec`.
5. Abra o endereço informado pelo console, normalmente `http://localhost:40120`. Vincule sua conta usando o PIN privado e crie a senha administrativa.
6. No assistente, escolha **Popular Recipes → CFX Default FiveM**. Não precisa instalar QBCore nem banco SQL. Insira a chave Cfx.re **somente no txAdmin**. Use **Save & Run Server**.
7. Encontre a pasta criada pelo txAdmin, que contém `server.cfg` e `resources`. Em geral fica dentro de `txData\CFXDefault_...base`, mas o nome depende da instalação.

## 2. Instale o pacote PRF RP no servidor

### Opção mais simples (manual)

1. Baixe este repositório como ZIP no GitHub: **Code → Download ZIP** e extraia.
2. Copie a pasta `fivem/resources/[prf]/prf_core` para `resources/[prf]/prf_core` **dentro da pasta de dados do servidor txAdmin**, junto ao `server.cfg`.
3. Abra o `server.cfg` existente no txAdmin e acrescente **apenas** estas linhas no final:

```cfg
# Simulador PRF RP (standalone)
ensure prf_core

# TESTE LOCAL PRIVADO APENAS: qualquer jogador conectado pode virar PRF!
# Remova antes de abrir a porta do servidor para terceiros.
add_ace builtin.everyone prfrp.officer allow
```

4. No txAdmin, reinicie o servidor ou execute `refresh` e `ensure prf_core` no console.

### Opção automática no Windows (PowerShell)

Abra o PowerShell **na pasta extraída deste repositório** e execute:

```powershell
powershell -ExecutionPolicy Bypass -File .\fivem\scripts\install-prf.ps1 -ServerDataPath "C:\FXServer\txData\CFXDefault_123456.base" -LocalTestEveryone
```

Troque o exemplo pelo caminho **real da pasta com `server.cfg`**. O script copia apenas quatro arquivos do recurso, faz backup do `server.cfg` antes de alterá-lo e adiciona `ensure prf_core`. O parâmetro `-LocalTestEveryone` libera o trabalho policial para todos no teste local; remova essa opção em um servidor público.

### Quando for abrir para outras pessoas

Remova `add_ace builtin.everyone prfrp.officer allow` e permita apenas um identificador privado autorizado no `server.cfg`:

```cfg
add_ace identifier.license:COLOQUE_SEU_IDENTIFICADOR_LOCALMENTE prfrp.officer allow
```

Descubra seu identificador pelos comandos e registros administrativos do servidor. Não cole identificadores privados, senhas ou chaves de registro no GitHub. Proteja o painel txAdmin; ele usa uma porta administrativa diferente da porta do jogo.

## 3. Entre e jogue

1. Inicie o FiveM no **mesmo computador** e pressione **F8**.
2. Digite `connect 127.0.0.1:30120` (se o txAdmin usa a porta padrão).
3. Já no jogo, digite `/prfservico`. O personagem vai para a base de teste de Sandy Shores.
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
