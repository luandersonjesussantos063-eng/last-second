extends CanvasLayer


# =========================================================
# LAST SECOND
# MENU PRINCIPAL v3.1
#
# MENU CINEMATOGRAFICO / SCI-FI
#
# - Fundo espacial animado
# - Planeta gigante ao fundo
# - Nave P-01 estilizada
# - Painel de status da central
# - Painel de missao
# - Botoes neon
# - Como jogar
# - Nao interfere nos HUDs do jogo
# - Apenas pausa o jogo enquanto o menu esta aberto
# - Musica ambiente sci-fi procedural
# - Menu CONFIGURACOES com volumes / sensibilidade / tela cheia / controles mobile no PC
# - Configuracoes salvas em user://last_second_settings.cfg
# =========================================================


@export var versao_jogo: String = "ALPHA 0.3"
@export var unidade_jogador: String = "P-01"
@export var agencia: String = "POLICIA INTERPLANETARIA"


var raiz: Control = null
var fundo: ColorRect = null

var estrelas: Array[ColorRect] = []
var estrelas_velocidade: Array[float] = []

var planeta: Panel = null
var planeta_brillo: Panel = null

var scan_line: ColorRect = null
var scan_tempo: float = 0.0

var ship_root: Control = null
var ship_body: Polygon2D = null
var ship_cockpit: Polygon2D = null
var ship_left: Polygon2D = null
var ship_right: Polygon2D = null
var ship_engine_l: ColorRect = null
var ship_engine_r: ColorRect = null

var titulo: Label = null
var subtitulo: Label = null
var badge: Label = null

var painel_esquerdo: Panel = null
var painel_direito: Panel = null
var painel_central: Panel = null

var label_status: Label = null
var label_setor: Label = null
var label_unidade: Label = null
var label_sistema: Label = null
var label_operacao: Label = null

var botao_iniciar: Button = null
var botao_como: Button = null
var botao_config: Button = null
var botao_sair: Button = null

var rodape_esq: Label = null
var rodape_dir: Label = null

var painel_ajuda: Panel = null
var titulo_ajuda: Label = null
var texto_ajuda: Label = null
var botao_voltar: Button = null

var painel_config: Panel = null
var titulo_config: Label = null
var label_master: Label = null
var slider_master: HSlider = null
var valor_master: Label = null
var label_music: Label = null
var slider_music: HSlider = null
var valor_music: Label = null
var label_sensibilidade: Label = null
var slider_sensibilidade: HSlider = null
var valor_sensibilidade: Label = null
var botao_fullscreen: Button = null
var botao_mobile_pc: Button = null
var label_versao_config: Label = null
var botao_voltar_config: Button = null

var volume_master: float = 0.85
var volume_musica: float = 0.45
var tela_cheia_ativa: bool = false
var controles_mobile_pc: bool = false
var sensibilidade_touch: float = 1.00

var music_player: AudioStreamPlayer = null
var music_stream: AudioStreamGenerator = null
var music_playback: AudioStreamGeneratorPlayback = null
var music_sample_index: int = 0
var music_mix_rate: float = 44100.0

const CONFIG_PATH: String = "user://last_second_settings.cfg"

var pulso: float = 0.0
var ultimo_tamanho_tela: Vector2 = Vector2.ZERO

var rng: RandomNumberGenerator = RandomNumberGenerator.new()


# =========================================================
# READY
# =========================================================

func _ready() -> void:

	layer = 500
	process_mode = Node.PROCESS_MODE_ALWAYS

	rng.randomize()

	carregar_configuracoes()

	criar_interface()

	aplicar_configuracoes()

	iniciar_musica()

	get_tree().paused = true

	await get_tree().process_frame

	atualizar_layout()


# =========================================================
# PROCESS
# =========================================================

func _process(delta: float) -> void:

	var tela: Vector2 = (
		get_viewport().get_visible_rect().size
	)


	if tela != ultimo_tamanho_tela:
		atualizar_layout()


	animar_estrelas(delta)
	animar_scan(delta)
	animar_pulso(delta)
	animar_nave(delta)
	processar_musica()


# =========================================================
# INTERFACE
# =========================================================

func criar_interface() -> void:

	raiz = Control.new()
	raiz.name = "MenuRoot"
	raiz.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(raiz)


	fundo = ColorRect.new()
	fundo.name = "Background"
	fundo.color = Color(
		0.004,
		0.010,
		0.026,
		1.0
	)
	fundo.mouse_filter = Control.MOUSE_FILTER_STOP
	raiz.add_child(fundo)


	criar_estrelas()
	criar_planeta()
	criar_scan_line()
	criar_nave_decorativa()

	criar_titulos()
	criar_painel_esquerdo()
	criar_painel_central()
	criar_painel_direito()
	criar_rodape()
	criar_painel_ajuda()
	criar_painel_configuracoes()


# =========================================================
# ESTRELAS
# =========================================================

func criar_estrelas() -> void:

	for i: int in range(95):

		var estrela: ColorRect = ColorRect.new()

		estrela.mouse_filter = Control.MOUSE_FILTER_IGNORE

		var brilho: float = rng.randf_range(
			0.32,
			1.0
		)

		estrela.color = Color(
			brilho * 0.72,
			brilho * 0.86,
			brilho,
			rng.randf_range(
				0.30,
				0.95
			)
		)

		fundo.add_child(estrela)

		estrelas.append(estrela)

		estrelas_velocidade.append(
			rng.randf_range(
				2.0,
				10.0
			)
		)


# =========================================================
# PLANETA
# =========================================================

func criar_planeta() -> void:

	planeta_brillo = Panel.new()
	planeta_brillo.mouse_filter = Control.MOUSE_FILTER_IGNORE
	planeta_brillo.add_theme_stylebox_override(
		"panel",
		criar_circulo(
			Color(
				0.02,
				0.20,
				0.36,
				0.18
			),
			Color(
				0.04,
				0.44,
				0.80,
				0.10
			),
			4
		)
	)
	fundo.add_child(planeta_brillo)


	planeta = Panel.new()
	planeta.mouse_filter = Control.MOUSE_FILTER_IGNORE
	planeta.add_theme_stylebox_override(
		"panel",
		criar_circulo(
			Color(
				0.015,
				0.065,
				0.12,
				1.0
			),
			Color(
				0.05,
				0.52,
				0.95,
				0.55
			),
			3
		)
	)
	fundo.add_child(planeta)


	for i: int in range(8):

		var faixa: ColorRect = ColorRect.new()

		faixa.color = Color(
			0.04,
			0.26,
			0.44,
			0.12 + float(i % 3) * 0.04
		)

		faixa.mouse_filter = Control.MOUSE_FILTER_IGNORE

		planeta.add_child(faixa)

		faixa.position = Vector2(
			70.0 + i * 24.0,
			45.0 + i * 42.0
		)

		faixa.size = Vector2(
			260.0,
			5.0 + float(i % 2) * 7.0
		)

		faixa.rotation = deg_to_rad(
			-12.0 + float(i) * 2.5
		)


