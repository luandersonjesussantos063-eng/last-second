extends Node


# ============================================================
# LAST SECOND
# P-01 // MODELO EXTERNO v1.0
#
# Cria o casco externo da nave do jogador.
#
# - aparece quando o policial esta a pe
# - desaparece quando estamos pilotando
# - acompanha a posicao real do Player
# - cabe dentro da colisao existente da P-01
# - otimizado para PC e Android
# ============================================================


# ============================================================
# CONFIGURACAO
# ============================================================

@export_category("P-01")

@export var mostrar_apenas_a_pe: bool = true

@export var offset_modelo := Vector3(
	0.0,
	-0.70,
	0.0
)


# ============================================================
# REFERENCIAS
# ============================================================

var cena: Node = null

var player: Node3D = null

var mobile_controls: Node = null

var player_on_foot: Node3D = null

var nave_exterior: Node3D = null


# ============================================================
# MATERIAIS
# ============================================================

var mat_casco: StandardMaterial3D = null

var mat_casco_claro: StandardMaterial3D = null

var mat_escuro: StandardMaterial3D = null

var mat_cockpit: StandardMaterial3D = null

var mat_ciano: StandardMaterial3D = null

var mat_vermelho: StandardMaterial3D = null

var mat_branco: StandardMaterial3D = null


# ============================================================
# READY
# ============================================================

func _ready() -> void:

	process_mode = Node.PROCESS_MODE_ALWAYS


	await get_tree().process_frame

	await get_tree().process_frame

	await get_tree().physics_frame


	localizar_sistemas()


	if player == null:

		push_error(
			"P-01 EXTERIOR: Player nao encontrado."
		)

		return


	criar_materiais()

	criar_nave_externa()

	atualizar_visibilidade()


	print(
		"========================================"
	)

	print(
		"P-01 // MODELO EXTERNO ONLINE"
	)

	print(
		"CASCO POLICIA INTERPLANETARIA"
	)

	print(
		"========================================"
	)



# ============================================================
# LOCALIZAR SISTEMAS
# ============================================================

