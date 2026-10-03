extends Node

# =========================================================
# LAST SECOND
# SPACE TRAFFIC v2.6 // HANGAR EXCLUSION + RADAR // 90% A 5 U/S + 10% A 40 U/S
# NAVES VARIADAS + COLISAO LEVE + MOBILE FRIENDLY
#
# IMPORTANTE:
# - Este script foi feito para ser anexado a um no do tipo Node.
# - As naves 3D sao criadas como filhos Node3D automaticamente.
# =========================================================

@export var quantidade_naves: int = 7
@export var raio_spawn: float = 180.0
@export var distancia_reciclagem: float = 220.0
@export var faixa_lateral: float = 85.0
@export var altura_minima: float = -14.0
@export var altura_maxima: float = 18.0
@export var velocidade_trafego_normal: float = 5.0
@export var velocidade_trafego_rapido: float = 40.0
@export_range(0.0, 1.0, 0.01) var chance_trafego_rapido: float = 0.10
@export var distancia_minima_do_player: float = 25.0
@export var aguardar_saida_do_hangar: bool = true
@export_range(60.0, 220.0, 5.0) var distancia_para_ativar_trafego: float = 120.0

@export var repulsao_colisao: float = 18.0
@export var raio_colisao_extra: float = 2.2

# Distribuicao de velocidade:
# - 90% das naves ficam em 5 U/S
# - 10% passam em 40 U/S
# A velocidade e sorteada quando a nave nasce e quando e reciclada.

var player: Node3D = null
var camera: Camera3D = null
var hangar_base: Node3D = null

var naves: Array = []

var trafego_ativo: bool = false
var posicao_inicio_player: Vector3 = Vector3.ZERO
var posicao_inicio_definida: bool = false

var mat_casco_escuro: StandardMaterial3D
var mat_casco_cinza: StandardMaterial3D
var mat_casco_azulado: StandardMaterial3D
var mat_luz_ciano: StandardMaterial3D
var mat_luz_laranja: StandardMaterial3D
var mat_motor_azul: StandardMaterial3D
var mat_motor_vermelho: StandardMaterial3D
var mat_vidro: StandardMaterial3D

enum TipoNave {
	INTERCEPTOR,
	CARGUEIRO,
	SHUTTLE
}


func _ready() -> void:
	await get_tree().process_frame
	await get_tree().process_frame

	localizar_player_camera()
	criar_materiais()

	# Espera o HangarBase terminar de colocar a P-01 na vaga correta.
	# Assim guardamos como origem exatamente o ponto de partida no hangar.
	for _i: int in range(4):
		await get_tree().physics_frame

	localizar_player_camera()

	if player != null:
		posicao_inicio_player = player.global_position
		posicao_inicio_definida = true

	if aguardar_saida_do_hangar:
		trafego_ativo = false
		limpar_trafego_existente()
		print("SPACE TRAFFIC v2.6: aguardando P-01 sair do hangar.")
	else:
		ativar_trafego()

	print("========================================")
	print("SPACE TRAFFIC v2.6 // HANGAR EXCLUSION + RADAR")
	print("QUANTIDADE PREVISTA: ", quantidade_naves)
	print("ATIVACAO APOS: ", distancia_para_ativar_trafego, " U")
	print("========================================")


