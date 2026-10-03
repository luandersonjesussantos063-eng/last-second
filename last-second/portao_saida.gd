extends Node3D


# ============================================================
# ODYSSEY STATION
# PORTAO PRINCIPAL v1.2
#
# AUTOMATICO:
# - nave liga propulsao -> abre
# - todas desligadas -> fecha
#
# MANUAL:
# - painel fisico ao lado direito
# - aproximar a pe
# - PC: tecla E
# - MOBILE: botao ABRIR PORTAO
#
# SEGURANCA:
# - portao fisico com colisao
# - nao fecha se player estiver passando
# - alerta vermelho piscante durante abertura
# ============================================================


# ============================================================
# CONFIGURACAO DO PORTAO
# ============================================================

@export_category("Portao")

@export_range(1.0, 10.0, 0.1)
var tempo_abertura: float = 10.0

@export_range(0.5, 5.0, 0.1)
var atraso_fechamento: float = 1.8

@export_range(0.01, 5.0, 0.01)
var limite_motor_p01: float = 0.10


# ============================================================
# ABERTURA MANUAL
# ============================================================

@export_category("Controle Manual")

# Depois de apertar o botao,
# o portao permanece liberado por este tempo.
@export_range(3.0, 30.0, 1.0)
var tempo_abertura_manual: float = 12.0

@export_range(2.0, 8.0, 0.5)
var alcance_botao_manual: float = 4.5


# ============================================================
# ALERTA
# ============================================================

@export_category("Alerta")

@export_range(0.08, 1.0, 0.01)
var velocidade_pisca: float = 0.20

@export_range(1.0, 20.0, 0.5)
var energia_luz_alerta: float = 8.0


# ============================================================
# SEGURANCA
# ============================================================

@export_category("Seguranca")

@export_range(5.0, 30.0, 1.0)
var distancia_seguranca_portao: float = 14.0


# ============================================================
# REFERENCIAS
# ============================================================

var hangar: Node3D = null

var cena: Node = null

var player: Node3D = null

var mobile_controls: Node = null


# ============================================================
# PORTAO
# ============================================================

var folha_portao: AnimatableBody3D = null

var colisao_portao: CollisionShape3D = null

var tween_portao: Tween = null


# ============================================================
# BOTAO MANUAL
# ============================================================

var sensor_botao: Area3D = null

var botao_3d: MeshInstance3D = null

var botao_3d_posicao_normal := Vector3.ZERO

var jogador_perto_botao: bool = false

var tempo_manual_restante: float = 0.0


# ============================================================
# INTERFACE DO BOTAO
# ============================================================

var canvas_manual: CanvasLayer = null

var ui_manual: Control = null

var botao_manual_ui: Button = null


# ============================================================
# ALERTA
# ============================================================

var alerta_visual: Array[Node3D] = []

var alerta_luzes: Array[OmniLight3D] = []

var tempo_pisca: float = 0.0

var alerta_ligado: bool = false


# ============================================================
# DIMENSOES
# ============================================================

var largura_hangar: float = 150.0

var profundidade_hangar: float = 180.0

var altura_hangar: float = 30.0


var largura_portao: float = 136.0

var altura_portao: float = 25.0

var espessura_portao: float = 1.2


# ============================================================
# POSICOES
# ============================================================

var frente_z: float = -90.0

var posicao_fechada := Vector3.ZERO

var posicao_aberta := Vector3.ZERO


# ============================================================
# ESTADO
# ============================================================

var portao_aberto: bool = false

var alvo_aberto: bool = false

var portao_movendo: bool = false

var abrindo_agora: bool = false

var tempo_sem_motor: float = 0.0


# ============================================================
# NAVES P02/P03/P04
# ============================================================

var motores_naves: Dictionary = {

	"P02": false,

	"P03": false,

	"P04": false

}


# ============================================================
# CORES
# ============================================================

const COR_ESTRUTURA := Color(
	0.10,
	0.12,
	0.16
)

const COR_PORTAO := Color(
	0.075,
	0.09,
	0.12
)

const COR_PAINEL := Color(
	0.17,
	0.20,
	0.25
)

const COR_CIANO := Color(
	0.0,
	0.80,
	1.0
)

