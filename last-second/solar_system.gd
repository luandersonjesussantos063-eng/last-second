extends Node3D


# =========================================================
# LAST SECOND - SOLAR SYSTEM v3.1
#
# - Mantem a Terra original
# - Sol procedural
# - Planetas detalhados
# - Atmosferas
# - Saturno / Urano com aneis
# - Asteroides
# - Estrelas distantes
# - NOME DOS PLANETAS
# - DISTANCIA DA NAVE EM TEMPO REAL
# =========================================================


@export var distancia_terra_sol: float = 3300.0

@export var quantidade_asteroides: int = 320

@export var quantidade_estrelas_distantes: int = 220

@export var seed_sistema: int = 945721


# 1 unidade do mundo = 1 km por enquanto
@export var unidades_por_km: float = 1.0


# Tamanho das etiquetas
@export var tamanho_texto_planeta: int = 42


var player: Node3D = null

var space_world: Node = null

var terra: MeshInstance3D = null

var raio_terra: float = 100.0

var posicao_sol: Vector3 = Vector3.ZERO


var rng: RandomNumberGenerator = (
	RandomNumberGenerator.new()
)


var objetos_rotacao: Array[Dictionary] = []

var etiquetas: Array[Dictionary] = []


# =========================================================
# READY
# =========================================================

func _ready() -> void:

	call_deferred(
		"construir_sistema"
	)


# =========================================================
# PROCESS
# =========================================================

func _process(delta: float) -> void:

	atualizar_rotacoes(
		delta
	)


	atualizar_etiquetas()


# =========================================================
# ROTACOES
# =========================================================

func atualizar_rotacoes(
	delta: float
) -> void:

	for item: Dictionary in objetos_rotacao:

		var objeto: Node3D = (
			item.get(
				"node"
			) as Node3D
		)


		if objeto == null:
			continue


		if !is_instance_valid(
			objeto
		):
			continue


		var velocidade: float = float(
			item.get(
				"speed",
				0.0
			)
		)


		objeto.rotate_y(
			velocidade * delta
		)


# =========================================================
# ATUALIZAR NOMES / DISTANCIAS
# =========================================================

func atualizar_etiquetas() -> void:

	if player == null:
		return


	for item: Dictionary in etiquetas:

		var alvo: Node3D = (
			item.get(
				"target"
			) as Node3D
		)


		var label: Label3D = (
			item.get(
				"label"
			) as Label3D
		)


		if alvo == null:
			continue


		if label == null:
			continue


		if !is_instance_valid(
			alvo
		):
			continue


		if !is_instance_valid(
			label
		):
			continue


		var nome: String = String(
			item.get(
				"name",
				"Planeta"
			)
		)


		var offset: float = float(
			item.get(
				"offset",
				100.0
			)
		)


		# =================================================
		# POSICAO DA ETIQUETA
		# =================================================

		label.global_position = (
			alvo.global_position
			+
			Vector3.UP
			*
			offset
		)


		# =================================================
		# DISTANCIA DA NAVE
		# =================================================

		var distancia_unidades: float = (
			player.global_position.distance_to(
				alvo.global_position
			)
		)


		var distancia_km: float = (
			distancia_unidades
			/
			maxf(
				unidades_por_km,
				0.001
			)
		)


		label.text = (
			nome.to_upper()
			+
			"\n"
			+
			formatar_distancia(
				distancia_km
			)
		)


# =========================================================
# FORMATAR DISTANCIA
# =========================================================

func formatar_distancia(
	distancia: float
) -> String:

	if distancia < 1000.0:

		return (
			"%.0f km"
			%
			distancia
		)


	if distancia < 1000000.0:

		return (
			"%.2f mil km"
			%
			(
				distancia
				/
				1000.0
			)
		)


	return (
		"%.2f mi km"
		%
		(
			distancia
			/
			1000000.0
		)
	)


# =========================================================
# CRIAR ETIQUETA
# =========================================================

func criar_etiqueta(
	nome: String,
	alvo: Node3D,
	offset: float
) -> void:

	if alvo == null:
		return


	var label: Label3D = Label3D.new()


	label.name = (
		"Label_" + nome
	)


	label.text = nome.to_upper()


	label.font_size = (
		tamanho_texto_planeta
	)


	label.outline_size = 10


	label.modulate = Color(
		0.90,
		0.96,
		1.0,
		1.0
	)


	label.billboard = (
		BaseMaterial3D.BILLBOARD_ENABLED
	)


	# Mantem tamanho legivel mesmo de longe.
	label.fixed_size = true


	label.no_depth_test = true


	label.pixel_size = 0.008


	add_child(
		label
	)


	etiquetas.append(
		{
			"name": nome,
			"target": alvo,
			"label": label,
			"offset": offset
		}
	)


