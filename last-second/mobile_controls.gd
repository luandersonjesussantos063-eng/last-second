extends Node


# =========================================================
# LAST SECOND
# CONTROLES MOBILE v5.1 // ON FOOT MODE + SPAWN SYNC + START LOCK + PEDAL
#
# CONTROLES:
# - Arraste o dedo na tela = pilotar a nave
# - SCAN = E
# - ORDEM = F
# - TURBO = SHIFT
# - ATIRAR = ESPACO
# - GIRO = liga/desliga giroflex visual
# - SIRENE = liga/desliga sirene sintetica
# - visual futurista inspirado no conceito da cabine
# - compativel com no do tipo Node (CanvasLayer criado internamente)
# =========================================================

@export var mostrar_no_pc_para_teste: bool = true
@export_range(0.20, 1.0, 0.05) var opacidade_controles: float = 0.42
@export_range(0.50, 2.00, 0.05) var sensibilidade_touch: float = 1.00
@export_range(8.0, 80.0, 1.0) var distancia_base_ativacao: float = 34.0
@export_range(0.10, 0.60, 0.01) var zona_morta_direcional: float = 0.22
@export_range(0.0, 1.0, 0.05) var volume_sirene: float = 0.35
@export_range(40.0, 400.0, 5.0) var velocidade_maxima_nave: float = 180.0
@export_range(0.0, 400.0, 1.0) var velocidade_inicial_nave: float = 0.0
@export_range(10.0, 300.0, 5.0) var aceleracao_pedal: float = 85.0
@export_range(10.0, 300.0, 5.0) var desaceleracao_pedal: float = 105.0
@export_range(1.0, 20.0, 1.0) var passo_velocidade_teclado: float = 5.0
@export var colisao_fisica_ativa: bool = true
@export_range(0.5, 8.0, 0.1) var raio_colisao_p01: float = 2.6
@export var mascara_colisao_voo: int = 1

const ACAO_SCAN: String = "scan"
const ACAO_ORDEM: String = "ordem"
const ACAO_TURBO: String = "turbo"
const ACAO_ATIRAR: String = "atirar"
const ACAO_GIRO: String = "giro"
const ACAO_SIRENE: String = "sirene"

const CONFIG_PATH: String = "user://last_second_settings.cfg"

var camada_ui: CanvasLayer = null
var raiz: Control = null
var dica_pilotagem: Label = null

var botao_scan: Control = null
var botao_ordem: Control = null
var botao_turbo: Control = null
var botao_atirar: Control = null
var botao_giro: Control = null
var botao_sirene: Control = null

var throttle_root: Control = null
var throttle_base: Panel = null
var throttle_fill: ColorRect = null
var throttle_knob: Panel = null
var throttle_label: Label = null
var throttle_value: Label = null
var throttle_max_label: Label = null
var throttle_rect: Rect2 = Rect2()
var throttle_touch_id: int = -9999
var throttle_mouse_ativo: bool = false
var pedal_pressionado: bool = false

var reflexo_esquerda: ColorRect = null
var reflexo_direita: ColorRect = null
var reflexo_topo: ColorRect = null

var giro_bar_base: Panel = null
var giro_bar_red: ColorRect = null
var giro_bar_blue: ColorRect = null
var giro_bar_red_glow: ColorRect = null
var giro_bar_blue_glow: ColorRect = null

var botoes_visuais: Dictionary = {}
var botoes_titulos: Dictionary = {}
var botoes_estados: Dictionary = {}
var botoes_cores: Dictionary = {}
var botoes_toggle: Dictionary = {
	ACAO_GIRO: true,
	ACAO_SIRENE: true
}
var estado_toggles: Dictionary = {
	ACAO_GIRO: false,
	ACAO_SIRENE: false
}
var retangulos_botoes: Dictionary = {}

var toque_pilotagem: int = -1
var origem_pilotagem: Vector2 = Vector2.ZERO
var posicao_pilotagem: Vector2 = Vector2.ZERO
var mouse_pilotagem_ativo: bool = false

var toques_botoes: Dictionary = {}
var contagem_acoes: Dictionary = {
	ACAO_SCAN: 0,
	ACAO_ORDEM: 0,
	ACAO_TURBO: 0,
	ACAO_ATIRAR: 0
}

var tecla_w_ativa: bool = false
var tecla_a_ativa: bool = false
var tecla_s_ativa: bool = false
var tecla_d_ativa: bool = false

var eh_mobile: bool = false
var controles_ativos: bool = false
var modo_a_pe: bool = false

var ultimo_tamanho_tela: Vector2 = Vector2.ZERO
var tempo_recarregar_config: float = 0.0
var tempo_atualizar_prompts: float = 0.0
var tempo_giroflex: float = 0.0

var velocidade_selecionada: float = 0.0
var velocidade_efetiva: float = 0.0
var player_nave: Node3D = null
var camera_nave: Camera3D = null
var propriedade_velocidade_player: StringName = &""
var controle_velocidade_direto: bool = false
var ultima_posicao_corrigida: Vector3 = Vector3.ZERO
var fallback_velocidade_inicializado: bool = false
var tempo_buscar_player: float = 0.0
var forma_colisao_p01: SphereShape3D = null

var scanner_contexto: Node = null
var cockpit_contexto: Node = null

var sirene_player: AudioStreamPlayer = null
var sirene_generator: AudioStreamGenerator = null
var sirene_playback: AudioStreamGeneratorPlayback = null
var sirene_fase: float = 0.0
var sirene_tempo: float = 0.0


# =========================================================
# READY
# =========================================================

func _ready() -> void:
	camada_ui = CanvasLayer.new()
	camada_ui.name = "MobileControlsCanvas"
	camada_ui.layer = 120
	add_child(camada_ui)

	process_mode = Node.PROCESS_MODE_ALWAYS
	# Roda depois do controlador antigo da nave para neutralizar o auto-forward.
	process_priority = 1000
	process_physics_priority = 1000

	forma_colisao_p01 = SphereShape3D.new()
	forma_colisao_p01.radius = raio_colisao_p01

	eh_mobile = (
		OS.has_feature("android")
		or OS.has_feature("ios")
		or OS.has_feature("mobile")
	)

	carregar_sensibilidade()
	carregar_visibilidade_pc()
	carregar_velocidade_nave()

	controles_ativos = (
		eh_mobile
		or mostrar_no_pc_para_teste
	)

	criar_audio_sirene()
	criar_interface()

	raiz.visible = controles_ativos

	if !controles_ativos:
		return

	await get_tree().process_frame
	await get_tree().process_frame

	localizar_sistemas_contexto()
	localizar_player_e_propriedade_velocidade()
	atualizar_layout()
	atualizar_status_toggles()
	adaptar_prompts_para_touch()


# =========================================================
# PROCESS
# =========================================================

