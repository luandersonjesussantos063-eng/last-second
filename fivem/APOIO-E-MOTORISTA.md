# Apoio, comboio e motorista — versão 0.9

Todos os comandos usam o T, com ou sem `/`. Entre em serviço primeiro.

## Chamar apoio

- **`apoio`**: uma viatura com quatro policiais, incluindo o motorista.
- **`apoio 3`**: acrescenta três viaturas, cada uma com quatro policiais. Pode repetir sem apagar as anteriores.
- **`reforco`** e `reforco 3` continuam funcionando.
- **`dispensarapoio`**: dispensa todas as unidades e cancela chamadas pendentes. `dispensar reforco` também funciona.

As viaturas copiam modelo, pintura, cores, vidro e extras da sua viatura. Se estiver de moto, o apoio usa o SUV PRF para acomodar quatro policiais. Um modelo modificado que não tenha quatro bancos é recusado com aviso. Os policiais usam a farda PRF quando instalada e levam fuzis.

O apoio acompanha sua viatura e persegue o veículo em fuga selecionado pela abordagem. Se você estiver a pé, aproxima-se e desembarca para acompanhar e defender contra agressão. As equipes voltam às viaturas quando você segue de carro ou surge uma nova perseguição. Pessoas já rendidas são preservadas. A criação é gradual e aguarda via livre; não há cota fixa de unidades ativas.

## Sair em comboio

1. Pegue sua viatura e deixe-a próxima, ou assuma o volante.
2. Digite **`comboio 3`** para acrescentar três viaturas. `comboio` sozinho chama duas.
3. Saia para a ronda: a primeira acompanha sua viatura e as seguintes acompanham a anterior.

| Comando | Ação |
| --- | --- |
| `pararcomboio` | Para as viaturas do comboio; equipes aguardam embarcadas |
| `retomarcomboio` | Retoma o acompanhamento |
| `desembarcarapoio` | Com você a pé, converte as equipes em apoio fora das viaturas |
| `encerrarcomboio` | Dispensa só unidades e chamadas ainda pertencentes ao comboio |
| `dispensarapoio` | Dispensa todo o apoio |

Ao sair da sua viatura, o comboio aguarda perto dela. Em agressão, as equipes podem desembarcar para defesa. Durante fuga ativa, acompanham o alvo, respeitando a pausa manual. O NPC motorista da sua própria viatura também pode liderar a formação.

## Deixar um NPC dirigir

1. Pegue a viatura, pare e espere seus três colegas estarem próximos.
2. Digite **`motorista`**. Um colega assume o volante e você ocupa um banco de passageiro. Os outros colegas continuam na equipe; um preso conserva o banco reservado.
3. Abra o mapa e marque um destino. O motorista segue as ruas até um ponto acessível próximo à marcação. Pode trocar o destino durante a rota.

Você controla **L (giroflex)** e **O (sirene)**. O motorista ajusta a condução ao estado de emergência que você escolheu; não liga a sirene por conta própria. A mira usa **Z ou o botão direito**, com uma pistola de serviço para a posição de passageiro. K/fuzil alterna essa arma enquanto você estiver nesse banco. A arma temporária é recolhida ao encerrar o modo; uma pistola que você já possuía é preservada.

| Comando | Ação |
| --- | --- |
| `motorista` | Aciona o motorista; se já estiver ativo, solicita devolver o volante |
| `pararviatura` | Freia e aguarda |
| `continuar` | Retoma o destino do mapa após uma pausa ou abordagem |
| `embarcar` ou `passageiro` | Volta ao banco de passageiro da viatura próxima |
| `assumir` | Para, libera o motorista e devolve o volante a você |

Se você desembarcar, o motorista aguarda na viatura. Após uma abordagem, libere o alvo pelo T quando terminar e use `continuar` para seguir o GPS.

## Abordar de dentro da viatura

Mantenha a mira em um alvo por cerca de meio segundo, a partir do banco de passageiro com o motorista ativo. Também pode mirar e digitar `abordar`.

- **Pessoa a pé:** o motorista se aproxima e freia. A ordem de rendição só é aceita com a viatura parada e próxima do alvo. Desembarque para documento, revista, algemas ou prisão.
- **Veículo:** o motorista intercepta e solicita a parada quando chega perto. Quem obedece permanece sob abordagem até você liberar. Se o condutor fugir, a perseguição começa e as viaturas de apoio acompanham.

A exceção de abordagem a partir do carro só vale para o alvo autorizado pelo modo motorista, com velocidade baixa e proximidade verificadas no servidor. Os colegas e as equipes de apoio são excluídos da seleção automática.

## Instalar e validar

Pare o servidor, extraia o ZIP completo, execute `fivem/scripts/setup-prf-update.cmd`, inicie o servidor e reabra o FiveM. O instalador inclui os dois módulos do motorista e mantém a permissão ACE, os dados salvos e a viatura PRF instalada.

Os testes em Lua verificam quatro ocupantes e bancos, aparência, fila, perseguição após desembarque, comboio, pausa, cancelamento durante carregamento, NPC dirigindo pelo GPS, mira, rendição com o carro parado, controle da sirene, troca de volante e preservação de jogadores/armas existentes. Os instaladores são testados com PowerShell em perfis temporários.

GTA V/FXServer não estão disponíveis neste ambiente. Condução, distância entre veículos, obstáculos, animações e desembarque ainda precisam de conferência no FiveM. O trajeto depende do sistema de ruas e direção do GTA; você pode pausar ou reassumir a viatura quando precisar.