# =========================================================
# CONSTRUIR SISTEMA
# =========================================================

func construir_sistema() -> void:

	await get_tree().process_frame


	player = get_node_or_null(
		"../Player"
	) as Node3D


	if player == null:

		push_warning(
			"SolarSystem: Player nao encontrado."
		)


	space_world = get_node_or_null(
		"../SpaceWorld"
	)


	if space_world == null:

		push_warning(
			"SolarSystem: SpaceWorld nao encontrado."
		)

		return


	terra = procurar_terra(
		space_world
	)


	if terra == null:

		push_warning(
			"SolarSystem: Terra nao encontrada."
		)

		return


	raio_terra = calcular_raio(
		terra
	)


	rng.seed = seed_sistema


	# =====================================================
	# CAMERA
	# =====================================================

	if player != null:

		var camera: Camera3D = procurar_camera(
			player
		)


		if camera != null:

			camera.far = maxf(
				camera.far,
				50000.0
			)


	# =====================================================
	# SOL
	# =====================================================

	posicao_sol = (
		terra.global_position
		-
		Vector3(
			distancia_terra_sol,
			0.0,
			0.0
		)
	)


	criar_sol()


	# =====================================================
	# MERCURIO
	# =====================================================

	criar_planeta_rochoso(
		"Mercurio",
		raio_terra * 0.38,
		1100.0,
		18.0,
		Color(
			0.43,
			0.40,
			0.37,
			1.0
		),
		Color(
			0.16,
			0.15,
			0.14,
			1.0
		),
		Color(
			0.68,
			0.58,
			0.47,
			1.0
		),
		Color(
			0.80,
			0.52,
			0.27,
			0.025
		),
		101
	)


	# =====================================================
	# VENUS
	# =====================================================

	criar_planeta_nublado(
		"Venus",
		raio_terra * 0.92,
		2150.0,
		62.0,
		Color(
			0.72,
			0.48,
			0.20,
			1.0
		),
		Color(
			0.95,
			0.79,
			0.46,
			1.0
		),
		Color(
			0.98,
			0.82,
			0.54,
			0.14
		),
		202
	)


	# =====================================================
	# TERRA EXISTENTE
	# =====================================================

	criar_etiqueta(
		"Terra",
		terra,
		raio_terra * 1.45
	)


	# =====================================================
	# MARTE
	# =====================================================

	criar_planeta_rochoso(
		"Marte",
		raio_terra * 0.53,
		4450.0,
		126.0,
		Color(
			0.61,
			0.19,
			0.075,
			1.0
		),
		Color(
			0.27,
			0.075,
			0.035,
			1.0
		),
		Color(
			0.82,
			0.35,
			0.16,
			1.0
		),
		Color(
			0.95,
			0.30,
			0.10,
			0.045
		),
		303
	)


	# =====================================================
	# ASTEROIDES
	# =====================================================

	criar_cinturao_asteroides()


	# =====================================================
	# JUPITER
	# =====================================================

	criar_gigante_gasoso(
		"Jupiter",
		raio_terra * 4.65,
		6500.0,
		168.0,
		Color(
			0.82,
			0.70,
			0.54,
			1.0
		),
		Color(
			0.48,
			0.27,
			0.16,
			1.0
		),
		Color(
			0.96,
			0.85,
			0.69,
			0.055
		),
		404,
		14.0
	)


	# =====================================================
	# SATURNO
	# =====================================================

	var saturno: Node3D = criar_gigante_gasoso(
		"Saturno",
		raio_terra * 3.95,
		8100.0,
		220.0,
		Color(
			0.78,
			0.70,
			0.49,
			1.0
		),
		Color(
			0.58,
			0.46,
			0.28,
			1.0
		),
		Color(
			0.96,
			0.88,
			0.68,
			0.045
		),
		505,
		18.0
	)


	if saturno != null:

		saturno.rotation_degrees.z = 18.0


		criar_sistema_aneis(
			saturno,
			raio_terra * 4.65,
			raio_terra * 7.15,
			Color(
				0.82,
				0.75,
				0.58,
				0.72
			)
		)


	# =====================================================
	# URANO
	# =====================================================

	var urano: Node3D = criar_planeta_nublado(
		"Urano",
		raio_terra * 1.82,
		9650.0,
		278.0,
		Color(
			0.30,
			0.66,
			0.72,
			1.0
		),
		Color(
			0.63,
			0.88,
			0.91,
			1.0
		),
		Color(
			0.50,
			0.92,
			0.98,
			0.07
		),
		606
	)


	if urano != null:

		urano.rotation_degrees.z = 79.0


		criar_sistema_aneis(
			urano,
			raio_terra * 2.15,
			raio_terra * 2.70,
			Color(
				0.58,
				0.78,
				0.80,
				0.28
			)
		)


	# =====================================================
	# NETUNO
	# =====================================================

	criar_planeta_nublado(
		"Netuno",
		raio_terra * 1.76,
		11150.0,
		332.0,
		Color(
			0.055,
			0.18,
			0.69,
			1.0
		),
		Color(
			0.15,
			0.39,
			0.91,
			1.0
		),
		Color(
			0.25,
			0.50,
			1.0,
			0.09
		),
		707
	)


	criar_estrelas_distantes()


	print(
		"===================================="
	)

	print(
		"SISTEMA SOLAR V3.1 PRONTO"
	)

	print(
		"NOMES E DISTANCIAS ATIVADOS"
	)

	print(
		"===================================="
	)