func _process(delta: float) -> void:
	tempo_recarregar_config += delta
	tempo_atualizar_prompts += delta

	if tempo_recarregar_config >= 0.50:
		tempo_recarregar_config = 0.0
		carregar_sensibilidade()

	if !controles_ativos:
		return

	var tamanho_atual: Vector2 = get_viewport().get_visible_rect().size
	if tamanho_atual != ultimo_tamanho_tela:
		atualizar_layout()

	if !get_tree().paused and tempo_atualizar_prompts >= 0.12:
		tempo_atualizar_prompts = 0.0
		localizar_sistemas_contexto()
		adaptar_prompts_para_touch()

	tempo_buscar_player += delta
	if tempo_buscar_player >= 1.0:
		tempo_buscar_player = 0.0
		if player_nave == null or !is_instance_valid(player_nave):
			localizar_player_e_propriedade_velocidade()

	atualizar_velocidade_efetiva()
	atualizar_interface_throttle()
	atualizar_reflexos_giroflex(delta)
	atualizar_audio_sirene()
	manter_nave_parada_se_sem_propulsao()


# =========================================================
# PHYSICS PROCESS - VELOCIDADE REAL DA P-01
# =========================================================

func _physics_process(delta: float) -> void:
	if !controles_ativos:
		return
	if get_tree().paused:
		return

	# Enquanto o policial estiver fora da P-01, a nave permanece travada.
	if modo_a_pe:
		pedal_pressionado = false
		velocidade_selecionada = 0.0
		velocidade_efetiva = 0.0
		manter_nave_parada_se_sem_propulsao()
		return

	# Pedal de apertar: segurando acelera, soltando desacelera.
	atualizar_pedal(delta)
	atualizar_velocidade_efetiva()
	aplicar_velocidade_na_nave(delta)


# =========================================================
# INPUT
# =========================================================

func _input(event: InputEvent) -> void:
	if !controles_ativos:
		return

	if get_tree().paused:
		return

	if modo_a_pe:
		return

	if event is InputEventScreenTouch:
		var toque: InputEventScreenTouch = event as InputEventScreenTouch
		if toque.pressed:
			if iniciar_toque(toque.index, toque.position):
				get_viewport().set_input_as_handled()
		else:
			if finalizar_toque(toque.index):
				get_viewport().set_input_as_handled()
		return

	if event is InputEventScreenDrag:
		var arrasto: InputEventScreenDrag = event as InputEventScreenDrag
		# O pedal nao usa arrasto. Enquanto o dedo continuar sendo o do pedal,
		# apenas mantemos a aceleracao ativa e consumimos o gesto.
		if arrasto.index == throttle_touch_id:
			get_viewport().set_input_as_handled()
			return
		if arrasto.index == toque_pilotagem:
			posicao_pilotagem = arrasto.position
			atualizar_pilotagem_touch()
			get_viewport().set_input_as_handled()
		return

	if !eh_mobile and mostrar_no_pc_para_teste:
		if event is InputEventMouseButton:
			var clique: InputEventMouseButton = event as InputEventMouseButton
			if clique.button_index != MOUSE_BUTTON_LEFT:
				return
			if clique.pressed:
				iniciar_toque(-100, clique.position)
			else:
				finalizar_toque(-100)
			return

		if event is InputEventMouseMotion:
			var movimento: InputEventMouseMotion = event as InputEventMouseMotion
			if throttle_mouse_ativo:
				return
			if mouse_pilotagem_ativo:
				posicao_pilotagem = movimento.position
				atualizar_pilotagem_touch()


# =========================================================
# TOQUE / CLIQUE
# =========================================================

func iniciar_toque(id_toque: int, posicao: Vector2) -> bool:
	# Pedal tem prioridade para nao virar comando de pilotagem.
	if throttle_rect.has_point(posicao):
		throttle_touch_id = id_toque
		pedal_pressionado = true
		if id_toque == -100:
			throttle_mouse_ativo = true
		atualizar_interface_throttle()
		return true

	for acao: String in retangulos_botoes.keys():
		var rect: Rect2 = retangulos_botoes[acao]
		if rect.has_point(posicao):
			toques_botoes[id_toque] = acao
			if eh_acao_toggle(acao):
				alternar_toggle(acao)
				aplicar_visual_botao(acao, true)
			else:
				pressionar_acao(acao)
			return true

	if toque_pilotagem == -1:
		toque_pilotagem = id_toque
		origem_pilotagem = posicao
		posicao_pilotagem = posicao
		if id_toque == -100:
			mouse_pilotagem_ativo = true
		atualizar_pilotagem_touch()
		return true

	return false


func finalizar_toque(id_toque: int) -> bool:
	var tratou: bool = false

	if id_toque == throttle_touch_id:
		throttle_touch_id = -9999
		throttle_mouse_ativo = false
		pedal_pressionado = false
		atualizar_interface_throttle()
		tratou = true

	if id_toque == toque_pilotagem:
		toque_pilotagem = -1
		mouse_pilotagem_ativo = false
		resetar_pilotagem()
		tratou = true

	if toques_botoes.has(id_toque):
		var acao: String = String(toques_botoes[id_toque])
		toques_botoes.erase(id_toque)
		if eh_acao_toggle(acao):
			aplicar_visual_botao(acao, false)
		else:
			soltar_acao(acao)
		tratou = true

	return tratou


func eh_acao_toggle(acao: String) -> bool:
	return bool(botoes_toggle.get(acao, false))


# =========================================================
# PILOTAGEM
# =========================================================

func atualizar_pilotagem_touch() -> void:
	if toque_pilotagem == -1:
		return

	var deslocamento: Vector2 = posicao_pilotagem - origem_pilotagem
	var divisor: float = maxf(distancia_base_ativacao / maxf(sensibilidade_touch, 0.05), 1.0)
	var valor: Vector2 = deslocamento / divisor

	valor.x = clampf(valor.x, -1.0, 1.0)
	valor.y = clampf(valor.y, -1.0, 1.0)

	var esquerda: bool = valor.x < -zona_morta_direcional
	var direita: bool = valor.x > zona_morta_direcional
	var cima: bool = valor.y < -zona_morta_direcional
	var baixo: bool = valor.y > zona_morta_direcional

	definir_tecla_pilotagem(KEY_A, esquerda)
	definir_tecla_pilotagem(KEY_D, direita)
	definir_tecla_pilotagem(KEY_W, cima)
	definir_tecla_pilotagem(KEY_S, baixo)


func resetar_pilotagem() -> void:
	definir_tecla_pilotagem(KEY_W, false)
	definir_tecla_pilotagem(KEY_A, false)
	definir_tecla_pilotagem(KEY_S, false)
	definir_tecla_pilotagem(KEY_D, false)


func definir_tecla_pilotagem(codigo: int, pressionada: bool) -> void:
	match codigo:
		KEY_W:
			if tecla_w_ativa == pressionada:
				return
			tecla_w_ativa = pressionada
		KEY_A:
			if tecla_a_ativa == pressionada:
				return
			tecla_a_ativa = pressionada
		KEY_S:
			if tecla_s_ativa == pressionada:
				return
			tecla_s_ativa = pressionada
		KEY_D:
			if tecla_d_ativa == pressionada:
				return
			tecla_d_ativa = pressionada
		_:
			return

	enviar_tecla(codigo, pressionada)


# =========================================================
# ACOES PADRAO
# =========================================================

