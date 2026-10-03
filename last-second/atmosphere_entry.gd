extends Node


# =========================================================
# LAST SECOND - ATMOSPHERE ENTRY v2.0
# Atmosfera somente perto do planeta
# =========================================================


# A nave precisa se afastar pelo menos isso do hangar
# antes da atmosfera poder começar.
@export var distancia_minima_do_hangar: float = 200.0

# Atmosfera começa quando estivermos a aproximadamente
# 70% do raio do planeta acima da superfície.
@export var inicio_atmosfera: float = 0.70

# Atmosfera fica forte bem perto da superfície.
@export var atmosfera_forte: float = 0.10

@export var densidade_maxima: float = 0.012


var player: Node3D = null
var camera: Camera3D = null
var planeta: MeshInstance3D = null

var ambiente: Environment = null

var raio_planeta: float = 1.0

var posicao_inicial: Vector3 = Vector3.ZERO

var intensidade: float = 0.0

var dentro_atmosfera: bool = false


# =========================================================
# READY
# =========================================================

func _ready() -> void:

	call_deferred(
		"configurar"
	)


# =========================================================
# CONFIGURAR
# =========================================================

func configurar() -> void:

	await get_tree().process_frame


	player = get_node_or_null(
		"../Player"
	) as Node3D


	if player == null:

		push_warning(
			"AtmosphereEntry: Player nao encontrado."
		)

		return


	posicao_inicial = player.global_position


	camera = procurar_camera(
		player
	)


	if camera == null:

		push_warning(
			"AtmosphereEntry: Camera nao encontrada."
		)

		return


	var space_world: Node = get_node_or_null(
		"../SpaceWorld"
	)


	if space_world == null:

		push_warning(
			"AtmosphereEntry: SpaceWorld nao encontrado."
		)

		return


	planeta = procurar_planeta(
		space_world
	)


	if planeta == null:

		push_warning(
			"AtmosphereEntry: planeta nao encontrado."
		)

		return


	raio_planeta = calcular_raio(
		planeta
	)


	criar_ambiente()


	# =====================================================
	# IMPORTANTE:
	# SEM NEBLINA AO COMEÇAR O JOGO
	# =====================================================

	ambiente.fog_enabled = false

	ambiente.fog_density = 0.0


	print(
		"ATMOSFERA V2 PRONTA"
	)

	print(
		"Planeta: ",
		planeta.name
	)

	print(
		"Raio aproximado: ",
		raio_planeta
	)


# =========================================================
# PROCESS
# =========================================================

func _process(delta: float) -> void:

	if player == null:
		return

	if planeta == null:
		return

	if ambiente == null:
		return


	# =====================================================
	# DISTANCIA PERCORRIDA DESDE O HANGAR
	# =====================================================

	var distancia_hangar: float = (
		player.global_position.distance_to(
			posicao_inicial
		)
	)


	# =====================================================
	# ENQUANTO ESTIVER PERTO DO HANGAR:
	# ZERO NEBLINA
	# =====================================================

	if distancia_hangar < distancia_minima_do_hangar:

		intensidade = lerpf(
			intensidade,
			0.0,
			clampf(
				delta * 4.0,
				0.0,
				1.0
			)
		)


		aplicar_atmosfera(
			intensidade
		)

		return


	# =====================================================
	# DISTANCIA ATE O PLANETA
	# =====================================================

	var distancia_centro: float = (
		player.global_position.distance_to(
			planeta.global_position
		)
	)


	var altitude: float = (
		distancia_centro
		-
		raio_planeta
	)


	var altitude_inicio: float = (
		raio_planeta
		*
		inicio_atmosfera
	)


	var altitude_forte: float = (
		raio_planeta
		*
		atmosfera_forte
	)


	var alvo: float = 0.0


	# =====================================================
	# SO COMEÇA QUANDO REALMENTE CHEGAR PERTO
	# =====================================================

	if altitude < altitude_inicio:

		alvo = inverse_lerp(
			altitude_inicio,
			altitude_forte,
			altitude
		)


	alvo = clampf(
		alvo,
		0.0,
		1.0
	)


	intensidade = lerpf(
		intensidade,
		alvo,
		clampf(
			delta * 2.0,
			0.0,
			1.0
		)
	)


	aplicar_atmosfera(
		intensidade
	)


