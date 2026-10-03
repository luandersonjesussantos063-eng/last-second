extends Node


# =========================================================
# LAST SECOND - LAUNCH AUDIO v2.1
# SEM COMANDOS DE VOZ
# =========================================================


const MIX_RATE: float = 32000.0


# =========================================================
# ESTADOS
# =========================================================

const POWER_OFF: int = 0
const POWER_ON: int = 1
const ENGINE_STARTING: int = 2
const ENGINE_READY: int = 3
const LAUNCHING: int = 4
const FLIGHT: int = 5


var ship_systems: Node = null
var estado_anterior: int = -1


# =========================================================
# SIRENE
# =========================================================

var sirene_player: AudioStreamPlayer = null
var sirene_generator: AudioStreamGenerator = null
var sirene_playback: AudioStreamGeneratorPlayback = null

var sirene_ativa: bool = false

var sirene_fase: float = 0.0
var sirene_fase_2: float = 0.0
var sirene_modulacao: float = 0.0


# =========================================================
# PORTA
# =========================================================

var porta_player: AudioStreamPlayer = null
var porta_generator: AudioStreamGenerator = null
var porta_playback: AudioStreamGeneratorPlayback = null

var porta_ativa: bool = false
var porta_tempo: float = 0.0
var porta_duracao: float = 2.7

var porta_fase_1: float = 0.0
var porta_fase_2: float = 0.0
var porta_fase_3: float = 0.0
var porta_fase_4: float = 0.0

var impacto_restante: float = 0.0
var impacto_fase: float = 0.0


# =========================================================
# BEEP
# =========================================================

var beep_player: AudioStreamPlayer = null
var beep_generator: AudioStreamGenerator = null
var beep_playback: AudioStreamGeneratorPlayback = null

var beep_restante: float = 0.0
var beep_fase: float = 0.0
var beep_frequencia: float = 800.0


# =========================================================
# READY
# =========================================================

func _ready() -> void:

	ship_systems = get_node_or_null(
		"../ShipSystems"
	)

	criar_sirene()

	criar_som_porta()

	criar_beep()

	print("LaunchAudio carregado - comandos de voz desativados.")


# =========================================================
# PROCESS
# =========================================================

func _process(delta: float) -> void:

	atualizar_estado()

	atualizar_porta(delta)

	atualizar_beep(delta)

	preencher_sirene()

	preencher_porta()

	preencher_beep()


# =========================================================
# ESTADOS DA NAVE
# =========================================================

func atualizar_estado() -> void:

	if ship_systems == null:

		ship_systems = get_node_or_null(
			"../ShipSystems"
		)

		if ship_systems == null:
			return


	var valor_estado: Variant = ship_systems.get(
		"estado"
	)

	if valor_estado == null:
		return


	var estado_atual: int = int(
		valor_estado
	)


	if estado_atual == estado_anterior:
		return


	estado_anterior = estado_atual


	match estado_atual:

		POWER_ON:

			som_confirmacao(
				720.0
			)


		ENGINE_STARTING:

			som_confirmacao(
				540.0
			)


		ENGINE_READY:

			motor_pronto()


		LAUNCHING:

			iniciar_lancamento()


		FLIGHT:

			finalizar_lancamento()


# =========================================================
# MOTOR PRONTO
# =========================================================

func motor_pronto() -> void:

	som_confirmacao(
		980.0
	)

	await get_tree().create_timer(
		0.12
	).timeout

	som_confirmacao(
		1220.0
	)


# =========================================================
# LANÇAMENTO
# =========================================================

func iniciar_lancamento() -> void:

	sirene_ativa = true

	porta_ativa = true

	porta_tempo = 0.0


	som_confirmacao(
		1150.0
	)


# =========================================================
# VOO
# =========================================================

func finalizar_lancamento() -> void:

	sirene_ativa = false

	porta_ativa = false


	som_confirmacao(
		1450.0
	)


	await get_tree().create_timer(
		0.16
	).timeout


	som_confirmacao(
		1780.0
	)


# =========================================================
# CRIAR SIRENE
# =========================================================

func criar_sirene() -> void:

	sirene_generator = AudioStreamGenerator.new()

	sirene_generator.mix_rate = MIX_RATE
	sirene_generator.buffer_length = 0.25


	sirene_player = AudioStreamPlayer.new()

	sirene_player.name = "LaunchSiren"

	sirene_player.stream = sirene_generator
	sirene_player.volume_db = -5.0


	add_child(
		sirene_player
	)


	sirene_player.play()


	sirene_playback = (
		sirene_player.get_stream_playback()
		as AudioStreamGeneratorPlayback
	)


# =========================================================
# GERAR SIRENE
# =========================================================

func preencher_sirene() -> void:

	if sirene_playback == null:
		return


	var frames: int = (
		sirene_playback.get_frames_available()
	)


	for i: int in range(
		frames
	):

		var volume: float = 0.0


		if sirene_ativa:
			volume = 1.0


		sirene_modulacao += (
			TAU
			*
			1.35
			/
			MIX_RATE
		)


		if sirene_modulacao >= TAU:
			sirene_modulacao -= TAU


		var movimento: float = (
			sin(
				sirene_modulacao
			)
			+
			1.0
		) * 0.5


		var frequencia: float = lerpf(
			420.0,
			690.0,
			movimento
		)


		sirene_fase += (
			TAU
			*
			frequencia
			/
			MIX_RATE
		)


		sirene_fase_2 += (
			TAU
			*
			(
				frequencia * 1.52
			)
			/
			MIX_RATE
		)


		if sirene_fase >= TAU:
			sirene_fase -= TAU


		if sirene_fase_2 >= TAU:
			sirene_fase_2 -= TAU


		var som: float = (
			sin(
				sirene_fase
			)
			*
			0.12
		)


		som += (
			sin(
				sirene_fase_2
			)
			*
			0.045
		)


		som *= volume


		som = clampf(
			som,
			-0.65,
			0.65
		)


		sirene_playback.push_frame(
			Vector2(
				som,
				som
			)
		)