# =========================================================
# SOL
# =========================================================

func criar_sol() -> void:

	var root: Node3D = Node3D.new()


	root.name = "Sol"


	add_child(
		root
	)


	root.global_position = posicao_sol


	var raio: float = (
		raio_terra * 8.6
	)


	var superficie: MeshInstance3D = (
		MeshInstance3D.new()
	)


	superficie.name = "SunSurface"


	superficie.mesh = criar_esfera(
		raio,
		72,
		36
	)


	var material: StandardMaterial3D = (
		StandardMaterial3D.new()
	)


	material.shading_mode = (
		BaseMaterial3D.SHADING_MODE_UNSHADED
	)


	material.albedo_texture = (
		criar_textura_sol(
			384,
			192
		)
	)


	material.emission_enabled = true


	material.emission = Color(
		1.0,
		0.42,
		0.06,
		1.0
	)


	material.emission_energy_multiplier = 3.2


	superficie.material_override = material


	root.add_child(
		superficie
	)


	criar_halo_sol(
		root,
		raio * 2.35,
		Color(
			1.0,
			0.42,
			0.06,
			0.44
		)
	)


	criar_halo_sol(
		root,
		raio * 3.0,
		Color(
			1.0,
			0.25,
			0.025,
			0.18
		)
	)


	var luz: OmniLight3D = (
		OmniLight3D.new()
	)


	luz.name = "SunLight"


	luz.light_color = Color(
		1.0,
		0.83,
		0.66,
		1.0
	)


	luz.light_energy = 9.0

	luz.omni_range = 15000.0

	luz.omni_attenuation = 0.65

	luz.shadow_enabled = false


	root.add_child(
		luz
	)


	criar_etiqueta(
		"Sol",
		root,
		raio * 1.40
	)


	registrar_rotacao(
		superficie,
		0.035
	)


# =========================================================
# HALO DO SOL
# =========================================================

func criar_halo_sol(
	root: Node3D,
	tamanho: float,
	cor: Color
) -> void:

	var halo: MeshInstance3D = (
		MeshInstance3D.new()
	)


	var quad: QuadMesh = QuadMesh.new()


	quad.size = Vector2(
		tamanho,
		tamanho
	)


	halo.mesh = quad


	var material: StandardMaterial3D = (
		StandardMaterial3D.new()
	)


	material.shading_mode = (
		BaseMaterial3D.SHADING_MODE_UNSHADED
	)


	material.transparency = (
		BaseMaterial3D.TRANSPARENCY_ALPHA
	)


	material.billboard_mode = (
		BaseMaterial3D.BILLBOARD_ENABLED
	)


	material.cull_mode = (
		BaseMaterial3D.CULL_DISABLED
	)


	material.albedo_texture = (
		criar_textura_halo(
			256,
			cor
		)
	)


	halo.material_override = material


	root.add_child(
		halo
	)


# =========================================================
# PLANETA ROCHOSO
# =========================================================

