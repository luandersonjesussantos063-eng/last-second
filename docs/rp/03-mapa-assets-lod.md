# IA-03 — Plano verificável de mapa, frota e desempenho (09/11/2026)

Escopo: **jogo web Three.js primeiro**, sem alterar produção neste PR. Issue #4. O jogo web e experimentos `fivem/` continuam no mesmo repositório. Este documento não é um modelo 3D, nem atesta FPS medido.

## Planta funcional da sede (proposta, unidades em metros)
Coordenadas locais: origem (0,0) no portão principal; eixo X para leste, Z para norte. Validar dimensões com o mapa real do jogo antes de implementar.

| Zona | Centro X,Z | Dimensão X×Z | Função e circulação |
|---|---|---|---|
| Portaria | 0, 0 | 8×6 | Controle de acesso, pedestres separados dos veículos |
| Pátio | 0, 22 | 32×28 | Formação e manobra; corredor livre de 6 m |
| Garagem | -24, 25 | 16×22 | 3 vagas de 3,5×6 m, saída sem cruzar pedestres |
| Recepção/sede | 22, 22 | 24×20 | Recepção, sala de comando e circulação |
| Alojamento | 22, 44 | 18×14 | Descanso, água e banheiro; interiores simplificados |
| Área de cones | -20, 4 | 10×8 | Armazenamento e montagem/desmontagem da blitz |

**Colisão:** volumes estáticos AABB em paredes e pilares; volumes de interação independentes; cones com colisão simplificada; portas com abertura e passagem verificadas. Separar navmesh/caminhos de NPC dos trajetos de viaturas. Evitar colisão física de detalhes decorativos.

## Ordem de execução web
1. Auditar `base-layout.js`, `road-world.js`, `fleet-models.js`, `model-library.js` e `police-crew.js` antes de editar, reutilizando geometria e materiais já existentes.
2. Melhorar fachada, garagem, sinalização e iluminação com primitivas Three.js próprias e texturas procedurais; nenhuma importação de modelos GTA.
3. Implementar pontos de espera, deslocamento e interação para policiais na sede, sem bloquear patrulha com equipe de 3 acompanhantes.
4. Ajustar viaturas *genéricas e originais* por silhueta e proporções; Duster/Hilux/Trailblazer são referências de classe, não promessa de modelos licenciados ou réplicas de marca.
5. Somente após avaliação visual, adicionar LOD e redução de draw calls, com comparativo FPS.

## Orçamento técnico e LOD (metas, não medições)
| Elemento | Próximo <25m | Médio 25–75m | Distante >75m |
|---|---|---|---|
| Sede | Fachada e interiores visíveis | Fachada simplificada | Silhueta e poucos materiais |
| Viatura | Rodas e luzes detalhadas | Corpo com rodas simples | Corpo simplificado; ocultar interior |
| Policial | Corpo, uniforme e acessórios | Corpo simplificado | Silhueta ou ocultar após teste |
| Vegetação/objetos | Geometria instanciada | Geometria reduzida | Ocultar objetos pequenos |

Metas preliminares: 60 FPS desktop e 30 FPS em celular intermediário, a validar em dispositivos reais; não são resultados obtidos. Monitorar `renderer.info.render.calls`, triângulos, geometria, texturas, tempo por frame p50/p95, memória e FPS em cena parada, patrulha e blitz. Usar instancing para cones/postes, materiais compartilhados, geometria reutilizada, sombras seletivas e descarte de recursos ao remover objetos. Medir 60 s após aquecimento de 15 s com resolução e dispositivo registrados. Não reduzir qualidade sem comparação antes/depois.

## Registro de proveniência e licenças
| Item | Origem planejada | Licença comprovada | Decisão |
|---|---|---|---|
| Sede geométrica | Criar com primitivas Three.js no repositório | Código próprio sujeito à licença do repositório; conferir titularidade | Permitido como implementação original |
| Viaturas genéricas | Modelagem procedural própria | A documentar em commit do autor | Sem logos/marcas ou malhas copiadas |
| Personagens | Geometria própria existente, a auditar | **Pendente de auditoria** | Não redistribuir novos binários |
| Materiais | Cores e shaders próprios | **Pendente de auditoria** | Não baixar texturas sem licença |
| Modelos GTA V/FiveM de terceiros | Não utilizar | Não autorizada | **Proibido copiar/exportar** |
| Modelos de marketplace | Nenhum selecionado | Não verificada | Bloqueado até URL, autor, versão, licença e atribuição |

Para qualquer asset externo futuro registrar: identificador, URL de origem, autor, data de consulta, licença completa, prova/arquivo de licença, restrições de redistribuição e atribuição, hash SHA-256, formato e local no projeto. Não presumir que conteúdo público é livre.

## Checklist de integridade antes de gameplay web
- [ ] Verificar versão corrente da `main` e incrementar SemVer acima dela.
- [ ] Executar `npm run stamp:release` e conferir `package.json`, `package-lock.json`, todos os `?v=` e `index.html`.
- [ ] Executar `npm run check`, `npm test`, `npm run build:site`.
- [ ] Revisar colisões, navegação de NPC, entrada na viatura, mobile e regressão visual.
- [ ] Abrir PR web com `AUTO-PUBLICAR-WEB: SIM`; aguardar CI, merge e deploy antes de afirmar publicação.

**Estado deste PR:** somente documentação. Nenhum asset/modelo foi criado, nenhuma medição FPS foi executada e nenhuma atualização do jogo web foi publicada por este documento. GitHub Pages é hospedagem estática; não executa servidor FiveM ou multiplayer persistente.
