extends Node


# =========================================================
# LAST SECOND - POLICE DISPATCH v3.0
#
# - Central policial
# - Procura Marte
# - Cria uma nave REAL perto de Marte
# - Distancia ate a nave
# - Objetivos da ocorrencia
# =========================================================


const SUSPECT_SHIP_SCRIPT = preload(
	"res://suspect_ship.gd"
)


@export var nome_agencia: String = (
	"POLICIA INTERPLANETARIA"
)

@export var identificacao_unidade: String = "P-01"

@export var setor_patrulha: String = "TERRA / MARTE"

@export var tempo_primeira_ocorrencia: float = 10.0

@export var unidades_por_km: float = 1.0


var player: Node3D = null

var solar_system: Node3D = null

var marte: Node3D = null

var nave_suspeita: Node3D = null


# =========================================================
# HUD
# =========================================================

var canvas: CanvasLayer = null

var painel: ColorRect = null

var barra_superior: ColorRect = null

var label_agencia: Label = null

var label_unidade: Label = null

var label_status: Label = null

var label_setor: Label = null

var label_central: Label = null

var label_ocorrencia: Label = null

var label_alvo: Label = null

var label_distancia: Label = null

var label_prioridade: Label = null

var label_objetivo: Label = null


# =========================================================
# ESTADOS
# =========================================================

enum EstadoOcorrencia {
	SEM_OCORRENCIA,
	DESPACHADA,
	APROXIMANDO,
	PROXIMO,
	ABORDAGEM
}


var estado_ocorrencia: int = (
	EstadoOcorrencia.SEM_OCORRENCIA
)


var ocorrencia_ativa: bool = false

var tempo_alerta: float = 0.0


# =========================================================
# READY
# =========================================================

func _ready() -> void:

	call_deferred(
		"iniciar_sistema"
	)


# =========================================================
# INICIAR
# =========================================================

func iniciar_sistema() -> void:

	await get_tree().process_frame

	await get_tree().process_frame


	player = get_node_or_null(
		"../Player"
	) as Node3D


	solar_system = get_node_or_null(
		"../SolarSystem"
	) as Node3D


	if player == null:

		push_warning(
			"PoliceDispatch: Player nao encontrado."
		)

		return


	if solar_system == null:

		push_warning(
			"PoliceDispatch: SolarSystem nao encontrado."
		)

		return


	# =====================================================
	# ESPERAR MARTE SER CRIADO
	# =====================================================

	for tentativa: int in range(
		180
	):

		marte = encontrar_planeta(
			"Marte"
		)


		if marte != null:

			break


		await get_tree().process_frame


	if marte == null:

		push_warning(
			"PoliceDispatch: Marte nao foi encontrado."
		)

		return


	print(
		"POLICE DISPATCH: MARTE ENCONTRADO"
	)


	print(
		"Posicao Marte: ",
		marte.global_position
	)


	criar_hud()


	label_status.text = (
		"STATUS: INICIALIZANDO SISTEMAS"
	)


	label_central.text = (
		"CENTRAL: CONECTANDO..."
	)


	await get_tree().create_timer(
		2.0
	).timeout


	label_status.text = (
		"STATUS: EM PATRULHA"
	)


	label_central.text = (
		"CENTRAL: CONEXAO ESTABELECIDA"
	)


	barra_superior.color = Color(
		0.08,
		0.55,
		0.92,
		1.0
	)


	await get_tree().create_timer(
		tempo_primeira_ocorrencia
	).timeout


	despachar_ocorrencia()


# =========================================================
# PROCESS
# =========================================================

func _process(delta: float) -> void:

	if !ocorrencia_ativa:
		return


	tempo_alerta += delta


	atualizar_ocorrencia()

	animar_alerta()


# =========================================================
# DESPACHAR
# =========================================================

func despachar_ocorrencia() -> void:

	if marte == null:

		label_central.text = (
			"CENTRAL: MARTE NAO LOCALIZADO"
		)

		return


	criar_nave_suspeita()


	if nave_suspeita == null:

		label_central.text = (
			"CENTRAL: ERRO AO GERAR ALVO"
		)

		return


	ocorrencia_ativa = true


	estado_ocorrencia = (
		EstadoOcorrencia.DESPACHADA
	)


	label_central.text = (
		"⚠ NOVA OCORRENCIA"
	)


	label_ocorrencia.text = (
		"NAVE NAO IDENTIFICADA"
	)


	label_alvo.text = (
		"SETOR: PROXIMO A MARTE"
	)


	label_prioridade.text = (
		"PRIORIDADE: MEDIA"
	)


	label_objetivo.text = (
		"OBJETIVO: DIRIJA-SE AO ALVO"
	)


	print(
		"================================"
	)


	print(
		"OCORRENCIA CRIADA"
	)


	print(
		"NAVE SUSPEITA EM: ",
		nave_suspeita.global_position
	)


	print(
		"MARTE EM: ",
		marte.global_position
	)


	print(
		"================================"
	)


