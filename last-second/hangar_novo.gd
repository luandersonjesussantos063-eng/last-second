extends Node3D


# ============================================================
# ODYSSEY STATION
# HANGAR PRINCIPAL - VERSAO 07
#
# P-01 = NAVE DO JOGADOR
# P-02 = INTERCEPTOR DE PATRULHA
# P-03 = CARGUEIRO MILITAR
# P-04 = CACA AVANCADO
#
# Mantem:
# - salas
# - mobilia
# - iluminacao
# - modo a pe
# - colisao
# ============================================================


# ============================================================
# HANGAR
# ============================================================

@export_category("Hangar")

@export var largura_hangar: float = 150.0
@export var profundidade_hangar: float = 180.0
@export var altura_hangar: float = 30.0

@export var altura_piso_fisico: float = 0.0


# ============================================================
# P-01
# ============================================================

@export var p01_spawn_local := Vector3(
	-36.0,
	2.5,
	-43.0
)


# ============================================================
# DIMENSOES
# ============================================================

const ESPESSURA_PAREDE := 2.0
const ESPESSURA_CHAO := 1.5
const ESPESSURA_TETO := 1.5

const PISTA_LARGURA := 52.0
const PISTA_PROFUNDIDADE := 58.0

const SALA_ALTURA := 8.0
const SALA_PROFUNDIDADE := 10.0
const SALA_COMPRIMENTO := 34.0

const PORTA_LARGURA := 4.5
const PORTA_ALTURA := 4.5


# ============================================================
# POSICOES PISTAS
# ============================================================

const POS_P01 := Vector3(
	-36.0,
	0.0,
	-43.0
)

const POS_P02 := Vector3(
	-36.0,
	0.0,
	43.0
)

const POS_P03 := Vector3(
	36.0,
	0.0,
	43.0
)

const POS_P04 := Vector3(
	36.0,
	0.0,
	-43.0
)


# ============================================================
# CORES
# ============================================================

const COR_CHAO := Color(
	0.10,
	0.12,
	0.16
)

const COR_PAREDE := Color(
	0.16,
	0.19,
	0.24
)

const COR_TETO := Color(
	0.08,
	0.10,
	0.14
)

const COR_PISTA := Color(
	0.12,
	0.14,
	0.18
)

const COR_CORREDOR := Color(
	0.18,
	0.21,
	0.25
)

const COR_SALA := Color(
	0.11,
	0.13,
	0.17
)

const COR_METAL := Color(
	0.25,
	0.28,
	0.33
)

const COR_METAL_ESCURO := Color(
	0.055,
	0.07,
	0.095
)

const COR_PRATA := Color(
	0.40,
	0.45,
	0.52
)

const COR_PRATA_CLARA := Color(
	0.58,
	0.63,
	0.70
)

const COR_CIANO := Color(
	0.0,
	0.78,
	1.0
)

const COR_LARANJA := Color(
	1.0,
	0.35,
	0.08
)

const COR_AMARELA := Color(
	1.0,
	0.72,
	0.10
)

const COR_VERDE := Color(
	0.12,
	1.0,
	0.50
)

const COR_ROXO := Color(
	0.66,
	0.30,
	1.0
)

const COR_VERMELHO := Color(
	1.0,
	0.10,
	0.06
)

const COR_COCKPIT := Color(
	0.015,
	0.12,
	0.18
)


# ============================================================
# READY
# ============================================================

func _ready() -> void:

	construir_estrutura()

	construir_corredores()

	construir_pistas()

	construir_salas()

	mobiliar_todas_as_salas()

	criar_naves_estacionadas()

	criar_iluminacao()

	call_deferred(
		"posicionar_player_na_p01"
	)



# ============================================================
# P-01 DO JOGADOR
# ============================================================

func posicionar_player_na_p01() -> void:

	var cena := get_tree().current_scene

	if cena == null:
		return


	var player := cena.get_node_or_null(
		"Player"
	) as Node3D


	if player == null:

		var encontrado := cena.find_child(
			"Player",
			true,
			false
		)

		if encontrado is Node3D:
			player = encontrado


	if player == null:
		return


	if player is CharacterBody3D:

		player.velocity = Vector3.ZERO


	if player is RigidBody3D:

		player.linear_velocity = Vector3.ZERO
		player.angular_velocity = Vector3.ZERO


	player.global_position = to_global(
		p01_spawn_local
	)


	player.global_rotation = Vector3.ZERO


	var mobile_controls := cena.get_node_or_null(
		"MobileControls"
	)


	if mobile_controls == null:

		mobile_controls = cena.find_child(
			"MobileControls",
			true,
			false
		)


	if (
		mobile_controls != null
		and mobile_controls.has_method(
			"sincronizar_spawn_hangar"
		)
	):

		mobile_controls.call(
			"sincronizar_spawn_hangar",
			player.global_position,
			player.global_rotation
		)



# ============================================================
# ESTRUTURA
# ============================================================

func construir_estrutura() -> void:


	criar_caixa(
		"ChaoPrincipal",

		Vector3(
			largura_hangar,
			ESPESSURA_CHAO,
			profundidade_hangar
		),

		Vector3(
			0.0,
			-ESPESSURA_CHAO / 2.0,
			0.0
		),

		COR_CHAO,
		true
	)


	criar_caixa(
		"TetoPrincipal",

		Vector3(
			largura_hangar,
			ESPESSURA_TETO,
			profundidade_hangar
		),

		Vector3(
			0.0,
			altura_hangar
			+ ESPESSURA_TETO / 2.0,
			0.0
		),

		COR_TETO,
		true
	)


	criar_caixa(
		"ParedeEsquerda",

		Vector3(
			ESPESSURA_PAREDE,
			altura_hangar,
			profundidade_hangar
		),

		Vector3(
			-largura_hangar / 2.0,
			altura_hangar / 2.0,
			0.0
		),

		COR_PAREDE,
		true
	)


	criar_caixa(
		"ParedeDireita",

		Vector3(
			ESPESSURA_PAREDE,
			altura_hangar,
			profundidade_hangar
		),

		Vector3(
			largura_hangar / 2.0,
			altura_hangar / 2.0,
			0.0
		),

		COR_PAREDE,
		true
	)


	criar_caixa(
		"ParedeFundo",

		Vector3(
			largura_hangar,
			altura_hangar,
			ESPESSURA_PAREDE
		),

		Vector3(
			0.0,
			altura_hangar / 2.0,
			profundidade_hangar / 2.0
		),

		COR_PAREDE,
		true
	)