func _physics_process(delta: float) -> void:
	if player == null or !is_instance_valid(player):
		localizar_player_camera()
		if player == null:
			return

	# Sempre que a P-01 estiver dentro da base, o espaco ao redor do hangar
	# fica limpo. Ao sair novamente, o trafego volta depois da distancia segura.
	if player_dentro_hangar():
		if trafego_ativo or !naves.is_empty():
			limpar_trafego_existente()
		trafego_ativo = false
		posicao_inicio_player = player.global_position
		posicao_inicio_definida = true
		return

	# Enquanto a P-01 ainda estiver no hangar, nenhuma nave aleatoria existe.
	# Isso impede NaveTrafego_0...6 de nascer no corredor da base.
	if !trafego_ativo:
		if !posicao_inicio_definida:
			posicao_inicio_player = player.global_position
			posicao_inicio_definida = true
			return

		var distancia_saida: float = player.global_position.distance_to(posicao_inicio_player)
		if !aguardar_saida_do_hangar or distancia_saida >= distancia_para_ativar_trafego:
			ativar_trafego()
		else:
			return

	for info: Dictionary in naves:
		if !info.has("node"):
			continue

		var nave: Node3D = info["node"] as Node3D
		if nave == null or !is_instance_valid(nave):
			continue

		var dir: Vector3 = info["dir"]
		var dist_player: float = nave.global_position.distance_to(player.global_position)
		var vel: float = float(info.get("vel", velocidade_trafego_normal))

		var proxima_posicao: Vector3 = nave.global_position + dir * vel * delta

		# Nave civil nunca atravessa parede/teto/portao do hangar.
		# Antes de aplicar o movimento, checamos o volume protegido.
		if ponto_dentro_hangar(proxima_posicao, 8.0):
			reciclar_nave(info)
			continue

		nave.global_position = proxima_posicao

		var alvo_rot_y: float = atan2(-dir.x, -dir.z)
		nave.rotation.y = lerp_angle(nave.rotation.y, alvo_rot_y, delta * 2.5)

		if dist_player > distancia_reciclagem:
			reciclar_nave(info)



func ativar_trafego() -> void:
	if trafego_ativo:
		return

	trafego_ativo = true
	limpar_trafego_existente()
	criar_trafego()

	print(
		"SPACE TRAFFIC v2.5: P-01 saiu da base - ",
		naves.size(),
		" naves aleatorias ativadas."
	)


func limpar_trafego_existente() -> void:
	for info: Dictionary in naves:
		if !info.has("node"):
			continue

		var nave: Node3D = info["node"] as Node3D
		if nave != null and is_instance_valid(nave):
			nave.queue_free()

	naves.clear()

	# Segurança contra qualquer NaveTrafego antiga que tenha sido criada
	# antes deste script terminar a inicialização.
	for no: Node in get_tree().get_nodes_in_group("traffic_ship"):
		if no is Node3D and no != player:
			no.queue_free()


func localizar_player_camera() -> void:
	var cena: Node = get_tree().current_scene
	if cena == null:
		return

	player = cena.get_node_or_null("Player") as Node3D
	if player == null:
		var p: Node = cena.find_child("Player", true, false)
		if p is Node3D:
			player = p as Node3D

	camera = cena.get_node_or_null("Player/Camera3D") as Camera3D
	if camera == null:
		var c: Node = cena.find_child("Camera3D", true, false)
		if c is Camera3D:
			camera = c as Camera3D

	hangar_base = cena.get_node_or_null("HangarBase") as Node3D
	if hangar_base == null:
		var h: Node = cena.find_child("HangarBase", true, false)
		if h is Node3D:
			hangar_base = h as Node3D


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
	mat_casco_escuro = criar_material(
		Color(0.08, 0.09, 0.12),
		Color(0.0, 0.0, 0.0),
		0.65,
		0.15,
		1.0
	)

	mat_casco_cinza = criar_material(
		Color(0.18, 0.20, 0.23),
		Color(0.0, 0.0, 0.0),
		0.55,
		0.10,
		1.0
	)

	mat_casco_azulado = criar_material(
		Color(0.10, 0.13, 0.18),
		Color(0.0, 0.0, 0.0),
		0.50,
		0.08,
		1.0
	)

	mat_luz_ciano = criar_material(
		Color(0.03, 0.10, 0.14),
		Color(0.00, 0.85, 1.00),
		0.20,
		0.05,
		1.8
	)

	mat_luz_laranja = criar_material(
		Color(0.16, 0.09, 0.02),
		Color(1.0, 0.50, 0.08),
		0.20,
		0.05,
		1.6
	)

	mat_motor_azul = criar_material(
		Color(0.02, 0.05, 0.10),
		Color(0.25, 0.70, 1.0),
		0.10,
		0.02,
		2.4
	)

	mat_motor_vermelho = criar_material(
		Color(0.10, 0.02, 0.02),
		Color(1.0, 0.18, 0.12),
		0.10,
		0.02,
		2.1
	)

	mat_vidro = criar_material(
		Color(0.08, 0.15, 0.20, 0.55),
		Color(0.00, 0.55, 0.75),
		0.05,
		0.01,
		0.8
	)
	mat_vidro.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA


