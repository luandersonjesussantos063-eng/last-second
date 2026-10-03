extends Node

# =========================================================
# LAST SECOND
# SUSPECT PATROL MANAGER v1.3 // PHYSICS + RADAR // TARGET GLOW
# - reduz tempo entre ocorrencias
# - cria janela de patrulha entre um caso e outro
# - remove nome/texto flutuante do alvo durante aproximacao
# - nave proxima fica verde para indicar o alvo selecionado
# - mostra prompt apenas durante scan/resultado/abordagem
# - gera resultado do scan (permissao, situacao, condicao)
# - se houver irregularidade, pede ORDEM para abordar
# - compativel com Node comum (cria tudo internamente)
# =========================================================

@export_range(5.0, 60.0, 1.0) var intervalo_min_ocorrencia: float = 8.0
@export_range(5.0, 90.0, 1.0) var intervalo_max_ocorrencia: float = 16.0
@export_range(10.0, 150.0, 1.0) var distancia_spawn_frontal: float = 72.0
@export_range(10.0, 80.0, 1.0) var faixa_lateral_spawn: float = 36.0
@export_range(5.0, 60.0, 1.0) var distancia_scan: float = 28.0
@export_range(10.0, 100.0, 1.0) var distancia_destaque_verde: float = 45.0
@export_range(0.1, 1.0, 0.05) var intensidade_destaque_verde: float = 0.55
@export_range(5.0, 60.0, 1.0) var distancia_abordagem: float = 34.0
@export_range(0.5, 5.0, 0.1) var duracao_scan: float = 1.6
@export_range(2.0, 15.0, 0.5) var duracao_resultado_ok: float = 5.0
@export_range(3.0, 20.0, 0.5) var duracao_resultado_irregular: float = 8.0
@export_range(3.0, 20.0, 0.5) var velocidade_nave_suspeita: float = 11.0

const KEY_SCAN := KEY_E
const KEY_ORDEM := KEY_F

enum Estado {
	PATRULHA,
	ALVO_ATIVO,
	ESCANEANDO,
	RESULTADO,
	ABORDAGEM
}

var estado: int = Estado.PATRULHA
var player: Node3D = null
var camera_3d: Camera3D = null

var tempo_proxima_ocorrencia: float = 0.0
var tempo_estado: float = 0.0
var progresso_scan: float = 0.0

var suspect_root: Node3D = null
var suspect_velocity: Vector3 = Vector3.ZERO
var suspect_id: int = 0

var material_destaque_verde: StandardMaterial3D = null
var destaque_alvo_ativo: bool = false
var tempo_pulso_destaque: float = 0.0

var resultado_scan: Dictionary = {}
var resultado_irregular: bool = false

var ui_layer: CanvasLayer = null
var ui_root: Control = null
var label_patrol: Label = null
var label_prompt: Label = null
var panel_result: Panel = null
var label_result_title: Label = null
var label_result_body: RichTextLabel = null
var label_result_footer: Label = null
var barra_scan_bg: ColorRect = null
var barra_scan_fill: ColorRect = null


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	await get_tree().process_frame
	await get_tree().process_frame
	localizar_referencias()
	criar_material_destaque_verde()
	criar_ui()
	agendar_proxima_ocorrencia()
	atualizar_layout_ui()
	atualizar_texto_patrulha("PATRULHANDO SETOR...")
	set_objetivo_cockpit("OBJETIVO: PATRULHAR O SETOR")


func _process(delta: float) -> void:
	if player == null or !is_instance_valid(player) or camera_3d == null or !is_instance_valid(camera_3d):
		localizar_referencias()
		atualizar_layout_ui()
		return

	var tela := get_viewport().get_visible_rect().size
	if ui_root != null and ui_root.size != tela:
		atualizar_layout_ui()

	tempo_estado += delta

	match estado:
		Estado.PATRULHA:
			processar_patrulha(delta)
		Estado.ALVO_ATIVO:
			processar_alvo_ativo(delta)
		Estado.ESCANEANDO:
			processar_escaneando(delta)
		Estado.RESULTADO:
			processar_resultado(delta)
		Estado.ABORDAGEM:
			processar_abordagem(delta)

	atualizar_destaque_alvo(delta)
	atualizar_prompt_tela()


