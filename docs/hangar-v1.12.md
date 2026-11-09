# Hangar explorável — v1.12

O salão principal passou de 34 para 68 metros de largura. Quatro salas laterais de 20 × 20 metros têm mobiliário próprio: alojamentos, enfermaria, oficina e comando. A pista, o portão e a aproximação automática mantêm o percurso de voo.

O jogador pode iniciar a pé pelo menu ou sair da nave após o pouso. A câmera sai do cockpit e assume altura de 1,65 m; um modelo externo procedural representa a nave estacionada. O embarque exige proximidade da rampa, e os comandos de voo não decolam enquanto o jogador está a pé. Não há saída da nave em voo.

WASD/setas movem, Shift corre e mouse capturado ou arrasto orienta a visão. Um analógico independente permite andar e olhar simultaneamente no celular. Pausa, perda de foco e cancelamento dos ponteiros liberam os controles. Voltar ao cockpit restaura câmera e HUD de voo.

Cada porta usa dois painéis deslizantes. O sensor abre a porta a 5,5 m, aguarda após a saída e mantém a abertura enquanto a passagem estiver ocupada. A colisão considera a largura efetivamente aberta. Movimento em pequenos passos impede atravessar paredes, portas e mobiliário durante quadros mais lentos.

Seis tripulantes no celular e oito no computador percorrem circuitos no hangar e nas salas. São personagens humanoides procedurais com membros animados, sem diálogo ou missões. Seis lotes instanciados compartilham geometria; as partes fixas do cenário são agrupadas por material. A atualização e a exibição desta extensão são suspensas quando a nave está longe da base. Nenhum asset externo ou serviço foi acrescentado.

## Verificação

- Nove testes unitários/de artefatos, incluindo limites das salas, abertura parcial de portas, colisão contínua do pedestre e deslizamento junto às paredes.
- Teste de navegador com Chromium, perfis móvel com toque 844 × 390 e desktop 1280 × 720: início a pé, arrastar para olhar, teclado/analógico, cancelamento de gesto, NPCs em movimento, pausa, entrada nas quatro salas, sensor ocupado, fechamento após afastamento, embarque e saída da nave.
- O mesmo teste continua pela decolagem, turbo, pouso automático, colisão e reinício para detectar regressões de voo.
- Carregamento e renderização reais, com capturas em /tmp/last-second-hangar. Os passos de simulação são acelerados no teste; não representam uma medição de FPS ou validação em celular físico.
