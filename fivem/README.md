# PRF RP — servidor local FiveM gratuito (Nova Byte)

> **PADRÃO ATUAL: GTA V LEGACY + FiveM Legacy.** Este é o servidor que já está funcionando no Windows, com `FXServer.exe`, `C:\FXServer` e o perfil txAdmin `C:\txData\FiveMBasicServerCFXDefault_F3288B.base`. O GTA V Enhanced **não é necessário**. A opção [Enhanced](enhanced/README.md) foi preservada separadamente, mas não é a instalação recomendada para este projeto agora.

## PRF RP — Trailblazer, uniformes e posto operacional

A versão atual inclui a **Chevrolet Trailblazer PRF** do arquivo enviado e os **uniformes masculinos/femininos de wlukaas**, preparados para **FiveM Legacy**. Há um posto provisório junto à delegacia de Sandy Shores, com garagem, vestiário, COPOM, armaria e interações **E**. A **BMW GS e o mapa da base da foto ainda não foram fornecidos**. Veja o estado de cada item em [Referências PRF](REFERENCIAS-PRF.md).

Três policiais **NPC** são criados quando você entra de serviço. Eles acompanham o jogador a pé e são colocados nos bancos livres da viatura quando o personagem dirige; na motocicleta, a equipe acompanha somente a pé. Para reagrupar, use **J**. Os NPCs são locais ao cliente, não jogadores reais nem policiais com IA completa. Para preservar FPS, a equipe atualiza a cada 1,7 s.

`/prfviatura` solicita a Trailblazer, que substitui o modelo `police`. **F9** percorre a Trailblazer e os quatro veículos de teste do GTA (`police3`, `police2`, `sheriff2`, `policeb`). Para vestir/remover o uniforme do jogador, use **F6 → opção 4** ou **E no vestiário**. Personagens freemode mantêm o sexo; outros modelos usam o masculino por padrão. Retirar o uniforme restaura o modelo anterior com roupas padrão, sem preservar toda a aparência personalizada.

Há seis ocorrências fictícias, com condutores NPC, GPS e **três etapas acionadas com E**, validadas pelo servidor antes de registrar conclusão. O acesso policial continua exclusivo para quem tiver `prfrp.officer` no ACE, sem permitir liberar ações pelo cliente.

| Tecla | Ação |
|---|---|
| **F5** | Entrar/sair de serviço |
| **F6** | Abrir menu operacional; usar teclas **1–9** |
| **F7** | Solicitar ocorrência COPOM |
| **F9** | Alternar Trailblazer e veículos de teste |
| **J** | Reagrupar seus três policiais NPC |
| **K** | Sacar/guardar pistola fictícia do GTA V |
| **E** | Interagir com posto ou avançar etapa no local do chamado |
| **Botão direito do mouse** | Apontar a arma (controle padrão do GTA V) |

**Notebook:** se teclas F5–F9 exigirem `Fn`, pressione `Fn` junto. Os atalhos podem ser remapeados no FiveM em **Settings → Key Bindings → FiveM**. Se o cliente estiver com janela de chat/console aberta, feche-a antes de usar os atalhos.

### Atualização no computador (sem apagar seu servidor)

1. Baixe o ZIP do GitHub (**Code → Download ZIP**) e extraia.
2. Execute `fivem/scripts/setup-prf-legacy.cmd`. Ele instala `prf_core`, `prf_trailblazer` e `prf_uniformes_wlukaas` na pasta existente `C:\txData\FiveMBasicServerCFXDefault_F3288B.base`, preservando os outros recursos. O instalador configura os recursos dos mods antes do core e faz backup do `server.cfg` quando o modifica. Se a pasta mudou, edite `SERVERDATA` no CMD.
3. Reinicie o servidor no txAdmin. Para atualizar sem reiniciá-lo, execute no **Live Console**, um por linha: `refresh`, `ensure prf_trailblazer`, `ensure prf_uniformes_wlukaas`, `ensure prf_core`.
4. No FiveM, use **F5** para entrar em serviço, `/prfviatura` para a Trailblazer e **F6 → 4** para o uniforme. Se sua permissão ACE só foi concedida no console, salve a regra no `server.cfg` local para ela persistir após reiniciar.

