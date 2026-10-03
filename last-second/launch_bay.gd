extends Node3D


# =========================================================
# LAST SECOND - LAUNCH BAY v1.1
# =========================================================
#
# NOVO:
# - porta fechada no inicio
# - duas folhas da porta
# - abertura automatica no LAUNCH
# - luzes vermelhas de alerta
# - sincronizacao automatica com ShipSystems
#
# NAO PRECISA ALTERAR:
# - player.gd
# - ship_systems.gd
# - space_world.gd
# - cockpit_fx.gd
#
# =========================================================


@export var comprimento: float = 170.0
@export var largura: float = 32.0
@export var altura: float = 14.0


# =========================================================
# MATERIAIS
# =========================================================

var material_metal: StandardMaterial3D
var material_metal_escuro: StandardMaterial3D
var material_piso: StandardMaterial3D

var material_luz_azul: StandardMaterial3D
var material_luz_vermelha: StandardMaterial3D
var material_luz_branca: StandardMaterial3D


# =========================================================
# SISTEMAS
# =========================================================

var ship_systems: Node = null


# No ShipSystems atual:
#
# 0 POWER_OFF
# 1 POWER_ON
# 2 ENGINE_STARTING
# 3 ENGINE_READY
# 4 LAUNCHING
# 5 FLIGHT

const ESTADO_LAUNCHING: int = 4
const ESTADO_FLIGHT: int = 5


var estado_anterior: int = -1


# =========================================================
# PORTA
# =========================================================

var porta_esquerda: MeshInstance3D = null
var porta_direita: MeshInstance3D = null

var porta_abrindo: bool = false
var porta_aberta: bool = false


var posicao_porta_esquerda_fechada := Vector3(
	-7.0,
	1.0,
	-147.7
)


var posicao_porta_direita_fechada := Vector3(
	7.0,
	1.0,
	-147.7
)


var posicao_porta_esquerda_aberta := Vector3(
	-25.0,
	1.0,
	-147.7
)


var posicao_porta_direita_aberta := Vector3(
	25.0,
	1.0,
	-147.7
)


# =========================================================
# ALERTA
# =========================================================

var alerta_ativo: bool = false

var luzes_alerta: Array[OmniLight3D] = []

var tempo: float = 0.0


# =========================================================
# INICIO
# =========================================================

func _ready():

	criar_materiais()

	criar_piso()

	criar_paredes()

	criar_teto()

	criar_estrutura()

	criar_plataforma_inicial()

	criar_luzes_pista()

	criar_luzes_teto()

	criar_portal_saida()

	criar_porta_hangar()

	criar_detalhes_laterais()

	criar_parede_traseira()

	criar_luzes_alerta()


	ship_systems = get_node_or_null(
		"../ShipSystems"
	)


# =========================================================
# LOOP
# =========================================================

func _process(delta: float):

	tempo += delta


	atualizar_luzes()

	atualizar_ship_systems()


# =========================================================
# MONITORAR SHIP SYSTEMS
# =========================================================

func atualizar_ship_systems():

	if ship_systems == null:

		ship_systems = get_node_or_null(
			"../ShipSystems"
		)


		if ship_systems == null:
			return


	var valor_estado: Variant = (
		ship_systems.get(
			"estado"
		)
	)


	if valor_estado == null:
		return


	var estado_atual: int = int(
		valor_estado
	)


	if estado_atual == estado_anterior:
		return


	estado_anterior = estado_atual


	# =====================================================
	# LAUNCH FOI PRESSIONADO
	# =====================================================

	if estado_atual == ESTADO_LAUNCHING:

		ativar_alerta_lancamento()

		iniciar_abertura_porta()


	# =====================================================
	# NAVE FOI LIBERADA
	# =====================================================

	elif estado_atual == ESTADO_FLIGHT:

		finalizar_alerta_lancamento()


# =========================================================
# MATERIAIS
# =========================================================

