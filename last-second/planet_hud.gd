extends CanvasLayer


# =========================================================
# LAST SECOND - PLANET HUD v1.0
#
# HUD DE NAVEGACAO ESPACIAL
#
# - Nome discreto
# - Distancia em tempo real
# - Marcador ◇
# - Esconde planetas atras da nave
# - Esconde marcadores fora da tela
# - Mais transparente quando longe/lateral
# - Destaca planeta para onde a nave aponta
# - Terra e Sol incluidos
# =========================================================


@export var unidades_por_km: float = 1.0

@export var distancia_maxima_hud: float = 50000.0

@export var distancia_nome_sempre: float = 2200.0

@export var zona_nome_completo: float = 0.38

@export var zona_foco: float = 0.20

@export var margem_tela: float = 35.0

@export var tamanho_nome: int = 18

@export var tamanho_distancia: int = 14

@export var tamanho_marcador: int = 22


var player: Node3D = null

var camera: Camera3D = null

var solar_system: Node3D = null

var space_world: Node = null


var hud_root: Control = null


var marcadores: Array[Dictionary] = []


var tempo_rebuscar: float = 0.0


# =========================================================
# READY
# =========================================================

func _ready() -> void:

	layer = 20

	call_deferred(
		"preparar_hud"
	)


# =========================================================
# PREPARAR HUD
# =========================================================

func preparar_hud() -> void:

	await get_tree().process_frame

	await get_tree().process_frame

	await get_tree().process_frame


	player = get_node_or_null(
		"../Player"
	) as Node3D


	solar_system = get_node_or_null(
		"../SolarSystem"
	) as Node3D


	space_world = get_node_or_null(
		"../SpaceWorld"
	)


	if player == null:

		push_warning(
			"PlanetHUD: Player nao encontrado."
		)

		return


	camera = procurar_camera(
		player
	)


	if camera == null:

		push_warning(
			"PlanetHUD: Camera nao encontrada."
		)

		return


	criar_raiz_hud()


	# =====================================================
	# ESCONDER ETIQUETAS ANTIGAS
	# =====================================================

	if solar_system != null:

		esconder_labels_3d_antigos(
			solar_system
		)


	# =====================================================
	# PEGAR ESCALA DO SOLAR SYSTEM
	# =====================================================

	if solar_system != null:

		var escala_variant: Variant = (
			solar_system.get(
				"unidades_por_km"
			)
		)


		if escala_variant != null:

			unidades_por_km = float(
				escala_variant
			)


	descobrir_planetas()


	print(
		"PLANET HUD ATIVADO"
	)


# =========================================================
# ROOT DO HUD
# =========================================================

func criar_raiz_hud() -> void:

	hud_root = Control.new()


	hud_root.name = "PlanetHUDRoot"


	hud_root.set_anchors_and_offsets_preset(
		Control.PRESET_FULL_RECT
	)


	hud_root.mouse_filter = (
		Control.MOUSE_FILTER_IGNORE
	)


	add_child(
		hud_root
	)


# =========================================================
# PROCESS
# =========================================================

func _process(delta: float) -> void:

	if hud_root == null:
		return


	if player == null:
		return


	if camera == null:

		camera = procurar_camera(
			player
		)


		if camera == null:
			return


	tempo_rebuscar += delta


	# =====================================================
	# CASO SOLAR SYSTEM TENHA SIDO CRIADO DEPOIS
	# =====================================================

	if tempo_rebuscar >= 2.0:

		tempo_rebuscar = 0.0


		if marcadores.size() < 9:

			solar_system = get_node_or_null(
				"../SolarSystem"
			) as Node3D


			space_world = get_node_or_null(
				"../SpaceWorld"
			)


			if solar_system != null:

				esconder_labels_3d_antigos(
					solar_system
				)


			descobrir_planetas()


	atualizar_hud()


# =========================================================
# DESCOBRIR PLANETAS
# =========================================================

func descobrir_planetas() -> void:

	if hud_root == null:
		return


	limpar_marcadores()


	if solar_system != null:

		adicionar_alvo_por_nome(
			"Sol",
			solar_system
		)


		adicionar_alvo_por_nome(
			"Mercurio",
			solar_system
		)


		adicionar_alvo_por_nome(
			"Venus",
			solar_system
		)


		adicionar_alvo_por_nome(
			"Marte",
			solar_system
		)


		adicionar_alvo_por_nome(
			"Jupiter",
			solar_system
		)


		adicionar_alvo_por_nome(
			"Saturno",
			solar_system
		)


		adicionar_alvo_por_nome(
			"Urano",
			solar_system
		)


		adicionar_alvo_por_nome(
			"Netuno",
			solar_system
		)


	# =====================================================
	# TERRA EXISTENTE NO SPACE WORLD
	# =====================================================

	if space_world != null:

		var terra: MeshInstance3D = procurar_terra(
			space_world
		)


		if terra != null:

			criar_marcador(
				"Terra",
				terra
			)


