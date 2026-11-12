# PRF RP — servidor local FiveM gratuito (Nova Byte)

> **PADRÃO ATUAL: GTA V LEGACY + FiveM Legacy.** Este é o servidor que já está funcionando no Windows, com `FXServer.exe`, `C:\FXServer` e o perfil txAdmin `C:\txData\FiveMBasicServerCFXDefault_F3288B.base`. O GTA V Enhanced **não é necessário**. A opção [Enhanced](enhanced/README.md) foi preservada separadamente, mas não é a instalação recomendada para este projeto agora.

## PRF RP 0.2.3 — farda PRF enviada e fuzis da equipe

O arquivo `GTA 5 Skin PRF.rar` enviado pelo usuário contém uma farda personalizada de **Mr.KobraX** (boné, colete e acessórios). Ele substitui o ped GTA V **`s_m_y_sheriff_01`**, com `.ydd`, `.ytd` e `.ymt`; **não é um ped addon**. O pacote de texturas/modelos não é publicado no repositório, pois não há autorização de redistribuição comprovada para esta farda. O usuário pode instalar a cópia original no próprio servidor.

### Instalar e testar a farda de verdade (Windows Legacy)

1. Baixe o ZIP **PRF_Farda_FiveM_Legacy.zip** disponibilizado nesta conversa e deixe-o em **Downloads**. Alternativamente, coloque o RAR original **GTA 5 Skin PRF.rar** em Downloads; nesse caso pode precisar do **7-Zip**.
2. Baixe a versão atualizada do repositório no GitHub (**Code → Download ZIP**) e extraia.
3. Execute `fivem/scripts/setup-prf-legacy.cmd` (atualiza o script do uniforme e o fuzil).
4. Execute `fivem/scripts/setup-prf-skin.cmd` (instala a farda; confere os três arquivos por **SHA-256**, preserva backups e registra `ensure prf_skin_replace` antes do `ensure prf_core`). O instalador opcional `setup-prf-assets.cmd` também detecta a farda em Downloads.
5. No txAdmin → Live Console, rode separadamente **`refresh`**, **`ensure prf_skin_replace`**, **`restart prf_core`**. Depois saia e entre novamente no FiveM para renovar as texturas.
6. Pressione **F5** para entrar de serviço. A farda PRF deve ser equipada automaticamente no jogador e em seus três NPCs quando o recurso estiver ativo. F6 → 4 alterna a farda fora do veículo. Pressione **K** para sacar/guardar a **carabina `WEAPON_CARBINERIFLE`** fictícia do GTA V.

**Apenas policiais em serviço autorizado** recebem a arma por esses comandos: o servidor mantém o controle de permissão ACE `prfrp.officer`; os três NPCs são criados somente ao iniciar o turno, e os equipamentos da equipe são eliminados ao sair. Não concedemos fuzis a cidadãos NPCs. A IA dos colegas reage aos agressores identificados, não a civis aleatórios.

**Limitação:** o skin é um *replace* de `s_m_y_sheriff_01`, então xerifes NPCs com esse mesmo modelo também podem aparecer com a farda PRF. Não há um ped standalone separado neste pacote. A renderização/streaming do traje e o comportamento da arma ainda exigem teste dentro do FiveM Legacy.

## Localizar a nova base PRF de Chumash (v0.2.2)

O mapa do autor **LN3D3V** foi inspecionado: os objetos principais de `prfminibaseln3d3v.ymap` estão perto de **X -3026, Y 367, Z 14**, junto à **Great Ocean Highway, região de Chumash (costa oeste)**. As coordenadas são derivadas do arquivo do mapa; a localização da porta e do estacionamento ainda requer teste dentro do FiveM.

Após instalar e iniciar `prfMiniLN3d3v` no txAdmin, **F10** ou **`/prfbase`** coloca uma rota no GPS até a construção. Ela aparece no mapa como **PRF RP | Nova base Chumash** quando o recurso está iniciado. O comando avisa se o mapa não estiver funcionando, inclusive se houver problema com a exigência `/assetpacks`.

**Importante:** o comando **F5** ainda inicia o turno na base de testes em Sandy Shores. Não alteramos o teleporte nem a posição da garagem sem conferir o terreno e a entrada da construção, para não repetir o erro de nascer no telhado.

## Integração opcional: base PRF LN3D3V e Equinox 2020 PRF

