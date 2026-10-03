extends Node


# =========================================================
# LAST SECOND
# MOBILE OPTIMIZER v6.8 // ON FOOT + MOBILE HD ADAPTATIVO + MULTI-CONTACT RADAR
#
# OBJETIVO:
# - chegar muito mais perto da imagem-conceito
# - sem depender de um cockpit 3D pesado
# - manter a visao do espaco totalmente livre no centro
# - usar uma cabine 2D/2.5D desenhada por cima da cena 3D
#
# MOBILE FIRST:
# - cockpit 3D pesado original oculto
# - zero OmniLight adicional
# - zero sombra adicional da cabine
# - cabine nao sofre com luz forte do Sol/planetas
# - painel sempre legivel
# - custo visual baixo para celular
# - 3 telas funcionais no painel
# - velocidade real da P-01
# - radar real do suspeito
# - telemetria / FPS / turbo
# - metais, molduras, barras ciano e alertas laranja/vermelhos
#
# IMPORTANTE:
# Este script deve ficar no no MobileOptimizer, que e um Node.
# MobileControls continua separado e NAO deve ser alterado.
# =========================================================


@export var aplicar_no_mobile: bool = true
@export var visualizar_mobile_no_pc_para_teste: bool = true
@export_range(0.60, 1.0, 0.01) var escala_3d_mobile: float = 0.85
@export var qualidade_adaptativa_mobile: bool = true
@export_range(0.60, 1.0, 0.01) var escala_minima_adaptativa: float = 0.75
@export_range(0.60, 1.0, 0.01) var escala_maxima_adaptativa: float = 0.92
@export_range(30.0, 60.0, 1.0) var fps_para_reduzir_qualidade: float = 52.0
@export_range(30.0, 60.0, 1.0) var fps_para_aumentar_qualidade: float = 58.0
@export_range(0.5, 5.0, 0.1) var intervalo_ajuste_qualidade: float = 1.5
@export_range(0.01, 0.10, 0.01) var passo_ajuste_qualidade: float = 0.02
@export var melhorar_nitidez_texturas: bool = true
@export_range(-0.50, 0.0, 0.05) var bias_mipmap_mobile: float = -0.10
@export var desativar_sombras_mobile: bool = true
@export var criar_cockpit_fake: bool = true
@export_range(0.70, 1.30, 0.05) var escala_cockpit: float = 1.00
@export_range(0.88, 1.00, 0.01) var escala_enquadramento: float = 0.93
@export_range(-0.10, 0.10, 0.01) var deslocamento_vertical_enquadramento: float = 0.02
@export_range(0.60, 1.00, 0.05) var opacidade_cockpit: float = 0.94
@export_range(2.0, 20.0, 1.0) var atualizacoes_painel_por_segundo: float = 10.0
@export_range(300.0, 5000.0, 100.0) var alcance_radar: float = 1400.0


var camera: Camera3D = null
var modo_mobile_ativo: bool = false
var eh_mobile_real: bool = false

var cockpit_root: Control = null
var modo_a_pe: bool = false
var ultimo_tamanho_tela: Vector2 = Vector2.ZERO

# Referencias do jogo usadas pelas telas.
var player: Node3D = null
var alvo_radar: Node3D = null

# Telemetria simples e barata.
var ultima_posicao_player: Vector3 = Vector3.ZERO
var velocidade_atual: float = 0.0
var tempo_atualizacao_painel: float = 0.0
var angulo_varredura: float = 0.0
var escala_3d_atual: float = 0.85
var tempo_ajuste_qualidade: float = 0.0
var tempo_aquecimento_qualidade: float = 0.0
var amostras_fps: Array[float] = []

# Elementos dinamicos das tres telas.
var label_velocidade: Label = null
var label_integridade: Label = null
var label_estado_voo: Label = null
var barra_velocidade: ColorRect = null
var barra_velocidade_largura: float = 0.0

var label_radar_titulo: Label = null
var label_radar_alvo: Label = null
var marcador_radar: Polygon2D = null
var marcadores_radar_multiplos: Array[Polygon2D] = []
@export_range(4, 32, 1) var max_contatos_radar: int = 18
var linha_varredura_radar: Line2D = null
var centro_radar: Vector2 = Vector2.ZERO
var raio_radar: float = 0.0

var label_sistemas: Label = null
var label_fps: Label = null
var label_propulsao: Label = null
var label_link: Label = null
var barra_propulsao: ColorRect = null
var barra_energia: ColorRect = null
var barra_sistema_largura: float = 0.0

# Containers com recorte para manter texto dentro das telas.
var painel_esq_ui: Control = null
var painel_centro_ui: Control = null
var painel_dir_ui: Control = null


# =========================================================
# READY
# =========================================================

func _ready() -> void:
	eh_mobile_real = (
		OS.has_feature("android")
		or OS.has_feature("ios")
		or OS.has_feature("mobile")
	)

	var eh_pc_teste: bool = (
		!eh_mobile_real
		and visualizar_mobile_no_pc_para_teste
	)

	modo_mobile_ativo = (
		(aplicar_no_mobile and eh_mobile_real)
		or eh_pc_teste
	)

	if !modo_mobile_ativo:
		print("MOBILE OPTIMIZER v6: modo mobile nao aplicado.")
		return

	print("========================================")
	print("MOBILE OPTIMIZER v6.7 // MOBILE HD ADAPTATIVO ATIVO")
	print("FAKE COCKPIT 2.5D // MOBILE FIRST")
	print("========================================")

	await get_tree().process_frame
	await get_tree().process_frame

	encontrar_camera()
	localizar_referencias_jogo()

	if eh_mobile_real:
		aplicar_resolucao_mobile()

	esconder_cockpit_pesado()

	if desativar_sombras_mobile:
		desativar_sombras_recursivo(get_tree().current_scene)

	if criar_cockpit_fake:
		criar_canvas_cockpit()
		construir_cockpit_fake()

	if eh_mobile_real:
		print("ESCALA 3D MOBILE INICIAL: ", escala_3d_atual)
	else:
		print("PC TESTE: visual mobile ativo")

	print("COCKPIT FAKE 2.5D: ", criar_cockpit_fake)
	print("========================================")


func set_modo_a_pe(ativo: bool) -> void:
	modo_a_pe = ativo

	if cockpit_root != null:
		cockpit_root.visible = modo_mobile_ativo and !modo_a_pe

	print(
		"MOBILE OPTIMIZER v6.8: cockpit ",
		"OCULTO // MODO A PE" if modo_a_pe else "ATIVO // MODO NAVE"
	)


