extends Node

# =========================================================
# LAST SECOND
# SPACE DEBRIS v1.1 // HANGAR SAFE + ZERO-G PHYSICS + RADAR
#
# Anexar em um Node chamado SpaceDebris.
# - meteoros e destrocos com RigidBody3D
# - gravidade zero
# - colisao real em layer 1
# - aparecem no radar como contatos cinza
# - tiros podem destruir os objetos
# - objetos sao reciclados longe do player
# =========================================================

@export_range(4, 24, 1) var quantidade_destrocos: int = 12
@export_range(40.0, 300.0, 5.0) var distancia_min_spawn: float = 65.0
@export_range(80.0, 500.0, 5.0) var distancia_max_spawn: float = 180.0
@export_range(100.0, 800.0, 10.0) var distancia_reciclagem: float = 280.0
@export_range(0.0, 8.0, 0.1) var velocidade_max_drift: float = 2.2
@export_range(0.0, 3.0, 0.1) var rotacao_maxima: float = 0.8

var player: Node3D = null
var hangar_base: Node3D = null
var destrocos: Array[RigidBody3D] = []
var tempo_manutencao: float = 0.0

var mat_rocha: StandardMaterial3D
var mat_rocha_clara: StandardMaterial3D
var mat_metal: StandardMaterial3D
var mat_metal_escuro: StandardMaterial3D
var mat_emissivo: StandardMaterial3D


func _ready() -> void:
	await get_tree().process_frame
	await get_tree().process_frame
	localizar_player()
	criar_materiais()

	# Nao cria meteoros/destrocos enquanto a P-01 estiver dentro da base.
	if !player_dentro_hangar():
		completar_destrocos()

	print("SPACE DEBRIS v1.1 // HANGAR SAFE // ", quantidade_destrocos, " OBJETOS")


func _physics_process(delta: float) -> void:
	tempo_manutencao += delta
	if tempo_manutencao < 0.25:
		return
	tempo_manutencao = 0.0

	if player == null or !is_instance_valid(player):
		localizar_player()
		if player == null:
			return

	# Base limpa: ao entrar no hangar, removemos todos os objetos espaciais.
	if player_dentro_hangar():
		limpar_destrocos()
		return

	for i: int in range(destrocos.size() - 1, -1, -1):
		var corpo: RigidBody3D = destrocos[i]

		if corpo == null or !is_instance_valid(corpo):
			destrocos.remove_at(i)
			continue

		if ponto_dentro_hangar(corpo.global_position, 8.0):
			reciclar_destroco(corpo)
			continue

		if corpo.global_position.distance_to(player.global_position) > distancia_reciclagem:
			reciclar_destroco(corpo)

	completar_destrocos()


func localizar_player() -> void:
	var cena: Node = get_tree().current_scene
	if cena == null:
		return
	player = cena.get_node_or_null("Player") as Node3D
	if player == null:
		var p: Node = cena.find_child("Player", true, false)
		if p is Node3D:
			player = p as Node3D

	hangar_base = cena.get_node_or_null("HangarBase") as Node3D
	if hangar_base == null:
		var h: Node = cena.find_child("HangarBase", true, false)
		if h is Node3D:
			hangar_base = h as Node3D


func limpar_destrocos() -> void:
	for corpo: RigidBody3D in destrocos:
		if corpo != null and is_instance_valid(corpo):
			corpo.queue_free()

	destrocos.clear()


func player_dentro_hangar() -> bool:
	if player == null:
		return false
	return ponto_dentro_hangar(player.global_position, 0.0)


func ponto_dentro_hangar(
	posicao_global: Vector3,
	margem: float = 0.0
) -> bool:
	if hangar_base == null or !is_instance_valid(hangar_base):
		return false

	if hangar_base.has_method("ponto_dentro_hangar"):
		return bool(
			hangar_base.call(
				"ponto_dentro_hangar",
				posicao_global,
				margem
			)
		)

	var local: Vector3 = hangar_base.to_local(posicao_global)

	var largura: float = 180.0
	var profundidade: float = 240.0
	var altura: float = 32.0

	var v: Variant = hangar_base.get("largura_hangar")
	if v != null:
		largura = float(v)
	v = hangar_base.get("profundidade_hangar")
	if v != null:
		profundidade = float(v)
	v = hangar_base.get("altura_hangar")
	if v != null:
		altura = float(v)

	return (
		absf(local.x) <= largura * 0.5 + margem
		and absf(local.z) <= profundidade * 0.5 + margem
		and local.y >= -3.0 - margem
		and local.y <= altura + margem
	)


func criar_materiais() -> void:
	mat_rocha = criar_material(Color(0.16, 0.13, 0.11), Color.BLACK, 0.0, 0.94, 0.0)
	mat_rocha_clara = criar_material(Color(0.26, 0.23, 0.20), Color.BLACK, 0.0, 0.90, 0.0)
	mat_metal = criar_material(Color(0.25, 0.30, 0.36), Color.BLACK, 0.72, 0.40, 0.0)
	mat_metal_escuro = criar_material(Color(0.08, 0.10, 0.13), Color.BLACK, 0.65, 0.52, 0.0)
	mat_emissivo = criar_material(Color(0.10, 0.18, 0.20), Color(0.00, 0.75, 1.00), 0.25, 0.20, 1.2)


