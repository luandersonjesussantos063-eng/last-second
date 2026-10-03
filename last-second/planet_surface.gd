extends Node3D


# =========================================================
# LAST SECOND - PLANET SURFACE v6.0
#
# SEM TELEPORTAR A NAVE
# O MUNDO APARECE EMBAIXO DELA
# =========================================================


@export var altura_entrada_local: float = 450.0

@export var largura_mundo: float = 18000.0

@export var comprimento_frente: float = 24000.0
@export var comprimento_atras: float = 4000.0

@export var resolucao_x: int = 150
@export var resolucao_z: int = 220

@export var largura_rio: float = 140.0

@export var seed_mundo: int = 72841


# =========================================================
# REFERENCIAS
# =========================================================

var player: Node3D = null
var camera: Camera3D = null

var planeta: MeshInstance3D = null

var space_world: Node = null
var atmosphere_entry: Node = null
var launch_bay: Node3D = null


# =========================================================
# PLANETA
# =========================================================

var raio_planeta: float = 100.0

var normal_planeta: Vector3 = Vector3.UP


# =========================================================
# MUNDO LOCAL
# =========================================================

var nivel_agua: float = 3.5

var mundo_pronto: bool = false
var modo_local: bool = false


# =========================================================
# RUIDOS
# =========================================================

var ruido_planicie: FastNoiseLite = FastNoiseLite.new()
var ruido_colinas: FastNoiseLite = FastNoiseLite.new()
var ruido_montanhas: FastNoiseLite = FastNoiseLite.new()
var ruido_detalhe: FastNoiseLite = FastNoiseLite.new()
var ruido_rio: FastNoiseLite = FastNoiseLite.new()
var ruido_cor: FastNoiseLite = FastNoiseLite.new()


# =========================================================
# READY
# =========================================================

func _ready() -> void:

	visible = false

	call_deferred(
		"construir_mundo"
	)


# =========================================================
# CONSTRUIR
# =========================================================

func construir_mundo() -> void:

	await get_tree().process_frame


	player = get_node_or_null(
		"../Player"
	) as Node3D


	if player == null:

		push_warning(
			"PlanetSurface: Player nao encontrado."
		)

		return


	camera = procurar_camera(
		player
	)


	if camera != null:

		camera.far = 50000.0


	space_world = get_node_or_null(
		"../SpaceWorld"
	)


	atmosphere_entry = get_node_or_null(
		"../AtmosphereEntry"
	)


	launch_bay = get_node_or_null(
		"../LaunchBay"
	) as Node3D


	if space_world == null:

		push_warning(
			"PlanetSurface: SpaceWorld nao encontrado."
		)

		return


	planeta = procurar_planeta(
		space_world
	)


	if planeta == null:

		push_warning(
			"PlanetSurface: planeta nao encontrado."
		)

		return


	raio_planeta = calcular_raio(
		planeta
	)


	configurar_ruidos()


	criar_terreno()

	criar_rio()


	mundo_pronto = true


	print(
		"PLANET SURFACE V6 PRONTO"
	)


# =========================================================
# PROCESS
# =========================================================

func _process(_delta: float) -> void:

	if !mundo_pronto:
		return


	if player == null:
		return


	if planeta == null:
		return


	if modo_local:

		atualizar_atmosfera_local()

		return


	var distancia_centro: float = (
		player.global_position.distance_to(
			planeta.global_position
		)
	)


	var altitude_planeta: float = (
		distancia_centro
		-
		raio_planeta
	)


	var altura_transicao: float = (
		raio_planeta * 0.16
	)


	if altitude_planeta <= altura_transicao:

		entrar_mundo_local()


# =========================================================
# TRANSICAO
# =========================================================