func pressionar_acao(acao: String) -> void:
	var quantidade: int = int(contagem_acoes.get(acao, 0))
	quantidade += 1
	contagem_acoes[acao] = quantidade

	if quantidade == 1:
		enviar_tecla(pegar_tecla_acao(acao), true)

	if acao == ACAO_TURBO:
		atualizar_velocidade_efetiva()

	aplicar_visual_botao(acao, true)


func soltar_acao(acao: String) -> void:
	var quantidade: int = int(contagem_acoes.get(acao, 0))
	quantidade = maxi(quantidade - 1, 0)
	contagem_acoes[acao] = quantidade

	if quantidade == 0:
		enviar_tecla(pegar_tecla_acao(acao), false)

	if acao == ACAO_TURBO:
		atualizar_velocidade_efetiva()

	aplicar_visual_botao(acao, false)


func pegar_tecla_acao(acao: String) -> int:
	match acao:
		ACAO_SCAN:
			return KEY_E
		ACAO_ORDEM:
			return KEY_F
		ACAO_TURBO:
			return KEY_SHIFT
		ACAO_ATIRAR:
			return KEY_SPACE
	return KEY_NONE


func enviar_tecla(codigo: int, pressionada: bool) -> void:
	if codigo == KEY_NONE:
		return

	var evento: InputEventKey = InputEventKey.new()
	evento.keycode = codigo
	evento.physical_keycode = codigo
	evento.pressed = pressionada
	evento.echo = false
	Input.parse_input_event(evento)


# =========================================================
# GIROFLEX / SIRENE
# =========================================================

func alternar_toggle(acao: String) -> void:
	var novo_estado: bool = !bool(estado_toggles.get(acao, false))
	estado_toggles[acao] = novo_estado

	match acao:
		ACAO_GIRO:
			if !novo_estado:
				limpar_reflexos_giroflex()
		ACAO_SIRENE:
			if novo_estado:
				iniciar_sirene()
			else:
				parar_sirene()

	atualizar_status_toggles()


func atualizar_status_toggles() -> void:
	atualizar_status_toggle_unico(ACAO_GIRO, "ON", "OFF")
	atualizar_status_toggle_unico(ACAO_SIRENE, "ON", "OFF")


func atualizar_status_toggle_unico(acao: String, texto_on: String, texto_off: String) -> void:
	var label_estado: Label = botoes_estados.get(acao, null)
	if label_estado == null:
		return

	if bool(estado_toggles.get(acao, false)):
		label_estado.text = texto_on
	else:
		label_estado.text = texto_off

	aplicar_visual_botao(acao, false)


func criar_audio_sirene() -> void:
	sirene_player = AudioStreamPlayer.new()
	sirene_player.name = "SireneSintetica"
	sirene_player.bus = "Master"
	add_child(sirene_player)

	sirene_generator = AudioStreamGenerator.new()
	sirene_generator.mix_rate = 22050.0
	sirene_generator.buffer_length = 0.18
	sirene_player.stream = sirene_generator
	if sirene_player.has_method("set_volume_linear"):
		sirene_player.set_volume_linear(maxf(volume_sirene, 0.001))


func iniciar_sirene() -> void:
	if sirene_player == null:
		return

	sirene_fase = 0.0
	sirene_tempo = 0.0
	sirene_playback = null

	if sirene_player.playing:
		sirene_player.stop()

	sirene_player.play()


func parar_sirene() -> void:
	if sirene_player != null and sirene_player.playing:
		sirene_player.stop()
	sirene_playback = null


func atualizar_audio_sirene() -> void:
	if !bool(estado_toggles.get(ACAO_SIRENE, false)):
		return

	if sirene_player == null:
		return

	if !sirene_player.playing:
		iniciar_sirene()
		return

	if sirene_playback == null:
		sirene_playback = sirene_player.get_stream_playback() as AudioStreamGeneratorPlayback
		if sirene_playback == null:
			return

	var frames: int = sirene_playback.get_frames_available()
	var mix_rate: float = maxf(sirene_generator.mix_rate, 1.0)

	for i in range(frames):
		var sweep: float = 0.5 + 0.5 * sin(sirene_tempo * 3.2)
		var freq: float = lerpf(620.0, 980.0, sweep)
		sirene_fase += TAU * freq / mix_rate
		if sirene_fase > TAU:
			sirene_fase -= TAU

		sirene_tempo += 1.0 / mix_rate
		var sample: float = sin(sirene_fase) * volume_sirene * 0.55
		var stereo_wobble: float = 0.12 * sin(sirene_tempo * 6.0)
		sirene_playback.push_frame(Vector2(sample + stereo_wobble, sample - stereo_wobble))


func atualizar_reflexos_giroflex(delta: float) -> void:
	if reflexo_esquerda == null or reflexo_direita == null or reflexo_topo == null:
		return

	# barra visivel mesmo desligada
	if giro_bar_red != null:
		giro_bar_red.color = Color(1.0, 0.22, 0.16, 0.30)
	if giro_bar_blue != null:
		giro_bar_blue.color = Color(0.18, 0.75, 1.0, 0.30)
	if giro_bar_red_glow != null:
		giro_bar_red_glow.color = Color(1.0, 0.15, 0.10, 0.05)
	if giro_bar_blue_glow != null:
		giro_bar_blue_glow.color = Color(0.10, 0.65, 1.0, 0.05)

	if !bool(estado_toggles.get(ACAO_GIRO, false)):
		limpar_reflexos_giroflex()
		return

	tempo_giroflex += delta
	var onda: float = sin(tempo_giroflex * 13.5)
	var pisca_esquerda: float = maxf(onda, 0.0)
	var pisca_direita: float = maxf(-onda, 0.0)
	var pico: float = maxf(pisca_esquerda, pisca_direita)

	reflexo_esquerda.color = Color(1.0, 0.12, 0.12, 0.16 + pisca_esquerda * 0.42)
	reflexo_direita.color = Color(0.08, 0.72, 1.0, 0.14 + pisca_direita * 0.42)
	reflexo_topo.color = Color(0.65 + 0.35 * pisca_direita, 0.10, 0.22 + 0.78 * pisca_esquerda, 0.10 + pico * 0.18)

	if giro_bar_red != null:
		giro_bar_red.color = Color(1.0, 0.20, 0.12, 0.58 + pisca_esquerda * 0.42)
	if giro_bar_blue != null:
		giro_bar_blue.color = Color(0.12, 0.75, 1.0, 0.58 + pisca_direita * 0.42)
	if giro_bar_red_glow != null:
		giro_bar_red_glow.color = Color(1.0, 0.18, 0.12, 0.10 + pisca_esquerda * 0.24)
	if giro_bar_blue_glow != null:
		giro_bar_blue_glow.color = Color(0.12, 0.70, 1.0, 0.10 + pisca_direita * 0.24)