# =========================================================
# SCAN LINE
# =========================================================

func criar_scan_line() -> void:

	scan_line = ColorRect.new()

	scan_line.color = Color(
		0.15,
		0.72,
		1.0,
		0.10
	)

	scan_line.mouse_filter = Control.MOUSE_FILTER_IGNORE

	fundo.add_child(scan_line)


# =========================================================
# NAVE DECORATIVA
# =========================================================

func criar_nave_decorativa() -> void:

	ship_root = Control.new()

	ship_root.mouse_filter = Control.MOUSE_FILTER_IGNORE

	fundo.add_child(ship_root)


	ship_body = Polygon2D.new()

	ship_body.polygon = PackedVector2Array([
		Vector2(0.0, -95.0),
		Vector2(28.0, -20.0),
		Vector2(22.0, 78.0),
		Vector2(0.0, 105.0),
		Vector2(-22.0, 78.0),
		Vector2(-28.0, -20.0)
	])

	ship_body.color = Color(
		0.12,
		0.18,
		0.26,
		0.95
	)

	ship_root.add_child(ship_body)


	ship_cockpit = Polygon2D.new()

	ship_cockpit.polygon = PackedVector2Array([
		Vector2(0.0, -65.0),
		Vector2(15.0, -25.0),
		Vector2(9.0, 5.0),
		Vector2(-9.0, 5.0),
		Vector2(-15.0, -25.0)
	])

	ship_cockpit.color = Color(
		0.06,
		0.68,
		1.0,
		0.92
	)

	ship_root.add_child(ship_cockpit)


	ship_left = Polygon2D.new()

	ship_left.polygon = PackedVector2Array([
		Vector2(-22.0, 5.0),
		Vector2(-108.0, 56.0),
		Vector2(-98.0, 78.0),
		Vector2(-18.0, 48.0)
	])

	ship_left.color = Color(
		0.08,
		0.12,
		0.18,
		0.95
	)

	ship_root.add_child(ship_left)


	ship_right = Polygon2D.new()

	ship_right.polygon = PackedVector2Array([
		Vector2(22.0, 5.0),
		Vector2(108.0, 56.0),
		Vector2(98.0, 78.0),
		Vector2(18.0, 48.0)
	])

	ship_right.color = Color(
		0.08,
		0.12,
		0.18,
		0.95
	)

	ship_root.add_child(ship_right)


	ship_engine_l = ColorRect.new()
	ship_engine_l.color = Color(
		0.05,
		0.60,
		1.0,
		0.90
	)
	ship_engine_l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ship_root.add_child(ship_engine_l)


	ship_engine_r = ColorRect.new()
	ship_engine_r.color = Color(
		0.05,
		0.60,
		1.0,
		0.90
	)
	ship_engine_r.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ship_root.add_child(ship_engine_r)


# =========================================================
# TITULOS
# =========================================================

func criar_titulos() -> void:

	badge = Label.new()

	badge.text = "INTERPLANETARY ENFORCEMENT DIVISION"

	badge.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER

	badge.add_theme_color_override(
		"font_color",
		Color(
			0.25,
			0.72,
			0.95,
			0.80
		)
	)

	raiz.add_child(badge)


	titulo = Label.new()

	titulo.text = "LAST SECOND"

	titulo.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER

	titulo.add_theme_color_override(
		"font_color",
		Color(
			0.88,
			0.97,
			1.0
		)
	)

	titulo.add_theme_color_override(
		"font_outline_color",
		Color(
			0.0,
			0.15,
			0.28,
			0.95
		)
	)

	titulo.add_theme_constant_override(
		"outline_size",
		12
	)

	raiz.add_child(titulo)


	subtitulo = Label.new()

	subtitulo.text = agencia

	subtitulo.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER

	subtitulo.add_theme_color_override(
		"font_color",
		Color(
			0.10,
			0.66,
			1.0
		)
	)

	raiz.add_child(subtitulo)


# =========================================================
# PAINEL ESQUERDO
# =========================================================

func criar_painel_esquerdo() -> void:

	painel_esquerdo = Panel.new()

	painel_esquerdo.add_theme_stylebox_override(
		"panel",
		criar_painel_estilo(
			Color(
				0.01,
				0.04,
				0.075,
				0.88
			)
		)
	)

	raiz.add_child(painel_esquerdo)


	var titulo_painel: Label = Label.new()

	titulo_painel.text = "CENTRAL DE OPERACOES"

	titulo_painel.add_theme_color_override(
		"font_color",
		Color(
			0.40,
			0.84,
			1.0
		)
	)

	painel_esquerdo.add_child(titulo_painel)


	label_status = Label.new()

	label_status.text = "● ONLINE"

	label_status.add_theme_color_override(
		"font_color",
		Color(
			0.22,
			1.0,
			0.52
		)
	)

	painel_esquerdo.add_child(label_status)


	label_setor = Label.new()
	label_setor.text = "SETOR\nSISTEMA SOLAR"
	painel_esquerdo.add_child(label_setor)


	label_unidade = Label.new()
	label_unidade.text = "UNIDADE\n" + unidade_jogador
	painel_esquerdo.add_child(label_unidade)


	label_sistema = Label.new()
	label_sistema.text = "SISTEMAS\nTODOS NOMINAIS"
	painel_esquerdo.add_child(label_sistema)


	for label: Label in [
		label_setor,
		label_unidade,
		label_sistema
	]:

		label.add_theme_color_override(
			"font_color",
			Color(
				0.70,
				0.82,
				0.90
			)
		)


# =========================================================
# PAINEL CENTRAL
# =========================================================

func criar_painel_central() -> void:

	painel_central = Panel.new()

	painel_central.add_theme_stylebox_override(
		"panel",
		criar_painel_estilo(
			Color(
				0.005,
				0.025,
				0.05,
				0.72
			)
		)
	)

	raiz.add_child(painel_central)


	var titulo_operacao: Label = Label.new()

	titulo_operacao.text = "STATUS OPERACIONAL"

	titulo_operacao.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER

	titulo_operacao.add_theme_color_override(
		"font_color",
		Color(
			0.22,
			0.75,
			1.0
		)
	)

	painel_central.add_child(titulo_operacao)


	label_operacao = Label.new()

	label_operacao.text = (
		"PATRULHA ORBITAL DISPONIVEL\n\n"
		+
		"AGUARDANDO AUTORIZACAO DO PILOTO\n\n"
		+
		"PROTOCOLO LS-P01"
	)

	label_operacao.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER

	label_operacao.vertical_alignment = VERTICAL_ALIGNMENT_CENTER

	label_operacao.add_theme_color_override(
		"font_color",
		Color(
			0.72,
			0.88,
			0.96
		)
	)

	painel_central.add_child(label_operacao)


