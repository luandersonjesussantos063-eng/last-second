extends Node3D


# =========================================================
# LAST SECOND - PLAYER v0.7.1
# NOVO COCKPIT + CONTROLE VERTICAL CORRIGIDO
# =========================================================
#
# CONTROLES:
#
# W / SETA CIMA     = SOBE
# S / SETA BAIXO    = DESCE
# A / SETA ESQUERDA = ESQUERDA
# D / SETA DIREITA  = DIREITA
# SHIFT              = TURBO
#
# =========================================================


@export var velocidade_normal := 22.0
@export var velocidade_turbo := 50.0

var velocidade_atual := 22.0

var target_x := 0.0
var target_y := 0.0

var ship_x := 0.0
var ship_y := 0.0

var control_speed := 1.5
var turn_strength := 1.15

var turbo := false
var tempo := 0.0
var timer_telas := 0.0


@onready var camera: Camera3D = $Camera3D


var camera_posicao_inicial := Vector3.ZERO
var cockpit_novo: Node = null


# =========================================================
# TELAS
# =========================================================

var radar_sweep: Line2D

var radar_blip_1: ColorRect
var radar_blip_2: ColorRect
var radar_blip_3: ColorRect

var radar_coordenadas: Label

var velocidade_label: Label
var modo_voo_label: Label
var barra_velocidade: ColorRect

var hull_label: Label
var energia_label: Label
var engine_label: Label

var barra_hull: ColorRect
var barra_energia: ColorRect


# =========================================================
# INICIO
# =========================================================

func _ready():

	camera_posicao_inicial = camera.position

	camera.fov = 85.0


	RenderingServer.set_default_clear_color(
		Color(
			0.004,
			0.007,
			0.018
		)
	)


	cockpit_novo = procurar_cockpit_novo()


	if cockpit_novo != null:

		preparar_materiais_cockpit(
			cockpit_novo
		)

		criar_luzes_novo_cockpit()

		criar_telas_novo_cockpit()


	criar_estrelas()

	criar_asteroides()


# =========================================================
# LOOP PRINCIPAL
# =========================================================

func _process(delta):

	tempo += delta

	ler_controles(delta)

	atualizar_velocidade(delta)

	atualizar_voo(delta)

	atualizar_camera(delta)


	timer_telas += delta


	if timer_telas >= 0.05:

		timer_telas = 0.0

		atualizar_telas()


# =========================================================
# CONTROLES
# =========================================================

func ler_controles(delta):

	var esquerda := (
		Input.is_key_pressed(KEY_A)
		or
		Input.is_key_pressed(KEY_LEFT)
	)


	var direita := (
		Input.is_key_pressed(KEY_D)
		or
		Input.is_key_pressed(KEY_RIGHT)
	)


	var cima := (
		Input.is_key_pressed(KEY_W)
		or
		Input.is_key_pressed(KEY_UP)
	)


	var baixo := (
		Input.is_key_pressed(KEY_S)
		or
		Input.is_key_pressed(KEY_DOWN)
	)


	turbo = Input.is_key_pressed(KEY_SHIFT)


	var horizontal := 0.0
	var vertical := 0.0


	# =====================================================
	# LATERAL
	#
	# JA ESTAVA CORRETO.
	# NAO ALTERAMOS.
	# =====================================================

	if direita:
		horizontal += 1.0


	if esquerda:
		horizontal -= 1.0


	# =====================================================
	# VERTICAL - CORRIGIDO
	#
	# CIMA = SOBE
	# BAIXO = DESCE
	# =====================================================

	if cima:
		vertical -= 1.0


	if baixo:
		vertical += 1.0


	# =====================================================
	# SUAVIDADE / INERCIA
	# =====================================================

	target_x += (
		horizontal
		*
		control_speed
		*
		delta
	)


	target_y += (
		vertical
		*
		control_speed
		*
		delta
	)


	target_x *= pow(
		0.34,
		delta
	)


	target_y *= pow(
		0.34,
		delta
	)


	target_x = clamp(
		target_x,
		-1.0,
		1.0
	)


	target_y = clamp(
		target_y,
		-1.0,
		1.0
	)


	ship_x = lerpf(
		ship_x,
		target_x,
		min(
			1.0,
			delta * 5.5
		)
	)


	ship_y = lerpf(
		ship_y,
		target_y,
		min(
			1.0,
			delta * 5.5
		)
	)


