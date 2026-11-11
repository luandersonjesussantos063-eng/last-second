# PRF RP Legacy — mapa LN3D3V e Equinox 2020

Esta integração prioriza o veículo no próprio repositório quando os arquivos YFT/YTD estiverem presentes; também aceita o RAR original local como alternativa. O usuário declarou autorização dos autores para publicação neste projeto. **Créditos: LN3D3V (base), Martinelli e Alessandro da Fonseca (Equinox).**

## Pacotes reconhecidos

- PRF-MAP-994-1-0-1726085655.zip (inclui prfMiniLN3d3v/fxmanifest.lua e stream com YMAP/YTYP/YDR/YTD/YBN).
- Equinox 2020 PRF l By Martinelli (1).rar (inclui police.yft, police_hi.yft, police.ytd, police+hi.ytd).

A **Equinox é um modelo replace**: substitui o carro vanilla police em todo o servidor, não cria um novo modelo exclusivo. police2, police3, sheriff2 e policeb não são substituídos. No PRF RP, a Equinox fica na quinta opção da frota, ou pelo comando /prfviatura police. Giroflex/sirene usam controles GTA V; o mod pode ter iluminação especial feita para ELS, que não está incluído.

**O mapa tem posição própria no mundo do GTA V, em uma rodovia.** O teleporte atual do /prfservico ainda vai à base provisória de Sandy Shores. Não inventamos coordenadas do mapa novo: depois de visitar a construção e identificar a localização, será possível mudar o ponto de serviço/garagem.

## Instalação no Windows (FiveM Legacy)

1. Coloque o ZIP original do mapa em Downloads. A Equinox virá do GitHub após a importação automática confirmada; se os modelos ainda não estiverem no repositório, coloque também o RAR original da Equinox em Downloads.
2. Acesse o GitHub last-second, clique em Code → Download ZIP, extraia o ZIP.
3. Execute fivem/scripts/setup-prf-legacy.cmd para atualizar o prf_core e incluir police na lista de viaturas.
4. Execute fivem/scripts/setup-prf-assets.cmd: ele prioriza a Equinox do repositório e usa o RAR em Downloads se necessário; instala os resources em C:\txData\FiveMBasicServerCFXDefault_F3288B.base\resources\[prf]. Use 7-Zip caso seu Windows não consiga abrir RAR via tar.exe.
5. No txAdmin → Live Console execute os comandos em linhas separadas: refresh, ensure prfMiniLN3d3v, ensure prf_equinox_replace, restart prf_core.
6. Saia e entre novamente no FiveM para atualizar os assets. Use /prfassets para ver o status do mapa e do carro e /prfviatura police para pedir a Equinox.

Para informar caminhos diferentes, execute PowerShell no diretório da cópia do repositório:

    powershell -ExecutionPolicy Bypass -File .\fivem\scripts\install-prf-assets.ps1 -MapZip "C:\CAMINHO\PRF-MAP.zip" -EquinoxRar "C:\CAMINHO\Equinox-PRF.rar"

## Cuidados

- O arquivo de mapa original declara **dependency '/assetpacks'**. O instalador preserva a dependência, adicionando apenas os registros DLC_ITYP_REQUEST de dois arquivos YTYP. Se aparecer erro de assetpacks/entitlement, verifique os artifacts do FXServer e os direitos de uso no Cfx Portal. Não tente contornar essa exigência.
- O instalador modifica somente os diretórios dos resources instalados e acrescenta ensure no server.cfg (com backup). Não mexe na instalação original do GTA V, OpenIV, FXServer.exe ou dados de jogadores.
- Equinox ocupa cerca de 59 MB de modelos e texturas extraídos e pode impactar notebook de 8 GB RAM. Não altera handling, ELS ou o sistema de pagamentos/estoque de outros projetos.
- Validação final visual depende de executar os mods no FiveM Legacy local. Os testes do GitHub não garantem localização do mapa, funcionamento da sirene ou ausência de conflitos de outros recursos.

## Autoria e redistribuição

- **Base PRF MLO, LN3D3V:** https://www.nexusmods.com/gta5/mods/994 — autor permite redistribuição com créditos, mas proíbe uso comercial dos assets.
- **EQUINOX 2020 PRF (BLINDADA):** https://www.gta5-mods.com/vehicles/equinox-2020-prf-blindada — autores Martinelli e Alessandro da Fonseca. A página pública contém uma restrição geral de republicação; o usuário afirmou ter autorização específica para este projeto. Preserve os créditos e a documentação dessa autorização. Os quatro arquivos são importados apenas após validação por hash.

A Nova Byte é responsável somente pelos scripts de integração; não reivindica autoria dos modelos, texturas ou mapa.