func criar_planeta_rochoso(
	nome: String,
	raio: float,
	distancia: float,
	angulo: float,
	cor_base: Color,
	cor_escura: Color,
	cor_clara: Color,
	cor_atmosfera: Color,
	seed: int
) -> Node3D:

	var root: Node3D = criar_raiz_planeta(
		nome,
		distancia,
		angulo
	)


	var superficie: MeshInstance3D = (
		MeshInstance3D.new()
	)


	superficie.name = "Surface"


	superficie.mesh = criar_esfera(
		raio,
		52,
		26
	)


	var material: StandardMaterial3D = (
		StandardMaterial3D.new()
	)


	material.albedo_texture = (
		criar_textura_rochosa(
			256,
			128,
			cor_base,
			cor_escura,
			cor_clara,
			seed
		)
	)


	material.roughness = 0.94


	superficie.material_override = material


	root.add_child(
		superficie
	)


	if cor_atmosfera.a > 0.001:

		criar_atmosfera(
			root,
			raio * 1.035,
			cor_atmosfera
		)


	criar_etiqueta(
		nome,
		root,
		raio * 1.45
	)


	registrar_rotacao(
		superficie,
		0.045
	)


	return root


# =========================================================
# PLANETA NUBLADO
# =========================================================

func criar_planeta_nublado(
	nome: String,
	raio: float,
	distancia: float,
	angulo: float,
	cor_base: Color,
	cor_nuvem: Color,
	cor_atmosfera: Color,
	seed: int
) -> Node3D:

	var root: Node3D = criar_raiz_planeta(
		nome,
		distancia,
		angulo
	)


	var superficie: MeshInstance3D = (
		MeshInstance3D.new()
	)


	superficie.name = "Surface"


	superficie.mesh = criar_esfera(
		raio,
		52,
		26
	)


	var material: StandardMaterial3D = (
		StandardMaterial3D.new()
	)


	material.albedo_texture = (
		criar_textura_nublada(
			256,
			128,
			cor_base,
			cor_nuvem,
			seed
		)
	)


	material.roughness = 0.80


	superficie.material_override = material


	root.add_child(
		superficie
	)


	var nuvens: MeshInstance3D = (
		MeshInstance3D.new()
	)


	nuvens.name = "CloudLayer"


	nuvens.mesh = criar_esfera(
		raio * 1.018,
		42,
		20
	)


	var material_nuvem: StandardMaterial3D = (
		StandardMaterial3D.new()
	)


	material_nuvem.albedo_texture = (
		criar_textura_nuvens(
			256,
			128,
			cor_nuvem,
			seed + 50
		)
	)


	material_nuvem.transparency = (
		BaseMaterial3D.TRANSPARENCY_ALPHA
	)


	material_nuvem.cull_mode = (
		BaseMaterial3D.CULL_DISABLED
	)


	nuvens.material_override = (
		material_nuvem
	)


	root.add_child(
		nuvens
	)


	criar_atmosfera(
		root,
		raio * 1.045,
		cor_atmosfera
	)


	criar_etiqueta(
		nome,
		root,
		raio * 1.50
	)


	registrar_rotacao(
		superficie,
		0.035
	)


	registrar_rotacao(
		nuvens,
		0.055
	)


	return root


# =========================================================
# GIGANTE GASOSO
# =========================================================

func criar_gigante_gasoso(
	nome: String,
	raio: float,
	distancia: float,
	angulo: float,
	cor_base: Color,
	cor_faixas: Color,
	cor_atmosfera: Color,
	seed: int,
	quantidade_faixas: float
) -> Node3D:

	var root: Node3D = criar_raiz_planeta(
		nome,
		distancia,
		angulo
	)


	var superficie: MeshInstance3D = (
		MeshInstance3D.new()
	)


	superficie.name = "GasSurface"


	superficie.mesh = criar_esfera(
		raio,
		64,
		32
	)


	var material: StandardMaterial3D = (
		StandardMaterial3D.new()
	)


	material.albedo_texture = (
		criar_textura_gasosa(
			384,
			192,
			cor_base,
			cor_faixas,
			seed,
			quantidade_faixas
		)
	)


	material.roughness = 0.82


	superficie.material_override = material


	root.add_child(
		superficie
	)


	criar_atmosfera(
		root,
		raio * 1.025,
		cor_atmosfera
	)


	criar_etiqueta(
		nome,
		root,
		raio * 1.35
	)


	registrar_rotacao(
		superficie,
		0.030
	)


	return root


# =========================================================
# ATMOSFERA
# =========================================================