# =========================================================
# VELOCIDADE
# =========================================================

func atualizar_velocidade(delta):

	var velocidade_desejada := velocidade_normal


	if turbo:

		velocidade_desejada = velocidade_turbo


	velocidade_atual = lerpf(
		velocidade_atual,
		velocidade_desejada,
		min(
			1.0,
			delta * 3.8
		)
	)


# =========================================================
# VOO
# =========================================================

func atualizar_voo(delta):

	rotate_y(
		-ship_x
		*
		turn_strength
		*
		delta
	)


	rotate_object_local(
		Vector3.RIGHT,
		-ship_y
		*
		turn_strength
		*
		delta
	)


	rotation.x = clamp(
		rotation.x,
		deg_to_rad(-75.0),
		deg_to_rad(75.0)
	)


	translate_object_local(
		Vector3(
			0.0,
			0.0,
			-velocidade_atual * delta
		)
	)


# =========================================================
# CAMERA
# =========================================================

func atualizar_camera(delta):

	var bank := (
		-ship_x
		*
		0.078
	)


	var pitch_visual := (
		ship_y
		*
		0.042
	)


	var bob := (
		sin(
			tempo * 1.7
		)
		*
		0.012
	)


	camera.position = (
		camera_posicao_inicial
		+
		Vector3(
			0.0,
			bob,
			0.0
		)
	)


	camera.rotation.x = pitch_visual

	camera.rotation.z = bank


	var fov_desejado := 85.0


	if turbo:

		fov_desejado = 94.0


	camera.fov = lerpf(
		camera.fov,
		fov_desejado,
		min(
			1.0,
			delta * 3.6
		)
	)


# =========================================================
# PROCURAR NOVO COCKPIT
# =========================================================

func procurar_cockpit_novo() -> Node:

	for filho in camera.get_children():

		var nome := str(
			filho.name
		).to_lower()


		if nome.contains(
			"spaceship_interior"
		):

			return filho


	return null


# =========================================================
# PREPARAR MATERIAIS
# =========================================================

func preparar_materiais_cockpit(
	no: Node
):

	if no is MeshInstance3D:

		var objeto := no as MeshInstance3D


		if objeto.mesh != null:

			var quantidade := (
				objeto.mesh.get_surface_count()
			)


			for superficie in range(
				quantidade
			):

				var material_original := (
					objeto.get_active_material(
						superficie
					)
				)


				if material_original == null:

					continue


				var nome_material := str(
					material_original.resource_name
				).to_lower()


				if nome_material == "spaceship":

					if material_original is StandardMaterial3D:

						var material_novo := (
							material_original.duplicate()
							as StandardMaterial3D
						)


						if material_novo != null:

							if material_novo.emission_enabled:

								material_novo.emission_energy_multiplier = 0.45


							objeto.set_surface_override_material(
								superficie,
								material_novo
							)


	for filho in no.get_children():

		preparar_materiais_cockpit(
			filho
		)


# =========================================================
# ILUMINACAO DO COCKPIT
# =========================================================

func criar_luzes_novo_cockpit():

	var luz_geral := DirectionalLight3D.new()

	luz_geral.name = "CockpitMainLight"


	luz_geral.light_color = Color(
		1.0,
		0.92,
		0.82
	)


	luz_geral.light_energy = 0.48

	luz_geral.shadow_enabled = false


	luz_geral.rotation_degrees = Vector3(
		-28.0,
		25.0,
		0.0
	)


	camera.add_child(
		luz_geral
	)


	var luz_cabine := OmniLight3D.new()

	luz_cabine.name = "CockpitFillLight"


	luz_cabine.position = Vector3(
		0.0,
		0.15,
		-0.25
	)


	luz_cabine.light_color = Color(
		0.78,
		0.88,
		1.0
	)


	luz_cabine.light_energy = 0.55

	luz_cabine.omni_range = 5.0

	luz_cabine.shadow_enabled = false


	camera.add_child(
		luz_cabine
	)