# =========================================================
# APLICAR ATMOSFERA
# =========================================================

func aplicar_atmosfera(
	forca: float
) -> void:

	var suave: float = (
		forca
		*
		forca
		*
		(
			3.0
			-
			2.0 * forca
		)
	)


	# =====================================================
	# FORA DA ATMOSFERA
	# =====================================================

	if suave < 0.01:

		ambiente.fog_enabled = false

		ambiente.fog_density = 0.0


		if dentro_atmosfera:

			dentro_atmosfera = false

			print(
				"ATMOSFERA: ESPACO"
			)


		return


	# =====================================================
	# DENTRO DA ATMOSFERA
	# =====================================================

	ambiente.fog_enabled = true


	ambiente.fog_density = lerpf(
		0.0,
		densidade_maxima,
		suave
	)


	ambiente.fog_light_color = Color(
		0.52,
		0.72,
		0.94,
		1.0
	)


	ambiente.fog_light_energy = lerpf(
		0.8,
		1.15,
		suave
	)


	ambiente.fog_sky_affect = lerpf(
		0.1,
		0.85,
		suave
	)


	ambiente.fog_sun_scatter = lerpf(
		0.0,
		0.35,
		suave
	)


	ambiente.fog_aerial_perspective = lerpf(
		0.0,
		0.80,
		suave
	)


	if !dentro_atmosfera:

		dentro_atmosfera = true

		print(
			"ATMOSFERA: ENTRADA INICIADA"
		)


# =========================================================
# CRIAR AMBIENTE DA CAMERA
# =========================================================

func criar_ambiente() -> void:

	var origem: Environment = null


	if camera.environment != null:

		origem = camera.environment


	else:

		var world_env: WorldEnvironment = (
			procurar_world_environment(
				get_tree().current_scene
			)
		)


		if (
			world_env != null
			and
			world_env.environment != null
		):

			origem = world_env.environment


	if origem != null:

		ambiente = (
			origem.duplicate(
				true
			)
			as Environment
		)

	else:

		ambiente = Environment.new()


	camera.environment = ambiente


# =========================================================
# PROCURAR CAMERA
# =========================================================

func procurar_camera(
	no_atual: Node
) -> Camera3D:

	if no_atual is Camera3D:

		return no_atual as Camera3D


	for filho: Node in no_atual.get_children():

		var resultado: Camera3D = (
			procurar_camera(
				filho
			)
		)


		if resultado != null:

			return resultado


	return null


# =========================================================
# PROCURAR PLANETA
# =========================================================

func procurar_planeta(
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


		if nome.contains("planet"):
			pontos += 100

		if nome.contains("terra"):
			pontos += 100

		if nome.contains("earth"):
			pontos += 100

		if nome.contains("ocean"):
			pontos += 50


		if candidato.mesh is SphereMesh:
			pontos += 20


		if nome.contains("moon"):
			pontos -= 300

		if nome.contains("lua"):
			pontos -= 300

		if nome.contains("cloud"):
			pontos -= 300

		if nome.contains("atmos"):
			pontos -= 300

		if nome.contains("asteroid"):
			pontos -= 300

		if nome.contains("star"):
			pontos -= 300


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


# =========================================================
# RAIO DO PLANETA
# =========================================================

func calcular_raio(
	mesh_planeta: MeshInstance3D
) -> float:

	var caixa: AABB = (
		mesh_planeta.get_aabb()
	)


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


# =========================================================
# PROCURAR WORLD ENVIRONMENT
# =========================================================

func procurar_world_environment(
	no_atual: Node
) -> WorldEnvironment:

	if no_atual is WorldEnvironment:

		return no_atual as WorldEnvironment


	for filho: Node in no_atual.get_children():

		var resultado: WorldEnvironment = (
			procurar_world_environment(
				filho
			)
		)


		if resultado != null:

			return resultado


	return null
