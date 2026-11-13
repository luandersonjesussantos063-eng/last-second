# COPOM 0.8 — atendimentos com cenas

O COPOM monta a ocorrência quando você se aproxima do ponto no GPS. São dez tipos, duas variações por tipo e oito regiões. Todos os tipos são oferecidos antes de repetir a fila, mesmo após reiniciar o servidor. As regiões também alternam. A mesma cena pode envolver mais vítimas, outra quantidade de obstáculos, necessidade de guincho em vez de mecânico ou um motorista que foge.

## Como atender

1. Entre em serviço e use **`chamado`** no T ou F7. Siga o GPS.
2. Digite **`copom`** para ver o que falta. A tela também mostra a próxima pendência.
3. Faça as ações no mundo: coloque cones, ouça envolvidos, aborde, consulte, reviste, detenha ou solicite socorro.
4. Aguarde os serviços chegarem e executarem o atendimento. A ocorrência só conta após resolver os objetivos e salvar o progresso.

**`conversar`** ouça a pessoa próxima. **`recolher`** retira um obstáculo. **`inspecionar`** confere um volume ou prende a carga na traseira do caminhão. Essas ações demoram de quatro a sete segundos e exigem ficar perto, a pé. Também funcionam segurando **E** junto ao alvo; soltar a tecla interrompe. A tecla não avança um contador de etapas.

**`sinalizar`** ou `cone` equipa cones: Z/botão direito + clique coloca cada um. Dois cones próximos à cena cumprem a sinalização. `guardarcone` encerra a colocação e `recolhercones` retira os cones.

| Ocorrência | O que acontece e como resolver |
| --- | --- |
| Pane no acostamento | Carro avariado e motorista no local. Sinalize, ouça o motorista e solicite mecânico ou guincho conforme a necessidade relatada. |
| Colisão com vítimas | Dois carros danificados, testemunha e uma ou duas vítimas. Sinalize, ouça a testemunha, chame ambulância junto a cada vítima e remova os dois carros com guincho. |
| Carga espalhada | Caminhão, motorista e três ou quatro obstáculos físicos na via. Sinalize, ouça o motorista e recolha cada objeto. |
| Direção perigosa | Condutor circulando; pode fugir da parada. Intercepte com abordar, consulte os documentos, use bafômetro e prenda o suspeito diante do resultado positivo fictício. |
| Veículo furtado | Carro com alerta fictício; o suspeito carrega uma arma e pode fugir. Pare, consulte documento, mande descer, aborde a pessoa, reviste, prenda e recupere o carro com guincho. |
| Motoristas ameaçados | Dois ou três agressores armados e uma vítima. Contenha o ataque, prendendo quem se render, socorra a vítima e ouça seu relato. |
| Pessoa desorientada | Uma pessoa andando junto à via. Converse, aborde e mande seguir. Conduza até a área verde marcada e solicite avaliação médica. |
| Veículo em chamas | Um ou dois carros pegando fogo e motoristas feridos fora deles. Sinalize, chame bombeiros junto a cada carro e ambulância junto a cada motorista. |
| Carga insegura | Caminhão aberto, motorista e volumes para verificar. Sinalize, converse, consulte os documentos, inspecione os dois ou três volumes e prenda a carga junto à traseira. |
| Equipe sob ataque | Viatura, policial ferido e dois ou três agressores. Solicite reforço, contenha o ataque, peça socorro e ouça o policial. |

## Fiscalização, socorro e remoção

Os comandos existentes cumprem os objetivos: `abordar`, `documento`, `bafometro`, `desce do carro`, `revistar`, `prender` e `seguir`. A revista recolhe a arma real do NPC para o inventário. O documento do veículo furtado mostra o alerta fictício no tablet. O bafômetro do chamado de direção perigosa mostra o resultado ligado àquela ocorrência.

Fique perto do alvo e digite `ambulancia`, `mecanico`, `bombeiros` ou `guincho`. A ambulância escolhe a vítima pendente mais próxima, em vez de tratar o policial. Havendo duas vítimas, faça um atendimento de cada vez. O guincho da ocorrência espera o socorro e a fiscalização terminarem, não embarca veículo ocupado e precisa retirar o carro fisicamente do local. Se o acesso estiver bloqueado, o atendimento pode falhar; libere espaço e solicite novamente.

A prisão no chamado conserva o NPC em custódia. A entrega na base continua separada: `entrar no carro` → conduzir à base → desembarcar → `registrarprisao`. Isso registra a prisão no histórico; não é necessário manter o chamado aberto durante todo o transporte.

`finalizar` mostra o que falta e não pula objetivos. `cancelar`, sair de serviço, morrer ou exceder o tempo da ocorrência limpa a cena sem contar atendimento concluído. Falha ao montar a cena ou perda de um envolvido necessária ao atendimento também é informada, em vez de deixar um ponto vazio que possa ser concluído. Se falhar a gravação do progresso, a cena resolvida aguarda uma nova tentativa de salvamento, sem contar duas vezes.

## Validação e configuração

O catálogo, variações, modelos e posições ficam em `prf_core/copom_config.lua`. As cenas têm poucos NPCs/objetos e só são criadas perto do jogador. O servidor verifica sessão, proprietário, modelo, distância e objetivos. Os antigos eventos de avançar/finalizar por E foram removidos.

Testes em Lua cobrem as vinte combinações, criação das cenas no cliente, rejeição de chão ausente, fila salva, consulta/abordagem/prisão, serviços para NPCs, remoção, tempos de trabalho, cancelamento, mensagens antigas, falha de gravação e preservação de presos. **GTA V/FXServer não estão disponíveis neste ambiente:** posição do acostamento, navegação dos serviços, física, combate e animações ainda precisam de conferência no FiveM. Todas as identidades, alertas e ocorrências são fictícios.
