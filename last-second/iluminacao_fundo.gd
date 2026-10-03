extends Node3D


# ============================================================
# ODYSSEY STATION
# ILUMINACAO DO FUNDO v1.0
#
# OBJETIVO:
# - clarear a parte traseira do hangar
# - destacar salas, portas e parede
# - manter clima espacial escuro
# - funcionar no PC e Android
# - sem sombras para preservar desempenho
# ============================================================


# ============================================================
# CONFIGURACAO
# ============================================================

@export_category("Iluminacao")

@export_range(1.0, 12.0, 0.5)
var intensidade_principal: float = 5.5

@export_range(20.0, 80.0, 1.0)
var alcance_principal: float = 58.0

@export_range(25.0, 85.0, 1.0)
var abertura_luz: float = 62.0


@export_category("Luzes de apoio")

@export_range(0.5, 8.0, 0.5)
var intensidade_apoio: float = 2.5


# ============================================================
# CORES
# ============================================================

const COR_LUZ_FRIA := Color(
	0.68,
	0.82,
	1.0
)

const COR_CIANO := Color(
	0.0,
	0.82,
	1.0
)

const COR_AZUL_SUAVE := Color(
	0.22,
	0.46,
	0.72
)

const COR_METAL := Color(
	0.10,
	0.13,
	0.18
)


# ============================================================
# READY
# ============================================================

func _ready() -> void:

	# Evita criar tudo duas vezes.
	if has_node(
		"IluminacaoTraseiraGerada"
	):
		return


	var raiz := Node3D.new()

	raiz.name = "IluminacaoTraseiraGerada"

	add_child(
		raiz
	)


	criar_spots_principais(
		raiz
	)

	criar_luzes_de_apoio(
		raiz
	)

	criar_barras_teto(
		raiz
	)

	criar_faixa_parede_fundo(
		raiz
	)


	print(
		"========================================"
	)

	print(
		"HANGAR // ILUMINACAO TRASEIRA ONLINE"
	)

	print(
		"FUNDO DO HANGAR // VISIBILIDADE AUMENTADA"
	)

	print(
		"========================================"
	)



# ============================================================
# 3 LUZES PRINCIPAIS
#
# Ficam no teto e jogam luz para a parede do fundo.
#
# O fundo do nosso hangar esta em +Z.
# ============================================================

func criar_spots_principais(
	raiz: Node3D
) -> void:


	for x in [
		-45.0,
		0.0,
		45.0
	]:

		var posicao := Vector3(
			x,
			25.0,
			48.0
		)


		var alvo := Vector3(
			x,
			7.0,
			88.0
		)


		criar_spot(
			raiz,
			"LuzFundoPrincipal",
			posicao,
			alvo,
			COR_LUZ_FRIA,
			intensidade_principal,
			alcance_principal,
			abertura_luz
		)



# ============================================================
# LUZES DE APOIO
#
# Iluminam a parte baixa da parede e entradas das salas.
# ============================================================

func criar_luzes_de_apoio(
	raiz: Node3D
) -> void:


	for x in [
		-52.0,
		-26.0,
		0.0,
		26.0,
		52.0
	]:

		var posicao := Vector3(
			x,
			2.0,
			72.0
		)


		var alvo := Vector3(
			x,
			5.0,
			89.0
		)


		criar_spot(
			raiz,
			"LuzBaixaFundo",
			posicao,
			alvo,
			COR_AZUL_SUAVE,
			intensidade_apoio,
			28.0,
			48.0
		)



# ============================================================
# BARRAS DE LUZ DO TETO
# ============================================================

func criar_barras_teto(
	raiz: Node3D
) -> void:


	for x in [
		-45.0,
		-15.0,
		15.0,
		45.0
	]:

		criar_barra_emissiva(
			raiz,

			"BarraTetoFundo",

			Vector3(
				18.0,
				0.22,
				0.65
			),

			Vector3(
				x,
				29.0,
				66.0
			),

			COR_CIANO,

			4.5
		)



# ============================================================
# FAIXA HORIZONTAL NA PAREDE DO FUNDO
#
# Ajuda a desenhar visualmente aquela parede enorme.
# ============================================================

func criar_faixa_parede_fundo(
	raiz: Node3D
) -> void:


	criar_barra_emissiva(
		raiz,

		"FaixaFundoSuperior",

		Vector3(
			118.0,
			0.32,
			0.20
		),

		Vector3(
			0.0,
			10.5,
			88.75
		),

		COR_CIANO,

		3.5
	)


	# ========================================================
	# SEGUNDA FAIXA MAIS FRACA
	# ========================================================

	criar_barra_emissiva(
		raiz,

		"FaixaFundoInferior",

		Vector3(
			92.0,
			0.14,
			0.18
		),

		Vector3(
			0.0,
			1.0,
			88.70
		),

		COR_AZUL_SUAVE,

		2.4
	)



# ============================================================
# CRIAR SPOTLIGHT
# ============================================================

func criar_spot(
	pai: Node3D,
	nome: String,
	posicao: Vector3,
	alvo: Vector3,
	cor: Color,
	energia: float,
	alcance: float,
	angulo: float
) -> SpotLight3D:


	var luz := SpotLight3D.new()

	luz.name = nome

	luz.position = posicao

	luz.light_color = cor

	luz.light_energy = energia

	luz.spot_range = alcance

	luz.spot_angle = angulo

	luz.spot_angle_attenuation = 0.65


	# ========================================================
	# IMPORTANTE PARA PERFORMANCE
	# ========================================================

	luz.shadow_enabled = false


	pai.add_child(
		luz
	)


	# ========================================================
	# APONTA PARA O ALVO
	# ========================================================

	luz.look_at(
		alvo,
		Vector3.UP
	)


	return luz



# ============================================================
# BARRA EMISSIVA
# ============================================================

func criar_barra_emissiva(
	pai: Node3D,
	nome: String,
	tamanho: Vector3,
	posicao: Vector3,
	cor: Color,
	energia: float
) -> MeshInstance3D:


	var objeto := MeshInstance3D.new()

	objeto.name = nome

	objeto.position = posicao


	var mesh := BoxMesh.new()

	mesh.size = tamanho


	objeto.mesh = mesh


	var material := StandardMaterial3D.new()

	material.albedo_color = cor

	material.emission_enabled = true

	material.emission = cor

	material.emission_energy_multiplier = energia

	material.metallic = 0.20

	material.roughness = 0.18


	objeto.material_override = material


	pai.add_child(
		objeto
	)


	return objeto
