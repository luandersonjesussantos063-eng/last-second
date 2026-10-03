extends CanvasLayer


# =========================================================
# LAST SECOND - SUSPECT TARGET HUD v2.0
#
# - Localiza a nave suspeita
# - Mostra distancia
# - Mostra direcao
# - Detecta alcance de abordagem
# - Tecla E inicia scanner
# - Scanner leva alguns segundos
# - Exibe resultado da consulta
# =========================================================


@export var unidades_por_km: float = 1.0

@export var distancia_deteccao: float = 5000.0

@export var distancia_abordagem: float = 220.0

@export var margem_tela: float = 70.0

@export var tempo_scan_total: float = 4.0


var player: Node3D = null

var camera: Camera3D = null

var alvo: Node3D = null


var hud_root: Control = null

var marcador_container: Control = null

var label_simbolo: Label = null

var label_nome: Label = null

var label_distancia: Label = null

var label_acao: Label = null


var tempo_busca: float = 0.0


# =========================================================
# SCANNER
# =========================================================

enum EstadoScanner {
	AGUARDANDO,
	ESCANEANDO,
	CONCLUIDO
}


var estado_scanner: int = (
	EstadoScanner.AGUARDANDO
)


var progresso_scan: float = 0.0

var e_estava_pressionado: bool = false


# =========================================================
# READY
# =========================================================

func _ready() -> void:

	layer = 30


	call_deferred(
		"iniciar_hud"
	)


# =========================================================
# INICIAR
# =========================================================

func iniciar_hud() -> void:

	await get_tree().process_frame

	await get_tree().process_frame


	player = get_node_or_null(
		"../Player"
	) as Node3D


	if player == null:

		push_warning(
			"SuspectTargetHUD: Player nao encontrado."
		)

		return


	camera = procurar_camera(
		player
	)


	if camera == null:

		push_warning(
			"SuspectTargetHUD: Camera nao encontrada."
		)

		return


	criar_interface()


	procurar_alvo()


# =========================================================
# PROCESS
# =========================================================

func _process(delta: float) -> void:

	if hud_root == null:
		return


	if alvo == null:

		tempo_busca += delta


		if tempo_busca >= 0.5:

			tempo_busca = 0.0

			procurar_alvo()


		if marcador_container != null:

			marcador_container.visible = false


		return


	if !is_instance_valid(
		alvo
	):

		alvo = null


		if marcador_container != null:

			marcador_container.visible = false


		return


	var distancia: float = (
		player.global_position.distance_to(
			alvo.global_position
		)
	)


	processar_scanner(
		delta,
		distancia
	)


	atualizar_marcador(
		distancia
	)


# =========================================================
# PROCURAR ALVO
# =========================================================

func procurar_alvo() -> void:

	var suspect_test: Node = get_node_or_null(
		"../SuspectTest"
	)


	if suspect_test == null:
		return


	var resultado: Node = encontrar_node_recursivo(
		suspect_test,
		"NaveSuspeitaTeste"
	)


	if resultado is Node3D:

		alvo = resultado as Node3D


		print(
			"SUSPECT TARGET HUD: NAVE ENCONTRADA"
		)


# =========================================================
# SCANNER
# =========================================================

func processar_scanner(
	delta: float,
	distancia: float
) -> void:

	var e_pressionado: bool = (
		Input.is_key_pressed(
			KEY_E
		)
	)


	var acabou_de_apertar: bool = (
		e_pressionado
		and
		!e_estava_pressionado
	)


	e_estava_pressionado = e_pressionado


	# =====================================================
	# AINDA LONGE
	# =====================================================

	if distancia > distancia_abordagem:

		if estado_scanner == (
			EstadoScanner.ESCANEANDO
		):

			cancelar_scan()


		return


	# =====================================================
	# INICIAR SCAN
	# =====================================================

	if estado_scanner == (
		EstadoScanner.AGUARDANDO
	):

		if acabou_de_apertar:

			iniciar_scan()


		return


	# =====================================================
	# ESCANEANDO
	# =====================================================

	if estado_scanner == (
		EstadoScanner.ESCANEANDO
	):

		progresso_scan += delta


		if progresso_scan >= tempo_scan_total:

			concluir_scan()


# =========================================================
# INICIAR SCAN
# =========================================================