# ============================================================
# CORREDORES
# ============================================================

func construir_corredores() -> void:


	criar_caixa(
		"CorredorCentral",

		Vector3(
			10.0,
			0.08,
			158.0
		),

		Vector3(
			0.0,
			0.06,
			0.0
		),

		COR_CORREDOR
	)


	criar_caixa(
		"CorredorTransversal",

		Vector3(
			132.0,
			0.08,
			10.0
		),

		Vector3(
			0.0,
			0.07,
			0.0
		),

		COR_CORREDOR
	)


	criar_caixa(
		"CorredorLateralE",

		Vector3(
			8.0,
			0.09,
			168.0
		),

		Vector3(
			-61.0,
			0.08,
			0.0
		),

		COR_METAL
	)


	criar_caixa(
		"CorredorLateralD",

		Vector3(
			8.0,
			0.09,
			168.0
		),

		Vector3(
			61.0,
			0.08,
			0.0
		),

		COR_METAL
	)


	criar_caixa(
		"GuiaCentralE",

		Vector3(
			0.20,
			0.05,
			158.0
		),

		Vector3(
			-5.0,
			0.12,
			0.0
		),

		COR_CIANO,
		false,
		true,
		4.0
	)


	criar_caixa(
		"GuiaCentralD",

		Vector3(
			0.20,
			0.05,
			158.0
		),

		Vector3(
			5.0,
			0.12,
			0.0
		),

		COR_CIANO,
		false,
		true,
		4.0
	)



# ============================================================
# PISTAS
# ============================================================

func construir_pistas() -> void:

	criar_pista(
		"P01",
		POS_P01,
		COR_CIANO
	)

	criar_pista(
		"P02",
		POS_P02,
		COR_AMARELA
	)

	criar_pista(
		"P03",
		POS_P03,
		COR_CIANO
	)

	criar_pista(
		"P04",
		POS_P04,
		COR_LARANJA
	)



func criar_pista(
	nome: String,
	pos: Vector3,
	cor: Color
) -> void:


	criar_caixa(
		nome + "_Base",

		Vector3(
			PISTA_LARGURA,
			0.10,
			PISTA_PROFUNDIDADE
		),

		pos + Vector3(
			0.0,
			0.07,
			0.0
		),

		COR_PISTA
	)


	criar_caixa(
		nome + "_E",

		Vector3(
			0.32,
			0.06,
			PISTA_PROFUNDIDADE
		),

		pos + Vector3(
			-PISTA_LARGURA / 2.0,
			0.14,
			0.0
		),

		cor,
		false,
		true,
		5.0
	)


	criar_caixa(
		nome + "_D",

		Vector3(
			0.32,
			0.06,
			PISTA_PROFUNDIDADE
		),

		pos + Vector3(
			PISTA_LARGURA / 2.0,
			0.14,
			0.0
		),

		cor,
		false,
		true,
		5.0
	)


	criar_caixa(
		nome + "_Frente",

		Vector3(
			PISTA_LARGURA,
			0.06,
			0.32
		),

		pos + Vector3(
			0.0,
			0.14,
			-PISTA_PROFUNDIDADE / 2.0
		),

		cor,
		false,
		true,
		5.0
	)


	criar_caixa(
		nome + "_Tras",

		Vector3(
			PISTA_LARGURA,
			0.06,
			0.32
		),

		pos + Vector3(
			0.0,
			0.14,
			PISTA_PROFUNDIDADE / 2.0
		),

		cor,
		false,
		true,
		5.0
	)


	criar_caixa(
		nome + "_Centro",

		Vector3(
			0.28,
			0.06,
			PISTA_PROFUNDIDADE - 10.0
		),

		pos + Vector3(
			0.0,
			0.15,
			0.0
		),

		cor,
		false,
		true,
		3.5
	)


	criar_caixa(
		nome + "_Cruz",

		Vector3(
			12.0,
			0.07,
			0.45
		),

		pos + Vector3(
			0.0,
			0.17,
			0.0
		),

		cor,
		false,
		true,
		4.0
	)


	criar_texto_pista(
		nome,
		pos + Vector3(
			0.0,
			0.20,
			-19.0
		),
		cor
	)



func criar_texto_pista(
	nome: String,
	pos: Vector3,
	cor: Color
) -> void:

	var label := Label3D.new()

	label.name = "Texto_" + nome

	label.text = nome.insert(
		1,
		"-"
	)

	label.position = pos

	label.rotation_degrees = Vector3(
		-90.0,
		0.0,
		0.0
	)

	label.font_size = 72

	label.pixel_size = 0.025

	label.outline_size = 10

	label.modulate = cor

	label.outline_modulate = Color.BLACK


	add_child(
		label
	)



# ============================================================
# ============================================================
# NAVES ESTACIONADAS
# ============================================================
# ============================================================

func criar_naves_estacionadas() -> void:


	# P-01 NAO E CRIADA.
	# A nave do jogador ja ocupa a vaga.


	criar_nave_p02_patrulha(
		POS_P02
	)


	criar_nave_p03_cargueiro(
		POS_P03
	)


	criar_nave_p04_caca(
		POS_P04
	)



# ============================================================
# P-02
# INTERCEPTOR DE PATRULHA
# ============================================================