func criar_materiais():

	# =====================================================
	# METAL PRINCIPAL
	# =====================================================

	material_metal = StandardMaterial3D.new()


	material_metal.albedo_color = Color(
		0.10,
		0.12,
		0.15
	)


	material_metal.metallic = 0.75

	material_metal.roughness = 0.38


	# =====================================================
	# METAL ESCURO
	# =====================================================

	material_metal_escuro = StandardMaterial3D.new()


	material_metal_escuro.albedo_color = Color(
		0.025,
		0.035,
		0.050
	)


	material_metal_escuro.metallic = 0.82

	material_metal_escuro.roughness = 0.30


	# =====================================================
	# PISO
	# =====================================================

	material_piso = StandardMaterial3D.new()


	material_piso.albedo_color = Color(
		0.055,
		0.060,
		0.070
	)


	material_piso.metallic = 0.55

	material_piso.roughness = 0.55


	# =====================================================
	# LUZ AZUL
	# =====================================================

	material_luz_azul = StandardMaterial3D.new()


	material_luz_azul.albedo_color = Color(
		0.05,
		0.55,
		1.0
	)


	material_luz_azul.emission_enabled = true


	material_luz_azul.emission = Color(
		0.04,
		0.55,
		1.0
	)


	material_luz_azul.emission_energy_multiplier = 3.0


	material_luz_azul.shading_mode = (
		BaseMaterial3D.SHADING_MODE_UNSHADED
	)


	# =====================================================
	# LUZ VERMELHA
	# =====================================================

	material_luz_vermelha = StandardMaterial3D.new()


	material_luz_vermelha.albedo_color = Color(
		1.0,
		0.08,
		0.03
	)


	material_luz_vermelha.emission_enabled = true


	material_luz_vermelha.emission = Color(
		1.0,
		0.04,
		0.01
	)


	material_luz_vermelha.emission_energy_multiplier = 0.5


	material_luz_vermelha.shading_mode = (
		BaseMaterial3D.SHADING_MODE_UNSHADED
	)


	# =====================================================
	# LUZ BRANCA
	# =====================================================

	material_luz_branca = StandardMaterial3D.new()


	material_luz_branca.albedo_color = Color(
		0.72,
		0.90,
		1.0
	)


	material_luz_branca.emission_enabled = true


	material_luz_branca.emission = Color(
		0.55,
		0.82,
		1.0
	)


	material_luz_branca.emission_energy_multiplier = 2.6


	material_luz_branca.shading_mode = (
		BaseMaterial3D.SHADING_MODE_UNSHADED
	)


# =========================================================
# CRIAR CAIXA
# =========================================================

func criar_caixa(
	nome: String,
	posicao: Vector3,
	tamanho: Vector3,
	material: Material
) -> MeshInstance3D:

	var objeto := MeshInstance3D.new()


	objeto.name = nome


	var caixa := BoxMesh.new()


	caixa.size = tamanho


	objeto.mesh = caixa

	objeto.position = posicao

	objeto.material_override = material


	add_child(
		objeto
	)


	return objeto


# =========================================================
# PISO
# =========================================================

func criar_piso():

	var centro_z: float = (
		20.0
		-
		comprimento * 0.5
	)


	criar_caixa(
		"MainFloor",

		Vector3(
			0.0,
			-5.0,
			centro_z
		),

		Vector3(
			largura,
			1.0,
			comprimento
		),

		material_piso
	)


	criar_caixa(
		"FloorGuideLeft",

		Vector3(
			-3.6,
			-4.44,
			centro_z
		),

		Vector3(
			0.16,
			0.05,
			comprimento - 6.0
		),

		material_luz_azul
	)


	criar_caixa(
		"FloorGuideRight",

		Vector3(
			3.6,
			-4.44,
			centro_z
		),

		Vector3(
			0.16,
			0.05,
			comprimento - 6.0
		),

		material_luz_azul
	)


# =========================================================
# PAREDES
# =========================================================

func criar_paredes():

	var centro_z: float = (
		20.0
		-
		comprimento * 0.5
	)


	criar_caixa(
		"WallLeft",

		Vector3(
			-largura * 0.5,
			1.0,
			centro_z
		),

		Vector3(
			1.0,
			altura,
			comprimento
		),

		material_metal_escuro
	)


	criar_caixa(
		"WallRight",

		Vector3(
			largura * 0.5,
			1.0,
			centro_z
		),

		Vector3(
			1.0,
			altura,
			comprimento
		),

		material_metal_escuro
	)


# =========================================================
# TETO
# =========================================================

func criar_teto():

	var centro_z: float = (
		20.0
		-
		comprimento * 0.5
	)


	criar_caixa(
		"Ceiling",

		Vector3(
			0.0,
			8.0,
			centro_z
		),

		Vector3(
			largura,
			0.65,
			comprimento
		),

		material_metal_escuro
	)


# =========================================================
# ARCOS E ESTRUTURA
# =========================================================

func criar_estrutura():

	var z: float = 15.0

	var numero: int = 0


	while z > -145.0:

		criar_caixa(
			"FrameLeft_%02d" % numero,

			Vector3(
				-14.8,
				1.0,
				z
			),

			Vector3(
				1.5,
				13.0,
				1.3
			),

			material_metal
		)


		criar_caixa(
			"FrameRight_%02d" % numero,

			Vector3(
				14.8,
				1.0,
				z
			),

			Vector3(
				1.5,
				13.0,
				1.3
			),

			material_metal
		)


		criar_caixa(
			"FrameTop_%02d" % numero,

			Vector3(
				0.0,
				7.1,
				z
			),

			Vector3(
				30.8,
				1.1,
				1.3
			),

			material_metal
		)


		z -= 15.0

		numero += 1


