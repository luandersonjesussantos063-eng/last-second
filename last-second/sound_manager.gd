extends Node


# =========================================================
# LAST SECOND - SOUND MANAGER v2.0
# MOTOR DE NAVE
# =========================================================
#
# - grave forte de motor
# - turbina
# - vibração metálica
# - ruído energético
# - turbo mais agressivo
# - transição suave
#
# =========================================================


var audio_player: AudioStreamPlayer
var generator: AudioStreamGenerator
var playback: AudioStreamGeneratorPlayback


var mix_rate := 44100.0


# =========================================================
# FASES
# =========================================================

var fase_grave_1 := 0.0
var fase_grave_2 := 0.0

var fase_motor := 0.0

var fase_turbina_1 := 0.0
var fase_turbina_2 := 0.0

var fase_energia_1 := 0.0
var fase_energia_2 := 0.0

var fase_vibracao := 0.0

var fase_noise_1 := 0.0
var fase_noise_2 := 0.0


# =========================================================
# ESTADO
# =========================================================

var intensidade_turbo := 0.0
var velocidade_som := 0.0

var volume_motor := 1.0


# =========================================================
# INICIO
# =========================================================

func _ready():

	generator = AudioStreamGenerator.new()


	generator.mix_rate = mix_rate

	generator.buffer_length = 0.30


	audio_player = AudioStreamPlayer.new()

	audio_player.name = "SpaceshipEngine"


	audio_player.stream = generator


	# =====================================================
	# VOLUME PRINCIPAL
	#
	# Antes estava -15.
	# Agora está muito mais alto.
	# =====================================================

	audio_player.volume_db = -5.0


	add_child(
		audio_player
	)


	audio_player.play()


	playback = (
		audio_player.get_stream_playback()
		as AudioStreamGeneratorPlayback
	)


# =========================================================
# LOOP
# =========================================================

func _process(delta):

	if playback == null:

		return


	var turbo_ativo := Input.is_key_pressed(
		KEY_SHIFT
	)


	var alvo_turbo := 0.0


	if turbo_ativo:

		alvo_turbo = 1.0


	# =====================================================
	# TURBO ENTRA RAPIDO
	# E SAI MAIS DEVAGAR
	# =====================================================

	var resposta := 3.5


	if turbo_ativo:

		resposta = 6.5


	intensidade_turbo = lerpf(
		intensidade_turbo,
		alvo_turbo,
		min(
			1.0,
			delta * resposta
		)
	)


	# =====================================================
	# VALOR INTERNO DE POTENCIA DO MOTOR
	# =====================================================

	var potencia_desejada := lerpf(
		0.35,
		1.0,
		intensidade_turbo
	)


	velocidade_som = lerpf(
		velocidade_som,
		potencia_desejada,
		min(
			1.0,
			delta * 3.0
		)
	)


	preencher_audio()


# =========================================================
# GERAR AUDIO
# =========================================================