func is_modo_a_pe() -> bool:
	return modo_a_pe


# =========================================================
# PROCESS - SO REFAZ O LAYOUT SE A TELA MUDAR
# =========================================================

func _process(delta: float) -> void:
	if !modo_mobile_ativo:
		return

	if cockpit_root == null:
		return

	var tamanho_atual: Vector2 = get_viewport().get_visible_rect().size

	if tamanho_atual != ultimo_tamanho_tela:
		construir_cockpit_fake()

	atualizar_velocidade_player(delta)
	animar_radar(delta)

	if eh_mobile_real:
		atualizar_qualidade_adaptativa(delta)

	tempo_atualizacao_painel += delta
	var intervalo: float = 1.0 / maxf(atualizacoes_painel_por_segundo, 1.0)

	if tempo_atualizacao_painel >= intervalo:
		tempo_atualizacao_painel = 0.0
		atualizar_paineis_funcionais()


# =========================================================
# CAMERA
# =========================================================

func encontrar_camera() -> void:
	var cena: Node = get_tree().current_scene
	if cena == null:
		return

	camera = cena.get_node_or_null("Player/Camera3D") as Camera3D

	if camera == null:
		var encontrada: Node = cena.find_child(
			"Camera3D",
			true,
			false
		)

		if encontrada is Camera3D:
			camera = encontrada as Camera3D

	if camera == null:
		push_warning(
			"MOBILE OPTIMIZER v6.6 // MULTI-CONTACT RADAR: Camera3D nao encontrada."
		)


# =========================================================
# RESOLUCAO 3D MOBILE
# =========================================================

func aplicar_resolucao_mobile() -> void:
	var viewport: Viewport = get_viewport()
	if viewport == null:
		return

	# v6.7:
	# Antes o mobile usava 0.70, que renderiza apenas 49% dos pixels
	# de uma imagem nativa no eixo combinado e deixa o 3D muito borrado.
	# Agora comecamos em 0.85 e ajustamos dinamicamente conforme o FPS.
	escala_3d_atual = clampf(
		escala_3d_mobile,
		escala_minima_adaptativa,
		escala_maxima_adaptativa
	)
	viewport.scaling_3d_scale = escala_3d_atual

	# Pequeno ganho de nitidez nas texturas com mipmaps.
	# Mantido conservador para nao criar cintilacao nem pesar muito.
	if melhorar_nitidez_texturas:
		viewport.texture_mipmap_bias = bias_mipmap_mobile


func atualizar_qualidade_adaptativa(delta: float) -> void:
	if !qualidade_adaptativa_mobile:
		return

	var viewport: Viewport = get_viewport()
	if viewport == null:
		return

	# Evita tomar decisoes enquanto a cena ainda esta carregando.
	tempo_aquecimento_qualidade += delta
	if tempo_aquecimento_qualidade < 4.0:
		return

	tempo_ajuste_qualidade += delta
	amostras_fps.append(float(Engine.get_frames_per_second()))

	# Guarda poucas amostras; custo praticamente zero.
	if amostras_fps.size() > 12:
		amostras_fps.pop_front()

	if tempo_ajuste_qualidade < intervalo_ajuste_qualidade:
		return

	tempo_ajuste_qualidade = 0.0

	if amostras_fps.is_empty():
		return

	var soma_fps: float = 0.0
	for valor: float in amostras_fps:
		soma_fps += valor

	var fps_medio: float = soma_fps / float(amostras_fps.size())
	var nova_escala: float = escala_3d_atual

	# Se cair abaixo do alvo, reduz poucos pontos por vez.
	if fps_medio < fps_para_reduzir_qualidade:
		nova_escala -= passo_ajuste_qualidade

	# Se estiver sobrando FPS, melhora a imagem aos poucos.
	elif fps_medio >= fps_para_aumentar_qualidade:
		nova_escala += passo_ajuste_qualidade

	nova_escala = clampf(
		nova_escala,
		escala_minima_adaptativa,
		escala_maxima_adaptativa
	)

	# Evita ficar escrevendo no Viewport sem necessidade.
	if absf(nova_escala - escala_3d_atual) >= 0.005:
		escala_3d_atual = nova_escala
		viewport.scaling_3d_scale = escala_3d_atual


# =========================================================
# ESCONDER COCKPIT 3D PESADO
# =========================================================

func esconder_cockpit_pesado() -> void:
	var cena: Node = get_tree().current_scene
	if cena == null:
		return

	var nomes_alvo: Array[String] = [
		"Spaceship_interior",
		"CockpitMobileConceptV5",
		"CockpitLiteMobile"
	]

	for nome: String in nomes_alvo:
		var encontrado: Node = cena.find_child(
			nome,
			true,
			false
		)

		if encontrado is Node3D:
			(encontrado as Node3D).visible = false

	# Fallback para o caminho que usamos desde o inicio.
	var cockpit_original: Node = cena.get_node_or_null(
		"Player/Camera3D/Spaceship_interior"
	)

	if cockpit_original is Node3D:
		(cockpit_original as Node3D).visible = false

	print("Cockpit 3D pesado original: OCULTO")


# =========================================================
# SOMBRAS
# =========================================================

func desativar_sombras_recursivo(no: Node) -> void:
	if no == null:
		return

	if no is Light3D:
		(no as Light3D).shadow_enabled = false

	for filho: Node in no.get_children():
		desativar_sombras_recursivo(filho)


# =========================================================
# CANVAS DA CABINE
# =========================================================

func criar_canvas_cockpit() -> void:
	if cockpit_root != null:
		return

	# Nao usamos CanvasLayer separado aqui.
	# Assim a cabine fica no canvas normal com z_index baixo,
	# enquanto os HUDs existentes (missao, planetas, performance)
	# continuam desenhados por cima dela.
	cockpit_root = Control.new()
	cockpit_root.name = "CockpitFakeRoot"
	cockpit_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	cockpit_root.position = Vector2.ZERO
	cockpit_root.z_index = -100
	add_child(cockpit_root)


# =========================================================
# CONSTRUIR CABINE 2.5D
# =========================================================