# =========================================================
# CRIAR NAVE
# =========================================================

func criar_nave_suspeita() -> void:

	if nave_suspeita != null:

		if is_instance_valid(
			nave_suspeita
		):

			return


	var instancia: Node = (
		SUSPECT_SHIP_SCRIPT.new()
	)


	if !(instancia is Node3D):

		push_warning(
			"PoliceDispatch: SuspectShip nao e Node3D."
		)

		return


	nave_suspeita = (
		instancia as Node3D
	)


	nave_suspeita.name = "NaveSuspeita"


	# =====================================================
	# IMPORTANTE:
	# ADICIONAMOS NO SOLAR SYSTEM
	# PARA GARANTIR QUE ESTEJA NO MUNDO 3D
	# =====================================================

	solar_system.add_child(
		nave_suspeita
	)


	# =====================================================
	# DEIXAR A NAVE GRANDE O SUFICIENTE
	# PARA SER VISTA AO SE APROXIMAR
	# =====================================================

	nave_suspeita.scale = Vector3(
		2.6,
		2.6,
		2.6
	)


	# =====================================================
	# POSICAO PERTO DE MARTE
	# =====================================================

	var posicao_alvo: Vector3 = (
		marte.global_position
		+
		Vector3(
			320.0,
			80.0,
			220.0
		)
	)


	if nave_suspeita.has_method(
		"definir_ponto_patrulha"
	):

		nave_suspeita.call(
			"definir_ponto_patrulha",
			posicao_alvo
		)

	else:

		nave_suspeita.global_position = (
			posicao_alvo
		)


	print(
		"NAVE SUSPEITA CRIADA COM SUCESSO"
	)


# =========================================================
# ATUALIZAR OCORRENCIA
# =========================================================

func atualizar_ocorrencia() -> void:

	if player == null:
		return


	if nave_suspeita == null:
		return


	if !is_instance_valid(
		nave_suspeita
	):
		return


	var distancia: float = (
		player.global_position.distance_to(
			nave_suspeita.global_position
		)
	)


	label_distancia.text = (
		"DISTANCIA DO ALVO: "
		+
		formatar_distancia(
			distancia
		)
	)


	# =====================================================
	# LONGE
	# =====================================================

	if distancia > 2000.0:

		estado_ocorrencia = (
			EstadoOcorrencia.DESPACHADA
		)


		label_objetivo.text = (
			"OBJETIVO: DIRIJA-SE A MARTE"
		)


		return


	# =====================================================
	# SETOR
	# =====================================================

	if distancia > 700.0:

		if estado_ocorrencia != (
			EstadoOcorrencia.APROXIMANDO
		):

			estado_ocorrencia = (
				EstadoOcorrencia.APROXIMANDO
			)


			label_central.text = (
				"CENTRAL: SINAL DO ALVO DETECTADO"
			)


		label_objetivo.text = (
			"OBJETIVO: SIGA O MARCADOR"
		)


		return


	# =====================================================
	# VISUAL
	# =====================================================

	if distancia > 220.0:

		if estado_ocorrencia != (
			EstadoOcorrencia.PROXIMO
		):

			estado_ocorrencia = (
				EstadoOcorrencia.PROXIMO
			)


			label_central.text = (
				"CENTRAL: CONTATO VISUAL POSSIVEL"
			)


			label_prioridade.text = (
				"PRIORIDADE: ATENCAO"
			)


		label_objetivo.text = (
			"OBJETIVO: APROXIME-SE DA NAVE"
		)


		return


	# =====================================================
	# ABORDAGEM
	# =====================================================

	if estado_ocorrencia != (
		EstadoOcorrencia.ABORDAGEM
	):

		estado_ocorrencia = (
			EstadoOcorrencia.ABORDAGEM
		)


		label_central.text = (
			"◆ ALVO EM ALCANCE"
		)


		label_prioridade.text = (
			"PRIORIDADE: ABORDAGEM"
		)


		label_objetivo.text = (
			"OBJETIVO: PREPARE O SCANNER"
		)


# =========================================================
# ALERTA
# =========================================================

func animar_alerta() -> void:

	if barra_superior == null:
		return


	var pulso: float = (
		sin(
			tempo_alerta * 5.0
		)
		+
		1.0
	) * 0.5


	var alpha: float = lerpf(
		0.65,
		1.0,
		pulso
	)


	if estado_ocorrencia >= (
		EstadoOcorrencia.PROXIMO
	):

		barra_superior.color = Color(
			0.95,
			0.20,
			0.08,
			alpha
		)

	else:

		barra_superior.color = Color(
			0.20,
			0.72,
			1.0,
			alpha
		)


# =========================================================
# DISTANCIA
# =========================================================

func formatar_distancia(
	distancia: float
) -> String:

	var distancia_km: float = (
		distancia
		/
		maxf(
			unidades_por_km,
			0.001
		)
	)


	if distancia_km < 1000.0:

		return (
			"%.0f km"
			%
			distancia_km
		)


	return (
		"%.2f mil km"
		%
		(
			distancia_km
			/
			1000.0
		)
	)