func limpar_reflexos_giroflex() -> void:
	if reflexo_esquerda != null:
		reflexo_esquerda.color = Color(1.0, 0.1, 0.1, 0.0)
	if reflexo_direita != null:
		reflexo_direita.color = Color(0.1, 0.7, 1.0, 0.0)
	if reflexo_topo != null:
		reflexo_topo.color = Color(1.0, 1.0, 1.0, 0.0)
	if giro_bar_red != null:
		giro_bar_red.color = Color(1.0, 0.22, 0.16, 0.30)
	if giro_bar_blue != null:
		giro_bar_blue.color = Color(0.18, 0.75, 1.0, 0.30)
	if giro_bar_red_glow != null:
		giro_bar_red_glow.color = Color(1.0, 0.15, 0.10, 0.05)
	if giro_bar_blue_glow != null:
		giro_bar_blue_glow.color = Color(0.10, 0.65, 1.0, 0.05)


# =========================================================
# INTERFACE
# =========================================================

func criar_interface() -> void:
	raiz = Control.new()
	raiz.name = "MobileControlsRoot"
	raiz.mouse_filter = Control.MOUSE_FILTER_IGNORE
	camada_ui.add_child(raiz)

	giro_bar_base = Panel.new()
	giro_bar_base.name = "GiroBarBase"
	giro_bar_base.mouse_filter = Control.MOUSE_FILTER_IGNORE
	raiz.add_child(giro_bar_base)

	giro_bar_red_glow = ColorRect.new()
	giro_bar_red_glow.name = "GiroBarRedGlow"
	giro_bar_red_glow.mouse_filter = Control.MOUSE_FILTER_IGNORE
	giro_bar_base.add_child(giro_bar_red_glow)

	giro_bar_blue_glow = ColorRect.new()
	giro_bar_blue_glow.name = "GiroBarBlueGlow"
	giro_bar_blue_glow.mouse_filter = Control.MOUSE_FILTER_IGNORE
	giro_bar_base.add_child(giro_bar_blue_glow)

	giro_bar_red = ColorRect.new()
	giro_bar_red.name = "GiroBarRed"
	giro_bar_red.mouse_filter = Control.MOUSE_FILTER_IGNORE
	giro_bar_base.add_child(giro_bar_red)

	giro_bar_blue = ColorRect.new()
	giro_bar_blue.name = "GiroBarBlue"
	giro_bar_blue.mouse_filter = Control.MOUSE_FILTER_IGNORE
	giro_bar_base.add_child(giro_bar_blue)

	reflexo_topo = ColorRect.new()
	reflexo_topo.mouse_filter = Control.MOUSE_FILTER_IGNORE
	raiz.add_child(reflexo_topo)

	reflexo_esquerda = ColorRect.new()
	reflexo_esquerda.mouse_filter = Control.MOUSE_FILTER_IGNORE
	raiz.add_child(reflexo_esquerda)

	reflexo_direita = ColorRect.new()
	reflexo_direita.mouse_filter = Control.MOUSE_FILTER_IGNORE
	raiz.add_child(reflexo_direita)

	dica_pilotagem = Label.new()
	dica_pilotagem.name = "TouchFlightHint"
	dica_pilotagem.text = "ARRASTE NA TELA PARA PILOTAR"
	dica_pilotagem.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	dica_pilotagem.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	dica_pilotagem.mouse_filter = Control.MOUSE_FILTER_IGNORE
	dica_pilotagem.add_theme_color_override("font_color", Color(0.45, 0.88, 1.0, 0.48))
	dica_pilotagem.add_theme_color_override("font_outline_color", Color(0.0, 0.0, 0.0, 0.70))
	dica_pilotagem.add_theme_constant_override("outline_size", 2)
	raiz.add_child(dica_pilotagem)

	criar_interface_throttle()

	botao_scan = criar_botao_futurista(ACAO_SCAN, "SCAN", "SCAN", Color(0.05, 0.72, 0.98, 1.0), false)
	botao_ordem = criar_botao_futurista(ACAO_ORDEM, "ORDEM", "POLICE", Color(1.0, 0.50, 0.08, 1.0), false)
	botao_turbo = criar_botao_futurista(ACAO_TURBO, "TURBO", "BOOST", Color(0.20, 0.42, 1.0, 1.0), false)
	botao_atirar = criar_botao_futurista(ACAO_ATIRAR, "ATIRAR", "FIRE", Color(1.0, 0.14, 0.12, 1.0), false)
	botao_giro = criar_botao_futurista(ACAO_GIRO, "GIRO", "OFF", Color(0.08, 0.90, 1.0, 1.0), true)
	botao_sirene = criar_botao_futurista(ACAO_SIRENE, "SIRENE", "OFF", Color(1.0, 0.26, 0.20, 1.0), true)


func criar_botao_futurista(acao: String, titulo_texto: String, estado_texto: String, cor: Color, toggle: bool) -> Control:
	var root := Control.new()
	root.name = "Botao_" + acao
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	raiz.add_child(root)

	var base := Panel.new()
	base.name = "Base"
	base.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(base)

	var brilho := ColorRect.new()
	brilho.name = "Brilho"
	brilho.mouse_filter = Control.MOUSE_FILTER_IGNORE
	base.add_child(brilho)

	var faixa_topo := ColorRect.new()
	faixa_topo.name = "FaixaTopo"
	faixa_topo.mouse_filter = Control.MOUSE_FILTER_IGNORE
	base.add_child(faixa_topo)

	var faixa_base := ColorRect.new()
	faixa_base.name = "FaixaBase"
	faixa_base.mouse_filter = Control.MOUSE_FILTER_IGNORE
	base.add_child(faixa_base)

	var titulo := Label.new()
	titulo.name = "Titulo"
	titulo.text = titulo_texto
	titulo.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	titulo.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	titulo.mouse_filter = Control.MOUSE_FILTER_IGNORE
	titulo.add_theme_color_override("font_outline_color", Color(0.0, 0.0, 0.0, 0.85))
	titulo.add_theme_constant_override("outline_size", 2)
	base.add_child(titulo)

	var estado := Label.new()
	estado.name = "Estado"
	estado.text = estado_texto
	estado.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	estado.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	estado.mouse_filter = Control.MOUSE_FILTER_IGNORE
	estado.add_theme_color_override("font_outline_color", Color(0.0, 0.0, 0.0, 0.85))
	estado.add_theme_constant_override("outline_size", 1)
	base.add_child(estado)

	botoes_visuais[acao] = root
	botoes_titulos[acao] = titulo
	botoes_estados[acao] = estado
	botoes_cores[acao] = cor
	if toggle:
		botoes_toggle[acao] = true

	aplicar_visual_botao(acao, false)
	return root


# =========================================================
# THROTTLE / VELOCIDADE SELECIONAVEL
# =========================================================

