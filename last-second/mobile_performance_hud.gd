extends CanvasLayer


# =========================================================
# LAST SECOND
# MOBILE PERFORMANCE HUD v1.2
#
# - FPS / frame / draw calls / objetos / primitivas
# - Canto superior direito para nao cobrir o painel de ocorrencia
# - Reposiciona automaticamente em resolucoes diferentes
# =========================================================


@export var atualizar_a_cada: float = 0.5
@export var mostrar_no_pc: bool = true
@export var margem: float = 12.0


var painel: Panel = null
var label: Label = null

var tempo: float = 0.0


func _ready() -> void:

	layer = 999
	process_mode = Node.PROCESS_MODE_ALWAYS

	var eh_mobile: bool = (
		OS.has_feature("android")
		or
		OS.has_feature("ios")
		or
		OS.has_feature("mobile")
	)

	if !eh_mobile and !mostrar_no_pc:
		visible = false
		return

	criar_interface()
	reposicionar_painel()
	atualizar_texto()


func _process(delta: float) -> void:

	if !visible:
		return

	tempo += delta

	if tempo >= atualizar_a_cada:
		tempo = 0.0
		reposicionar_painel()
		atualizar_texto()


func criar_interface() -> void:

	painel = Panel.new()
	painel.size = Vector2(
		310.0,
		126.0
	)

	var estilo: StyleBoxFlat = StyleBoxFlat.new()

	estilo.bg_color = Color(
		0.0,
		0.0,
		0.0,
		0.72
	)

	estilo.border_color = Color(
		0.15,
		0.72,
		1.0,
		0.75
	)

	estilo.border_width_left = 1
	estilo.border_width_top = 1
	estilo.border_width_right = 1
	estilo.border_width_bottom = 1

	estilo.corner_radius_top_left = 8
	estilo.corner_radius_top_right = 8
	estilo.corner_radius_bottom_left = 8
	estilo.corner_radius_bottom_right = 8

	painel.add_theme_stylebox_override(
		"panel",
		estilo
	)

	add_child(
		painel
	)

	label = Label.new()

	label.position = Vector2(
		12.0,
		10.0
	)

	label.size = Vector2(
		286.0,
		106.0
	)

	label.add_theme_font_size_override(
		"font_size",
		13
	)

	label.add_theme_color_override(
		"font_color",
		Color.WHITE
	)

	painel.add_child(
		label
	)


func reposicionar_painel() -> void:

	if painel == null:
		return

	var tamanho_tela: Vector2 = get_viewport().get_visible_rect().size

	painel.position = Vector2(
		maxf(
			margem,
			tamanho_tela.x - painel.size.x - margem
		),
		margem
	)


func atualizar_texto() -> void:

	if label == null:
		return

	var fps: float = Performance.get_monitor(
		Performance.TIME_FPS
	)

	var tempo_frame_seg: float = Performance.get_monitor(
		Performance.TIME_PROCESS
	)

	var tempo_frame_ms: float = (
		tempo_frame_seg
		*
		1000.0
	)

	var objetos: float = Performance.get_monitor(
		Performance.RENDER_TOTAL_OBJECTS_IN_FRAME
	)

	var primitivas: float = Performance.get_monitor(
		Performance.RENDER_TOTAL_PRIMITIVES_IN_FRAME
	)

	var draw_calls: float = Performance.get_monitor(
		Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME
	)


	var estado: String = "OK"

	if fps < 25.0:
		estado = "PESADO"
	elif fps < 45.0:
		estado = "ATENCAO"

	label.text = (
		"LAST SECOND // PERFORMANCE\n"
		+
		"FPS: %.0f   [%s]\n"
		% [
			fps,
			estado
		]
		+
		"FRAME: %.2f ms\n"
		% tempo_frame_ms
		+
		"DRAW CALLS: %.0f\n"
		% draw_calls
		+
		"OBJETOS: %.0f\n"
		% objetos
		+
		"PRIMITIVAS: %.0f"
		% primitivas
	)