# =========================================================
# PLATAFORMA INICIAL
# =========================================================

func criar_plataforma_inicial():

	criar_caixa(
		"LaunchPlatform",

		Vector3(
			0.0,
			-4.25,
			2.0
		),

		Vector3(
			13.0,
			0.40,
			20.0
		),

		material_metal
	)


	criar_caixa(
		"PlatformCenter",

		Vector3(
			0.0,
			-4.01,
			2.0
		),

		Vector3(
			3.0,
			0.05,
			17.0
		),

		material_metal_escuro
	)


	for lado in [
		-1.0,
		1.0
	]:

		criar_caixa(
			"PlatformGlow",

			Vector3(
				lado * 6.0,
				-4.0,
				2.0
			),

			Vector3(
				0.18,
				0.08,
				18.0
			),

			material_luz_azul
		)


# =========================================================
# LUZES DE PISTA
# =========================================================

func criar_luzes_pista():

	var z: float = 10.0

	var numero: int = 0


	while z > -145.0:

		for lado in [
			-1.0,
			1.0
		]:

			criar_caixa(
				"RunwayLight_%02d" % numero,

				Vector3(
					lado * 10.5,
					-4.38,
					z
				),

				Vector3(
					0.32,
					0.08,
					1.5
				),

				material_luz_branca
			)


		z -= 8.0

		numero += 1


# =========================================================
# LUZES DE TETO
# =========================================================

func criar_luzes_teto():

	var z: float = 8.0

	var numero: int = 0


	while z > -142.0:

		criar_caixa(
			"CeilingLight_%02d" % numero,

			Vector3(
				0.0,
				7.62,
				z
			),

			Vector3(
				8.0,
				0.08,
				0.40
			),

			material_luz_branca
		)


		z -= 12.0

		numero += 1


# =========================================================
# PORTAL DE SAIDA
# =========================================================

func criar_portal_saida():

	var z_saida: float = -148.0


	criar_caixa(
		"ExitGateLeft",

		Vector3(
			-14.5,
			1.0,
			z_saida
		),

		Vector3(
			2.5,
			14.0,
			3.0
		),

		material_metal
	)


	criar_caixa(
		"ExitGateRight",

		Vector3(
			14.5,
			1.0,
			z_saida
		),

		Vector3(
			2.5,
			14.0,
			3.0
		),

		material_metal
	)


	criar_caixa(
		"ExitGateTop",

		Vector3(
			0.0,
			7.0,
			z_saida
		),

		Vector3(
			31.0,
			2.0,
			3.0
		),

		material_metal
	)


	for lado in [
		-1.0,
		1.0
	]:

		for altura_luz in [
			-2.5,
			0.0,
			2.5,
			5.0
		]:

			criar_caixa(
				"ExitWarning",

				Vector3(
					lado * 12.8,
					altura_luz,
					z_saida + 1.6
				),

				Vector3(
					0.30,
					0.30,
					0.18
				),

				material_luz_vermelha
			)


	criar_caixa(
		"ExitBlueLine",

		Vector3(
			0.0,
			5.6,
			z_saida + 1.6
		),

		Vector3(
			22.0,
			0.12,
			0.18
		),

		material_luz_azul
	)


# =========================================================
# PORTA PRINCIPAL
# =========================================================

func criar_porta_hangar():

	# =====================================================
	# METADE ESQUERDA
	# =====================================================

	porta_esquerda = criar_caixa(
		"BlastDoorLeft",

		posicao_porta_esquerda_fechada,

		Vector3(
			14.0,
			12.0,
			1.0
		),

		material_metal
	)


	# =====================================================
	# METADE DIREITA
	# =====================================================

	porta_direita = criar_caixa(
		"BlastDoorRight",

		posicao_porta_direita_fechada,

		Vector3(
			14.0,
			12.0,
			1.0
		),

		material_metal
	)


	# =====================================================
	# DETALHES DAS PORTAS
	# =====================================================

	for y in [
		-3.8,
		-1.8,
		0.2,
		2.2,
		4.2
	]:

		criar_caixa(
			"DoorStripeLeft",

			Vector3(
				-7.0,
				y,
				-147.15
			),

			Vector3(
				12.5,
				0.10,
				0.08
			),

			material_metal_escuro
		)


		criar_caixa(
			"DoorStripeRight",

			Vector3(
				7.0,
				y,
				-147.15
			),

			Vector3(
				12.5,
				0.10,
				0.08
			),

			material_metal_escuro
		)


	# Linha luminosa central

	criar_caixa(
		"DoorCenterLight",

		Vector3(
			0.0,
			1.0,
			-147.1
		),

		Vector3(
			0.12,
			10.0,
			0.08
		),

		material_luz_vermelha
	)


