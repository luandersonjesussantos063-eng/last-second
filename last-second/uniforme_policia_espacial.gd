extends Node


# ============================================================
# LAST SECOND
# UNIFORME DA POLICIA INTERPLANETARIA v1.0
#
# Este script NAO altera:
# - movimento
# - camera
# - animacao de caminhada
# - colisao
# - sistema de entrar/descer da nave
#
# Ele apenas equipa o PlayerOnFoot com:
# - capacete espacial
# - viseira
# - armadura peitoral
# - ombreiras
# - protecao de bracos
# - protecao de pernas
# - botas
# - cinto tatico
# - mochila de suporte
# - luzes ciano
# - identificacao policial
# ============================================================


var personagem: CharacterBody3D = null
var visual: Node3D = null

var perna_l: Node3D = null
var perna_r: Node3D = null

var braco_l: Node3D = null
var braco_r: Node3D = null


# ============================================================
# MATERIAIS
# ============================================================

var mat_traje: StandardMaterial3D
var mat_armadura: StandardMaterial3D
var mat_armadura_azul: StandardMaterial3D

var mat_metal: StandardMaterial3D

var mat_ciano: StandardMaterial3D
var mat_branco: StandardMaterial3D

var mat_visera: StandardMaterial3D
var mat_vermelho: StandardMaterial3D


# ============================================================
# READY
# ============================================================

func _ready() -> void:

	process_mode = Node.PROCESS_MODE_ALWAYS


	# O OnFootSystem cria o personagem durante o inicio.
	# Esperamos alguns frames.

	await get_tree().process_frame
	await get_tree().process_frame
	await get_tree().physics_frame


	if !localizar_personagem():

		push_warning(
			"UNIFORME: PlayerOnFoot nao encontrado."
		)

		return


	criar_materiais()

	preparar_corpo_original()

	criar_uniforme()


	print(
		"=============================================="
	)

	print(
		"POLICIA INTERPLANETARIA // TRAJE ESPACIAL"
	)

	print(
		"UNIFORME TATICO // ONLINE"
	)

	print(
		"=============================================="
	)



# ============================================================
# LOCALIZAR PERSONAGEM
# ============================================================

func localizar_personagem() -> bool:

	var cena := get_tree().current_scene


	if cena == null:

		return false


	var encontrado := cena.find_child(
		"PlayerOnFoot",
		true,
		false
	)


	if encontrado is CharacterBody3D:

		personagem = encontrado


	if personagem == null:

		return false


	visual = personagem.get_node_or_null(
		"Visual"
	) as Node3D


	if visual == null:

		return false


	perna_l = visual.get_node_or_null(
		"PernaL_Pivo"
	) as Node3D


	perna_r = visual.get_node_or_null(
		"PernaR_Pivo"
	) as Node3D


	braco_l = visual.get_node_or_null(
		"BracoL_Pivo"
	) as Node3D


	braco_r = visual.get_node_or_null(
		"BracoR_Pivo"
	) as Node3D


	return true



# ============================================================
# MATERIAIS
# ============================================================

