extends Node


# =========================================================
# LAST SECOND - GROUND GUARD v2.0
#
# - SOLO SOLIDO
# - NAVE NAO ATRAVESSA O TERRENO
# - NIVELAMENTO SUAVE AO SAIR DA ATMOSFERA
# =========================================================


@export var distancia_segura_solo: float = 7.0

# Quanto tempo a nave leva para nivelar
# depois de entrar no mundo local.
@export var duracao_nivelamento: float = 3.0

# Depois da atmosfera ela ainda fica
# levemente apontada para baixo.
@export var inclinacao_descida_graus: float = 8.0


var player: Node3D = null
var planet_surface: Node3D = null


var estava_modo_local: bool = false

var nivelamento_ativo: bool = false

var tempo_nivelamento: float = 0.0

var tocando_solo: bool = false


# =========================================================
# READY
# =========================================================

func _ready() -> void:

	player = get_node_or_null(
		"../Player"
	) as Node3D


	planet_surface = get_node_or_null(
		"../PlanetSurface"
	) as Node3D


	if player == null:

		push_warning(
			"GroundGuard: Player nao encontrado."
		)


	if planet_surface == null:

		push_warning(
			"GroundGuard: PlanetSurface nao encontrado."
		)


# =========================================================
# PHYSICS
# =========================================================

func _physics_process(delta: float) -> void:

	if player == null:
		return


	if planet_surface == null:
		return


	var modo_variant: Variant = (
		planet_surface.get(
			"modo_local"
		)
	)


	if modo_variant == null:
		return


	var modo_local: bool = bool(
		modo_variant
	)


	# =====================================================
	# AINDA NO ESPACO
	# =====================================================

	if !modo_local:

		estava_modo_local = false

		nivelamento_ativo = false

		tocando_solo = false

		return


	# =====================================================
	# ACABOU DE ENTRAR NO MUNDO LOCAL
	# =====================================================

	if !estava_modo_local:

		estava_modo_local = true

		nivelamento_ativo = true

		tempo_nivelamento = 0.0


		print(
			"GROUND GUARD: NIVELANDO NAVE"
		)


	# =====================================================
	# NIVELAR SUAVEMENTE
	# =====================================================

	if nivelamento_ativo:

		nivelar_nave_suavemente(
			delta
		)


	# =====================================================
	# SOLO SOLIDO
	# =====================================================

	impedir_atravessar_solo()


# =========================================================
# NIVELAMENTO SUAVE
# =========================================================

func nivelar_nave_suavemente(
	delta: float
) -> void:

	tempo_nivelamento += delta


	var progresso: float = clampf(
		tempo_nivelamento
		/
		maxf(
			duracao_nivelamento,
			0.1
		),
		0.0,
		1.0
	)


	# Curva suave
	progresso = (
		progresso
		*
		progresso
		*
		(
			3.0
			-
			2.0
			*
			progresso
		)
	)


	# =====================================================
	# "CIMA" DO MUNDO LOCAL
	# =====================================================

	var up: Vector3 = (
		planet_surface.global_transform.basis.y
	).normalized()


	# =====================================================
	# FRENTE DO MUNDO
	#
	# O terreno foi criado para se estender
	# principalmente nessa direcao.
	# =====================================================

	var frente_horizontal: Vector3 = (
		-planet_surface.global_transform.basis.z
	).normalized()


	# =====================================================
	# INCLINACAO LEVE PARA BAIXO
	# =====================================================

	var angulo: float = deg_to_rad(
		inclinacao_descida_graus
	)


	var direcao_alvo: Vector3 = (
		frente_horizontal
		*
		cos(
			angulo
		)
		-
		up
		*
		sin(
			angulo
		)
	).normalized()


	# =====================================================
	# TRANSFORM DE DESTINO
	# =====================================================

	var transform_atual: Transform3D = (
		player.global_transform
	)


	var transform_alvo: Transform3D = (
		transform_atual.looking_at(
			player.global_position
			+
			direcao_alvo
			*
			100.0,
			up
		)
	)


	# =====================================================
	# ROTACAO SUAVE
	# =====================================================

	var peso_frame: float = clampf(
		delta
		*
		(
			1.2
			+
			progresso
			*
			2.5
		),
		0.0,
		1.0
	)


	var nova_basis: Basis = (
		transform_atual.basis.slerp(
			transform_alvo.basis,
			peso_frame
		)
	)


	nova_basis = (
		nova_basis.orthonormalized()
	)


	player.global_transform = Transform3D(
		nova_basis,
		player.global_position
	)


	# =====================================================
	# TERMINOU
	# =====================================================

	if tempo_nivelamento >= duracao_nivelamento:

		nivelamento_ativo = false


		print(
			"GROUND GUARD: NAVE NIVELADA"
		)