# =========================================================
# ENCONTRAR MESH PRINCIPAL
# =========================================================

func procurar_mesh_cockpit(
	no: Node
) -> MeshInstance3D:

	if no is MeshInstance3D:

		var objeto := no as MeshInstance3D


		if objeto.mesh != null:

			if objeto.mesh.get_surface_count() >= 5:

				return objeto


	for filho in no.get_children():

		var resultado := procurar_mesh_cockpit(
			filho
		)


		if resultado != null:

			return resultado


	return null


# =========================================================
# TELAS DO NOVO COCKPIT
# =========================================================

func criar_telas_novo_cockpit():

	if cockpit_novo == null:

		return


	var mesh_cockpit := procurar_mesh_cockpit(
		cockpit_novo
	)


	if mesh_cockpit == null:

		return


	var viewport_esquerdo := criar_tela_base(
		"NAV // RADAR",
		Color(
			0.0,
			0.90,
			1.0
		)
	)


	criar_radar(
		viewport_esquerdo
	)


	var viewport_central := criar_tela_base(
		"FLIGHT CORE",
		Color(
			0.0,
			0.85,
			1.0
		)
	)


	criar_velocimetro(
		viewport_central
	)


	var viewport_direito := criar_tela_base(
		"SHIP STATUS",
		Color(
			0.10,
			1.0,
			0.60
		)
	)


	criar_status_nave(
		viewport_direito
	)


	var quantidade := (
		mesh_cockpit.mesh.get_surface_count()
	)


	for superficie in range(
		quantidade
	):

		var material := (
			mesh_cockpit.get_active_material(
				superficie
			)
		)


		if material == null:

			continue


		var nome := str(
			material.resource_name
		).to_lower()


		if nome == "screen_1":

			aplicar_display_superficie(
				mesh_cockpit,
				superficie,
				viewport_central
			)


		elif nome == "screen_2":

			aplicar_display_superficie(
				mesh_cockpit,
				superficie,
				viewport_esquerdo
			)


		elif nome == "screen_3":

			aplicar_display_superficie(
				mesh_cockpit,
				superficie,
				viewport_direito
			)


# =========================================================
# TELA BASE
# =========================================================

func criar_tela_base(
	titulo: String,
	cor: Color
) -> SubViewport:

	var viewport := SubViewport.new()


	viewport.size = Vector2i(
		640,
		400
	)


	viewport.transparent_bg = false

	viewport.disable_3d = true


	viewport.render_target_update_mode = (
		SubViewport.UPDATE_ALWAYS
	)


	camera.add_child(
		viewport
	)


	var fundo := ColorRect.new()


	fundo.size = Vector2(
		640,
		400
	)


	fundo.color = Color(
		0.002,
		0.010,
		0.018
	)


	viewport.add_child(
		fundo
	)


	for y in range(
		80,
		360,
		45
	):

		var linha := ColorRect.new()


		linha.position = Vector2(
			15,
			y
		)


		linha.size = Vector2(
			610,
			1
		)


		linha.color = Color(
			cor.r,
			cor.g,
			cor.b,
			0.08
		)


		viewport.add_child(
			linha
		)


	var titulo_label := Label.new()


	titulo_label.text = titulo


	titulo_label.position = Vector2(
		20,
		15
	)


	titulo_label.size = Vector2(
		600,
		45
	)


	titulo_label.horizontal_alignment = (
		HORIZONTAL_ALIGNMENT_CENTER
	)


	titulo_label.add_theme_font_size_override(
		"font_size",
		28
	)


	titulo_label.add_theme_color_override(
		"font_color",
		cor
	)


	viewport.add_child(
		titulo_label
	)


	return viewport


# =========================================================
# RADAR
# =========================================================