func entrar_mundo_local() -> void:

	if modo_local:
		return


	modo_local = true


	print(
		"ENTRANDO NO MUNDO LOCAL"
	)


	# =====================================================
	# NORMAL EXATA DO PLANETA NO MOMENTO DA ENTRADA
	# =====================================================

	normal_planeta = (
		player.global_position
		-
		planeta.global_position
	).normalized()


	# =====================================================
	# DESCOBRIR PARA ONDE A NAVE ESTA INDO
	# =====================================================

	var frente: Vector3 = (
		-player.global_transform.basis.z
	).normalized()


	# Remove a componente vertical para descobrir
	# a direção sobre a superfície.
	var frente_horizontal: Vector3 = (
		frente
		-
		normal_planeta
		*
		frente.dot(
			normal_planeta
		)
	)


	if frente_horizontal.length() < 0.05:

		var referencia: Vector3 = Vector3.FORWARD


		if absf(
			normal_planeta.dot(
				referencia
			)
		) > 0.90:

			referencia = Vector3.RIGHT


		frente_horizontal = (
			referencia
			-
			normal_planeta
			*
			referencia.dot(
				normal_planeta
			)
		)


	frente_horizontal = (
		frente_horizontal.normalized()
	)


	# =====================================================
	# CRIAR OS EIXOS DO NOVO MUNDO
	#
	# Y = para cima
	# -Z = direção para onde a nave seguia
	# =====================================================

	var eixo_y: Vector3 = normal_planeta


	var eixo_z: Vector3 = (
		-frente_horizontal
	)


	var eixo_x: Vector3 = (
		frente_horizontal.cross(
			eixo_y
		)
	).normalized()


	eixo_z = (
		eixo_x.cross(
			eixo_y
		)
	)


	# =====================================================
	# O SEGREDO:
	#
	# NÃO MOVEMOS A NAVE.
	#
	# Colocamos o chão 450 unidades ABAIXO dela.
	# =====================================================

	var origem_chao: Vector3 = (
		player.global_position
		-
		normal_planeta
		*
		altura_entrada_local
	)


	var base: Basis = Basis(
		eixo_x,
		eixo_y,
		eixo_z
	)


	base = base.orthonormalized()


	global_transform = Transform3D(
		base,
		origem_chao
	)


	# =====================================================
	# MOSTRAR O MUNDO
	# =====================================================

	visible = true


	# =====================================================
	# PARAR O CONTROLADOR ANTIGO DA ATMOSFERA
	#
	# Daqui para frente este script controla a nevoa.
	# =====================================================

	if atmosphere_entry != null:

		atmosphere_entry.process_mode = (
			Node.PROCESS_MODE_DISABLED
		)


	# =====================================================
	# ESCONDER O PLANETA / ESPACO
	# =====================================================

	ocultar_visuais_espaco(
		space_world
	)


	if space_world != null:

		space_world.process_mode = (
			Node.PROCESS_MODE_DISABLED
		)


	# =====================================================
	# HANGAR NAO PRECISA MAIS EXISTIR VISUALMENTE
	# =====================================================

	if launch_bay != null:

		launch_bay.visible = false

		launch_bay.process_mode = (
			Node.PROCESS_MODE_DISABLED
		)


	print(
		"ALTURA INICIAL SOBRE O SOLO: ",
		altura_entrada_local
	)


# =========================================================
# ATMOSFERA LOCAL
# =========================================================

