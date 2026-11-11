# Moto, viatura e base PRF das fotos

O `prf_core` permite configurar veículos adicionais e o ponto de uma base fixa. **Este repositório ainda não inclui os modelos 3D, as pinturas dos veículos nem o mapa das fotos.** A viatura padrão continua sendo o `police3` original do GTA V; a moto permanece desativada até receber um modelo real.

## Referências visuais

| Item | Características a reproduzir |
| --- | --- |
| Moto da primeira foto | BMW GS Adventure, provavelmente R 1200 GS; ano e versão a confirmar. Azul escura com faixas amarelas, `PRF`, brasão e `191`; motor boxer, protetores tubulares prateados, rodas raiadas, para-brisa alto, bagageiro e suportes laterais sem malas instaladas. |
| Base da segunda foto | Cobertura metálica larga sobre a rodovia, estrutura e pilares aparentes; testeira azul escura com `POLÍCIA RODOVIÁRIA FEDERAL` em amarelo e brasões nas extremidades. Prédio amarelo e azul à esquerda, janelas grandes e cobertura lateral mais baixa. |
| Viatura da terceira foto | Chevrolet Trailblazer; ano e versão a confirmar. Azul muito escura, faixa amarela sob as janelas, `PRF` nas portas, brasão, bandeira do Brasil, `191` na lateral traseira, grafismos amarelos, rodas pretas e barra de luzes no teto. |

As fotos orientam a aparência, mas não contêm geometria, texturas aplicáveis ao jogo, interiores ou colisões. Para reproduzir esses itens é necessário obter ou produzir os modelos correspondentes para **GTA V Legacy/FiveM Legacy**. Apenas trocar o nome de um veículo ou criar um marcador no GPS não reproduz as fotos.

## Instalar os modelos e o mapa

1. Obtenha os recursos completos dos veículos e da base, preparados para FiveM Legacy. Veículos normalmente incluem modelos `.yft`, texturas `.ytd`, arquivos `.meta` e `fxmanifest.lua`. O mapa pode incluir `.ymap`, `.ytyp`, modelos e colisões `.ybn`, conforme o pacote do autor.
2. Copie cada recurso para a pasta `resources` do seu perfil txAdmin, seguindo as instruções e dependências do autor. Os recursos externos são instalados separadamente; o instalador deste repositório copia apenas `prf_core`.
3. No `server.cfg`, inicie os recursos reais **antes** de `prf_core`. No exemplo abaixo, substitua os nomes em maiúsculas pelos nomes exatos das pastas instaladas:

```cfg
ensure NOME_REAL_DO_RECURSO_DA_MOTO
ensure NOME_REAL_DO_RECURSO_DA_VIATURA
ensure NOME_REAL_DO_RECURSO_DO_MAPA
ensure prf_core
```

## Configurar o `prf_core`

Edite `resources/[prf]/prf_core/config.lua` **na instalação do servidor**. Use os nomes e índices fornecidos pelo pacote real:

O instalador substitui `config.lua` nas atualizações. Guarde uma cópia dos ajustes da frota e da base para reaplicá-los depois de atualizar o `prf_core`.

| Campo | Como preencher |
| --- | --- |
| `Config.Fleet.moto.model` e `Config.Fleet.viatura.model` | Código de spawn do modelo, que pode ser diferente do nome da pasta. A moto fica com `false` enquanto não houver modelo instalado. |
| `resource` em cada veículo | Nome exato do recurso que fornece o modelo; `false` quando não precisar conferir um recurso externo. |
| `label` | Nome apresentado ao jogador. Não altera a aparência do modelo. |
| `livery` | Índice da pintura via `SetVehicleLivery`, começando em zero; `false` para não alterar. |
| `modLivery` | Índice da pintura pelo mod 48, se o modelo usar esse sistema; `false` para não alterar. Use o sistema indicado pelo autor. |
| `extras` | Tabela com os IDs de extras existentes no modelo, por exemplo `{ [1] = true, [2] = false }`. `true` ativa e `false` desativa o extra. |
| `Config.Base.name` | Nome da base exibido ao jogador. |
| `Config.Base.mapResource` | Nome exato do recurso do mapa instalado; deixe `false` enquanto usar a base de teste. |
| `Config.Base.x`, `y`, `z` e `heading` | Coordenadas e direção de um ponto seguro da base real, conforme o mapa instalado. Não são coordenadas extraídas da foto. |

`Config.Vehicle` preserva o modelo padrão/compatibilidade da viatura. Configure a frota com os códigos reais para selecionar os veículos adicionais. Não é necessário alterar os arquivos `.meta` do autor apenas para preencher esses campos.

Reinicie o `prf_core` depois de salvar a configuração. Entre em serviço com `/prfservico` e teste `/prfviatura`, `/prfmoto` e `/prfbase`. Os comandos exigem a permissão ACE `prfrp.officer` e turno ativo. `/prfbase` aponta para a base configurada; a construção é carregada pelo recurso de mapa.

Confira dentro do FiveM as pinturas, os extras, o ponto de chegada e as colisões da base. Essa validação visual depende dos recursos instalados e não é substituída pelos testes de código do repositório.
