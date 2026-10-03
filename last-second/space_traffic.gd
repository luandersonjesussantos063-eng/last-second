extends Node

# =========================================================
# LAST SECOND
# SPACE TRAFFIC v3.0 // PC // TRAFEGO ESTAVEL + NAVES 3D
# =========================================================

@export var quantidade_naves: int = 10
@export var raio_spawn_min: float = 130.0
@export var raio_spawn_max: float = 260.0
@export var distancia_reciclagem: float = 330.0
@export var faixa_lateral: float = 115.0
@export var altura_minima: float = -18.0
@export var altura_maxima: float = 34.0
@export var velocidade_minima: float = 18.0
@export var velocidade_maxima: float = 38.0
@export var velocidade_rapida: float = 62.0
@export_range(0.0, 1.0, 0.01) var chance_trafego_rapido: float = 0.12
@export var distancia_minima_do_player: float = 45.0
@export var aguardar_saida_do_hangar: bool = true
@export_range(40.0, 220.0, 5.0) var distancia_para_ativar_trafego: float = 90.0
@export var tempo_maximo_sem_mover: float = 0.75

var player: Node3D = null
var hangar_base: Node3D = null
var naves: Array[Dictionary] = []
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
	randomize()
	await get_tree().process_frame
	await get_tree().process_frame
	localizar_referencias()
	criar_materiais()

	for _i in range(3):
		await get_tree().physics_frame

	localizar_referencias()

	if player != null:
		posicao_inicio_player = player.global_position
		posicao_inicio_definida = true

	if aguardar_saida_do_hangar:
		limpar_trafego_existente()
		trafego_ativo = false
	else:
		ativar_trafego()

	print("SPACE TRAFFIC v3.0 pronto")

func _physics_process(delta: float) -> void:
	if player == null or !is_instance_valid(player):
		localizar_referencias()
		if player == null:
			return

	if player_dentro_hangar():
		if trafego_ativo or !naves.is_empty():
			limpar_trafego_existente()
			trafego_ativo = false
		posicao_inicio_player = player.global_position
		posicao_inicio_definida = true
		return

	if !trafego_ativo:
		if !posicao_inicio_definida:
			posicao_inicio_player = player.global_position
			posicao_inicio_definida = true
			return

		if !aguardar_saida_do_hangar or player.global_position.distance_to(posicao_inicio_player) >= distancia_para_ativar_trafego:
			ativar_trafego()
		else:
			return

	for i in range(naves.size()):
		var info: Dictionary = naves[i]
		var nave := info.get("node") as Node3D
		if nave == null or !is_instance_valid(nave):
			continue

		var dir: Vector3 = info.get("dir", Vector3.FORWARD)
		var vel: float = float(info.get("vel", velocidade_minima))
		var pos_antes := nave.global_position
		var proxima := pos_antes + dir * vel * delta

		if ponto_dentro_hangar(proxima, 12.0):
			reciclar_nave(i)
			continue

		nave.global_position = proxima
		apontar_nave(nave, dir, delta)

		var deslocamento := nave.global_position.distance_to(pos_antes)
		var parado: float = float(info.get("tempo_parado", 0.0))
		if deslocamento < 0.001:
			parado += delta
		else:
			parado = 0.0
		info["tempo_parado"] = parado
		info["distancia_percorrida"] = float(info.get("distancia_percorrida", 0.0)) + deslocamento
		naves[i] = info

		if parado >= tempo_maximo_sem_mover:
			reciclar_nave(i)
			continue

		if nave.global_position.distance_to(player.global_position) > distancia_reciclagem:
			reciclar_nave(i)
			continue

		if float(info.get("distancia_percorrida", 0.0)) > distancia_reciclagem * 1.6:
			reciclar_nave(i)

func ativar_trafego() -> void:
	if trafego_ativo:
		return
	trafego_ativo = true
	limpar_trafego_existente()
	criar_trafego()

func limpar_trafego_existente() -> void:
	for info in naves:
		var nave := info.get("node") as Node3D
		if nave != null and is_instance_valid(nave):
			nave.queue_free()
	naves.clear()

	for no in get_tree().get_nodes_in_group("traffic_ship"):
		if no is Node3D and no != player:
			no.queue_free()

