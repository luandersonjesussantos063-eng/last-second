# Entrega web 2.20.0 — mundo conectado

Esta entrega integra a lista solicitada ao simulador single-player existente. O mundo é ficcional, estilizado e local. Não é um servidor GTA/FiveM.

| Área | Entrega jogável | Limite |
| --- | --- | --- |
| Equipe | Desvios de móveis, portas, carros e pessoas; embarque escalonado; tarefas, pausas, água, revisão sentada, conversas andando e retorno ao posto | Decisões e falas baseadas em regras, com trajetos e busca delimitados |
| Trânsito | Carreta, bitrem, caminhão-baú e ônibus com dimensões próprias, ultrapassagem em trecho de duas faixas por sentido, reação à sirene e ao horário | Física cinemática, sem tráfego de uma cidade real |
| Balança | Plataforma, sinal verde/vermelho, leitura de 6 segundos em kg/toneladas, pesos por eixo, relatório, saída física e pátio para excesso | Massas e referências fictícias; não consultar legislação no jogo |
| COPOM | Pane, objeto, colisão com vítima, carreta e incêndio; cenas físicas e sinalização; apoio, mecânico, resgate, bombeiros, guincho e encerramento por etapas | Serviços e personagens limitados por cena, sem hospitais ou combate a incêndio completo |
| Cidades | Vila da Serra e Santa Aurora, acessos dirigíveis, ruas, quarteirões, semáforos, combustível, oficinas, comércio e pedestres | Áreas estilizadas; fachadas de comércio não oferecem interiores completos |
| Viaturas | Portas com recorte real, passageiros, faróis, freios, danos, suspensão visual, combustível e reparos | Sem física completa de suspensão/colisão de deformação |
| Fiscalização | Documentos fictícios, relato, vistoria, decisões, registro; retenção chama guincho e transporta carro a vagas reutilizáveis | Sem consulta governamental ou aplicação real de penalidades |
| Comando/GPS | Rádio por nomes, funções, missões, mapa, destinos e rota pelo grafo de ruas | Mapa local ficcional, sem geolocalização |
| Som | Sirenes autorizadas preservadas, motor, tráfego pesado, chuva, passos, portas e rádio | Voz livre não implementada; diálogo contextual em texto |
| Clima | Chuva visível, neblina, pista com material molhado, visibilidade e aderência diferentes | Reflexos PBR simples, sem ray tracing ou reflexão completa da cena |
| Carreira | XP, avaliação, turnos e kit de campo desbloqueado em 250 XP, uma utilização por dia | Graduações são ficcionais; não há uma árvore extensa de equipamentos |
| Salvamento | Resultados, carreira, histórico, relógio, recursos e limite diário do kit no navegador | Reabertura inicia serviço seguro na base; não restaura NPCs ou incidentes em movimento |

## Controles e roteiro

- U: tablet, mapa/GPS, clima, abastecimento/oficina, kit e salvamento.
- T: comando, ordens e COPOM. F: etapas da ocorrência, pesagem e interação próxima.
- O menu permite entrar diretamente em uma ocorrência ou na balança, além da patrulha normal.
- Na balança, pese o caminhão parado, aguarde seis segundos e registre a decisão. Aguarde o próximo veículo entrar fisicamente.
- Nos COPOM, isole a cena, converse/vistorie, aguarde o apoio e só encerre após o atendimento necessário.
- As cidades ficam a leste da rodovia em z=-500 e z=500; selecione o destino no tablet.
- Pare junto à bomba/oficina para usar o serviço. O kit de manutenção recupera até20 pontos por dia após250 XP.
- Salvar fica neste navegador. Reiniciar preserva a carreira e disponibiliza uma viatura revisada.

## Verificação

`npm test`, `npm run check` e `npm run build:site` validam a publicação. Os testes no Chromium verificam a cena real, os controles e os fluxos operacionais. Emulação de celular não substitui uma medição de desempenho em aparelho físico.

## Serviços ainda necessários para outras modalidades

Multiplayer exige servidor de tempo real, autenticação, banco, sincronização, moderação e testes de carga. Conversa livre com IA e voz exige backend, serviço de modelo/voz e configuração de credenciais e custos. Nenhum desses serviços foi contratado, nenhuma chave foi exposta no frontend e o GitHub Pages continua hospedando o jogo estático.