func criar_atmosfera(
	root: Node3D,
	raio: float,
	cor: Color
) -> void:

	var atmosfera: MeshInstance3D = (
		MeshInstance3D.new()
	)


	atmosfera.mesh = criar_esfera(
		raio,
		40,
		20
	)


	var material: StandardMaterial3D = (
		StandardMaterial3D.new()
	)


	material.albedo_color = cor


	material.transparency = (
		BaseMaterial3D.TRANSPARENCY_ALPHA
	)


	material.cull_mode = (
		BaseMaterial3D.CULL_DISABLED
	)


	material.emission_enabled = true


	material.emission = Color(
		cor.r,
		cor.g,
		cor.b,
		1.0
	)


	material.emission_energy_multiplier = 0.30


	atmosfera.material_override = material


	root.add_child(
		atmosfera
	)


# =========================================================
# ANEIS
# =========================================================

func criar_sistema_aneis(
	root: Node3D,
	raio_interno: float,
	raio_externo: float,
	cor: Color
) -> void:

	var largura: float = (
		raio_externo
		-
		raio_interno
	)


	for faixa: int in range(
		3
	):

		var inicio: float = (
			raio_interno
			+
			largura
			*
			float(faixa)
			/
			3.0
		)


		var fim: float = (
			raio_interno
			+
			largura
			*
			float(faixa + 1)
			/
			3.0
			-
			largura
			*
			0.025
		)


		criar_anel_plano(
			root,
			inicio,
			fim,
			Color(
				cor.r,
				cor.g,
				cor.b,
				cor.a
				*
				(
					0.85
					-
					float(faixa)
					*
					0.12
				)
			)
		)


# =========================================================
# ANEL PLANO
# =========================================================

func criar_anel_plano(
	root: Node3D,
	raio_interno: float,
	raio_externo: float,
	cor: Color
) -> void:

	var instancia: MeshInstance3D = (
		MeshInstance3D.new()
	)


	var surface: SurfaceTool = (
		SurfaceTool.new()
	)


	surface.begin(
		Mesh.PRIMITIVE_TRIANGLES
	)


	var segmentos: int = 128


	for i: int in range(
		segmentos
	):

		var a0: float = (
			TAU
			*
			float(i)
			/
			float(segmentos)
		)


		var a1: float = (
			TAU
			*
			float(i + 1)
			/
			float(segmentos)
		)


		var i0 := Vector3(
			cos(a0) * raio_interno,
			0.0,
			sin(a0) * raio_interno
		)


		var o0 := Vector3(
			cos(a0) * raio_externo,
			0.0,
			sin(a0) * raio_externo
		)


		var i1 := Vector3(
			cos(a1) * raio_interno,
			0.0,
			sin(a1) * raio_interno
		)


		var o1 := Vector3(
			cos(a1) * raio_externo,
			0.0,
			sin(a1) * raio_externo
		)


		adicionar_vertice_anel(
			surface,
			i0
		)

		adicionar_vertice_anel(
			surface,
			o0
		)

		adicionar_vertice_anel(
			surface,
			i1
		)


		adicionar_vertice_anel(
			surface,
			i1
		)

		adicionar_vertice_anel(
			surface,
			o0
		)

		adicionar_vertice_anel(
			surface,
			o1
		)


	instancia.mesh = surface.commit()


	var material: StandardMaterial3D = (
		StandardMaterial3D.new()
	)


	material.albedo_color = cor


	material.transparency = (
		BaseMaterial3D.TRANSPARENCY_ALPHA
	)


	material.cull_mode = (
		BaseMaterial3D.CULL_DISABLED
	)


	instancia.material_override = material


	root.add_child(
		instancia
	)


func adicionar_vertice_anel(
	surface: SurfaceTool,
	posicao: Vector3
) -> void:

	surface.set_normal(
		Vector3.UP
	)


	surface.add_vertex(
		posicao
	)


# =========================================================
# ASTEROIDES
# =========================================================