func criar_nave_p02_patrulha(
	pos: Vector3
) -> void:

	var nave := Node3D.new()

	nave.name = "P02_InterceptorPatrulha"

	nave.position = pos


	add_child(
		nave
	)


	# ========================================================
	# FUSELAGEM CENTRAL
	# ========================================================

	criar_caixa(
		"P02_Fuselagem",

		Vector3(
			2.8,
			1.65,
			10.5
		),

		Vector3(
			0.0,
			2.0,
			0.8
		),

		COR_PRATA,
		false,
		false,
		1.0,
		Vector3.ZERO,
		nave,
		0.78,
		0.24
	)


	# Parte superior

	criar_caixa(
		"P02_Dorso",

		Vector3(
			1.9,
			0.75,
			7.2
		),

		Vector3(
			0.0,
			3.0,
			0.8
		),

		COR_METAL_ESCURO,
		false,
		false,
		1.0,
		Vector3.ZERO,
		nave,
		0.65,
		0.22
	)


	# ========================================================
	# NARIZ
	# ========================================================

	criar_caixa(
		"P02_Nariz01",

		Vector3(
			2.2,
			1.25,
			3.2
		),

		Vector3(
			0.0,
			1.85,
			-5.5
		),

		COR_PRATA_CLARA,
		false,
		false,
		1.0,
		Vector3(
			8.0,
			0.0,
			0.0
		),
		nave,
		0.80,
		0.20
	)


	criar_caixa(
		"P02_Nariz02",

		Vector3(
			1.35,
			0.80,
			2.6
		),

		Vector3(
			0.0,
			1.65,
			-8.0
		),

		COR_PRATA,
		false,
		false,
		1.0,
		Vector3(
			12.0,
			0.0,
			0.0
		),
		nave,
		0.80,
		0.20
	)


	# ========================================================
	# COCKPIT
	# ========================================================

	criar_esfera(
		"P02_Cockpit",

		Vector3(
			0.0,
			3.15,
			-3.15
		),

		Vector3(
			1.45,
			0.70,
			2.2
		),

		COR_COCKPIT,

		nave,

		false
	)


	criar_caixa(
		"P02_CockpitLuz",

		Vector3(
			1.35,
			0.08,
			1.8
		),

		Vector3(
			0.0,
			3.47,
			-3.4
		),

		COR_CIANO,
		false,
		true,
		2.5,
		Vector3.ZERO,
		nave
	)


	# ========================================================
	# ASAS
	# ========================================================

	criar_caixa(
		"P02_AsaE",

		Vector3(
			6.4,
			0.34,
			4.7
		),

		Vector3(
			-3.7,
			1.9,
			0.4
		),

		COR_PRATA,
		false,
		false,
		1.0,
		Vector3(
			0.0,
			-8.0,
			-3.0
		),
		nave,
		0.75,
		0.28
	)


	criar_caixa(
		"P02_AsaD",

		Vector3(
			6.4,
			0.34,
			4.7
		),

		Vector3(
			3.7,
			1.9,
			0.4
		),

		COR_PRATA,
		false,
		false,
		1.0,
		Vector3(
			0.0,
			8.0,
			3.0
		),
		nave,
		0.75,
		0.28
	)


	# Luz nas pontas

	criar_caixa(
		"P02_LuzAsaE",

		Vector3(
			0.18,
			0.14,
			3.0
		),

		Vector3(
			-6.75,
			2.08,
			0.3
		),

		COR_CIANO,
		false,
		true,
		5.0,
		Vector3.ZERO,
		nave
	)


	criar_caixa(
		"P02_LuzAsaD",

		Vector3(
			0.18,
			0.14,
			3.0
		),

		Vector3(
			6.75,
			2.08,
			0.3
		),

		COR_CIANO,
		false,
		true,
		5.0,
		Vector3.ZERO,
		nave
	)


	# ========================================================
	# MOTORES
	# ========================================================

	for x in [
		-1.35,
		1.35
	]:

		criar_cilindro(
			"P02_Motor",

			0.72,
			2.4,

			Vector3(
				x,
				2.0,
				5.0
			),

			COR_METAL_ESCURO,

			false,

			Vector3(
				90.0,
				0.0,
				0.0
			),

			nave
		)


		criar_cilindro(
			"P02_Propulsor",

			0.54,
			0.15,

			Vector3(
				x,
				2.0,
				6.22
			),

			COR_CIANO,

			false,

			Vector3(
				90.0,
				0.0,
				0.0
			),

			nave,

			true,
			8.0
		)


	# ========================================================
	# TREM DE POUSO
	# ========================================================

	for x in [
		-2.0,
		2.0
	]:

		criar_caixa(
			"P02_TremPouso",

			Vector3(
				0.28,
				1.45,
				0.28
			),

			Vector3(
				x,
				0.85,
				1.2
			),

			COR_METAL_ESCURO,
			false,
			false,
			1.0,
			Vector3.ZERO,
			nave
		)


		criar_caixa(
			"P02_Pe",

			Vector3(
				0.75,
				0.16,
				1.1
			),

			Vector3(
				x,
				0.15,
				1.2
			),

			COR_METAL_ESCURO,
			false,
			false,
			1.0,
			Vector3.ZERO,
			nave
		)


	# ========================================================
	# COLISAO SIMPLES
	# ========================================================

	criar_colisao_caixa(
		"P02_Colisao",

		Vector3(
			10.5,
			3.6,
			15.0
		),

		Vector3(
			0.0,
			1.9,
			0.0
		),

		Vector3.ZERO,

		nave
	)



# ============================================================
# P-03
# CARGUEIRO MILITAR
# ============================================================