func construir_cockpit_fake() -> void:
	if cockpit_root == null:
		return

	var tela: Vector2 = get_viewport().get_visible_rect().size
	if tela.x <= 1.0 or tela.y <= 1.0:
		return

	ultimo_tamanho_tela = tela
	cockpit_root.position = Vector2(0.0, tela.y * deslocamento_vertical_enquadramento)
	cockpit_root.size = tela

	# Enquadramento geral da cabine.
	# Escalamos a partir do centro inferior para abrir um pouco mais o para-brisa,
	# afastar os paineis das bordas e manter a base ancorada no rodape.
	cockpit_root.pivot_offset = Vector2(tela.x * 0.5, tela.y)
	cockpit_root.scale = Vector2(escala_enquadramento, escala_enquadramento)

	for filho: Node in cockpit_root.get_children():
		cockpit_root.remove_child(filho)
		filho.queue_free()

	limpar_referencias_paineis()

	var w: float = tela.x
	var h: float = tela.y
	var s: float = escala_cockpit
	var a: float = opacidade_cockpit

	# -----------------------------------------------------
	# PALETA
	# -----------------------------------------------------

	var metal_escuro := Color(0.045, 0.060, 0.085, a)
	var metal_medio := Color(0.100, 0.125, 0.165, a)
	var metal_claro := Color(0.210, 0.250, 0.310, a)
	var painel := Color(0.018, 0.030, 0.052, a)
	var tela_fundo := Color(0.003, 0.028, 0.052, 0.97)
	var ciano := Color(0.08, 0.84, 1.00, 0.95)
	var ciano_fraco := Color(0.02, 0.62, 0.86, 0.34)
	var azul_tela := Color(0.04, 0.42, 0.68, 0.60)
	var laranja := Color(1.00, 0.38, 0.04, 0.92)
	var vermelho := Color(1.00, 0.05, 0.04, 0.92)

	# -----------------------------------------------------
	# TETO / ESTRUTURA SUPERIOR
	# Mantem o centro aberto, mas da leitura de cabine fechada.
	# -----------------------------------------------------

	# Casco superior principal.
	adicionar_poligono([
		Vector2(0.14 * w, 0.00 * h),
		Vector2(0.86 * w, 0.00 * h),
		Vector2(0.77 * w, 0.085 * h),
		Vector2(0.23 * w, 0.085 * h)
	], metal_escuro)

	# Painel central do teto.
	adicionar_poligono([
		Vector2(0.29 * w, 0.00 * h),
		Vector2(0.71 * w, 0.00 * h),
		Vector2(0.67 * w, 0.058 * h),
		Vector2(0.33 * w, 0.058 * h)
	], metal_medio)

	# Recortes laterais que conectam teto e colunas.
	adicionar_poligono([
		Vector2(0.14 * w, 0.00 * h),
		Vector2(0.29 * w, 0.00 * h),
		Vector2(0.25 * w, 0.090 * h),
		Vector2(0.20 * w, 0.115 * h)
	], metal_medio)

	adicionar_poligono([
		Vector2(0.86 * w, 0.00 * h),
		Vector2(0.71 * w, 0.00 * h),
		Vector2(0.75 * w, 0.090 * h),
		Vector2(0.80 * w, 0.115 * h)
	], metal_medio)

	# Faixa de iluminacao superior fake, barata para mobile.
	adicionar_glow([
		Vector2(0.36 * w, 0.060 * h),
		Vector2(0.64 * w, 0.060 * h)
	], 2.4 * s, ciano, ciano_fraco)

	# Pequenos alertas no teto para quebrar o visual plano.
	adicionar_glow([
		Vector2(0.47 * w, 0.025 * h),
		Vector2(0.53 * w, 0.025 * h)
	], 1.5 * s, laranja, Color(1.0, 0.25, 0.02, 0.18))

	# -----------------------------------------------------
	# FUNDO INFERIOR / BASE DA CABINE
	# -----------------------------------------------------

	adicionar_poligono([
		Vector2(0.00 * w, 1.00 * h),
		Vector2(0.00 * w, 0.83 * h),
		Vector2(0.17 * w, 0.66 * h),
		Vector2(0.30 * w, 0.61 * h),
		Vector2(0.70 * w, 0.61 * h),
		Vector2(0.83 * w, 0.66 * h),
		Vector2(1.00 * w, 0.83 * h),
		Vector2(1.00 * w, 1.00 * h)
	], metal_escuro)

	# Console esquerdo.
	adicionar_poligono([
		Vector2(0.00 * w, 0.79 * h),
		Vector2(0.17 * w, 0.65 * h),
		Vector2(0.34 * w, 0.67 * h),
		Vector2(0.29 * w, 1.00 * h),
		Vector2(0.00 * w, 1.00 * h)
	], metal_medio)

	# Console direito.
	adicionar_poligono([
		Vector2(1.00 * w, 0.79 * h),
		Vector2(0.83 * w, 0.65 * h),
		Vector2(0.66 * w, 0.67 * h),
		Vector2(0.71 * w, 1.00 * h),
		Vector2(1.00 * w, 1.00 * h)
	], metal_medio)

	# Painel central em perspectiva.
	adicionar_poligono([
		Vector2(0.27 * w, 0.64 * h),
		Vector2(0.73 * w, 0.64 * h),
		Vector2(0.82 * w, 1.00 * h),
		Vector2(0.18 * w, 1.00 * h)
	], painel)

	# Aba superior do painel.
	adicionar_poligono([
		Vector2(0.31 * w, 0.60 * h),
		Vector2(0.69 * w, 0.60 * h),
		Vector2(0.73 * w, 0.66 * h),
		Vector2(0.27 * w, 0.66 * h)
	], metal_medio)

	# Acabamento claro frontal.
	adicionar_poligono([
		Vector2(0.28 * w, 0.665 * h),
		Vector2(0.72 * w, 0.665 * h),
		Vector2(0.74 * w, 0.69 * h),
		Vector2(0.26 * w, 0.69 * h)
	], metal_claro)

	# -----------------------------------------------------
	# MOLDURA SUPERIOR DO PARA-BRISA
	# -----------------------------------------------------

	adicionar_poligono([
		Vector2(0.27 * w, 0.075 * h),
		Vector2(0.73 * w, 0.075 * h),
		Vector2(0.70 * w, 0.125 * h),
		Vector2(0.30 * w, 0.125 * h)
	], metal_medio)

	adicionar_poligono([
		Vector2(0.30 * w, 0.125 * h),
		Vector2(0.70 * w, 0.125 * h),
		Vector2(0.67 * w, 0.155 * h),
		Vector2(0.33 * w, 0.155 * h)
	], metal_escuro)

	# -----------------------------------------------------
	# COLUNAS EXTERNAS DO PARA-BRISA
	# -----------------------------------------------------

	adicionar_poligono([
		Vector2(0.205 * w, 0.10 * h),
		Vector2(0.245 * w, 0.12 * h),
		Vector2(0.285 * w, 0.61 * h),
		Vector2(0.225 * w, 0.65 * h)
	], metal_medio)

	adicionar_poligono([
		Vector2(0.795 * w, 0.10 * h),
		Vector2(0.755 * w, 0.12 * h),
		Vector2(0.715 * w, 0.61 * h),
		Vector2(0.775 * w, 0.65 * h)
	], metal_medio)

	# Faces claras das colunas.
	adicionar_poligono([
		Vector2(0.218 * w, 0.125 * h),
		Vector2(0.235 * w, 0.135 * h),
		Vector2(0.272 * w, 0.59 * h),
		Vector2(0.248 * w, 0.61 * h)
	], metal_claro)

	adicionar_poligono([
		Vector2(0.782 * w, 0.125 * h),
		Vector2(0.765 * w, 0.135 * h),
		Vector2(0.728 * w, 0.59 * h),
		Vector2(0.752 * w, 0.61 * h)
	], metal_claro)

	# -----------------------------------------------------
	# COLUNAS INTERNAS FINAS
	# -----------------------------------------------------

	adicionar_poligono([
		Vector2(0.345 * w, 0.17 * h),
		Vector2(0.358 * w, 0.17 * h),
		Vector2(0.380 * w, 0.58 * h),
		Vector2(0.363 * w, 0.59 * h)
	], metal_escuro)

	adicionar_poligono([
		Vector2(0.655 * w, 0.17 * h),
		Vector2(0.642 * w, 0.17 * h),
		Vector2(0.620 * w, 0.58 * h),
		Vector2(0.637 * w, 0.59 * h)
	], metal_escuro)

	# -----------------------------------------------------
	# OMBREIRAS LATERAIS
	# -----------------------------------------------------

	adicionar_poligono([
		Vector2(0.235 * w, 0.17 * h),
		Vector2(0.35 * w, 0.17 * h),
		Vector2(0.36 * w, 0.20 * h),
		Vector2(0.25 * w, 0.21 * h)
	], metal_escuro)

	adicionar_poligono([
		Vector2(0.765 * w, 0.17 * h),
		Vector2(0.65 * w, 0.17 * h),
		Vector2(0.64 * w, 0.20 * h),
		Vector2(0.75 * w, 0.21 * h)
	], metal_escuro)

	# -----------------------------------------------------
	# LUZES CIANO NAS COLUNAS
	# Duas linhas por faixa criam um brilho falso barato.
	# -----------------------------------------------------

	adicionar_glow([
		Vector2(0.244 * w, 0.24 * h),
		Vector2(0.264 * w, 0.52 * h)
	], 2.6 * s, ciano, ciano_fraco)

	adicionar_glow([
		Vector2(0.756 * w, 0.24 * h),
		Vector2(0.736 * w, 0.52 * h)
	], 2.6 * s, ciano, ciano_fraco)

	adicionar_glow([
		Vector2(0.38 * w, 0.145 * h),
		Vector2(0.62 * w, 0.145 * h)
	], 2.0 * s, ciano, ciano_fraco)

	# -----------------------------------------------------
	# 3 TELAS FAKE
	# -----------------------------------------------------

	var tela_esq: Array[Vector2] = [
		Vector2(0.255 * w, 0.735 * h),
		Vector2(0.370 * w, 0.735 * h),
		Vector2(0.345 * w, 0.895 * h),
		Vector2(0.215 * w, 0.875 * h)
	]

	var tela_centro: Array[Vector2] = [
		Vector2(0.385 * w, 0.715 * h),
		Vector2(0.615 * w, 0.715 * h),
		Vector2(0.650 * w, 0.905 * h),
		Vector2(0.350 * w, 0.905 * h)
	]

	var tela_dir: Array[Vector2] = [
		Vector2(0.630 * w, 0.735 * h),
		Vector2(0.745 * w, 0.735 * h),
		Vector2(0.785 * w, 0.875 * h),
		Vector2(0.655 * w, 0.895 * h)
	]

	criar_tela_fake(tela_esq, tela_fundo, ciano, azul_tela, 0)
	criar_tela_fake(tela_centro, tela_fundo, ciano, azul_tela, 1)
	criar_tela_fake(tela_dir, tela_fundo, ciano, azul_tela, 2)

	criar_conteudo_paineis_funcionais(
		tela_esq,
		tela_centro,
		tela_dir,
		ciano,
		azul_tela
	)

	# -----------------------------------------------------
	# FAIXAS LUMINOSAS DOS CONSOLES
	# -----------------------------------------------------

	adicionar_glow([
		Vector2(0.03 * w, 0.87 * h),
		Vector2(0.18 * w, 0.73 * h),
		Vector2(0.28 * w, 0.72 * h)
	], 3.0 * s, ciano, ciano_fraco)

	adicionar_glow([
		Vector2(0.97 * w, 0.87 * h),
		Vector2(0.82 * w, 0.73 * h),
		Vector2(0.72 * w, 0.72 * h)
	], 3.0 * s, ciano, ciano_fraco)

	adicionar_glow([
		Vector2(0.40 * w, 0.675 * h),
		Vector2(0.60 * w, 0.675 * h)
	], 3.2 * s, ciano, ciano_fraco)

	# -----------------------------------------------------
	# ALERTAS LARANJA E VERMELHOS
	# -----------------------------------------------------

	adicionar_glow([
		Vector2(0.44 * w, 0.625 * h),
		Vector2(0.56 * w, 0.625 * h)
	], 2.2 * s, laranja, Color(1.0, 0.25, 0.02, 0.24))

	for x: float in [0.405, 0.435, 0.565, 0.595]:
		adicionar_poligono([
			Vector2((x - 0.010) * w, 0.685 * h),
			Vector2((x + 0.010) * w, 0.685 * h),
			Vector2((x + 0.008) * w, 0.695 * h),
			Vector2((x - 0.008) * w, 0.695 * h)
		], vermelho)

	# -----------------------------------------------------
	# DETALHES METALICOS / RECORTES
	# -----------------------------------------------------

	adicionar_linha([
		Vector2(0.19 * w, 0.665 * h),
		Vector2(0.29 * w, 0.625 * h),
		Vector2(0.71 * w, 0.625 * h),
		Vector2(0.81 * w, 0.665 * h)
	], 2.0 * s, Color(0.48, 0.58, 0.68, 0.58), false)

	adicionar_linha([
		Vector2(0.21 * w, 0.91 * h),
		Vector2(0.18 * w, 1.00 * h)
	], 1.4 * s, Color(0.34, 0.42, 0.52, 0.48), false)

	adicionar_linha([
		Vector2(0.79 * w, 0.91 * h),
		Vector2(0.82 * w, 1.00 * h)
	], 1.4 * s, Color(0.34, 0.42, 0.52, 0.48), false)

	# Parafusos/pontos decorativos.
	for px: float in [0.205, 0.235, 0.765, 0.795]:
		adicionar_circulo(
			Vector2(px * w, 0.705 * h),
			3.0 * s,
			Color(0.55, 0.66, 0.76, 0.75),
			8
		)

	print("MOBILE OPTIMIZER v6.6 // MULTI-CONTACT RADAR: teto adicionado e painel esquerdo reenquadrado.")