func criar_cinturao_asteroides() -> void:

	var multimesh: MultiMesh = MultiMesh.new()


	multimesh.transform_format = (
		MultiMesh.TRANSFORM_3D
	)


	var pedra: SphereMesh = SphereMesh.new()


	pedra.radius = 1.0

	pedra.height = 1.6

	pedra.radial_segments = 6

	pedra.rings = 4


	var material: StandardMaterial3D = (
		StandardMaterial3D.new()
	)


	material.albedo_color = Color(
		0.27,
		0.24,
		0.21,
		1.0
	)


	material.roughness = 1.0


	pedra.material = material


	multimesh.mesh = pedra


	multimesh.instance_count = (
		quantidade_asteroides
	)


	for i: int in range(
		quantidade_asteroides
	):

		var angulo: float = rng.randf_range(
			0.0,
			TAU
		)


		var distancia: float = rng.randf_range(
			5000.0,
			5700.0
		)


		var altura: float = rng.randf_range(
			-90.0,
			90.0
		)


		var global_pos: Vector3 = (
			posicao_sol
			+
			Vector3(
				cos(angulo)
				*
				distancia,
				altura,
				sin(angulo)
				*
				distancia
			)
		)


		var local_pos: Vector3 = (
			to_local(
				global_pos
			)
		)


		var tamanho: float = rng.randf_range(
			2.0,
			9.0
		)


		var basis: Basis = (
			Basis.IDENTITY.scaled(
				Vector3(
					tamanho,
					tamanho
					*
					rng.randf_range(
						0.5,
						1.3
					),
					tamanho
				)
			)
		)


		multimesh.set_instance_transform(
			i,
			Transform3D(
				basis,
				local_pos
			)
		)


	var instancia: MultiMeshInstance3D = (
		MultiMeshInstance3D.new()
	)


	instancia.multimesh = multimesh


	add_child(
		instancia
	)


# =========================================================
# ESTRELAS
# =========================================================

func criar_estrelas_distantes() -> void:

	var multimesh: MultiMesh = MultiMesh.new()


	multimesh.transform_format = (
		MultiMesh.TRANSFORM_3D
	)


	var estrela: SphereMesh = SphereMesh.new()


	estrela.radius = 1.0

	estrela.height = 2.0

	estrela.radial_segments = 8

	estrela.rings = 4


	var material: StandardMaterial3D = (
		StandardMaterial3D.new()
	)


	material.shading_mode = (
		BaseMaterial3D.SHADING_MODE_UNSHADED
	)


	material.emission_enabled = true


	material.emission = Color.WHITE

	material.emission_energy_multiplier = 5.0


	estrela.material = material


	multimesh.mesh = estrela


	multimesh.instance_count = (
		quantidade_estrelas_distantes
	)


	for i: int in range(
		quantidade_estrelas_distantes
	):

		var direcao := Vector3(
			rng.randf_range(
				-1.0,
				1.0
			),
			rng.randf_range(
				-0.75,
				0.75
			),
			rng.randf_range(
				-1.0,
				1.0
			)
		)


		if direcao.length() < 0.01:

			direcao = Vector3.FORWARD


		direcao = direcao.normalized()


		var distancia: float = rng.randf_range(
			18000.0,
			36000.0
		)


		var global_pos: Vector3 = (
			terra.global_position
			+
			direcao
			*
			distancia
		)


		var local_pos: Vector3 = (
			to_local(
				global_pos
			)
		)


		var escala: float = rng.randf_range(
			7.0,
			24.0
		)


		multimesh.set_instance_transform(
			i,
			Transform3D(
				Basis.IDENTITY.scaled(
					Vector3.ONE
					*
					escala
				),
				local_pos
			)
		)


	var instancia: MultiMeshInstance3D = (
		MultiMeshInstance3D.new()
	)


	instancia.multimesh = multimesh


	add_child(
		instancia
	)


# =========================================================
# TEXTURA SOL
# =========================================================

func criar_textura_sol(
	largura: int,
	altura: int
) -> ImageTexture:

	var imagem: Image = Image.create(
		largura,
		altura,
		false,
		Image.FORMAT_RGBA8
	)


	var ruido: FastNoiseLite = FastNoiseLite.new()


	ruido.seed = (
		seed_sistema + 900
	)


	ruido.noise_type = (
		FastNoiseLite.TYPE_SIMPLEX_SMOOTH
	)


	ruido.frequency = 0.035


	for y: int in range(
		altura
	):

		for x: int in range(
			largura
		):

			var n: float = (
				ruido.get_noise_2d(
					float(x),
					float(y)
				)
				+
				1.0
			) * 0.5


			var faixa: float = (
				sin(
					float(x)
					*
					0.16
					+
					n
					*
					8.0
				)
				+
				1.0
			) * 0.5


			var mistura: float = clampf(
				n
				*
				0.75
				+
				faixa
				*
				0.25,
				0.0,
				1.0
			)


			var escura := Color(
				1.0,
				0.23,
				0.015,
				1.0
			)


			var media := Color(
				1.0,
				0.62,
				0.07,
				1.0
			)


			var clara := Color(
				1.0,
				0.96,
				0.58,
				1.0
			)


			var cor: Color = escura.lerp(
				media,
				mistura
			)


			if mistura > 0.68:

				cor = cor.lerp(
					clara,
					(
						mistura
						-
						0.68
					)
					/
					0.32
				)


			imagem.set_pixel(
				x,
				y,
				cor
			)


	return ImageTexture.create_from_image(
		imagem
	)