func criar_nave_p03_cargueiro(
	pos: Vector3
) -> void:

	var nave := Node3D.new()

	nave.name = "P03_CargueiroMilitar"

	nave.position = pos


	add_child(
		nave
	)


	# ========================================================
	# CORPO PRINCIPAL
	# ========================================================

	criar_caixa(
		"P03_Corpo",

		Vector3(
			5.4,
			3.2,
			11.5
		),

		Vector3(
			0.0,
			2.6,
			0.8
		),

		Color(
			0.25,
			0.30,
			0.28
		),

		false,
		false,
		1.0,
		Vector3.ZERO,
		nave,
		0.70,
		0.34
	)


	# Teto reforcado

	criar_caixa(
		"P03_Teto",

		Vector3(
			4.1,
			0.85,
			8.4
		),

		Vector3(
			0.0,
			4.55,
			1.2
		),

		COR_METAL_ESCURO,
		false,
		false,
		1.0,
		Vector3.ZERO,
		nave
	)


	# ========================================================
	# MODULOS DE CARGA LATERAIS
	# ========================================================

	for x in [
		-4.3,
		4.3
	]:

		criar_caixa(
			"P03_ModuloCarga",

			Vector3(
				3.0,
				2.8,
				8.0
			),

			Vector3(
				x,
				2.35,
				1.4
			),

			Color(
				0.19,
				0.23,
				0.21
			),

			false,
			false,
			1.0,
			Vector3.ZERO,
			nave,
			0.72,
			0.38
		)


		criar_caixa(
			"P03_FaixaCarga",

			Vector3(
				0.16,
				0.35,
				6.4
			),

			Vector3(
				x
				+ (
					-1.52
					if x < 0.0
					else 1.52
				),

				2.6,

				1.4
			),

			COR_AMARELA,
			false,
			true,
			3.0,
			Vector3.ZERO,
			nave
		)


	# ========================================================
	# CABINE
	# ========================================================

	criar_caixa(
		"P03_Cabine",

		Vector3(
			4.2,
			2.1,
			3.5
		),

		Vector3(
			0.0,
			3.05,
			-6.1
		),

		COR_PRATA,
		false,
		false,
		1.0,
		Vector3(
			5.0,
			0.0,
			0.0
		),
		nave,
		0.78,
		0.24
	)


	criar_caixa(
		"P03_Parabrisa",

		Vector3(
			3.2,
			0.75,
			0.16
		),

		Vector3(
			0.0,
			3.55,
			-7.85
		),

		COR_CIANO,
		false,
		true,
		2.0,
		Vector3(
			-8.0,
			0.0,
			0.0
		),
		nave
	)


	# ========================================================
	# MOTORES
	# ========================================================

	for x in [
		-4.2,
		-1.5,
		1.5,
		4.2
	]:

		criar_cilindro(
			"P03_Motor",

			0.70,
			2.5,

			Vector3(
				x,
				2.35,
				5.6
			),

			COR_METAL_ESCURO,

			false,

			Vector3(
				90.0,
				0.0,
				0.0
			),

			nave
		)


		criar_cilindro(
			"P03_Propulsor",

			0.52,
			0.16,

			Vector3(
				x,
				2.35,
				6.88
			),

			COR_LARANJA,

			false,

			Vector3(
				90.0,
				0.0,
				0.0
			),

			nave,

			true,
			7.0
		)


	# ========================================================
	# TREM DE POUSO
	# ========================================================

	for x in [
		-4.4,
		4.4
	]:

		for z in [
			-2.5,
			3.0
		]:

			criar_caixa(
				"P03_Trem",

				Vector3(
					0.38,
					1.5,
					0.38
				),

				Vector3(
					x,
					0.9,
					z
				),

				COR_METAL_ESCURO,
				false,
				false,
				1.0,
				Vector3.ZERO,
				nave
			)


			criar_caixa(
				"P03_Pe",

				Vector3(
					1.2,
					0.18,
					1.35
				),

				Vector3(
					x,
					0.15,
					z
				),

				COR_METAL_ESCURO,
				false,
				false,
				1.0,
				Vector3.ZERO,
				nave
			)


	criar_colisao_caixa(
		"P03_Colisao",

		Vector3(
			11.5,
			5.0,
			16.5
		),

		Vector3(
			0.0,
			2.5,
			0.0
		),

		Vector3.ZERO,

		nave
	)



# ============================================================
# P-04
# CACA AVANCADO
# ============================================================

func criar_nave_p04_caca(
	pos: Vector3
) -> void:

	var nave := Node3D.new()

	nave.name = "P04_CacaAvancado"

	nave.position = pos


	add_child(
		nave
	)


	# ========================================================
	# FUSELAGEM
	# ========================================================

	criar_caixa(
		"P04_Fuselagem",

		Vector3(
			2.2,
			1.25,
			12.5
		),

		Vector3(
			0.0,
			1.9,
			0.2
		),

		COR_PRATA_CLARA,
		false,
		false,
		1.0,
		Vector3.ZERO,
		nave,
		0.85,
		0.16
	)


	# Parte inferior escura

	criar_caixa(
		"P04_Barriga",

		Vector3(
			2.65,
			0.70,
			8.5
		),

		Vector3(
			0.0,
			1.3,
			0.8
		),

		COR_METAL_ESCURO,
		false,
		false,
		1.0,
		Vector3.ZERO,
		nave
	)


	# ========================================================
	# NARIZ LONGO
	# ========================================================

	criar_caixa(
		"P04_Nariz",

		Vector3(
			1.35,
			0.80,
			4.5
		),

		Vector3(
			0.0,
			1.72,
			-7.6
		),

		COR_PRATA,
		false,
		false,
		1.0,
		Vector3(
			9.0,
			0.0,
			0.0
		),
		nave,
		0.82,
		0.18
	)


	criar_caixa(
		"P04_Ponta",

		Vector3(
			0.65,
			0.42,
			2.2
		),

		Vector3(
			0.0,
			1.48,
			-10.2
		),

		COR_METAL_ESCURO,
		false,
		false,
		1.0,
		Vector3(
			12.0,
			0.0,
			0.0
		),
		nave
	)


	# ========================================================
	# COCKPIT
	# ========================================================

	criar_esfera(
		"P04_Cockpit",

		Vector3(
			0.0,
			2.75,
			-3.8
		),

		Vector3(
			1.15,
			0.62,
			2.2
		),

		COR_COCKPIT,

		nave,

		false
	)


	# ========================================================
	# ASAS ANGULADAS
	# ========================================================

	criar_caixa(
		"P04_AsaE01",

		Vector3(
			7.8,
			0.28,
			3.8
		),

		Vector3(
			-4.0,
			1.55,
			0.8
		),

		COR_PRATA,
		false,
		false,
		1.0,
		Vector3(
			0.0,
			-17.0,
			-4.0
		),
		nave,
		0.82,
		0.20
	)


	criar_caixa(
		"P04_AsaD01",

		Vector3(
			7.8,
			0.28,
			3.8
		),

		Vector3(
			4.0,
			1.55,
			0.8
		),

		COR_PRATA,
		false,
		false,
		1.0,
		Vector3(
			0.0,
			17.0,
			4.0
		),
		nave,
		0.82,
		0.20
	)


	# Asas secundarias

	criar_caixa(
		"P04_AsaE02",

		Vector3(
			4.4,
			0.24,
			3.0
		),

		Vector3(
			-2.9,
			1.75,
			4.1
		),

		COR_METAL_ESCURO,
		false,
		false,
		1.0,
		Vector3(
			0.0,
			12.0,
			-5.0
		),
		nave
	)


	criar_caixa(
		"P04_AsaD02",

		Vector3(
			4.4,
			0.24,
			3.0
		),

		Vector3(
			2.9,
			1.75,
			4.1
		),

		COR_METAL_ESCURO,
		false,
		false,
		1.0,
		Vector3(
			0.0,
			-12.0,
			5.0
		),
		nave
	)


	# ========================================================
	# LUZES NAS ASAS
	# ========================================================

	criar_caixa(
		"P04_LuzAsaE",

		Vector3(
			0.18,
			0.12,
			2.8
		),

		Vector3(
			-7.4,
			1.72,
			1.5
		),

		COR_LARANJA,
		false,
		true,
		6.0,
		Vector3(
			0.0,
			-17.0,
			0.0
		),
		nave
	)


	criar_caixa(
		"P04_LuzAsaD",

		Vector3(
			0.18,
			0.12,
			2.8
		),

		Vector3(
			7.4,
			1.72,
			1.5
		),

		COR_LARANJA,
		false,
		true,
		6.0,
		Vector3(
			0.0,
			17.0,
			0.0
		),
		nave
	)


	# ========================================================
	# ESTABILIZADORES TRASEIROS
	# ========================================================

	criar_caixa(
		"P04_EstabilizadorE",

		Vector3(
			0.35,
			2.8,
			3.2
		),

		Vector3(
			-1.6,
			3.0,
			4.5
		),

		COR_PRATA,
		false,
		false,
		1.0,
		Vector3(
			0.0,
			0.0,
			-14.0
		),
		nave
	)


	criar_caixa(
		"P04_EstabilizadorD",

		Vector3(
			0.35,
			2.8,
			3.2
		),

		Vector3(
			1.6,
			3.0,
			4.5
		),

		COR_PRATA,
		false,
		false,
		1.0,
		Vector3(
			0.0,
			0.0,
			14.0
		),
		nave
	)


	# ========================================================
	# MOTORES
	# ========================================================

	for x in [
		-1.25,
		1.25
	]:

		criar_cilindro(
			"P04_Motor",

			0.78,
			2.6,

			Vector3(
				x,
				1.65,
				5.7
			),

			COR_METAL_ESCURO,

			false,

			Vector3(
				90.0,
				0.0,
				0.0
			),

			nave
		)


		criar_cilindro(
			"P04_Propulsor",

			0.60,
			0.15,

			Vector3(
				x,
				1.65,
				7.0
			),

			COR_LARANJA,

			false,

			Vector3(
				90.0,
				0.0,
				0.0
			),

			nave,

			true,
			9.0
		)


	# ========================================================
	# TREM DE POUSO
	# ========================================================

	criar_caixa(
		"P04_TremFrente",

		Vector3(
			0.25,
			1.25,
			0.25
		),

		Vector3(
			0.0,
			0.72,
			-4.2
		),

		COR_METAL_ESCURO,
		false,
		false,
		1.0,
		Vector3.ZERO,
		nave
	)


	for x in [
		-2.6,
		2.6
	]:

		criar_caixa(
			"P04_TremTras",

			Vector3(
				0.25,
				1.25,
				0.25
			),

			Vector3(
				x,
				0.72,
				2.5
			),

			COR_METAL_ESCURO,
			false,
			false,
			1.0,
			Vector3.ZERO,
			nave
		)


	criar_colisao_caixa(
		"P04_Colisao",

		Vector3(
			13.0,
			4.0,
			19.0
		),

		Vector3(
			0.0,
			2.0,
			-0.5
		),

		Vector3.ZERO,

		nave
	)