func criar_radar(
	viewport: SubViewport
):

	var centro := Vector2(
		320,
		215
	)


	for raio in [
		55.0,
		100.0,
		145.0
	]:

		var circulo := Line2D.new()

		var pontos := PackedVector2Array()


		for i in range(49):

			var angulo := (
				TAU
				*
				float(i)
				/
				48.0
			)


			pontos.append(
				centro
				+
				Vector2(
					cos(angulo),
					sin(angulo)
				)
				*
				raio
			)


		circulo.points = pontos

		circulo.width = 2.0


		circulo.default_color = Color(
			0.0,
			0.85,
			1.0,
			0.35
		)


		viewport.add_child(
			circulo
		)


	radar_sweep = Line2D.new()


	radar_sweep.width = 4.0


	radar_sweep.default_color = Color(
		0.0,
		1.0,
		0.7,
		0.85
	)


	radar_sweep.points = PackedVector2Array(
		[
			centro,

			centro
			+
			Vector2(
				0,
				-140
			)
		]
	)


	viewport.add_child(
		radar_sweep
	)


	radar_blip_1 = criar_blip(
		viewport,
		Vector2(
			365,
			165
		)
	)


	radar_blip_2 = criar_blip(
		viewport,
		Vector2(
			255,
			255
		)
	)


	radar_blip_3 = criar_blip(
		viewport,
		Vector2(
			390,
			275
		)
	)


	radar_coordenadas = Label.new()


	radar_coordenadas.position = Vector2(
		15,
		355
	)


	radar_coordenadas.size = Vector2(
		610,
		35
	)


	radar_coordenadas.horizontal_alignment = (
		HORIZONTAL_ALIGNMENT_CENTER
	)


	radar_coordenadas.add_theme_font_size_override(
		"font_size",
		17
	)


	radar_coordenadas.add_theme_color_override(
		"font_color",
		Color(
			0.0,
			0.9,
			1.0
		)
	)


	viewport.add_child(
		radar_coordenadas
	)


# =========================================================
# BLIP
# =========================================================

func criar_blip(
	viewport: SubViewport,
	posicao: Vector2
) -> ColorRect:

	var blip := ColorRect.new()


	blip.position = posicao


	blip.size = Vector2(
		10,
		10
	)


	blip.color = Color(
		0.10,
		1.0,
		0.60
	)


	viewport.add_child(
		blip
	)


	return blip


# =========================================================
# VELOCIMETRO
# =========================================================

func criar_velocimetro(
	viewport: SubViewport
):

	velocidade_label = Label.new()


	velocidade_label.text = "022"


	velocidade_label.position = Vector2(
		20,
		75
	)


	velocidade_label.size = Vector2(
		600,
		155
	)


	velocidade_label.horizontal_alignment = (
		HORIZONTAL_ALIGNMENT_CENTER
	)


	velocidade_label.vertical_alignment = (
		VERTICAL_ALIGNMENT_CENTER
	)


	velocidade_label.add_theme_font_size_override(
		"font_size",
		82
	)


	velocidade_label.add_theme_color_override(
		"font_color",
		Color(
			0.75,
			0.95,
			1.0
		)
	)


	viewport.add_child(
		velocidade_label
	)


	barra_velocidade = ColorRect.new()


	barra_velocidade.position = Vector2(
		80,
		270
	)


	barra_velocidade.size = Vector2(
		210,
		20
	)


	barra_velocidade.color = Color(
		0.0,
		0.85,
		1.0
	)


	viewport.add_child(
		barra_velocidade
	)


	modo_voo_label = Label.new()


	modo_voo_label.text = "CRUISE // STABLE"


	modo_voo_label.position = Vector2(
		20,
		320
	)


	modo_voo_label.size = Vector2(
		600,
		45
	)


	modo_voo_label.horizontal_alignment = (
		HORIZONTAL_ALIGNMENT_CENTER
	)


	modo_voo_label.add_theme_font_size_override(
		"font_size",
		24
	)


	modo_voo_label.add_theme_color_override(
		"font_color",
		Color(
			0.0,
			0.9,
			1.0
		)
	)


	viewport.add_child(
		modo_voo_label
	)


# =========================================================
# STATUS
# =========================================================