# =========================================================
# TELA FAKE
# =========================================================

func criar_tela_fake(
	pontos: Array[Vector2],
	fundo: Color,
	borda: Color,
	detalhe: Color,
	tipo: int
) -> void:
	adicionar_poligono(pontos, fundo)
	adicionar_linha(pontos, 7.0, Color(borda.r, borda.g, borda.b, 0.16), true)
	adicionar_linha(pontos, 2.0, borda, true)

	var min_x: float = pontos[0].x
	var max_x: float = pontos[0].x
	var min_y: float = pontos[0].y
	var max_y: float = pontos[0].y

	for ponto: Vector2 in pontos:
		min_x = minf(min_x, ponto.x)
		max_x = maxf(max_x, ponto.x)
		min_y = minf(min_y, ponto.y)
		max_y = maxf(max_y, ponto.y)

	var centro := Vector2(
		(min_x + max_x) * 0.5,
		(min_y + max_y) * 0.5
	)

	var largura: float = max_x - min_x
	var altura: float = max_y - min_y

	if tipo == 0:
		# Esquerdinha: silhueta da nave + barras.
		adicionar_linha([
			centro + Vector2(0.0, -altura * 0.26),
			centro + Vector2(-largura * 0.12, altura * 0.18),
			centro + Vector2(0.0, altura * 0.08),
			centro + Vector2(largura * 0.12, altura * 0.18),
			centro + Vector2(0.0, -altura * 0.26)
		], 1.8, detalhe, false)

		for i: int in range(5):
			var y: float = min_y + altura * (0.28 + float(i) * 0.10)
			adicionar_linha([
				Vector2(min_x + largura * 0.66, y),
				Vector2(min_x + largura * (0.78 + float(i % 2) * 0.08), y)
			], 1.2, detalhe, false)

	elif tipo == 1:
		# Central: radar falso.
		var raio1: float = minf(largura, altura) * 0.34
		var raio2: float = raio1 * 0.66
		var raio3: float = raio1 * 0.34

		adicionar_linha(
			pontos_circulo(centro, raio1, 32),
			1.2,
			Color(detalhe.r, detalhe.g, detalhe.b, 0.52),
			true
		)

		adicionar_linha(
			pontos_circulo(centro, raio2, 28),
			1.0,
			Color(detalhe.r, detalhe.g, detalhe.b, 0.42),
			true
		)

		adicionar_linha(
			pontos_circulo(centro, raio3, 24),
			1.0,
			Color(detalhe.r, detalhe.g, detalhe.b, 0.34),
			true
		)

		adicionar_linha([
			centro + Vector2(-raio1, 0.0),
			centro + Vector2(raio1, 0.0)
		], 1.0, Color(detalhe.r, detalhe.g, detalhe.b, 0.40), false)

		adicionar_linha([
			centro + Vector2(0.0, -raio1 * 0.50),
			centro + Vector2(0.0, raio1 * 0.50)
		], 1.0, Color(detalhe.r, detalhe.g, detalhe.b, 0.28), false)

		adicionar_poligono([
			centro + Vector2(0.0, -6.0),
			centro + Vector2(-5.5, 5.5),
			centro + Vector2(5.5, 5.5)
		], Color(0.18, 0.92, 1.0, 0.92))

	else:
		# Direita: globo fake + telemetria.
		var raio: float = minf(largura, altura) * 0.22
		var centro_globo := centro + Vector2(largura * 0.12, -altura * 0.05)

		adicionar_linha(
			pontos_circulo(centro_globo, raio, 28),
			1.3,
			detalhe,
			true
		)

		adicionar_linha([
			centro_globo + Vector2(-raio, 0.0),
			centro_globo + Vector2(raio, 0.0)
		], 1.0, detalhe, false)

		for i: int in range(5):
			var y2: float = min_y + altura * (0.30 + float(i) * 0.10)
			adicionar_linha([
				Vector2(min_x + largura * 0.12, y2),
				Vector2(min_x + largura * (0.32 + float(i % 3) * 0.05), y2)
			], 1.2, detalhe, false)


