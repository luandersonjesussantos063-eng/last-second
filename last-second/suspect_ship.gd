extends Node3D


# =========================================================
# LAST SECOND - NAVE SUSPEITA v2.0
#
# Nave 3D física da ocorrência policial.
#
# - Casco
# - Cockpit
# - Asas
# - Motores
# - Luzes
# - Marcador
# - Movimento orbital
# =========================================================


@export var raio_patrulha: float = 30.0
@export var velocidade_patrulha: float = 0.12


var centro_patrulha: Vector3 = Vector3.ZERO

var patrulha_ativa: bool = false

var tempo: float = 0.0


var motor_esquerdo: MeshInstance3D = null
var motor_direito: MeshInstance3D = null

var luz_motor_esquerdo: OmniLight3D = null
var luz_motor_direito: OmniLight3D = null

var luz_navegacao: OmniLight3D = null


# =========================================================
# READY
# =========================================================

func _ready() -> void:

	name = "NaveSuspeita"

	construir_nave()


# =========================================================
# PROCESS
# =========================================================

func _process(delta: float) -> void:

	tempo += delta


	if patrulha_ativa:

		atualizar_patrulha()


	animar_motores()

	animar_luz_navegacao()


# =========================================================
# POSICIONAR NAVE
# =========================================================

func definir_ponto_patrulha(
	posicao: Vector3
) -> void:

	centro_patrulha = posicao

	global_position = posicao

	patrulha_ativa = true


# =========================================================
# MOVIMENTO
# =========================================================

func atualizar_patrulha() -> void:

	var angulo: float = (
		tempo
		*
		velocidade_patrulha
	)


	var deslocamento: Vector3 = Vector3(
		cos(angulo)
		*
		raio_patrulha,

		sin(
			angulo * 0.65
		)
		*
		7.0,

		sin(angulo)
		*
		raio_patrulha
	)


	global_position = (
		centro_patrulha
		+
		deslocamento
	)


	# Faz a nave acompanhar aproximadamente
	# a direção do movimento orbital.
	rotation.y = (
		-angulo
		+
		PI * 0.5
	)


	rotation.z = (
		sin(
			angulo
		)
		*
		0.08
	)


# =========================================================
# CONSTRUIR NAVE
# =========================================================