func localizar_referencias() -> void:
	var cena := get_tree().current_scene
	if cena == null:
		return

	player = cena.get_node_or_null("Player") as Node3D
	if player == null:
		var p := cena.find_child("Player", true, false)
		if p is Node3D:
			player = p as Node3D

	hangar_base = cena.get_node_or_null("HangarBase") as Node3D
	if hangar_base == null:
		var h := cena.find_child("HangarBase", true, false)
		if h is Node3D:
			hangar_base = h as Node3D

func player_dentro_hangar() -> bool:
	if player == null:
		return false
	return ponto_dentro_hangar(player.global_position, 0.0)

func ponto_dentro_hangar(posicao_global: Vector3, margem: float = 0.0) -> bool:
	if hangar_base == null or !is_instance_valid(hangar_base):
		return false

	if hangar_base.has_method("ponto_dentro_hangar"):
		return bool(hangar_base.call("ponto_dentro_hangar", posicao_global, margem))

	var local := hangar_base.to_local(posicao_global)
	var largura := float(hangar_base.get("largura_hangar")) if hangar_base.get("largura_hangar") != null else 180.0
	var profundidade := float(hangar_base.get("profundidade_hangar")) if hangar_base.get("profundidade_hangar") != null else 240.0
	var altura := float(hangar_base.get("altura_hangar")) if hangar_base.get("altura_hangar") != null else 32.0

	return (
		absf(local.x) <= largura * 0.5 + margem
		and absf(local.z) <= profundidade * 0.5 + margem
		and local.y >= -4.0 - margem
		and local.y <= altura + margem
	)

func criar_materiais() -> void:
	mat_casco_escuro = criar_material(Color(0.025, 0.035, 0.055), Color(0,0,0), 0.75, 0.24, 0.0)
	mat_casco_cinza = criar_material(Color(0.18, 0.21, 0.25), Color(0,0,0), 0.62, 0.28, 0.0)
	mat_casco_azulado = criar_material(Color(0.055, 0.11, 0.18), Color(0.0,0.08,0.14), 0.68, 0.22, 0.8)
	mat_luz_ciano = criar_material(Color(0.01,0.08,0.12), Color(0.0,0.85,1.0), 0.25, 0.12, 4.0)
	mat_luz_laranja = criar_material(Color(0.12,0.045,0.01), Color(1.0,0.32,0.03), 0.18, 0.14, 3.4)
	mat_motor_azul = criar_material(Color(0.01,0.04,0.12), Color(0.12,0.62,1.0), 0.15, 0.08, 7.0)
	mat_motor_vermelho = criar_material(Color(0.12,0.015,0.01), Color(1.0,0.12,0.04), 0.15, 0.08, 6.0)
	mat_vidro = criar_material(Color(0.025,0.12,0.18,0.58), Color(0.0,0.55,0.9), 0.35, 0.08, 1.8)
	mat_vidro.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA

func criar_trafego() -> void:
	for i in range(quantidade_naves):
		naves.append(criar_nave_info(i))

func criar_nave_info(indice: int) -> Dictionary:
	var tipo := randi() % 3
	var raiz := Node3D.new()
	raiz.name = "NaveTrafego_%02d" % indice
	raiz.add_to_group("radar_targets")
	raiz.add_to_group("traffic_ship")
	raiz.set_meta("radar_kind", "traffic")
	add_child(raiz)

	match tipo:
		TipoNave.INTERCEPTOR:
			construir_interceptor(raiz)
		TipoNave.CARGUEIRO:
			construir_cargueiro(raiz)
		TipoNave.SHUTTLE:
			construir_shuttle(raiz)

	var info: Dictionary = {
		"node": raiz,
		"tipo": tipo,
		"dir": Vector3.FORWARD,
		"vel": escolher_velocidade(),
		"tempo_parado": 0.0,
		"distancia_percorrida": 0.0
	}
	posicionar_rota_nova(info, true)
	return info