const COR_VERDE := Color(
	0.05,
	1.0,
	0.38
)

const COR_LARANJA := Color(
	1.0,
	0.36,
	0.06
)

const COR_VERMELHO := Color(
	1.0,
	0.02,
	0.01
)


# ============================================================
# READY
# ============================================================

func _ready() -> void:

	process_mode = Node.PROCESS_MODE_ALWAYS


	hangar = get_parent() as Node3D


	if hangar == null:

		push_error(
			"PORTAO: PortaoSaida precisa ser filho do HangarBase."
		)

		return


	cena = get_tree().current_scene


	ler_dimensoes_hangar()

	localizar_sistemas()

	criar_portao_principal()

	criar_sistema_alerta()

	criar_botao_manual()

	criar_interface_manual()

	desligar_alerta()


	print(
		"=========================================="
	)

	print(
		"PORTAO v1.2 // AUTOMATICO + MANUAL"
	)

	print(
		"PAINEL MANUAL // ONLINE"
	)

	print(
		"=========================================="
	)



# ============================================================
# DIMENSOES
# ============================================================

func ler_dimensoes_hangar() -> void:

	var valor: Variant


	valor = hangar.get(
		"largura_hangar"
	)


	if valor != null:

		largura_hangar = float(
			valor
		)


	valor = hangar.get(
		"profundidade_hangar"
	)


	if valor != null:

		profundidade_hangar = float(
			valor
		)


	valor = hangar.get(
		"altura_hangar"
	)


	if valor != null:

		altura_hangar = float(
			valor
		)


	largura_portao = (
		largura_hangar
		- 14.0
	)


	altura_portao = (
		altura_hangar
		- 5.0
	)


	frente_z = (
		-profundidade_hangar / 2.0
		+ 0.5
	)


	posicao_fechada = Vector3(
		0.0,
		altura_portao / 2.0,
		frente_z
	)


	posicao_aberta = Vector3(
		0.0,

		altura_hangar
		+ altura_portao / 2.0
		+ 2.0,

		frente_z
	)



# ============================================================
# LOCALIZAR SISTEMAS
# ============================================================

func localizar_sistemas() -> void:


	if cena == null:

		return


	player = cena.get_node_or_null(
		"Player"
	) as Node3D


	if player == null:

		var encontrado := cena.find_child(
			"Player",
			true,
			false
		)


		if encontrado is Node3D:

			player = encontrado


	mobile_controls = cena.get_node_or_null(
		"MobileControls"
	)


	if mobile_controls == null:

		mobile_controls = cena.find_child(
			"MobileControls",
			true,
			false
		)



# ============================================================
# PORTAO PRINCIPAL
# ============================================================

