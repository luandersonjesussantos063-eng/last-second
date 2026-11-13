# Base PRF: teste com interior restaurado

VERSAO DE TESTE COM INTERIOR RESTAURADO. Ainda requer teste no FiveM.
Pare o servidor. Mova a versao anterior da pasta prfMiniLN3d3v para FORA de resources. Extraia esta pasta em resources/[prf]. Mantenha so uma copia ativa. Inicie o servidor, feche e reabra o FiveM e teste a mesma estrada.
Se voltar a travar, pare o mapa e volte ao pacote exterior de diagnostico.
Creditos: LN3D3V. Preserve condicoes de uso e autoria originais. Dependencia /assetpacks preservada.


## Alterações verificadas nos arquivos

O YMAP original referenciava o archetype MLO prfmloybn como CEntityDef comum. A variante cria um bloco CMloInstanceDef usando o schema já existente no arquivo, redireciona somente essa referência, marca o conteúdo como interior e configura os três portais de saída existentes. A lista mantém oito entidades: sete comuns e uma instância MLO.

Os limites zerados do MLO foram substituídos pelos limites do drawable filho prfmlo.ydr, que coincidem com os limites das salas. O manifesto registra os dois YTYP explicitamente. Os modelos, texturas, colisões e salas originais foram mantidos, assim como /assetpacks.

Somente três dos treze arquivos originais mudam: fxmanifest.lua, prfminibaseln3d3v.ymap e PRFMLOMINIBASE3D3V.ytyp. Os outros dez são idênticos byte a byte. Foram conferidos CRC do ZIP, descompressão RSC7/DEFLATE, referências dentro dos blocos, tipo e quantidade de entidades e flag de interior. Isso não substitui um teste no GTA V/FiveM.

A variante exterior anterior foi testada pelo usuário sem travamento. Conserve-a fora de resources como alternativa caso esta nova variante volte a travar. Mantenha apenas uma cópia do mapa ativa.

Reprodução: python rebuild-map-interior.py ORIGINAL.zip PASTA_SAIDA. A entrada é conferida por SHA256 e nunca modificada. A saída é determinística. Estruturas baseadas em CodeWalker Meta.cs, MetaTypes.cs e YmapFile.cs: https://github.com/dexyfex/CodeWalker/tree/master/CodeWalker.Core/GameFiles . Créditos do mapa: LN3D3V, Nexus Mods GTA5 nº994; preserve as condições de uso originais.