func escolher_velocidade() -> float:
	if randf() < chance_trafego_rapido:
		return velocidade_rapida
	return randf_range(velocidade_minima, velocidade_maxima)

func direcao_horizontal_aleatoria() -> Vector3:
	var angulo := randf_range(0.0, TAU)
	var y := randf_range(-0.08, 0.08)
	return Vector3(cos(angulo), y, sin(angulo)).normalized()

func posicionar_rota_nova(info: Dictionary, inicial: bool) -> void:
	if player == null:
		return

	var nave := info.get("node") as Node3D
	if nave == null:
		return

	var radial := direcao_horizontal_aleatoria()
	var lateral := Vector3(-radial.z, 0.0, radial.x).normalized()
	var distancia := randf_range(raio_spawn_min, raio_spawn_max)
	var spawn := player.global_position + radial * distancia
	spawn += lateral * randf_range(-faixa_lateral, faixa_lateral)
	spawn.y += randf_range(altura_minima, altura_maxima)

	var alvo := player.global_position - radial * distancia
	alvo += lateral * randf_range(-faixa_lateral * 0.35, faixa_lateral * 0.35)
	alvo.y += randf_range(altura_minima * 0.35, altura_maxima * 0.35)

	var dir := (alvo - spawn).normalized()

	var tentativas := 0
	while (ponto_dentro_hangar(spawn, 14.0) or spawn.distance_to(player.global_position) < distancia_minima_do_player) and tentativas < 12:
		radial = direcao_horizontal_aleatoria()
		lateral = Vector3(-radial.z, 0.0, radial.x).normalized()
		distancia = randf_range(raio_spawn_min, raio_spawn_max)
		spawn = player.global_position + radial * distancia
		spawn += lateral * randf_range(-faixa_lateral, faixa_lateral)
		spawn.y += randf_range(altura_minima, altura_maxima)
		alvo = player.global_position - radial * distancia
		alvo.y += randf_range(altura_minima * 0.3, altura_maxima * 0.3)
		dir = (alvo - spawn).normalized()
		tentativas += 1

	nave.global_position = spawn
	info["dir"] = dir
	info["vel"] = escolher_velocidade()
	info["tempo_parado"] = 0.0
	info["distancia_percorrida"] = 0.0
	apontar_nave(nave, dir, 1.0)

func reciclar_nave(indice: int) -> void:
	if indice < 0 or indice >= naves.size():
		return
	var info := naves[indice]
	posicionar_rota_nova(info, false)
	naves[indice] = info

func apontar_nave(nave: Node3D, dir: Vector3, delta: float) -> void:
	if dir.length_squared() < 0.001:
		return
	var alvo_yaw := atan2(-dir.x, -dir.z)
	nave.rotation.y = lerp_angle(nave.rotation.y, alvo_yaw, clampf(delta * 5.0, 0.0, 1.0))
	var alvo_pitch := asin(clampf(dir.y, -0.65, 0.65))
	nave.rotation.x = lerp_angle(nave.rotation.x, alvo_pitch, clampf(delta * 3.5, 0.0, 1.0))
	nave.rotation.z = lerp(nave.rotation.z, sin(Time.get_ticks_msec() * 0.001 + nave.get_instance_id() * 0.01) * 0.025, clampf(delta * 2.0, 0.0, 1.0))

# =========================================================
# MODELOS 3D PROCEDURAIS
# =========================================================

func construir_interceptor(pai: Node3D) -> void:
	pai.add_child(criar_bloco(Vector3.ZERO, Vector3(1.65,0.48,4.2), mat_casco_escuro))
	pai.add_child(criar_bloco(Vector3(0,0.05,-2.65), Vector3(0.68,0.28,1.55), mat_casco_cinza))
	pai.add_child(criar_bloco(Vector3(-2.0,-0.02,0.0), Vector3(2.5,0.12,1.75), mat_casco_azulado, Vector3(0,0,deg_to_rad(-4.0))))
	pai.add_child(criar_bloco(Vector3(2.0,-0.02,0.0), Vector3(2.5,0.12,1.75), mat_casco_azulado, Vector3(0,0,deg_to_rad(4.0))))
	pai.add_child(criar_bloco(Vector3(0,0.42,-0.65), Vector3(0.92,0.38,1.32), mat_vidro))
	pai.add_child(criar_bloco(Vector3(-0.53,-0.03,2.35), Vector3(0.42,0.34,0.95), mat_motor_azul))
	pai.add_child(criar_bloco(Vector3(0.53,-0.03,2.35), Vector3(0.42,0.34,0.95), mat_motor_azul))
	pai.add_child(criar_bloco(Vector3(0,-0.18,-2.1), Vector3(0.42,0.05,0.35), mat_luz_ciano))

