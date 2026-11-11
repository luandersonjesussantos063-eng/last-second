# Uniformes PRF v2 — wlukaas

Adaptação do arquivo `PRF v2 - by wlukaas.zip` enviado pelo usuário para streaming no **FiveM/GTA V Legacy**. Os 20 arquivos `.ydd`/`.ytd` são os originais, sem alteração de conteúdo, renomeados para `colecao_de_stream^arquivo` conforme as pastas indicadas pelo autor. Este é um recurso de substituição de roupas existentes: pode conflitar com outros recursos que substituam as mesmas peças.

O ZIP do GitHub inclui este recurso e os 20 binários. O instalador `fivem/scripts/setup-prf-legacy.cmd` copia tudo e configura `ensure prf_uniformes_wlukaas` antes de `ensure prf_core`. `Config.Uniform` no `prf_core` seleciona os perfis; **F6 → opção 4** e o vestiário usam o mesmo fluxo existente. Os nomes de coleção usados pelas natives são os nomes curtos abaixo, sem o prefixo do ped utilizado nos nomes dos arquivos de streaming.

| Personagem | Peças fornecidas: coleção e índice local |
| --- | --- |
| Masculino `mp_m_freemode_01` | Camisa: componente 11, `mp_m_christmas2017`, 1. Colete: componente 9, `male_freemode_business2`, 0. Boné: prop 0, `mp_m_christmas2017`, 1. |
| Feminino `mp_f_freemode_01` | Camisa: componente 11, `female_heist`, 3. Calça: componente 4, `female_heist`, 1. Colete: componente 9, `female_heist`, 0, 1 ou 2. Acessório: componente 7, `female_heist`, 1. Boné: prop 0, `mp_f_christmas2017`, 1. |

Textura `a` corresponde ao índice local de textura 0. Não use esses índices como índices globais de roupa. O pacote não fornece calça masculina, sapatos ou todas as variações de braços; essas peças continuam sendo do GTA. Confira encaixe e aparência no jogo antes de escolher outras peças.

O `prf_core` preserva o sexo de personagens freemode existentes. Para outro modelo de personagem, usa `Config.Uniform.defaultSex` e valida o perfil em um ped temporário local antes de trocar o modelo do jogador. Se faltarem natives, coleções ou índices, o uniforme não é aplicado. Ao retirar, a restauração continua limitada ao modelo anterior e às roupas padrão; rosto e aparência personalizada completos não são salvos.

Os arquivos são RSC7, compatíveis com o formato do GTA V Legacy. A adaptação não inclui conversão Enhanced nem teste visual executado dentro do GTA/FiveM neste ambiente.

Crédito original: **@wlukaas**. O README original agradece o download, indica substituição de arquivos nos DLCs Heist/Business2/Christmas2017 e termina com “Compartilhe”. Não foi encontrada licença formal adicional no arquivo. A origem, os caminhos e os hashes estão em `origem.json`.

Referência das natives: https://docs.fivem.net/docs/scripting-manual/using-new-game-features/collection-based-natives/