func criar_interface_throttle() -> void:
	throttle_root = Control.new()
	throttle_root.name = "ThrottleControl"
	throttle_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	raiz.add_child(throttle_root)

	throttle_base = Panel.new()
	throttle_base.name = "Base"
	throttle_base.mouse_filter = Control.MOUSE_FILTER_IGNORE
	throttle_root.add_child(throttle_base)

	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.02, 0.05, 0.08, 0.24)
	style.border_color = Color(0.12, 0.80, 1.0, 0.40)
	style.border_width_left = 2
	style.border_width_top = 2
	style.border_width_right = 2
	style.border_width_bottom = 2
	style.corner_radius_top_left = 18
	style.corner_radius_top_right = 18
	style.corner_radius_bottom_left = 26
	style.corner_radius_bottom_right = 26
	style.shadow_size = 0
	throttle_base.add_theme_stylebox_override("panel", style)

	throttle_fill = ColorRect.new()
	throttle_fill.name = "Fill"
	throttle_fill.mouse_filter = Control.MOUSE_FILTER_IGNORE
	throttle_fill.color = Color(0.04, 0.78, 1.0, 0.16)
	throttle_base.add_child(throttle_fill)

	throttle_knob = Panel.new()
	throttle_knob.name = "Knob"
	throttle_knob.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var knob_style := StyleBoxFlat.new()
	knob_style.bg_color = Color(0.12, 0.86, 1.0, 0.60)
	knob_style.border_color = Color(0.80, 0.98, 1.0, 0.78)
	knob_style.border_width_left = 1
	knob_style.border_width_top = 1
	knob_style.border_width_right = 1
	knob_style.border_width_bottom = 1
	knob_style.corner_radius_top_left = 10
	knob_style.corner_radius_top_right = 10
	knob_style.corner_radius_bottom_left = 10
	knob_style.corner_radius_bottom_right = 10
	throttle_knob.add_theme_stylebox_override("panel", knob_style)
	throttle_base.add_child(throttle_knob)

	throttle_label = Label.new()
	throttle_label.text = "ACELERADOR"
	throttle_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	throttle_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	throttle_label.add_theme_color_override("font_color", Color(0.70, 0.92, 1.0, 0.55))
	throttle_root.add_child(throttle_label)

	throttle_value = Label.new()
	throttle_value.text = "022"
	throttle_value.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	throttle_value.mouse_filter = Control.MOUSE_FILTER_IGNORE
	throttle_value.add_theme_color_override("font_color", Color(0.80, 0.97, 1.0, 0.92))
	throttle_value.add_theme_color_override("font_outline_color", Color(0.0, 0.0, 0.0, 0.85))
	throttle_value.add_theme_constant_override("outline_size", 2)
	throttle_root.add_child(throttle_value)

	throttle_max_label = Label.new()
	throttle_max_label.text = "SEGURE PARA ACELERAR"
	throttle_max_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	throttle_max_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	throttle_max_label.add_theme_color_override("font_color", Color(0.58, 0.82, 0.90, 0.62))
	throttle_root.add_child(throttle_max_label)


func atualizar_throttle_por_posicao(_posicao_tela: Vector2) -> void:
	# Mantida apenas por compatibilidade com versoes anteriores.
	# A v4.8 nao usa arrasto: o pedal funciona por pressionar/segurar.
	return


func atualizar_pedal(delta: float) -> void:
	if pedal_pressionado:
		velocidade_selecionada = move_toward(
			velocidade_selecionada,
			velocidade_maxima_nave,
			aceleracao_pedal * delta
		)
	else:
		velocidade_selecionada = move_toward(
			velocidade_selecionada,
			0.0,
			desaceleracao_pedal * delta
		)

	velocidade_selecionada = clampf(
		velocidade_selecionada,
		0.0,
		velocidade_maxima_nave
	)


func atualizar_velocidade_efetiva() -> void:
	velocidade_selecionada = clampf(velocidade_selecionada, 0.0, velocidade_maxima_nave)

	# TURBO continua sendo um atalho para velocidade maxima enquanto pressionado.
	var turbo_ativo: bool = (
		int(contagem_acoes.get(ACAO_TURBO, 0)) > 0
		or Input.is_key_pressed(KEY_SHIFT)
	)

	velocidade_efetiva = (
		velocidade_maxima_nave if turbo_ativo
		else velocidade_selecionada
	)


func atualizar_interface_throttle() -> void:
	if throttle_root == null or throttle_base == null:
		return

	var pct: float = 0.0
	if velocidade_maxima_nave > 0.001:
		pct = clampf(velocidade_selecionada / velocidade_maxima_nave, 0.0, 1.0)

	# O pedal nao tem mais cursor/slider. A placa inteira acende conforme a velocidade.
	var inset_x: float = throttle_base.size.x * 0.13
	var inset_y: float = throttle_base.size.y * 0.10
	throttle_fill.position = Vector2(inset_x, inset_y)
	throttle_fill.size = Vector2(
		throttle_base.size.x - inset_x * 2.0,
		throttle_base.size.y - inset_y * 2.0
	)
	throttle_fill.color = Color(0.04, 0.78, 1.0, 0.05 + pct * 0.18)

	# A placa do pedal afunda levemente quando pressionada.
	var deslocamento_press: float = 6.0 if pedal_pressionado else 0.0
	throttle_knob.position = Vector2(
		throttle_base.size.x * 0.10,
		throttle_base.size.y * 0.16 + deslocamento_press
	)
	throttle_knob.size = Vector2(
		throttle_base.size.x * 0.80,
		throttle_base.size.y * 0.68
	)

	var pedal_style := StyleBoxFlat.new()
	pedal_style.bg_color = (
		Color(0.10, 0.82, 1.0, 0.42) if pedal_pressionado
		else Color(0.08, 0.52, 0.66, 0.20)
	)
	pedal_style.border_color = (
		Color(0.78, 0.98, 1.0, 0.72) if pedal_pressionado
		else Color(0.48, 0.82, 0.92, 0.36)
	)
	pedal_style.border_width_left = 1
	pedal_style.border_width_top = 1
	pedal_style.border_width_right = 1
	pedal_style.border_width_bottom = 1
	pedal_style.corner_radius_top_left = 10
	pedal_style.corner_radius_top_right = 10
	pedal_style.corner_radius_bottom_left = 16
	pedal_style.corner_radius_bottom_right = 16
	throttle_knob.add_theme_stylebox_override("panel", pedal_style)

	if throttle_value != null:
		throttle_value.text = "%03d" % int(round(velocidade_efetiva))
	if throttle_max_label != null:
		throttle_max_label.text = "SEGURE PARA ACELERAR"


func localizar_player_e_propriedade_velocidade() -> void:
	var cena: Node = get_tree().current_scene
	if cena == null:
		return

	var candidato: Node = cena.get_node_or_null("Player")
	if candidato == null:
		candidato = cena.find_child("Player", true, false)

	if candidato is Node3D:
		player_nave = candidato as Node3D
		ultima_posicao_corrigida = player_nave.global_position
		fallback_velocidade_inicializado = true
	else:
		player_nave = null
		camera_nave = null
		return

	camera_nave = player_nave.get_node_or_null("Camera3D") as Camera3D
	if camera_nave == null:
		var camera_encontrada: Node = cena.find_child("Camera3D", true, false)
		if camera_encontrada is Camera3D:
			camera_nave = camera_encontrada as Camera3D

	# v4.5: velocidade real por deslocamento.
	# Nao usamos mais uma propriedade generica "speed",
	# porque ela pode existir sem controlar o movimento real.
	propriedade_velocidade_player = &""
	controle_velocidade_direto = false
	print("PEDAL v5.0: SPAWN SYNC + START LOCK ativos.")