func criar_portao_principal() -> void:


	# ========================================================
	# PILAR ESQUERDO
	# ========================================================

	criar_bloco_estatico(
		"PilarPortaoE",

		Vector3(
			6.0,
			altura_hangar,
			4.0
		),

		Vector3(
			-largura_portao / 2.0 - 3.0,
			altura_hangar / 2.0,
			frente_z
		),

		COR_ESTRUTURA
	)


	# ========================================================
	# PILAR DIREITO
	# ========================================================

	criar_bloco_estatico(
		"PilarPortaoD",

		Vector3(
			6.0,
			altura_hangar,
			4.0
		),

		Vector3(
			largura_portao / 2.0 + 3.0,
			altura_hangar / 2.0,
			frente_z
		),

		COR_ESTRUTURA
	)


	# ========================================================
	# VIGA SUPERIOR
	# ========================================================

	criar_bloco_estatico(
		"VigaSuperiorPortao",

		Vector3(
			largura_portao + 12.0,
			5.0,
			4.0
		),

		Vector3(
			0.0,
			altura_hangar - 2.5,
			frente_z
		),

		COR_ESTRUTURA
	)


	# ========================================================
	# FOLHA MOVEL
	# ========================================================

	folha_portao = AnimatableBody3D.new()

	folha_portao.name = "FolhaPortaoPrincipal"

	folha_portao.position = posicao_fechada

	folha_portao.sync_to_physics = true

	folha_portao.collision_layer = 1

	folha_portao.collision_mask = 1


	add_child(
		folha_portao
	)


	# ========================================================
	# VISUAL
	# ========================================================

	var visual := MeshInstance3D.new()

	visual.name = "Blindagem"


	var mesh := BoxMesh.new()

	mesh.size = Vector3(
		largura_portao,
		altura_portao,
		espessura_portao
	)


	visual.mesh = mesh


	var material := StandardMaterial3D.new()

	material.albedo_color = COR_PORTAO

	material.metallic = 0.72

	material.roughness = 0.32


	visual.material_override = material


	folha_portao.add_child(
		visual
	)


	# ========================================================
	# COLISAO REAL
	# ========================================================

	colisao_portao = CollisionShape3D.new()

	colisao_portao.name = "ColisaoPortao"


	var shape := BoxShape3D.new()

	shape.size = Vector3(
		largura_portao,
		altura_portao,
		espessura_portao
	)


	colisao_portao.shape = shape


	folha_portao.add_child(
		colisao_portao
	)


	# ========================================================
	# REFORCOS
	# ========================================================

	for y in [
		-9.0,
		-4.5,
		0.0,
		4.5,
		9.0
	]:

		criar_detalhe_portao(
			"ReforcoHorizontal",

			Vector3(
				largura_portao - 4.0,
				0.32,
				0.20
			),

			Vector3(
				0.0,
				y,
				-0.68
			),

			COR_PAINEL,
			false
		)


	for x in [
		-52.0,
		-26.0,
		0.0,
		26.0,
		52.0
	]:

		criar_detalhe_portao(
			"ReforcoVertical",

			Vector3(
				0.38,
				altura_portao - 2.0,
				0.20
			),

			Vector3(
				x,
				0.0,
				-0.68
			),

			COR_PAINEL,
			false
		)


	# ========================================================
	# LUZES CIANO
	# ========================================================

	for y in [
		-6.8,
		6.8
	]:

		criar_detalhe_portao(
			"LuzCiano",

			Vector3(
				largura_portao - 12.0,
				0.18,
				0.18
			),

			Vector3(
				0.0,
				y,
				-0.82
			),

			COR_CIANO,
			true,
			4.5
		)


	# ========================================================
	# FAIXA CENTRAL
	# ========================================================

	criar_detalhe_portao(
		"FaixaCentral",

		Vector3(
			34.0,
			0.30,
			0.20
		),

		Vector3(
			0.0,
			0.0,
			-0.84
		),

		COR_LARANJA,
		true,
		5.0
	)



# ============================================================
# BOTAO MANUAL FISICO
# ============================================================