# =========================================================
# ADICIONAR ALVO PELO NOME
# =========================================================

func adicionar_alvo_por_nome(
	nome: String,
	root: Node
) -> void:

	var alvo: Node = encontrar_node_recursivo(
		root,
		nome
	)


	if alvo == null:
		return


	if alvo is Node3D:

		criar_marcador(
			nome,
			alvo as Node3D
		)


# =========================================================
# CRIAR MARCADOR
# =========================================================

func criar_marcador(
	nome: String,
	alvo: Node3D
) -> void:

	var container: Control = Control.new()


	container.name = (
		"HUD_" + nome
	)


	container.size = Vector2(
		250.0,
		65.0
	)


	container.mouse_filter = (
		Control.MOUSE_FILTER_IGNORE
	)


	hud_root.add_child(
		container
	)


	# =====================================================
	# DIAMANTE
	# =====================================================

	var marcador: Label = Label.new()


	marcador.name = "Marker"


	marcador.text = "◇"


	marcador.position = Vector2(
		-11.0,
		-16.0
	)


	marcador.size = Vector2(
		30.0,
		35.0
	)


	marcador.mouse_filter = (
		Control.MOUSE_FILTER_IGNORE
	)


	marcador.add_theme_font_size_override(
		"font_size",
		tamanho_marcador
	)


	marcador.add_theme_color_override(
		"font_color",
		Color(
			0.55,
			0.87,
			1.0,
			1.0
		)
	)


	marcador.add_theme_color_override(
		"font_outline_color",
		Color(
			0.0,
			0.0,
			0.0,
			0.95
		)
	)


	marcador.add_theme_constant_override(
		"outline_size",
		3
	)


	container.add_child(
		marcador
	)


	# =====================================================
	# NOME
	# =====================================================

	var label_nome: Label = Label.new()


	label_nome.name = "Name"


	label_nome.text = nome.to_upper()


	label_nome.position = Vector2(
		17.0,
		-22.0
	)


	label_nome.size = Vector2(
		215.0,
		27.0
	)


	label_nome.mouse_filter = (
		Control.MOUSE_FILTER_IGNORE
	)


	label_nome.add_theme_font_size_override(
		"font_size",
		tamanho_nome
	)


	label_nome.add_theme_color_override(
		"font_color",
		Color(
			0.82,
			0.93,
			1.0,
			1.0
		)
	)


	label_nome.add_theme_color_override(
		"font_outline_color",
		Color(
			0.0,
			0.0,
			0.0,
			0.95
		)
	)


	label_nome.add_theme_constant_override(
		"outline_size",
		4
	)


	container.add_child(
		label_nome
	)


	# =====================================================
	# DISTANCIA
	# =====================================================

	var label_distancia: Label = Label.new()


	label_distancia.name = "Distance"


	label_distancia.text = "--- km"


	label_distancia.position = Vector2(
		18.0,
		1.0
	)


	label_distancia.size = Vector2(
		210.0,
		24.0
	)


	label_distancia.mouse_filter = (
		Control.MOUSE_FILTER_IGNORE
	)


	label_distancia.add_theme_font_size_override(
		"font_size",
		tamanho_distancia
	)


	label_distancia.add_theme_color_override(
		"font_color",
		Color(
			0.47,
			0.76,
			0.88,
			1.0
		)
	)


	label_distancia.add_theme_color_override(
		"font_outline_color",
		Color(
			0.0,
			0.0,
			0.0,
			0.90
		)
	)


	label_distancia.add_theme_constant_override(
		"outline_size",
		3
	)


	container.add_child(
		label_distancia
	)


	marcadores.append(
		{
			"name": nome,
			"target": alvo,
			"container": container,
			"marker": marcador,
			"name_label": label_nome,
			"distance_label": label_distancia
		}
	)


# =========================================================
# ATUALIZAR HUD
# =========================================================