# =========================================================
# HALO
# =========================================================

func criar_textura_halo(
	tamanho: int,
	cor: Color
) -> ImageTexture:

	var imagem: Image = Image.create(
		tamanho,
		tamanho,
		false,
		Image.FORMAT_RGBA8
	)


	var centro := Vector2(
		float(tamanho) * 0.5,
		float(tamanho) * 0.5
	)


	var raio: float = float(
		tamanho
	) * 0.5


	for y: int in range(
		tamanho
	):

		for x: int in range(
			tamanho
		):

			var distancia: float = (
				Vector2(
					float(x),
					float(y)
				).distance_to(
					centro
				)
				/
				raio
			)


			var alpha: float = (
				1.0
				-
				clampf(
					distancia,
					0.0,
					1.0
				)
			)


			alpha = pow(
				alpha,
				2.5
			)


			alpha *= cor.a


			imagem.set_pixel(
				x,
				y,
				Color(
					cor.r,
					cor.g,
					cor.b,
					alpha
				)
			)


	return ImageTexture.create_from_image(
		imagem
	)


# =========================================================
# TEXTURA ROCHOSA
# =========================================================

func criar_textura_rochosa(
	largura: int,
	altura: int,
	cor_base: Color,
	cor_escura: Color,
	cor_clara: Color,
	seed: int
) -> ImageTexture:

	var imagem := Image.create(
		largura,
		altura,
		false,
		Image.FORMAT_RGBA8
	)


	var ruido := FastNoiseLite.new()


	ruido.seed = (
		seed_sistema + seed
	)


	ruido.noise_type = (
		FastNoiseLite.TYPE_SIMPLEX_SMOOTH
	)


	ruido.frequency = 0.035


	for y in range(
		altura
	):

		for x in range(
			largura
		):

			var n: float = (
				ruido.get_noise_2d(
					float(x),
					float(y)
				)
				+
				1.0
			) * 0.5


			var cor := cor_escura.lerp(
				cor_base,
				n
			)


			if n > 0.67:

				cor = cor.lerp(
					cor_clara,
					(n - 0.67)
					/
					0.33
				)


			imagem.set_pixel(
				x,
				y,
				cor
			)


	return ImageTexture.create_from_image(
		imagem
	)


# =========================================================
# TEXTURA NUBLADA
# =========================================================

func criar_textura_nublada(
	largura: int,
	altura: int,
	cor_base: Color,
	cor_nuvem: Color,
	seed: int
) -> ImageTexture:

	var imagem := Image.create(
		largura,
		altura,
		false,
		Image.FORMAT_RGBA8
	)


	var ruido := FastNoiseLite.new()


	ruido.seed = (
		seed_sistema + seed
	)


	ruido.noise_type = (
		FastNoiseLite.TYPE_SIMPLEX_SMOOTH
	)


	ruido.frequency = 0.026


	for y in range(
		altura
	):

		for x in range(
			largura
		):

			var n: float = (
				ruido.get_noise_2d(
					float(x)
					+
					sin(
						float(y)
						*
						0.12
					)
					*
					12.0,
					float(y)
				)
				+
				1.0
			) * 0.5


			imagem.set_pixel(
				x,
				y,
				cor_base.lerp(
					cor_nuvem,
					n
				)
			)


	return ImageTexture.create_from_image(
		imagem
	)


# =========================================================
# NUVENS
# =========================================================

func criar_textura_nuvens(
	largura: int,
	altura: int,
	cor: Color,
	seed: int
) -> ImageTexture:

	var imagem := Image.create(
		largura,
		altura,
		false,
		Image.FORMAT_RGBA8
	)


	var ruido := FastNoiseLite.new()


	ruido.seed = (
		seed_sistema + seed
	)


	ruido.noise_type = (
		FastNoiseLite.TYPE_SIMPLEX_SMOOTH
	)


	ruido.frequency = 0.040


	for y in range(
		altura
	):

		for x in range(
			largura
		):

			var n: float = (
				ruido.get_noise_2d(
					float(x),
					float(y)
				)
				+
				1.0
			) * 0.5


			var alpha: float = clampf(
				(n - 0.42)
				/
				0.58,
				0.0,
				1.0
			)


			alpha *= 0.30


			imagem.set_pixel(
				x,
				y,
				Color(
					cor.r,
					cor.g,
					cor.b,
					alpha
				)
			)


	return ImageTexture.create_from_image(
		imagem
	)