# =========================================================
# SOM DA PORTA
# =========================================================

func criar_som_porta() -> void:

	porta_generator = AudioStreamGenerator.new()

	porta_generator.mix_rate = MIX_RATE
	porta_generator.buffer_length = 0.25


	porta_player = AudioStreamPlayer.new()

	porta_player.name = "HangarDoorAudio"

	porta_player.stream = porta_generator
	porta_player.volume_db = -2.0


	add_child(
		porta_player
	)


	porta_player.play()


	porta_playback = (
		porta_player.get_stream_playback()
		as AudioStreamGeneratorPlayback
	)


# =========================================================
# ATUALIZAR PORTA
# =========================================================

func atualizar_porta(delta: float) -> void:

	if impacto_restante > 0.0:

		impacto_restante -= delta

		if impacto_restante < 0.0:
			impacto_restante = 0.0


	if !porta_ativa:
		return


	porta_tempo += delta


	if porta_tempo >= porta_duracao:

		porta_ativa = false

		impacto_restante = 0.34


# =========================================================
# GERAR SOM DA PORTA
# =========================================================

func preencher_porta() -> void:

	if porta_playback == null:
		return


	var frames: int = (
		porta_playback.get_frames_available()
	)


	for i: int in range(
		frames
	):

		var volume: float = 0.0


		if porta_ativa:
			volume = 1.0


		porta_fase_1 += (
			TAU
			*
			42.0
			/
			MIX_RATE
		)


		porta_fase_2 += (
			TAU
			*
			76.0
			/
			MIX_RATE
		)


		porta_fase_3 += (
			TAU
			*
			188.0
			/
			MIX_RATE
		)


		porta_fase_4 += (
			TAU
			*
			713.0
			/
			MIX_RATE
		)


		if porta_fase_1 >= TAU:
			porta_fase_1 -= TAU


		if porta_fase_2 >= TAU:
			porta_fase_2 -= TAU


		if porta_fase_3 >= TAU:
			porta_fase_3 -= TAU


		if porta_fase_4 >= TAU:
			porta_fase_4 -= TAU


		var grave: float = (
			sin(
				porta_fase_1
			)
			*
			0.17
		)


		var motor: float = (
			sin(
				porta_fase_2
			)
			*
			0.095
		)


		var hidraulico: float = (
			sin(
				porta_fase_3
			)
			*
			0.042
		)


		var metal: float = (
			sin(
				porta_fase_4
			)
			*
			sin(
				porta_fase_2 * 1.31
			)
			*
			0.018
		)


		var som: float = (
			grave
			+
			motor
			+
			hidraulico
			+
			metal
		)


		som *= volume


		if impacto_restante > 0.0:

			impacto_fase += (
				TAU
				*
				54.0
				/
				MIX_RATE
			)


			if impacto_fase >= TAU:
				impacto_fase -= TAU


			var envelope: float = clampf(
				impacto_restante / 0.34,
				0.0,
				1.0
			)


			som += (
				sin(
					impacto_fase
				)
				*
				0.32
				*
				envelope
			)


		som = tanh(
			som * 1.35
		)


		som *= 0.78


		som = clampf(
			som,
			-0.90,
			0.90
		)


		porta_playback.push_frame(
			Vector2(
				som,
				som
			)
		)


# =========================================================
# BEEP
# =========================================================

func criar_beep() -> void:

	beep_generator = AudioStreamGenerator.new()

	beep_generator.mix_rate = MIX_RATE
	beep_generator.buffer_length = 0.20


	beep_player = AudioStreamPlayer.new()

	beep_player.name = "ComputerBeep"

	beep_player.stream = beep_generator
	beep_player.volume_db = -3.0


	add_child(
		beep_player
	)


	beep_player.play()


	beep_playback = (
		beep_player.get_stream_playback()
		as AudioStreamGeneratorPlayback
	)


# =========================================================
# DISPARAR BEEP
# =========================================================

func som_confirmacao(
	frequencia: float
) -> void:

	beep_frequencia = frequencia

	beep_restante = 0.11

	beep_fase = 0.0


# =========================================================
# ATUALIZAR BEEP
# =========================================================

func atualizar_beep(delta: float) -> void:

	if beep_restante <= 0.0:
		return


	beep_restante -= delta


	if beep_restante < 0.0:
		beep_restante = 0.0


# =========================================================
# GERAR BEEP
# =========================================================

func preencher_beep() -> void:

	if beep_playback == null:
		return


	var frames: int = (
		beep_playback.get_frames_available()
	)


	for i: int in range(
		frames
	):

		var volume: float = 0.0


		if beep_restante > 0.0:

			volume = clampf(
				beep_restante / 0.11,
				0.0,
				1.0
			)


		beep_fase += (
			TAU
			*
			beep_frequencia
			/
			MIX_RATE
		)


		if beep_fase >= TAU:
			beep_fase -= TAU


		var som: float = (
			sin(
				beep_fase
			)
			*
			0.17
			*
			volume
		)


		beep_playback.push_frame(
			Vector2(
				som,
				som
			)
		)