func atualizar_hud() -> void:

	var viewport_size: Vector2 = (
		get_viewport().get_visible_rect().size
	)


	var centro_tela: Vector2 = (
		viewport_size * 0.5
	)


	var alvo_focado: Node3D = (
		encontrar_alvo_em_foco(
			viewport_size,
			centro_tela
		)
	)


	for item: Dictionary in marcadores:

		var alvo: Node3D = (
			item.get(
				"target"
			) as Node3D
		)


		var container: Control = (
			item.get(
				"container"
			) as Control
		)


		var marcador: Label = (
			item.get(
				"marker"
			) as Label
		)


		var nome_label: Label = (
			item.get(
				"name_label"
			) as Label
		)


		var distancia_label: Label = (
			item.get(
				"distance_label"
			) as Label
		)


		if alvo == null:
			continue


		if container == null:
			continue


		if !is_instance_valid(
			alvo
		):

			container.visible = false

			continue


		# =================================================
		# ATRAS DA NAVE
		# =================================================

		if camera.is_position_behind(
			alvo.global_position
		):

			container.visible = false

			continue


		var distancia_unidades: float = (
			player.global_position.distance_to(
				alvo.global_position
			)
		)


		if distancia_unidades > distancia_maxima_hud:

			container.visible = false

			continue


		var screen_pos: Vector2 = (
			camera.unproject_position(
				alvo.global_position
			)
		)


		# =================================================
		# FORA DA TELA
		# =================================================

		if screen_pos.x < margem_tela:

			container.visible = false

			continue


		if screen_pos.x > (
			viewport_size.x
			-
			margem_tela
		):

			container.visible = false

			continue


		if screen_pos.y < margem_tela:

			container.visible = false

			continue


		if screen_pos.y > (
			viewport_size.y
			-
			margem_tela
		):

			container.visible = false

			continue


		container.visible = true


		container.position = screen_pos


		# =================================================
		# DISTANCIA AO CENTRO DA TELA
		# =================================================

		var distancia_centro: float = (
			screen_pos.distance_to(
				centro_tela
			)
		)


		var referencia_tela: float = maxf(
			viewport_size.x,
			viewport_size.y
		)


		var centro_normalizado: float = (
			distancia_centro
			/
			maxf(
				referencia_tela,
				1.0
			)
		)


		# =================================================
		# DISTANCIA EM KM
		# =================================================

		var distancia_km: float = (
			distancia_unidades
			/
			maxf(
				unidades_por_km,
				0.001
			)
		)


		distancia_label.text = (
			formatar_distancia(
				distancia_km
			)
		)


		# =================================================
		# MOSTRAR TEXTO COMPLETO?
		# =================================================

		var perto: bool = (
			distancia_unidades
			<=
			distancia_nome_sempre
		)


		var centralizado: bool = (
			centro_normalizado
			<=
			zona_nome_completo
		)


		var focado: bool = (
			alvo
			==
			alvo_focado
		)


		var mostrar_completo: bool = (
			perto
			or
			centralizado
			or
			focado
		)


		nome_label.visible = (
			mostrar_completo
		)


		distancia_label.visible = (
			mostrar_completo
		)


		# =================================================
		# OPACIDADE
		# =================================================

		var centralidade: float = (
			1.0
			-
			clampf(
				centro_normalizado
				/
				0.60,
				0.0,
				1.0
			)
		)


		var proximidade: float = (
			1.0
			-
			clampf(
				distancia_unidades
				/
				distancia_maxima_hud,
				0.0,
				1.0
			)
		)


		var alpha: float = clampf(
			0.28
			+
			centralidade
			*
			0.48
			+
			proximidade
			*
			0.20,
			0.25,
			1.0
		)


		# =================================================
		# PLANETA EM FOCO
		# =================================================

		if focado:

			alpha = 1.0


			marcador.text = "◆"


			marcador.add_theme_color_override(
				"font_color",
				Color(
					0.35,
					0.95,
					1.0,
					1.0
				)
			)


			nome_label.add_theme_color_override(
				"font_color",
				Color(
					0.78,
					0.98,
					1.0,
					1.0
				)
			)


			distancia_label.add_theme_color_override(
				"font_color",
				Color(
					0.40,
					0.90,
					1.0,
					1.0
				)
			)


		else:

			marcador.text = "◇"


			marcador.add_theme_color_override(
				"font_color",
				Color(
					0.55,
					0.87,
					1.0,
					1.0
				)
			)


			nome_label.add_theme_color_override(
				"font_color",
				Color(
					0.82,
					0.93,
					1.0,
					1.0
				)
			)


			distancia_label.add_theme_color_override(
				"font_color",
				Color(
					0.47,
					0.76,
					0.88,
					1.0
				)
			)


		container.modulate = Color(
			1.0,
			1.0,
			1.0,
			alpha
		)