# =========================================================
# PAINEL DIREITO
# =========================================================

func criar_painel_direito() -> void:

	painel_direito = Panel.new()

	painel_direito.add_theme_stylebox_override(
		"panel",
		criar_painel_estilo(
			Color(
				0.01,
				0.04,
				0.075,
				0.90
			)
		)
	)

	raiz.add_child(painel_direito)


	var titulo_menu: Label = Label.new()

	titulo_menu.text = "TERMINAL P-01"

	titulo_menu.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER

	titulo_menu.add_theme_color_override(
		"font_color",
		Color(
			0.42,
			0.84,
			1.0
		)
	)

	painel_direito.add_child(titulo_menu)


	botao_iniciar = criar_botao(
		"INICIAR PATRULHA",
		Color(
			0.03,
			0.46,
			0.76
		)
	)

	botao_iniciar.pressed.connect(
		iniciar_jogo
	)

	painel_direito.add_child(botao_iniciar)


	botao_como = criar_botao(
		"COMO JOGAR",
		Color(
			0.05,
			0.16,
			0.26
		)
	)

	botao_como.pressed.connect(
		abrir_ajuda
	)

	painel_direito.add_child(botao_como)


	botao_config = criar_botao(
		"CONFIGURACOES",
		Color(
			0.055,
			0.20,
			0.31
		)
	)

	botao_config.pressed.connect(
		abrir_configuracoes
	)

	painel_direito.add_child(botao_config)


	botao_sair = criar_botao(
		"ENCERRAR SISTEMA",
		Color(
			0.22,
			0.045,
			0.065
		)
	)

	botao_sair.pressed.connect(
		sair_do_jogo
	)

	painel_direito.add_child(botao_sair)


	var dica: Label = Label.new()

	dica.text = (
		"AUTO-NAV ONLINE\n"
		+
		"FLIGHT CORE READY"
	)

	dica.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER

	dica.add_theme_color_override(
		"font_color",
		Color(
			0.38,
			0.60,
			0.72
		)
	)

	painel_direito.add_child(dica)


# =========================================================
# RODAPE
# =========================================================

func criar_rodape() -> void:

	rodape_esq = Label.new()

	rodape_esq.text = (
		"LS // "
		+
		versao_jogo
	)

	rodape_esq.add_theme_color_override(
		"font_color",
		Color(
			0.36,
			0.52,
			0.62,
			0.75
		)
	)

	raiz.add_child(rodape_esq)


	rodape_dir = Label.new()

	rodape_dir.text = (
		"SISTEMA SEGURO // LINK ESTAVEL"
	)

	rodape_dir.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT

	rodape_dir.add_theme_color_override(
		"font_color",
		Color(
			0.20,
			0.72,
			0.95,
			0.72
		)
	)

	raiz.add_child(rodape_dir)


# =========================================================
# AJUDA
# =========================================================

func criar_painel_ajuda() -> void:

	painel_ajuda = Panel.new()

	painel_ajuda.visible = false

	painel_ajuda.mouse_filter = Control.MOUSE_FILTER_STOP

	painel_ajuda.add_theme_stylebox_override(
		"panel",
		criar_painel_estilo(
			Color(
				0.006,
				0.028,
				0.055,
				0.98
			)
		)
	)

	raiz.add_child(painel_ajuda)


	titulo_ajuda = Label.new()

	titulo_ajuda.text = "MANUAL DE OPERACAO"

	titulo_ajuda.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER

	titulo_ajuda.add_theme_color_override(
		"font_color",
		Color(
			0.30,
			0.82,
			1.0
		)
	)

	painel_ajuda.add_child(titulo_ajuda)


	texto_ajuda = Label.new()

	texto_ajuda.text = (
		"CONTROLES DE VOO\n\n"
		+
		"PC\n"
		+
		"W A S D  //  PILOTAR\n"
		+
		"SHIFT  //  TURBO\n"
		+
		"E  //  ESCANEAR\n"
		+
		"F  //  ORDEM DE PARADA\n"
		+
		"ESPACO  //  DISPARAR QUANDO AUTORIZADO\n\n"
		+
		"CELULAR\n"
		+
		"ARRASTE NA TELA  //  PILOTAR\n"
		+
		"SCAN  //  ESCANEAR\n"
		+
		"ORDEM  //  ORDEM DE PARADA\n"
		+
		"TURBO  //  ACELERACAO\n"
		+
		"ATIRAR  //  ARMAMENTO"
	)

	texto_ajuda.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER

	texto_ajuda.vertical_alignment = VERTICAL_ALIGNMENT_CENTER

	texto_ajuda.add_theme_color_override(
		"font_color",
		Color(
			0.76,
			0.88,
			0.94
		)
	)

	painel_ajuda.add_child(texto_ajuda)


	botao_voltar = criar_botao(
		"VOLTAR AO TERMINAL",
		Color(
			0.03,
			0.34,
			0.56
		)
	)

	botao_voltar.pressed.connect(
		fechar_ajuda
	)

	painel_ajuda.add_child(botao_voltar)


# =========================================================
# CONFIGURACOES
# =========================================================

