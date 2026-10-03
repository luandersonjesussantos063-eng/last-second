extends Node

# =========================================================
# LAST SECOND
# DOCKING SYSTEM v1.1 // P-01 // START LOCK COMPATIVEL
#
# Anexar em um Node chamado: DockingSystem
#
# NAO cria Area3D nem depende de colisao.
# Detecta a P-01 pela posicao relativa ao HangarBase.
# Durante a atracacao, sincroniza o Start Lock do MobileControls
# a cada frame para nenhum outro sistema puxar a nave de volta.
# =========================================================

@export_category("Docking P-01")
@export_range(8.0, 50.0, 1.0) var zona_meia_largura: float = 24.0
@export_range(6.0, 30.0, 1.0) var zona_meia_altura: float = 15.0
@export_range(10.0, 60.0, 1.0) var zona_meia_profundidade: float = 34.0
@export_range(1.0, 20.0, 0.5) var velocidade_max_atracar: float = 8.0
@export_range(0.4, 4.0, 0.05) var tempo_atracacao: float = 1.35
@export_range(0.5, 6.0, 0.25) var tolerancia_atracado: float = 2.5
@export_range(3.0, 20.0, 0.5) var distancia_liberar_atracacao: float = 8.0

@export_category("Interface")
@export var mostrar_no_pc_para_teste: bool = true
@export var tecla_atracar_pc: Key = KEY_E

var cena: Node = null
var nave: Node3D = null
var hangar: Node3D = null
var mobile_controls: Node = null
var on_foot_system: Node = null

var camada_ui: CanvasLayer = null
var label_status: Label = null
var botao_atracar: Button = null
var ultimo_tamanho_tela: Vector2 = Vector2.ZERO

var atracada: bool = false
var atracando: bool = false

var tempo_docking: float = 0.0
var inicio_pos: Vector3 = Vector3.ZERO
var inicio_rot: Vector3 = Vector3.ZERO
var alvo_pos: Vector3 = Vector3.ZERO
var alvo_rot: Vector3 = Vector3.ZERO

var nave_processava: bool = true
var nave_processava_fisica: bool = true

var tempo_relocalizar: float = 0.0
var tecla_e_anterior: bool = false


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS

	await get_tree().process_frame
	await get_tree().process_frame
	await get_tree().physics_frame

	localizar_sistemas()
	criar_interface()
	atualizar_layout()
	atualizar_estado_inicial()

	print("========================================")
	print("DOCKING SYSTEM v1.1 // START LOCK COMPATIVEL // ONLINE")
	print("P-01: ", nave)
	print("HANGAR: ", hangar)
	print("MOBILE CONTROLS: ", mobile_controls)
	print("DOCK GLOBAL: ", pegar_dock_global())
	print("========================================")


# =========================================================
# LOCALIZAR SISTEMAS
# =========================================================

func localizar_sistemas() -> void:
	cena = get_tree().current_scene
	if cena == null:
		return

	nave = cena.get_node_or_null("Player") as Node3D
	if nave == null:
		var candidato_player: Node = cena.find_child("Player", true, false)
		if candidato_player is Node3D:
			nave = candidato_player as Node3D

	hangar = cena.get_node_or_null("HangarBase") as Node3D
	if hangar == null:
		var candidato_hangar: Node = cena.find_child("HangarBase", true, false)
		if candidato_hangar is Node3D:
			hangar = candidato_hangar as Node3D

	mobile_controls = cena.get_node_or_null("MobileControls")
	if mobile_controls == null:
		mobile_controls = cena.find_child("MobileControls", true, false)

	on_foot_system = cena.get_node_or_null("OnFootSystem")
	if on_foot_system == null:
		on_foot_system = cena.find_child("OnFootSystem", true, false)


# =========================================================
# POSICAO DA VAGA
# =========================================================

func pegar_spawn_local() -> Vector3:
	if hangar == null or !is_instance_valid(hangar):
		return Vector3(0.0, 5.0, -35.0)

	var valor: Variant = hangar.get("p01_spawn_local")
	if typeof(valor) == TYPE_VECTOR3:
		return valor as Vector3

	return Vector3(0.0, 5.0, -35.0)


func pegar_dock_global() -> Vector3:
	if hangar == null or !is_instance_valid(hangar):
		return Vector3.ZERO

	return hangar.to_global(pegar_spawn_local())


func pegar_rotacao_dock() -> Vector3:
	if hangar == null or !is_instance_valid(hangar):
		return Vector3.ZERO

	return Vector3(
		0.0,
		hangar.global_rotation.y,
		0.0
	)


func nave_na_zona_docking() -> bool:
	if nave == null or hangar == null:
		return false
	if !is_instance_valid(nave) or !is_instance_valid(hangar):
		return false

	var nave_local: Vector3 = hangar.to_local(nave.global_position)
	var dock_local: Vector3 = pegar_spawn_local()
	var d: Vector3 = nave_local - dock_local

	return (
		absf(d.x) <= zona_meia_largura
		and absf(d.y) <= zona_meia_altura
		and absf(d.z) <= zona_meia_profundidade
	)