# =========================================================
# PAINEIS FUNCIONAIS
# =========================================================

func limpar_referencias_paineis() -> void:
	label_velocidade = null
	label_integridade = null
	label_estado_voo = null
	barra_velocidade = null
	barra_velocidade_largura = 0.0

	label_radar_titulo = null
	label_radar_alvo = null
	marcador_radar = null
	marcadores_radar_multiplos.clear()
	linha_varredura_radar = null
	centro_radar = Vector2.ZERO
	raio_radar = 0.0

	label_sistemas = null
	label_fps = null
	label_propulsao = null
	label_link = null
	barra_propulsao = null
	barra_energia = null
	barra_sistema_largura = 0.0

	painel_esq_ui = null
	painel_centro_ui = null
	painel_dir_ui = null


func criar_conteudo_paineis_funcionais(
	tela_esq: Array[Vector2],
	tela_centro: Array[Vector2],
	tela_dir: Array[Vector2],
	ciano: Color,
	azul: Color
) -> void:
	var escala_ui: float = clampf(
		minf(
			ultimo_tamanho_tela.x / 1280.0,
			ultimo_tamanho_tela.y / 720.0
		),
		0.74,
		1.25
	)

	# ---------------- ESQUERDA: NAVE ----------------
	var re: Rect2 = retangulo_dos_pontos(tela_esq)
	var fonte_titulo: int = maxi(int(11.0 * escala_ui), 9)
	var fonte_texto: int = maxi(int(9.5 * escala_ui), 8)
	var fonte_titulo_esq: int = maxi(int(9.5 * escala_ui), 8)
	var fonte_texto_esq: int = maxi(int(8.0 * escala_ui), 7)

	painel_esq_ui = criar_container_painel(
		Rect2(
			Vector2(re.position.x + re.size.x * 0.29, re.position.y + re.size.y * 0.11),
			Vector2(re.size.x * 0.52, re.size.y * 0.72)
		)
	)

	criar_label_painel(
		"NAVE // P-01",
		Vector2(0.0, 0.0),
		Vector2(painel_esq_ui.size.x, painel_esq_ui.size.y * 0.18),
		fonte_titulo_esq,
		ciano,
		HORIZONTAL_ALIGNMENT_LEFT,
		painel_esq_ui
	)

	label_velocidade = criar_label_painel(
		"VEL 000 U/S",
		Vector2(0.0, painel_esq_ui.size.y * 0.20),
		Vector2(painel_esq_ui.size.x, painel_esq_ui.size.y * 0.15),
		fonte_texto_esq,
		Color(0.72, 0.94, 1.0, 0.95),
		HORIZONTAL_ALIGNMENT_LEFT,
		painel_esq_ui
	)

	label_integridade = criar_label_painel(
		"INTEGRIDADE 100%",
		Vector2(0.0, painel_esq_ui.size.y * 0.39),
		Vector2(painel_esq_ui.size.x, painel_esq_ui.size.y * 0.15),
		fonte_texto_esq,
		Color(0.55, 0.95, 0.78, 0.95),
		HORIZONTAL_ALIGNMENT_LEFT,
		painel_esq_ui
	)

	label_estado_voo = criar_label_painel(
		"PROPULSAO NORMAL",
		Vector2(0.0, painel_esq_ui.size.y * 0.58),
		Vector2(painel_esq_ui.size.x, painel_esq_ui.size.y * 0.15),
		fonte_texto_esq,
		Color(0.44, 0.82, 1.0, 0.92),
		HORIZONTAL_ALIGNMENT_LEFT,
		painel_esq_ui
	)

	var bg_vel := criar_barra_painel(
		Vector2(0.0, painel_esq_ui.size.y * 0.83),
		Vector2(painel_esq_ui.size.x * 0.90, maxf(5.0 * escala_ui, 4.0)),
		Color(0.06, 0.18, 0.24, 0.90),
		painel_esq_ui
	)
	barra_velocidade_largura = bg_vel.size.x
	barra_velocidade = criar_barra_painel(
		bg_vel.position,
		Vector2(barra_velocidade_largura * 0.10, bg_vel.size.y),
		Color(0.08, 0.82, 1.0, 0.90),
		painel_esq_ui
	)

	# ---------------- CENTRO: RADAR ----------------
	var rc: Rect2 = retangulo_dos_pontos(tela_centro)
	painel_centro_ui = criar_container_painel(
		Rect2(
			Vector2(rc.position.x + rc.size.x * 0.09, rc.position.y + rc.size.y * 0.08),
			Vector2(rc.size.x * 0.82, rc.size.y * 0.84)
		)
	)

	centro_radar = Vector2(
		rc.position.x + rc.size.x * 0.50,
		rc.position.y + rc.size.y * 0.56
	)
	raio_radar = minf(rc.size.x, rc.size.y) * 0.25

	label_radar_titulo = criar_label_painel(
		"RADAR TATICO // P-01",
		Vector2(0.0, 0.0),
		Vector2(painel_centro_ui.size.x, painel_centro_ui.size.y * 0.14),
		fonte_titulo,
		ciano,
		HORIZONTAL_ALIGNMENT_CENTER,
		painel_centro_ui
	)

	label_radar_alvo = criar_label_painel(
		"PROCURANDO ALVO...",
		Vector2(0.0, painel_centro_ui.size.y * 0.84),
		Vector2(painel_centro_ui.size.x, painel_centro_ui.size.y * 0.12),
		fonte_texto,
		Color(0.58, 0.94, 1.0, 0.94),
		HORIZONTAL_ALIGNMENT_CENTER,
		painel_centro_ui
	)

	linha_varredura_radar = adicionar_linha(
		[
			centro_radar,
			centro_radar + Vector2(0.0, -raio_radar)
		],
		maxf(1.1 * escala_ui, 1.0),
		Color(0.08, 0.95, 1.0, 0.62),
		false
	)

	# Pool de contatos do radar: suspeito, trafego e destrocos.
	for i: int in range(max_contatos_radar):
		var tamanho_blip: float = 4.5 * escala_ui if i == 0 else 3.0 * escala_ui
		var blip := adicionar_poligono(
			[
				centro_radar + Vector2(0.0, -tamanho_blip),
				centro_radar + Vector2(tamanho_blip, 0.0),
				centro_radar + Vector2(0.0, tamanho_blip),
				centro_radar + Vector2(-tamanho_blip, 0.0)
			],
			Color(0.18, 0.86, 1.0, 0.92)
		)
		blip.visible = false
		marcadores_radar_multiplos.append(blip)

	if !marcadores_radar_multiplos.is_empty():
		marcador_radar = marcadores_radar_multiplos[0]

	# ---------------- DIREITA: SISTEMAS ----------------
	var rd: Rect2 = retangulo_dos_pontos(tela_dir)
	painel_dir_ui = criar_container_painel(
		Rect2(
			Vector2(rd.position.x + rd.size.x * 0.16, rd.position.y + rd.size.y * 0.11),
			Vector2(rd.size.x * 0.58, rd.size.y * 0.72)
		)
	)

	label_sistemas = criar_label_painel(
		"SISTEMAS // ONLINE",
		Vector2(0.0, 0.0),
		Vector2(painel_dir_ui.size.x, painel_dir_ui.size.y * 0.18),
		fonte_titulo,
		ciano,
		HORIZONTAL_ALIGNMENT_LEFT,
		painel_dir_ui
	)

	label_fps = criar_label_painel(
		"FPS: --",
		Vector2(0.0, painel_dir_ui.size.y * 0.20),
		Vector2(painel_dir_ui.size.x, painel_dir_ui.size.y * 0.14),
		fonte_texto,
		Color(0.65, 0.93, 1.0, 0.95),
		HORIZONTAL_ALIGNMENT_LEFT,
		painel_dir_ui
	)

	label_propulsao = criar_label_painel(
		"PROPULSAO: 64%",
		Vector2(0.0, painel_dir_ui.size.y * 0.39),
		Vector2(painel_dir_ui.size.x, painel_dir_ui.size.y * 0.14),
		fonte_texto,
		Color(0.65, 0.93, 1.0, 0.95),
		HORIZONTAL_ALIGNMENT_LEFT,
		painel_dir_ui
	)

	label_link = criar_label_painel(
		"LINK: ESTAVEL",
		Vector2(0.0, painel_dir_ui.size.y * 0.58),
		Vector2(painel_dir_ui.size.x, painel_dir_ui.size.y * 0.14),
		fonte_texto,
		Color(0.50, 0.96, 0.70, 0.95),
		HORIZONTAL_ALIGNMENT_LEFT,
		painel_dir_ui
	)

	var bg_sistema := criar_barra_painel(
		Vector2(0.0, painel_dir_ui.size.y * 0.82),
		Vector2(painel_dir_ui.size.x * 0.90, maxf(5.0 * escala_ui, 4.0)),
		Color(0.06, 0.18, 0.24, 0.90),
		painel_dir_ui
	)
	barra_sistema_largura = bg_sistema.size.x

	barra_propulsao = criar_barra_painel(
		bg_sistema.position,
		Vector2(barra_sistema_largura * 0.64, bg_sistema.size.y),
		Color(0.08, 0.82, 1.0, 0.90),
		painel_dir_ui
	)

	barra_energia = criar_barra_painel(
		Vector2(bg_sistema.position.x, bg_sistema.position.y + 10.0 * escala_ui),
		Vector2(barra_sistema_largura, bg_sistema.size.y),
		Color(0.12, 0.55, 1.0, 0.66),
		painel_dir_ui
	)

	atualizar_paineis_funcionais()