func criar_painel_configuracoes() -> void:

	painel_config = Panel.new()

	painel_config.visible = false

	painel_config.mouse_filter = Control.MOUSE_FILTER_STOP

	painel_config.add_theme_stylebox_override(
		"panel",
		criar_painel_estilo(
			Color(
				0.006,
				0.028,
				0.055,
				0.985
			)
		)
	)

	raiz.add_child(painel_config)


	titulo_config = Label.new()

	titulo_config.text = "CONFIGURACOES DO SISTEMA"

	titulo_config.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER

	titulo_config.add_theme_color_override(
		"font_color",
		Color(
			0.30,
			0.82,
			1.0
		)
	)

	painel_config.add_child(titulo_config)


	label_master = Label.new()

	label_master.text = "VOLUME GERAL"

	label_master.add_theme_color_override(
		"font_color",
		Color(
			0.72,
			0.88,
			0.96
		)
	)

	painel_config.add_child(label_master)


	slider_master = HSlider.new()

	slider_master.min_value = 0.0
	slider_master.max_value = 1.0
	slider_master.step = 0.05
	slider_master.value = volume_master

	slider_master.value_changed.connect(
		alterar_volume_master
	)

	painel_config.add_child(slider_master)


	valor_master = Label.new()

	valor_master.text = "%d%%" % int(
		volume_master * 100.0
	)

	valor_master.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT

	valor_master.add_theme_color_override(
		"font_color",
		Color(
			0.38,
			0.80,
			1.0
		)
	)

	painel_config.add_child(valor_master)


	label_music = Label.new()

	label_music.text = "MUSICA DO MENU"

	label_music.add_theme_color_override(
		"font_color",
		Color(
			0.72,
			0.88,
			0.96
		)
	)

	painel_config.add_child(label_music)


	slider_music = HSlider.new()

	slider_music.min_value = 0.0
	slider_music.max_value = 1.0
	slider_music.step = 0.05
	slider_music.value = volume_musica

	slider_music.value_changed.connect(
		alterar_volume_musica
	)

	painel_config.add_child(slider_music)


	valor_music = Label.new()

	valor_music.text = "%d%%" % int(
		volume_musica * 100.0
	)

	valor_music.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT

	valor_music.add_theme_color_override(
		"font_color",
		Color(
			0.38,
			0.80,
			1.0
		)
	)

	painel_config.add_child(valor_music)


	label_sensibilidade = Label.new()

	label_sensibilidade.text = "SENSIBILIDADE DO TOQUE"

	label_sensibilidade.add_theme_color_override(
		"font_color",
		Color(
			0.72,
			0.88,
			0.96
		)
	)

	painel_config.add_child(label_sensibilidade)


	slider_sensibilidade = HSlider.new()

	slider_sensibilidade.min_value = 0.50
	slider_sensibilidade.max_value = 2.00
	slider_sensibilidade.step = 0.05
	slider_sensibilidade.value = sensibilidade_touch

	slider_sensibilidade.value_changed.connect(
		alterar_sensibilidade_touch
	)

	painel_config.add_child(slider_sensibilidade)


	valor_sensibilidade = Label.new()

	valor_sensibilidade.text = "%d%%" % int(
		sensibilidade_touch * 100.0
	)

	valor_sensibilidade.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT

	valor_sensibilidade.add_theme_color_override(
		"font_color",
		Color(
			0.38,
			0.80,
			1.0
		)
	)

	painel_config.add_child(valor_sensibilidade)


	botao_fullscreen = criar_botao(
		"",
		Color(
			0.04,
			0.24,
			0.38
		)
	)

	botao_fullscreen.pressed.connect(
		alternar_tela_cheia
	)

	painel_config.add_child(botao_fullscreen)


	botao_mobile_pc = criar_botao(
		"",
		Color(
			0.04,
			0.24,
			0.38
		)
	)

	botao_mobile_pc.pressed.connect(
		alternar_controles_mobile_pc
	)

	painel_config.add_child(botao_mobile_pc)

	# PC-only por enquanto: controles de toque ficam guardados no codigo,
	# mas nao aparecem nas configuracoes nem durante o jogo.
	label_sensibilidade.visible = false
	slider_sensibilidade.visible = false
	valor_sensibilidade.visible = false
	botao_mobile_pc.visible = false
	controles_mobile_pc = false


	label_versao_config = Label.new()

	label_versao_config.text = (
		"VERSAO ATUAL // "
		+
		versao_jogo
	)

	label_versao_config.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER

	label_versao_config.add_theme_color_override(
		"font_color",
		Color(
			0.42,
			0.66,
			0.78
		)
	)

	painel_config.add_child(label_versao_config)


	botao_voltar_config = criar_botao(
		"VOLTAR AO TERMINAL",
		Color(
			0.03,
			0.34,
			0.56
		)
	)

	botao_voltar_config.pressed.connect(
		fechar_configuracoes
	)

	painel_config.add_child(botao_voltar_config)


	atualizar_textos_configuracao()


# =========================================================
# BOTAO
# =========================================================

func criar_botao(
	texto: String,
	cor: Color
) -> Button:

	var botao: Button = Button.new()

	botao.text = texto

	botao.focus_mode = Control.FOCUS_NONE


	var normal: StyleBoxFlat = StyleBoxFlat.new()

	normal.bg_color = Color(
		cor.r,
		cor.g,
		cor.b,
		0.90
	)

	normal.border_color = Color(
		0.16,
		0.70,
		1.0,
		0.44
	)

	normal.border_width_left = 1
	normal.border_width_top = 1
	normal.border_width_right = 1
	normal.border_width_bottom = 1

	normal.corner_radius_top_left = 7
	normal.corner_radius_top_right = 7
	normal.corner_radius_bottom_left = 7
	normal.corner_radius_bottom_right = 7


	var hover: StyleBoxFlat = (
		normal.duplicate()
		as StyleBoxFlat
	)

	hover.bg_color = Color(
		minf(cor.r + 0.10, 1.0),
		minf(cor.g + 0.12, 1.0),
		minf(cor.b + 0.14, 1.0),
		1.0
	)

	hover.border_color = Color(
		0.55,
		0.92,
		1.0,
		1.0
	)


	var pressed: StyleBoxFlat = (
		normal.duplicate()
		as StyleBoxFlat
	)

	pressed.bg_color = Color(
		cor.r * 0.62,
		cor.g * 0.62,
		cor.b * 0.62,
		1.0
	)


	botao.add_theme_stylebox_override(
		"normal",
		normal
	)

	botao.add_theme_stylebox_override(
		"hover",
		hover
	)

	botao.add_theme_stylebox_override(
		"pressed",
		pressed
	)

	botao.add_theme_stylebox_override(
		"focus",
		hover
	)

	botao.add_theme_color_override(
		"font_color",
		Color.WHITE
	)

	botao.add_theme_color_override(
		"font_hover_color",
		Color.WHITE
	)

	botao.add_theme_color_override(
		"font_pressed_color",
		Color.WHITE
	)

	return botao


# =========================================================
# LAYOUT
# =========================================================