# ============================================================
# SALAS
# ============================================================

func construir_salas() -> void:


	criar_sala(
		"OFICINA MECANICA",
		-1.0,
		-67.0,
		COR_LARANJA
	)

	criar_sala(
		"ESTACAO DE COMBUSTIVEL",
		-1.0,
		-23.0,
		COR_AMARELA
	)

	criar_sala(
		"REFEITORIO",
		-1.0,
		23.0,
		COR_VERDE
	)

	criar_sala(
		"DORMITORIOS",
		-1.0,
		67.0,
		COR_CIANO
	)

	criar_sala(
		"ZONA DE CARGA",
		1.0,
		-67.0,
		COR_LARANJA
	)

	criar_sala(
		"EQUIPAMENTOS",
		1.0,
		-23.0,
		COR_CIANO
	)

	criar_sala(
		"SALA DE JOGOS",
		1.0,
		23.0,
		COR_ROXO
	)

	criar_sala(
		"SALA DE CONTROLE",
		1.0,
		67.0,
		COR_CIANO
	)



func criar_sala(
	nome: String,
	lado: float,
	z: float,
	cor: Color
) -> void:


	var centro_x := lado * 70.0

	var entrada_x := lado * 65.0


	criar_caixa(
		nome + "_Piso",

		Vector3(
			SALA_PROFUNDIDADE,
			0.12,
			SALA_COMPRIMENTO
		),

		Vector3(
			centro_x,
			0.10,
			z
		),

		COR_SALA
	)


	criar_caixa(
		nome + "_Teto",

		Vector3(
			SALA_PROFUNDIDADE,
			0.5,
			SALA_COMPRIMENTO
		),

		Vector3(
			centro_x,
			SALA_ALTURA,
			z
		),

		COR_TETO,
		true
	)


	for deslocamento in [
		-SALA_COMPRIMENTO / 2.0,
		SALA_COMPRIMENTO / 2.0
	]:

		criar_caixa(
			nome + "_Parede",

			Vector3(
				SALA_PROFUNDIDADE,
				SALA_ALTURA,
				0.5
			),

			Vector3(
				centro_x,
				SALA_ALTURA / 2.0,
				z + deslocamento
			),

			COR_PAREDE,
			true
		)


	var segmento := (
		SALA_COMPRIMENTO
		- PORTA_LARGURA
	) / 2.0


	var deslocamento_porta := (
		PORTA_LARGURA / 2.0
		+ segmento / 2.0
	)


	for sinal in [
		-1.0,
		1.0
	]:

		criar_caixa(
			nome + "_Entrada",

			Vector3(
				0.5,
				SALA_ALTURA,
				segmento
			),

			Vector3(
				entrada_x,
				SALA_ALTURA / 2.0,
				z
				+ deslocamento_porta
				* sinal
			),

			COR_PAREDE,
			true
		)


	var topo := (
		SALA_ALTURA
		- PORTA_ALTURA
	)


	criar_caixa(
		nome + "_TopoPorta",

		Vector3(
			0.5,
			topo,
			PORTA_LARGURA
		),

		Vector3(
			entrada_x,

			PORTA_ALTURA
			+ topo / 2.0,

			z
		),

		COR_PAREDE,
		true
	)


	criar_caixa(
		nome + "_LuzPorta",

		Vector3(
			0.25,
			0.35,
			5.5
		),

		Vector3(
			entrada_x
			- lado * 0.30,

			5.2,

			z
		),

		cor,
		false,
		true,
		5.0
	)


	criar_texto_sala(
		nome,
		lado,

		Vector3(
			entrada_x
			- lado * 0.40,

			6.15,

			z
		),

		cor
	)


	criar_luz_sala(
		Vector3(
			centro_x,
			6.5,
			z
		),
		cor
	)



