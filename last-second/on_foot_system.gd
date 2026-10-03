extends Node


# ============================================================
# LAST SECOND
# ON FOOT SYSTEM v2.0
#
# - DESCER / ENTRAR NA P-01
# - PERSONAGEM COM COLISAO
# - CAMINHADA ANIMADA
# - CORRIDA ANIMADA
# - PERNAS E BRACOS SE MOVEM
# - CAMERA SEGUE A ROTACAO DO PERSONAGEM
# - CAMERA LIVRE POR TOQUE / MOUSE
# - JOYSTICK MOBILE
#
# PC:
# W / S = frente / tras
# A / D = virar
# SHIFT = correr
# arrastar mouse = olhar ao redor
# ============================================================


# ============================================================
# MOVIMENTO
# ============================================================

@export_category("Movimento")

@export_range(1.0, 12.0, 0.5)
var velocidade_andar: float = 4.5

@export_range(2.0, 18.0, 0.5)
var velocidade_correr: float = 8.0

@export_range(5.0, 40.0, 1.0)
var aceleracao: float = 18.0

@export_range(60.0, 260.0, 5.0)
var velocidade_giro_graus: float = 145.0

@export_range(10.0, 40.0, 1.0)
var gravidade: float = 22.0


# ============================================================
# ANIMACAO
# ============================================================

@export_category("Animacao")

@export_range(2.0, 14.0, 0.5)
var velocidade_animacao_andar: float = 7.0

@export_range(4.0, 20.0, 0.5)
var velocidade_animacao_correr: float = 11.0

@export_range(10.0, 60.0, 1.0)
var angulo_perna_andar: float = 28.0

@export_range(20.0, 75.0, 1.0)
var angulo_perna_correr: float = 45.0

@export_range(5.0, 45.0, 1.0)
var angulo_braco_andar: float = 20.0

@export_range(10.0, 60.0, 1.0)
var angulo_braco_correr: float = 36.0


# ============================================================
# CAMERA
# ============================================================

@export_category("Camera")

@export_range(2.5, 8.0, 0.1)
var distancia_camera: float = 4.8

@export_range(0.001, 0.015, 0.001)
var sensibilidade_camera: float = 0.005

@export_range(-70.0, -5.0, 1.0)
var limite_camera_cima: float = -45.0

@export_range(5.0, 70.0, 1.0)
var limite_camera_baixo: float = 35.0

@export_range(2.0, 20.0, 0.5)
var suavidade_camera: float = 11.0


# ============================================================
# NAVE
# ============================================================

@export_category("Nave")

@export_range(3.0, 12.0, 0.5)
var distancia_entrar_nave: float = 6.5

@export_range(0.0, 5.0, 0.1)
var velocidade_max_para_descer: float = 0.5

@export var offset_spawn_personagem: Vector3 = Vector3(
	8.5,
	0.03,
	0.0
)


# ============================================================
# INTERFACE
# ============================================================

@export_category("Interface")

@export var mostrar_no_pc_para_teste: bool = true

@export_range(0.15, 0.80, 0.05)
var opacidade_ui: float = 0.38


# ============================================================
# SISTEMAS
# ============================================================

var cena: Node = null

var nave: Node3D = null

var camera_nave: Camera3D = null

var hangar: Node3D = null

var mobile_controls: Node = null

var mobile_optimizer: Node = null


# ============================================================
# PERSONAGEM
# ============================================================

var personagem: CharacterBody3D = null

var personagem_visual: Node3D = null


# ============================================================
# MEMBROS ANIMADOS
# ============================================================

var perna_l: Node3D = null
var perna_r: Node3D = null

var braco_l: Node3D = null
var braco_r: Node3D = null

var tempo_animacao: float = 0.0


# ============================================================
# CAMERA
# ============================================================

var camera_rig: Node3D = null

var camera_pitch: Node3D = null

var spring_arm: SpringArm3D = null

var camera_pe: Camera3D = null


# Angulo livre da camera relativo ao personagem.

var offset_yaw_camera: float = 0.0

var pitch_camera: float = deg_to_rad(
	-12.0
)


# ============================================================
# ESTADOS
# ============================================================

var modo_a_pe: bool = false

var nave_processava: bool = true

var nave_processava_fisica: bool = true


# ============================================================
# UI
# ============================================================

var camada_ui: CanvasLayer = null

var ui_root: Control = null

var botao_descer: Button = null

var botao_entrar: Button = null

var botao_correr: Button = null

var label_modo: Label = null

var label_dica: Label = null


# ============================================================
# JOYSTICK
# ============================================================

var joystick_base: Panel = null

var joystick_knob: Panel = null

var joystick_valor: Vector2 = Vector2.ZERO

var joystick_touch_id: int = -1


# ============================================================
# CAMERA TOUCH
# ============================================================

var camera_touch_id: int = -1

var correr_mobile: bool = false

var mouse_camera_arrastando: bool = false


# ============================================================
# COLISAO DA NAVE
# ============================================================

var colisao_nave_a_pe: AnimatableBody3D = null

var shape_colisao_nave_a_pe: CollisionShape3D = null


# ============================================================
# OUTROS
# ============================================================

var ultimo_tamanho_tela: Vector2 = Vector2.ZERO

var tempo_ui: float = 0.0


# ============================================================
# READY
# ============================================================