func criar_materiais() -> void:


	# ========================================================
	# TECIDO DO TRAJE
	# ========================================================

	mat_traje = StandardMaterial3D.new()

	mat_traje.albedo_color = Color(
		0.018,
		0.028,
		0.050
	)

	mat_traje.metallic = 0.15

	mat_traje.roughness = 0.72


	# ========================================================
	# ARMADURA PRETA
	# ========================================================

	mat_armadura = StandardMaterial3D.new()

	mat_armadura.albedo_color = Color(
		0.025,
		0.040,
		0.065
	)

	mat_armadura.metallic = 0.70

	mat_armadura.roughness = 0.30


	# ========================================================
	# ARMADURA AZUL
	# ========================================================

	mat_armadura_azul = StandardMaterial3D.new()

	mat_armadura_azul.albedo_color = Color(
		0.025,
		0.080,
		0.145
	)

	mat_armadura_azul.metallic = 0.62

	mat_armadura_azul.roughness = 0.30


	# ========================================================
	# METAL
	# ========================================================

	mat_metal = StandardMaterial3D.new()

	mat_metal.albedo_color = Color(
		0.18,
		0.22,
		0.28
	)

	mat_metal.metallic = 0.82

	mat_metal.roughness = 0.25


	# ========================================================
	# CIANO EMISSIVO
	# ========================================================

	mat_ciano = StandardMaterial3D.new()

	mat_ciano.albedo_color = Color(
		0.0,
		0.78,
		1.0
	)

	mat_ciano.emission_enabled = true

	mat_ciano.emission = Color(
		0.0,
		0.65,
		1.0
	)

	mat_ciano.emission_energy_multiplier = 5.0

	mat_ciano.metallic = 0.22

	mat_ciano.roughness = 0.18


	# ========================================================
	# BRANCO
	# ========================================================

	mat_branco = StandardMaterial3D.new()

	mat_branco.albedo_color = Color(
		0.72,
		0.82,
		0.90
	)

	mat_branco.metallic = 0.45

	mat_branco.roughness = 0.30


	# ========================================================
	# VISEIRA
	# ========================================================

	mat_visera = StandardMaterial3D.new()

	mat_visera.albedo_color = Color(
		0.005,
		0.055,
		0.080
	)

	mat_visera.metallic = 0.82

	mat_visera.roughness = 0.08

	mat_visera.emission_enabled = true

	mat_visera.emission = Color(
		0.0,
		0.16,
		0.25
	)

	mat_visera.emission_energy_multiplier = 1.8


	# ========================================================
	# VERMELHO
	# ========================================================

	mat_vermelho = StandardMaterial3D.new()

	mat_vermelho.albedo_color = Color(
		1.0,
		0.025,
		0.015
	)

	mat_vermelho.emission_enabled = true

	mat_vermelho.emission = Color(
		1.0,
		0.01,
		0.0
	)

	mat_vermelho.emission_energy_multiplier = 4.0



# ============================================================
# PREPARAR BONECO ORIGINAL
# ============================================================

func preparar_corpo_original() -> void:


	# ========================================================
	# TRANSFORMA O CORPO ANTIGO EM ROUPA INTERNA
	# ========================================================

	for nome in [
		"Tronco",
		"Colete"
	]:

		var parte := visual.get_node_or_null(
			nome
		) as MeshInstance3D


		if parte != null:

			parte.material_override = mat_traje


	# ========================================================
	# ESCONDE CABECA E VISEIRA ANTIGAS
	#
	# O capacete novo vai substituir.
	# ========================================================

	var cabeca := visual.get_node_or_null(
		"Cabeca"
	)


	if cabeca != null:

		cabeca.visible = false


	var viseira_antiga := visual.get_node_or_null(
		"Viseira"
	)


	if viseira_antiga != null:

		viseira_antiga.visible = false


	# ========================================================
	# FAIXA ANTIGA
	# ========================================================

	var faixa := visual.get_node_or_null(
		"FaixaPolicial"
	)


	if faixa != null:

		faixa.visible = false



# ============================================================
# CRIAR UNIFORME COMPLETO
# ============================================================