func atualizar_layout() -> void:

	var tela: Vector2 = (
		get_viewport().get_visible_rect().size
	)

	ultimo_tamanho_tela = tela


	raiz.position = Vector2.ZERO
	raiz.size = tela

	fundo.position = Vector2.ZERO
	fundo.size = tela


	var escala: float = clampf(
		minf(
			tela.x / 1280.0,
			tela.y / 720.0
		),
		0.72,
		1.30
	)


	# -----------------------------------------------------
	# ESTRELAS
	# -----------------------------------------------------

	for i: int in range(
		estrelas.size()
	):

		var estrela: ColorRect = estrelas[i]

		var tamanho: float = (
			1.0
			+
			float(i % 3)
		)

		estrela.size = Vector2(
			tamanho,
			tamanho
		)

		if estrela.position == Vector2.ZERO:

			estrela.position = Vector2(
				rng.randf_range(
					0.0,
					tela.x
				),
				rng.randf_range(
					0.0,
					tela.y
				)
			)


	# -----------------------------------------------------
	# PLANETA
	# -----------------------------------------------------

	var diametro: float = minf(
		tela.y * 0.92,
		720.0 * escala
	)


	planeta_brillo.size = Vector2(
		diametro * 1.12,
		diametro * 1.12
	)

	planeta_brillo.position = Vector2(
		-diametro * 0.36,
		tela.y
		-
		diametro * 0.76
	)


	planeta.size = Vector2(
		diametro,
		diametro
	)

	planeta.position = Vector2(
		-diametro * 0.30,
		tela.y
		-
		diametro * 0.70
	)


	# -----------------------------------------------------
	# SCAN LINE
	# -----------------------------------------------------

	scan_line.size = Vector2(
		tela.x,
		2.0
	)


	# -----------------------------------------------------
	# NAVE
	# -----------------------------------------------------

	ship_root.position = Vector2(
		tela.x * 0.50,
		tela.y * 0.59
	)

	ship_root.scale = Vector2(
		escala * 1.15,
		escala * 1.15
	)


	ship_engine_l.position = Vector2(
		-14.0,
		79.0
	)

	ship_engine_l.size = Vector2(
		8.0,
		30.0
	)


	ship_engine_r.position = Vector2(
		6.0,
		79.0
	)

	ship_engine_r.size = Vector2(
		8.0,
		30.0
	)


	# -----------------------------------------------------
	# TITULO
	# -----------------------------------------------------

	badge.position = Vector2(
		tela.x * 0.25,
		25.0 * escala
	)

	badge.size = Vector2(
		tela.x * 0.50,
		24.0 * escala
	)

	badge.add_theme_font_size_override(
		"font_size",
		int(
			10.0 * escala
		)
	)


	titulo.position = Vector2(
		tela.x * 0.20,
		48.0 * escala
	)

	titulo.size = Vector2(
		tela.x * 0.60,
		82.0 * escala
	)

	titulo.add_theme_font_size_override(
		"font_size",
		int(
			56.0 * escala
		)
	)


	subtitulo.position = Vector2(
		tela.x * 0.25,
		128.0 * escala
	)

	subtitulo.size = Vector2(
		tela.x * 0.50,
		28.0 * escala
	)

	subtitulo.add_theme_font_size_override(
		"font_size",
		int(
			14.0 * escala
		)
	)


	# -----------------------------------------------------
	# PAINEIS
	# -----------------------------------------------------

	var margem: float = (
		28.0 * escala
	)

	var painel_largura: float = (
		250.0 * escala
	)

	var painel_altura: float = (
		365.0 * escala
	)


	painel_esquerdo.position = Vector2(
		margem,
		tela.y * 0.30
	)

	painel_esquerdo.size = Vector2(
		painel_largura,
		painel_altura
	)


	painel_direito.position = Vector2(
		tela.x
		-
		margem
		-
		painel_largura,
		tela.y * 0.30
	)

	painel_direito.size = Vector2(
		painel_largura,
		painel_altura
	)


	painel_central.position = Vector2(
		tela.x * 0.5
		-
		170.0 * escala,
		tela.y
		-
		138.0 * escala
	)

	painel_central.size = Vector2(
		340.0 * escala,
		105.0 * escala
	)


	organizar_painel_esquerdo(
		escala
	)

	organizar_painel_direito(
		escala
	)

	organizar_painel_central(
		escala
	)


	# -----------------------------------------------------
	# RODAPE
	# -----------------------------------------------------

	rodape_esq.position = Vector2(
		18.0 * escala,
		tela.y
		-
		28.0 * escala
	)

	rodape_esq.size = Vector2(
		300.0 * escala,
		20.0 * escala
	)

	rodape_esq.add_theme_font_size_override(
		"font_size",
		int(
			9.0 * escala
		)
	)


	rodape_dir.position = Vector2(
		tela.x
		-
		340.0 * escala,
		tela.y
		-
		28.0 * escala
	)

	rodape_dir.size = Vector2(
		320.0 * escala,
		20.0 * escala
	)

	rodape_dir.add_theme_font_size_override(
		"font_size",
		int(
			9.0 * escala
		)
	)


	organizar_ajuda(
		tela,
		escala
	)

	organizar_configuracoes(
		tela,
		escala
	)


# =========================================================
# PAINEL ESQUERDO LAYOUT
# =========================================================

func organizar_painel_esquerdo(
	escala: float
) -> void:

	var filhos: Array[Node] = (
		painel_esquerdo.get_children()
	)

	if filhos.size() < 5:
		return


	var titulo_painel: Label = filhos[0] as Label


	titulo_painel.position = Vector2(
		18.0 * escala,
		18.0 * escala
	)

	titulo_painel.size = Vector2(
		215.0 * escala,
		26.0 * escala
	)

	titulo_painel.add_theme_font_size_override(
		"font_size",
		int(
			11.0 * escala
		)
	)


	label_status.position = Vector2(
		18.0 * escala,
		54.0 * escala
	)

	label_status.size = Vector2(
		210.0 * escala,
		24.0 * escala
	)

	label_status.add_theme_font_size_override(
		"font_size",
		int(
			11.0 * escala
		)
	)


	label_setor.position = Vector2(
		18.0 * escala,
		94.0 * escala
	)

	label_unidade.position = Vector2(
		18.0 * escala,
		154.0 * escala
	)

	label_sistema.position = Vector2(
		18.0 * escala,
		214.0 * escala
	)


	for label: Label in [
		label_setor,
		label_unidade,
		label_sistema
	]:

		label.size = Vector2(
			210.0 * escala,
			48.0 * escala
		)

		label.add_theme_font_size_override(
			"font_size",
			int(
				10.0 * escala
			)
		)


# =========================================================
# PAINEL DIREITO LAYOUT
# =========================================================

func organizar_painel_direito(
	escala: float
) -> void:

	var filhos: Array[Node] = (
		painel_direito.get_children()
	)

	if filhos.size() < 6:
		return


	var titulo_menu: Label = filhos[0] as Label
	var dica: Label = filhos[5] as Label


	titulo_menu.position = Vector2(
		18.0 * escala,
		18.0 * escala
	)

	titulo_menu.size = Vector2(
		214.0 * escala,
		30.0 * escala
	)

	titulo_menu.add_theme_font_size_override(
		"font_size",
		int(
			12.0 * escala
		)
	)


	var largura_botao: float = (
		210.0 * escala
	)

	var altura_botao: float = (
		48.0 * escala
	)


	for i: int in range(4):

		var botao: Button = [
			botao_iniciar,
			botao_como,
			botao_config,
			botao_sair
		][i]

		botao.position = Vector2(
			20.0 * escala,
			60.0 * escala
			+
			float(i)
			*
			59.0
			*
			escala
		)

		botao.size = Vector2(
			largura_botao,
			altura_botao
		)

		botao.add_theme_font_size_override(
			"font_size",
			int(
				10.5 * escala
			)
		)


	dica.position = Vector2(
		18.0 * escala,
		310.0 * escala
	)

	dica.size = Vector2(
		214.0 * escala,
		38.0 * escala
	)

	dica.add_theme_font_size_override(
		"font_size",
		int(
			9.0 * escala
		)
	)