func iniciar_scan() -> void:

	estado_scanner = (
		EstadoScanner.ESCANEANDO
	)


	progresso_scan = 0.0


	print(
		"SCANNER: ANALISE INICIADA"
	)


# =========================================================
# CANCELAR SCAN
# =========================================================

func cancelar_scan() -> void:

	estado_scanner = (
		EstadoScanner.AGUARDANDO
	)


	progresso_scan = 0.0


	print(
		"SCANNER: CANCELADO - ALVO FORA DE ALCANCE"
	)


# =========================================================
# CONCLUIR SCAN
# =========================================================

func concluir_scan() -> void:

	estado_scanner = (
		EstadoScanner.CONCLUIDO
	)


	progresso_scan = tempo_scan_total


	print(
		"================================="
	)

	print(
		"SCAN CONCLUIDO"
	)

	print(
		"REGISTRO: CX-7714"
	)

	print(
		"PROPRIETARIO: DESCONHECIDO"
	)

	print(
		"STATUS: IDENTIFICACAO INVALIDA"
	)

	print(
		"================================="
	)


# =========================================================
# ATUALIZAR MARCADOR
# =========================================================

func atualizar_marcador(
	distancia_unidades: float
) -> void:

	if player == null:
		return


	if camera == null:
		return


	# =====================================================
	# FORA DO RADAR
	# =====================================================

	if distancia_unidades > distancia_deteccao:

		marcador_container.visible = false

		return


	marcador_container.visible = true


	var distancia_km: float = (
		distancia_unidades
		/
		maxf(
			unidades_por_km,
			0.001
		)
	)


	label_distancia.text = (
		formatar_distancia(
			distancia_km
		)
	)


	var viewport_size: Vector2 = (
		get_viewport().get_visible_rect().size
	)


	var centro_tela: Vector2 = (
		viewport_size * 0.5
	)


	# =====================================================
	# POSICAO DO ALVO
	# =====================================================

	var atras: bool = camera.is_position_behind(
		alvo.global_position
	)


	var posicao_tela: Vector2


	if !atras:

		posicao_tela = camera.unproject_position(
			alvo.global_position
		)


	else:

		var direcao_mundo: Vector3 = (
			alvo.global_position
			-
			camera.global_position
		).normalized()


		var direita: Vector3 = (
			camera.global_transform.basis.x
		)


		var cima: Vector3 = (
			camera.global_transform.basis.y
		)


		var lado: float = (
			direcao_mundo.dot(
				direita
			)
		)


		var vertical: float = (
			direcao_mundo.dot(
				cima
			)
		)


		posicao_tela = (
			centro_tela
			+
			Vector2(
				lado,
				-vertical
			)
			*
			10000.0
		)


	# =====================================================
	# DENTRO DA TELA?
	# =====================================================

	var dentro_tela: bool = (
		!atras
		and
		posicao_tela.x >= margem_tela
		and
		posicao_tela.x <= (
			viewport_size.x
			-
			margem_tela
		)
		and
		posicao_tela.y >= margem_tela
		and
		posicao_tela.y <= (
			viewport_size.y
			-
			margem_tela
		)
	)


	if dentro_tela:

		marcador_container.position = (
			posicao_tela
			-
			Vector2(
				20.0,
				20.0
			)
		)


		if estado_scanner != (
			EstadoScanner.CONCLUIDO
		):

			label_simbolo.text = "◇"


	else:

		var direcao_2d: Vector2 = (
			posicao_tela
			-
			centro_tela
		)


		if direcao_2d.length() < 0.01:

			direcao_2d = Vector2.UP


		direcao_2d = (
			direcao_2d.normalized()
		)


		var limite_x: float = (
			viewport_size.x
			*
			0.5
			-
			margem_tela
		)


		var limite_y: float = (
			viewport_size.y
			*
			0.5
			-
			margem_tela
		)


		var escala_x: float = INF

		var escala_y: float = INF


		if absf(
			direcao_2d.x
		) > 0.001:

			escala_x = (
				limite_x
				/
				absf(
					direcao_2d.x
				)
			)


		if absf(
			direcao_2d.y
		) > 0.001:

			escala_y = (
				limite_y
				/
				absf(
					direcao_2d.y
				)
			)


		var escala_final: float = minf(
			escala_x,
			escala_y
		)


		var posicao_borda: Vector2 = (
			centro_tela
			+
			direcao_2d
			*
			escala_final
		)


		marcador_container.position = (
			posicao_borda
			-
			Vector2(
				20.0,
				20.0
			)
		)


		if estado_scanner != (
			EstadoScanner.CONCLUIDO
		):

			label_simbolo.text = (
				simbolo_direcao(
					direcao_2d
				)
			)


	# =====================================================
	# FORA DO ALCANCE DE SCAN
	# =====================================================

	if distancia_unidades > distancia_abordagem:

		label_nome.text = (
			"NAVE NAO IDENTIFICADA"
		)


		label_acao.visible = false


		definir_cor_normal()


		return


	# =====================================================
	# AGUARDANDO SCAN
	# =====================================================

	if estado_scanner == (
		EstadoScanner.AGUARDANDO
	):

		label_nome.text = (
			"ALVO EM ALCANCE"
		)


		label_simbolo.text = "◆"


		label_acao.text = (
			"PRESSIONE E PARA ESCANEAR"
		)


		label_acao.visible = true


		definir_cor_scan()


		return


	# =====================================================
	# ESCANEANDO
	# =====================================================

	if estado_scanner == (
		EstadoScanner.ESCANEANDO
	):

		var porcentagem: int = int(
			clampf(
				progresso_scan
				/
				tempo_scan_total,
				0.0,
				1.0
			)
			*
			100.0
		)


		label_nome.text = (
			"ESCANEANDO ALVO..."
		)


		label_simbolo.text = "◎"


		label_acao.text = (
			"ANALISANDO SISTEMAS... "
			+
			str(
				porcentagem
			)
			+
			"%"
		)


		label_acao.visible = true


		definir_cor_scan()


		return


	# =====================================================
	# CONCLUIDO
	# =====================================================

	if estado_scanner == (
		EstadoScanner.CONCLUIDO
	):

		label_nome.text = (
			"NAVE SUSPEITA"
		)


		label_simbolo.text = "◆"


		label_acao.text = (
			"ID: CX-7714\n"
			+
			"REGISTRO: INVALIDO\n"
			+
			"PROPRIETARIO: DESCONHECIDO"
		)


		label_acao.visible = true


		definir_cor_alerta()