func set_modo_a_pe(ativo: bool) -> void:
	modo_a_pe = ativo

	if ativo:
		liberar_todos_controles()
		pedal_pressionado = false
		velocidade_selecionada = 0.0
		velocidade_efetiva = 0.0
		atualizar_interface_throttle()
		manter_nave_parada_se_sem_propulsao()

	if raiz != null:
		raiz.visible = controles_ativos and !modo_a_pe

	print(
		"MOBILE CONTROLS v5.1: ",
		"MODO A PE" if modo_a_pe else "MODO NAVE"
	)


func is_modo_a_pe() -> bool:
	return modo_a_pe


func sincronizar_spawn_hangar(
	nova_posicao: Vector3,
	nova_rotacao: Vector3
) -> void:
	# Chamado pelo HangarBase depois de colocar a P-01 no P01Spawn.
	# Atualiza a referencia do START LOCK para que a nave nao volte
	# para a posicao antiga no frame seguinte.
	if player_nave == null or !is_instance_valid(player_nave):
		localizar_player_e_propriedade_velocidade()

	if player_nave == null or !is_instance_valid(player_nave):
		return

	player_nave.global_position = nova_posicao
	player_nave.global_rotation = nova_rotacao

	ultima_posicao_corrigida = nova_posicao
	fallback_velocidade_inicializado = true

	velocidade_selecionada = 0.0
	velocidade_efetiva = 0.0
	pedal_pressionado = false

	atualizar_interface_throttle()

	print("MOBILE CONTROLS v5.0: spawn do hangar sincronizado em ", nova_posicao)


func aplicar_velocidade_na_nave(delta: float) -> void:
	if get_tree().paused:
		return
	if player_nave == null or !is_instance_valid(player_nave):
		return
	if delta <= 0.00001:
		return

	if !fallback_velocidade_inicializado:
		ultima_posicao_corrigida = player_nave.global_position
		fallback_velocidade_inicializado = true
		return

	var pos_atual: Vector3 = player_nave.global_position
	var deslocamento: Vector3 = pos_atual - ultima_posicao_corrigida

	# Teleportes/respawns grandes continuam permitidos.
	if deslocamento.length() > 80.0:
		ultima_posicao_corrigida = pos_atual
		return

	# v4.9: se o pedal esta em zero, anulamos COMPLETAMENTE qualquer
	# movimento automatico do controlador antigo da nave.
	# Antes o script preservava parte desse deslocamento e a P-01
	# acabava saindo do hangar sozinha mesmo mostrando 000 no pedal.
	if velocidade_efetiva <= 0.05:
		player_nave.global_position = ultima_posicao_corrigida
		return

	var frente: Vector3
	if camera_nave != null and is_instance_valid(camera_nave):
		frente = -camera_nave.global_transform.basis.z.normalized()
	else:
		frente = -player_nave.global_transform.basis.z.normalized()

	var componente_frontal: float = deslocamento.dot(frente)
	var deslocamento_lateral: Vector3 = deslocamento - frente * componente_frontal

	var desejado_frontal: float = velocidade_efetiva * delta
	var movimento_desejado: Vector3 = deslocamento_lateral + frente * desejado_frontal

	if colisao_fisica_ativa and forma_colisao_p01 != null and movimento_desejado.length() > 0.0001:
		forma_colisao_p01.radius = raio_colisao_p01
		var mundo: World3D = player_nave.get_world_3d()
		if mundo != null:
			var query := PhysicsShapeQueryParameters3D.new()
			query.shape = forma_colisao_p01
			query.transform = Transform3D(Basis.IDENTITY, ultima_posicao_corrigida)
			query.motion = movimento_desejado
			query.collision_mask = mascara_colisao_voo
			query.collide_with_bodies = true
			query.collide_with_areas = false

			var exclusoes: Array[RID] = []
			if player_nave is CollisionObject3D:
				exclusoes.append((player_nave as CollisionObject3D).get_rid())
			query.exclude = exclusoes

			var resultado: PackedFloat32Array = mundo.direct_space_state.cast_motion(query)
			if resultado.size() >= 1:
				var fracao_segura: float = clampf(resultado[0], 0.0, 1.0)
				if fracao_segura < 1.0:
					movimento_desejado *= maxf(fracao_segura - 0.02, 0.0)

	var pos_corrigida: Vector3 = ultima_posicao_corrigida + movimento_desejado
	player_nave.global_position = pos_corrigida
	ultima_posicao_corrigida = pos_corrigida


func manter_nave_parada_se_sem_propulsao() -> void:
	if player_nave == null or !is_instance_valid(player_nave):
		return
	if !fallback_velocidade_inicializado:
		return
	if velocidade_efetiva > 0.05:
		return

	# Esta segunda trava roda no _process para pegar controladores antigos
	# que movam a nave fora do _physics_process.
	var deslocamento: Vector3 = player_nave.global_position - ultima_posicao_corrigida

	# Se outro sistema realmente teleportar a nave, aceitamos o novo ponto.
	if deslocamento.length() > 80.0:
		ultima_posicao_corrigida = player_nave.global_position
		return

	player_nave.global_position = ultima_posicao_corrigida


func carregar_velocidade_nave() -> void:
	# v4.9: a P-01 SEMPRE nasce completamente parada.
	# Ignora qualquer velocidade antiga/salva para impedir auto-saida do hangar.
	velocidade_selecionada = 0.0
	velocidade_efetiva = 0.0
	pedal_pressionado = false


func salvar_velocidade_nave() -> void:
	var config := ConfigFile.new()
	config.load(CONFIG_PATH)
	config.set_value("controls", "ship_speed", velocidade_selecionada)
	config.save(CONFIG_PATH)


# =========================================================
# LAYOUT
# =========================================================