func _input(event: InputEvent) -> void:
	if event is InputEventKey:
		var key_event := event as InputEventKey
		if !key_event.pressed or key_event.echo:
			return

		var code: int = key_event.keycode
		if code == 0:
			code = key_event.physical_keycode

		if code == KEY_SCAN:
			if estado == Estado.ALVO_ATIVO and alvo_em_alcance_para_scan():
				iniciar_scan()
		elif code == KEY_ORDEM:
			if estado == Estado.RESULTADO and resultado_irregular:
				iniciar_abordagem()


# =========================================================
# FLUXO PRINCIPAL
# =========================================================

func processar_patrulha(delta: float) -> void:
	tempo_proxima_ocorrencia -= delta
	if tempo_proxima_ocorrencia < 0.0:
		tempo_proxima_ocorrencia = 0.0

	atualizar_texto_patrulha("PATRULHANDO SETOR // PROXIMA VARREDURA EM %ss" % str(int(ceil(tempo_proxima_ocorrencia))))

	if tempo_proxima_ocorrencia <= 0.0:
		ativar_nova_ocorrencia()


func processar_alvo_ativo(delta: float) -> void:
	mover_alvo(delta)
	if suspect_root == null or !is_instance_valid(suspect_root):
		encerrar_ocorrencia_e_patrulhar()
		return

	var dist: float = distancia_ao_alvo()
	atualizar_texto_patrulha("OCORRENCIA ATIVA // LOCALIZE A NAVE DESTACADA")

	# Sem texto flutuante sobre a nave: o alvo proximo fica verde.
	label_prompt.visible = false

	if dist <= distancia_scan:
		set_objetivo_cockpit("OBJETIVO: NAVE VERDE EM ALCANCE - USE SCAN")
	else:
		set_objetivo_cockpit("OBJETIVO: APROXIME-SE DA NAVE DESTACADA EM VERDE")


func processar_escaneando(delta: float) -> void:
	mover_alvo(delta * 0.35)
	progresso_scan = clampf(progresso_scan + delta / maxf(duracao_scan, 0.1), 0.0, 1.0)
	barra_scan_fill.size = Vector2(barra_scan_bg.size.x * progresso_scan, barra_scan_bg.size.y)
	label_prompt.text = "ESCANEANDO... %d%%" % int(progresso_scan * 100.0)
	label_prompt.visible = true
	set_objetivo_cockpit("OBJETIVO: AGUARDE O ESCANEAMENTO")

	if progresso_scan >= 1.0:
		finalizar_scan()


func processar_resultado(delta: float) -> void:
	mover_alvo(delta * 0.18)
	var limite := duracao_resultado_irregular if resultado_irregular else duracao_resultado_ok

	if resultado_irregular:
		label_prompt.text = "IRREGULARIDADE DETECTADA\nTOQUE EM ORDEM"
		label_prompt.visible = true
		set_objetivo_cockpit("OBJETIVO: USE ORDEM PARA PARAR A NAVE")
	else:
		label_prompt.text = "TUDO CERTO COM A NAVE\nLIBERE E SIGA PATRULHANDO"
		label_prompt.visible = true
		set_objetivo_cockpit("OBJETIVO: NAVE REGULAR - RETOMAR PATRULHA")
		if tempo_estado >= limite:
			encerrar_ocorrencia_e_patrulhar()