func criar_botao_manual() -> void:


	# ========================================================
	# POSICAO
	#
	# Fica no pilar direito,
	# voltado para o interior do hangar.
	# ========================================================

	var x := (
		largura_portao / 2.0
		+ 3.0
	)


	var pos_painel := Vector3(
		x,
		2.1,
		frente_z + 2.18
	)


	# ========================================================
	# CAIXA DO PAINEL
	# ========================================================

	criar_bloco_estatico(
		"PainelControlePortao",

		Vector3(
			2.4,
			3.2,
			0.40
		),

		pos_painel,

		Color(
			0.035,
			0.05,
			0.07
		)
	)


	# ========================================================
	# BORDA CIANO
	# ========================================================

	criar_bloco_visual_emissivo(
		"BordaPainel",

		Vector3(
			2.0,
			2.7,
			0.08
		),

		pos_painel + Vector3(
			0.0,
			0.0,
			0.25
		),

		Color(
			0.02,
			0.16,
			0.21
		),

		1.0
	)


	# ========================================================
	# BOTAO VERDE 3D
	# ========================================================

	botao_3d = MeshInstance3D.new()

	botao_3d.name = "BotaoAbrirPortao"


	var mesh_botao := BoxMesh.new()

	mesh_botao.size = Vector3(
		1.25,
		0.72,
		0.32
	)


	botao_3d.mesh = mesh_botao


	var mat_botao := StandardMaterial3D.new()

	mat_botao.albedo_color = COR_VERDE

	mat_botao.emission_enabled = true

	mat_botao.emission = COR_VERDE

	mat_botao.emission_energy_multiplier = 5.0

	mat_botao.metallic = 0.20

	mat_botao.roughness = 0.20


	botao_3d.material_override = mat_botao


	botao_3d.position = (
		pos_painel
		+ Vector3(
			0.0,
			0.0,
			0.43
		)
	)


	botao_3d_posicao_normal = (
		botao_3d.position
	)


	add_child(
		botao_3d
	)


	# ========================================================
	# LED DO PAINEL
	# ========================================================

	criar_bloco_visual_emissivo(
		"LedPainelPortao",

		Vector3(
			1.2,
			0.12,
			0.10
		),

		pos_painel + Vector3(
			0.0,
			1.05,
			0.28
		),

		COR_CIANO,
		4.0
	)


	# ========================================================
	# TEXTO
	# ========================================================

	var texto := Label3D.new()

	texto.name = "TextoPainel"

	texto.text = "OPEN"

	texto.position = pos_painel + Vector3(
		0.0,
		-0.82,
		0.40
	)

	texto.rotation_degrees = Vector3(
		0.0,
		180.0,
		0.0
	)

	texto.font_size = 56

	texto.pixel_size = 0.008

	texto.outline_size = 7

	texto.modulate = COR_CIANO

	texto.outline_modulate = Color.BLACK


	add_child(
		texto
	)


	# ========================================================
	# PEQUENA LUZ VERDE
	# ========================================================

	var luz_botao := OmniLight3D.new()

	luz_botao.name = "LuzBotaoManual"

	luz_botao.position = pos_painel + Vector3(
		0.0,
		0.0,
		1.0
	)

	luz_botao.light_color = COR_VERDE

	luz_botao.light_energy = 1.4

	luz_botao.omni_range = 4.0

	luz_botao.shadow_enabled = false


	add_child(
		luz_botao
	)


	# ========================================================
	# SENSOR DE PROXIMIDADE
	# ========================================================

	sensor_botao = Area3D.new()

	sensor_botao.name = "SensorBotaoManual"

	sensor_botao.position = pos_painel + Vector3(
		0.0,
		0.0,
		2.0
	)

	sensor_botao.collision_layer = 0

	sensor_botao.collision_mask = 1

	sensor_botao.monitoring = true

	sensor_botao.monitorable = true


	add_child(
		sensor_botao
	)


	var collision := CollisionShape3D.new()


	var shape := BoxShape3D.new()

	shape.size = Vector3(
		alcance_botao_manual,
		4.5,
		alcance_botao_manual
	)


	collision.shape = shape


	sensor_botao.add_child(
		collision
	)


	sensor_botao.body_entered.connect(
		_on_sensor_botao_body_entered
	)


	sensor_botao.body_exited.connect(
		_on_sensor_botao_body_exited
	)



# ============================================================
# PLAYER ENTROU NA AREA DO BOTAO
# ============================================================

func _on_sensor_botao_body_entered(
	body: Node3D
) -> void:


	if !corpo_e_player_a_pe(
		body
	):

		return


	jogador_perto_botao = true

	atualizar_interface_manual()



# ============================================================
# PLAYER SAIU
# ============================================================

func _on_sensor_botao_body_exited(
	body: Node3D
) -> void:


	if !corpo_e_player_a_pe(
		body
	):

		return


	jogador_perto_botao = false

	atualizar_interface_manual()



# ============================================================
# IDENTIFICAR PERSONAGEM
# ============================================================

func corpo_e_player_a_pe(
	body: Node3D
) -> bool:


	if body.is_in_group(
		"player_on_foot"
	):

		return true


	var nome := body.name.to_lower()


	return (
		"playeronfoot" in nome
		or "player_on_foot" in nome
	)



# ============================================================
# INTERFACE MOBILE / PC
# ============================================================