func atualizar_layout() -> void:
	if raiz == null:
		return

	var tela: Vector2 = get_viewport().get_visible_rect().size
	ultimo_tamanho_tela = tela

	raiz.position = Vector2.ZERO
	raiz.size = tela

	var escala: float = clampf(minf(tela.x / 1280.0, tela.y / 720.0), 0.72, 1.35)
	var margem: float = 22.0 * escala
	var gap: float = 12.0 * escala

	dica_pilotagem.position = Vector2(margem, tela.y - 50.0 * escala)
	dica_pilotagem.size = Vector2(360.0 * escala, 28.0 * escala)
	dica_pilotagem.add_theme_font_size_override("font_size", int(11.0 * escala))

	# Barra superior visivel do giroflex (opcao 3).
	if giro_bar_base != null:
		giro_bar_base.position = Vector2(tela.x * 0.34, tela.y * 0.055)
		giro_bar_base.size = Vector2(tela.x * 0.32, 26.0 * escala)
		var base_style := StyleBoxFlat.new()
		base_style.bg_color = Color(0.03, 0.05, 0.08, 0.65)
		base_style.border_color = Color(0.32, 0.85, 1.0, 0.55)
		base_style.border_width_left = 1
		base_style.border_width_top = 1
		base_style.border_width_right = 1
		base_style.border_width_bottom = 1
		base_style.corner_radius_top_left = 4
		base_style.corner_radius_top_right = 4
		base_style.corner_radius_bottom_left = 4
		base_style.corner_radius_bottom_right = 4
		giro_bar_base.add_theme_stylebox_override("panel", base_style)

		var margem_barra: float = giro_bar_base.size.x * 0.06
		var metade: float = (giro_bar_base.size.x - margem_barra * 3.0) * 0.5
		giro_bar_red_glow.position = Vector2(margem_barra - 10.0 * escala, 2.0 * escala)
		giro_bar_red_glow.size = Vector2(metade + 20.0 * escala, giro_bar_base.size.y - 4.0 * escala)
		giro_bar_blue_glow.position = Vector2(margem_barra * 2.0 + metade - 10.0 * escala, 2.0 * escala)
		giro_bar_blue_glow.size = Vector2(metade + 20.0 * escala, giro_bar_base.size.y - 4.0 * escala)
		giro_bar_red.position = Vector2(margem_barra, 6.0 * escala)
		giro_bar_red.size = Vector2(metade, giro_bar_base.size.y - 12.0 * escala)
		giro_bar_blue.position = Vector2(margem_barra * 2.0 + metade, 6.0 * escala)
		giro_bar_blue.size = Vector2(metade, giro_bar_base.size.y - 12.0 * escala)

	# Reflexos do giroflex no canopy.
	reflexo_topo.position = Vector2(tela.x * 0.36, tela.y * 0.07)
	reflexo_topo.size = Vector2(tela.x * 0.28, 9.0 * escala)
	reflexo_esquerda.position = Vector2(tela.x * 0.18, tela.y * 0.17)
	reflexo_esquerda.size = Vector2(10.0 * escala, tela.y * 0.34)
	reflexo_direita.position = Vector2(tela.x * 0.72, tela.y * 0.17)
	reflexo_direita.size = Vector2(10.0 * escala, tela.y * 0.34)

	var pequeno := Vector2(102.0, 58.0) * escala
	var medio := Vector2(116.0, 72.0) * escala
	var grande := Vector2(132.0, 94.0) * escala

	botao_atirar.position = Vector2(tela.x - margem - grande.x, tela.y - margem - grande.y)
	botao_atirar.size = grande

	botao_turbo.position = Vector2(botao_atirar.position.x - gap - medio.x, botao_atirar.position.y + (grande.y - medio.y))
	botao_turbo.size = medio

	botao_sirene.position = Vector2(botao_atirar.position.x + (grande.x - pequeno.x) * 0.5, botao_atirar.position.y - gap - pequeno.y)
	botao_sirene.size = pequeno

	botao_giro.position = Vector2(botao_turbo.position.x + (medio.x - pequeno.x) * 0.5, botao_turbo.position.y - gap - pequeno.y)
	botao_giro.size = pequeno

	botao_ordem.position = Vector2(botao_sirene.position.x, botao_sirene.position.y - gap - pequeno.y)
	botao_ordem.size = pequeno

	botao_scan.position = Vector2(botao_giro.position.x, botao_giro.position.y - gap - pequeno.y)
	botao_scan.size = pequeno

	# Propulsao em formato de pedal no canto inferior esquerdo.
	if throttle_root != null:
		var throttle_w: float = 136.0 * escala
		var throttle_h: float = 168.0 * escala
		var throttle_x: float = margem * 0.55
		var throttle_y: float = tela.y - margem - throttle_h
		throttle_root.position = Vector2(throttle_x, throttle_y)
		throttle_root.size = Vector2(throttle_w, throttle_h)

		throttle_label.position = Vector2(0.0, 4.0 * escala)
		throttle_label.size = Vector2(throttle_w, 16.0 * escala)
		throttle_label.add_theme_font_size_override("font_size", int(8.0 * escala))

		throttle_base.position = Vector2(35.0 * escala, 22.0 * escala)
		throttle_base.size = Vector2(56.0 * escala, 108.0 * escala)
		throttle_base.rotation_degrees = -10.0

		throttle_value.position = Vector2(0.0, 128.0 * escala)
		throttle_value.size = Vector2(throttle_w, 22.0 * escala)
		throttle_value.add_theme_font_size_override("font_size", int(16.0 * escala))

		throttle_max_label.position = Vector2(0.0, 146.0 * escala)
		throttle_max_label.size = Vector2(throttle_w, 14.0 * escala)
		throttle_max_label.add_theme_font_size_override("font_size", int(6.5 * escala))

		throttle_rect = Rect2(throttle_root.position, throttle_root.size)
		atualizar_interface_throttle()

	configurar_layout_botao(botao_scan, 11.5 * escala, 9.0 * escala)
	configurar_layout_botao(botao_ordem, 10.8 * escala, 8.6 * escala)
	configurar_layout_botao(botao_giro, 11.2 * escala, 9.2 * escala)
	configurar_layout_botao(botao_sirene, 10.6 * escala, 9.0 * escala)
	configurar_layout_botao(botao_turbo, 13.0 * escala, 10.2 * escala)
	configurar_layout_botao(botao_atirar, 17.0 * escala, 11.5 * escala)

	retangulos_botoes[ACAO_SCAN] = Rect2(botao_scan.position, botao_scan.size)
	retangulos_botoes[ACAO_ORDEM] = Rect2(botao_ordem.position, botao_ordem.size)
	retangulos_botoes[ACAO_GIRO] = Rect2(botao_giro.position, botao_giro.size)
	retangulos_botoes[ACAO_SIRENE] = Rect2(botao_sirene.position, botao_sirene.size)
	retangulos_botoes[ACAO_TURBO] = Rect2(botao_turbo.position, botao_turbo.size)
	retangulos_botoes[ACAO_ATIRAR] = Rect2(botao_atirar.position, botao_atirar.size)

	atualizar_status_toggles()


func configurar_layout_botao(botao: Control, fonte_titulo: float, fonte_estado: float) -> void:
	if botao == null:
		return

	var base: Panel = botao.get_node_or_null("Base") as Panel
	var brilho: ColorRect = botao.get_node_or_null("Base/Brilho") as ColorRect
	var topo: ColorRect = botao.get_node_or_null("Base/FaixaTopo") as ColorRect
	var fundo: ColorRect = botao.get_node_or_null("Base/FaixaBase") as ColorRect
	var titulo: Label = botao.get_node_or_null("Base/Titulo") as Label
	var estado: Label = botao.get_node_or_null("Base/Estado") as Label

	base.position = Vector2.ZERO
	base.size = botao.size
	if brilho != null:
		brilho.position = Vector2(botao.size.x * 0.07, botao.size.y * 0.22)
		brilho.size = Vector2(botao.size.x * 0.86, botao.size.y * 0.16)
	if topo != null:
		topo.position = Vector2(botao.size.x * 0.08, botao.size.y * 0.10)
		topo.size = Vector2(botao.size.x * 0.84, maxf(3.0, botao.size.y * 0.06))
	if fundo != null:
		fundo.position = Vector2(botao.size.x * 0.20, botao.size.y * 0.83)
		fundo.size = Vector2(botao.size.x * 0.60, maxf(2.0, botao.size.y * 0.04))

	if titulo != null:
		titulo.position = Vector2(botao.size.x * 0.08, botao.size.y * 0.20)
		titulo.size = Vector2(botao.size.x * 0.84, botao.size.y * 0.34)
		titulo.add_theme_font_size_override("font_size", int(fonte_titulo))
	if estado != null:
		estado.position = Vector2(botao.size.x * 0.08, botao.size.y * 0.54)
		estado.size = Vector2(botao.size.x * 0.84, botao.size.y * 0.20)
		estado.add_theme_font_size_override("font_size", int(fonte_estado))