func criar_status_nave(
	viewport: SubViewport
):

	hull_label = criar_label_status(
		viewport,
		"HULL 100%",
		Vector2(
			40,
			95
		)
	)


	barra_hull = criar_barra_status(
		viewport,
		Vector2(
			40,
			140
		),
		Color(
			0.10,
			1.0,
			0.60
		)
	)


	energia_label = criar_label_status(
		viewport,
		"ENERGY 100%",
		Vector2(
			40,
			195
		)
	)


	barra_energia = criar_barra_status(
		viewport,
		Vector2(
			40,
			240
		),
		Color(
			0.0,
			0.80,
			1.0
		)
	)


	engine_label = Label.new()


	engine_label.text = "ENGINE // ONLINE"


	engine_label.position = Vector2(
		20,
		310
	)


	engine_label.size = Vector2(
		600,
		45
	)


	engine_label.horizontal_alignment = (
		HORIZONTAL_ALIGNMENT_CENTER
	)


	engine_label.add_theme_font_size_override(
		"font_size",
		23
	)


	engine_label.add_theme_color_override(
		"font_color",
		Color(
			0.15,
			1.0,
			0.65
		)
	)


	viewport.add_child(
		engine_label
	)


# =========================================================
# LABEL STATUS
# =========================================================

func criar_label_status(
	viewport: SubViewport,
	texto: String,
	posicao: Vector2
) -> Label:

	var label := Label.new()


	label.text = texto

	label.position = posicao


	label.size = Vector2(
		560,
		40
	)


	label.add_theme_font_size_override(
		"font_size",
		24
	)


	label.add_theme_color_override(
		"font_color",
		Color(
			0.82,
			0.96,
			1.0
		)
	)


	viewport.add_child(
		label
	)


	return label


# =========================================================
# BARRA STATUS
# =========================================================

func criar_barra_status(
	viewport: SubViewport,
	posicao: Vector2,
	cor: Color
) -> ColorRect:

	var fundo := ColorRect.new()


	fundo.position = posicao


	fundo.size = Vector2(
		560,
		22
	)


	fundo.color = Color(
		0.02,
		0.08,
		0.12
	)


	viewport.add_child(
		fundo
	)


	var barra := ColorRect.new()


	barra.position = posicao


	barra.size = Vector2(
		560,
		22
	)


	barra.color = cor


	viewport.add_child(
		barra
	)


	return barra


# =========================================================
# APLICAR TELA
# =========================================================

func aplicar_display_superficie(
	objeto: MeshInstance3D,
	superficie: int,
	viewport: SubViewport
):

	var textura := viewport.get_texture()


	var material := StandardMaterial3D.new()


	material.albedo_texture = textura

	material.albedo_color = Color.WHITE


	material.emission_enabled = true

	material.emission = Color.WHITE

	material.emission_texture = textura

	material.emission_energy_multiplier = 1.6


	material.shading_mode = (
		BaseMaterial3D.SHADING_MODE_UNSHADED
	)


	material.cull_mode = (
		BaseMaterial3D.CULL_DISABLED
	)


	objeto.set_surface_override_material(
		superficie,
		material
	)


# =========================================================
# ATUALIZAR TELAS
# =========================================================