Foi acrescentado um instalador separado para os dois mods enviados. Conforme a autorização de publicação declarada pelo usuário, a Equinox poderá ser incluída no repositório com os créditos dos autores; o workflow verificará o hash original antes de adicionar os arquivos. Execute primeiro o setup-prf-legacy.cmd e depois o **fivem/scripts/setup-prf-assets.cmd**. O script procura a Equinox integrada no repositório (ou o RAR em Downloads) e o mapa em Downloads, instala o mapa como **prfMiniLN3d3v** e a viatura como **prf_equinox_replace** no FXServer Legacy. A Equinox fica disponível por **/prfviatura police** ou pela tecla F9 (quinta opção). A Equinox substitui globalmente o modelo police do GTA V, não é addon. A construção permanece na localização original do autor; ainda não alteramos o teleporte da base provisória de Sandy Shores. Use **/prfassets** em serviço para conferir se os resources iniciaram. Consulte o [guia completo dos arquivos](assets/README.md) e as restrições de redistribuição e dependência /assetpacks.

## Correções v0.2.1 — garagem, uniforme, giroflex, sirene e apoio armado

Esta versão corrige a garagem que criava a viatura **sobre o telhado**. O jogo agora procura um nó de rua próximo, aguarda o solo carregar e só posiciona a viatura se encontrar uma rua livre. Se não houver local válido, mostra um aviso em vez de deixá-la suspensa. Ao pedir uma nova viatura em qualquer lugar, ela utiliza um ponto de via próximo.

O **menu F6** foi refeito: pressionar **4 agora solicita o uniforme**, não a mudança de turno. A opção só troca a roupa quando o personagem está **fora da viatura**. Os três colegas NPC usam o mesmo modelo rodoviário do GTA V e recebem pistolas, usadas contra um agressor identificado após dano ao jogador ou à equipe.

**L** liga/desliga o **giroflex** e **O** ativa/silencia a **sirene** das viaturas de emergência do GTA V; esses controles também dependem da viatura equipada. Para as luzes funcionarem, o modelo deve ser um veículo de emergência com sirene nativa. Não foram importadas barras de luz, veículos ou fardas oficiais da PRF.

Enquanto seu personagem estiver em serviço, o cliente tenta impedir o procurado e o envio de policiais hostis do GTA V para ele. Essa configuração é restaurada ao encerrar o turno. O atendimento dos três aliados ocorre em NPCs locais e ainda precisa ser validado visualmente no FiveM.

**Atualização no computador:** baixe novamente **Code → Download ZIP**, extraia e execute `fivem/scripts/setup-prf-legacy.cmd` no Windows. No txAdmin, rode `refresh` e depois `restart prf_core` em linhas separadas. Se o recurso aparecer reiniciado, reconecte no FiveM se necessário. O GitHub não instala automaticamente essas alterações no seu computador.

## PRF RP 0.2.0 — Posto operacional, frota, três companheiros e teclas

A versão atual usa **somente recursos nativos do GTA V Legacy**, sem downloads pesados. Há um posto de serviço provisório junto à delegacia de Sandy Shores, marcado no mapa, com **garagem**, **vestiário**, **COPOM**, **armaria**, cones/barreiras e pontos de interação **E**. Isso **não é um edifício MLO 3D personalizado nem uma réplica real da PRF**; para isso serão necessários mapa e texturas próprios ou licenciados.

Três policiais **NPC** são criados quando você entra de serviço. Eles acompanham o jogador a pé e são colocados nos bancos livres da viatura quando o personagem dirige; na motocicleta, a equipe acompanha somente a pé. Para reagrupar, use **J**. Os NPCs são locais ao cliente, não jogadores reais nem policiais com IA completa. Para preservar FPS, a equipe atualiza a cada 1,7 s.

A frota tem quatro **veículos originais do GTA V** (`police3`, `police2`, `sheriff2`, `policeb`), com cores provisórias em carros compatíveis. São equivalentes para teste e **não possuem as carrocerias e adesivos oficiais PRF**. O uniforme disponível no vestiário usa o ped rodoviário nativo `s_m_y_hwaycop_01`, não a farda real; trocar o modelo pode redefinir a aparência anterior do personagem.

Há seis ocorrências fictícias, com condutores NPC, GPS e **três etapas acionadas com E**, validadas pelo servidor antes de registrar conclusão. O acesso policial continua exclusivo para quem tiver `prfrp.officer` no ACE, sem permitir liberar ações pelo cliente.