O ZIP do GitHub inclui os arquivos dos dois mods. Não precisa de OpenIV nem de modificar o GTA original. O GitHub não atualiza automaticamente sua pasta do FXServer: instale o ZIP e reinicie os recursos. **A aparência e o funcionamento ainda precisam ser conferidos dentro do FiveM; os testes de código não comprovam fidelidade às fotos.**

## Retomar o servidor Legacy que já criamos

Se o txAdmin já mostrou `Started resource prf_core`, **não reinstale o servidor**: basta abrir `fivem/scripts/start-prf-legacy.cmd` (ou continuar iniciando seu `C:\FXServer\FXServer.exe`) e usar seu perfil txAdmin existente. Quando o GTA V Legacy terminar de instalar, abra o FiveM Legacy, pressione **F8** e execute `connect 127.0.0.1:30120`.

Para atualizar o servidor Legacy existente, baixe o ZIP mais recente e execute **`fivem/scripts/setup-prf-legacy.cmd`** dentro da pasta extraída. Ele instala o core e os dois mods em `resources/[prf]`, sem conceder acesso policial a todos. Depois, siga a ordem de reinício acima. Se a pasta do perfil mudou, edite `SERVERDATA` no CMD ou use o PowerShell com `-ServerDataPath`.

**Segurança:** mantenha a liberação individual `add_ace identifier.fivem:SEU_ID prfrp.officer allow` diretamente no `server.cfg`, sem colocar identificadores privados ou chave Cfx no GitHub. O servidor local precisa continuar aberto durante o jogo; com 8 GB de RAM, o desempenho pode ficar limitado.


Versão jogável standalone para **GTA V Legacy + FiveM**, sem QBCore, sem SQL, sem hospedagem paga e sem necessidade de modificar a versão web. Scripts de simulação fictícia, não vinculados à PRF real.

## O que funciona

- `/prfajuda`: consulta comandos.
- `/prfservico`: começa/encerra o turno PRF (permissão ACE obrigatória).
- `/prfviatura [modelo]`: solicita a Trailblazer por padrão; aceita os modelos permitidos na frota.
- `/prfmoto`: informa que a BMW GS da referência ainda não está instalada. A `policeb` disponível em F9 é uma moto de teste do GTA.
- `/prfbase`: marca o posto provisório de Sandy Shores no GPS; não cria a construção da foto.
- `/prfchamado`: recebe uma das seis ocorrências fictícias, com NPC, etapas, marcação no GPS e rota.
- Chegar ao marcador e apertar **E** três vezes para avançar as etapas e finalizar; o **servidor** confere jogador, ocorrência e distância.
- `/prfcancelar`: cancela a ocorrência em andamento.
- `/prfstatus`: consulta status e total de ocorrências concluídas naquela sessão.

Esta é uma **base operacional inicial de demonstração**, não um servidor aberto 24h, nem um RP multiplayer completo. Não há banco de dados, inventário, economia ou persistência de carreira. O `prf_tablet` antigo **não é instalado**, pois requer QBCore.

## 1. Instale gratuitamente o FXServer e o FiveM