# =========================================================
# ESTADO DO JOGO
# =========================================================

func velocidade_atual() -> float:
	if mobile_controls == null or !is_instance_valid(mobile_controls):
		return 0.0

	var valor: Variant = mobile_controls.get("velocidade_efetiva")
	if valor == null:
		return 0.0

	return float(valor)


func jogador_esta_a_pe() -> bool:
	if on_foot_system != null and is_instance_valid(on_foot_system):
		var modo: Variant = on_foot_system.get("modo_a_pe")
		if modo != null:
			return bool(modo)

	if mobile_controls != null and is_instance_valid(mobile_controls):
		if mobile_controls.has_method("is_modo_a_pe"):
			return bool(mobile_controls.call("is_modo_a_pe"))

	return false


func atualizar_estado_inicial() -> void:
	if nave == null or !is_instance_valid(nave):
		return

	var distancia: float = nave.global_position.distance_to(pegar_dock_global())

	if distancia <= tolerancia_atracado:
		atracada = true
		zerar_propulsao()
		sincronizar_start_lock_atual()
	else:
		atracada = false


# =========================================================
# PROCESSO
# =========================================================

func _process(delta: float) -> void:
	var tamanho: Vector2 = get_viewport().get_visible_rect().size
	if tamanho != ultimo_tamanho_tela:
		atualizar_layout()

	if nave == null or hangar == null or mobile_controls == null:
		tempo_relocalizar += delta
		if tempo_relocalizar >= 0.75:
			tempo_relocalizar = 0.0
			localizar_sistemas()
		return

	if !is_instance_valid(nave) or !is_instance_valid(hangar):
		return

	if jogador_esta_a_pe():
		esconder_interface()
		tecla_e_anterior = false
		return

	if atracando:
		mostrar_status("P-01 // ATRACACAO AUTOMATICA", false)
		return

	var distancia: float = nave.global_position.distance_to(pegar_dock_global())
	var vel: float = velocidade_atual()

	if atracada:
		if distancia > distancia_liberar_atracacao or vel > 0.5:
			atracada = false
		else:
			mostrar_status("P-01 // ATRACADA", false)
			return

	if !nave_na_zona_docking():
		esconder_interface()
		tecla_e_anterior = false
		return

	if vel > velocidade_max_atracar:
		mostrar_status(
			"DOCKING // REDUZA PARA %d U/S" % int(velocidade_max_atracar),
			false
		)
		tecla_e_anterior = false
		return

	mostrar_status("DOCKING DISPONIVEL // E OU ATRACAR", true)

	var tecla_e_agora: bool = Input.is_key_pressed(tecla_atracar_pc)
	if tecla_e_agora and !tecla_e_anterior:
		solicitar_atracacao()

	tecla_e_anterior = tecla_e_agora


func _physics_process(delta: float) -> void:
	if !atracando:
		return

	if nave == null or !is_instance_valid(nave):
		cancelar_atracacao()
		return

	tempo_docking += delta

	var t: float = clampf(
		tempo_docking / maxf(tempo_atracacao, 0.01),
		0.0,
		1.0
	)

	# Smoothstep: entrada e saida suaves.
	var suave: float = t * t * (3.0 - 2.0 * t)

	nave.global_position = inicio_pos.lerp(alvo_pos, suave)

	nave.global_rotation = Vector3(
		lerp_angle(inicio_rot.x, alvo_rot.x, suave),
		lerp_angle(inicio_rot.y, alvo_rot.y, suave),
		lerp_angle(inicio_rot.z, alvo_rot.z, suave)
	)

	# ESTE E O PONTO PRINCIPAL DA v1.1:
	# o Start Lock acompanha a nave durante TODO o movimento.
	sincronizar_start_lock_atual()

	if t >= 1.0:
		finalizar_atracacao()


# =========================================================
# ATRACACAO
# =========================================================

func solicitar_atracacao() -> void:
	if atracando or atracada:
		return
	if jogador_esta_a_pe():
		return
	if nave == null or !is_instance_valid(nave):
		return
	if !nave_na_zona_docking():
		return
	if velocidade_atual() > velocidade_max_atracar:
		return

	atracando = true
	tempo_docking = 0.0

	inicio_pos = nave.global_position
	inicio_rot = nave.global_rotation

	alvo_pos = pegar_dock_global()
	alvo_rot = pegar_rotacao_dock()

	nave_processava = nave.is_processing()
	nave_processava_fisica = nave.is_physics_processing()

	zerar_propulsao()

	# Impede o controlador antigo da propria P-01 de interferir.
	nave.set_process(false)
	nave.set_physics_process(false)

	sincronizar_start_lock_atual()

	mostrar_status("P-01 // ATRACACAO AUTOMATICA", false)

	print("DOCKING v1.1: inicio da atracacao.")