func atualizar_atmosfera_local() -> void:

	if camera == null:
		return


	if camera.environment == null:
		return


	var ambiente: Environment = (
		camera.environment
	)


	var posicao_local: Vector3 = (
		to_local(
			player.global_position
		)
	)


	var altitude: float = (
		posicao_local.y
	)


	# =====================================================
	# 450 m = ainda bem azul
	# 250 m = terreno já aparece
	# 100 m = visão bem mais limpa
	# =====================================================

	var clareza: float = inverse_lerp(
		altura_entrada_local,
		80.0,
		altitude
	)


	clareza = clampf(
		clareza,
		0.0,
		1.0
	)


	clareza = (
		clareza
		*
		clareza
		*
		(
			3.0
			-
			2.0
			*
			clareza
		)
	)


	ambiente.fog_enabled = true


	ambiente.fog_density = lerpf(
		0.0022,
		0.00012,
		clareza
	)


	ambiente.fog_light_color = Color(
		0.53,
		0.72,
		0.92,
		1.0
	)


	ambiente.fog_light_energy = lerpf(
		1.10,
		0.92,
		clareza
	)


	ambiente.fog_sky_affect = lerpf(
		0.80,
		0.18,
		clareza
	)


	ambiente.fog_sun_scatter = lerpf(
		0.32,
		0.08,
		clareza
	)


	ambiente.fog_aerial_perspective = lerpf(
		0.72,
		0.15,
		clareza
	)


# =========================================================
# CONFIGURAR RUIDOS
# =========================================================

func configurar_ruidos() -> void:

	ruido_planicie.seed = seed_mundo

	ruido_planicie.noise_type = (
		FastNoiseLite.TYPE_SIMPLEX_SMOOTH
	)

	ruido_planicie.frequency = 0.0009


	ruido_colinas.seed = (
		seed_mundo + 100
	)

	ruido_colinas.noise_type = (
		FastNoiseLite.TYPE_SIMPLEX_SMOOTH
	)

	ruido_colinas.frequency = 0.00040


	ruido_montanhas.seed = (
		seed_mundo + 200
	)

	ruido_montanhas.noise_type = (
		FastNoiseLite.TYPE_SIMPLEX_SMOOTH
	)

	ruido_montanhas.frequency = 0.00024


	ruido_detalhe.seed = (
		seed_mundo + 300
	)

	ruido_detalhe.noise_type = (
		FastNoiseLite.TYPE_SIMPLEX
	)

	ruido_detalhe.frequency = 0.005


	ruido_rio.seed = (
		seed_mundo + 400
	)

	ruido_rio.noise_type = (
		FastNoiseLite.TYPE_SIMPLEX_SMOOTH
	)

	ruido_rio.frequency = 0.00035


	ruido_cor.seed = (
		seed_mundo + 500
	)

	ruido_cor.noise_type = (
		FastNoiseLite.TYPE_SIMPLEX_SMOOTH
	)

	ruido_cor.frequency = 0.0009


# =========================================================
# SUAVIZAR
# =========================================================

func suavizar(
	valor: float
) -> float:

	var t: float = clampf(
		valor,
		0.0,
		1.0
	)


	return (
		t
		*
		t
		*
		(
			3.0
			-
			2.0 * t
		)
	)


# =========================================================
# DISTANCIA PARA FRENTE
# =========================================================

func distancia_frente(
	z: float
) -> float:

	return maxf(
		-z,
		0.0
	)


# =========================================================
# COLINAS
# =========================================================

func fator_colinas(
	z: float
) -> float:

	return suavizar(
		inverse_lerp(
			8000.0,
			13000.0,
			distancia_frente(
				z
			)
		)
	)


# =========================================================
# MONTANHAS
# =========================================================

func fator_montanhas(
	z: float
) -> float:

	return suavizar(
		inverse_lerp(
			16000.0,
			23000.0,
			distancia_frente(
				z
			)
		)
	)


# =========================================================
# RIO
# =========================================================

func centro_rio(
	z: float
) -> float:

	return (
		sin(
			z * 0.00085
		)
		*
		400.0
		+
		sin(
			z * 0.0024
		)
		*
		120.0
		+
		ruido_rio.get_noise_2d(
			z,
			200.0
		)
		*
		350.0
	)


# =========================================================
# ALTURA
# =========================================================