| Tecla | Ação |
|---|---|
| **F5** | Entrar/sair de serviço |
| **F6** | Abrir menu operacional; usar **1–9** ou setas e Enter |
| **F7** | Solicitar ocorrência COPOM |
| **F9** | Alternar e solicitar viatura da frota |
| **J** | Reagrupar seus três policiais NPC |
| **L** | Ligar/desligar giroflex |
| **O** | Ativar/silenciar sirene |
| **K** | Sacar/guardar carabina do serviço, após F5 |
| **E** | Interagir com posto ou avançar etapa no local do chamado |
| **Botão direito do mouse** | Apontar a arma (controle padrão do GTA V) |

**Notebook:** se teclas F5–F9 exigirem `Fn`, pressione `Fn` junto. Os atalhos podem ser remapeados no FiveM em **Settings → Key Bindings → FiveM**. Se o cliente estiver com janela de chat/console aberta, feche-a antes de usar os atalhos.

### Atualização no computador (sem apagar seu servidor)

1. Baixe o ZIP do GitHub (**Code → Download ZIP**) e extraia.
2. Execute `fivem/scripts/setup-prf-legacy.cmd`. Ele copia os **sete arquivos** do `prf_core` na pasta existente `C:\txData\FiveMBasicServerCFXDefault_F3288B.base`, preservando os outros recursos. Se a pasta mudou, edite `SERVERDATA` no CMD.
3. No txAdmin **Live Console**, rode `refresh` e depois `ensure prf_core`, em **linhas separadas**.
4. Na sessão do FiveM, use **F5** para entrar de serviço e confirme que aparecem os **três NPCs**. Se sua permissão ACE só foi concedida no console, salve a regra no `server.cfg` local para ela persistir após reiniciar o servidor.

**Atenção:** o GitHub não atualiza automaticamente os arquivos na pasta do FXServer. Somente depois de copiar/instalar e reiniciar o recurso a versão 0.2.0 será usada no jogo. Os testes automatizados verificam estrutura e regressões, mas **não substituem teste visual e jogável no FiveM**.

## Retomar o servidor Legacy que já criamos

Se o txAdmin já mostrou `Started resource prf_core`, **não reinstale o servidor**: basta abrir `fivem/scripts/start-prf-legacy.cmd` (ou continuar iniciando seu `C:\FXServer\FXServer.exe`) e usar seu perfil txAdmin existente. Quando o GTA V Legacy terminar de instalar, abra o FiveM Legacy, pressione **F8** e execute `connect 127.0.0.1:30120`.

Para atualizar os sete arquivos do recurso do GitHub no servidor Legacy existente, baixe o ZIP mais recente deste repositório e execute **`fivem/scripts/setup-prf-legacy.cmd`** dentro do ZIP extraído. O instalador confere o perfil que você já criou, copia somente os arquivos de `prf_core` para `resources\[prf]\prf_core`, faz backup do `server.cfg` antes de modificá-lo e não concede acesso policial a todos. No **txAdmin → Live Console**, execute `refresh` e depois `ensure prf_core`, **cada comando separado**. Se a pasta do seu perfil mudou, edite a variável `SERVERDATA` no início do .cmd ou use o PowerShell com `-ServerDataPath`.

**Segurança:** mantenha a liberação individual `add_ace identifier.fivem:SEU_ID prfrp.officer allow` diretamente no `server.cfg`, sem colocar identificadores privados ou chave Cfx no GitHub. O servidor local precisa continuar aberto durante o jogo; com 8 GB de RAM, o desempenho pode ficar limitado.


Versão jogável standalone para **GTA V Legacy + FiveM**, sem QBCore, sem SQL, sem hospedagem paga e sem necessidade de modificar a versão web. Scripts de simulação fictícia, não vinculados à PRF real.

## O que funciona

- `/prfajuda`: consulta comandos.
- `/prfservico`: começa/encerra o turno PRF (permissão ACE obrigatória).
- `/prfviatura [modelo]`: gera uma das quatro viaturas GTA V originais (veja frota acima), sem pacote externo.
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

Troque o exemplo pelo caminho **real da pasta com `server.cfg`**. O script copia os sete arquivos do recurso, faz backup do `server.cfg` antes de alterá-lo e adiciona `ensure prf_core`. O parâmetro opcional `-LocalTestEveryone` libera o trabalho policial para todos e **não deve ser usado** neste servidor. A execução padrão preserva permissões individuais.

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
4. Pressione **F9** para pegar uma viatura ou alterne pelo menu **F6**.
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