func criar_uniforme() -> void:


	if visual.has_node(
		"TrajePoliciaInterplanetaria"
	):

		return


	var traje := Node3D.new()

	traje.name = "TrajePoliciaInterplanetaria"


	visual.add_child(
		traje
	)


	# ========================================================
	# TORSO / COLETE ESPACIAL
	# ========================================================

	criar_caixa(
		traje,
		"ArmaduraTorso",

		Vector3(
			1.04,
			0.72,
			0.50
		),

		Vector3(
			0.0,
			1.14,
			0.0
		),

		mat_armadura
	)


	# ========================================================
	# PLACA PEITORAL FRONTAL
	#
	# Frente do personagem = -Z
	# ========================================================

	criar_caixa(
		traje,
		"PlacaPeitoral",

		Vector3(
			0.84,
			0.50,
			0.11
		),

		Vector3(
			0.0,
			1.18,
			-0.305
		),

		mat_armadura_azul
	)


	# ========================================================
	# PEITORAL SUPERIOR
	# ========================================================

	criar_caixa(
		traje,
		"PeitoralSuperior",

		Vector3(
			0.72,
			0.15,
			0.12
		),

		Vector3(
			0.0,
			1.48,
			-0.31
		),

		mat_metal
	)


	# ========================================================
	# LUZ PEITORAL
	# ========================================================

	criar_caixa(
		traje,
		"LuzPeitoral",

		Vector3(
			0.58,
			0.045,
			0.035
		),

		Vector3(
			0.0,
			1.43,
			-0.385
		),

		mat_ciano
	)


	# ========================================================
	# ABDOMEN PROTEGIDO
	# ========================================================

	for y in [
		0.91,
		0.82
	]:

		criar_caixa(
			traje,
			"PlacaAbdomen",

			Vector3(
				0.72,
				0.065,
				0.42
			),

			Vector3(
				0.0,
				y,
				0.0
			),

			mat_armadura
		)


	# ========================================================
	# GOLA ESPACIAL
	# ========================================================

	criar_cilindro(
		traje,
		"Gola",

		0.34,
		0.16,

		Vector3(
			0.0,
			1.55,
			0.0
		),

		mat_metal
	)


	# ========================================================
	# CAPACETE
	# ========================================================

	criar_esfera(
		traje,
		"Capacete",

		Vector3(
			0.0,
			1.78,
			0.0
		),

		Vector3(
			0.40,
			0.39,
			0.40
		),

		mat_armadura
	)


	# ========================================================
	# PARTE SUPERIOR DO CAPACETE
	# ========================================================

	criar_caixa(
		traje,
		"TopoCapacete",

		Vector3(
			0.50,
			0.12,
			0.48
		),

		Vector3(
			0.0,
			2.06,
			0.02
		),

		mat_armadura_azul
	)


	# ========================================================
	# VISEIRA GRANDE
	# ========================================================

	criar_caixa(
		traje,
		"ViseiraEspacial",

		Vector3(
			0.56,
			0.22,
			0.055
		),

		Vector3(
			0.0,
			1.82,
			-0.382
		),

		mat_visera
	)


	# ========================================================
	# LINHA CIANO DA VISEIRA
	# ========================================================

	criar_caixa(
		traje,
		"LuzViseira",

		Vector3(
			0.53,
			0.035,
			0.025
		),

		Vector3(
			0.0,
			1.735,
			-0.422
		),

		mat_ciano
	)


	# ========================================================
	# MODULOS LATERAIS CAPACETE
	# ========================================================

	for x in [
		-0.405,
		0.405
	]:

		criar_caixa(
			traje,
			"ModuloCapacete",

			Vector3(
				0.12,
				0.28,
				0.22
			),

			Vector3(
				x,
				1.80,
				0.0
			),

			mat_metal
		)


		criar_caixa(
			traje,
			"LuzModuloCapacete",

			Vector3(
				0.025,
				0.18,
				0.13
			),

			Vector3(
				x
				+ (
					-0.066
					if x < 0.0
					else 0.066
				),

				1.80,
				-0.01
			),

			mat_ciano
		)


	# ========================================================
	# LUZ TRASEIRA DO CAPACETE
	# ========================================================

	criar_caixa(
		traje,
		"LuzTraseiraCapacete",

		Vector3(
			0.36,
			0.05,
			0.025
		),

		Vector3(
			0.0,
			1.82,
			0.405
		),

		mat_ciano
	)


	# ========================================================
	# OMBREIRAS
	# ========================================================

	criar_armadura_braco(
		braco_l,
		-1.0,
		"L"
	)


	criar_armadura_braco(
		braco_r,
		1.0,
		"R"
	)


	# ========================================================
	# PERNAS
	# ========================================================

	criar_armadura_perna(
		perna_l,
		"L"
	)


	criar_armadura_perna(
		perna_r,
		"R"
	)


	# ========================================================
	# CINTO TATICO
	# ========================================================

	criar_caixa(
		traje,
		"Cinto",

		Vector3(
			1.02,
			0.17,
			0.49
		),

		Vector3(
			0.0,
			0.73,
			0.0
		),

		mat_armadura
	)


	# ========================================================
	# FIVELA CENTRAL
	# ========================================================

	criar_caixa(
		traje,
		"Fivela",

		Vector3(
			0.21,
			0.18,
			0.08
		),

		Vector3(
			0.0,
			0.73,
			-0.295
		),

		mat_metal
	)


	criar_caixa(
		traje,
		"LuzFivela",

		Vector3(
			0.08,
			0.10,
			0.025
		),

		Vector3(
			0.0,
			0.73,
			-0.345
		),

		mat_ciano
	)


	# ========================================================
	# BOLSOS DO CINTO
	# ========================================================

	for x in [
		-0.40,
		-0.22,
		0.22,
		0.40
	]:

		criar_caixa(
			traje,
			"BolsoTatico",

			Vector3(
				0.16,
				0.21,
				0.18
			),

			Vector3(
				x,
				0.70,
				-0.27
			),

			mat_armadura
		)


	# ========================================================
	# MOCHILA DE SUPORTE DE VIDA
	# ========================================================

	criar_caixa(
		traje,
		"MochilaOxigenio",

		Vector3(
			0.74,
			0.76,
			0.30
		),

		Vector3(
			0.0,
			1.16,
			0.34
		),

		mat_armadura
	)


	# ========================================================
	# MODULOS MOCHILA
	# ========================================================

	for x in [
		-0.25,
		0.25
	]:

		criar_cilindro(
			traje,
			"TanqueSuporte",

			0.10,
			0.55,

			Vector3(
				x,
				1.17,
				0.53
			),

			mat_metal
		)


	# ========================================================
	# LUZ TRASEIRA
	# ========================================================

	criar_caixa(
		traje,
		"LuzMochila",

		Vector3(
			0.48,
			0.055,
			0.035
		),

		Vector3(
			0.0,
			1.38,
			0.505
		),

		mat_ciano
	)


	# ========================================================
	# IDENTIFICACAO FRONTAL
	# ========================================================

	criar_texto(
		traje,

		"POLICIA\nINTERPLANETARIA",

		Vector3(
			0.0,
			1.25,
			-0.375
		),

		Vector3(
			0.0,
			180.0,
			0.0
		),

		24,
		0.0035
	)


	# ========================================================
	# IDENTIFICACAO TRASEIRA
	#
	# Essa e a que mais veremos na camera em terceira pessoa.
	# ========================================================

	criar_texto(
		traje,

		"POLICIA\nINTERPLANETARIA",

		Vector3(
			0.0,
			1.23,
			0.505
		),

		Vector3.ZERO,

		26,
		0.0035
	)


	# ========================================================
	# EMBLEMA PEITORAL
	# ========================================================

	criar_emblema(
		traje,

		Vector3(
			0.0,
			1.04,
			-0.378
		),

		true
	)


	# ========================================================
	# EMBLEMA TRASEIRO
	# ========================================================

	criar_emblema(
		traje,

		Vector3(
			0.0,
			1.04,
			0.505
		),

		false
	)



