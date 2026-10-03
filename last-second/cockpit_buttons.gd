extends Control


# =========================================================
# LAST SECOND - COCKPIT BUTTONS v1.0
# BOTOES FISICOS DO COCKPIT
# =========================================================


# Deixe TRUE enquanto estamos calibrando os botoes.
# Depois mudaremos para FALSE e eles ficarão invisíveis.
const MODO_TESTE: bool = true


var botao_power: Button = null
var botao_engine: Button = null
var botao_launch: Button = null


# =========================================================
# READY
# =========================================================

func _ready() -> void:

	mouse_filter = Control.MOUSE_FILTER_PASS

	criar_botoes()

	get_viewport().size_changed.connect(
		ajustar_botoes
	)

	ajustar_botoes()

	print("CockpitButtons carregado.")


# =========================================================
# CRIAR BOTOES
# =========================================================

func criar_botoes() -> void:

	botao_power = criar_botao(
		"POWER"
	)

	botao_engine = criar_botao(
		"ENGINE"
	)

	botao_launch = criar_botao(
		"LAUNCH"
	)


	botao_power.pressed.connect(
		pressionar_power
	)

	botao_engine.pressed.connect(
		pressionar_engine
	)

	botao_launch.pressed.connect(
		pressionar_launch
	)


# =========================================================
# CRIAR UM BOTAO
# =========================================================

func criar_botao(
	texto: String
) -> Button:

	var botao: Button = Button.new()

	botao.text = texto

	botao.focus_mode = Control.FOCUS_NONE

	botao.mouse_default_cursor_shape = (
		Control.CURSOR_POINTING_HAND
	)


	if MODO_TESTE:

		botao.modulate = Color(
			1.0,
			1.0,
			1.0,
			0.65
		)

	else:

		# Continua clicável,
		# mas fica invisível.
		botao.modulate = Color(
			1.0,
			1.0,
			1.0,
			0.0
		)


	add_child(
		botao
	)

	return botao


# =========================================================
# POSICIONAR EM CIMA DOS BOTOES DO COCKPIT
# =========================================================

func ajustar_botoes() -> void:

	var tamanho_tela: Vector2 = (
		get_viewport_rect().size
	)


	# =====================================================
	# TAMANHO DAS AREAS CLICAVEIS
	# =====================================================

	var largura: float = (
		tamanho_tela.x * 0.060
	)

	var altura: float = (
		tamanho_tela.y * 0.060
	)


	var tamanho_botao := Vector2(
		largura,
		altura
	)


	# =====================================================
	# POWER
	# =====================================================

	var centro_power := Vector2(
		tamanho_tela.x * 0.470,
		tamanho_tela.y * 0.915
	)

	botao_power.size = tamanho_botao

	botao_power.position = (
		centro_power
		-
		tamanho_botao / 2.0
	)


	# =====================================================
	# ENGINE
	# =====================================================

	var centro_engine := Vector2(
		tamanho_tela.x * 0.535,
		tamanho_tela.y * 0.915
	)

	botao_engine.size = tamanho_botao

	botao_engine.position = (
		centro_engine
		-
		tamanho_botao / 2.0
	)


	# =====================================================
	# LAUNCH
	# =====================================================

	var centro_launch := Vector2(
		tamanho_tela.x * 0.600,
		tamanho_tela.y * 0.915
	)

	botao_launch.size = tamanho_botao

	botao_launch.position = (
		centro_launch
		-
		tamanho_botao / 2.0
	)


# =========================================================
# POWER
# =========================================================

func pressionar_power() -> void:

	print("COCKPIT: MAIN POWER")

	simular_tecla(
		KEY_1
	)


# =========================================================
# ENGINE
# =========================================================

func pressionar_engine() -> void:

	print("COCKPIT: ENGINE START")

	simular_tecla(
		KEY_2
	)


# =========================================================
# LAUNCH
# =========================================================

func pressionar_launch() -> void:

	print("COCKPIT: LAUNCH")

	simular_tecla(
		KEY_3
	)


# =========================================================
# SIMULAR TECLA
# =========================================================

func simular_tecla(
	tecla: Key
) -> void:

	var pressionar := InputEventKey.new()

	pressionar.keycode = tecla

	pressionar.physical_keycode = tecla

	pressionar.pressed = true


	Input.parse_input_event(
		pressionar
	)


	await get_tree().process_frame


	var soltar := InputEventKey.new()

	soltar.keycode = tecla

	soltar.physical_keycode = tecla

	soltar.pressed = false


	Input.parse_input_event(
		soltar
	)