func construir_cargueiro(pai: Node3D) -> void:
	pai.add_child(criar_bloco(Vector3.ZERO, Vector3(3.0,1.15,5.8), mat_casco_cinza))
	pai.add_child(criar_bloco(Vector3(0,0.45,-3.1), Vector3(2.0,0.75,1.25), mat_casco_azulado))
	pai.add_child(criar_bloco(Vector3(0,0.92,-1.65), Vector3(1.2,0.38,1.15), mat_vidro))
	for z in [-1.0,0.8,2.6]:
		pai.add_child(criar_bloco(Vector3(-2.45,-0.12,z), Vector3(1.25,0.82,1.45), mat_casco_escuro))
		pai.add_child(criar_bloco(Vector3(2.45,-0.12,z), Vector3(1.25,0.82,1.45), mat_casco_escuro))
	pai.add_child(criar_bloco(Vector3(-0.95,0.0,3.55), Vector3(0.62,0.52,1.05), mat_motor_vermelho))
	pai.add_child(criar_bloco(Vector3(0.95,0.0,3.55), Vector3(0.62,0.52,1.05), mat_motor_vermelho))
	pai.add_child(criar_bloco(Vector3(0,0.72,0.2), Vector3(0.42,0.08,0.42), mat_luz_laranja))

func construir_shuttle(pai: Node3D) -> void:
	pai.add_child(criar_bloco(Vector3.ZERO, Vector3(2.05,0.92,3.8), mat_casco_azulado))
	pai.add_child(criar_bloco(Vector3(0,0.24,-2.28), Vector3(1.22,0.58,1.15), mat_casco_cinza))
	pai.add_child(criar_bloco(Vector3(0,0.64,-0.78), Vector3(1.45,0.33,1.55), mat_vidro))
	pai.add_child(criar_bloco(Vector3(-1.62,-0.08,0.35), Vector3(1.45,0.12,2.1), mat_casco_escuro, Vector3(0,0,deg_to_rad(-3.0))))
	pai.add_child(criar_bloco(Vector3(1.62,-0.08,0.35), Vector3(1.45,0.12,2.1), mat_casco_escuro, Vector3(0,0,deg_to_rad(3.0))))
	pai.add_child(criar_bloco(Vector3(-0.66,-0.16,2.35), Vector3(0.42,0.34,0.88), mat_motor_azul))
	pai.add_child(criar_bloco(Vector3(0.66,-0.16,2.35), Vector3(0.42,0.34,0.88), mat_motor_azul))
	pai.add_child(criar_bloco(Vector3(0,0.0,-2.85), Vector3(0.34,0.06,0.24), mat_luz_ciano))

func criar_bloco(pos: Vector3, tamanho: Vector3, material: Material, rotacao: Vector3 = Vector3.ZERO) -> MeshInstance3D:
	var mesh := BoxMesh.new()
	mesh.size = tamanho
	var mi := MeshInstance3D.new()
	mi.mesh = mesh
	mi.material_override = material
	mi.position = pos
	mi.rotation = rotacao
	return mi

func criar_material(albedo: Color, emission: Color, metallic: float, roughness: float, emission_energy: float) -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	mat.albedo_color = albedo
	mat.metallic = metallic
	mat.roughness = roughness
	if emission_energy > 0.0:
		mat.emission_enabled = true
		mat.emission = emission
		mat.emission_energy_multiplier = emission_energy
	return mat