# =========================================================
# SOLO SOLIDO
# =========================================================

func impedir_atravessar_solo() -> void:

	var posicao_local: Vector3 = (
		planet_surface.to_local(
			player.global_position
		)
	)


	# =====================================================
	# DIMENSOES DO MAPA
	# =====================================================

	var largura: float = 18000.0

	var frente: float = 24000.0

	var atras: float = 4000.0


	var largura_variant: Variant = (
		planet_surface.get(
			"largura_mundo"
		)
	)


	if largura_variant != null:

		largura = float(
			largura_variant
		)


	var frente_variant: Variant = (
		planet_surface.get(
			"comprimento_frente"
		)
	)


	if frente_variant != null:

		frente = float(
			frente_variant
		)


	var atras_variant: Variant = (
		planet_surface.get(
			"comprimento_atras"
		)
	)


	if atras_variant != null:

		atras = float(
			atras_variant
		)


	# =====================================================
	# FORA DOS LIMITES
	# =====================================================

	if posicao_local.x < (
		-largura * 0.5
	):

		return


	if posicao_local.x > (
		largura * 0.5
	):

		return


	if posicao_local.z < -frente:

		return


	if posicao_local.z > atras:

		return


	# =====================================================
	# ALTURA DO TERRENO
	# =====================================================

	if !planet_surface.has_method(
		"altura_terreno"
	):

		return


	var resultado: Variant = (
		planet_surface.call(
			"altura_terreno",
			posicao_local.x,
			posicao_local.z
		)
	)


	var altura_chao: float = float(
		resultado
	)


	var altura_minima: float = (
		altura_chao
		+
		distancia_segura_solo
	)


	# =====================================================
	# AINDA ACIMA DO SOLO
	# =====================================================

	if posicao_local.y >= altura_minima:

		tocando_solo = false

		return


	# =====================================================
	# IMPEDIR ATRAVESSAR
	# =====================================================

	posicao_local.y = altura_minima


	player.global_position = (
		planet_surface.to_global(
			posicao_local
		)
	)


	# =====================================================
	# PRIMEIRO TOQUE
	# =====================================================

	if !tocando_solo:

		tocando_solo = true


		print(
			"SOLO: NAVE TOCOU O TERRENO"
		)


		nivelar_totalmente()


# =========================================================
# NIVELAR AO TOCAR O SOLO
# =========================================================

func nivelar_totalmente() -> void:

	var up: Vector3 = (
		planet_surface.global_transform.basis.y
	).normalized()


	var frente: Vector3 = (
		-player.global_transform.basis.z
	).normalized()


	# Remove qualquer componente que
	# continue apontando para baixo.
	var frente_horizontal: Vector3 = (
		frente
		-
		up
		*
		frente.dot(
			up
		)
	)


	if frente_horizontal.length() < 0.05:

		frente_horizontal = (
			-planet_surface.global_transform.basis.z
		)


	frente_horizontal = (
		frente_horizontal.normalized()
	)


	player.look_at(
		player.global_position
		+
		frente_horizontal
		*
		100.0,
		up
	)