1. Você precisa ter **GTA V original compatível** e o cliente FiveM instalado para jogar; o servidor em si é gratuito.
2. Crie uma conta Cfx.re e uma **chave de registro gratuita** no [Cfx Portal](https://portal.cfx.re/). **Não salve nem envie essa chave ao GitHub ou ChatGPT.**
3. Baixe o **artifact Windows recomendado para FiveM Legacy** pelo guia oficial [Servidor FiveM + txAdmin](https://docs.fivem.net/docs/server-manual/setting-up-a-server-txadmin/). Para o GTA V Legacy, o executável é `FXServer.exe` (Enhanced usa outro artifact).
4. Extraia para `C:\FXServer` (ou reutilize o que já instalou). Abra `C:\FXServer\FXServer.exe` **sem** `+exec`.
5. Abra o endereço informado pelo console, normalmente `http://localhost:40120`. Vincule sua conta usando o PIN privado e crie a senha administrativa.
6. No assistente, escolha **Popular Recipes → CFX Default FiveM**. Não precisa instalar QBCore nem banco SQL. Insira a chave Cfx.re **somente no txAdmin**. Use **Save & Run Server**.
7. Use seu perfil existente `C:\txData\FiveMBasicServerCFXDefault_F3288B.base`, que contém `server.cfg` e `resources`. O nome pode variar em outras instalações.

## 2. Instale o pacote PRF RP no servidor

### Pelo instalador do ZIP

1. Baixe o repositório como ZIP no GitHub: **Code → Download ZIP** e extraia tudo.
2. Execute `fivem/scripts/setup-prf-legacy.cmd`, ajustando `SERVERDATA` para a pasta do seu perfil txAdmin se necessário.
3. O instalador prepara o modelo da Trailblazer, copia os três recursos e coloca `prf_trailblazer` e `prf_uniformes_wlukaas` antes de `prf_core` no `server.cfg`. **Não copie somente a pasta da Trailblazer manualmente antes dessa preparação.**
4. Preserve sua regra individual `add_ace identifier.fivem:SEU_ID prfrp.officer allow` no `server.cfg` local.
5. Reinicie o servidor no txAdmin ou execute os quatro comandos do Live Console indicados na atualização acima.

### Opção automática no Windows (PowerShell)

Abra o PowerShell **na pasta extraída deste repositório** e execute:

```powershell
powershell -ExecutionPolicy Bypass -File .\fivem\scripts\install-prf.ps1 -ServerDataPath "C:\txData\FiveMBasicServerCFXDefault_F3288B.base"
```

Troque o exemplo pelo caminho **real da pasta com `server.cfg`**. O script instala o core e, pelo helper `install-prf-assets.ps1`, os dois recursos dos mods presentes no ZIP; configura a ordem de inicialização e faz backup do `server.cfg` quando o modifica. O parâmetro opcional `-LocalTestEveryone` libera o trabalho policial para todos e **não deve ser usado** neste servidor. A execução padrão preserva permissões individuais.

### Quando for abrir para outras pessoas

Remova `add_ace builtin.everyone prfrp.officer allow` e permita apenas um identificador privado autorizado no `server.cfg`:

```cfg
add_ace identifier.fivem:SEU_ID prfrp.officer allow
```

Descubra seu identificador pelos comandos e registros administrativos do servidor. Não cole identificadores privados, senhas ou chaves de registro no GitHub. Proteja o painel txAdmin; ele usa uma porta administrativa diferente da porta do jogo.

## 3. Entre e jogue

1. Inicie o FiveM no **mesmo computador** e pressione **F8**.
2. Digite `connect 127.0.0.1:30120` (se o txAdmin usa a porta padrão).
3. Já no jogo, pressione **F5** (ou `/prfservico`). O personagem vai para a base de teste de Sandy Shores e cria três policiais NPC.
4. Use `/prfviatura` para a Trailblazer. **F9** alterna a frota; **F6 → 4** veste/remove o uniforme.
5. Pressione **F7** para receber um chamado e siga a rota amarela no GPS.
6. Ao chegar, pressione **E** em cada uma das três etapas; o servidor valida a distância e a conclusão.
7. Repita **F7** para outra missão. Use o menu **F6** para status e equipe.

## Avisos e próximos passos

- Uso local gratuito: computador precisa ficar ligado enquanto quiser jogar. Não existe servidor 24h hospedado automaticamente por este repositório.
- Abertura para internet requer configurar firewall/roteador, inclusive a porta de jogo usada pelo FiveM (normalmente 30120 TCP/UDP). **Não** exponha o txAdmin (normalmente 40120) publicamente.
- As coordenadas e missões ficam no arquivo `config.lua`; são pontos iniciais de teste a ajustar no mapa.
- Todo tráfego e funções dependem do FXServer estar instalado e iniciado; os testes de CI do repositório validam o pacote, **não substituem** um teste prático dentro do GTA V/FiveM.
- Não use nomes, uniformes e símbolos oficiais como se o servidor fosse serviço institucional ou afiliado à PRF; este projeto é um simulador fictício.

Fonte oficial: https://docs.fivem.net/docs/server-manual/setting-up-a-server-txadmin/