# ============================================================
# MOBILIA
# ============================================================

func mobiliar_todas_as_salas() -> void:

	mobiliar_oficina()
	mobiliar_combustivel()
	mobiliar_refeitorio()
	mobiliar_dormitorios()
	mobiliar_carga()
	mobiliar_equipamentos()
	mobiliar_jogos()
	mobiliar_controle()



func mobiliar_oficina() -> void:


	for z in [
		-76.0,
		-58.0
	]:

		criar_bancada(
			Vector3(
				-72.0,
				0.0,
				z
			),
			COR_LARANJA
		)


	for z in [
		-80.0,
		-72.0,
		-61.0,
		-54.0
	]:

		criar_armario(
			Vector3(
				-73.3,
				0.0,
				z
			),
			COR_LARANJA
		)


	criar_caixa(
		"PlataformaReparo",

		Vector3(
			5.0,
			0.28,
			7.0
		),

		Vector3(
			-69.5,
			0.14,
			-67.0
		),

		COR_METAL,
		true
	)


	criar_braco_robotico(
		Vector3(
			-72.3,
			0.0,
			-67.0
		)
	)



func mobiliar_combustivel() -> void:


	for z in [
		-32.0,
		-23.0,
		-14.0
	]:

		criar_tanque(
			Vector3(
				-72.5,
				0.0,
				z
			)
		)


	for z in [
		-29.0,
		-17.0
	]:

		criar_console(
			Vector3(
				-68.0,
				0.0,
				z
			),
			COR_AMARELA
		)



func mobiliar_refeitorio() -> void:


	for z in [
		13.0,
		23.0,
		33.0
	]:

		criar_mesa(
			Vector3(
				-71.0,
				0.0,
				z
			),
			COR_METAL
		)


	criar_caixa(
		"BalcaoRefeitorio",

		Vector3(
			2.0,
			1.15,
			10.0
		),

		Vector3(
			-73.2,
			0.575,
			23.0
		),

		COR_METAL,
		true
	)



func mobiliar_dormitorios() -> void:


	for z in [
		54.0,
		62.5,
		72.0,
		80.0
	]:

		criar_cama(
			Vector3(
				-72.0,
				0.0,
				z
			)
		)


		criar_armario(
			Vector3(
				-67.5,
				0.0,
				z
			),
			COR_CIANO
		)



func mobiliar_carga() -> void:


	for z in [
		-79.0,
		-69.0,
		-58.0
	]:

		criar_caixa(
			"Pallet",

			Vector3(
				3.4,
				0.22,
				4.2
			),

			Vector3(
				71.0,
				0.11,
				z
			),

			Color(
				0.18,
				0.13,
				0.08
			),
			true
		)


	for z in [
		-76.0,
		-63.0
	]:

		criar_pilha_caixas(
			Vector3(
				72.0,
				0.0,
				z
			)
		)



func mobiliar_equipamentos() -> void:


	for z in [
		-34.0,
		-26.0,
		-19.0,
		-12.0
	]:

		criar_rack(
			Vector3(
				72.5,
				0.0,
				z
			)
		)


	for z in [
		-29.0,
		-17.0
	]:

		criar_armario(
			Vector3(
				68.0,
				0.0,
				z
			),
			COR_CIANO
		)



func mobiliar_jogos() -> void:


	for z in [
		12.0,
		19.0,
		27.0,
		34.0
	]:

		criar_arcade(
			Vector3(
				73.0,
				0.0,
				z
			)
		)


	criar_mesa_holografica(
		Vector3(
			69.0,
			0.0,
			21.0
		),
		COR_ROXO
	)


	criar_sofa(
		Vector3(
			70.0,
			0.0,
			32.0
		)
	)



func mobiliar_controle() -> void:


	for z in [
		55.0,
		67.0,
		79.0
	]:

		criar_monitor(
			Vector3(
				74.5,
				4.5,
				z
			)
		)


		criar_console(
			Vector3(
				71.0,
				0.0,
				z
			),
			COR_CIANO
		)


	criar_mesa_holografica(
		Vector3(
			68.0,
			0.0,
			67.0
		),
		COR_CIANO
	)



# ============================================================
# MOBILIARIO
# ============================================================

func criar_bancada(
	pos: Vector3,
	cor: Color
) -> void:

	criar_caixa(
		"Bancada",

		Vector3(
			3.2,
			1.0,
			4.5
		),

		pos + Vector3(
			0.0,
			0.5,
			0.0
		),

		COR_METAL_ESCURO,
		true
	)


	criar_caixa(
		"BancadaTela",

		Vector3(
			0.10,
			0.7,
			1.8
		),

		pos + Vector3(
			1.62,
			1.4,
			0.0
		),

		cor,
		false,
		true,
		3.0
	)



func criar_armario(
	pos: Vector3,
	cor: Color
) -> void:

	criar_caixa(
		"Armario",

		Vector3(
			1.4,
			2.6,
			2.1
		),

		pos + Vector3(
			0.0,
			1.3,
			0.0
		),

		COR_METAL_ESCURO,
		true
	)


	criar_caixa(
		"ArmarioLed",

		Vector3(
			0.08,
			0.15,
			1.3
		),

		pos + Vector3(
			-0.72,
			1.8,
			0.0
		),

		cor,
		false,
		true,
		2.5
	)



func criar_braco_robotico(
	pos: Vector3
) -> void:

	criar_cilindro(
		"RoboBase",

		0.65,
		0.7,

		pos + Vector3(
			0.0,
			0.35,
			0.0
		),

		COR_METAL_ESCURO,
		true
	)


	criar_caixa(
		"RoboBraco",

		Vector3(
			0.45,
			2.8,
			0.45
		),

		pos + Vector3(
			0.0,
			2.0,
			0.0
		),

		COR_METAL
	)


	criar_caixa(
		"RoboAntebraco",

		Vector3(
			1.8,
			0.38,
			0.38
		),

		pos + Vector3(
			0.8,
			3.3,
			0.0
		),

		COR_METAL
	)