func criar_interface_manual() -> void:


	canvas_manual = CanvasLayer.new()

	canvas_manual.name = "PortaoManualCanvas"

	canvas_manual.layer = 145


	add_child(
		canvas_manual
	)


	ui_manual = Control.new()

	ui_manual.name = "PortaoManualUI"

	ui_manual.mouse_filter = Control.MOUSE_FILTER_IGNORE


	canvas_manual.add_child(
		ui_manual
	)


	ui_manual.set_anchors_and_offsets_preset(
		Control.PRESET_FULL_RECT
	)


	botao_manual_ui = Button.new()

	botao_manual_ui.name = "AbrirPortao"

	botao_manual_ui.text = "ABRIR PORTAO  [E]"

	botao_manual_ui.focus_mode = Control.FOCUS_NONE


	ui_manual.add_child(
		botao_manual_ui
	)


	botao_manual_ui.set_anchors_preset(
		Control.PRESET_CENTER_BOTTOM
	)


	botao_manual_ui.offset_left = -125.0

	botao_manual_ui.offset_right = 125.0

	botao_manual_ui.offset_top = -115.0

	botao_manual_ui.offset_bottom = -55.0


	botao_manual_ui.add_theme_font_size_override(
		"font_size",
		18
	)


	var normal := StyleBoxFlat.new()

	normal.bg_color = Color(
		0.015,
		0.10,
		0.06,
		0.92
	)

	normal.border_color = COR_VERDE

	normal.set_border_width_all(
		2
	)

	normal.set_corner_radius_all(
		12
	)


	var pressionado := normal.duplicate() as StyleBoxFlat

	pressionado.bg_color = Color(
		0.02,
		0.30,
		0.13,
		0.96
	)


	botao_manual_ui.add_theme_stylebox_override(
		"normal",
		normal
	)

	botao_manual_ui.add_theme_stylebox_override(
		"hover",
		normal
	)

	botao_manual_ui.add_theme_stylebox_override(
		"pressed",
		pressionado
	)


	botao_manual_ui.add_theme_color_override(
		"font_color",
		Color(
			0.72,
			1.0,
			0.82
		)
	)


	botao_manual_ui.pressed.connect(
		acionar_botao_manual
	)


	botao_manual_ui.visible = false



# ============================================================
# ATUALIZAR INTERFACE
# ============================================================

func atualizar_interface_manual() -> void:


	if botao_manual_ui == null:

		return


	botao_manual_ui.visible = (
		jogador_perto_botao
	)


	if tempo_manual_restante > 0.0:

		botao_manual_ui.text = (
			"MANTER PORTAO ABERTO  [E]"
		)

	else:

		botao_manual_ui.text = (
			"ABRIR PORTAO  [E]"
		)



# ============================================================
# INPUT DO TECLADO
# ============================================================

func _unhandled_input(
	event: InputEvent
) -> void:


	if !jogador_perto_botao:

		return


	if event is InputEventKey:

		var tecla := event as InputEventKey


		if (
			tecla.pressed
			and !tecla.echo
			and tecla.keycode == KEY_E
		):

			acionar_botao_manual()

			get_viewport().set_input_as_handled()



# ============================================================
# ACIONAR BOTAO
# ============================================================

func acionar_botao_manual() -> void:


	if !jogador_perto_botao:

		return


	# ========================================================
	# RENOVA O TEMPO MANUAL
	# ========================================================

	tempo_manual_restante = (
		tempo_abertura_manual
	)


	tempo_sem_motor = 0.0


	# ========================================================
	# ABRE
	# ========================================================

	solicitar_abertura()


	# ========================================================
	# ANIMA O BOTAO FISICO
	# ========================================================

	animar_botao_fisico()


	atualizar_interface_manual()


	print(
		"PORTAO: ABERTURA MANUAL ACIONADA."
	)



# ============================================================
# ANIMAR BOTAO 3D
# ============================================================

func animar_botao_fisico() -> void:


	if botao_3d == null:

		return


	var tween := create_tween()


	tween.set_trans(
		Tween.TRANS_QUAD
	)


	tween.tween_property(
		botao_3d,
		"position",

		botao_3d_posicao_normal
		+ Vector3(
			0.0,
			0.0,
			-0.13
		),

		0.10
	)


	tween.tween_property(
		botao_3d,
		"position",
		botao_3d_posicao_normal,
		0.16
	)



# ============================================================
# SISTEMA DE ALERTA
# ============================================================

