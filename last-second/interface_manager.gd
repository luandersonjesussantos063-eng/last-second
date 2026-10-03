extends Node


# ============================================================
# LAST SECOND
# INTERFACE MANAGER v1.0
#
# FUNCOES:
#
# - Esconde HUD policial enquanto estamos a pe
# - Mostra novamente quando entramos na nave
#
# - HUD de performance desligado por padrao
# - Adiciona opcao nas CONFIGURACOES
# - PC e Android
# - Salva preferencia
# ============================================================


const CONFIG_PATH := "user://last_second_settings.cfg"


# ============================================================
# CONFIGURACOES
# ============================================================

@export_category("HUD")

@export var ocultar_hud_policial_quando_a_pe: bool = true

@export var performance_hud_padrao: bool = false


# ============================================================
# REFERENCIAS
# ============================================================

var cena: Node = null

var cockpit_fx: Node = null

var painel_policial: Control = null

var mobile_performance_hud: CanvasLayer = null

var mobile_controls: Node = null

var player_on_foot: Node3D = null

var main_menu: Node = null

var painel_config: Control = null

var label_versao_config: Label = null


# ============================================================
# BOTAO CONFIGURACOES
# ============================================================

var botao_performance: Button = null

var performance_hud_ativo: bool = false


# ============================================================
# CONTROLE
# ============================================================

var tempo_busca: float = 0.0


# ============================================================
# READY
# ============================================================

func _ready() -> void:

	process_mode = Node.PROCESS_MODE_ALWAYS

	# Faz este script atualizar depois dos sistemas principais.
	process_priority = 100


	carregar_configuracao()


	await get_tree().process_frame
	await get_tree().process_frame
	await get_tree().process_frame


	localizar_sistemas()

	aplicar_performance_hud()

	criar_botao_nas_configuracoes()


	print(
		"=========================================="
	)

	print(
		"INTERFACE MANAGER // ONLINE"
	)

	print(
		"HUD A PE // LIMPO"
	)

	print(
		"MONITOR PERFORMANCE // CONFIGURAVEL"
	)

	print(
		"=========================================="
	)



# ============================================================
# PROCESS
# ============================================================

func _process(
	delta: float
) -> void:


	# ========================================================
	# PROCURA PERIODICAMENTE SISTEMAS QUE AINDA NAO EXISTIAM
	# ========================================================

	tempo_busca += delta


	if tempo_busca >= 1.0:

		tempo_busca = 0.0

		localizar_sistemas()


		if botao_performance == null:

			criar_botao_nas_configuracoes()


	# ========================================================
	# HUD POLICIAL
	# ========================================================

	atualizar_hud_policial()


	# ========================================================
	# POSICIONAMENTO DO BOTAO CONFIG
	#
	# Fazemos continuamente porque o MainMenu reorganiza
	# a interface quando muda resolucao/orientacao.
	# ========================================================

	if painel_config != null:

		if painel_config.visible:

			organizar_botao_configuracoes()



# ============================================================
# LOCALIZAR SISTEMAS
# ============================================================