# =========================================================
# CORES
# =========================================================

func definir_cor_normal() -> void:

	var cor: Color = Color(
		1.0,
		0.66,
		0.25,
		1.0
	)


	label_nome.add_theme_color_override(
		"font_color",
		cor
	)


	label_simbolo.add_theme_color_override(
		"font_color",
		cor
	)


func definir_cor_scan() -> void:

	var cor: Color = Color(
		0.30,
		1.0,
		0.70,
		1.0
	)


	label_nome.add_theme_color_override(
		"font_color",
		cor
	)


	label_simbolo.add_theme_color_override(
		"font_color",
		cor
	)


func definir_cor_alerta() -> void:

	var cor: Color = Color(
		1.0,
		0.22,
		0.16,
		1.0
	)


	label_nome.add_theme_color_override(
		"font_color",
		cor
	)


	label_simbolo.add_theme_color_override(
		"font_color",
		cor
	)


	label_acao.add_theme_color_override(
		"font_color",
		Color(
			1.0,
			0.55,
			0.25,
			1.0
		)
	)


# =========================================================
# SIMBOLO DIRECAO
# =========================================================

func simbolo_direcao(
	direcao: Vector2
) -> String:

	if absf(
		direcao.x
	) > absf(
		direcao.y
	):

		if direcao.x > 0.0:

			return "▷"

		else:

			return "◁"


	else:

		if direcao.y > 0.0:

			return "▽"

		else:

			return "△"


# =========================================================
# FORMATAR DISTANCIA
# =========================================================

func formatar_distancia(
	distancia_km: float
) -> String:

	if distancia_km < 1000.0:

		return (
			"%.0f km"
			%
			distancia_km
		)


	return (
		"%.2f mil km"
		%
		(
			distancia_km
			/
			1000.0
		)
	)


# =========================================================
# CRIAR INTERFACE
# =========================================================

