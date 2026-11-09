# Sons da viatura

Fonte: `videoplayback.m4a`, 12,65 s, fornecido e autorizado pelo usuário nesta conversa. A gravação completa permanece no anexo; somente três cortes necessários ao jogo são distribuídos.

| Comando | Arquivo | Trecho de origem | Uso |
| --- | --- | --- | --- |
| H | perseguicao.mp3 | 5,56–6,72 s | Contínuo até desligar |
| F, ao solicitar parada | parada.mp3 | 9,13–10,98 s | Ordem de parada por 4,2 s |
| B | passagem.mp3 | 6,98–8,10 s | Pedido curto de passagem |

Conversão para MP3 mono 64 kbit/s: primeiro recorte e timestamps zerados, depois filtros, ganho calculado pelo PCM e fades curtos. Cada MP3 decodificado é verificado contra silêncio. Os arquivos somam 34.610 bytes. São trechos da gravação fornecida, sem substituição por sirene sintetizada. Os efeitos de motor, passos e rádio continuam separados.

A reprodução usa um único comando principal por vez. Um pedido de passagem interrompe brevemente a perseguição e, depois, a retoma se H permanece ligado. Solicitar parada desliga a perseguição e executa a ordem própria. O contexto de áudio é suspenso na pausa, incluindo os trechos gravados. Volume e mute passam pelo mesmo controle mestre.

Manifesto com hash do original, limites de origem e hashes dos MP3: manifest.json.

Correção 2.1.1: os cortes anteriores tinham duração válida, mas eram silenciosos porque o fade de saída era aplicado no tempo do arquivo completo antes do corte. Os arquivos foram reconstruídos; o RMS decodificado de cada um é aproximadamente −18,45 dBFS. O teste passa a analisar a gravação isolada, além da saída geral do jogo.