func localizar_sistemas() -> void:


	cena = get_tree().current_scene


	if cena == null:

		return


	# ========================================================
	# COCKPIT FX
	# ========================================================

	if cockpit_fx == null:

		cockpit_fx = cena.get_node_or_null(
			"CockpitFX"
		)


	if cockpit_fx == null:

		cockpit_fx = cena.find_child(
			"CockpitFX",
			true,
			false
		)


	# ========================================================
	# PAINEL POLICIAL
	#
	# O script CockpitFX guarda o painel na variavel "painel".
	# ========================================================

	if cockpit_fx != null:

		var valor_painel: Variant = cockpit_fx.get(
			"painel"
		)


		if valor_painel is Control:

			painel_policial = valor_painel


	# ========================================================
	# PERFORMANCE HUD
	# ========================================================

	if mobile_performance_hud == null:

		var encontrado_performance := cena.get_node_or_null(
			"MobilePerformanceHUD"
		)


		if encontrado_performance is CanvasLayer:

			mobile_performance_hud = encontrado_performance


	if mobile_performance_hud == null:

		var encontrado := cena.find_child(
			"MobilePerformanceHUD",
			true,
			false
		)


		if encontrado is CanvasLayer:

			mobile_performance_hud = encontrado


	# ========================================================
	# MOBILE CONTROLS
	# ========================================================

	if mobile_controls == null:

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
	# PLAYER A PE
	# ========================================================

	if player_on_foot == null:

		var pe := cena.find_child(
			"PlayerOnFoot",
			true,
			false
		)


		if pe is Node3D:

			player_on_foot = pe


	# ========================================================
	# MAIN MENU
	# ========================================================

	if main_menu == null:

		main_menu = cena.get_node_or_null(
			"MainMenu"
		)


	if main_menu == null:

		main_menu = cena.find_child(
			"MainMenu",
			true,
			false
		)


	# ========================================================
	# CONFIG PANEL
	# ========================================================

	if main_menu != null:

		var painel_var: Variant = main_menu.get(
			"painel_config"
		)


		if painel_var is Control:

			painel_config = painel_var


		var versao_var: Variant = main_menu.get(
			"label_versao_config"
		)


		if versao_var is Label:

			label_versao_config = versao_var



# ============================================================
# VERIFICAR SE ESTA A PE
# ============================================================

func esta_a_pe() -> bool:


	# ========================================================
	# PRIMEIRA OPCAO
	# ========================================================

	if mobile_controls != null:

		var valor: Variant = mobile_controls.get(
			"modo_a_pe"
		)


		if valor != null:

			return bool(
				valor
			)


	# ========================================================
	# SEGUNDA OPCAO
	# ========================================================

	if player_on_foot != null:

		if is_instance_valid(
			player_on_foot
		):

			return player_on_foot.visible


	return false



# ============================================================
# HUD POLICIAL
# ============================================================

func atualizar_hud_policial() -> void:


	if painel_policial == null:

		return


	if !is_instance_valid(
		painel_policial
	):

		painel_policial = null

		return


	# ========================================================
	# ENQUANTO ESTAMOS A PE:
	#
	# some o painel enorme de ocorrencia.
	#
	# Quando voltamos para a nave:
	# aparece novamente.
	# ========================================================

	if ocultar_hud_policial_quando_a_pe:

		painel_policial.visible = !esta_a_pe()

	else:

		painel_policial.visible = true



# ============================================================
# PERFORMANCE HUD
# ============================================================

func aplicar_performance_hud() -> void:


	if mobile_performance_hud == null:

		return


	if !is_instance_valid(
		mobile_performance_hud
	):

		mobile_performance_hud = null

		return


	mobile_performance_hud.visible = (
		performance_hud_ativo
	)



# ============================================================
# CRIAR BOTAO NAS CONFIGURACOES
# ============================================================