func finalizar_atracacao() -> void:
	if nave == null or !is_instance_valid(nave):
		cancelar_atracacao()
		return

	nave.global_position = alvo_pos
	nave.global_rotation = alvo_rot

	zerar_propulsao()
	sincronizar_start_lock_atual()

	nave.set_process(nave_processava)
	nave.set_physics_process(nave_processava_fisica)

	atracando = false
	atracada = true
	tempo_docking = 0.0

	mostrar_status("P-01 // ATRACADA", false)

	print("DOCKING v1.1: P-01 ATRACADA.")


func cancelar_atracacao() -> void:
	atracando = false
	tempo_docking = 0.0

	if nave != null and is_instance_valid(nave):
		nave.set_process(nave_processava)
		nave.set_physics_process(nave_processava_fisica)


func zerar_propulsao() -> void:
	if mobile_controls == null or !is_instance_valid(mobile_controls):
		return

	if mobile_controls.has_method("liberar_todos_controles"):
		mobile_controls.call("liberar_todos_controles")

	mobile_controls.set("velocidade_selecionada", 0.0)
	mobile_controls.set("velocidade_efetiva", 0.0)
	mobile_controls.set("pedal_pressionado", false)


func sincronizar_start_lock_atual() -> void:
	if nave == null or !is_instance_valid(nave):
		return
	if mobile_controls == null or !is_instance_valid(mobile_controls):
		return

	if mobile_controls.has_method("sincronizar_spawn_hangar"):
		mobile_controls.call(
			"sincronizar_spawn_hangar",
			nave.global_position,
			nave.global_rotation
		)


# =========================================================
# INTERFACE
# =========================================================

func interface_permitida() -> bool:
	return (
		OS.has_feature("android")
		or OS.has_feature("ios")
		or OS.has_feature("mobile")
		or mostrar_no_pc_para_teste
	)


func criar_interface() -> void:
	if !interface_permitida():
		return

	camada_ui = CanvasLayer.new()
	camada_ui.name = "DockingCanvas"
	camada_ui.layer = 132
	add_child(camada_ui)

	label_status = Label.new()
	label_status.name = "DockingStatus"
	label_status.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label_status.add_theme_font_size_override("font_size", 14)
	label_status.add_theme_color_override(
		"font_color",
		Color(0.72, 0.95, 1.0, 0.95)
	)
	label_status.visible = false
	camada_ui.add_child(label_status)

	botao_atracar = Button.new()
	botao_atracar.name = "DockButton"
	botao_atracar.text = "ATRACAR"
	botao_atracar.focus_mode = Control.FOCUS_NONE
	botao_atracar.add_theme_font_size_override("font_size", 16)
	botao_atracar.visible = false
	botao_atracar.pressed.connect(solicitar_atracacao)
	camada_ui.add_child(botao_atracar)

	var normal := StyleBoxFlat.new()
	normal.bg_color = Color(0.01, 0.11, 0.16, 0.80)
	normal.border_color = Color(0.08, 0.84, 1.0, 0.96)
	normal.set_border_width_all(2)
	normal.set_corner_radius_all(12)

	var pressionado := normal.duplicate() as StyleBoxFlat
	pressionado.bg_color = Color(0.02, 0.32, 0.42, 0.94)

	botao_atracar.add_theme_stylebox_override("normal", normal)
	botao_atracar.add_theme_stylebox_override("hover", normal)
	botao_atracar.add_theme_stylebox_override("pressed", pressionado)
	botao_atracar.add_theme_stylebox_override("focus", normal)

	botao_atracar.add_theme_color_override(
		"font_color",
		Color(0.90, 0.99, 1.0, 1.0)
	)


func atualizar_layout() -> void:
	if camada_ui == null:
		return

	var tela: Vector2 = get_viewport().get_visible_rect().size
	ultimo_tamanho_tela = tela

	var escala: float = clampf(
		minf(tela.x / 1280.0, tela.y / 720.0),
		0.72,
		1.25
	)

	if label_status != null:
		var w: float = 460.0 * escala
		var h: float = 34.0 * escala

		label_status.position = Vector2(
			(tela.x - w) * 0.5,
			tela.y - 192.0 * escala
		)
		label_status.size = Vector2(w, h)

	if botao_atracar != null:
		var w: float = 180.0 * escala
		var h: float = 58.0 * escala

		botao_atracar.position = Vector2(
			(tela.x - w) * 0.5,
			tela.y - 148.0 * escala
		)
		botao_atracar.size = Vector2(w, h)


func mostrar_status(texto: String, mostrar_botao: bool) -> void:
	if label_status != null:
		label_status.text = texto
		label_status.visible = true

	if botao_atracar != null:
		botao_atracar.visible = mostrar_botao


func esconder_interface() -> void:
	if label_status != null:
		label_status.visible = false

	if botao_atracar != null:
		botao_atracar.visible = false
