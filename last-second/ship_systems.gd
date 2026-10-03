extends Control


# =========================================================
# LAST SECOND - SHIP SYSTEMS v2.0
# SEQUENCIA AUTOMATICA DE INICIALIZACAO
# =========================================================


enum Estado {
	POWER_OFF,
	POWER_ON,
	ENGINE_STARTING,
	ENGINE_READY,
	LAUNCHING,
	FLIGHT
}


var estado: int = Estado.POWER_OFF


var player: Node = null
var cockpit_fx: Control = null
var sound_manager: Node = null

var engine_audio: AudioStreamPlayer = null


# =========================================================
# READY
# =========================================================

func _ready() -> void:

	player = get_node_or_null(
		"../Player"
	)

	cockpit_fx = get_node_or_null(
		"../CockpitFX"
	) as Control

	sound_manager = get_node_or_null(
		"../SoundManager"
	)


	preparar_nave_desligada()


	# Comeca automaticamente depois que toda a cena carregar.
	call_deferred(
		"iniciar_sequencia_automatica"
	)


# =========================================================
# NAVE COMECA TOTALMENTE DESLIGADA
# =========================================================

func preparar_nave_desligada() -> void:

	estado = Estado.POWER_OFF


	# =====================================================
	# PLAYER PARADO
	# =====================================================

	if player != null:

		player.set(
			"velocidade_atual",
			0.0
		)

		player.process_mode = (
			Node.PROCESS_MODE_DISABLED
		)


	# =====================================================
	# HUD / COCKPIT DESLIGADO
	# =====================================================

	if cockpit_fx != null:

		cockpit_fx.visible = false

		cockpit_fx.process_mode = (
			Node.PROCESS_MODE_DISABLED
		)


	# =====================================================
	# MOTOR SEM SOM
	# =====================================================

	if sound_manager != null:

		engine_audio = encontrar_audio_motor(
			sound_manager
		)


		if engine_audio != null:

			engine_audio.volume_db = -60.0


		sound_manager.process_mode = (
			Node.PROCESS_MODE_DISABLED
		)


	# =====================================================
	# LUZES DO COCKPIT DESLIGADAS
	# =====================================================

	definir_luzes_player(
		player,
		false
	)


	print(
		"NAVE: SISTEMAS DESLIGADOS"
	)


# =========================================================
# SEQUENCIA AUTOMATICA
# =========================================================

func iniciar_sequencia_automatica() -> void:

	# =====================================================
	# 1 - NAVE FICA APAGADA POR ALGUNS SEGUNDOS
	# =====================================================

	await get_tree().create_timer(
		2.5
	).timeout


	ligar_energia()


	# =====================================================
	# 2 - PAUSA COM PAINEL LIGADO
	# =====================================================

	await get_tree().create_timer(
		2.2
	).timeout


	iniciar_motor()


	# =====================================================
	# 3 - MOTOR GANHANDO VIDA
	# =====================================================

	await get_tree().create_timer(
		3.0
	).timeout


	motor_pronto()


	# =====================================================
	# 4 - MOTOR ESTABILIZADO
	# =====================================================

	await get_tree().create_timer(
		2.0
	).timeout


	preparar_lancamento()


	# =====================================================
	# 5 - PORTA DO HANGAR ABRINDO
	#
	# LaunchBay detecta o estado LAUNCHING
	# e abre automaticamente a porta.
	# =====================================================

	await get_tree().create_timer(
		3.2
	).timeout


	iniciar_voo()


# =========================================================
# LIGAR ENERGIA
# =========================================================

func ligar_energia() -> void:

	if estado != Estado.POWER_OFF:
		return


	estado = Estado.POWER_ON


	print(
		"NAVE: ENERGIA PRINCIPAL LIGADA"
	)


	# =====================================================
	# PAINEL ACENDE
	# =====================================================

	if cockpit_fx != null:

		cockpit_fx.visible = true

		cockpit_fx.process_mode = (
			Node.PROCESS_MODE_INHERIT
		)


	# =====================================================
	# LUZES INTERNAS
	# =====================================================

	definir_luzes_player(
		player,
		true
	)


# =========================================================
# INICIAR MOTOR
# =========================================================

func iniciar_motor() -> void:

	if estado != Estado.POWER_ON:
		return


	estado = Estado.ENGINE_STARTING


	print(
		"NAVE: INICIANDO MOTOR"
	)


	if sound_manager == null:
		return


	sound_manager.process_mode = (
		Node.PROCESS_MODE_INHERIT
	)


	engine_audio = encontrar_audio_motor(
		sound_manager
	)


	if engine_audio == null:
		return


	engine_audio.volume_db = -35.0


	var tween: Tween = create_tween()


	tween.tween_property(
		engine_audio,
		"volume_db",
		-5.0,
		2.8
	)


# =========================================================
# MOTOR PRONTO
# =========================================================

func motor_pronto() -> void:

	if estado != Estado.ENGINE_STARTING:
		return


	estado = Estado.ENGINE_READY


	print(
		"NAVE: MOTOR PRONTO"
	)


# =========================================================
# PREPARAR LANCAMENTO
# =========================================================

func preparar_lancamento() -> void:

	if estado != Estado.ENGINE_READY:
		return


	estado = Estado.LAUNCHING


	print(
		"NAVE: PREPARANDO DECOLAGEM"
	)


# =========================================================
# COMECA A SAIR DO HANGAR
# =========================================================

func iniciar_voo() -> void:

	if estado != Estado.LAUNCHING:
		return


	# Primeiro deixamos a velocidade zerada.
	if player != null:

		player.set(
			"velocidade_atual",
			0.0
		)


	# Muda para voo.
	estado = Estado.FLIGHT


	# Somente agora o Player volta a processar.
	# O player.gd ja possui aceleracao suavizada,
	# entao a nave sai do zero e ganha velocidade.
	if player != null:

		player.process_mode = (
			Node.PROCESS_MODE_INHERIT
		)


	print(
		"NAVE: DECOLAGEM"
	)


# =========================================================
# PROCURAR AUDIO DO MOTOR
# =========================================================

func encontrar_audio_motor(
	no_atual: Node
) -> AudioStreamPlayer:

	if no_atual == null:
		return null


	if no_atual is AudioStreamPlayer:

		var audio := (
			no_atual as AudioStreamPlayer
		)


		var nome_audio: String = (
			String(
				audio.name
			)
			.to_lower()
		)


		if (
			nome_audio.contains("engine")
			or
			nome_audio.contains("motor")
			or
			nome_audio.contains("spaceship")
		):

			return audio


	for filho: Node in no_atual.get_children():

		var resultado: AudioStreamPlayer = (
			encontrar_audio_motor(
				filho
			)
		)


		if resultado != null:
			return resultado


	return null


# =========================================================
# LIGAR / DESLIGAR LUZES DO PLAYER
# =========================================================

func definir_luzes_player(
	no_atual: Node,
	ligadas: bool
) -> void:

	if no_atual == null:
		return


	for filho: Node in no_atual.get_children():

		if filho is Light3D:

			var luz := (
				filho as Light3D
			)

			luz.visible = ligadas


		definir_luzes_player(
			filho,
			ligadas
		)