# ============================================================
# ARMADURA DOS BRACOS
# ============================================================

func criar_armadura_braco(
	pivo: Node3D,
	lado: float,
	sufixo: String
) -> void:


	if pivo == null:

		return


	# ========================================================
	# OMBREIRA
	# ========================================================

	criar_caixa(
		pivo,
		"Ombreira_" + sufixo,

		Vector3(
			0.38,
			0.25,
			0.42
		),

		Vector3(
			lado * 0.045,
			-0.08,
			0.0
		),

		mat_armadura_azul
	)


	# ========================================================
	# PLACA EXTERNA OMBRO
	# ========================================================

	criar_caixa(
		pivo,
		"PlacaOmbro_" + sufixo,

		Vector3(
			0.09,
			0.27,
			0.30
		),

		Vector3(
			lado * 0.22,
			-0.10,
			0.0
		),

		mat_branco
	)


	# ========================================================
	# LED DO OMBRO
	# ========================================================

	criar_caixa(
		pivo,
		"LedOmbro_" + sufixo,

		Vector3(
			0.08,
			0.055,
			0.26
		),

		Vector3(
			lado * 0.245,
			-0.01,
			0.0
		),

		mat_ciano
	)


	# ========================================================
	# PROTECAO DO ANTEBRACO
	# ========================================================

	criar_caixa(
		pivo,
		"Antebraco_" + sufixo,

		Vector3(
			0.31,
			0.31,
			0.35
		),

		Vector3(
			0.0,
			-0.49,
			0.0
		),

		mat_armadura
	)


	# ========================================================
	# LUZ DO PULSO
	# ========================================================

	criar_caixa(
		pivo,
		"PulsoLed_" + sufixo,

		Vector3(
			0.32,
			0.055,
			0.37
		),

		Vector3(
			0.0,
			-0.61,
			0.0
		),

		mat_ciano
	)


	# ========================================================
	# LUZ DE EMERGENCIA NO OMBRO ESQUERDO
	# ========================================================

	if lado < 0.0:

		criar_caixa(
			pivo,
			"LuzEmergencia",

			Vector3(
				0.10,
				0.10,
				0.10
			),

			Vector3(
				-0.18,
				0.06,
				0.0
			),

			mat_vermelho
		)