# =========================================================
# PAINEL CENTRAL LAYOUT
# =========================================================

func organizar_painel_central(
	escala: float
) -> void:

	var filhos: Array[Node] = (
		painel_central.get_children()
	)

	if filhos.size() < 2:
		return


	var titulo_operacao: Label = filhos[0] as Label


	titulo_operacao.position = Vector2(
		12.0 * escala,
		10.0 * escala
	)

	titulo_operacao.size = Vector2(
		316.0 * escala,
		20.0 * escala
	)

	titulo_operacao.add_theme_font_size_override(
		"font_size",
		int(
			9.0 * escala
		)
	)


	label_operacao.position = Vector2(
		12.0 * escala,
		28.0 * escala
	)

	label_operacao.size = Vector2(
		316.0 * escala,
		66.0 * escala
	)

	label_operacao.add_theme_font_size_override(
		"font_size",
		int(
			9.0 * escala
		)
	)


# =========================================================
# AJUDA LAYOUT
# =========================================================

func organizar_ajuda(
	tela: Vector2,
	escala: float
) -> void:

	var largura: float = minf(
		620.0 * escala,
		tela.x - 30.0
	)

	var altura: float = minf(
		570.0 * escala,
		tela.y - 26.0
	)


	painel_ajuda.size = Vector2(
		largura,
		altura
	)

	painel_ajuda.position = Vector2(
		(tela.x - largura) * 0.5,
		(tela.y - altura) * 0.5
	)


	titulo_ajuda.position = Vector2(
		24.0 * escala,
		24.0 * escala
	)

	titulo_ajuda.size = Vector2(
		largura - 48.0 * escala,
		34.0 * escala
	)

	titulo_ajuda.add_theme_font_size_override(
		"font_size",
		int(
			18.0 * escala
		)
	)


	texto_ajuda.position = Vector2(
		28.0 * escala,
		70.0 * escala
	)

	texto_ajuda.size = Vector2(
		largura - 56.0 * escala,
		altura - 160.0 * escala
	)

	texto_ajuda.add_theme_font_size_override(
		"font_size",
		int(
			12.0 * escala
		)
	)


	botao_voltar.position = Vector2(
		30.0 * escala,
		altura - 72.0 * escala
	)

	botao_voltar.size = Vector2(
		largura - 60.0 * escala,
		46.0 * escala
	)

	botao_voltar.add_theme_font_size_override(
		"font_size",
		int(
			11.0 * escala
		)
	)


# =========================================================
# CONFIGURACOES LAYOUT
# =========================================================

func organizar_configuracoes(
	tela: Vector2,
	escala: float
) -> void:

	if painel_config == null:
		return


	var largura: float = minf(
		590.0 * escala,
		tela.x - 30.0
	)

	var altura: float = minf(
		650.0 * escala,
		tela.y - 26.0
	)


	painel_config.size = Vector2(
		largura,
		altura
	)

	painel_config.position = Vector2(
		(tela.x - largura) * 0.5,
		(tela.y - altura) * 0.5
	)


	var margem: float = 34.0 * escala
	var conteudo: float = largura - margem * 2.0


	titulo_config.position = Vector2(
		margem,
		22.0 * escala
	)

	titulo_config.size = Vector2(
		conteudo,
		34.0 * escala
	)

	titulo_config.add_theme_font_size_override(
		"font_size",
		int(18.0 * escala)
	)


	label_master.position = Vector2(margem, 76.0 * escala)
	label_master.size = Vector2(conteudo * 0.70, 23.0 * escala)
	label_master.add_theme_font_size_override("font_size", int(11.0 * escala))

	valor_master.position = Vector2(margem + conteudo * 0.72, 76.0 * escala)
	valor_master.size = Vector2(conteudo * 0.28, 23.0 * escala)
	valor_master.add_theme_font_size_override("font_size", int(10.0 * escala))

	slider_master.position = Vector2(margem, 102.0 * escala)
	slider_master.size = Vector2(conteudo, 28.0 * escala)


	label_music.position = Vector2(margem, 140.0 * escala)
	label_music.size = Vector2(conteudo * 0.70, 23.0 * escala)
	label_music.add_theme_font_size_override("font_size", int(11.0 * escala))

	valor_music.position = Vector2(margem + conteudo * 0.72, 140.0 * escala)
	valor_music.size = Vector2(conteudo * 0.28, 23.0 * escala)
	valor_music.add_theme_font_size_override("font_size", int(10.0 * escala))

	slider_music.position = Vector2(margem, 166.0 * escala)
	slider_music.size = Vector2(conteudo, 28.0 * escala)


	label_sensibilidade.position = Vector2(margem, 204.0 * escala)
	label_sensibilidade.size = Vector2(conteudo * 0.70, 23.0 * escala)
	label_sensibilidade.add_theme_font_size_override("font_size", int(11.0 * escala))

	valor_sensibilidade.position = Vector2(margem + conteudo * 0.72, 204.0 * escala)
	valor_sensibilidade.size = Vector2(conteudo * 0.28, 23.0 * escala)
	valor_sensibilidade.add_theme_font_size_override("font_size", int(10.0 * escala))

	slider_sensibilidade.position = Vector2(margem, 230.0 * escala)
	slider_sensibilidade.size = Vector2(conteudo, 28.0 * escala)


	botao_fullscreen.position = Vector2(margem, 278.0 * escala)
	botao_fullscreen.size = Vector2(conteudo, 44.0 * escala)
	botao_fullscreen.add_theme_font_size_override("font_size", int(10.5 * escala))

	botao_mobile_pc.position = Vector2(margem, 334.0 * escala)
	botao_mobile_pc.size = Vector2(conteudo, 44.0 * escala)
	botao_mobile_pc.add_theme_font_size_override("font_size", int(10.5 * escala))


	label_versao_config.position = Vector2(margem, 394.0 * escala)
	label_versao_config.size = Vector2(conteudo, 28.0 * escala)
	label_versao_config.add_theme_font_size_override("font_size", int(10.0 * escala))


	botao_voltar_config.position = Vector2(
		margem,
		altura - 68.0 * escala
	)

	botao_voltar_config.size = Vector2(conteudo, 44.0 * escala)
	botao_voltar_config.add_theme_font_size_override("font_size", int(10.5 * escala))


# =========================================================
# ANIMACOES
# =========================================================

func animar_estrelas(
	delta: float
) -> void:

	if fundo == null:
		return


	var tela: Vector2 = (
		get_viewport().get_visible_rect().size
	)


	for i: int in range(
		estrelas.size()
	):

		var estrela: ColorRect = estrelas[i]

		estrela.position.y += (
			estrelas_velocidade[i]
			*
			delta
		)


		if estrela.position.y > tela.y + 5.0:

			estrela.position.y = -5.0

			estrela.position.x = rng.randf_range(
				0.0,
				tela.x
			)