func processar_abordagem(delta: float) -> void:
	if suspect_root != null and is_instance_valid(suspect_root):
		# desacelera ate quase parar
		suspect_velocity = suspect_velocity.lerp(Vector3.ZERO, delta * 2.2)
		mover_alvo(delta)

	label_prompt.text = "NAVE EM ABORDAGEM\nAGUARDANDO PARADA"
	label_prompt.visible = true
	set_objetivo_cockpit("OBJETIVO: ABORDAGEM EM ANDAMENTO")

	if tempo_estado >= 2.8:
		label_prompt.text = "ABORDAGEM CONCLUIDA\nRETOMAR PATRULHA"
		set_objetivo_cockpit("OBJETIVO: RETOMAR PATRULHA")
		encerrar_ocorrencia_e_patrulhar()


func agendar_proxima_ocorrencia() -> void:
	tempo_proxima_ocorrencia = randf_range(intervalo_min_ocorrencia, intervalo_max_ocorrencia)


func ativar_nova_ocorrencia() -> void:
	tempo_estado = 0.0
	progresso_scan = 0.0
	resultado_scan.clear()
	resultado_irregular = false
	criar_ou_reposicionar_alvo()
	estado = Estado.ALVO_ATIVO
	label_prompt.visible = false
	barra_scan_bg.visible = false
	panel_result.visible = false
	atualizar_texto_patrulha("OCORRENCIA ATIVA // NAVE SUSPEITA LOCALIZADA")
	set_objetivo_cockpit("OBJETIVO: LOCALIZAR E ESCANEAR A NAVE")


func iniciar_scan() -> void:
	if suspect_root == null or !is_instance_valid(suspect_root):
		return
	estado = Estado.ESCANEANDO
	tempo_estado = 0.0
	progresso_scan = 0.0
	barra_scan_bg.visible = true
	barra_scan_fill.visible = true
	barra_scan_fill.size = Vector2(0.0, barra_scan_bg.size.y)


func finalizar_scan() -> void:
	gerar_resultado_scan()
	estado = Estado.RESULTADO
	tempo_estado = 0.0
	barra_scan_bg.visible = false
	barra_scan_fill.visible = false
	mostrar_resultado_no_painel()


func iniciar_abordagem() -> void:
	estado = Estado.ABORDAGEM
	tempo_estado = 0.0
	panel_result.visible = false


func encerrar_ocorrencia_e_patrulhar() -> void:
	estado = Estado.PATRULHA
	tempo_estado = 0.0
	resultado_irregular = false
	label_prompt.visible = false
	panel_result.visible = false
	barra_scan_bg.visible = false
	barra_scan_fill.visible = false
	remover_destaque_alvo()
	if suspect_root != null and is_instance_valid(suspect_root):
		suspect_root.visible = false
	agendar_proxima_ocorrencia()
	atualizar_texto_patrulha("PATRULHANDO SETOR...")
	set_objetivo_cockpit("OBJETIVO: PATRULHAR O SETOR")


# =========================================================
# ALVO / NAVE SUSPEITA
# =========================================================

func criar_ou_reposicionar_alvo() -> void:
	if player == null:
		return

	if suspect_root == null or !is_instance_valid(suspect_root):
		suspect_root = criar_nave_suspeita_visual()
		add_child(suspect_root)

	suspect_id += 1
	suspect_root.name = "SuspectShip_%d" % suspect_id
	suspect_root.visible = true

	var forward := -player.global_transform.basis.z.normalized()
	var right := player.global_transform.basis.x.normalized()
	var pos := player.global_position
	pos += forward * distancia_spawn_frontal
	pos += right * randf_range(-faixa_lateral_spawn, faixa_lateral_spawn)
	pos.y += randf_range(-4.0, 6.0)
	suspect_root.global_position = pos

	var lateral_sign := -1.0 if randf() < 0.5 else 1.0
	suspect_velocity = right * lateral_sign * velocidade_nave_suspeita
	suspect_root.rotation.y = atan2(-suspect_velocity.x, -suspect_velocity.z)