func criar_container_painel(area: Rect2) -> Control:
	var container := Control.new()
	container.position = area.position
	container.size = area.size
	container.clip_contents = true
	container.mouse_filter = Control.MOUSE_FILTER_IGNORE
	cockpit_root.add_child(container)
	return container


func criar_label_painel(
	texto: String,
	posicao: Vector2,
	tamanho: Vector2,
	fonte: int,
	cor: Color,
	alinhamento: int,
	pai: Control = cockpit_root
) -> Label:
	var label := Label.new()
	label.text = texto
	label.position = posicao
	label.size = tamanho
	label.horizontal_alignment = alinhamento
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.clip_text = true
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.add_theme_font_size_override("font_size", fonte)
	label.add_theme_color_override("font_color", cor)
	label.add_theme_color_override(
		"font_outline_color",
		Color(0.0, 0.0, 0.0, 0.70)
	)
	label.add_theme_constant_override("outline_size", 1)
	pai.add_child(label)
	return label


func criar_barra_painel(
	posicao: Vector2,
	tamanho: Vector2,
	cor: Color,
	pai: Control = cockpit_root
) -> ColorRect:
	var barra := ColorRect.new()
	barra.position = posicao
	barra.size = tamanho
	barra.color = cor
	barra.mouse_filter = Control.MOUSE_FILTER_IGNORE
	pai.add_child(barra)
	return barra