func criar_sistema_alerta() -> void:


	var faixa := criar_luz_alerta_visual(
		"AlertaSuperior",

		Vector3(
			55.0,
			0.65,
			0.35
		),

		Vector3(
			0.0,
			altura_hangar - 5.4,
			frente_z + 2.25
		)
	)


	alerta_visual.append(
		faixa
	)


	# ========================================================
	# BARRAS LATERAIS
	# ========================================================

	for x in [
		-largura_portao / 2.0 - 3.2,
		largura_portao / 2.0 + 3.2
	]:

		var barra := criar_luz_alerta_visual(
			"AlertaLateral",

			Vector3(
				0.65,
				13.0,
				0.40
			),

			Vector3(
				x,
				13.0,
				frente_z + 2.3
			)
		)


		alerta_visual.append(
			barra
		)


	# ========================================================
	# BALIZAS
	# ========================================================

	for x in [
		-largura_portao / 2.0 - 3.4,
		largura_portao / 2.0 + 3.4
	]:

		for y in [
			5.0,
			14.0,
			23.0
		]:

			var baliza := criar_baliza_vermelha(
				Vector3(
					x,
					y,
					frente_z + 2.6
				)
			)


			alerta_visual.append(
				baliza
			)


	# ========================================================
	# LUZ REAL VERMELHA
	# ========================================================

	for x in [
		-48.0,
		48.0
	]:

		var luz := OmniLight3D.new()

		luz.name = "LuzAlertaVermelho"

		luz.position = Vector3(
			x,
			16.0,
			frente_z + 6.0
		)

		luz.light_color = COR_VERMELHO

		luz.light_energy = energia_luz_alerta

		luz.omni_range = 22.0

		luz.shadow_enabled = false


		add_child(
			luz
		)


		alerta_luzes.append(
			luz
		)



# ============================================================
# PROCESS
# ============================================================

func _process(
	delta: float
) -> void:


	if hangar == null:

		return


	if mobile_controls == null:

		localizar_sistemas()


	# ========================================================
	# ALERTA
	# ========================================================

	atualizar_alerta(
		delta
	)


	# ========================================================
	# TEMPO MANUAL
	# ========================================================

	if tempo_manual_restante > 0.0:

		tempo_manual_restante -= delta


		if tempo_manual_restante < 0.0:

			tempo_manual_restante = 0.0


		atualizar_interface_manual()


	# ========================================================
	# ALGUM MOTOR LIGADO
	# ========================================================

	if algum_motor_ligado():

		tempo_sem_motor = 0.0

		solicitar_abertura()

		return


	# ========================================================
	# ABERTURA MANUAL AINDA ATIVA
	# ========================================================

	if tempo_manual_restante > 0.0:

		tempo_sem_motor = 0.0

		solicitar_abertura()

		return


	# ========================================================
	# NENHUM MOTOR
	# ========================================================

	tempo_sem_motor += delta


	if tempo_sem_motor < atraso_fechamento:

		return


	# ========================================================
	# SEGURANCA
	# ========================================================

	if zona_portao_ocupada():

		solicitar_abertura()

		return


	solicitar_fechamento()



# ============================================================
# EXISTE ALGUM MOTOR LIGADO?
# ============================================================

func algum_motor_ligado() -> bool:

	return (
		motor_p01_ligado()

		or motor_nave_ligado(
			"P02"
		)

		or motor_nave_ligado(
			"P03"
		)

		or motor_nave_ligado(
			"P04"
		)
	)



# ============================================================
# MOTOR P-01
# ============================================================

func motor_p01_ligado() -> bool:


	if mobile_controls == null:

		return false


	var modo_pe: Variant = mobile_controls.get(
		"modo_a_pe"
	)


	if (
		modo_pe != null
		and bool(
			modo_pe
		)
	):

		return false


	var pedal: Variant = mobile_controls.get(
		"pedal_pressionado"
	)


	if (
		pedal != null
		and bool(
			pedal
		)
	):

		return true


	var velocidade: Variant = mobile_controls.get(
		"velocidade_efetiva"
	)


	if velocidade != null:

		if float(
			velocidade
		) > limite_motor_p01:

			return true


	return false



# ============================================================
# P02 / P03 / P04
# ============================================================

func motor_nave_ligado(
	nome: String
) -> bool:


	if bool(
		motores_naves.get(
			nome,
			false
		)
	):

		return true


	var nave := encontrar_nave_estacionada(
		nome
	)


	if nave != null:

		return bool(
			nave.get_meta(
				"motor_ligado",
				false
			)
		)


	return false



