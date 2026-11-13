# Base PRF: variante de diagnóstico do exterior

VERSAO DE DIAGNOSTICO: exterior da base PRF LN3D3V. Interior MLO desativado; nao e reparo completo do interior. Preserve credito LN3D3V e uso nao comercial conforme origem do projeto.

Com servidor parado, mova a pasta antiga prfMiniLN3d3v para fora de resources. Extraia esta pasta no mesmo lugar. Mantenha so UMA copia deste mapa em resources. Inicie o servidor e reconecte o FiveM. Teste a mesma estrada. Caso trave, mantenha o mapa parado e envie CitizenFX.log.

A dependencia /assetpacks foi preservada. Sem validacao dentro do GTA/FiveM neste ambiente.


## Resultado da análise estática

O ZIP original contém um archetype MLO chamado prfmloybn, com limites zerados, referenciado no YMAP principal como CEntityDef sem CMloInstanceDef. A variante remove essa referência da lista de entidades, de oito para sete, e os arquivos exclusivos do interior. Registra explicitamente o YTYP do exterior e preserva /assetpacks. Isso isola uma estrutura suspeita; não comprova sozinho a causa do crash.

Verificações: CRC do ZIP, descompressão RSC7/DEFLATE, tabelas Meta e lista resultante de ponteiros. Não foi executado GTA V/FiveM neste ambiente. Os modelos restantes mantêm os bytes originais. Créditos: LN3D3V, base original Nexus Mods GTA5 nº 994. Preserve autoria e condições de uso originais.