# ============================================================
# ARMADURA DAS PERNAS
# ============================================================

func criar_armadura_perna(
	pivo: Node3D,
	sufixo: String
) -> void:


	if pivo == null:

		return


	# ========================================================
	# COXA
	# ========================================================

	criar_caixa(
		pivo,
		"Coxa_" + sufixo,

		Vector3(
			0.32,
			0.30,
			0.33
		),

		Vector3(
			0.0,
			-0.20,
			0.0
		),

		mat_armadura_azul
	)


	# ========================================================
	# JOELHEIRA
	# ========================================================

	criar_caixa(
		pivo,
		"Joelheira_" + sufixo,

		Vector3(
			0.34,
			0.20,
			0.12
		),

		Vector3(
			0.0,
			-0.43,
			-0.17
		),

		mat_armadura
	)


	# ========================================================
	# CANELEIRA
	# ========================================================

	criar_caixa(
		pivo,
		"Caneleira_" + sufixo,

		Vector3(
			0.31,
			0.30,
			0.12
		),

		Vector3(
			0.0,
			-0.59,
			-0.17
		),

		mat_armadura
	)


	# ========================================================
	# LED DA CANELA
	# ========================================================

	criar_caixa(
		pivo,
		"LedPerna_" + sufixo,

		Vector3(
			0.22,
			0.045,
			0.025
		),

		Vector3(
			0.0,
			-0.60,
			-0.245
		),

		mat_ciano
	)


	# ========================================================
	# BOTA REFORCADA
	# ========================================================

	criar_caixa(
		pivo,
		"BotaEspacial_" + sufixo,

		Vector3(
			0.38,
			0.22,
			0.52
		),

		Vector3(
			0.0,
			-0.76,
			-0.11
		),

		mat_armadura
	)


	# ========================================================
	# LUZ DA BOTA
	# ========================================================

	criar_caixa(
		pivo,
		"LuzBota_" + sufixo,

		Vector3(
			0.25,
			0.04,
			0.035
		),

		Vector3(
			0.0,
			-0.75,
			-0.385
		),

		mat_ciano
	)



