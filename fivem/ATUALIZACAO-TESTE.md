# Atualização 0.4.0 — viatura, física da favela e comandos no T

## Instalar

1. Pare o servidor no txAdmin.
2. Extraia o ZIP completo desta atualização.
3. Entre em `fivem/scripts` e abra `setup-prf-update.cmd`.
4. Aguarde terminar. Inicie o servidor e feche/reabra o FiveM.

O perfil padrão é `C:\txData\FiveMBasicServerCFXDefault_F3288B.base`; ajuste `SERVERDATA` no CMD se o seu caminho for outro. O instalador preserva a permissão ACE e faz backup em `_prf_backups`, fora de `resources`.

## Jogar pelo T

Abra o chat com **T**, digite a palavra e aperte Enter. Pode usar com ou sem a barra.

- `servico`: entrar/sair de serviço.
- `viatura`: pegar o SUV PRF.
- `farda`, `fuzil`, `equipe`: roupa, arma e reagrupar os colegas.
- `abordar`: pessoa ou carro à frente.
- `documento`, `antecedentes` ou `passagem`: documento e histórico fictícios da pessoa abordada.
- `revistar`, `liberar`: fiscalizar ou encerrar a abordagem atual.
- `giroflex`, `sirene`: luzes e som da viatura.
- `guincho`, `reforco`, `blitz`: remoção, apoio e cones.
- `ronda`, `cancelarronda`, `chamado`, `cancelar`: patrulhas e ocorrências COPOM.
- `base`, `favela`, `ajuda`: GPS e comandos.

Para abordar uma pessoa a pé, entre em serviço, saque o fuzil e mantenha a mira nela por meio segundo, a até 15 metros. Ela se rende com as mãos na cabeça. Vá até três metros dela e digite `documento` ou `revistar` no T. `liberar` encerra a abordagem. Ela permanece rendida quando você baixa a arma para digitar. Colegas da sua equipe e do reforço são preservados.

Os dados são **fictícios e gerados para o jogo**. A mesma pessoa conserva documento e histórico em novas consultas durante a sessão. Não há consulta real nem integração com inventário ou banco externo.

Os painéis F6/F11 foram retirados. Binds antigos dessas teclas mostram ajuda no chat; os números antigos não acionam opções. Atalhos diretos de viatura, arma e sirene continuam funcionando.

## Correções

- O atualizador conserva uma Trailblazer completa já instalada; caso contrário, instala a Equinox incluída. Desliga o outro replace conhecido para evitar dois modelos substituindo `police`. `viatura` e o primeiro F9 usam o SUV PRF e mantêm a pintura original.
- Os quinze modelos da favela registram `physicsDictionary` com o nome de cada YDR. Antes as casas tinham colisão embutida, mas o YTYP não apontava para ela. A geometria original foi preservada e as máscaras de colisão, materiais e triângulos foram verificados.
- O pacote da base com interior usado na versão anterior foi preservado, assim como nascimento na base, fardas e fuzis dos colegas.

## Conferir no jogo

Testes de código e de instalação passaram; o GTA V/FiveM não foi executado neste ambiente. Confira a viatura, a rendição, a animação da revista e os tiros contra as paredes após reconectar. A favela continua limitada a 12 NPCs locais; os confrontos das rondas são separados. A autorização ACE individual continua obrigatória.
