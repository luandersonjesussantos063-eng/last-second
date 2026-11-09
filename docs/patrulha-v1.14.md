# Polícia espacial, uniformes e áudio — v1.14

## Identidade visual

Cinco conjuntos de roupas por função: polícia espacial com capacete selado, visor, proteção e distintivo; operadores com jaqueta identificada e headset; manutenção com macacão, capacete de segurança e ferramentas no cinto; medicina com uniforme claro, identificação verde e touca; suprimentos com roupa de trabalho e bolsos. Não são apenas trocas de cor: acessórios e silhuetas variam. Corpos, membros e acessórios continuam em lotes instanciados; cada acessório contém apenas os personagens da função correspondente.

A nave do jogador e as três patrulhas usam o mesmo projeto policial: casco branco e azul escuro, asas enflechadas com espessura e bordas chanfradas, motores duplos, identificação POLÍCIA ESPACIAL, brasão e barra luminosa vermelha/azul. As baias, rotas, pilotos e controles de embarque são preservados.

## Áudio

Web Audio sintetiza efeitos sem downloads, bibliotecas ou arquivos adicionais. Há um único contexto, um buffer de ruído compartilhado, seis fontes contínuas (ambiente, ventilação, motor da cabine e três motores de patrulha), atenuação por distância, estéreo pela orientação e compressor na saída. Os novos efeitos transitórios têm limite de 24 vozes, com desconexão ao terminar. A automação dos volumes contínuos é limitada pelo relógio de áudio, evitando acumular comandos durante avanços acelerados da simulação.

Eventos: passos do jogador e da tripulação, servos e fechos das portas, portão, escotilhas/embarque, motores variando com impulso/turbo, aviso policial curto na liberação da patrulha, reparos, scanners/consoles, botões e impacto na nave. Passos acompanham distância percorrida e não tocam com o personagem parado. Não se acrescenta vento ou som propagando no vácuo: em voo, o motor é ouvido dentro da cabine. Os equipamentos próximos têm efeitos discretos, sem bip a cada quadro.

Volume e mute disponíveis na interface, com preferência local. Todos os sons antigos também passam pelo controle mestre. Pausa/perda de foco suspende o contexto; mexer no volume durante a pausa não o retoma. Falha de inicialização de áudio mantém o jogo funcionando sem som.

## Verificação

Vinte testes unitários/de artefatos incluem escolha de uniforme por função, distância/estéreo, limite e liberação das vozes, efeitos amostrados e sintetizados, indisponibilidade de áudio e versão comum nos URLs dos módulos. Mantêm também os testes de tráfego, rampa, colisão e modelos.

O teste de Chromium, nos perfis móvel e desktop, verifica saída de áudio não silenciosa com analisador, mute, volume e contexto suspenso na pausa; continua por caminhada, portas, central, frota, decolagem, turbo, pouso e reinício. Capturas mostram os modelos reais renderizados. Isso não equivale a medição de FPS nem a teste em celular físico.