func retangulo_dos_pontos(pontos: Array[Vector2]) -> Rect2:
	var min_x: float = pontos[0].x
	var max_x: float = pontos[0].x
	var min_y: float = pontos[0].y
	var max_y: float = pontos[0].y

	for p: Vector2 in pontos:
		min_x = minf(min_x, p.x)
		max_x = maxf(max_x, p.x)
		min_y = minf(min_y, p.y)
		max_y = maxf(max_y, p.y)

	return Rect2(
		Vector2(min_x, min_y),
		Vector2(max_x - min_x, max_y - min_y)
	)


func localizar_referencias_jogo() -> void:
	var cena: Node = get_tree().current_scene
	if cena == null:
		return

	player = cena.get_node_or_null("Player") as Node3D
	if player == null:
		var candidato: Node = cena.find_child("Player", true, false)
		if candidato is Node3D:
			player = candidato as Node3D

	if player != null:
		ultima_posicao_player = player.global_position

	procurar_alvo_radar()


func procurar_alvo_radar() -> void:
	var cena: Node = get_tree().current_scene
	if cena == null:
		alvo_radar = null
		return

	var nomes: Array[String] = [
		"NaveSuspeitaTeste",
		"NaveSuspeita",
		"Suspect",
		"Target"
	]

	for nome: String in nomes:
		var candidato: Node = cena.find_child(nome, true, false)
		if candidato is Node3D:
			alvo_radar = candidato as Node3D
			return

	alvo_radar = null


func atualizar_velocidade_player(delta: float) -> void:
	if player == null or !is_instance_valid(player):
		localizar_referencias_jogo()
		return

	if delta <= 0.0001:
		return

	var velocidade_bruta: float = (
		player.global_position.distance_to(ultima_posicao_player)
		/ delta
	)

	velocidade_atual = lerpf(
		velocidade_atual,
		velocidade_bruta,
		clampf(delta * 6.0, 0.0, 1.0)
	)

	ultima_posicao_player = player.global_position


func atualizar_paineis_funcionais() -> void:
	if player == null or !is_instance_valid(player):
		localizar_referencias_jogo()

	if alvo_radar == null or !is_instance_valid(alvo_radar):
		procurar_alvo_radar()

	# Tela esquerda: velocidade real da nave.
	if label_velocidade != null:
		label_velocidade.text = "VEL %03d U/S" % int(round(velocidade_atual))

	var turbo_ativo: bool = Input.is_key_pressed(KEY_SHIFT)
	var propulsao: float = 1.0 if turbo_ativo else 0.64
	var energia: float = 0.78 if turbo_ativo else 1.0

	if label_estado_voo != null:
		label_estado_voo.text = (
			"TURBO ATIVO" if turbo_ativo else "PROPULSAO NORMAL"
		)
		label_estado_voo.add_theme_color_override(
			"font_color",
			Color(1.0, 0.56, 0.12, 0.96) if turbo_ativo
			else Color(0.44, 0.82, 1.0, 0.92)
		)

	if barra_velocidade != null:
		var pct_vel: float = clampf(velocidade_atual / 180.0, 0.04, 1.0)
		barra_velocidade.size.x = barra_velocidade_largura * pct_vel

	# Tela central: alvo real no radar.
	atualizar_marcador_radar()

	# Tela direita: telemetria leve.
	var fps: int = int(Engine.get_frames_per_second())
	if label_fps != null:
		label_fps.text = "FPS: " + str(fps)
		var cor_fps: Color = Color(0.50, 0.96, 0.70, 0.95)
		if fps < 40:
			cor_fps = Color(1.0, 0.56, 0.12, 0.96)
		if fps < 28:
			cor_fps = Color(1.0, 0.18, 0.12, 0.96)
		label_fps.add_theme_color_override("font_color", cor_fps)

	if label_propulsao != null:
		label_propulsao.text = "PROPULSAO: %d%%" % int(propulsao * 100.0)

	if label_link != null:
		label_link.text = "LINK: ESTAVEL"

	if barra_propulsao != null:
		barra_propulsao.size.x = barra_sistema_largura * propulsao

	if barra_energia != null:
		barra_energia.size.x = barra_sistema_largura * energia