func preencher_audio():

	var frames := playback.get_frames_available()


	for i in range(frames):

		var turbo := intensidade_turbo


		# =================================================
		# GRAVE PRINCIPAL
		#
		# Ronco profundo da nave.
		# =================================================

		var freq_grave_1 := lerpf(
			36.0,
			53.0,
			turbo
		)


		var freq_grave_2 := lerpf(
			54.0,
			78.0,
			turbo
		)


		avancar_fases_graves(
			freq_grave_1,
			freq_grave_2
		)


		var grave_1 := (
			sin(
				fase_grave_1
			)
			*
			0.19
		)


		var grave_2 := (
			sin(
				fase_grave_2
			)
			*
			0.10
		)


		# =================================================
		# MOTOR CENTRAL
		#
		# Frequência média que dá sensação de máquina.
		# =================================================

		var freq_motor := lerpf(
			82.0,
			138.0,
			turbo
		)


		fase_motor += (
			TAU
			*
			freq_motor
			/
			mix_rate
		)


		corrigir_fase()


		var motor_base := sin(
			fase_motor
		)


		# Harmônico deixa o som menos "seno puro".

		var motor_harmonico := sin(
			fase_motor * 2.0
		)


		var motor := (
			motor_base * 0.13
			+
			motor_harmonico * 0.055
		)


		# =================================================
		# TURBINA
		#
		# Som que sobe quando acelera.
		# =================================================

		var freq_turbina_1 := lerpf(
			185.0,
			410.0,
			turbo
		)


		var freq_turbina_2 := lerpf(
			275.0,
			670.0,
			turbo
		)


		avancar_fases_turbina(
			freq_turbina_1,
			freq_turbina_2
		)


		var turbina_1 := (
			sin(
				fase_turbina_1
			)
			*
			0.045
		)


		var turbina_2 := (
			sin(
				fase_turbina_2
			)
			*
			0.024
			*
			turbo
		)


		var turbina := (
			turbina_1
			+
			turbina_2
		)


		# =================================================
		# ENERGIA / REATOR
		#
		# Frequências próximas criam batimento,
		# dando sensação de reator funcionando.
		# =================================================

		var freq_energia_1 := lerpf(
			112.0,
			165.0,
			turbo
		)


		var freq_energia_2 := (
			freq_energia_1
			+
			3.7
		)


		avancar_fases_energia(
			freq_energia_1,
			freq_energia_2
		)


		var energia := (
			sin(
				fase_energia_1
			)
			+
			sin(
				fase_energia_2
			)
		)


		energia *= 0.032


		# =================================================
		# VIBRACAO DO MOTOR
		#
		# Pequena pulsação grave.
		# =================================================

		var freq_vibracao := lerpf(
			7.0,
			12.0,
			turbo
		)


		fase_vibracao += (
			TAU
			*
			freq_vibracao
			/
			mix_rate
		)


		if fase_vibracao > TAU:

			fase_vibracao -= TAU


		var vibracao := (
			sin(
				fase_vibracao
			)
			*
			0.025
		)


		# =================================================
		# "RUIDO" PROCEDURAL
		#
		# Duas frequências altas misturadas.
		# Dá sensação de gás/energia/turbina sem
		# precisar gerar ruído aleatório pesado.
		# =================================================

		var freq_noise_1 := lerpf(
			630.0,
			1180.0,
			turbo
		)


		var freq_noise_2 := lerpf(
			911.0,
			1760.0,
			turbo
		)


		fase_noise_1 += (
			TAU
			*
			freq_noise_1
			/
			mix_rate
		)


		fase_noise_2 += (
			TAU
			*
			freq_noise_2
			/
			mix_rate
		)


		if fase_noise_1 > TAU:

			fase_noise_1 -= TAU


		if fase_noise_2 > TAU:

			fase_noise_2 -= TAU


		var ruido := (
			sin(
				fase_noise_1
			)
			*
			sin(
				fase_noise_2
			)
		)


		ruido *= (
			0.012
			+
			turbo * 0.032
		)


		# =================================================
		# TURBO EXTRA
		#
		# Quando Shift está apertado aparece uma
		# camada mais agressiva.
		# =================================================

		var turbo_rumble := (
			sin(
				fase_motor * 0.47
			)
			*
			0.09
			*
			turbo
		)


		var turbo_whine := (
			sin(
				fase_turbina_2 * 1.73
			)
			*
			0.04
			*
			turbo
		)


		# =================================================
		# MISTURA FINAL
		# =================================================

		var amostra := (
			grave_1
			+
			grave_2
			+
			motor
			+
			turbina
			+
			energia
			+
			vibracao
			+
			ruido
			+
			turbo_rumble
			+
			turbo_whine
		)


		# =================================================
		# MODULACAO
		#
		# Impede que o motor pareça uma nota musical
		# constante.
		# =================================================

		var tremor := (
			1.0
			+
			sin(
				fase_vibracao * 0.43
			)
			*
			0.06
		)


		amostra *= tremor


		# =================================================
		# POTENCIA
		# =================================================

		amostra *= lerpf(
			0.85,
			1.18,
			turbo
		)


		# =================================================
		# SATURACAO SUAVE
		#
		# Dá mais peso ao som sem clipar feio.
		# =================================================

		amostra = tanh(
			amostra * 1.65
		)


		amostra *= 0.70


		# =================================================
		# ESTEREO
		#
		# Pequena diferença entre canais.
		# =================================================

		var esquerdo := (
			amostra
			+
			sin(
				fase_energia_1
			)
			*
			0.015
		)


		var direito := (
			amostra
			+
			sin(
				fase_energia_2
			)
			*
			0.015
		)


		esquerdo = clampf(
			esquerdo,
			-0.95,
			0.95
		)


		direito = clampf(
			direito,
			-0.95,
			0.95
		)


		playback.push_frame(
			Vector2(
				esquerdo,
				direito
			)
		)


# =========================================================
# FASES GRAVES
# =========================================================

func avancar_fases_graves(
	frequencia_1: float,
	frequencia_2: float
):

	fase_grave_1 += (
		TAU
		*
		frequencia_1
		/
		mix_rate
	)


	fase_grave_2 += (
		TAU
		*
		frequencia_2
		/
		mix_rate
	)


	if fase_grave_1 > TAU:

		fase_grave_1 -= TAU


	if fase_grave_2 > TAU:

		fase_grave_2 -= TAU


# =========================================================
# FASES TURBINA
# =========================================================

func avancar_fases_turbina(
	frequencia_1: float,
	frequencia_2: float
):

	fase_turbina_1 += (
		TAU
		*
		frequencia_1
		/
		mix_rate
	)


	fase_turbina_2 += (
		TAU
		*
		frequencia_2
		/
		mix_rate
	)


	if fase_turbina_1 > TAU:

		fase_turbina_1 -= TAU


	if fase_turbina_2 > TAU:

		fase_turbina_2 -= TAU


# =========================================================
# FASES ENERGIA
# =========================================================

func avancar_fases_energia(
	frequencia_1: float,
	frequencia_2: float
):

	fase_energia_1 += (
		TAU
		*
		frequencia_1
		/
		mix_rate
	)


	fase_energia_2 += (
		TAU
		*
		frequencia_2
		/
		mix_rate
	)


	if fase_energia_1 > TAU:

		fase_energia_1 -= TAU


	if fase_energia_2 > TAU:

		fase_energia_2 -= TAU


# =========================================================
# CORRIGIR FASE DO MOTOR
# =========================================================

func corrigir_fase():

	if fase_motor > TAU:

		fase_motor -= TAU