func criar_interface() -> void:

	hud_root = Control.new()


	hud_root.name = "SuspectHUDRoot"


	hud_root.set_anchors_and_offsets_preset(
		Control.PRESET_FULL_RECT
	)


	hud_root.mouse_filter = (
		Control.MOUSE_FILTER_IGNORE
	)


	add_child(
		hud_root
	)


	# =====================================================
	# CONTAINER
	# =====================================================

	marcador_container = Control.new()


	marcador_container.name = "TargetMarker"


	marcador_container.size = Vector2(
		320.0,
		130.0
	)


	marcador_container.mouse_filter = (
		Control.MOUSE_FILTER_IGNORE
	)


	marcador_container.visible = false


	hud_root.add_child(
		marcador_container
	)


	# =====================================================
	# SIMBOLO
	# =====================================================

	label_simbolo = Label.new()


	label_simbolo.text = "◇"


	label_simbolo.position = Vector2(
		0.0,
		0.0
	)


	label_simbolo.size = Vector2(
		38.0,
		38.0
	)


	label_simbolo.add_theme_font_size_override(
		"font_size",
		24
	)


	label_simbolo.add_theme_color_override(
		"font_color",
		Color(
			1.0,
			0.66,
			0.25,
			1.0
		)
	)


	label_simbolo.add_theme_color_override(
		"font_outline_color",
		Color.BLACK
	)


	label_simbolo.add_theme_constant_override(
		"outline_size",
		4
	)


	marcador_container.add_child(
		label_simbolo
	)


	# =====================================================
	# NOME
	# =====================================================

	label_nome = Label.new()


	label_nome.text = (
		"NAVE NAO IDENTIFICADA"
	)


	label_nome.position = Vector2(
		35.0,
		0.0
	)


	label_nome.size = Vector2(
		275.0,
		28.0
	)


	label_nome.add_theme_font_size_override(
		"font_size",
		16
	)


	label_nome.add_theme_color_override(
		"font_color",
		Color(
			1.0,
			0.66,
			0.25,
			1.0
		)
	)


	label_nome.add_theme_color_override(
		"font_outline_color",
		Color.BLACK
	)


	label_nome.add_theme_constant_override(
		"outline_size",
		4
	)


	marcador_container.add_child(
		label_nome
	)


	# =====================================================
	# DISTANCIA
	# =====================================================

	label_distancia = Label.new()


	label_distancia.text = "--- km"


	label_distancia.position = Vector2(
		36.0,
		24.0
	)


	label_distancia.size = Vector2(
		260.0,
		24.0
	)


	label_distancia.add_theme_font_size_override(
		"font_size",
		13
	)


	label_distancia.add_theme_color_override(
		"font_color",
		Color(
			0.70,
			0.82,
			0.88,
			1.0
		)
	)


	label_distancia.add_theme_color_override(
		"font_outline_color",
		Color.BLACK
	)


	label_distancia.add_theme_constant_override(
		"outline_size",
		3
	)


	marcador_container.add_child(
		label_distancia
	)


	# =====================================================
	# ACAO / RESULTADO
	# =====================================================

	label_acao = Label.new()


	label_acao.text = (
		"PRESSIONE E PARA ESCANEAR"
	)


	label_acao.position = Vector2(
		36.0,
		48.0
	)


	label_acao.size = Vector2(
		285.0,
		75.0
	)


	label_acao.add_theme_font_size_override(
		"font_size",
		12
	)


	label_acao.add_theme_color_override(
		"font_color",
		Color(
			0.30,
			1.0,
			0.70,
			1.0
		)
	)


	label_acao.add_theme_color_override(
		"font_outline_color",
		Color.BLACK
	)


	label_acao.add_theme_constant_override(
		"outline_size",
		3
	)


	label_acao.visible = false


	marcador_container.add_child(
		label_acao
	)


# =========================================================
# CAMERA
# =========================================================

func procurar_camera(
	no_atual: Node
) -> Camera3D:

	if no_atual is Camera3D:

		return no_atual as Camera3D


	for filho: Node in no_atual.get_children():

		var resultado: Camera3D = procurar_camera(
			filho
		)


		if resultado != null:

			return resultado


	return null


# =========================================================
# BUSCA RECURSIVA
# =========================================================

func encontrar_node_recursivo(
	no_atual: Node,
	nome_procurado: String
) -> Node:

	if String(
		no_atual.name
	) == nome_procurado:

		return no_atual


	for filho: Node in no_atual.get_children():

		var resultado: Node = encontrar_node_recursivo(
			filho,
			nome_procurado
		)


		if resultado != null:

			return resultado


	return null