func criar_botao_nas_configuracoes() -> void:


	if painel_config == null:

		localizar_sistemas()


	if painel_config == null:

		return


	# ========================================================
	# EVITA DUPLICAR
	# ========================================================

	var existente := painel_config.get_node_or_null(
		"BotaoPerformanceHUD"
	)


	if existente is Button:

		botao_performance = existente

		atualizar_texto_botao()

		return


	# ========================================================
	# BOTAO
	# ========================================================

	botao_performance = Button.new()

	botao_performance.name = "BotaoPerformanceHUD"

	botao_performance.focus_mode = Control.FOCUS_NONE


	# ========================================================
	# VISUAL
	# ========================================================

	var normal := StyleBoxFlat.new()

	normal.bg_color = Color(
		0.015,
		0.08,
		0.13,
		0.95
	)

	normal.border_color = Color(
		0.05,
		0.52,
		0.80,
		0.90
	)

	normal.set_border_width_all(
		2
	)

	normal.set_corner_radius_all(
		8
	)


	var hover := normal.duplicate() as StyleBoxFlat

	hover.bg_color = Color(
		0.02,
		0.15,
		0.23,
		0.97
	)


	var pressed := normal.duplicate() as StyleBoxFlat

	pressed.bg_color = Color(
		0.03,
		0.25,
		0.35,
		1.0
	)


	botao_performance.add_theme_stylebox_override(
		"normal",
		normal
	)

	botao_performance.add_theme_stylebox_override(
		"hover",
		hover
	)

	botao_performance.add_theme_stylebox_override(
		"pressed",
		pressed
	)

	botao_performance.add_theme_stylebox_override(
		"focus",
		normal
	)


	botao_performance.add_theme_color_override(
		"font_color",
		Color(
			0.72,
			0.92,
			1.0
		)
	)


	botao_performance.pressed.connect(
		alternar_performance_hud
	)


	painel_config.add_child(
		botao_performance
	)


	atualizar_texto_botao()

	organizar_botao_configuracoes()



# ============================================================
# ORGANIZAR BOTAO
# ============================================================

func organizar_botao_configuracoes() -> void:


	if botao_performance == null:

		return


	if painel_config == null:

		return


	var largura := painel_config.size.x

	var altura := painel_config.size.y


	if largura <= 10.0:

		return


	# ========================================================
	# MESMO ESTILO DE MARGEM DO MENU ORIGINAL
	# ========================================================

	var margem := maxf(
		24.0,
		largura * 0.058
	)


	var conteudo := (
		largura
		- margem * 2.0
	)


	# ========================================================
	# NOVO BOTAO ENTRE
	# CONTROLES MOBILE e VERSAO
	# ========================================================

	botao_performance.position = Vector2(
		margem,
		altura * 0.60
	)


	botao_performance.size = Vector2(
		conteudo,
		44.0
	)


	botao_performance.add_theme_font_size_override(
		"font_size",
		11
	)


	# ========================================================
	# EMPURRA TEXTO DA VERSAO UM POUCO PARA BAIXO
	# ========================================================

	if label_versao_config != null:

		label_versao_config.position = Vector2(
			margem,
			altura * 0.70
		)

		label_versao_config.size = Vector2(
			conteudo,
			28.0
		)



# ============================================================
# LIGAR / DESLIGAR PERFORMANCE
# ============================================================

func alternar_performance_hud() -> void:


	performance_hud_ativo = (
		!performance_hud_ativo
	)


	aplicar_performance_hud()

	atualizar_texto_botao()

	salvar_configuracao()



# ============================================================
# TEXTO DO BOTAO
# ============================================================

func atualizar_texto_botao() -> void:


	if botao_performance == null:

		return


	if performance_hud_ativo:

		botao_performance.text = (
			"MONITOR DE DESEMPENHO // ATIVADO"
		)

	else:

		botao_performance.text = (
			"MONITOR DE DESEMPENHO // DESATIVADO"
		)



# ============================================================
# CARREGAR CONFIGURACAO
# ============================================================

func carregar_configuracao() -> void:


	var config := ConfigFile.new()


	var erro := config.load(
		CONFIG_PATH
	)


	if erro != OK:

		performance_hud_ativo = (
			performance_hud_padrao
		)

		return


	performance_hud_ativo = bool(
		config.get_value(
			"interface",
			"performance_hud",
			performance_hud_padrao
		)
	)



# ============================================================
# SALVAR CONFIGURACAO
# ============================================================

func salvar_configuracao() -> void:


	var config := ConfigFile.new()


	# ========================================================
	# IMPORTANTE:
	#
	# Carrega o arquivo existente primeiro para NAO apagar
	# volume, sensibilidade, fullscreen etc.
	# ========================================================

	config.load(
		CONFIG_PATH
	)


	config.set_value(
		"interface",
		"performance_hud",
		performance_hud_ativo
	)


	config.save(
		CONFIG_PATH
	)