func atualizar_marcador_radar() -> void:
	if label_radar_alvo == null:
		return

	for blip: Polygon2D in marcadores_radar_multiplos:
		if blip != null:
			blip.visible = false

	if player == null or !is_instance_valid(player):
		label_radar_alvo.text = "RADAR SEM LINK"
		return

	var contatos: Array[Node3D] = coletar_contatos_radar()
	if contatos.is_empty():
		label_radar_alvo.text = "SEM CONTATOS"
		return

	var exibidos: int = 0
	var menor_distancia: float = 999999.0

	for alvo: Node3D in contatos:
		if exibidos >= marcadores_radar_multiplos.size():
			break
		if alvo == null or !is_instance_valid(alvo) or !alvo.visible:
			continue

		var vetor_mundo: Vector3 = alvo.global_position - player.global_position
		var distancia: float = vetor_mundo.length()
		if distancia > alcance_radar:
			continue

		menor_distancia = minf(menor_distancia, distancia)
		var vetor_local: Vector3 = player.global_transform.basis.inverse() * vetor_mundo
		var radar_2d := Vector2(vetor_local.x, vetor_local.z)
		var escala_distancia: float = clampf(distancia / maxf(alcance_radar, 1.0), 0.0, 1.0)

		if radar_2d.length() > 0.001:
			radar_2d = radar_2d.normalized() * raio_radar * escala_distancia
		else:
			radar_2d = Vector2.ZERO

		var blip: Polygon2D = marcadores_radar_multiplos[exibidos]
		blip.position = radar_2d
		blip.color = cor_contato_radar(alvo)
		blip.visible = true
		exibidos += 1

	if exibidos == 0:
		label_radar_alvo.text = "SEM CONTATOS NO ALCANCE"
	else:
		label_radar_alvo.text = "%d CONTATOS // PROX %dm" % [exibidos, int(round(menor_distancia))]


func coletar_contatos_radar() -> Array[Node3D]:
	var suspeitos: Array[Node3D] = []
	var trafego: Array[Node3D] = []
	var destrocos: Array[Node3D] = []
	var outros: Array[Node3D] = []
	var vistos: Dictionary = {}
	var cena: Node = get_tree().current_scene
	if cena == null:
		return suspeitos

	# Prioridade garante que TODAS as naves de trafego entrem antes
	# dos destrocos quando o radar atingir o limite de blips.
	for no: Node in get_tree().get_nodes_in_group("radar_targets"):
		if !(no is Node3D) or no == player:
			continue
		var id: int = no.get_instance_id()
		if vistos.has(id):
			continue
		vistos[id] = true
		var alvo := no as Node3D
		if alvo.is_in_group("suspect_target"):
			suspeitos.append(alvo)
		elif alvo.is_in_group("traffic_ship"):
			trafego.append(alvo)
		elif alvo.is_in_group("space_debris"):
			destrocos.append(alvo)
		else:
			outros.append(alvo)

	# Compatibilidade com o alvo antigo da ocorrencia.
	var candidato: Node = cena.find_child("NaveSuspeitaTeste", true, false)
	if candidato is Node3D:
		var id2: int = candidato.get_instance_id()
		if !vistos.has(id2):
			vistos[id2] = true
			suspeitos.append(candidato as Node3D)

	var resultado: Array[Node3D] = []
	resultado.append_array(suspeitos)
	resultado.append_array(trafego)
	resultado.append_array(destrocos)
	resultado.append_array(outros)
	return resultado


func cor_contato_radar(alvo: Node3D) -> Color:
	if alvo.is_in_group("suspect_target") or alvo.name.to_lower().contains("suspect"):
		return Color(1.0, 0.42, 0.08, 0.98)
	if alvo.is_in_group("space_debris"):
		return Color(0.78, 0.82, 0.88, 0.82)
	if alvo.is_in_group("traffic_ship"):
		return Color(0.12, 0.86, 1.0, 0.92)
	return Color(0.45, 1.0, 0.60, 0.90)


func animar_radar(delta: float) -> void:
	if linha_varredura_radar == null:
		return

	angulo_varredura = fmod(angulo_varredura + delta * 1.9, TAU)
	var ponta := centro_radar + Vector2(
		cos(angulo_varredura),
		sin(angulo_varredura)
	) * raio_radar

	linha_varredura_radar.points = PackedVector2Array([
		centro_radar,
		ponta
	])


# =========================================================
# HELPERS 2D
# =========================================================

func adicionar_poligono(
	pontos: Array[Vector2],
	cor: Color
) -> Polygon2D:
	var poligono := Polygon2D.new()
	poligono.polygon = PackedVector2Array(pontos)
	poligono.color = cor
	cockpit_root.add_child(poligono)
	return poligono


func adicionar_linha(
	pontos: Array[Vector2],
	largura: float,
	cor: Color,
	fechada: bool
) -> Line2D:
	var linha := Line2D.new()
	linha.points = PackedVector2Array(pontos)
	linha.width = largura
	linha.default_color = cor
	linha.closed = fechada
	linha.begin_cap_mode = Line2D.LINE_CAP_ROUND
	linha.end_cap_mode = Line2D.LINE_CAP_ROUND
	linha.joint_mode = Line2D.LINE_JOINT_ROUND
	cockpit_root.add_child(linha)
	return linha


func adicionar_glow(
	pontos: Array[Vector2],
	largura: float,
	cor_centro: Color,
	cor_glow: Color
) -> void:
	adicionar_linha(
		pontos,
		largura * 4.2,
		cor_glow,
		false
	)

	adicionar_linha(
		pontos,
		largura,
		cor_centro,
		false
	)


func adicionar_circulo(
	centro: Vector2,
	raio: float,
	cor: Color,
	segmentos: int = 20
) -> Polygon2D:
	return adicionar_poligono(
		pontos_circulo(centro, raio, segmentos),
		cor
	)


func pontos_circulo(
	centro: Vector2,
	raio: float,
	segmentos: int = 24
) -> Array[Vector2]:
	var pontos: Array[Vector2] = []
	var quantidade: int = maxi(segmentos, 8)

	for i: int in range(quantidade):
		var angulo: float = TAU * float(i) / float(quantidade)
		pontos.append(
			centro
			+ Vector2(
				cos(angulo) * raio,
				sin(angulo) * raio
			)
		)

	return pontos
