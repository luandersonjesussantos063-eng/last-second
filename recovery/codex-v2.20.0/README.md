# PRF RP — recuperação PARCIAL de sessão Codex v2.20.0

Este diretório preserva fragmentos de código obtidos do histórico da sessão Codex fornecido pelo proprietário. **NÃO é a build v2.20.0 completa, nem prova de que os 132 testes citados pelo Codex ainda passam.**

## Origem
- Sessão: `codex://threads/01a1713d-a6e5-7278-ac4f-389f815d2018`
- Repositório original: `luandersonjesussantos063-eng/last-second`
- Branch de resgate: `recovery/codex-v2-20-parcial`
- Referência da versão publicada quando o resgate começou: v2.14.0
- Arquivos copiados da transcrição de comandos `cat > arquivo <<EOF`; outros patches ocorreram depois e não estão totalmente preservados.

## Arquivos efetivamente recuperados
- `trechos_codigo/operations-sim.js`
- `trechos_codigo/operations-ui.js`
- `trechos_codigo/weather-world.js`
- `trechos_codigo/tests/world-browser.mjs`
- `trechos_codigo/tests/world-integration.test.mjs`
- `manifesto.json`

Os nomes e conteúdo são mantidos como *trechos da sessão*, para reconstrução posterior e comparação, sem inclusão automática em código jogável.

## NÃO RECONSTRUÍDOS AINDA
`heavy-traffic.js`, `heavy-vehicles.js`, `weighbridge.js`, `urban-layout.js`, `urban-world.js`, `incident-world.js`, `inspection-impound.js`, `inspection-impound-world.js`, `crew-navigation.js`, além de patches finais em `road-sim.js`, `main.js`, `road-world.js` e outros módulos.

## Importante
- Não mesclar automaticamente esta branch em `main`: os trechos têm dependências que ainda não existem.
- Nenhuma alteração foi feita na build publicada do GitHub Pages.
- O histórico bruto da conversa **não foi colocado no repositório** para evitar publicar detalhes de sessão/ambiente em um repositório possivelmente público. O proprietário mantém o ZIP original.
- Próximo passo: reconstruir módulos faltantes em outra branch de desenvolvimento, validar SemVer, imports, testes automatizados e testes visuais antes de publicar.