func completar_destrocos() -> void:
	if player == null:
		return
	while destrocos.size() < quantidade_destrocos:
		var corpo: RigidBody3D = criar_destroco(destrocos.size())
		add_child(corpo)
		destrocos.append(corpo)
		reciclar_destroco(corpo)


func criar_destroco(indice: int) -> RigidBody3D:
	var corpo := RigidBody3D.new()
	corpo.name = "Destroco_%02d" % indice
	corpo.gravity_scale = 0.0
	corpo.linear_damp = 0.0
	corpo.angular_damp = 0.0
	corpo.mass = randf_range(1.0, 8.0)
	corpo.collision_layer = 1
	corpo.collision_mask = 1
	corpo.add_to_group("radar_targets")
	corpo.add_to_group("space_debris")
	corpo.set_meta("radar_kind", "debris")

	if randf() < 0.58:
		construir_meteoro(corpo)
	else:
		construir_destroco_metalico(corpo)

	return corpo


func construir_meteoro(corpo: RigidBody3D) -> void:
	var raio: float = randf_range(1.6, 4.2)

	var mesh_i := MeshInstance3D.new()
	var mesh := SphereMesh.new()
	mesh.radius = raio
	mesh.height = raio * 2.0
	mesh.radial_segments = 8
	mesh.rings = 5
	mesh_i.mesh = mesh
	mesh_i.scale = Vector3(randf_range(0.75, 1.25), randf_range(0.70, 1.20), randf_range(0.80, 1.30))
	mesh_i.material_override = mat_rocha if randf() < 0.6 else mat_rocha_clara
	mesh_i.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	corpo.add_child(mesh_i)

	var collision := CollisionShape3D.new()
	var shape := SphereShape3D.new()
	shape.radius = raio
	collision.shape = shape
	corpo.add_child(collision)


func construir_destroco_metalico(corpo: RigidBody3D) -> void:
	var tamanho := Vector3(randf_range(2.5, 5.5), randf_range(0.8, 2.2), randf_range(3.0, 7.0))

	var principal := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = tamanho
	principal.mesh = mesh
	principal.material_override = mat_metal_escuro
	principal.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	corpo.add_child(principal)

	var asa := MeshInstance3D.new()
	var asa_mesh := BoxMesh.new()
	asa_mesh.size = Vector3(tamanho.x * 1.4, 0.18, tamanho.z * 0.55)
	asa.mesh = asa_mesh
	asa.position = Vector3(0.0, tamanho.y * 0.25, 0.0)
	asa.rotation.z = randf_range(-0.35, 0.35)
	asa.material_override = mat_metal
	asa.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	corpo.add_child(asa)

	if randf() < 0.5:
		var luz := MeshInstance3D.new()
		var luz_mesh := BoxMesh.new()
		luz_mesh.size = Vector3(0.30, 0.12, 0.50)
		luz.mesh = luz_mesh
		luz.position = Vector3(0.0, tamanho.y * 0.55, -tamanho.z * 0.30)
		luz.material_override = mat_emissivo
		luz.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		corpo.add_child(luz)

	var collision := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = tamanho
	collision.shape = shape
	corpo.add_child(collision)


func reciclar_destroco(corpo: RigidBody3D) -> void:
	if player == null or corpo == null:
		return

	var direcao := Vector3(
		randf_range(-1.0, 1.0),
		randf_range(-0.45, 0.45),
		randf_range(-1.0, 1.0)
	).normalized()
	if direcao.length() < 0.01:
		direcao = Vector3.FORWARD

	var distancia := randf_range(distancia_min_spawn, distancia_max_spawn)
	var nova_posicao: Vector3 = player.global_position + direcao * distancia

	# Nunca recicla um objeto para dentro do volume da base.
	var tentativas: int = 0
	while ponto_dentro_hangar(nova_posicao, 12.0) and tentativas < 12:
		direcao = Vector3(
			randf_range(-1.0, 1.0),
			randf_range(-0.45, 0.45),
			randf_range(-1.0, 1.0)
		).normalized()
		if direcao.length() < 0.01:
			direcao = Vector3.FORWARD
		distancia = randf_range(distancia_min_spawn, distancia_max_spawn)
		nova_posicao = player.global_position + direcao * distancia
		tentativas += 1

	if ponto_dentro_hangar(nova_posicao, 12.0) and hangar_base != null:
		var local: Vector3 = hangar_base.to_local(nova_posicao)
		local.z = -150.0
		nova_posicao = hangar_base.to_global(local)

	corpo.global_position = nova_posicao
	corpo.linear_velocity = Vector3(
		randf_range(-velocidade_max_drift, velocidade_max_drift),
		randf_range(-velocidade_max_drift * 0.45, velocidade_max_drift * 0.45),
		randf_range(-velocidade_max_drift, velocidade_max_drift)
	)
	corpo.angular_velocity = Vector3(
		randf_range(-rotacao_maxima, rotacao_maxima),
		randf_range(-rotacao_maxima, rotacao_maxima),
		randf_range(-rotacao_maxima, rotacao_maxima)
	)


func criar_material(
	albedo: Color,
	emission: Color,
	metallic: float,
	roughness: float,
	emission_energy: float
) -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	mat.albedo_color = albedo
	mat.metallic = metallic
	mat.roughness = roughness
	if emission_energy > 0.0:
		mat.emission_enabled = true
		mat.emission = emission
		mat.emission_energy_multiplier = emission_energy
	return mat