# ============================================================
# DEFINIR MOTOR DAS OUTRAS NAVES
# ============================================================

func set_motor_nave(
	nome: String,
	ligado: bool
) -> void:


	if !motores_naves.has(
		nome
	):

		return


	motores_naves[nome] = ligado


	var nave := encontrar_nave_estacionada(
		nome
	)


	if nave != null:

		nave.set_meta(
			"motor_ligado",
			ligado
		)


	if ligado:

		tempo_sem_motor = 0.0

		solicitar_abertura()



# ============================================================
# ENCONTRAR NAVES
# ============================================================

func encontrar_nave_estacionada(
	nome: String
) -> Node3D:


	if hangar == null:

		return null


	var nome_real := ""


	match nome:

		"P02":

			nome_real = "P02_InterceptorPatrulha"


		"P03":

			nome_real = "P03_CargueiroMilitar"


		"P04":

			nome_real = "P04_CacaAvancado"


		_:

			return null


	var encontrado := hangar.find_child(
		nome_real,
		true,
		false
	)


	if encontrado is Node3D:

		return encontrado


	return null



# ============================================================
# ABRIR
# ============================================================

func solicitar_abertura() -> void:


	if alvo_aberto:

		return


	alvo_aberto = true

	abrindo_agora = true


	animar_portao(
		posicao_aberta,
		true
	)



# ============================================================
# FECHAR
# ============================================================

func solicitar_fechamento() -> void:


	if !alvo_aberto:

		return


	alvo_aberto = false

	abrindo_agora = false


	desligar_alerta()


	animar_portao(
		posicao_fechada,
		false
	)



# ============================================================
# ANIMACAO PORTAO
# ============================================================

func animar_portao(
	destino: Vector3,
	abrindo: bool
) -> void:


	if folha_portao == null:

		return


	if tween_portao != null:

		if tween_portao.is_valid():

			tween_portao.kill()


	portao_movendo = true


	if abrindo:

		abrindo_agora = true

		tempo_pisca = velocidade_pisca

		alerta_ligado = true

		aplicar_estado_alerta(
			true
		)


	tween_portao = create_tween()


	tween_portao.set_trans(
		Tween.TRANS_QUAD
	)

	tween_portao.set_ease(
		Tween.EASE_IN_OUT
	)


	tween_portao.tween_property(
		folha_portao,
		"position",
		destino,
		tempo_abertura
	)


	tween_portao.finished.connect(

		func() -> void:

			portao_movendo = false

			portao_aberto = abrindo


			if abrindo:

				abrindo_agora = false

				desligar_alerta()

				print(
					"PORTAO: ABERTO."
				)

			else:

				print(
					"PORTAO: FECHADO."
				)

	)



# ============================================================
# ALERTA PISCANTE
# ============================================================

func atualizar_alerta(
	delta: float
) -> void:


	if (
		!portao_movendo
		or !abrindo_agora
	):

		if alerta_ligado:

			desligar_alerta()

		return


	tempo_pisca += delta


	if tempo_pisca < velocidade_pisca:

		return


	tempo_pisca = 0.0

	alerta_ligado = !alerta_ligado


	aplicar_estado_alerta(
		alerta_ligado
	)



func aplicar_estado_alerta(
	ligado: bool
) -> void:


	for objeto in alerta_visual:

		if (
			objeto != null
			and is_instance_valid(
				objeto
			)
		):

			objeto.visible = ligado


	for luz in alerta_luzes:

		if (
			luz != null
			and is_instance_valid(
				luz
			)
		):

			luz.visible = ligado


			luz.light_energy = (
				energia_luz_alerta
				if ligado
				else 0.0
			)



func desligar_alerta() -> void:

	alerta_ligado = false

	tempo_pisca = 0.0


	aplicar_estado_alerta(
		false
	)



# ============================================================
# SEGURANCA
# ============================================================

func zona_portao_ocupada() -> bool:


	if player != null:

		if objeto_perto_portao(
			player
		):

			return true


	if cena != null:

		var pe := cena.find_child(
			"PlayerOnFoot",
			true,
			false
		)


		if pe is Node3D:

			if pe.visible:

				if objeto_perto_portao(
					pe
				):

					return true


	return false