# =========================================================
# ABRIR PORTA
# =========================================================

func iniciar_abertura_porta():

	if porta_abrindo:
		return


	if porta_aberta:
		return


	if porta_esquerda == null:
		return


	if porta_direita == null:
		return


	porta_abrindo = true


	var tween: Tween = create_tween()


	tween.set_parallel(
		true
	)


	tween.set_trans(
		Tween.TRANS_QUAD
	)


	tween.set_ease(
		Tween.EASE_IN_OUT
	)


	tween.tween_property(
		porta_esquerda,
		"position",
		posicao_porta_esquerda_aberta,
		2.7
	)


	tween.tween_property(
		porta_direita,
		"position",
		posicao_porta_direita_aberta,
		2.7
	)


	await tween.finished


	porta_abrindo = false

	porta_aberta = true


# =========================================================
# ALERTA DE LANCAMENTO
# =========================================================

func ativar_alerta_lancamento():

	alerta_ativo = true


# =========================================================
# FINALIZAR ALERTA
# =========================================================

func finalizar_alerta_lancamento():

	alerta_ativo = false


# =========================================================
# LUZES DE ALERTA REAIS
# =========================================================

func criar_luzes_alerta():

	var posicoes: Array[Vector3] = [

		Vector3(
			-11.5,
			4.5,
			-135.0
		),

		Vector3(
			11.5,
			4.5,
			-135.0
		),

		Vector3(
			-11.5,
			4.5,
			-115.0
		),

		Vector3(
			11.5,
			4.5,
			-115.0
		)
	]


	for i in range(
		posicoes.size()
	):

		var luz := OmniLight3D.new()


		luz.name = (
			"LaunchWarningLight_%02d"
			%
			i
		)


		luz.position = posicoes[i]


		luz.light_color = Color(
			1.0,
			0.04,
			0.01
		)


		luz.light_energy = 0.0


		luz.omni_range = 12.0


		luz.shadow_enabled = false


		add_child(
			luz
		)


		luzes_alerta.append(
			luz
		)


# =========================================================
# ATUALIZAR LUZES
# =========================================================

func atualizar_luzes():

	# =====================================================
	# AZUL NORMAL
	# =====================================================

	var pulso_azul: float = (
		3.0
		+
		sin(
			tempo * 2.2
		)
		*
		0.65
	)


	material_luz_azul.emission_energy_multiplier = (
		pulso_azul
	)


	# =====================================================
	# ALERTA VERMELHO
	# =====================================================

	if alerta_ativo:

		var pulso: float = (
			sin(
				tempo * 9.0
			)
			+
			1.0
		) * 0.5


		var energia_vermelha: float = lerpf(
			0.5,
			6.0,
			pulso
		)


		material_luz_vermelha.emission_energy_multiplier = (
			energia_vermelha
		)


		for luz in luzes_alerta:

			if is_instance_valid(
				luz
			):

				luz.light_energy = lerpf(
					0.0,
					4.0,
					pulso
				)


	else:

		material_luz_vermelha.emission_energy_multiplier = (
			0.5
		)


		for luz in luzes_alerta:

			if is_instance_valid(
				luz
			):

				luz.light_energy = 0.0


# =========================================================
# DETALHES LATERAIS
# =========================================================

func criar_detalhes_laterais():

	var z: float = 8.0

	var numero: int = 0


	while z > -140.0:

		for lado in [
			-1.0,
			1.0
		]:

			var x: float = (
				lado * 15.35
			)


			criar_caixa(
				"SidePanel_%02d" % numero,

				Vector3(
					x,
					1.0,
					z
				),

				Vector3(
					0.30,
					4.6,
					6.5
				),

				material_metal
			)


			criar_caixa(
				"SideGlow_%02d" % numero,

				Vector3(
					x - lado * 0.18,
					1.0,
					z
				),

				Vector3(
					0.08,
					0.16,
					4.5
				),

				material_luz_azul
			)


		z -= 12.0

		numero += 1


# =========================================================
# PAREDE TRASEIRA
# =========================================================

func criar_parede_traseira():

	criar_caixa(
		"RearWall",

		Vector3(
			0.0,
			1.0,
			20.0
		),

		Vector3(
			32.0,
			14.0,
			1.0
		),

		material_metal_escuro
	)


	criar_caixa(
		"RearBlueLight",

		Vector3(
			0.0,
			3.0,
			19.4
		),

		Vector3(
			12.0,
			0.20,
			0.10
		),

		material_luz_azul
	)