func atualizar_telas():

	if radar_sweep != null:

		var centro := Vector2(
			320,
			215
		)


		var angulo := tempo * 1.8


		var ponta := (
			centro
			+
			Vector2(
				cos(angulo),
				sin(angulo)
			)
			*
			140.0
		)


		radar_sweep.points = PackedVector2Array(
			[
				centro,
				ponta
			]
		)


	if radar_blip_1 != null:

		radar_blip_1.position = Vector2(
			365
			+
			sin(
				tempo * 0.7
			)
			*
			15,

			165
			+
			cos(
				tempo * 0.9
			)
			*
			10
		)


	if radar_blip_2 != null:

		radar_blip_2.position = Vector2(
			255
			+
			cos(
				tempo * 0.6
			)
			*
			20,

			255
			+
			sin(
				tempo * 0.8
			)
			*
			12
		)


	if radar_blip_3 != null:

		radar_blip_3.position = Vector2(
			390
			+
			sin(
				tempo * 0.5
			)
			*
			18,

			275
			+
			cos(
				tempo * 0.6
			)
			*
			15
		)


	if radar_coordenadas != null:

		radar_coordenadas.text = (
			"X %05d  Y %05d  Z %05d"
			%
			[
				int(global_position.x),
				int(global_position.y),
				int(global_position.z)
			]
		)


	if velocidade_label != null:

		velocidade_label.text = (
			"%03d"
			%
			int(
				round(
					velocidade_atual
				)
			)
		)


	if barra_velocidade != null:

		barra_velocidade.size.x = (
			480.0
			*
			clamp(
				velocidade_atual
				/
				velocidade_turbo,
				0.0,
				1.0
			)
		)


	if modo_voo_label != null:

		if turbo:

			modo_voo_label.text = (
				"TURBO // ENGAGED"
			)

		else:

			modo_voo_label.text = (
				"CRUISE // STABLE"
			)


	var energia := 100.0


	if turbo:

		energia = 82.0


	if energia_label != null:

		energia_label.text = (
			"ENERGY %03d%%"
			%
			int(energia)
		)


	if barra_energia != null:

		barra_energia.size.x = (
			560.0
			*
			energia
			/
			100.0
		)


	if engine_label != null:

		if turbo:

			engine_label.text = (
				"ENGINE // BOOST ACTIVE"
			)

		else:

			engine_label.text = (
				"ENGINE // ONLINE"
			)


# =========================================================
# ESTRELAS ANTIGAS
#
# O SPACEWORLD REMOVE ESSAS AUTOMATICAMENTE.
# MANTIDAS PARA NAO ALTERAR A BASE DO PLAYER.
# =========================================================

func criar_estrelas():

	var mesh_estrela := SphereMesh.new()


	mesh_estrela.radius = 0.035

	mesh_estrela.height = 0.07

	mesh_estrela.radial_segments = 4

	mesh_estrela.rings = 2


	var material := StandardMaterial3D.new()


	material.albedo_color = Color.WHITE


	material.emission_enabled = true

	material.emission = Color.WHITE

	material.emission_energy_multiplier = 4.0


	material.shading_mode = (
		BaseMaterial3D.SHADING_MODE_UNSHADED
	)


	mesh_estrela.material = material


	for i in range(400):

		var estrela := MeshInstance3D.new()


		estrela.mesh = mesh_estrela


		estrela.position = Vector3(

			randf_range(
				-120.0,
				120.0
			),

			randf_range(
				-70.0,
				70.0
			),

			randf_range(
				-500.0,
				-10.0
			)
		)


		get_parent().add_child.call_deferred(
			estrela
		)


# =========================================================
# ASTEROIDES ANTIGOS
#
# TAMBEM SAO REMOVIDOS PELO SPACEWORLD.
# =========================================================

func criar_asteroides():

	var material := StandardMaterial3D.new()


	material.albedo_color = Color(
		0.38,
		0.34,
		0.30
	)


	material.roughness = 1.0


	for i in range(35):

		var asteroide := MeshInstance3D.new()


		var mesh := SphereMesh.new()


		var tamanho := randf_range(
			0.8,
			2.5
		)


		mesh.radius = tamanho

		mesh.height = tamanho * 2.0

		mesh.radial_segments = 8

		mesh.rings = 4


		asteroide.mesh = mesh

		asteroide.material_override = material


		asteroide.scale = Vector3(

			randf_range(
				0.65,
				1.35
			),

			randf_range(
				0.65,
				1.35
			),

			randf_range(
				0.65,
				1.35
			)
		)


		asteroide.rotation = Vector3(

			randf_range(
				0.0,
				TAU
			),

			randf_range(
				0.0,
				TAU
			),

			randf_range(
				0.0,
				TAU
			)
		)


		asteroide.position = Vector3(

			randf_range(
				-60.0,
				60.0
			),

			randf_range(
				-35.0,
				35.0
			),

			randf_range(
				-450.0,
				-40.0
			)
		)


		get_parent().add_child.call_deferred(
			asteroide
		)
