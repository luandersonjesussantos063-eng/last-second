# Base operacional — v1.13

## Frota e pessoas

Três naves procedurais adicionais têm identidade, baia e piloto próprios. Cada ciclo inclui preparação, caminhada para a rampa, embarque com subida e fechamento da escotilha, autorização, táxi, decolagem, patrulha, fila de retorno, aproximação, pouso, táxi para a baia, desembarque e relatório no terminal. O piloto desaparece da circulação durante o voo e reaparece ao desembarcar da mesma nave.

Uma máquina de estados independente da renderização mantém um único dono da pista. O jogador tem prioridade sobre novas solicitações automáticas; uma manobra já autorizada termina antes de liberar a pista. Pedestres na baia impedem a autorização e, na rota reservada, fazem a nave aguardar. Os cascos também atualizam os obstáculos de caminhada. Sair do cockpit cancela a decolagem do jogador ainda na fila. O portão agora sobe verticalmente para não obstruir a central.

Os antigos percursos sem função foram substituídos por postos: técnicos de pista, inspeção, engenharia, medicina, suprimentos, comunicações e operadores de voo, navegação e sensores. Há pausas de trabalho, gestos de operação/reparo e dispositivos de inspeção. Técnicos retornam ao terminal quando a nave está fora da baia. Não são adicionados diálogo, combate ou missões.

## Segundo andar e tecnologia

Rampa contínua, passarela com guarda-corpos e central elevada na frente direita do hangar. O piso fica a oito metros do térreo. O jogador pode subir, circular na central e descer usando os controles existentes. A nave continua usando a pista central no térreo. A navegação limita as bordas elevadas, separa móveis por piso e impede entrar lateralmente na parte alta da rampa.

A central possui três consoles principais, dois postos laterais, operadores em serviço, painéis grandes, janela lateral para o hangar e janela frontal transparente para o espaço real da cena. Os monitores mostram tráfego, radar, telemetria, energia, engenharia, equipe, suporte médico e suprimentos. Os dados são da simulação do jogo, sem serviços externos. As salas térreas ganharam telas, equipamentos de diagnóstico, iluminação estrutural, scanner médico e ferramentas de oficina.

## Desempenho e validação

Os monitores compartilham um atlas de canvas: 1024 × 256 no celular, 2048 × 512 no computador. Atualização limitada a aproximadamente 1,3 e 2,5 vezes por segundo. Geometria fixa agrupada por material; cada nave agrupa casco e motores por material; pessoas compartilham sete lotes instanciados para corpo, membros e dispositivo. Não foram acrescentados downloads de modelos ou bibliotecas. Operações continuam quando a base sai do campo visual, mas atualização de telas e matrizes da tripulação é suspensa enquanto a extensão não está visível.

Quatorze testes unitários/de artefatos cobrem ciclos completos das três naves, exclusividade e prioridade da pista, proteção a pedestres, funções dos trabalhadores, rampa/guarda-corpos e verificações anteriores de voo e assets. O teste de navegador atravessa as quatro salas, sobe e desce até a central usando o controle do jogador, observa ciclos completos, pausa a simulação e continua pelo voo, pouso e reinício. São usados Chromium com toque emulado e perfil desktop, renderização real e avanço acelerado da simulação. Não há medição de FPS em celular físico.