# =========================================================
# TEXTURA GASOSA
# =========================================================

func criar_textura_gasosa(
	largura: int,
	altura: int,
	cor_base: Color,
	cor_faixa: Color,
	seed: int,
	faixas: float
) -> ImageTexture:

	var imagem := Image.create(
		largura,
		altura,
		false,
		Image.FORMAT_RGBA8
	)


	var ruido := FastNoiseLite.new()


	ruido.seed = (
		seed_sistema + seed
	)


	ruido.noise_type = (
		FastNoiseLite.TYPE_SIMPLEX_SMOOTH
	)


	ruido.frequency = 0.020


	for y in range(
		altura
	):

		var v: float = (
			float(y)
			/
			float(altura)
		)


		for x in range(
			largura
		):

			var n: float = ruido.get_noise_2d(
				float(x),
				float(y)
			)


			var faixa: float = (
				sin(
					v
					*
					TAU
					*
					faixas
					+
					n
					*
					2.8
				)
				+
				1.0
			) * 0.5


			imagem.set_pixel(
				x,
				y,
				cor_base.lerp(
					cor_faixa,
					faixa * 0.72
				)
			)


	return ImageTexture.create_from_image(
		imagem
	)


# =========================================================
# RAIZ PLANETA
# =========================================================

func criar_raiz_planeta(
	nome: String,
	distancia: float,
	angulo_graus: float
) -> Node3D:

	var root := Node3D.new()


	root.name = nome


	add_child(
		root
	)


	var angulo: float = deg_to_rad(
		angulo_graus
	)


	var x: float = (
		cos(angulo)
		*
		distancia
	)


	var z: float = (
		sin(angulo)
		*
		distancia
	)


	var y: float = (
		sin(
			angulo * 1.7
		)
		*
		distancia
		*
		0.012
	)


	root.global_position = (
		posicao_sol
		+
		Vector3(
			x,
			y,
			z
		)
	)


	return root


# =========================================================
# ESFERA
# =========================================================

func criar_esfera(
	raio: float,
	segmentos: int,
	aneis: int
) -> SphereMesh:

	var esfera := SphereMesh.new()


	esfera.radius = raio

	esfera.height = (
		raio * 2.0
	)

	esfera.radial_segments = segmentos

	esfera.rings = aneis


	return esfera


# =========================================================
# ROTACAO
# =========================================================

func registrar_rotacao(
	node: Node3D,
	velocidade: float
) -> void:

	objetos_rotacao.append(
		{
			"node": node,
			"speed": velocidade
		}
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
# TERRA
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


		if nome.contains("earth"):
			pontos += 180

		if nome.contains("terra"):
			pontos += 180

		if nome.contains("planet"):
			pontos += 120

		if nome.contains("ocean"):
			pontos += 45

		if candidato.mesh is SphereMesh:
			pontos += 25


		if nome.contains("moon"):
			pontos -= 500

		if nome.contains("lua"):
			pontos -= 500

		if nome.contains("cloud"):
			pontos -= 500

		if nome.contains("atmos"):
			pontos -= 500

		if nome.contains("asteroid"):
			pontos -= 500

		if nome.contains("star"):
			pontos -= 500


		if pontos > melhor_pontos:

			melhor_pontos = pontos

			melhor = candidato


	if melhor_pontos < 20:

		return null


	return melhor


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


# =========================================================
# RAIO
# =========================================================

func calcular_raio(
	mesh_planeta: MeshInstance3D
) -> float:

	var caixa: AABB = mesh_planeta.get_aabb()


	var tamanho: Vector3 = caixa.size


	var maior: float = maxf(
		tamanho.x,
		maxf(
			tamanho.y,
			tamanho.z
		)
	)


	var escala: Vector3 = (
		mesh_planeta.global_transform.basis.get_scale()
	)


	var maior_escala: float = maxf(
		absf(
			escala.x
		),
		maxf(
			absf(
				escala.y
			),
			absf(
				escala.z
			)
		)
	)


	return maxf(
		maior
		*
		0.5
		*
		maior_escala,
		1.0
	)