func criar_trafego() -> void:
	for i: int in range(quantidade_naves):
		var info: Dictionary = criar_nave_info(i)
		naves.append(info)


func escolher_velocidade_trafego() -> float:
	if randf() < chance_trafego_rapido:
		return velocidade_trafego_rapido
	return velocidade_trafego_normal


func criar_nave_info(indice: int) -> Dictionary:
	var tipo: int = randi() % 3
	var raiz := AnimatableBody3D.new()
	raiz.name = "NaveTrafego_%d" % indice
	raiz.collision_layer = 1
	raiz.collision_mask = 1
	raiz.sync_to_physics = true
	raiz.add_to_group("radar_targets")
	raiz.add_to_group("traffic_ship")
	raiz.set_meta("radar_kind", "traffic")
	add_child(raiz)

	var raio_colisao: float = 2.5
	match tipo:
		TipoNave.INTERCEPTOR:
			raio_colisao = construir_interceptor(raiz)
		TipoNave.CARGUEIRO:
			raio_colisao = construir_cargueiro(raiz)
		TipoNave.SHUTTLE:
			raio_colisao = construir_shuttle(raiz)

	var collision := CollisionShape3D.new()
	var sphere := SphereShape3D.new()
	sphere.radius = raio_colisao
	collision.shape = sphere
	raiz.add_child(collision)

	var direcao: Vector3 = escolher_direcao()
	var velocidade: float = escolher_velocidade_trafego()

	var info: Dictionary = {
		"node": raiz,
		"tipo": tipo,
		"dir": direcao,
		"vel": velocidade,
		"raio": raio_colisao
	}

	posicionar_nave_inicial(info)
	return info


func escolher_direcao() -> Vector3:
	var opcoes: Array[Vector3] = [
		Vector3.LEFT,
		Vector3.RIGHT,
		Vector3.FORWARD,
		Vector3.BACK
	]
	return opcoes[randi() % opcoes.size()].normalized()


func posicionar_nave_inicial(info: Dictionary) -> void:
	if player == null:
		return

	var nave: Node3D = info["node"] as Node3D
	var dir: Vector3 = info["dir"]

	var lateral: Vector3 = Vector3(-dir.z, 0.0, dir.x).normalized()
	var frente_spawn: Vector3 = -dir * randf_range(70.0, raio_spawn)

	var lateral_offset: float = randf_range(-faixa_lateral, faixa_lateral)
	var altura: float = randf_range(altura_minima, altura_maxima)

	var pos: Vector3 = player.global_position
	pos += frente_spawn
	pos += lateral * lateral_offset
	pos.y += altura

	if pos.distance_to(player.global_position) < distancia_minima_do_player:
		pos += dir * distancia_minima_do_player

	var tentativas: int = 0
	while ponto_dentro_hangar(pos, 10.0) and tentativas < 10:
		pos = player.global_position
		pos += frente_spawn
		pos += lateral * randf_range(-faixa_lateral, faixa_lateral)
		pos.y += randf_range(altura_minima, altura_maxima)
		tentativas += 1

	if ponto_dentro_hangar(pos, 10.0) and hangar_base != null:
		var local: Vector3 = hangar_base.to_local(pos)
		local.z = -profundidade_hangar_segura() * 0.5 - 25.0
		pos = hangar_base.to_global(local)

	nave.global_position = pos
	nave.rotation.y = atan2(-dir.x, -dir.z)