# =========================================================
# HUD
# =========================================================

func criar_hud() -> void:

	canvas = CanvasLayer.new()


	canvas.name = "PoliceHUD"

	canvas.layer = 40


	add_child(
		canvas
	)


	painel = ColorRect.new()


	painel.name = "PolicePanel"


	painel.position = Vector2(
		22.0,
		22.0
	)


	painel.size = Vector2(
		430.0,
		285.0
	)


	painel.color = Color(
		0.015,
		0.035,
		0.060,
		0.82
	)


	painel.mouse_filter = (
		Control.MOUSE_FILTER_IGNORE
	)


	canvas.add_child(
		painel
	)


	barra_superior = ColorRect.new()


	barra_superior.position = Vector2.ZERO


	barra_superior.size = Vector2(
		430.0,
		5.0
	)


	barra_superior.color = Color(
		0.08,
		0.55,
		0.92,
		1.0
	)


	painel.add_child(
		barra_superior
	)


	label_agencia = criar_label(
		nome_agencia,
		Vector2(
			18.0,
			14.0
		),
		21,
		Color(
			0.42,
			0.85,
			1.0,
			1.0
		)
	)


	label_unidade = criar_label(
		"UNIDADE " + identificacao_unidade,
		Vector2(
			18.0,
			43.0
		),
		15,
		Color(
			0.72,
			0.88,
			0.96,
			1.0
		)
	)


	label_status = criar_label(
		"STATUS: OFFLINE",
		Vector2(
			18.0,
			70.0
		),
		14,
		Color(
			0.38,
			0.95,
			0.62,
			1.0
		)
	)


	label_setor = criar_label(
		"SETOR: "
		+
		setor_patrulha,
		Vector2(
			18.0,
			92.0
		),
		14,
		Color(
			0.58,
			0.74,
			0.84,
			1.0
		)
	)


	label_central = criar_label(
		"CENTRAL: AGUARDANDO...",
		Vector2(
			18.0,
			126.0
		),
		17,
		Color(
			1.0,
			0.72,
			0.24,
			1.0
		)
	)


	label_ocorrencia = criar_label(
		"NENHUMA OCORRENCIA ATIVA",
		Vector2(
			18.0,
			154.0
		),
		15,
		Color(
			0.88,
			0.92,
			0.96,
			1.0
		)
	)


	label_alvo = criar_label(
		"SETOR: ---",
		Vector2(
			18.0,
			178.0
		),
		14,
		Color(
			0.60,
			0.81,
			0.93,
			1.0
		)
	)


	label_distancia = criar_label(
		"DISTANCIA DO ALVO: ---",
		Vector2(
			18.0,
			201.0
		),
		14,
		Color(
			0.46,
			0.89,
			1.0,
			1.0
		)
	)


	label_prioridade = criar_label(
		"PRIORIDADE: ---",
		Vector2(
			18.0,
			224.0
		),
		14,
		Color(
			1.0,
			0.58,
			0.24,
			1.0
		)
	)


	label_objetivo = criar_label(
		"OBJETIVO: PATRULHAMENTO PREVENTIVO",
		Vector2(
			18.0,
			249.0
		),
		13,
		Color(
			0.78,
			0.86,
			0.91,
			1.0
		)
	)


# =========================================================
# CRIAR TEXTO
# =========================================================

func criar_label(
	texto: String,
	posicao: Vector2,
	tamanho: int,
	cor: Color
) -> Label:

	var label: Label = Label.new()


	label.text = texto

	label.position = posicao


	label.size = Vector2(
		395.0,
		28.0
	)


	label.mouse_filter = (
		Control.MOUSE_FILTER_IGNORE
	)


	label.add_theme_font_size_override(
		"font_size",
		tamanho
	)


	label.add_theme_color_override(
		"font_color",
		cor
	)


	label.add_theme_color_override(
		"font_outline_color",
		Color(
			0.0,
			0.0,
			0.0,
			0.95
		)
	)


	label.add_theme_constant_override(
		"outline_size",
		3
	)


	painel.add_child(
		label
	)


	return label


# =========================================================
# ENCONTRAR PLANETA
# =========================================================

func encontrar_planeta(
	nome_planeta: String
) -> Node3D:

	if solar_system == null:
		return null


	var resultado: Node = (
		encontrar_node_recursivo(
			solar_system,
			nome_planeta
		)
	)


	if resultado is Node3D:

		return resultado as Node3D


	return null


# =========================================================
# BUSCA RECURSIVA
# =========================================================

func encontrar_node_recursivo(
	no_atual: Node,
	nome_procurado: String
) -> Node:

	if String(
		no_atual.name
	) == nome_procurado:

		return no_atual


	for filho: Node in no_atual.get_children():

		var resultado: Node = (
			encontrar_node_recursivo(
				filho,
				nome_procurado
			)
		)


		if resultado != null:

			return resultado


	return null