# ============================================================
# EMBLEMA DA POLICIA INTERPLANETARIA
#
# Disco + faixa orbital ciano
# ============================================================

func criar_emblema(
	pai: Node3D,
	pos: Vector3,
	frontal: bool
) -> void:


	var rotacao := Vector3(
		90.0,
		0.0,
		0.0
	)


	# ========================================================
	# DISCO
	# ========================================================

	var disco := criar_cilindro(
		pai,
		"Emblema",

		0.12,
		0.035,

		pos,

		mat_branco,

		rotacao
	)


	# ========================================================
	# ORBITA CIANO
	# ========================================================

	var z_offset := (
		-0.035
		if frontal
		else 0.035
	)


	criar_caixa(
		pai,
		"OrbitaEmblema",

		Vector3(
			0.29,
			0.035,
			0.035
		),

		pos + Vector3(
			0.0,
			0.0,
			z_offset
		),

		mat_ciano,

		Vector3(
			0.0,
			0.0,
			-22.0
		)
	)



# ============================================================
# CRIAR CAIXA
# ============================================================

func criar_caixa(
	pai: Node3D,
	nome: String,
	tamanho: Vector3,
	posicao: Vector3,
	material: Material,
	rotacao: Vector3 = Vector3.ZERO
) -> MeshInstance3D:


	var objeto := MeshInstance3D.new()

	objeto.name = nome

	objeto.position = posicao

	objeto.rotation_degrees = rotacao


	var mesh := BoxMesh.new()

	mesh.size = tamanho


	objeto.mesh = mesh

	objeto.material_override = material


	pai.add_child(
		objeto
	)


	return objeto



# ============================================================
# CRIAR ESFERA
# ============================================================

func criar_esfera(
	pai: Node3D,
	nome: String,
	posicao: Vector3,
	escala: Vector3,
	material: Material
) -> MeshInstance3D:


	var objeto := MeshInstance3D.new()

	objeto.name = nome

	objeto.position = posicao

	objeto.scale = escala


	var mesh := SphereMesh.new()

	mesh.radius = 1.0

	mesh.height = 2.0

	mesh.radial_segments = 16

	mesh.rings = 8


	objeto.mesh = mesh

	objeto.material_override = material


	pai.add_child(
		objeto
	)


	return objeto



# ============================================================
# CRIAR CILINDRO
# ============================================================

func criar_cilindro(
	pai: Node3D,
	nome: String,
	raio: float,
	altura: float,
	posicao: Vector3,
	material: Material,
	rotacao: Vector3 = Vector3.ZERO
) -> MeshInstance3D:


	var objeto := MeshInstance3D.new()

	objeto.name = nome

	objeto.position = posicao

	objeto.rotation_degrees = rotacao


	var mesh := CylinderMesh.new()

	mesh.top_radius = raio

	mesh.bottom_radius = raio

	mesh.height = altura

	mesh.radial_segments = 12


	objeto.mesh = mesh

	objeto.material_override = material


	pai.add_child(
		objeto
	)


	return objeto



# ============================================================
# TEXTO 3D
# ============================================================

func criar_texto(
	pai: Node3D,
	texto: String,
	posicao: Vector3,
	rotacao: Vector3,
	tamanho_fonte: int,
	tamanho_pixel: float
) -> Label3D:


	var label := Label3D.new()

	label.text = texto

	label.position = posicao

	label.rotation_degrees = rotacao

	label.font_size = tamanho_fonte

	label.pixel_size = tamanho_pixel

	label.outline_size = 7

	label.modulate = Color(
		0.74,
		0.92,
		1.0
	)

	label.outline_modulate = Color(
		0.0,
		0.0,
		0.0,
		0.95
	)

	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER


	pai.add_child(
		label
	)


	return label