func reciclar_nave(info: Dictionary) -> void:
	if player == null:
		return

	var nave: Node3D = info["node"] as Node3D
	var dir: Vector3 = escolher_direcao()
	info["dir"] = dir
	info["vel"] = escolher_velocidade_trafego()

	var lateral: Vector3 = Vector3(-dir.z, 0.0, dir.x).normalized()
	var spawn_dist: float = randf_range(120.0, raio_spawn)
	var pos: Vector3 = player.global_position
	pos -= dir * spawn_dist
	pos += lateral * randf_range(-faixa_lateral, faixa_lateral)
	pos.y += randf_range(altura_minima, altura_maxima)

	var tentativas: int = 0
	while ponto_dentro_hangar(pos, 10.0) and tentativas < 10:
		dir = escolher_direcao()
		info["dir"] = dir
		lateral = Vector3(-dir.z, 0.0, dir.x).normalized()
		pos = player.global_position
		pos -= dir * randf_range(120.0, raio_spawn)
		pos += lateral * randf_range(-faixa_lateral, faixa_lateral)
		pos.y += randf_range(altura_minima, altura_maxima)
		tentativas += 1

	if ponto_dentro_hangar(pos, 10.0) and hangar_base != null:
		var local: Vector3 = hangar_base.to_local(pos)
		local.z = -profundidade_hangar_segura() * 0.5 - 25.0
		pos = hangar_base.to_global(local)

	nave.global_position = pos
	nave.rotation.y = atan2(-dir.x, -dir.z)


func profundidade_hangar_segura() -> float:
	if hangar_base == null:
		return 240.0

	var v: Variant = hangar_base.get("profundidade_hangar")
	if v != null:
		return float(v)

	return 240.0


func aplicar_bloqueio_no_player(info: Dictionary, delta: float) -> void:
	if player == null:
		return

	var nave: Node3D = info["node"] as Node3D
	var raio: float = float(info["raio"]) + raio_colisao_extra

	var origem_player: Vector3 = player.global_position
	var origem_nave: Vector3 = nave.global_position

	var delta_vec: Vector3 = origem_player - origem_nave
	var dist: float = delta_vec.length()

	if dist <= 0.001:
		delta_vec = Vector3(0.01, 0.0, 0.0)
		dist = 0.01

	if dist < raio:
		var direcao_escape: Vector3 = delta_vec.normalized()
		var penetracao: float = raio - dist
		player.global_position += direcao_escape * penetracao * repulsao_colisao * delta

		if abs(player.global_position.y - origem_nave.y) < 3.0:
			player.global_position.y = lerp(
				player.global_position.y,
				origem_player.y + direcao_escape.y * 0.3,
				delta * 3.0
			)


# =========================================================
# MODELOS DE NAVES
# =========================================================

func construir_interceptor(pai: Node3D) -> float:
	pai.add_child(criar_bloco(Vector3(0.0, 0.0, 0.0), Vector3(1.9, 0.45, 3.5), mat_casco_escuro))
	pai.add_child(criar_bloco(Vector3(0.0, 0.0, -2.35), Vector3(0.8, 0.25, 1.3), mat_casco_cinza))
	pai.add_child(criar_bloco(Vector3(-1.7, 0.0, -0.1), Vector3(1.9, 0.08, 1.5), mat_casco_azulado))
	pai.add_child(criar_bloco(Vector3(1.7, 0.0, -0.1), Vector3(1.9, 0.08, 1.5), mat_casco_azulado))
	pai.add_child(criar_bloco(Vector3(0.0, 0.32, -0.6), Vector3(0.75, 0.30, 0.95), mat_vidro))
	pai.add_child(criar_bloco(Vector3(-0.55, 0.0, 1.95), Vector3(0.35, 0.22, 0.7), mat_motor_azul))
	pai.add_child(criar_bloco(Vector3(0.55, 0.0, 1.95), Vector3(0.35, 0.22, 0.7), mat_motor_azul))
	pai.add_child(criar_bloco(Vector3(0.0, -0.08, -1.95), Vector3(0.35, 0.05, 0.18), mat_luz_ciano))
	return 3.2


