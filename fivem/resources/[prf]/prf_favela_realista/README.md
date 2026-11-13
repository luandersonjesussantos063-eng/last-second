# Favela Realista — conversão de teste para FiveM

Origem: `ecd196-Favela Realista BETA 1.0.zip`, fornecido pelo usuário. O XML identifica **CRAZY MODz** como criador. Preserve autoria e condições do pacote original; esta integração não reivindica autoria dos modelos.

O XML de Map Editor foi convertido para nove setores YMAP e um YTYP com quinze modelos addon. Os 495 objetos originais foram mantidos; os YDR/YTD preservam os bytes de origem e recebem nomes `prffavela_*` para não substituir quadros e objetos dos assaltos do GTA. O cenário original também contém objetos distantes do núcleo da favela; os setores mantêm essa distribuição.

Os 64 NPCs, cinco veículos e um pickup do XML não são criados de uma vez. O script utiliza as 63 posições do grupo principal da favela e mantém **até 12 integrantes de gangue próximos do jogador**, adicionando no máximo dois por ciclo. Eles ficam armados, reagem se o jogador os atacar, desaparecem longe e têm intervalo antes de reaparecer. Os confrontos de ronda são controlados separadamente pelo prf_core, somente durante missão aceita.

Use `/prffavela` para marcar a região no GPS. Ela fica aproximadamente em **1180, -125**, na região de Vinewood/Land Act, conforme o XML enviado. O menu F11 oferece uma ronda na favela com pontos extraídos das posições originais.

Instalação: o instalador `fivem/scripts/setup-prf-update.cmd` copia este recurso completo e registra `ensure prf_favela_realista` antes de `prf_core`. Não requer Map Editor, ScriptHook ou modificação do GTA original.

Verificações estáticas incluem limites dos modelos, colisões embutidas, hashes dos binários originais, ponteiros Meta e contagem de entidades. **Aparência, navegação, colisões e desempenho ainda precisam de teste no FiveM.** A população é local ao cliente; não é um sistema persistente de facções multiplayer.