func criar_tanque(
	pos: Vector3
) -> void:

	criar_cilindro(
		"Tanque",

		1.25,
		4.2,

		pos + Vector3(
			0.0,
			2.1,
			0.0
		),

		COR_METAL,
		true
	)



func criar_console(
	pos: Vector3,
	cor: Color
) -> void:

	criar_caixa(
		"Console",

		Vector3(
			1.4,
			1.25,
			2.6
		),

		pos + Vector3(
			0.0,
			0.625,
			0.0
		),

		COR_METAL_ESCURO,
		true
	)


	criar_caixa(
		"ConsoleTela",

		Vector3(
			0.10,
			0.78,
			1.8
		),

		pos + Vector3(
			-0.72,
			1.45,
			0.0
		),

		cor,
		false,
		true,
		3.5
	)



func criar_mesa(
	pos: Vector3,
	cor: Color
) -> void:

	criar_caixa(
		"Mesa",

		Vector3(
			3.8,
			0.18,
			2.0
		),

		pos + Vector3(
			0.0,
			0.92,
			0.0
		),

		cor,
		true
	)


	for dz in [
		-1.4,
		1.4
	]:

		criar_caixa(
			"Banco",

			Vector3(
				3.5,
				0.42,
				0.48
			),

			pos + Vector3(
				0.0,
				0.35,
				dz
			),

			COR_METAL_ESCURO,
			true
		)



func criar_cama(
	pos: Vector3
) -> void:

	criar_caixa(
		"Cama",

		Vector3(
			3.6,
			0.42,
			1.5
		),

		pos + Vector3(
			0.0,
			0.25,
			0.0
		),

		COR_METAL_ESCURO,
		true
	)


	criar_caixa(
		"Colchao",

		Vector3(
			3.25,
			0.24,
			1.28
		),

		pos + Vector3(
			0.0,
			0.55,
			0.0
		),

		Color(
			0.18,
			0.28,
			0.34
		)
	)



func criar_pilha_caixas(
	pos: Vector3
) -> void:

	for camada in range(
		2
	):

		for linha in range(
			2
		):

			criar_caixa(
				"CaixaCarga",

				Vector3(
					1.8,
					1.15,
					1.4
				),

				pos + Vector3(
					0.0,

					0.65
					+ camada * 1.25,

					linha * 1.55
					- 0.75
				),

				Color(
					0.24,
					0.18,
					0.09
				),

				true
			)



func criar_rack(
	pos: Vector3
) -> void:

	criar_caixa(
		"Rack",

		Vector3(
			1.3,
			3.4,
			3.0
		),

		pos + Vector3(
			0.0,
			1.7,
			0.0
		),

		COR_METAL_ESCURO,
		true
	)


	for y in [
		0.8,
		1.6,
		2.4
	]:

		criar_caixa(
			"RackLed",

			Vector3(
				0.10,
				0.10,
				1.8
			),

			pos + Vector3(
				-0.66,
				y,
				0.0
			),

			COR_CIANO,
			false,
			true,
			2.0
		)



func criar_arcade(
	pos: Vector3
) -> void:

	criar_caixa(
		"Arcade",

		Vector3(
			1.5,
			2.2,
			2.2
		),

		pos + Vector3(
			0.0,
			1.1,
			0.0
		),

		Color(
			0.10,
			0.06,
			0.15
		),

		true
	)


	criar_caixa(
		"ArcadeTela",

		Vector3(
			0.10,
			0.85,
			1.35
		),

		pos + Vector3(
			-0.76,
			1.45,
			0.0
		),

		COR_ROXO,
		false,
		true,
		4.0
	)



func criar_sofa(
	pos: Vector3
) -> void:

	criar_caixa(
		"Sofa",

		Vector3(
			3.6,
			0.7,
			1.5
		),

		pos + Vector3(
			0.0,
			0.35,
			0.0
		),

		Color(
			0.16,
			0.08,
			0.22
		),

		true
	)


	criar_caixa(
		"SofaEncosto",

		Vector3(
			3.6,
			1.2,
			0.4
		),

		pos + Vector3(
			0.0,
			0.9,
			0.65
		),

		Color(
			0.16,
			0.08,
			0.22
		),

		true
	)



func criar_mesa_holografica(
	pos: Vector3,
	cor: Color
) -> void:

	criar_cilindro(
		"MesaHolografica",

		1.4,
		0.85,

		pos + Vector3(
			0.0,
			0.425,
			0.0
		),

		COR_METAL_ESCURO,
		true
	)


	criar_cilindro(
		"Holograma",

		0.85,
		0.08,

		pos + Vector3(
			0.0,
			1.05,
			0.0
		),

		cor,
		false,
		Vector3.ZERO,
		null,
		true,
		4.0
	)



func criar_monitor(
	pos: Vector3
) -> void:

	criar_caixa(
		"Monitor",

		Vector3(
			0.24,
			2.4,
			7.0
		),

		pos,

		COR_METAL_ESCURO
	)


	criar_caixa(
		"MonitorTela",

		Vector3(
			0.10,
			1.9,
			6.4
		),

		pos + Vector3(
			-0.18,
			0.0,
			0.0
		),

		COR_CIANO,
		false,
		true,
		2.3
	)



# ============================================================
# ILUMINACAO
# ============================================================

func criar_iluminacao() -> void:


	var posicoes := [

		Vector3(-36.0, 26.0, -58.0),
		Vector3(-36.0, 26.0, -28.0),

		Vector3(36.0, 26.0, -58.0),
		Vector3(36.0, 26.0, -28.0),

		Vector3(-36.0, 26.0, 28.0),
		Vector3(-36.0, 26.0, 58.0),

		Vector3(36.0, 26.0, 28.0),
		Vector3(36.0, 26.0, 58.0),

		Vector3(0.0, 27.0, -45.0),
		Vector3(0.0, 27.0, 0.0),
		Vector3(0.0, 27.0, 45.0)
	]


	for pos in posicoes:

		var luz := SpotLight3D.new()

		luz.position = pos

		luz.rotation_degrees = Vector3(
			-90.0,
			0.0,
			0.0
		)

		luz.light_color = Color(
			0.78,
			0.88,
			1.0
		)

		luz.light_energy = 9.0

		luz.spot_range = 55.0

		luz.spot_angle = 72.0

		luz.shadow_enabled = false

		add_child(
			luz
		)