func construir_nave() -> void:

	# =====================================================
	# MATERIAL DO CASCO
	# =====================================================

	var mat_casco: StandardMaterial3D = (
		StandardMaterial3D.new()
	)


	mat_casco.albedo_color = Color(
		0.045,
		0.055,
		0.075,
		1.0
	)


	mat_casco.metallic = 0.80

	mat_casco.roughness = 0.26


	# =====================================================
	# MATERIAL SECUNDARIO
	# =====================================================

	var mat_secundario: StandardMaterial3D = (
		StandardMaterial3D.new()
	)


	mat_secundario.albedo_color = Color(
		0.16,
		0.17,
		0.20,
		1.0
	)


	mat_secundario.metallic = 0.70

	mat_secundario.roughness = 0.34


	# =====================================================
	# MATERIAL LARANJA
	# =====================================================

	var mat_laranja: StandardMaterial3D = (
		StandardMaterial3D.new()
	)


	mat_laranja.albedo_color = Color(
		0.82,
		0.20,
		0.035,
		1.0
	)


	mat_laranja.metallic = 0.45

	mat_laranja.roughness = 0.30


	# =====================================================
	# VIDRO
	# =====================================================

	var mat_vidro: StandardMaterial3D = (
		StandardMaterial3D.new()
	)


	mat_vidro.albedo_color = Color(
		0.025,
		0.30,
		0.48,
		0.72
	)


	mat_vidro.transparency = (
		BaseMaterial3D.TRANSPARENCY_ALPHA
	)


	mat_vidro.metallic = 0.35

	mat_vidro.roughness = 0.06


	# =====================================================
	# MOTOR
	# =====================================================

	var mat_motor: StandardMaterial3D = (
		StandardMaterial3D.new()
	)


	mat_motor.shading_mode = (
		BaseMaterial3D.SHADING_MODE_UNSHADED
	)


	mat_motor.albedo_color = Color(
		0.05,
		0.62,
		1.0,
		1.0
	)


	mat_motor.emission_enabled = true


	mat_motor.emission = Color(
		0.02,
		0.50,
		1.0,
		1.0
	)


	mat_motor.emission_energy_multiplier = 6.0


	# =====================================================
	# LUZ VERMELHA
	# =====================================================

	var mat_luz_vermelha: StandardMaterial3D = (
		StandardMaterial3D.new()
	)


	mat_luz_vermelha.shading_mode = (
		BaseMaterial3D.SHADING_MODE_UNSHADED
	)


	mat_luz_vermelha.albedo_color = Color(
		1.0,
		0.03,
		0.02,
		1.0
	)


	mat_luz_vermelha.emission_enabled = true


	mat_luz_vermelha.emission = Color(
		1.0,
		0.02,
		0.01,
		1.0
	)


	mat_luz_vermelha.emission_energy_multiplier = 5.0


	# =====================================================
	# CASCO PRINCIPAL
	# =====================================================

	var casco: MeshInstance3D = (
		MeshInstance3D.new()
	)


	casco.name = "CascoPrincipal"


	var casco_mesh: BoxMesh = BoxMesh.new()


	casco_mesh.size = Vector3(
		6.0,
		1.8,
		13.0
	)


	casco.mesh = casco_mesh

	casco.material_override = mat_casco


	add_child(
		casco
	)


	# =====================================================
	# CENTRO SUPERIOR
	# =====================================================

	var superior: MeshInstance3D = (
		MeshInstance3D.new()
	)


	var superior_mesh: BoxMesh = BoxMesh.new()


	superior_mesh.size = Vector3(
		3.8,
		1.1,
		6.0
	)


	superior.mesh = superior_mesh


	superior.position = Vector3(
		0.0,
		1.25,
		0.0
	)


	superior.material_override = (
		mat_secundario
	)


	add_child(
		superior
	)


	# =====================================================
	# NARIZ
	# =====================================================

	var nariz: MeshInstance3D = (
		MeshInstance3D.new()
	)


	nariz.name = "Nariz"


	var nariz_mesh: CylinderMesh = (
		CylinderMesh.new()
	)


	nariz_mesh.top_radius = 0.12

	nariz_mesh.bottom_radius = 2.25

	nariz_mesh.height = 4.2

	nariz_mesh.radial_segments = 8


	nariz.mesh = nariz_mesh


	nariz.rotation_degrees.x = 90.0


	nariz.position = Vector3(
		0.0,
		0.0,
		-8.4
	)


	nariz.material_override = mat_casco


	add_child(
		nariz
	)


	# =====================================================
	# COCKPIT
	# =====================================================

	var cockpit: MeshInstance3D = (
		MeshInstance3D.new()
	)


	cockpit.name = "Cockpit"


	var cockpit_mesh: SphereMesh = (
		SphereMesh.new()
	)


	cockpit_mesh.radius = 1.55

	cockpit_mesh.height = 3.10

	cockpit_mesh.radial_segments = 32

	cockpit_mesh.rings = 16


	cockpit.mesh = cockpit_mesh


	cockpit.scale = Vector3(
		1.05,
		0.50,
		1.55
	)


	cockpit.position = Vector3(
		0.0,
		1.75,
		-3.7
	)


	cockpit.material_override = mat_vidro


	add_child(
		cockpit
	)


	# =====================================================
	# ASA ESQUERDA
	# =====================================================

	var asa_esquerda: MeshInstance3D = (
		MeshInstance3D.new()
	)


	var asa_esquerda_mesh: BoxMesh = (
		BoxMesh.new()
	)


	asa_esquerda_mesh.size = Vector3(
		7.5,
		0.28,
		5.0
	)


	asa_esquerda.mesh = asa_esquerda_mesh


	asa_esquerda.position = Vector3(
		-6.0,
		-0.2,
		1.0
	)


	asa_esquerda.rotation_degrees.z = -5.0


	asa_esquerda.material_override = (
		mat_secundario
	)


	add_child(
		asa_esquerda
	)


	# =====================================================
	# ASA DIREITA
	# =====================================================

	var asa_direita: MeshInstance3D = (
		MeshInstance3D.new()
	)


	var asa_direita_mesh: BoxMesh = (
		BoxMesh.new()
	)


	asa_direita_mesh.size = Vector3(
		7.5,
		0.28,
		5.0
	)


	asa_direita.mesh = asa_direita_mesh


	asa_direita.position = Vector3(
		6.0,
		-0.2,
		1.0
	)


	asa_direita.rotation_degrees.z = 5.0


	asa_direita.material_override = (
		mat_secundario
	)


	add_child(
		asa_direita
	)


	# =====================================================
	# DETALHE ESQUERDO
	# =====================================================

	var detalhe_esquerdo: MeshInstance3D = (
		MeshInstance3D.new()
	)


	var detalhe_esquerdo_mesh: BoxMesh = (
		BoxMesh.new()
	)


	detalhe_esquerdo_mesh.size = Vector3(
		4.8,
		0.12,
		0.90
	)


	detalhe_esquerdo.mesh = detalhe_esquerdo_mesh


	detalhe_esquerdo.position = Vector3(
		-5.7,
		0.05,
		0.0
	)


	detalhe_esquerdo.material_override = (
		mat_laranja
	)


	add_child(
		detalhe_esquerdo
	)


	# =====================================================
	# DETALHE DIREITO
	# =====================================================

	var detalhe_direito: MeshInstance3D = (
		MeshInstance3D.new()
	)


	var detalhe_direito_mesh: BoxMesh = (
		BoxMesh.new()
	)


	detalhe_direito_mesh.size = Vector3(
		4.8,
		0.12,
		0.90
	)


	detalhe_direito.mesh = detalhe_direito_mesh


	detalhe_direito.position = Vector3(
		5.7,
		0.05,
		0.0
	)


	detalhe_direito.material_override = (
		mat_laranja
	)


	add_child(
		detalhe_direito
	)


	# =====================================================
	# MOTORES
	# =====================================================

	criar_casco_motor(
		Vector3(
			-2.0,
			0.0,
			7.2
		),
		mat_casco
	)


	criar_casco_motor(
		Vector3(
			2.0,
			0.0,
			7.2
		),
		mat_casco
	)


	motor_esquerdo = criar_brilho_motor(
		Vector3(
			-2.0,
			0.0,
			8.5
		),
		mat_motor
	)


	motor_direito = criar_brilho_motor(
		Vector3(
			2.0,
			0.0,
			8.5
		),
		mat_motor
	)


	# =====================================================
	# LUZ DOS MOTORES
	# =====================================================

	luz_motor_esquerdo = OmniLight3D.new()


	luz_motor_esquerdo.light_color = Color(
		0.05,
		0.50,
		1.0,
		1.0
	)


	luz_motor_esquerdo.light_energy = 5.0

	luz_motor_esquerdo.omni_range = 18.0


	luz_motor_esquerdo.position = Vector3(
		-2.0,
		0.0,
		8.7
	)


	add_child(
		luz_motor_esquerdo
	)


	luz_motor_direito = OmniLight3D.new()


	luz_motor_direito.light_color = Color(
		0.05,
		0.50,
		1.0,
		1.0
	)


	luz_motor_direito.light_energy = 5.0

	luz_motor_direito.omni_range = 18.0


	luz_motor_direito.position = Vector3(
		2.0,
		0.0,
		8.7
	)


	add_child(
		luz_motor_direito
	)


	# =====================================================
	# LUZ DE NAVEGACAO
	# =====================================================

	var luz_visual: MeshInstance3D = (
		MeshInstance3D.new()
	)


	var luz_visual_mesh: SphereMesh = (
		SphereMesh.new()
	)


	luz_visual_mesh.radius = 0.25

	luz_visual_mesh.height = 0.50


	luz_visual.mesh = luz_visual_mesh


	luz_visual.position = Vector3(
		0.0,
		2.20,
		2.3
	)


	luz_visual.material_override = (
		mat_luz_vermelha
	)


	add_child(
		luz_visual
	)


	luz_navegacao = OmniLight3D.new()


	luz_navegacao.light_color = Color(
		1.0,
		0.03,
		0.02,
		1.0
	)


	luz_navegacao.light_energy = 3.0

	luz_navegacao.omni_range = 12.0


	luz_navegacao.position = Vector3(
		0.0,
		2.2,
		2.3
	)


	add_child(
		luz_navegacao
	)


	# =====================================================
	# LABEL
	# =====================================================

	var label: Label3D = Label3D.new()


	label.name = "TargetLabel"


	label.text = (
		"◇ NAVE NAO IDENTIFICADA"
	)


	label.position = Vector3(
		0.0,
		7.5,
		0.0
	)


	label.font_size = 36

	label.outline_size = 10

	label.pixel_size = 0.007

	label.fixed_size = true


	label.billboard = (
		BaseMaterial3D.BILLBOARD_ENABLED
	)


	# Deixamos visivel mesmo de longe.
	label.no_depth_test = true


	label.modulate = Color(
		1.0,
		0.58,
		0.18,
		1.0
	)


	add_child(
		label
	)


	print(
		"NAVE SUSPEITA 3D CONSTRUIDA"
	)