func mover_alvo(delta: float) -> void:
	if suspect_root == null or !is_instance_valid(suspect_root):
		return

	suspect_root.global_position += suspect_velocity * delta
	suspect_root.rotation.y = atan2(-suspect_velocity.x, -suspect_velocity.z)

	if player != null and suspect_root.global_position.distance_to(player.global_position) > 180.0:
		var back := -suspect_velocity.normalized()
		suspect_root.global_position = player.global_position + back * 80.0


func criar_nave_suspeita_visual() -> Node3D:
	var root := AnimatableBody3D.new()
	root.collision_layer = 1
	root.collision_mask = 1
	root.sync_to_physics = true
	root.add_to_group("radar_targets")
	root.add_to_group("suspect_target")
	root.set_meta("radar_kind", "suspect")

	var mat_body := StandardMaterial3D.new()
	mat_body.albedo_color = Color(0.10, 0.12, 0.15)
	mat_body.metallic = 0.50
	mat_body.roughness = 0.35

	var mat_glass := StandardMaterial3D.new()
	mat_glass.albedo_color = Color(0.15, 0.38, 0.50, 0.55)
	mat_glass.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat_glass.emission_enabled = true
	mat_glass.emission = Color(0.08, 0.35, 0.55)
	mat_glass.emission_energy_multiplier = 0.6

	var mat_engine := StandardMaterial3D.new()
	mat_engine.albedo_color = Color(0.10, 0.10, 0.12)
	mat_engine.emission_enabled = true
	mat_engine.emission = Color(1.0, 0.18, 0.12)
	mat_engine.emission_energy_multiplier = 1.8

	var body := MeshInstance3D.new()
	var body_mesh := BoxMesh.new()
	body_mesh.size = Vector3(2.2, 0.7, 4.4)
	body.mesh = body_mesh
	body.material_override = mat_body
	root.add_child(body)

	var cockpit := MeshInstance3D.new()
	var cockpit_mesh := BoxMesh.new()
	cockpit_mesh.size = Vector3(1.1, 0.4, 1.3)
	cockpit.mesh = cockpit_mesh
	cockpit.material_override = mat_glass
	cockpit.position = Vector3(0.0, 0.38, -0.8)
	root.add_child(cockpit)

	for side in [-1.0, 1.0]:
		var wing := MeshInstance3D.new()
		var wing_mesh := BoxMesh.new()
		wing_mesh.size = Vector3(1.4, 0.08, 2.1)
		wing.mesh = wing_mesh
		wing.material_override = mat_body
		wing.position = Vector3(side * 1.55, -0.02, 0.1)
		root.add_child(wing)

		var engine := MeshInstance3D.new()
		var engine_mesh := BoxMesh.new()
		engine_mesh.size = Vector3(0.35, 0.20, 0.75)
		engine.mesh = engine_mesh
		engine.material_override = mat_engine
		engine.position = Vector3(side * 0.55, 0.0, 2.35)
		root.add_child(engine)

	# Colisao fisica da nave suspeita.
	var collision := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = Vector3(4.8, 2.0, 6.0)
	collision.shape = shape
	root.add_child(collision)

	# Sem luz dinamica no alvo: o destaque usa material emissivo verde.

	return root


func alvo_em_alcance_para_scan() -> bool:
	return suspect_root != null and is_instance_valid(suspect_root) and distancia_ao_alvo() <= distancia_scan


func distancia_ao_alvo() -> float:
	if player == null or suspect_root == null or !is_instance_valid(suspect_root):
		return 999999.0
	return player.global_position.distance_to(suspect_root.global_position)


# =========================================================
# DESTAQUE VERDE DO ALVO
# =========================================================

func criar_material_destaque_verde() -> void:
	material_destaque_verde = StandardMaterial3D.new()
	material_destaque_verde.albedo_color = Color(0.08, 1.0, 0.34, 0.18)
	material_destaque_verde.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material_destaque_verde.emission_enabled = true
	material_destaque_verde.emission = Color(0.02, 1.0, 0.22)
	material_destaque_verde.emission_energy_multiplier = 1.25
	material_destaque_verde.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED


func atualizar_destaque_alvo(delta: float) -> void:
	if suspect_root == null or !is_instance_valid(suspect_root):
		remover_destaque_alvo()
		return

	if !suspect_root.visible:
		remover_destaque_alvo()
		return

	var deve_destacar: bool = (
		estado != Estado.PATRULHA
		and distancia_ao_alvo() <= distancia_destaque_verde
	)

	if deve_destacar:
		if !destaque_alvo_ativo:
			aplicar_destaque_alvo()

		tempo_pulso_destaque += delta
		if material_destaque_verde != null:
			var pulso: float = 0.5 + 0.5 * sin(tempo_pulso_destaque * 4.5)
			material_destaque_verde.emission_energy_multiplier = (
				1.0 + intensidade_destaque_verde * pulso
			)
	else:
		remover_destaque_alvo()


func aplicar_destaque_alvo() -> void:
	if suspect_root == null or !is_instance_valid(suspect_root):
		return
	if material_destaque_verde == null:
		criar_material_destaque_verde()

	aplicar_overlay_verde_recursivo(suspect_root)
	destaque_alvo_ativo = true
	tempo_pulso_destaque = 0.0


func aplicar_overlay_verde_recursivo(no_atual: Node) -> void:
	if no_atual is GeometryInstance3D:
		(no_atual as GeometryInstance3D).material_overlay = material_destaque_verde

	for filho: Node in no_atual.get_children():
		aplicar_overlay_verde_recursivo(filho)


func remover_destaque_alvo() -> void:
	if suspect_root != null and is_instance_valid(suspect_root):
		remover_overlay_recursivo(suspect_root)
	destaque_alvo_ativo = false


func remover_overlay_recursivo(no_atual: Node) -> void:
	if no_atual is GeometryInstance3D:
		(no_atual as GeometryInstance3D).material_overlay = null

	for filho: Node in no_atual.get_children():
		remover_overlay_recursivo(filho)


# =========================================================
# SCAN / RESULTADOS
# =========================================================

func gerar_resultado_scan() -> void:
	var permissoes: Array[String] = ["VALIDA", "VALIDA", "VALIDA", "VENCIDA", "NAO ENCONTRADA"]
	var status_nave: Array[String] = ["REGULAR", "REGULAR", "REGULAR", "ROUBADA", "FURTADA", "CLONADA"]
	var condicoes: Array[String] = ["BOA", "BOA", "RAZOAVEL", "AVARIADA", "DANIFICADA"]
	var registros: Array[String] = ["EM DIA", "EM DIA", "EM DIA", "DIVERGENTE", "SEM REGISTRO"]

	var permissao: String = permissoes[randi() % permissoes.size()]
	var situacao: String = status_nave[randi() % status_nave.size()]
	var condicao: String = condicoes[randi() % condicoes.size()]
	var registro: String = registros[randi() % registros.size()]

	resultado_irregular = (
		permissao != "VALIDA"
		or situacao != "REGULAR"
		or registro != "EM DIA"
	)

	resultado_scan = {
		"piloto": "P-%03d" % (100 + (randi() % 900)),
		"permissao": permissao,
		"situacao": situacao,
		"condicao": condicao,
		"registro": registro,
		"acao": "ABORDAR E CONFERIR" if resultado_irregular else "LIBERAR E MONITORAR"
	}