func construir_cargueiro(pai: Node3D) -> float:
	pai.add_child(criar_bloco(Vector3(0.0, 0.0, 0.0), Vector3(2.6, 0.9, 4.8), mat_casco_cinza))
	pai.add_child(criar_bloco(Vector3(0.0, 0.0, -2.7), Vector3(1.9, 0.7, 1.2), mat_casco_azulado))
	pai.add_child(criar_bloco(Vector3(0.0, 0.0, 2.9), Vector3(1.8, 0.7, 1.0), mat_casco_escuro))
	pai.add_child(criar_bloco(Vector3(-2.2, -0.08, 0.5), Vector3(1.3, 0.12, 3.0), mat_casco_escuro))
	pai.add_child(criar_bloco(Vector3(2.2, -0.08, 0.5), Vector3(1.3, 0.12, 3.0), mat_casco_escuro))
	pai.add_child(criar_bloco(Vector3(0.0, 0.72, -1.4), Vector3(0.95, 0.35, 1.0), mat_vidro))
	pai.add_child(criar_bloco(Vector3(-0.9, 0.0, 3.7), Vector3(0.45, 0.32, 0.8), mat_motor_vermelho))
	pai.add_child(criar_bloco(Vector3(0.9, 0.0, 3.7), Vector3(0.45, 0.32, 0.8), mat_motor_vermelho))
	pai.add_child(criar_bloco(Vector3(0.0, 0.52, 0.0), Vector3(0.30, 0.06, 0.30), mat_luz_laranja))
	return 4.4


func construir_shuttle(pai: Node3D) -> float:
	pai.add_child(criar_bloco(Vector3(0.0, 0.0, 0.0), Vector3(1.8, 0.75, 3.0), mat_casco_azulado))
	pai.add_child(criar_bloco(Vector3(0.0, 0.08, -1.95), Vector3(1.0, 0.45, 1.0), mat_casco_cinza))
	pai.add_child(criar_bloco(Vector3(0.0, 0.52, -0.5), Vector3(1.2, 0.25, 1.5), mat_vidro))
	pai.add_child(criar_bloco(Vector3(-1.35, -0.05, 0.3), Vector3(1.0, 0.10, 1.8), mat_casco_escuro))
	pai.add_child(criar_bloco(Vector3(1.35, -0.05, 0.3), Vector3(1.0, 0.10, 1.8), mat_casco_escuro))
	pai.add_child(criar_bloco(Vector3(-0.58, -0.15, 1.85), Vector3(0.34, 0.26, 0.7), mat_motor_azul))
	pai.add_child(criar_bloco(Vector3(0.58, -0.15, 1.85), Vector3(0.34, 0.26, 0.7), mat_motor_azul))
	pai.add_child(criar_bloco(Vector3(0.0, 0.0, -2.45), Vector3(0.28, 0.05, 0.18), mat_luz_ciano))
	return 3.0


# =========================================================
# HELPERS
# =========================================================

func criar_bloco(
	pos: Vector3,
	tamanho: Vector3,
	material: Material
) -> MeshInstance3D:
	var mesh := BoxMesh.new()
	mesh.size = tamanho

	var mi := MeshInstance3D.new()
	mi.mesh = mesh
	mi.material_override = material
	mi.position = pos
	return mi


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
	mat.emission_enabled = true
	mat.emission = emission
	mat.emission_energy_multiplier = emission_energy
	return mat
