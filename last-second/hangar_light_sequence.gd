
extends Node3D


# =========================================================
# LAST SECOND - HANGAR LIGHT SEQUENCE v1.0
# Luzes acendem da nave ate a porta
# lados superior esquerdo e direito
# =========================================================


@export var quantidade_pares: int = 12

@export var inicio_z: float = -7.0
@export var fim_z: float = -138.0

@export var posicao_x: float = 15.25
@export var altura_y: float = 5.8

@export var intervalo: float = 0.22
@export var duracao_acender: float = 0.30

@export var intensidade_painel: float = 6.0
@export var intensidade_luz: float = 1.7

@export var cor_luz: Color = Color(
	0.42,
	0.76,
	1.0,
	1.0
)


# =========================================================
# PAR DE LUZ
# =========================================================

class ParLuz:

	var material_esquerdo: StandardMaterial3D = null
	var material_direito: StandardMaterial3D = null

	var luz_esquerda: OmniLight3D = null
	var luz_direita: OmniLight3D = null


var pares: Array[ParLuz] = []


# =========================================================
# READY
# =========================================================

func _ready() -> void:

	criar_luzes()

	call_deferred(
		"iniciar_sequencia"
	)


# =========================================================
# CRIAR TODAS AS LUZES
# =========================================================

func criar_luzes() -> void:

	pares.clear()


	var quantidade: int = max(
		quantidade_pares,
		2
	)


	for i: int in range(
		quantidade
	):

		var t: float = (
			float(i)
			/
			float(
				quantidade - 1
			)
		)


		var z: float = lerpf(
			inicio_z,
			fim_z,
			t
		)


		var par: ParLuz = ParLuz.new()


		# =================================================
		# LADO ESQUERDO
		# =================================================

		par.material_esquerdo = criar_painel(
			Vector3(
				-posicao_x,
				altura_y,
				z
			),
			"LightLeft_%02d" % i
		)


		# =================================================
		# LADO DIREITO
		# =================================================

		par.material_direito = criar_painel(
			Vector3(
				posicao_x,
				altura_y,
				z
			),
			"LightRight_%02d" % i
		)


		# =================================================
		# LUZ REAL
		#
		# Nao colocamos OmniLight em todos os pares.
		# Isso deixa bem mais leve.
		# =================================================

		if i % 3 == 0:

			par.luz_esquerda = criar_luz_real(
				Vector3(
					-posicao_x * 0.88,
					altura_y - 0.4,
					z
				),
				"RealLightLeft_%02d" % i
			)


			par.luz_direita = criar_luz_real(
				Vector3(
					posicao_x * 0.88,
					altura_y - 0.4,
					z
				),
				"RealLightRight_%02d" % i
			)


		pares.append(
			par
		)


# =========================================================
# CRIAR PAINEL LUMINOSO
# =========================================================

func criar_painel(
	posicao: Vector3,
	nome: String
) -> StandardMaterial3D:

	var painel: MeshInstance3D = (
		MeshInstance3D.new()
	)


	painel.name = nome

	painel.position = posicao


	var mesh: BoxMesh = BoxMesh.new()


	# Painel vertical fino preso na parte
	# superior das laterais do hangar.
	mesh.size = Vector3(
		0.22,
		0.34,
		2.6
	)


	painel.mesh = mesh


	var material: StandardMaterial3D = (
		StandardMaterial3D.new()
	)


	# Inicialmente apagado.
	material.albedo_color = Color(
		0.018,
		0.025,
		0.035,
		1.0
	)


	material.metallic = 0.15

	material.roughness = 0.30


	material.emission_enabled = true

	material.emission = cor_luz

	material.emission_energy_multiplier = 0.0


	painel.material_override = material


	add_child(
		painel
	)


	return material


# =========================================================
# CRIAR LUZ REAL
# =========================================================

func criar_luz_real(
	posicao: Vector3,
	nome: String
) -> OmniLight3D:

	var luz: OmniLight3D = (
		OmniLight3D.new()
	)


	luz.name = nome

	luz.position = posicao


	luz.light_color = cor_luz

	luz.light_energy = 0.0


	luz.omni_range = 11.0

	luz.omni_attenuation = 1.35


	# Sem sombra por enquanto.
	# Isso deixa a sequencia bem mais leve.
	luz.shadow_enabled = false


	add_child(
		luz
	)


	return luz


# =========================================================
# SEQUENCIA DE ACENDIMENTO
# =========================================================

func iniciar_sequencia() -> void:

	# Pequena pausa depois que a cena aparece.
	await get_tree().create_timer(
		0.25
	).timeout


	for par: ParLuz in pares:

		acender_par(
			par
		)


		await get_tree().create_timer(
			intervalo
		).timeout


	print(
		"HANGAR: LUZES PRINCIPAIS ATIVADAS"
	)


# =========================================================
# ACENDER UM PAR
# =========================================================

func acender_par(
	par: ParLuz
) -> void:

	var tween: Tween = create_tween()


	tween.set_parallel(
		true
	)


	# =====================================================
	# PAINEL ESQUERDO
	# =====================================================

	if par.material_esquerdo != null:

		tween.tween_property(
			par.material_esquerdo,
			"emission_energy_multiplier",
			intensidade_painel,
			duracao_acender
		)


	# =====================================================
	# PAINEL DIREITO
	# =====================================================

	if par.material_direito != null:

		tween.tween_property(
			par.material_direito,
			"emission_energy_multiplier",
			intensidade_painel,
			duracao_acender
		)


	# =====================================================
	# LUZ REAL ESQUERDA
	# =====================================================

	if par.luz_esquerda != null:

		tween.tween_property(
			par.luz_esquerda,
			"light_energy",
			intensidade_luz,
			duracao_acender
		)


	# =====================================================
	# LUZ REAL DIREITA
	# =====================================================

	if par.luz_direita != null:

		tween.tween_property(
			par.luz_direita,
			"light_energy",
			intensidade_luz,
			duracao_acender
		)