func mostrar_resultado_no_painel() -> void:
	panel_result.visible = true
	if resultado_irregular:
		label_result_title.text = "SCAN // IRREGULARIDADE DETECTADA"
		label_result_title.modulate = Color(1.0, 0.52, 0.12, 1.0)
		label_result_footer.text = "USE ORDEM PARA MANDAR PARAR"
	else:
		label_result_title.text = "SCAN // TUDO CERTO"
		label_result_title.modulate = Color(0.35, 1.0, 0.72, 1.0)
		label_result_footer.text = "NAVE LIBERADA - RETOMANDO PATRULHA"

	label_result_body.text = "[b]PILOTO:[/b] %s\n[b]PERMISSAO:[/b] %s\n[b]SITUACAO:[/b] %s\n[b]REGISTRO:[/b] %s\n[b]CONDICAO:[/b] %s\n[b]ACAO:[/b] %s" % [
		resultado_scan.get("piloto", "---"),
		resultado_scan.get("permissao", "---"),
		resultado_scan.get("situacao", "---"),
		resultado_scan.get("registro", "---"),
		resultado_scan.get("condicao", "---"),
		resultado_scan.get("acao", "---")
	]


# =========================================================
# UI
# =========================================================

func criar_ui() -> void:
	ui_layer = CanvasLayer.new()
	ui_layer.name = "SuspectPatrolUI"
	ui_layer.layer = 112
	add_child(ui_layer)

	ui_root = Control.new()
	ui_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ui_layer.add_child(ui_root)

	label_patrol = Label.new()
	label_patrol.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label_patrol.add_theme_font_size_override("font_size", 15)
	label_patrol.add_theme_color_override("font_color", Color(0.60, 0.95, 1.0, 0.95))
	label_patrol.add_theme_color_override("font_outline_color", Color(0.0, 0.0, 0.0, 0.82))
	label_patrol.add_theme_constant_override("outline_size", 2)
	ui_root.add_child(label_patrol)

	label_prompt = Label.new()
	label_prompt.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label_prompt.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label_prompt.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label_prompt.add_theme_font_size_override("font_size", 18)
	label_prompt.add_theme_color_override("font_color", Color(0.58, 0.96, 1.0, 0.98))
	label_prompt.add_theme_color_override("font_outline_color", Color(0.0, 0.0, 0.0, 0.90))
	label_prompt.add_theme_constant_override("outline_size", 3)
	label_prompt.visible = false
	ui_root.add_child(label_prompt)

	barra_scan_bg = ColorRect.new()
	barra_scan_bg.color = Color(0.03, 0.16, 0.22, 0.86)
	barra_scan_bg.visible = false
	ui_root.add_child(barra_scan_bg)

	barra_scan_fill = ColorRect.new()
	barra_scan_fill.color = Color(0.02, 0.84, 1.0, 0.92)
	barra_scan_fill.visible = false
	ui_root.add_child(barra_scan_fill)

	panel_result = Panel.new()
	panel_result.visible = false
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.02, 0.05, 0.08, 0.88)
	style.border_color = Color(0.06, 0.75, 1.0, 0.85)
	style.border_width_left = 2
	style.border_width_top = 2
	style.border_width_right = 2
	style.border_width_bottom = 2
	style.corner_radius_top_left = 10
	style.corner_radius_top_right = 10
	style.corner_radius_bottom_left = 10
	style.corner_radius_bottom_right = 10
	panel_result.add_theme_stylebox_override("panel", style)
	ui_root.add_child(panel_result)

	label_result_title = Label.new()
	label_result_title.add_theme_font_size_override("font_size", 16)
	label_result_title.add_theme_color_override("font_color", Color(0.62, 0.97, 1.0, 1.0))
	label_result_title.add_theme_color_override("font_outline_color", Color(0.0, 0.0, 0.0, 0.82))
	label_result_title.add_theme_constant_override("outline_size", 2)
	panel_result.add_child(label_result_title)

	label_result_body = RichTextLabel.new()
	label_result_body.bbcode_enabled = true
	label_result_body.fit_content = false
	label_result_body.scroll_active = false
	label_result_body.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label_result_body.add_theme_font_size_override("normal_font_size", 15)
	panel_result.add_child(label_result_body)

	label_result_footer = Label.new()
	label_result_footer.add_theme_font_size_override("font_size", 13)
	label_result_footer.add_theme_color_override("font_color", Color(0.96, 0.70, 0.18, 0.98))
	panel_result.add_child(label_result_footer)