func altura_terreno(
	x: float,
	z: float
) -> float:

	var altura: float = (
		4.0
		+
		ruido_planicie.get_noise_2d(
			x,
			z
		)
		*
		5.0
	)


	# =====================================================
	# COLINAS DISTANTES
	# =====================================================

	var colina: float = (
		ruido_colinas.get_noise_2d(
			x,
			z
		)
		+
		1.0
	) * 0.5


	altura += (
		colina
		*
		90.0
		*
		fator_colinas(
			z
		)
	)


	# =====================================================
	# MONTANHAS MUITO DISTANTES
	# =====================================================

	var montanha: float = (
		ruido_montanhas.get_noise_2d(
			x,
			z
		)
	)


	var crista: float = (
		1.0
		-
		absf(
			montanha
		)
	)


	crista = pow(
		crista,
		3.0
	)


	altura += (
		crista
		*
		500.0
		*
		fator_montanhas(
			z
		)
	)


	# =====================================================
	# DETALHE
	# =====================================================

	altura += (
		ruido_detalhe.get_noise_2d(
			x,
			z
		)
		*
		3.0
	)


	# =====================================================
	# RIO
	# =====================================================

	var distancia_rio: float = absf(
		x
		-
		centro_rio(
			z
		)
	)


	var zona_rio: float = (
		largura_rio * 1.7
	)


	if distancia_rio < zona_rio:

		var influencia: float = (
			1.0
			-
			clampf(
				distancia_rio
				/
				zona_rio,
				0.0,
				1.0
			)
		)


		influencia = suavizar(
			influencia
		)


		altura = lerpf(
			altura,
			nivel_agua - 2.0,
			influencia * 0.95
		)


	return altura


# =========================================================
# TERRENO
# =========================================================

func criar_terreno() -> void:

	var terreno: MeshInstance3D = (
		MeshInstance3D.new()
	)


	terreno.name = "LocalWorldTerrain"


	var surface: SurfaceTool = (
		SurfaceTool.new()
	)


	surface.begin(
		Mesh.PRIMITIVE_TRIANGLES
	)


	var sx: int = maxi(
		resolucao_x,
		32
	)


	var sz: int = maxi(
		resolucao_z,
		32
	)


	var vx: int = (
		sx + 1
	)


	var total_z: float = (
		comprimento_frente
		+
		comprimento_atras
	)


	var passo_x: float = (
		largura_mundo
		/
		float(
			sx
		)
	)


	var passo_z: float = (
		total_z
		/
		float(
			sz
		)
	)


	# =====================================================
	# VERTICES
	# =====================================================

	for iz: int in range(
		sz + 1
	):

		var z: float = (
			-comprimento_frente
			+
			float(
				iz
			)
			*
			passo_z
		)


		for ix: int in range(
			sx + 1
		):

			var x: float = (
				-largura_mundo * 0.5
				+
				float(
					ix
				)
				*
				passo_x
			)


			var altura: float = altura_terreno(
				x,
				z
			)


			surface.set_color(
				cor_terreno(
					x,
					z
				)
			)


			surface.set_uv(
				Vector2(
					float(
						ix
					)
					/
					float(
						sx
					),
					float(
						iz
					)
					/
					float(
						sz
					)
				)
			)


			surface.add_vertex(
				Vector3(
					x,
					altura,
					z
				)
			)


	# =====================================================
	# TRIANGULOS
	# =====================================================

	for iz: int in range(
		sz
	):

		for ix: int in range(
			sx
		):

			var i00: int = (
				iz
				*
				vx
				+
				ix
			)


			var i10: int = (
				i00 + 1
			)


			var i01: int = (
				i00 + vx
			)


			var i11: int = (
				i01 + 1
			)


			surface.add_index(i00)
			surface.add_index(i01)
			surface.add_index(i10)

			surface.add_index(i10)
			surface.add_index(i01)
			surface.add_index(i11)


	surface.generate_normals()


	terreno.mesh = surface.commit()


	var material: StandardMaterial3D = (
		StandardMaterial3D.new()
	)


	material.vertex_color_use_as_albedo = true

	material.roughness = 0.98

	material.metallic = 0.0


	terreno.material_override = material


	add_child(
		terreno
	)