func animar_scan(
	delta: float
) -> void:

	scan_tempo += delta * 55.0


	var tela: Vector2 = (
		get_viewport().get_visible_rect().size
	)


	if tela.y <= 0.0:
		return


	var y: float = fposmod(
		scan_tempo,
		tela.y
	)

	scan_line.position = Vector2(
		0.0,
		y
	)


func animar_pulso(
	delta: float
) -> void:

	pulso += delta


	var intensidade: float = (
		0.72
		+
		sin(
			pulso * 3.2
		)
		*
		0.20
	)


	label_status.modulate = Color(
		1.0,
		1.0,
		1.0,
		intensidade
	)


	ship_engine_l.modulate = Color(
		1.0,
		1.0,
		1.0,
		0.65
		+
		sin(
			pulso * 7.0
		)
		*
		0.25
	)


	ship_engine_r.modulate = ship_engine_l.modulate


func animar_nave(
	delta: float
) -> void:

	if ship_root == null:
		return


	ship_root.rotation += (
		sin(
			pulso * 0.60
		)
		*
		0.00025
		*
		delta
	)


# =========================================================
# AJUDA
# =========================================================

func abrir_ajuda() -> void:

	painel_config.visible = false
	painel_ajuda.visible = true

	painel_esquerdo.visible = false
	painel_direito.visible = false
	painel_central.visible = false
	ship_root.visible = false


func fechar_ajuda() -> void:

	painel_ajuda.visible = false

	painel_esquerdo.visible = true
	painel_direito.visible = true
	painel_central.visible = true
	ship_root.visible = true


# =========================================================
# MENU CONFIGURACOES
# =========================================================

func abrir_configuracoes() -> void:

	painel_config.visible = true

	painel_ajuda.visible = false

	painel_esquerdo.visible = false
	painel_direito.visible = false
	painel_central.visible = false
	ship_root.visible = false

	atualizar_textos_configuracao()


func fechar_configuracoes() -> void:

	painel_config.visible = false

	painel_esquerdo.visible = true
	painel_direito.visible = true
	painel_central.visible = true
	ship_root.visible = true


func alterar_volume_master(
	valor: float
) -> void:

	volume_master = clampf(
		valor,
		0.0,
		1.0
	)

	aplicar_volume_master()

	if valor_master != null:
		valor_master.text = "%d%%" % int(
			round(
				volume_master * 100.0
			)
		)

	salvar_configuracoes()


func alterar_volume_musica(
	valor: float
) -> void:

	volume_musica = clampf(
		valor,
		0.0,
		1.0
	)

	aplicar_volume_musica()

	if valor_music != null:
		valor_music.text = "%d%%" % int(
			round(
				volume_musica * 100.0
			)
		)

	salvar_configuracoes()


func alterar_sensibilidade_touch(
	valor: float
) -> void:

	sensibilidade_touch = clampf(
		valor,
		0.50,
		2.00
	)

	if valor_sensibilidade != null:
		valor_sensibilidade.text = "%d%%" % int(
			round(
				sensibilidade_touch * 100.0
			)
		)

	aplicar_sensibilidade_touch()
	salvar_configuracoes()


func alternar_tela_cheia() -> void:

	tela_cheia_ativa = !tela_cheia_ativa

	aplicar_tela_cheia()

	atualizar_textos_configuracao()

	salvar_configuracoes()


func alternar_controles_mobile_pc() -> void:

	controles_mobile_pc = !controles_mobile_pc

	aplicar_controles_mobile_pc()

	atualizar_textos_configuracao()

	salvar_configuracoes()


func atualizar_textos_configuracao() -> void:

	if botao_fullscreen != null:

		if tela_cheia_ativa:
			botao_fullscreen.text = "TELA CHEIA // ATIVADA"
		else:
			botao_fullscreen.text = "TELA CHEIA // DESATIVADA"


	if botao_mobile_pc != null:

		if controles_mobile_pc:
			botao_mobile_pc.text = "CONTROLES MOBILE NO PC // VISIVEIS"
		else:
			botao_mobile_pc.text = "CONTROLES MOBILE NO PC // OCULTOS"


	if valor_master != null:
		valor_master.text = "%d%%" % int(
			round(
				volume_master * 100.0
			)
		)


	if valor_music != null:
		valor_music.text = "%d%%" % int(
			round(
				volume_musica * 100.0
			)
		)


	if valor_sensibilidade != null:
		valor_sensibilidade.text = "%d%%" % int(
			round(
				sensibilidade_touch * 100.0
			)
		)


# =========================================================
# CONFIGURACOES SALVAS
# =========================================================

func carregar_configuracoes() -> void:

	var config: ConfigFile = ConfigFile.new()

	var erro: Error = config.load(
		CONFIG_PATH
	)

	if erro != OK:
		return


	volume_master = clampf(
		float(
			config.get_value(
				"audio",
				"master",
				volume_master
			)
		),
		0.0,
		1.0
	)


	volume_musica = clampf(
		float(
			config.get_value(
				"audio",
				"music",
				volume_musica
			)
		),
		0.0,
		1.0
	)


	tela_cheia_ativa = bool(
		config.get_value(
			"video",
			"fullscreen",
			tela_cheia_ativa
		)
	)


	controles_mobile_pc = bool(
		config.get_value(
			"interface",
			"mobile_controls_pc",
			controles_mobile_pc
		)
	)


	sensibilidade_touch = clampf(
		float(
			config.get_value(
				"controls",
				"touch_sensitivity",
				sensibilidade_touch
			)
		),
		0.50,
		2.00
	)


func salvar_configuracoes() -> void:

	var config: ConfigFile = ConfigFile.new()

	config.set_value(
		"audio",
		"master",
		volume_master
	)

	config.set_value(
		"audio",
		"music",
		volume_musica
	)

	config.set_value(
		"video",
		"fullscreen",
		tela_cheia_ativa
	)

	config.set_value(
		"interface",
		"mobile_controls_pc",
		controles_mobile_pc
	)

	config.set_value(
		"controls",
		"touch_sensitivity",
		sensibilidade_touch
	)

	config.save(
		CONFIG_PATH
	)


func aplicar_configuracoes() -> void:

	aplicar_volume_master()
	aplicar_volume_musica()
	aplicar_tela_cheia()
	aplicar_controles_mobile_pc()
	aplicar_sensibilidade_touch()

	if slider_master != null:
		slider_master.value = volume_master

	if slider_music != null:
		slider_music.value = volume_musica

	if slider_sensibilidade != null:
		slider_sensibilidade.value = sensibilidade_touch

	atualizar_textos_configuracao()