func atualizar_layout_ui() -> void:
	if ui_root == null:
		return

	var tela := get_viewport().get_visible_rect().size
	var escala := clampf(minf(tela.x / 1280.0, tela.y / 720.0), 0.72, 1.35)

	ui_root.position = Vector2.ZERO
	ui_root.size = tela

	label_patrol.position = Vector2(28.0 * escala, tela.y - 82.0 * escala)
	label_patrol.size = Vector2(520.0 * escala, 28.0 * escala)
	label_patrol.add_theme_font_size_override("font_size", int(15.0 * escala))

	barra_scan_bg.position = Vector2(tela.x * 0.40, tela.y * 0.13)
	barra_scan_bg.size = Vector2(260.0 * escala, 10.0 * escala)
	barra_scan_fill.position = barra_scan_bg.position
	barra_scan_fill.size = Vector2(0.0, barra_scan_bg.size.y)

	panel_result.position = Vector2(24.0 * escala, tela.y * 0.50)
	panel_result.size = Vector2(340.0 * escala, 188.0 * escala)

	label_result_title.position = Vector2(16.0 * escala, 12.0 * escala)
	label_result_title.size = Vector2(panel_result.size.x - 32.0 * escala, 24.0 * escala)
	label_result_title.add_theme_font_size_override("font_size", int(16.0 * escala))

	label_result_body.position = Vector2(16.0 * escala, 42.0 * escala)
	label_result_body.size = Vector2(panel_result.size.x - 32.0 * escala, 112.0 * escala)
	label_result_body.add_theme_font_size_override("normal_font_size", int(15.0 * escala))

	label_result_footer.position = Vector2(16.0 * escala, panel_result.size.y - 28.0 * escala)
	label_result_footer.size = Vector2(panel_result.size.x - 32.0 * escala, 20.0 * escala)
	label_result_footer.add_theme_font_size_override("font_size", int(13.0 * escala))


func atualizar_prompt_tela() -> void:
	if label_prompt == null:
		return

	if !label_prompt.visible:
		return

	if suspect_root == null or !is_instance_valid(suspect_root) or camera_3d == null:
		label_prompt.visible = false
		return

	if camera_3d.is_position_behind(suspect_root.global_position):
		label_prompt.visible = false
		return

	var pos_2d := camera_3d.unproject_position(suspect_root.global_position + Vector3(0.0, 2.2, 0.0))
	label_prompt.position = pos_2d - Vector2(130.0, 34.0)
	label_prompt.size = Vector2(260.0, 68.0)


func atualizar_texto_patrulha(texto: String) -> void:
	if label_patrol != null:
		label_patrol.text = texto


# =========================================================
# UTIL
# =========================================================

func localizar_referencias() -> void:
	var scene := get_tree().current_scene
	if scene == null:
		return

	if player == null or !is_instance_valid(player):
		var p := scene.find_child("Player", true, false)
		if p is Node3D:
			player = p as Node3D

	if camera_3d == null or !is_instance_valid(camera_3d):
		var c := scene.find_child("Camera3D", true, false)
		if c is Camera3D:
			camera_3d = c as Camera3D


func set_objetivo_cockpit(texto: String) -> void:
	var scene := get_tree().current_scene
	if scene == null:
		return

	var alvo := scene.find_child("CockpitFX", true, false)
	if alvo == null:
		alvo = scene.find_child("cockpit_fx", true, false)

	if alvo != null:
		var label_var: Variant = alvo.get("label_objetivo")
		if label_var is Label:
			(label_var as Label).text = texto
			return

	# fallback: tenta achar algum label com "OBJETIVO"
	for node in scene.find_children("*", "Label", true, false):
		var lb := node as Label
		if lb != null and lb.text.to_upper().contains("OBJETIVO"):
			lb.text = texto
			return