func _ready() -> void:

	process_mode = Node.PROCESS_MODE_ALWAYS


	await get_tree().process_frame

	await get_tree().process_frame

	await get_tree().physics_frame


	localizar_sistemas()

	criar_personagem()

	criar_colisao_nave_a_pe()

	criar_camera_terceira_pessoa()

	criar_interface()

	atualizar_layout()

	atualizar_interface_estado()


	print(
		"========================================"
	)

	print(
		"ON FOOT SYSTEM v2.0 // WALK ANIMATION"
	)

	print(
		"CAMERA FOLLOW // ONLINE"
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
	# NAVE PLAYER
	# ========================================================

	nave = cena.get_node_or_null(
		"Player"
	) as Node3D


	if nave == null:

		var candidato := cena.find_child(
			"Player",
			true,
			false
		)

		if candidato is Node3D:

			nave = candidato


	# ========================================================
	# HANGAR
	# ========================================================

	hangar = cena.get_node_or_null(
		"HangarBase"
	) as Node3D


	if hangar == null:

		var candidato_hangar := cena.find_child(
			"HangarBase",
			true,
			false
		)

		if candidato_hangar is Node3D:

			hangar = candidato_hangar


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
	# MOBILE OPTIMIZER
	# ========================================================

	mobile_optimizer = cena.get_node_or_null(
		"MobileOptimizer"
	)


	if mobile_optimizer == null:

		mobile_optimizer = cena.find_child(
			"MobileOptimizer",
			true,
			false
		)


	# ========================================================
	# CAMERA DA NAVE
	# ========================================================

	if nave != null:

		camera_nave = nave.get_node_or_null(
			"Camera3D"
		) as Camera3D


	if camera_nave == null:

		var camera_encontrada := cena.find_child(
			"Camera3D",
			true,
			false
		)

		if camera_encontrada is Camera3D:

			camera_nave = camera_encontrada



# ============================================================
# PERSONAGEM
# ============================================================

func criar_personagem() -> void:

	if cena == null:

		return


	# ========================================================
	# CHARACTER BODY
	# ========================================================

	personagem = CharacterBody3D.new()

	personagem.name = "PlayerOnFoot"

	personagem.collision_layer = 1

	personagem.collision_mask = 1

	personagem.floor_snap_length = 0.65

	personagem.safe_margin = 0.04

	personagem.floor_max_angle = deg_to_rad(
		48.0
	)


	personagem.add_to_group(
		"player_on_foot"
	)

	personagem.add_to_group(
		"player"
	)


	cena.add_child(
		personagem
	)


	# ========================================================
	# COLISAO
	# ========================================================

	var colisao := CollisionShape3D.new()

	colisao.name = "CollisionShape3D"


	var capsula := CapsuleShape3D.new()

	capsula.radius = 0.38

	capsula.height = 1.80


	colisao.shape = capsula


	colisao.position = Vector3(
		0.0,
		0.90,
		0.0
	)


	personagem.add_child(
		colisao
	)


	# ========================================================
	# ROOT VISUAL
	# ========================================================

	personagem_visual = Node3D.new()

	personagem_visual.name = "Visual"


	personagem.add_child(
		personagem_visual
	)


	# ========================================================
	# MATERIAIS
	# ========================================================

	var mat_uniforme := StandardMaterial3D.new()

	mat_uniforme.albedo_color = Color(
		0.055,
		0.075,
		0.105
	)

	mat_uniforme.metallic = 0.18

	mat_uniforme.roughness = 0.62


	var mat_colete := StandardMaterial3D.new()

	mat_colete.albedo_color = Color(
		0.025,
		0.035,
		0.050
	)

	mat_colete.metallic = 0.22

	mat_colete.roughness = 0.55


	var mat_ciano := StandardMaterial3D.new()

	mat_ciano.albedo_color = Color(
		0.03,
		0.58,
		0.82
	)

	mat_ciano.emission_enabled = true

	mat_ciano.emission = Color(
		0.00,
		0.42,
		0.70
	)

	mat_ciano.emission_energy_multiplier = 0.65


	var mat_pele := StandardMaterial3D.new()

	mat_pele.albedo_color = Color(
		0.56,
		0.39,
		0.29
	)

	mat_pele.roughness = 0.80


	var mat_visera := StandardMaterial3D.new()

	mat_visera.albedo_color = Color(
		0.02,
		0.16,
		0.22
	)

	mat_visera.emission_enabled = true

	mat_visera.emission = Color(
		0.00,
		0.22,
		0.34
	)

	mat_visera.emission_energy_multiplier = 0.45


	var mat_bota := StandardMaterial3D.new()

	mat_bota.albedo_color = Color(
		0.018,
		0.022,
		0.030
	)

	mat_bota.metallic = 0.15

	mat_bota.roughness = 0.72


	# ========================================================
	# PERNA ESQUERDA
	#
	# Agora usamos pivô no quadril.
	# Isso permite a perna realmente balançar.
	# ========================================================

	perna_l = criar_membro(
		"PernaL",
		Vector3(
			-0.20,
			0.72,
			0.0
		),
		Vector3(
			0.28,
			0.72,
			0.28
		),
		mat_uniforme
	)


	criar_caixa_em_no(
		perna_l,
		"BotaL",
		Vector3(
			0.31,
			0.16,
			0.48
		),
		Vector3(
			0.0,
			-0.73,
			-0.09
		),
		mat_bota
	)


	# ========================================================
	# PERNA DIREITA
	# ========================================================

	perna_r = criar_membro(
		"PernaR",
		Vector3(
			0.20,
			0.72,
			0.0
		),
		Vector3(
			0.28,
			0.72,
			0.28
		),
		mat_uniforme
	)


	criar_caixa_em_no(
		perna_r,
		"BotaR",
		Vector3(
			0.31,
			0.16,
			0.48
		),
		Vector3(
			0.0,
			-0.73,
			-0.09
		),
		mat_bota
	)


	# ========================================================
	# TRONCO
	# ========================================================

	criar_caixa_personagem(
		"Tronco",
		Vector3(
			0.88,
			0.78,
			0.42
		),
		Vector3(
			0.0,
			1.10,
			0.0
		),
		mat_uniforme
	)


	# ========================================================
	# COLETE
	# ========================================================

	criar_caixa_personagem(
		"Colete",
		Vector3(
			0.92,
			0.56,
			0.48
		),
		Vector3(
			0.0,
			1.13,
			-0.02
		),
		mat_colete
	)


	# ========================================================
	# BRACO ESQUERDO
	# ========================================================

	braco_l = criar_membro(
		"BracoL",
		Vector3(
			-0.58,
			1.39,
			0.0
		),
		Vector3(
			0.24,
			0.68,
			0.24
		),
		mat_uniforme
	)


	# ========================================================
	# BRACO DIREITO
	# ========================================================

	braco_r = criar_membro(
		"BracoR",
		Vector3(
			0.58,
			1.39,
			0.0
		),
		Vector3(
			0.24,
			0.68,
			0.24
		),
		mat_uniforme
	)


	# ========================================================
	# CABECA
	# ========================================================

	var cabeca := MeshInstance3D.new()

	cabeca.name = "Cabeca"


	var esfera := SphereMesh.new()

	esfera.radius = 0.29

	esfera.height = 0.58


	cabeca.mesh = esfera

	cabeca.material_override = mat_pele


	cabeca.position = Vector3(
		0.0,
		1.72,
		0.0
	)


	personagem_visual.add_child(
		cabeca
	)


	# ========================================================
	# VISEIRA
	# ========================================================

	criar_caixa_personagem(
		"Viseira",
		Vector3(
			0.38,
			0.16,
			0.06
		),
		Vector3(
			0.0,
			1.77,
			-0.27
		),
		mat_visera
	)


	# ========================================================
	# FAIXA POLICIAL
	# ========================================================

	criar_caixa_personagem(
		"FaixaPolicial",
		Vector3(
			0.74,
			0.08,
			0.46
		),
		Vector3(
			0.0,
			1.37,
			0.0
		),
		mat_ciano
	)


	# ========================================================
	# COMECA ESCONDIDO
	# ========================================================

	personagem.visible = false

	personagem.process_mode = Node.PROCESS_MODE_DISABLED

	personagem.collision_layer = 0

	personagem.collision_mask = 0



# ============================================================
# CRIAR MEMBRO COM PIVO
# ============================================================

func criar_membro(
	nome: String,
	posicao_pivo: Vector3,
	tamanho: Vector3,
	material: Material
) -> Node3D:

	var pivo := Node3D.new()

	pivo.name = nome + "_Pivo"

	pivo.position = posicao_pivo


	personagem_visual.add_child(
		pivo
	)


	var mesh_instance := MeshInstance3D.new()

	mesh_instance.name = nome


	var box := BoxMesh.new()

	box.size = tamanho


	mesh_instance.mesh = box

	mesh_instance.material_override = material


	# Corpo da perna / braço fica abaixo do pivô.

	mesh_instance.position = Vector3(
		0.0,
		-tamanho.y / 2.0,
		0.0
	)


	pivo.add_child(
		mesh_instance
	)


	return pivo



# ============================================================
# CRIAR CAIXA NO VISUAL
# ============================================================

func criar_caixa_personagem(
	nome: String,
	tamanho: Vector3,
	posicao: Vector3,
	material: Material
) -> MeshInstance3D:

	var mesh_instance := MeshInstance3D.new()

	mesh_instance.name = nome


	var box := BoxMesh.new()

	box.size = tamanho


	mesh_instance.mesh = box

	mesh_instance.material_override = material

	mesh_instance.position = posicao


	personagem_visual.add_child(
		mesh_instance
	)


	return mesh_instance



# ============================================================
# CRIAR CAIXA DENTRO DE UM NO
# ============================================================

func criar_caixa_em_no(
	pai: Node3D,
	nome: String,
	tamanho: Vector3,
	posicao: Vector3,
	material: Material
) -> MeshInstance3D:

	var mesh_instance := MeshInstance3D.new()

	mesh_instance.name = nome


	var box := BoxMesh.new()

	box.size = tamanho


	mesh_instance.mesh = box

	mesh_instance.material_override = material

	mesh_instance.position = posicao


	pai.add_child(
		mesh_instance
	)


	return mesh_instance



# ============================================================
# COLISAO DA NAVE ENQUANTO ESTAMOS A PE
# ============================================================

func criar_colisao_nave_a_pe() -> void:

	if nave == null:

		return


	if !is_instance_valid(
		nave
	):

		return


	var existente := nave.get_node_or_null(
		"P01OnFootCollision"
	)


	if existente is AnimatableBody3D:

		colisao_nave_a_pe = existente

		shape_colisao_nave_a_pe = (
			colisao_nave_a_pe.get_node_or_null(
				"CollisionShape3D"
			)
			as CollisionShape3D
		)

		ativar_colisao_nave_a_pe(
			false
		)

		return


	colisao_nave_a_pe = AnimatableBody3D.new()

	colisao_nave_a_pe.name = "P01OnFootCollision"

	colisao_nave_a_pe.collision_layer = 0

	colisao_nave_a_pe.collision_mask = 0

	colisao_nave_a_pe.sync_to_physics = true


	colisao_nave_a_pe.position = Vector3(
		0.0,
		-3.15,
		0.0
	)


	nave.add_child(
		colisao_nave_a_pe
	)


	shape_colisao_nave_a_pe = CollisionShape3D.new()

	shape_colisao_nave_a_pe.name = "CollisionShape3D"


	var box := BoxShape3D.new()

	box.size = Vector3(
		8.0,
		3.6,
		14.0
	)


	shape_colisao_nave_a_pe.shape = box


	colisao_nave_a_pe.add_child(
		shape_colisao_nave_a_pe
	)


	ativar_colisao_nave_a_pe(
		false
	)



# ============================================================
# ATIVAR COLISAO P-01
# ============================================================

func ativar_colisao_nave_a_pe(
	ativo: bool
) -> void:

	if colisao_nave_a_pe == null:

		return


	if !is_instance_valid(
		colisao_nave_a_pe
	):

		return


	colisao_nave_a_pe.collision_layer = (
		1
		if ativo
		else 0
	)

	colisao_nave_a_pe.collision_mask = (
		1
		if ativo
		else 0
	)


	if shape_colisao_nave_a_pe != null:

		shape_colisao_nave_a_pe.disabled = !ativo



# ============================================================
# CAMERA TERCEIRA PESSOA
# ============================================================

func criar_camera_terceira_pessoa() -> void:

	if cena == null:

		return


	camera_rig = Node3D.new()

	camera_rig.name = "OnFootCameraRig"


	cena.add_child(
		camera_rig
	)


	camera_pitch = Node3D.new()

	camera_pitch.name = "Pitch"


	camera_rig.add_child(
		camera_pitch
	)


	spring_arm = SpringArm3D.new()

	spring_arm.name = "SpringArm3D"

	spring_arm.spring_length = distancia_camera

	spring_arm.collision_mask = 1

	spring_arm.margin = 0.18


	camera_pitch.add_child(
		spring_arm
	)


	# Evita colisão da câmera com o policial.

	if personagem != null:

		spring_arm.add_excluded_object(
			personagem.get_rid()
		)


	camera_pe = Camera3D.new()

	camera_pe.name = "OnFootCamera3D"

	camera_pe.current = false

	camera_pe.fov = 72.0


	spring_arm.add_child(
		camera_pe
	)


	camera_rig.visible = false



# ============================================================
# PROCESS
# ============================================================

func _process(
	delta: float
) -> void:

	if cena == null:

		localizar_sistemas()


	var tamanho := get_viewport().get_visible_rect().size


	if tamanho != ultimo_tamanho_tela:

		atualizar_layout()


	tempo_ui += delta


	if tempo_ui >= 0.12:

		tempo_ui = 0.0

		atualizar_interface_estado()


	# ========================================================
	# CAMERA A PE
	# ========================================================

	if (
		modo_a_pe
		and personagem != null
		and camera_rig != null
	):

		var alvo_posicao := (
			personagem.global_position
			+ Vector3.UP * 1.48
		)


		camera_rig.global_position = (
			camera_rig.global_position.lerp(
				alvo_posicao,
				clampf(
					delta * 14.0,
					0.0,
					1.0
				)
			)
		)


		# ====================================================
		# AQUI ESTA A NOVA CAMERA
		#
		# A rotacao base agora SEMPRE vem do personagem.
		# O jogador pode olhar ao redor usando offset.
		# ====================================================

		var yaw_alvo := (
			personagem.global_rotation.y
			+ offset_yaw_camera
		)


		camera_rig.global_rotation.y = lerp_angle(
			camera_rig.global_rotation.y,
			yaw_alvo,
			clampf(
				delta * suavidade_camera,
				0.0,
				1.0
			)
		)


		camera_pitch.rotation.x = pitch_camera



# ============================================================
# PHYSICS
# ============================================================

func _physics_process(
	delta: float
) -> void:

	if !modo_a_pe:

		return


	if personagem == null:

		return


	if get_tree().paused:

		return


	# ========================================================
	# INPUT
	# ========================================================

	var input_vec := pegar_input_movimento()


	# ========================================================
	# GIRO
	#
	# A / D e joystick horizontal agora GIRAM o jogador.
	# ========================================================

	var giro_input: float = input_vec.x


	if absf(
		giro_input
	) > 0.04:

		personagem.rotation.y -= (
			giro_input
			* deg_to_rad(
				velocidade_giro_graus
			)
			* delta
		)


	# ========================================================
	# FRENTE / TRAS
	#
	# Joystick para cima = input Y negativo.
	# Transformamos em movimento positivo para frente.
	# ========================================================

	var movimento_frente: float = -input_vec.y


	var correndo := (
		correr_mobile
		or Input.is_key_pressed(
			KEY_SHIFT
		)
	)


	var velocidade_alvo := (
		velocidade_correr
		if correndo
		else velocidade_andar
	)


	# Direcao que o policial esta olhando.

	var frente := (
		-personagem.global_transform.basis.z
	).normalized()


	var direcao := (
		frente
		* movimento_frente
	)


	# ========================================================
	# VELOCIDADE
	# ========================================================

	var alvo_x := (
		direcao.x
		* velocidade_alvo
	)

	var alvo_z := (
		direcao.z
		* velocidade_alvo
	)


	personagem.velocity.x = move_toward(
		personagem.velocity.x,
		alvo_x,
		aceleracao * delta
	)


	personagem.velocity.z = move_toward(
		personagem.velocity.z,
		alvo_z,
		aceleracao * delta
	)


	# ========================================================
	# ALTURA
	# ========================================================

	if esta_dentro_hangar():

		personagem.velocity.y = 0.0

	else:

		if personagem.is_on_floor():

			if personagem.velocity.y < 0.0:

				personagem.velocity.y = -0.8

		else:

			personagem.velocity.y -= (
				gravidade
				* delta
			)


	# ========================================================
	# MOVE
	# ========================================================

	personagem.move_and_slide()


	# Mantem no piso do hangar.

	garantir_piso_hangar()


	# ========================================================
	# ANIMACAO
	# ========================================================

	var velocidade_horizontal := Vector2(
		personagem.velocity.x,
		personagem.velocity.z
	).length()


	animar_personagem(
		delta,
		velocidade_horizontal,
		correndo
	)



# ============================================================
# ANIMAR PERSONAGEM
# ============================================================

func animar_personagem(
	delta: float,
	velocidade_horizontal: float,
	correndo: bool
) -> void:

	if personagem_visual == null:

		return


	if perna_l == null:

		return


	var andando := (
		velocidade_horizontal > 0.15
	)


	# ========================================================
	# ANDANDO / CORRENDO
	# ========================================================

	if andando:

		var velocidade_animacao := (
			velocidade_animacao_correr
			if correndo
			else velocidade_animacao_andar
		)


		var angulo_perna := deg_to_rad(
			angulo_perna_correr
			if correndo
			else angulo_perna_andar
		)


		var angulo_braco := deg_to_rad(
			angulo_braco_correr
			if correndo
			else angulo_braco_andar
		)


		tempo_animacao += (
			delta
			* velocidade_animacao
		)


		var ciclo := sin(
			tempo_animacao
		)


		# ====================================================
		# PERNAS EM SENTIDOS OPOSTOS
		# ====================================================

		perna_l.rotation.x = (
			ciclo
			* angulo_perna
		)

		perna_r.rotation.x = (
			-ciclo
			* angulo_perna
		)


		# ====================================================
		# BRACOS OPOSTOS AS PERNAS
		# ====================================================

		braco_l.rotation.x = (
			-ciclo
			* angulo_braco
		)

		braco_r.rotation.x = (
			ciclo
			* angulo_braco
		)


		# ====================================================
		# PEQUENO MOVIMENTO VERTICAL
		# ====================================================

		var bob := (
			absf(
				sin(
					tempo_animacao * 2.0
				)
			)
			* (
				0.055
				if correndo
				else 0.025
			)
		)


		personagem_visual.position.y = bob


	# ========================================================
	# PARADO
	# ========================================================

	else:

		perna_l.rotation.x = lerp(
			perna_l.rotation.x,
			0.0,
			clampf(
				delta * 10.0,
				0.0,
				1.0
			)
		)


		perna_r.rotation.x = lerp(
			perna_r.rotation.x,
			0.0,
			clampf(
				delta * 10.0,
				0.0,
				1.0
			)
		)


		braco_l.rotation.x = lerp(
			braco_l.rotation.x,
			0.0,
			clampf(
				delta * 10.0,
				0.0,
				1.0
			)
		)


		braco_r.rotation.x = lerp(
			braco_r.rotation.x,
			0.0,
			clampf(
				delta * 10.0,
				0.0,
				1.0
			)
		)


		personagem_visual.position.y = lerp(
			personagem_visual.position.y,
			0.0,
			clampf(
				delta * 10.0,
				0.0,
				1.0
			)
		)



# ============================================================
# ALTURA DO PISO
# ============================================================

func pegar_altura_piso_local() -> float:

	if hangar == null:

		return 0.0


	var valor: Variant = hangar.get(
		"altura_piso_fisico"
	)


	if valor != null:

		return float(
			valor
		)


	return 0.0



# ============================================================
# DENTRO DO HANGAR
# ============================================================

func esta_dentro_hangar() -> bool:

	if personagem == null:

		return false


	if hangar == null:

		return false


	if !is_instance_valid(
		personagem
	):

		return false


	if !is_instance_valid(
		hangar
	):

		return false


	var p := hangar.to_local(
		personagem.global_position
	)


	var largura := 180.0

	var profundidade := 240.0

	var altura := 32.0


	var v: Variant = hangar.get(
		"largura_hangar"
	)


	if v != null:

		largura = float(
			v
		)


	v = hangar.get(
		"profundidade_hangar"
	)


	if v != null:

		profundidade = float(
			v
		)


	v = hangar.get(
		"altura_hangar"
	)


	if v != null:

		altura = float(
			v
		)


	return (
		absf(
			p.x
		)
		<= largura * 0.5 - 1.5

		and absf(
			p.z
		)
		<= profundidade * 0.5 - 1.5

		and p.y >= -4.0

		and p.y <= altura + 3.0
	)



# ============================================================
# TRAVA NO PISO
# ============================================================

func garantir_piso_hangar() -> void:

	if !esta_dentro_hangar():

		return


	var local := hangar.to_local(
		personagem.global_position
	)


	var piso_y := (
		pegar_altura_piso_local()
		+ 0.03
	)


	local.y = piso_y


	personagem.global_position = hangar.to_global(
		local
	)


	personagem.velocity.y = 0.0



# ============================================================
# INPUT MOVIMENTO
# ============================================================

func pegar_input_movimento() -> Vector2:

	var teclado := Vector2(
		float(
			Input.is_key_pressed(
				KEY_D
			)
		)
		- float(
			Input.is_key_pressed(
				KEY_A
			)
		),

		float(
			Input.is_key_pressed(
				KEY_S
			)
		)
		- float(
			Input.is_key_pressed(
				KEY_W
			)
		)
	)


	var resultado := teclado


	if joystick_valor.length() > resultado.length():

		resultado = joystick_valor


	return resultado.limit_length(
		1.0
	)



# ============================================================
# PODE DESCER
# ============================================================

func pode_descer() -> bool:

	if modo_a_pe:

		return false


	if nave == null:

		return false


	if !is_instance_valid(
		nave
	):

		return false


	if hangar == null:

		return false


	if !is_instance_valid(
		hangar
	):

		return false


	var local := hangar.to_local(
		nave.global_position
	)


	var largura := 180.0

	var profundidade := 240.0


	var largura_var: Variant = hangar.get(
		"largura_hangar"
	)

	var profundidade_var: Variant = hangar.get(
		"profundidade_hangar"
	)


	if largura_var != null:

		largura = float(
			largura_var
		)


	if profundidade_var != null:

		profundidade = float(
			profundidade_var
		)


	var dentro := (
		absf(
			local.x
		)
		<= largura * 0.5 - 4.0

		and absf(
			local.z
		)
		<= profundidade * 0.5 - 4.0
	)


	if !dentro:

		return false


	var velocidade := 0.0


	if mobile_controls != null:

		var v: Variant = mobile_controls.get(
			"velocidade_efetiva"
		)

		if v != null:

			velocidade = float(
				v
			)


	return (
		velocidade
		<= velocidade_max_para_descer
	)



# ============================================================
# DESCER DA NAVE
# ============================================================

func descer_da_nave() -> void:

	if !pode_descer():

		return


	if personagem == null:

		return


	if nave == null:

		return


	nave_processava = nave.is_processing()

	nave_processava_fisica = nave.is_physics_processing()


	# ========================================================
	# MOBILE
	# ========================================================

	if (
		mobile_controls != null
		and mobile_controls.has_method(
			"set_modo_a_pe"
		)
	):

		mobile_controls.call(
			"set_modo_a_pe",
			true
		)


	if (
		mobile_optimizer != null
		and mobile_optimizer.has_method(
			"set_modo_a_pe"
		)
	):

		mobile_optimizer.call(
			"set_modo_a_pe",
			true
		)


	# ========================================================
	# CONGELA NAVE
	# ========================================================

	nave.set_process(
		false
	)

	nave.set_physics_process(
		false
	)


	ativar_colisao_nave_a_pe(
		true
	)


	# ========================================================
	# SPAWN
	# ========================================================

	var spawn := calcular_spawn_personagem()


	personagem.global_position = spawn

	personagem.velocity = Vector3.ZERO


	personagem.rotation = Vector3(
		0.0,
		nave.global_rotation.y,
		0.0
	)


	personagem.visible = true

	personagem.process_mode = Node.PROCESS_MODE_INHERIT

	personagem.collision_layer = 1

	personagem.collision_mask = 1


	# ========================================================
	# RESETA ANIMACAO
	# ========================================================

	tempo_animacao = 0.0

	offset_yaw_camera = 0.0

	pitch_camera = deg_to_rad(
		-12.0
	)


	if perna_l != null:

		perna_l.rotation = Vector3.ZERO

		perna_r.rotation = Vector3.ZERO

		braco_l.rotation = Vector3.ZERO

		braco_r.rotation = Vector3.ZERO


	# ========================================================
	# CAMERA COMECA ATRAS DO PERSONAGEM
	# ========================================================

	camera_rig.global_position = (
		personagem.global_position
		+ Vector3.UP * 1.48
	)


	camera_rig.global_rotation = Vector3(
		0.0,
		personagem.global_rotation.y,
		0.0
	)


	camera_rig.visible = true


	if camera_nave != null:

		camera_nave.current = false


	if camera_pe != null:

		camera_pe.current = true


	modo_a_pe = true

	joystick_valor = Vector2.ZERO

	correr_mobile = false


	atualizar_interface_estado()


	print(
		"ON FOOT: policial desceu da P-01."
	)



# ============================================================
# CALCULAR SPAWN
# ============================================================

func calcular_spawn_personagem() -> Vector3:

	if (
		hangar != null
		and is_instance_valid(
			hangar
		)
	):

		var local_nave := hangar.to_local(
			nave.global_position
		)


		var piso_y := pegar_altura_piso_local()


		var local_spawn := Vector3(
			local_nave.x
			+ offset_spawn_personagem.x,

			piso_y + 0.03,

			local_nave.z
			+ offset_spawn_personagem.z
		)


		return hangar.to_global(
			local_spawn
		)


	return (
		nave.global_position
		+ nave.global_transform.basis.x.normalized()
		* 8.5
		+ Vector3.DOWN * 4.0
	)



# ============================================================
# ENTRAR NA NAVE
# ============================================================

func entrar_na_nave() -> void:

	if !modo_a_pe:

		return


	if personagem == null:

		return


	if nave == null:

		return


	if (
		personagem.global_position.distance_to(
			nave.global_position
		)
		> distancia_entrar_nave
	):

		return


	personagem.velocity = Vector3.ZERO


	ativar_colisao_nave_a_pe(
		false
	)


	personagem.visible = false

	personagem.process_mode = Node.PROCESS_MODE_DISABLED

	personagem.collision_layer = 0

	personagem.collision_mask = 0


	camera_rig.visible = false


	if camera_pe != null:

		camera_pe.current = false


	if camera_nave != null:

		camera_nave.current = true


	nave.set_process(
		nave_processava
	)

	nave.set_physics_process(
		nave_processava_fisica
	)


	if (
		mobile_controls != null
		and mobile_controls.has_method(
			"set_modo_a_pe"
		)
	):

		mobile_controls.call(
			"set_modo_a_pe",
			false
		)


	if (
		mobile_optimizer != null
		and mobile_optimizer.has_method(
			"set_modo_a_pe"
		)
	):

		mobile_optimizer.call(
			"set_modo_a_pe",
			false
		)


	modo_a_pe = false

	joystick_valor = Vector2.ZERO

	correr_mobile = false


	atualizar_interface_estado()


	print(
		"ON FOOT: policial entrou novamente na P-01."
	)



# ============================================================
# INTERFACE
# ============================================================

func criar_interface() -> void:

	camada_ui = CanvasLayer.new()

	camada_ui.name = "OnFootCanvas"

	camada_ui.layer = 135


	add_child(
		camada_ui
	)


	ui_root = Control.new()

	ui_root.name = "OnFootUI"

	ui_root.mouse_filter = Control.MOUSE_FILTER_IGNORE


	camada_ui.add_child(
		ui_root
	)

	# LAST SECOND PC BUILD:
	# A interface touch continua no codigo para voltarmos ao mobile depois,
	# mas nao deve aparecer na versao de PC.
	var pc_only: bool = !OS.has_feature("mobile")


	# ========================================================
	# DESCER
	# ========================================================

	botao_descer = criar_botao(
		"DESCER",
		Color(
			0.05,
			0.68,
			0.92,
			0.88
		)
	)


	botao_descer.pressed.connect(
		descer_da_nave
	)


	# ========================================================
	# ENTRAR
	# ========================================================

	botao_entrar = criar_botao(
		"ENTRAR",
		Color(
			0.04,
			0.78,
			0.56,
			0.88
		)
	)


	botao_entrar.pressed.connect(
		entrar_na_nave
	)


	# ========================================================
	# CORRER
	# ========================================================

	botao_correr = criar_botao(
		"CORRER",
		Color(
			0.12,
			0.52,
			0.98,
			0.82
		)
	)


	botao_correr.button_down.connect(
		func() -> void:

			correr_mobile = true
	)


	botao_correr.button_up.connect(
		func() -> void:

			correr_mobile = false
	)


	# ========================================================
	# JOYSTICK
	# ========================================================

	joystick_base = Panel.new()

	joystick_base.name = "JoystickBase"

	joystick_base.mouse_filter = Control.MOUSE_FILTER_IGNORE


	ui_root.add_child(
		joystick_base
	)


	var joy_style := StyleBoxFlat.new()

	joy_style.bg_color = Color(
		0.02,
		0.08,
		0.12,
		0.20
	)

	joy_style.border_color = Color(
		0.10,
		0.78,
		1.0,
		0.35
	)


	joy_style.set_border_width_all(
		2
	)

	joy_style.set_corner_radius_all(
		80
	)


	joystick_base.add_theme_stylebox_override(
		"panel",
		joy_style
	)


	# ========================================================
	# KNOB
	# ========================================================

	joystick_knob = Panel.new()

	joystick_knob.name = "JoystickKnob"

	joystick_knob.mouse_filter = Control.MOUSE_FILTER_IGNORE


	joystick_base.add_child(
		joystick_knob
	)


	var knob_style := StyleBoxFlat.new()

	knob_style.bg_color = Color(
		0.10,
		0.82,
		1.0,
		0.34
	)

	knob_style.border_color = Color(
		0.72,
		0.96,
		1.0,
		0.52
	)


	knob_style.set_border_width_all(
		2
	)

	knob_style.set_corner_radius_all(
		42
	)


	joystick_knob.add_theme_stylebox_override(
		"panel",
		knob_style
	)


	# ========================================================
	# LABEL MODO
	# ========================================================

	label_modo = Label.new()

	label_modo.text = "MODO A PE"

	label_modo.mouse_filter = Control.MOUSE_FILTER_IGNORE


	label_modo.add_theme_font_size_override(
		"font_size",
		15
	)


	label_modo.add_theme_color_override(
		"font_color",
		Color(
			0.62,
			0.92,
			1.0,
			0.82
		)
	)


	ui_root.add_child(
		label_modo
	)


	# ========================================================
	# DICA
	# ========================================================

	label_dica = Label.new()

	label_dica.text = (
		"JOYSTICK: ANDAR / GIRAR   •   ARRASTE: CAMERA"
	)


	label_dica.mouse_filter = Control.MOUSE_FILTER_IGNORE

	label_dica.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER


	label_dica.add_theme_font_size_override(
		"font_size",
		11
	)


	label_dica.add_theme_color_override(
		"font_color",
		Color(
			0.72,
			0.88,
			0.96,
			0.58
		)
	)


	ui_root.add_child(
		label_dica
	)

	if pc_only:
		botao_descer.visible = false
		botao_entrar.visible = false
		botao_correr.visible = false
		joystick_base.visible = false
		joystick_knob.visible = false
		label_dica.text = "PC // WASD: MOVER   •   MOUSE: CAMERA   •   SHIFT: CORRER   •   F: INTERAGIR"



# ============================================================
# CRIAR BOTAO
# ============================================================

func criar_botao(
	texto: String,
	cor: Color
) -> Button:

	var botao := Button.new()

	botao.text = texto

	botao.focus_mode = Control.FOCUS_NONE


	botao.add_theme_font_size_override(
		"font_size",
		16
	)


	ui_root.add_child(
		botao
	)


	var normal := StyleBoxFlat.new()


	normal.bg_color = Color(
		cor.r * 0.18,
		cor.g * 0.18,
		cor.b * 0.18,
		opacidade_ui
	)


	normal.border_color = cor


	normal.set_border_width_all(
		2
	)

	normal.set_corner_radius_all(
		12
	)


	var pressed := (
		normal.duplicate()
		as StyleBoxFlat
	)


	pressed.bg_color = Color(
		cor.r * 0.42,
		cor.g * 0.42,
		cor.b * 0.42,
		minf(
			opacidade_ui + 0.24,
			0.92
		)
	)


	botao.add_theme_stylebox_override(
		"normal",
		normal
	)

	botao.add_theme_stylebox_override(
		"hover",
		normal
	)

	botao.add_theme_stylebox_override(
		"pressed",
		pressed
	)

	botao.add_theme_stylebox_override(
		"focus",
		normal
	)


	botao.add_theme_color_override(
		"font_color",
		Color(
			0.88,
			0.97,
			1.0,
			0.96
		)
	)


	return botao



# ============================================================
# LAYOUT
# ============================================================

func atualizar_layout() -> void:

	if ui_root == null:

		return


	var tela := get_viewport().get_visible_rect().size


	ultimo_tamanho_tela = tela


	ui_root.position = Vector2.ZERO

	ui_root.size = tela


	var escala := clampf(
		minf(
			tela.x / 1280.0,
			tela.y / 720.0
		),
		0.70,
		1.25
	)


	var btn_w := 150.0 * escala

	var btn_h := 54.0 * escala

	var margem := 22.0 * escala


	# ========================================================
	# DESCER
	# ========================================================

	botao_descer.position = Vector2(
		(tela.x - btn_w) * 0.5,
		tela.y - btn_h - margem
	)

	botao_descer.size = Vector2(
		btn_w,
		btn_h
	)


	# ========================================================
	# JOYSTICK
	# ========================================================

	var joy_size := 150.0 * escala


	joystick_base.position = Vector2(
		margem,
		tela.y - joy_size - margem
	)


	joystick_base.size = Vector2(
		joy_size,
		joy_size
	)


	var knob_size := 64.0 * escala


	joystick_knob.size = Vector2(
		knob_size,
		knob_size
	)


	atualizar_joystick_visual()


	# ========================================================
	# CORRER
	# ========================================================

	botao_correr.position = Vector2(
		tela.x - btn_w - margem,
		tela.y - btn_h - margem
	)


	botao_correr.size = Vector2(
		btn_w,
		btn_h
	)


	# ========================================================
	# ENTRAR
	# ========================================================

	botao_entrar.position = Vector2(
		tela.x - btn_w - margem,
		tela.y
		- btn_h * 2.0
		- margem
		- 12.0 * escala
	)


	botao_entrar.size = Vector2(
		btn_w,
		btn_h
	)


	# ========================================================
	# LABEL
	# ========================================================

	label_modo.position = Vector2(
		margem,
		22.0 * escala
	)


	label_modo.size = Vector2(
		220.0 * escala,
		30.0 * escala
	)


	label_dica.position = Vector2(
		tela.x * 0.20,
		tela.y - 36.0 * escala
	)


	label_dica.size = Vector2(
		tela.x * 0.60,
		24.0 * escala
	)



# ============================================================
# ESTADO INTERFACE
# ============================================================

func atualizar_interface_estado() -> void:

	if ui_root == null:

		return

	# Na versao PC, nenhum controle de toque deve reaparecer.
	if !OS.has_feature("mobile"):
		if botao_descer != null:
			botao_descer.visible = false
		if botao_entrar != null:
			botao_entrar.visible = false
		if botao_correr != null:
			botao_correr.visible = false
		if joystick_base != null:
			joystick_base.visible = false
		if joystick_knob != null:
			joystick_knob.visible = false
		if label_modo != null:
			label_modo.visible = modo_a_pe
		if label_dica != null:
			label_dica.visible = modo_a_pe
		return


	if modo_a_pe:

		botao_descer.visible = false

		joystick_base.visible = true

		botao_correr.visible = true

		label_modo.visible = true

		label_dica.visible = true


		var perto := (
			personagem != null

			and nave != null

			and personagem.global_position.distance_to(
				nave.global_position
			)
			<= distancia_entrar_nave
		)


		botao_entrar.visible = perto


	else:

		joystick_base.visible = false

		botao_correr.visible = false

		botao_entrar.visible = false

		label_modo.visible = false

		label_dica.visible = false

		botao_descer.visible = pode_descer()



# ============================================================
# INPUT
# ============================================================

func _input(
	event: InputEvent
) -> void:

	if !modo_a_pe:

		return


	# ========================================================
	# TOUCH
	# ========================================================

	if event is InputEventScreenTouch:

		var toque := event as InputEventScreenTouch


		if toque.pressed:

			if ponto_no_joystick(
				toque.position
			):

				joystick_touch_id = toque.index

				atualizar_joystick(
					toque.position
				)

				get_viewport().set_input_as_handled()

				return


			if ponto_em_botao(
				toque.position
			):

				return


			camera_touch_id = toque.index


		else:

			if toque.index == joystick_touch_id:

				joystick_touch_id = -1

				joystick_valor = Vector2.ZERO

				atualizar_joystick_visual()

				get_viewport().set_input_as_handled()


			if toque.index == camera_touch_id:

				camera_touch_id = -1


		return


	# ========================================================
	# DRAG
	# ========================================================

	if event is InputEventScreenDrag:

		var drag := event as InputEventScreenDrag


		if drag.index == joystick_touch_id:

			atualizar_joystick(
				drag.position
			)

			get_viewport().set_input_as_handled()

			return


		if drag.index == camera_touch_id:

			girar_camera(
				drag.relative
			)

			get_viewport().set_input_as_handled()

			return


	# ========================================================
	# MOUSE
	# ========================================================

	if event is InputEventMouseButton:

		var mouse_button := (
			event
			as InputEventMouseButton
		)


		if (
			mouse_button.button_index
			== MOUSE_BUTTON_LEFT

			or mouse_button.button_index
			== MOUSE_BUTTON_RIGHT
		):

			if mouse_button.pressed:

				if (
					mouse_button.button_index
					== MOUSE_BUTTON_RIGHT

					or !ponto_em_ui_interativa(
						mouse_button.position
					)
				):

					mouse_camera_arrastando = true

					get_viewport().set_input_as_handled()


			else:

				mouse_camera_arrastando = false


		return


	# ========================================================
	# MOVIMENTO DO MOUSE
	# ========================================================

	if event is InputEventMouseMotion:

		if mouse_camera_arrastando:

			var motion := (
				event
				as InputEventMouseMotion
			)


			girar_camera(
				motion.relative
			)


			get_viewport().set_input_as_handled()



# ============================================================
# UI INTERATIVA
# ============================================================

func ponto_em_ui_interativa(
	p: Vector2
) -> bool:

	if ponto_no_joystick(
		p
	):

		return true


	return ponto_em_botao(
		p
	)



# ============================================================
# JOYSTICK AREA
# ============================================================

func ponto_no_joystick(
	p: Vector2
) -> bool:

	if joystick_base == null:

		return false


	if !joystick_base.visible:

		return false


	return Rect2(
		joystick_base.global_position,
		joystick_base.size
	).has_point(
		p
	)



# ============================================================
# BOTOES
# ============================================================

func ponto_em_botao(
	p: Vector2
) -> bool:

	for botao: Button in [
		botao_entrar,
		botao_correr
	]:

		if (
			botao != null
			and botao.visible
		):

			var rect := Rect2(
				botao.global_position,
				botao.size
			)


			if rect.has_point(
				p
			):

				return true


	return false



# ============================================================
# ATUALIZAR JOYSTICK
# ============================================================

func atualizar_joystick(
	pos_tela: Vector2
) -> void:

	var centro := (
		joystick_base.global_position
		+ joystick_base.size * 0.5
	)


	var delta := (
		pos_tela
		- centro
	)


	var raio := (
		joystick_base.size.x
		* 0.36
	)


	if delta.length() > raio:

		delta = (
			delta.normalized()
			* raio
		)


	joystick_valor = (
		delta
		/ maxf(
			raio,
			1.0
		)
	)


	atualizar_joystick_visual()



# ============================================================
# VISUAL JOYSTICK
# ============================================================

func atualizar_joystick_visual() -> void:

	if joystick_base == null:

		return


	if joystick_knob == null:

		return


	var centro_local := (
		joystick_base.size
		* 0.5
	)


	var raio := (
		joystick_base.size.x
		* 0.36
	)


	var offset := (
		joystick_valor
		* raio
	)


	joystick_knob.position = (
		centro_local
		- joystick_knob.size * 0.5
		+ offset
	)



# ============================================================
# GIRAR CAMERA
# ============================================================

func girar_camera(
	delta_tela: Vector2
) -> void:

	# ========================================================
	# HORIZONTAL
	#
	# Agora alteramos somente o ANGULO RELATIVO ao jogador.
	#
	# Quando o personagem gira, esse angulo vai junto.
	# ========================================================

	offset_yaw_camera -= (
		delta_tela.x
		* sensibilidade_camera
	)


	# Evita acumular numeros gigantes.

	offset_yaw_camera = wrapf(
		offset_yaw_camera,
		-PI,
		PI
	)


	# ========================================================
	# VERTICAL
	# ========================================================

	pitch_camera -= (
		delta_tela.y
		* sensibilidade_camera
	)


	pitch_camera = clampf(
		pitch_camera,
		deg_to_rad(
			limite_camera_cima
		),
		deg_to_rad(
			limite_camera_baixo
		)
	)