# ============================================================
# TEXTO DAS SALAS
# ============================================================

func criar_texto_sala(
	texto: String,
	lado: float,
	pos: Vector3,
	cor: Color
) -> void:

	var label := Label3D.new()

	label.text = texto

	label.position = pos


	label.rotation_degrees = Vector3(
		0.0,

		90.0
		if lado < 0.0
		else -90.0,

		0.0
	)


	label.font_size = 56

	label.pixel_size = 0.012

	label.outline_size = 8

	label.modulate = cor

	label.outline_modulate = Color.BLACK


	add_child(
		label
	)



func criar_luz_sala(
	pos: Vector3,
	cor: Color
) -> void:

	var luz := OmniLight3D.new()

	luz.position = pos

	luz.light_color = cor

	luz.light_energy = 2.8

	luz.omni_range = 12.0

	luz.shadow_enabled = false

	add_child(
		luz
	)



# ============================================================
# ============================================================
# FERRAMENTAS DE CONSTRUCAO
# ============================================================
# ============================================================

func criar_caixa(
	nome: String,
	tamanho: Vector3,
	pos: Vector3,
	cor: Color,
	colisao: bool = false,
	emissivo: bool = false,
	intensidade: float = 1.0,
	rotacao: Vector3 = Vector3.ZERO,
	pai: Node3D = null,
	metallic: float = 0.42,
	roughness: float = 0.50
) -> Node3D:


	var destino: Node3D = self


	if pai != null:
		destino = pai


	var material := StandardMaterial3D.new()

	material.albedo_color = cor

	material.metallic = metallic

	material.roughness = roughness


	if emissivo:

		material.emission_enabled = true

		material.emission = cor

		material.emission_energy_multiplier = intensidade


	if colisao:

		var corpo := StaticBody3D.new()

		corpo.name = nome

		corpo.position = pos

		corpo.rotation_degrees = rotacao

		corpo.collision_layer = 1

		corpo.collision_mask = 1


		destino.add_child(
			corpo
		)


		var visual := MeshInstance3D.new()

		var mesh := BoxMesh.new()

		mesh.size = tamanho

		visual.mesh = mesh

		visual.material_override = material


		corpo.add_child(
			visual
		)


		var shape := BoxShape3D.new()

		shape.size = tamanho


		var collision := CollisionShape3D.new()

		collision.shape = shape


		corpo.add_child(
			collision
		)


		return corpo


	else:

		var visual := MeshInstance3D.new()

		visual.name = nome

		visual.position = pos

		visual.rotation_degrees = rotacao


		var mesh := BoxMesh.new()

		mesh.size = tamanho


		visual.mesh = mesh

		visual.material_override = material


		destino.add_child(
			visual
		)


		return visual



# ============================================================
# CILINDRO
# ============================================================

func criar_cilindro(
	nome: String,
	raio: float,
	altura: float,
	pos: Vector3,
	cor: Color,
	colisao: bool = false,
	rotacao: Vector3 = Vector3.ZERO,
	pai: Node3D = null,
	emissivo: bool = false,
	intensidade: float = 1.0
) -> Node3D:


	var destino: Node3D = self


	if pai != null:
		destino = pai


	var material := StandardMaterial3D.new()

	material.albedo_color = cor

	material.metallic = 0.68

	material.roughness = 0.28


	if emissivo:

		material.emission_enabled = true

		material.emission = cor

		material.emission_energy_multiplier = intensidade


	var mesh := CylinderMesh.new()

	mesh.top_radius = raio

	mesh.bottom_radius = raio

	mesh.height = altura

	mesh.radial_segments = 12


	if colisao:

		var corpo := StaticBody3D.new()

		corpo.name = nome

		corpo.position = pos

		corpo.rotation_degrees = rotacao

		corpo.collision_layer = 1

		corpo.collision_mask = 1


		destino.add_child(
			corpo
		)


		var visual := MeshInstance3D.new()

		visual.mesh = mesh

		visual.material_override = material


		corpo.add_child(
			visual
		)


		var shape := CylinderShape3D.new()

		shape.radius = raio

		shape.height = altura


		var collision := CollisionShape3D.new()

		collision.shape = shape


		corpo.add_child(
			collision
		)


		return corpo


	else:

		var visual := MeshInstance3D.new()

		visual.name = nome

		visual.position = pos

		visual.rotation_degrees = rotacao

		visual.mesh = mesh

		visual.material_override = material


		destino.add_child(
			visual
		)


		return visual



# ============================================================
# ESFERA
# ============================================================

func criar_esfera(
	nome: String,
	pos: Vector3,
	escala: Vector3,
	cor: Color,
	pai: Node3D,
	emissivo: bool = false
) -> Node3D:


	var visual := MeshInstance3D.new()

	visual.name = nome

	visual.position = pos

	visual.scale = escala


	var mesh := SphereMesh.new()

	mesh.radius = 1.0

	mesh.height = 2.0

	mesh.radial_segments = 16

	mesh.rings = 8


	visual.mesh = mesh


	var material := StandardMaterial3D.new()

	material.albedo_color = cor

	material.metallic = 0.75

	material.roughness = 0.12


	if emissivo:

		material.emission_enabled = true

		material.emission = cor

		material.emission_energy_multiplier = 3.0


	visual.material_override = material


	pai.add_child(
		visual
	)


	return visual



# ============================================================
# COLISAO INVISIVEL PARA NAVES DECORATIVAS
# ============================================================

func criar_colisao_caixa(
	nome: String,
	tamanho: Vector3,
	pos: Vector3,
	rotacao: Vector3,
	pai: Node3D
) -> void:


	var corpo := StaticBody3D.new()

	corpo.name = nome

	corpo.position = pos

	corpo.rotation_degrees = rotacao

	corpo.collision_layer = 1

	corpo.collision_mask = 1


	pai.add_child(
		corpo
	)


	var shape := BoxShape3D.new()

	shape.size = tamanho


	var collision := CollisionShape3D.new()

	collision.shape = shape


	corpo.add_child(
		collision
	)