# =========================================================
# COR
# =========================================================

func cor_terreno(
	x: float,
	z: float
) -> Color:

	var distancia_rio: float = absf(
		x
		-
		centro_rio(
			z
		)
	)


	if distancia_rio < (
		largura_rio * 0.80
	):

		return Color(
			0.33,
			0.29,
			0.15
		)


	if distancia_rio < (
		largura_rio * 1.35
	):

		return Color(
			0.18,
			0.34,
			0.10
		)


	if fator_montanhas(
		z
	) > 0.60:

		return Color(
			0.29,
			0.30,
			0.27
		)


	var variacao: float = (
		ruido_cor.get_noise_2d(
			x,
			z
		)
	)


	if variacao > 0.25:

		return Color(
			0.045,
			0.23,
			0.065
		)


	if variacao < -0.25:

		return Color(
			0.19,
			0.39,
			0.11
		)


	return Color(
		0.09,
		0.32,
		0.08
	)


# =========================================================
# RIO
# =========================================================

func criar_rio() -> void:

	var rio: MeshInstance3D = (
		MeshInstance3D.new()
	)


	rio.name = "LocalRiver"


	var surface: SurfaceTool = (
		SurfaceTool.new()
	)


	surface.begin(
		Mesh.PRIMITIVE_TRIANGLES
	)


	var segmentos: int = 500


	for i: int in range(
		segmentos
	):

		var t0: float = (
			float(i)
			/
			float(
				segmentos
			)
		)


		var t1: float = (
			float(
				i + 1
			)
			/
			float(
				segmentos
			)
		)


		var z0: float = lerpf(
			-comprimento_frente,
			comprimento_atras,
			t0
		)


		var z1: float = lerpf(
			-comprimento_frente,
			comprimento_atras,
			t1
		)


		var x0: float = centro_rio(
			z0
		)


		var x1: float = centro_rio(
			z1
		)


		var metade: float = (
			largura_rio * 0.5
		)


		var e0 := Vector3(
			x0 - metade,
			nivel_agua,
			z0
		)


		var d0 := Vector3(
			x0 + metade,
			nivel_agua,
			z0
		)


		var e1 := Vector3(
			x1 - metade,
			nivel_agua,
			z1
		)


		var d1 := Vector3(
			x1 + metade,
			nivel_agua,
			z1
		)


		adicionar_agua(
			surface,
			e0
		)

		adicionar_agua(
			surface,
			e1
		)

		adicionar_agua(
			surface,
			d0
		)


		adicionar_agua(
			surface,
			d0
		)

		adicionar_agua(
			surface,
			e1
		)

		adicionar_agua(
			surface,
			d1
		)


	rio.mesh = surface.commit()


	var material: StandardMaterial3D = (
		StandardMaterial3D.new()
	)


	material.albedo_color = Color(
		0.018,
		0.18,
		0.32,
		0.88
	)


	material.transparency = (
		BaseMaterial3D.TRANSPARENCY_ALPHA
	)


	material.roughness = 0.12

	material.metallic = 0.08


	rio.material_override = material


	add_child(
		rio
	)


func adicionar_agua(
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
# ESCONDER VISUAIS DO ESPACO
# =========================================================

func ocultar_visuais_espaco(
	no_atual: Node
) -> void:

	if no_atual == null:
		return


	if no_atual is VisualInstance3D:

		(
			no_atual
			as VisualInstance3D
		).visible = false


	for filho: Node in no_atual.get_children():

		ocultar_visuais_espaco(
			filho
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
# PLANETA
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
# RAIO
# =========================================================

func calcular_raio(
	mesh_planeta: MeshInstance3D
) -> float:

	var caixa: AABB = (
		mesh_planeta.get_aabb()
	)


	var tamanho: Vector3 = (
		caixa.size
	)


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