func localizar_sistemas() -> void:

	cena = get_tree().current_scene


	if cena == null:

		return


	# ========================================================
	# PLAYER / NAVE REAL
	# ========================================================

	player = cena.get_node_or_null(
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


	# ========================================================
	# MOBILE CONTROLS
	# ========================================================

	mobile_controls = cena.get_node_or_null(
		"MobileControls"
	)


	if mobile_controls == null:

		mobile_controls = cena.find_child(
			"MobileControls",
			true,
			false
		)


	# ========================================================
	# PERSONAGEM A PE
	# ========================================================

	var pe := cena.find_child(
		"PlayerOnFoot",
		true,
		false
	)


	if pe is Node3D:

		player_on_foot = pe



# ============================================================
# PROCESS
# ============================================================

func _process(
	_delta: float
) -> void:

	if player == null:

		localizar_sistemas()


	if nave_exterior == null:

		return


	atualizar_visibilidade()



# ============================================================
# VISIBILIDADE
# ============================================================

func atualizar_visibilidade() -> void:


	if nave_exterior == null:

		return


	if !mostrar_apenas_a_pe:

		nave_exterior.visible = true

		return


	nave_exterior.visible = esta_a_pe()



# ============================================================
# ESTA A PE?
# ============================================================

func esta_a_pe() -> bool:


	# ========================================================
	# PRIMEIRA OPCAO:
	# MOBILE CONTROLS
	# ========================================================

	if mobile_controls != null:

		var valor: Variant = mobile_controls.get(
			"modo_a_pe"
		)


		if valor != null:

			return bool(
				valor
			)


	# ========================================================
	# FALLBACK:
	# PLAYER ON FOOT VISIVEL
	# ========================================================

	if player_on_foot != null:

		return player_on_foot.visible


	return false



# ============================================================
# MATERIAIS
# ============================================================

func criar_materiais() -> void:


	# ========================================================
	# CASCO PRINCIPAL
	# ========================================================

	mat_casco = StandardMaterial3D.new()

	mat_casco.albedo_color = Color(
		0.055,
		0.075,
		0.11
	)

	mat_casco.metallic = 0.78

	mat_casco.roughness = 0.28


	# ========================================================
	# CASCO CLARO
	# ========================================================

	mat_casco_claro = StandardMaterial3D.new()

	mat_casco_claro.albedo_color = Color(
		0.20,
		0.25,
		0.32
	)

	mat_casco_claro.metallic = 0.72

	mat_casco_claro.roughness = 0.27


	# ========================================================
	# PARTES ESCURAS
	# ========================================================

	mat_escuro = StandardMaterial3D.new()

	mat_escuro.albedo_color = Color(
		0.012,
		0.020,
		0.032
	)

	mat_escuro.metallic = 0.68

	mat_escuro.roughness = 0.30


	# ========================================================
	# COCKPIT
	# ========================================================

	mat_cockpit = StandardMaterial3D.new()

	mat_cockpit.albedo_color = Color(
		0.005,
		0.055,
		0.080
	)

	mat_cockpit.metallic = 0.82

	mat_cockpit.roughness = 0.08

	mat_cockpit.emission_enabled = true

	mat_cockpit.emission = Color(
		0.00,
		0.10,
		0.16
	)

	mat_cockpit.emission_energy_multiplier = 1.2


	# ========================================================
	# CIANO
	# ========================================================

	mat_ciano = criar_material_emissivo(
		Color(
			0.0,
			0.78,
			1.0
		),

		6.0
	)


	# ========================================================
	# VERMELHO
	# ========================================================

	mat_vermelho = criar_material_emissivo(
		Color(
			1.0,
			0.03,
			0.01
		),

		5.0
	)


	# ========================================================
	# BRANCO
	# ========================================================

	mat_branco = StandardMaterial3D.new()

	mat_branco.albedo_color = Color(
		0.72,
		0.82,
		0.90
	)

	mat_branco.metallic = 0.48

	mat_branco.roughness = 0.28



# ============================================================
# CRIAR NAVE
# ============================================================

func criar_nave_externa() -> void:


	if player == null:

		return


	if player.has_node(
		"P01Exterior"
	):

		nave_exterior = player.get_node(
			"P01Exterior"
		) as Node3D

		return


	nave_exterior = Node3D.new()

	nave_exterior.name = "P01Exterior"

	nave_exterior.position = offset_modelo


	player.add_child(
		nave_exterior
	)


	# ========================================================
	# FUSELAGEM CENTRAL
	# ========================================================

	criar_caixa(
		"FuselagemCentral",

		Vector3(
			3.20,
			1.65,
			8.60
		),

		Vector3(
			0.0,
			0.05,
			0.50
		),

		mat_casco
	)


	# ========================================================
	# PARTE INFERIOR
	# ========================================================

	criar_caixa(
		"Barriga",

		Vector3(
			3.70,
			0.75,
			7.00
		),

		Vector3(
			0.0,
			-0.75,
			0.60
		),

		mat_escuro
	)


	# ========================================================
	# DORSO
	# ========================================================

	criar_caixa(
		"Dorso",

		Vector3(
			2.40,
			0.60,
			5.00
		),

		Vector3(
			0.0,
			1.00,
			1.10
		),

		mat_casco_claro
	)


	# ========================================================
	# NARIZ
	# ========================================================

	criar_caixa(
		"Nariz01",

		Vector3(
			2.60,
			1.20,
			3.20
		),

		Vector3(
			0.0,
			0.0,
			-4.75
		),

		mat_casco_claro,

		Vector3(
			7.0,
			0.0,
			0.0
		)
	)


	criar_caixa(
		"Nariz02",

		Vector3(
			1.55,
			0.70,
			2.20
		),

		Vector3(
			0.0,
			-0.05,
			-6.20
		),

		mat_casco,

		Vector3(
			10.0,
			0.0,
			0.0
		)
	)


	# ========================================================
	# COCKPIT
	# ========================================================

	criar_esfera(
		"Cockpit",

		Vector3(
			0.0,
			1.05,
			-2.60
		),

		Vector3(
			1.40,
			0.62,
			1.75
		),

		mat_cockpit
	)


	# ========================================================
	# MOLDURA DO COCKPIT
	# ========================================================

	criar_caixa(
		"MolduraCockpitSuperior",

		Vector3(
			1.95,
			0.10,
			2.40
		),

		Vector3(
			0.0,
			1.56,
			-2.45
		),

		mat_casco_claro
	)


	# ========================================================
	# LUZ DO COCKPIT
	# ========================================================

	criar_caixa(
		"LuzCockpit",

		Vector3(
			1.60,
			0.045,
			0.05
		),

		Vector3(
			0.0,
			1.28,
			-3.90
		),

		mat_ciano
	)


	# ========================================================
	# ASAS PRINCIPAIS
	# ========================================================

	criar_caixa(
		"AsaEsquerda",

		Vector3(
			4.70,
			0.28,
			4.20
		),

		Vector3(
			-3.20,
			-0.20,
			0.70
		),

		mat_casco,

		Vector3(
			0.0,
			-12.0,
			-3.0
		)
	)


	criar_caixa(
		"AsaDireita",

		Vector3(
			4.70,
			0.28,
			4.20
		),

		Vector3(
			3.20,
			-0.20,
			0.70
		),

		mat_casco,

		Vector3(
			0.0,
			12.0,
			3.0
		)
	)


	# ========================================================
	# PONTAS DAS ASAS
	# ========================================================

	criar_caixa(
		"PontaAsaE",

		Vector3(
			1.20,
			0.38,
			2.80
		),

		Vector3(
			-5.55,
			-0.12,
			1.40
		),

		mat_escuro,

		Vector3(
			0.0,
			-12.0,
			0.0
		)
	)


	criar_caixa(
		"PontaAsaD",

		Vector3(
			1.20,
			0.38,
			2.80
		),

		Vector3(
			5.55,
			-0.12,
			1.40
		),

		mat_escuro,

		Vector3(
			0.0,
			12.0,
			0.0
		)
	)


	# ========================================================
	# LUZES NAS ASAS
	# ========================================================

	criar_caixa(
		"LuzAsaE",

		Vector3(
			0.15,
			0.12,
			2.20
		),

		Vector3(
			-6.10,
			0.02,
			1.30
		),

		mat_ciano,

		Vector3(
			0.0,
			-12.0,
			0.0
		)
	)


	criar_caixa(
		"LuzAsaD",

		Vector3(
			0.15,
			0.12,
			2.20
		),

		Vector3(
			6.10,
			0.02,
			1.30
		),

		mat_ciano,

		Vector3(
			0.0,
			12.0,
			0.0
		)
	)


	# ========================================================
	# MOTORES LATERAIS
	# ========================================================

	for x in [
		-1.65,
		1.65
	]:

		criar_cilindro(
			"Motor",

			0.72,
			2.80,

			Vector3(
				x,
				-0.15,
				4.20
			),

			mat_escuro,

			Vector3(
				90.0,
				0.0,
				0.0
			)
		)


		criar_cilindro(
			"Propulsor",

			0.56,
			0.18,

			Vector3(
				x,
				-0.15,
				5.62
			),

			mat_ciano,

			Vector3(
				90.0,
				0.0,
				0.0
			)
		)


	# ========================================================
	# MOTOR CENTRAL
	# ========================================================

	criar_cilindro(
		"MotorCentral",

		0.58,
		2.40,

		Vector3(
			0.0,
			0.50,
			4.35
		),

		mat_escuro,

		Vector3(
			90.0,
			0.0,
			0.0
		)
	)


	criar_cilindro(
		"PropulsorCentral",

		0.43,
		0.18,

		Vector3(
			0.0,
			0.50,
			5.57
		),

		mat_ciano,

		Vector3(
			90.0,
			0.0,
			0.0
		)
	)


	# ========================================================
	# ESTABILIZADORES
	# ========================================================

	criar_caixa(
		"EstabilizadorE",

		Vector3(
			0.30,
			1.75,
			2.20
		),

		Vector3(
			-1.40,
			0.95,
			3.65
		),

		mat_casco_claro,

		Vector3(
			0.0,
			0.0,
			-14.0
		)
	)


	criar_caixa(
		"EstabilizadorD",

		Vector3(
			0.30,
			1.75,
			2.20
		),

		Vector3(
			1.40,
			0.95,
			3.65
		),

		mat_casco_claro,

		Vector3(
			0.0,
			0.0,
			14.0
		)
	)


	# ========================================================
	# TREM DE POUSO
	# ========================================================

	criar_trem_pouso(
		Vector3(
			0.0,
			-0.80,
			-3.50
		)
	)


	criar_trem_pouso(
		Vector3(
			-2.25,
			-0.75,
			2.50
		)
	)


	criar_trem_pouso(
		Vector3(
			2.25,
			-0.75,
			2.50
		)
	)


	# ========================================================
	# FAIXAS POLICIAIS
	# ========================================================

	criar_caixa(
		"FaixaPolicialE",

		Vector3(
			0.12,
			0.16,
			5.40
		),

		Vector3(
			-1.68,
			0.33,
			0.50
		),

		mat_ciano
	)


	criar_caixa(
		"FaixaPolicialD",

		Vector3(
			0.12,
			0.16,
			5.40
		),

		Vector3(
			1.68,
			0.33,
			0.50
		),

		mat_ciano
	)


	# ========================================================
	# LUZ VERMELHA / AZUL TIPO POLICIA
	# ========================================================

	criar_caixa(
		"GiroflexAzul",

		Vector3(
			0.55,
			0.12,
			0.22
		),

		Vector3(
			-0.36,
			1.43,
			0.20
		),

		mat_ciano
	)


	criar_caixa(
		"GiroflexVermelho",

		Vector3(
			0.55,
			0.12,
			0.22
		),

		Vector3(
			0.36,
			1.43,
			0.20
		),

		mat_vermelho
	)


	# ========================================================
	# IDENTIFICACAO
	# ========================================================

	criar_texto_lateral(
		"P-01",
		-1
	)


	criar_texto_lateral(
		"P-01",
		1
	)


	# ========================================================
	# NUMERO NO TOPO
	# ========================================================

	var topo := Label3D.new()

	topo.name = "IdentificacaoTopo"

	topo.text = "POLICIA INTERPLANETARIA  //  P-01"

	topo.position = Vector3(
		0.0,
		1.34,
		1.15
	)

	topo.rotation_degrees = Vector3(
		-90.0,
		0.0,
		0.0
	)

	topo.font_size = 44

	topo.pixel_size = 0.008

	topo.outline_size = 7

	topo.modulate = Color(
		0.72,
		0.92,
		1.0
	)

	topo.outline_modulate = Color.BLACK


	nave_exterior.add_child(
		topo
	)



# ============================================================
# TREM DE POUSO
# ============================================================

func criar_trem_pouso(
	pos: Vector3
) -> void:


	criar_caixa(
		"PernaTrem",

		Vector3(
			0.22,
			1.15,
			0.22
		),

		pos + Vector3(
			0.0,
			-0.55,
			0.0
		),

		mat_escuro
	)


	criar_caixa(
		"PeTrem",

		Vector3(
			0.75,
			0.14,
			1.0
		),

		pos + Vector3(
			0.0,
			-1.10,
			0.0
		),

		mat_escuro
	)



# ============================================================
# TEXTO LATERAL
# ============================================================

func criar_texto_lateral(
	texto: String,
	lado: int
) -> void:


	var label := Label3D.new()

	label.name = (
		"IdentificacaoE"
		if lado < 0
		else "IdentificacaoD"
	)


	label.text = texto


	label.position = Vector3(
		1.73 * float(lado),
		0.55,
		-0.25
	)


	label.rotation_degrees = Vector3(
		0.0,

		90.0
		if lado < 0
		else -90.0,

		0.0
	)


	label.font_size = 56

	label.pixel_size = 0.009

	label.outline_size = 8

	label.modulate = Color(
		0.74,
		0.94,
		1.0
	)

	label.outline_modulate = Color.BLACK


	nave_exterior.add_child(
		label
	)



# ============================================================
# CAIXA
# ============================================================

func criar_caixa(
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


	nave_exterior.add_child(
		objeto
	)


	return objeto



# ============================================================
# ESFERA
# ============================================================

func criar_esfera(
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


	nave_exterior.add_child(
		objeto
	)


	return objeto



# ============================================================
# CILINDRO
# ============================================================

func criar_cilindro(
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


	nave_exterior.add_child(
		objeto
	)


	return objeto



# ============================================================
# MATERIAL EMISSIVO
# ============================================================

func criar_material_emissivo(
	cor: Color,
	energia: float
) -> StandardMaterial3D:


	var material := StandardMaterial3D.new()

	material.albedo_color = cor

	material.emission_enabled = true

	material.emission = cor

	material.emission_energy_multiplier = energia

	material.metallic = 0.28

	material.roughness = 0.18


	return material