func aplicar_sensibilidade_touch() -> void:

	var cena: Node = get_tree().current_scene

	if cena == null:
		return

	var controles: Node = cena.get_node_or_null("MobileControls")

	if controles == null:
		controles = cena.find_child(
			"MobileControls",
			true,
			false
		)

	if controles != null and controles.has_method("definir_sensibilidade"):
		controles.call(
			"definir_sensibilidade",
			sensibilidade_touch
		)


func aplicar_volume_master() -> void:

	var indice: int = AudioServer.get_bus_index(
		"Master"
	)

	if indice < 0:
		return


	AudioServer.set_bus_volume_db(
		indice,
		volume_para_db(
			volume_master
		)
	)


func aplicar_volume_musica() -> void:

	if music_player == null:
		return


	music_player.volume_db = volume_para_db(
		volume_musica
	)


func aplicar_tela_cheia() -> void:

	if OS.has_feature("mobile"):
		return


	if tela_cheia_ativa:

		DisplayServer.window_set_mode(
			DisplayServer.WINDOW_MODE_FULLSCREEN
		)

	else:

		DisplayServer.window_set_mode(
			DisplayServer.WINDOW_MODE_WINDOWED
		)


func aplicar_controles_mobile_pc() -> void:

	var mobile: Node = encontrar_node_por_nome(
		get_tree().current_scene,
		"MobileControls"
	)


	if mobile == null:
		return


	if mobile.get("mostrar_no_pc_para_teste") != null:

		mobile.set(
			"mostrar_no_pc_para_teste",
			controles_mobile_pc
		)


	var root_mobile: Node = mobile.get_node_or_null(
		"MobileControlsRoot"
	)


	if root_mobile != null:

		var mobile_real: bool = (
			OS.has_feature("android")
			or
			OS.has_feature("ios")
			or
			OS.has_feature("mobile")
		)

		root_mobile.set(
			"visible",
			mobile_real
			or
			controles_mobile_pc
		)


func volume_para_db(
	valor: float
) -> float:

	if valor <= 0.001:
		return -80.0

	return linear_to_db(
		valor
	)


func encontrar_node_por_nome(
	node: Node,
	nome_procurado: String
) -> Node:

	if node == null:
		return null


	if String(
		node.name
	) == nome_procurado:

		return node


	for filho: Node in node.get_children():

		var resultado: Node = encontrar_node_por_nome(
			filho,
			nome_procurado
		)

		if resultado != null:
			return resultado


	return null


# =========================================================
# MUSICA PROCEDURAL
# =========================================================

func iniciar_musica() -> void:

	music_player = AudioStreamPlayer.new()

	music_player.name = "MenuMusic"

	music_player.process_mode = Node.PROCESS_MODE_ALWAYS

	add_child(
		music_player
	)


	music_stream = AudioStreamGenerator.new()

	music_stream.mix_rate = music_mix_rate
	music_stream.buffer_length = 0.55


	music_player.stream = music_stream

	aplicar_volume_musica()

	music_player.play()


	music_playback = (
		music_player.get_stream_playback()
		as AudioStreamGeneratorPlayback
	)


	processar_musica()


func processar_musica() -> void:

	if music_player == null:
		return

	if music_playback == null:
		return

	if !music_player.playing:
		return


	var disponivel: int = music_playback.get_frames_available()

	var quantidade: int = mini(
		disponivel,
		2048
	)


	for i: int in range(
		quantidade
	):

		var t: float = (
			float(
				music_sample_index
			)
			/
			music_mix_rate
		)


		# Drone grave + quinta + oitava.
		var base: float = sin(
			TAU * 55.0 * t
		)

		var quinta: float = sin(
			TAU * 82.4069 * t
		)

		var oitava: float = sin(
			TAU * 110.0 * t
		)


		# Camada alta bem suave para dar sensacao sci-fi.
		var brilho: float = sin(
			TAU
			*
			(
				220.0
				+
				sin(
					TAU * 0.035 * t
				)
				*
				4.0
			)
			*
			t
		)


		var respiracao: float = (
			0.55
			+
			0.45
			*
			sin(
				TAU
				*
				0.075
				*
				t
			)
		)


		var pulso_lento: float = (
			0.70
			+
			0.30
			*
			sin(
				TAU
				*
				0.125
				*
				t
			)
		)


		var amostra: float = (
			base * 0.050
			+
			quinta * 0.030
			+
			oitava * 0.022
			+
			brilho * 0.010 * respiracao
		)


		amostra *= (
			0.55
			+
			pulso_lento * 0.35
		)


		# Pequena diferenca entre os canais cria largura.
		var esquerda: float = amostra * 0.95

		var direita: float = (
			amostra
			+
			sin(
				TAU * 164.8138 * t
			)
			*
			0.006
			*
			respiracao
		)


		music_playback.push_frame(
			Vector2(
				esquerda,
				direita
			)
		)


		music_sample_index += 1


# =========================================================
# INICIAR
# =========================================================

func iniciar_jogo() -> void:

	if music_player != null:
		music_player.stop()

	get_tree().paused = false

	raiz.visible = false


# =========================================================
# SAIR
# =========================================================

func sair_do_jogo() -> void:

	if music_player != null:
		music_player.stop()

	get_tree().paused = false

	get_tree().quit()


# =========================================================
# ESTILO PAINEL
# =========================================================

func criar_painel_estilo(
	fundo_cor: Color
) -> StyleBoxFlat:

	var estilo: StyleBoxFlat = StyleBoxFlat.new()

	estilo.bg_color = fundo_cor

	estilo.border_color = Color(
		0.08,
		0.48,
		0.76,
		0.60
	)

	estilo.border_width_left = 1
	estilo.border_width_top = 1
	estilo.border_width_right = 1
	estilo.border_width_bottom = 1

	estilo.corner_radius_top_left = 8
	estilo.corner_radius_top_right = 8
	estilo.corner_radius_bottom_left = 8
	estilo.corner_radius_bottom_right = 8

	estilo.shadow_color = Color(
		0.0,
		0.0,
		0.0,
		0.55
	)

	estilo.shadow_size = 12

	return estilo


# =========================================================
# ESTILO CIRCULO
# =========================================================

func criar_circulo(
	fundo_cor: Color,
	borda_cor: Color,
	borda: int
) -> StyleBoxFlat:

	var estilo: StyleBoxFlat = StyleBoxFlat.new()

	estilo.bg_color = fundo_cor

	estilo.border_color = borda_cor

	estilo.border_width_left = borda
	estilo.border_width_top = borda
	estilo.border_width_right = borda
	estilo.border_width_bottom = borda

	estilo.corner_radius_top_left = 1000
	estilo.corner_radius_top_right = 1000
	estilo.corner_radius_bottom_left = 1000
	estilo.corner_radius_bottom_right = 1000

	return estilo