# =========================================================
# CASCO DO MOTOR
# =========================================================

func criar_casco_motor(
	posicao: Vector3,
	material: Material
) -> void:

	var motor: MeshInstance3D = (
		MeshInstance3D.new()
	)


	var mesh: CylinderMesh = (
		CylinderMesh.new()
	)


	mesh.top_radius = 0.90

	mesh.bottom_radius = 0.90

	mesh.height = 2.5

	mesh.radial_segments = 16


	motor.mesh = mesh


	motor.rotation_degrees.x = 90.0

	motor.position = posicao

	motor.material_override = material


	add_child(
		motor
	)


# =========================================================
# BRILHO MOTOR
# =========================================================

func criar_brilho_motor(
	posicao: Vector3,
	material: Material
) -> MeshInstance3D:

	var brilho: MeshInstance3D = (
		MeshInstance3D.new()
	)


	var mesh: SphereMesh = (
		SphereMesh.new()
	)


	mesh.radius = 0.70

	mesh.height = 1.40

	mesh.radial_segments = 20

	mesh.rings = 10


	brilho.mesh = mesh


	brilho.position = posicao


	brilho.scale = Vector3(
		1.0,
		1.0,
		1.8
	)


	brilho.material_override = material


	add_child(
		brilho
	)


	return brilho


# =========================================================
# ANIMAR MOTORES
# =========================================================

func animar_motores() -> void:

	var pulso: float = (
		sin(
			tempo * 9.0
		)
		+
		1.0
	) * 0.5


	var comprimento: float = lerpf(
		1.55,
		2.15,
		pulso
	)


	if motor_esquerdo != null:

		motor_esquerdo.scale = Vector3(
			1.0,
			1.0,
			comprimento
		)


	if motor_direito != null:

		motor_direito.scale = Vector3(
			1.0,
			1.0,
			comprimento
		)


# =========================================================
# LUZ NAVEGACAO
# =========================================================

func animar_luz_navegacao() -> void:

	if luz_navegacao == null:
		return


	var ligado: bool = (
		int(
			tempo * 2.5
		)
		%
		2
		==
		0
	)


	if ligado:

		luz_navegacao.light_energy = 4.0

	else:

		luz_navegacao.light_energy = 0.15