# =========================================================
# QUAL PLANETA ESTA NO CENTRO?
# =========================================================

func encontrar_alvo_em_foco(
	viewport_size: Vector2,
	centro_tela: Vector2
) -> Node3D:

	var melhor_alvo: Node3D = null

	var melhor_distancia: float = INF


	for item: Dictionary in marcadores:

		var alvo: Node3D = (
			item.get(
				"target"
			) as Node3D
		)


		if alvo == null:
			continue


		if !is_instance_valid(
			alvo
		):
			continue


		if camera.is_position_behind(
			alvo.global_position
		):

			continue


		var distancia_nave: float = (
			player.global_position.distance_to(
				alvo.global_position
			)
		)


		if distancia_nave > distancia_maxima_hud:
			continue


		var screen_pos: Vector2 = (
			camera.unproject_position(
				alvo.global_position
			)
		)


		if screen_pos.x < 0.0:
			continue


		if screen_pos.y < 0.0:
			continue


		if screen_pos.x > viewport_size.x:
			continue


		if screen_pos.y > viewport_size.y:
			continue


		var distancia_centro: float = (
			screen_pos.distance_to(
				centro_tela
			)
		)


		var referencia: float = maxf(
			viewport_size.x,
			viewport_size.y
		)


		var normalizada: float = (
			distancia_centro
			/
			maxf(
				referencia,
				1.0
			)
		)


		if normalizada > zona_foco:
			continue


		if distancia_centro < melhor_distancia:

			melhor_distancia = distancia_centro

			melhor_alvo = alvo


	return melhor_alvo


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


	if distancia_km < 1000000.0:

		return (
			"%.2f mil km"
			%
			(
				distancia_km
				/
				1000.0
			)
		)


	return (
		"%.2f mi km"
		%
		(
			distancia_km
			/
			1000000.0
		)
	)


# =========================================================
# LIMPAR MARCADORES
# =========================================================

func limpar_marcadores() -> void:

	for item: Dictionary in marcadores:

		var container: Control = (
			item.get(
				"container"
			) as Control
		)


		if container != null:

			if is_instance_valid(
				container
			):

				container.queue_free()


	marcadores.clear()


# =========================================================
# ESCONDER LABELS 3D ANTIGOS
# =========================================================

func esconder_labels_3d_antigos(
	no_atual: Node
) -> void:

	if no_atual is Label3D:

		var label: Label3D = (
			no_atual as Label3D
		)


		if String(
			label.name
		).begins_with(
			"Label_"
		):

			label.visible = false


	for filho: Node in no_atual.get_children():

		esconder_labels_3d_antigos(
			filho
		)


# =========================================================
# ENCONTRAR NODE RECURSIVAMENTE
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


# =========================================================
# PROCURAR CAMERA
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
# PROCURAR TERRA
# =========================================================

func procurar_terra(
	no_atual: Node
) -> MeshInstance3D:

	var candidatos: Array[MeshInstance3D] = []


	coletar_meshes(
		no_atual,
		candidatos
	)


	var melhor: MeshInstance3D = null

	var melhor_pontos: int = -10000


	for candidato: MeshInstance3D in candidatos:

		if candidato.mesh == null:
			continue


		var nome: String = (
			String(
				candidato.name
			)
			.to_lower()
		)


		var pontos: int = 0


		if nome.contains(
			"earth"
		):

			pontos += 180


		if nome.contains(
			"terra"
		):

			pontos += 180


		if nome.contains(
			"planet"
		):

			pontos += 120


		if nome.contains(
			"ocean"
		):

			pontos += 45


		if candidato.mesh is SphereMesh:

			pontos += 25


		if nome.contains(
			"moon"
		):

			pontos -= 500


		if nome.contains(
			"lua"
		):

			pontos -= 500


		if nome.contains(
			"cloud"
		):

			pontos -= 500


		if nome.contains(
			"atmos"
		):

			pontos -= 500


		if nome.contains(
			"asteroid"
		):

			pontos -= 500


		if nome.contains(
			"star"
		):

			pontos -= 500


		if pontos > melhor_pontos:

			melhor_pontos = pontos

			melhor = candidato


	if melhor_pontos < 20:

		return null


	return melhor


# =========================================================
# COLETAR MESHES
# =========================================================

func coletar_meshes(
	no_atual: Node,
	lista: Array[MeshInstance3D]
) -> void:

	if no_atual is MeshInstance3D:

		lista.append(
			no_atual as MeshInstance3D
		)


	for filho: Node in no_atual.get_children():

		coletar_meshes(
			filho,
			lista
		)