# =========================================================
# VISUAL DOS BOTOES
# =========================================================

func aplicar_visual_botao(acao: String, pressionado: bool) -> void:
	if !botoes_visuais.has(acao):
		return

	var root: Control = botoes_visuais[acao] as Control
	if root == null:
		return

	var base: Panel = root.get_node_or_null("Base") as Panel
	var brilho: ColorRect = root.get_node_or_null("Base/Brilho") as ColorRect
	var topo: ColorRect = root.get_node_or_null("Base/FaixaTopo") as ColorRect
	var fundo: ColorRect = root.get_node_or_null("Base/FaixaBase") as ColorRect
	var titulo: Label = root.get_node_or_null("Base/Titulo") as Label
	var estado: Label = root.get_node_or_null("Base/Estado") as Label

	var cor: Color = botoes_cores.get(acao, Color(0.7, 0.8, 1.0, 1.0))
	var ativo_toggle: bool = bool(estado_toggles.get(acao, false))
	var opacidade_fundo: float = opacidade_controles * 0.55
	var opacidade_borda: float = 0.85
	var brilho_alpha: float = 0.10

	if ativo_toggle:
		opacidade_fundo += 0.16
		opacidade_borda = 1.0
		brilho_alpha = 0.18

	if pressionado:
		opacidade_fundo += 0.14
		opacidade_borda = 1.0
		brilho_alpha = 0.25

	var estilo: StyleBoxFlat = StyleBoxFlat.new()
	estilo.bg_color = Color(0.02, 0.05, 0.08, opacidade_fundo)
	estilo.border_color = Color(cor.r, cor.g, cor.b, opacidade_borda)
	estilo.border_width_left = 2
	estilo.border_width_top = 2
	estilo.border_width_right = 2
	estilo.border_width_bottom = 2
	estilo.corner_radius_top_left = 6
	estilo.corner_radius_top_right = 18
	estilo.corner_radius_bottom_left = 18
	estilo.corner_radius_bottom_right = 6
	base.add_theme_stylebox_override("panel", estilo)

	if brilho != null:
		brilho.color = Color(cor.r, cor.g, cor.b, brilho_alpha)
	if topo != null:
		topo.color = Color(cor.r, cor.g, cor.b, 0.92)
	if fundo != null:
		fundo.color = Color(cor.r, cor.g, cor.b, 0.75)
	if titulo != null:
		titulo.add_theme_color_override("font_color", Color(0.93, 0.98, 1.0, 0.98))
	if estado != null:
		if eh_acao_toggle(acao):
			if ativo_toggle:
				estado.add_theme_color_override("font_color", Color(cor.r, cor.g, cor.b, 0.98))
			else:
				estado.add_theme_color_override("font_color", Color(0.70, 0.82, 0.90, 0.88))
		else:
			estado.add_theme_color_override("font_color", Color(cor.r, cor.g, cor.b, 0.92))


# =========================================================
# PROMPTS MOBILE
# =========================================================

func localizar_sistemas_contexto() -> void:
	var cena: Node = get_tree().current_scene
	if cena == null:
		return

	if scanner_contexto == null or !is_instance_valid(scanner_contexto):
		scanner_contexto = cena.find_child("SuspectTargetHUD", true, false)

	if cockpit_contexto == null or !is_instance_valid(cockpit_contexto):
		cockpit_contexto = encontrar_controlador_cockpit(cena)


func encontrar_controlador_cockpit(no_atual: Node) -> Node:
	if no_atual == null:
		return null

	var script: Variant = no_atual.get_script()
	if script is Script:
		var caminho: String = (script as Script).resource_path.to_lower()
		if caminho.contains("cockpit_fx"):
			return no_atual

	for filho: Node in no_atual.get_children():
		var encontrado: Node = encontrar_controlador_cockpit(filho)
		if encontrado != null:
			return encontrado

	return null


func adaptar_prompts_para_touch() -> void:
	if !controles_ativos:
		return

	if cockpit_contexto != null and is_instance_valid(cockpit_contexto):
		var label_objetivo_variant: Variant = cockpit_contexto.get("label_objetivo")
		if label_objetivo_variant is Label:
			var label_objetivo: Label = label_objetivo_variant as Label
			var texto_objetivo: String = label_objetivo.text

			if texto_objetivo.contains("PRESSIONE F"):
				label_objetivo.text = "OBJETIVO: USE O BOTAO ORDEM"
			elif texto_objetivo.contains("[E]") or texto_objetivo.contains("PRESSIONE E"):
				label_objetivo.text = "OBJETIVO: USE O BOTAO SCAN"

	if scanner_contexto != null and is_instance_valid(scanner_contexto):
		adaptar_labels_scanner(scanner_contexto)


func adaptar_labels_scanner(no_atual: Node) -> void:
	if no_atual is Label:
		var label: Label = no_atual as Label
		var texto: String = label.text
		if texto.contains("PRESSIONE E") or texto.contains("[E]"):
			label.text = "USE SCAN PARA VERIFICAR"
		elif texto.contains("PRESSIONE F") or texto.contains("[F]"):
			label.text = "USE ORDEM PARA MANDAR PARAR"

	for filho: Node in no_atual.get_children():
		adaptar_labels_scanner(filho)


# =========================================================
# CONFIG
# =========================================================

func definir_sensibilidade(valor: float) -> void:
	sensibilidade_touch = clampf(valor, 0.50, 2.00)


func carregar_sensibilidade() -> void:
	var config: ConfigFile = ConfigFile.new()
	if config.load(CONFIG_PATH) != OK:
		return

	definir_sensibilidade(float(config.get_value("controls", "touch_sensitivity", sensibilidade_touch)))


func carregar_visibilidade_pc() -> void:
	if eh_mobile:
		return

	var config: ConfigFile = ConfigFile.new()
	if config.load(CONFIG_PATH) != OK:
		return

	mostrar_no_pc_para_teste = bool(config.get_value("interface", "mobile_controls_pc", mostrar_no_pc_para_teste))


# =========================================================
# LIBERAR TUDO
# =========================================================

func liberar_todos_controles() -> void:
	resetar_pilotagem()

	for acao: String in contagem_acoes.keys():
		contagem_acoes[acao] = 0
		enviar_tecla(pegar_tecla_acao(acao), false)
		aplicar_visual_botao(acao, false)

	toques_botoes.clear()
	toque_pilotagem = -1
	mouse_pilotagem_ativo = false
	throttle_touch_id = -9999
	throttle_mouse_ativo = false
	pedal_pressionado = false
	parar_sirene()
	estado_toggles[ACAO_GIRO] = false
	estado_toggles[ACAO_SIRENE] = false
	limpar_reflexos_giroflex()
	atualizar_status_toggles()


func _exit_tree() -> void:
	liberar_todos_controles()