func objeto_perto_portao(
	objeto: Node3D
) -> bool:


	var local := hangar.to_local(
		objeto.global_position
	)


	return (
		absf(
			local.z
			- frente_z
		)
		<= distancia_seguranca_portao

		and absf(
			local.x
		)
		<= largura_portao / 2.0
		+ 5.0
	)



# ============================================================
# BLOCOS FISICOS
# ============================================================

func criar_bloco_estatico(
	nome: String,
	tamanho: Vector3,
	posicao: Vector3,
	cor: Color
) -> void:


	var corpo := StaticBody3D.new()

	corpo.name = nome

	corpo.position = posicao

	corpo.collision_layer = 1

	corpo.collision_mask = 1


	add_child(
		corpo
	)


	var visual := MeshInstance3D.new()


	var mesh := BoxMesh.new()

	mesh.size = tamanho


	visual.mesh = mesh


	var material := StandardMaterial3D.new()

	material.albedo_color = cor

	material.metallic = 0.65

	material.roughness = 0.36


	visual.material_override = material


	corpo.add_child(
		visual
	)


	var collision := CollisionShape3D.new()


	var shape := BoxShape3D.new()

	shape.size = tamanho


	collision.shape = shape


	corpo.add_child(
		collision
	)



# ============================================================
# BLOCO VISUAL EMISSIVO
# ============================================================

func criar_bloco_visual_emissivo(
	nome: String,
	tamanho: Vector3,
	posicao: Vector3,
	cor: Color,
	intensidade: float
) -> MeshInstance3D:


	var visual := MeshInstance3D.new()

	visual.name = nome

	visual.position = posicao


	var mesh := BoxMesh.new()

	mesh.size = tamanho


	visual.mesh = mesh


	var material := StandardMaterial3D.new()

	material.albedo_color = cor

	material.emission_enabled = true

	material.emission = cor

	material.emission_energy_multiplier = intensidade

	material.metallic = 0.25

	material.roughness = 0.20


	visual.material_override = material


	add_child(
		visual
	)


	return visual



# ============================================================
# DETALHES PORTAO
# ============================================================

func criar_detalhe_portao(
	nome: String,
	tamanho: Vector3,
	posicao: Vector3,
	cor: Color,
	emissivo: bool,
	intensidade: float = 1.0
) -> void:


	var visual := MeshInstance3D.new()

	visual.name = nome

	visual.position = posicao


	var mesh := BoxMesh.new()

	mesh.size = tamanho


	visual.mesh = mesh


	var material := StandardMaterial3D.new()

	material.albedo_color = cor

	material.metallic = 0.45

	material.roughness = 0.28


	if emissivo:

		material.emission_enabled = true

		material.emission = cor

		material.emission_energy_multiplier = intensidade


	visual.material_override = material


	folha_portao.add_child(
		visual
	)



# ============================================================
# LUZ ALERTA
# ============================================================

func criar_luz_alerta_visual(
	nome: String,
	tamanho: Vector3,
	posicao: Vector3
) -> Node3D:


	var visual := MeshInstance3D.new()

	visual.name = nome

	visual.position = posicao


	var mesh := BoxMesh.new()

	mesh.size = tamanho


	visual.mesh = mesh


	var material := StandardMaterial3D.new()

	material.albedo_color = COR_VERMELHO

	material.emission_enabled = true

	material.emission = COR_VERMELHO

	material.emission_energy_multiplier = 10.0


	visual.material_override = material


	add_child(
		visual
	)


	return visual



# ============================================================
# BALIZA
# ============================================================

func criar_baliza_vermelha(
	posicao: Vector3
) -> Node3D:


	var visual := MeshInstance3D.new()

	visual.position = posicao


	var mesh := SphereMesh.new()

	mesh.radius = 0.48

	mesh.height = 0.96

	mesh.radial_segments = 12

	mesh.rings = 8


	visual.mesh = mesh


	var material := StandardMaterial3D.new()

	material.albedo_color = COR_VERMELHO

	material.emission_enabled = true

	material.emission = COR_VERMELHO

	material.emission_energy_multiplier = 12.0


	visual.material_override = material


	add_child(
		visual
	)


	return visual
