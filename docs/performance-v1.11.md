# Last Second v1.11 — revisão de desempenho e controles

## Mudanças

- Dependências locais em vez de importação do engine e decoder em CDNs. Versão fixada, lockfile e manifesto de hashes; sem desativar verificação TLS ou integridade de pacote.
- Asteroides em quatro InstancedMesh com cores individuais. As posições e colisões continuam separadas; a renderização é agrupada.
- Estrutura fixa do hangar agrupada por material; portões e luz de autorização continuam independentes. Menos luzes pontuais; geometrias com arestas arredondadas e arcos no hangar.
- Rochas com deslocamento contínuo e vértices soldados antes do cálculo de normais, eliminando fissuras/faces irregulares causadas por perturbar vértices coincidentes separadamente. Destroços em formas curvas e planeta/lua com texturas procedurais e atmosfera com efeito de borda.
- Texturas dos painéis com resolução física menor e coordenadas lógicas constantes: informações que antes extrapolavam a tela do celular agora cabem. Atualizações alternadas dos três painéis, inclusive durante o boot; HUD só troca textos que mudaram.
- Resolução adaptativa e modo econômico; rastros sem atualizar/desenhar quando invisíveis. O modelo precisa carregar e preparar os shaders antes de liberar Iniciar voo, com progresso e opção de recuperar erro.
- Relógio de simulação único para animações de decolagem, pouso e colisões; pausa não avança o voo. Colisões apenas no controle manual, com varredura do trecho percorrido para evitar atravessar rochas entre quadros.
- Sons de autorização e motor disparados uma única vez por decolagem. Pausa, reinício por toque, liberação de teclas/ponteiros ao cancelar gesto, perder foco ou rotacionar; segundo dedo fora dos botões não rouba o controle de pilotagem.

## Medidas

Modelo original: 7.853.800 bytes. Mobile: 3.100.956 bytes (redução de aproximadamente 60,5%). Desktop: 3.964.876 bytes (49,5%). Os modelos otimizados mantêm oito meshes e 13 primitivas, incluindo os três painéis identificáveis.

Em uma captura do hangar com a nave parada, renderer.info.render.calls passou de 159 para 54 no perfil móvel e de 206 para 54 no desktop. São aproximadamente 66% e 74% menos chamadas de desenho nessa cena, não uma promessa de ganho equivalente em FPS. A captura original usou o mesmo engine 0.186.0 servido localmente, para isolar o jogo da disponibilidade das CDNs. A variação da cena e dos objetos visíveis muda as contagens.

## Verificações

- Seis testes de funções/artefatos: colisão contínua, limite de passo, resolução adaptativa, recuperação sob quadros muito lentos, preservação dos meshes e integridade do engine.
- Chromium com renderização por software, perfil de toque 844×390 e desktop 1280×720. Carregamento real dos GLBs e shaders, zero requisições externas e nenhuma exceção JavaScript no fluxo normal.
- Teste de jogabilidade: ajuda, qualidade, carregamento, decolagem, pausa/retomada, direção, turbo, cancelamento de ponteiro, pouso, nova decolagem, dano e reinício por botão. O teste acelera a simulação e evita desenhar durante esses passos, mas os renders e as capturas usam o renderer real.
- Teste adicional: erro de download do modelo seguido de recarga bem-sucedida; DPR 2 e econômico; pausa por perda de foco e rotação de tela.

Não houve medição em celular físico. Não se afirma taxa de quadros garantida em todo aparelho. WebGL2, drivers, memória disponível, tela e temperatura influenciam o resultado. O teste automatizado valida comportamento e contagens de renderização, não substitui uma sessão no dispositivo.
