extends Node3D


# =========================================================
# LAST SECOND - SPACE WORLD v1.6 // PC VISUAL PASS
# =========================================================
#
# MANTEM:
# - estrelas
# - estrelas piscantes
# - planeta avancado
# - nuvens do planeta
# - atmosfera
# - luas
# - asteroides
# - turbo visual
#
# DESATIVADO:
# - nebulosa / neblina espacial
# - poeira espacial
#
# =========================================================


@export var quantidade_estrelas: int = 2800
@export var quantidade_asteroides: int = 75
@export var quantidade_estrelas_piscantes: int = 28
@export var quantidade_riscos_turbo: int = 125


@export var planeta_posicao: Vector3 = Vector3(
	220.0,
	70.0,
	-850.0
)


@export var planeta_raio: float = 160.0


# =========================================================
# REFERENCIAS
# =========================================================

var player: Node3D = null

var fundo_espacial: Node3D = null

var nebulosa: MeshInstance3D = null

var campo_estrelas: MultiMeshInstance3D = null

var planeta: MeshInstance3D = null

var nuvens: MeshInstance3D = null

var atmosfera: MeshInstance3D = null


# =========================================================
# ASTEROIDES
# =========================================================

var asteroides: Array[MeshInstance3D] = []

var velocidades_asteroides: Array[Vector3] = []


# =========================================================
# ESTRELAS PISCANTES
# =========================================================

var estrelas_piscantes: Array[MeshInstance3D] = []

var estrelas_tamanhos: Array[float] = []

var estrelas_fases: Array[float] = []

var estrelas_velocidades: Array[float] = []


# =========================================================
# TURBO
# =========================================================

var riscos_turbo: MultiMeshInstance3D = null

var multimesh_turbo: MultiMesh = null

var riscos_posicoes: Array[Vector3] = []

var riscos_comprimentos: Array[float] = []

var riscos_larguras: Array[float] = []

var intensidade_turbo: float = 0.0


var tempo: float = 0.0


# =========================================================
# INICIO
# =========================================================

func _ready():

	randomize()


	player = get_node_or_null(
		"../Player"
	) as Node3D


	criar_fundo_espacial()


	# =====================================================
	# NEBULOSA DESATIVADA
	#
	# Se quisermos colocar de volta depois,
	# basta retirar o # da linha abaixo.
	# =====================================================

	# No PC podemos usar a nebulosa volumetrica falsa sem sacrificar
	# a legibilidade dos controles mobile.
	criar_nebulosa()


	criar_estrelas()

	criar_estrelas_piscantes()

	criar_planeta()

	criar_nuvens()

	criar_atmosfera()

	criar_corpos_distantes()

	criar_asteroides()

	criar_riscos_turbo()


	await get_tree().process_frame
	await get_tree().process_frame


	remover_objetos_antigos()


# =========================================================
# LOOP
# =========================================================

func _process(delta: float):

	tempo += delta


	atualizar_fundo()

	atualizar_planeta(delta)

	atualizar_asteroides(delta)

	atualizar_estrelas_piscantes()

	atualizar_turbo(delta)


# =========================================================
# FUNDO ESPACIAL
# =========================================================

func criar_fundo_espacial():

	fundo_espacial = Node3D.new()

	fundo_espacial.name = "DeepSpace"


	add_child(
		fundo_espacial
	)


	if player != null:

		fundo_espacial.global_position = (
			player.global_position
		)


func atualizar_fundo():

	if player == null:
		return


	if fundo_espacial == null:
		return


	fundo_espacial.global_position = (
		player.global_position
	)


# =========================================================
# LIMPAR OBJETOS ANTIGOS DO PLAYER.GD
# =========================================================

func remover_objetos_antigos():

	var main: Node = get_parent()


	if main == null:
		return


	for filho in main.get_children():

		if filho == self:
			continue


		if filho is MeshInstance3D:

			var objeto: MeshInstance3D = (
				filho as MeshInstance3D
			)


			if objeto.mesh is SphereMesh:

				objeto.queue_free()


# =========================================================
# NEBULOSA
#
# A FUNCAO CONTINUA AQUI,
# MAS NAO E CHAMADA NO _ready().
# =========================================================

func criar_nebulosa():

	nebulosa = MeshInstance3D.new()

	nebulosa.name = "DeepNebula"


	fundo_espacial.add_child(
		nebulosa
	)


	var esfera := SphereMesh.new()


	esfera.radius = 1150.0

	esfera.height = 2300.0

	esfera.radial_segments = 48

	esfera.rings = 24


	nebulosa.mesh = esfera


	var material := ShaderMaterial.new()

	var shader := Shader.new()


	shader.code = """
shader_type spatial;

render_mode
	unshaded,
	blend_mix,
	cull_front,
	depth_draw_never;


float hash3(vec3 p)
{
	p = fract(
		p * 0.3183099
		+
		vec3(
			0.11,
			0.17,
			0.23
		)
	);

	p *= 17.0;

	return fract(
		p.x
		*
		p.y
		*
		p.z
		*
		(
			p.x + p.y + p.z
		)
	);
}


float noise3(vec3 p)
{
	vec3 i = floor(p);

	vec3 f = fract(p);

	f = f * f * (3.0 - 2.0 * f);


	float a = hash3(i);

	float b = hash3(
		i + vec3(1.0, 0.0, 0.0)
	);

	float c = hash3(
		i + vec3(0.0, 1.0, 0.0)
	);

	float d = hash3(
		i + vec3(1.0, 1.0, 0.0)
	);

	float e = hash3(
		i + vec3(0.0, 0.0, 1.0)
	);

	float f1 = hash3(
		i + vec3(1.0, 0.0, 1.0)
	);

	float g = hash3(
		i + vec3(0.0, 1.0, 1.0)
	);

	float h = hash3(
		i + vec3(1.0, 1.0, 1.0)
	);


	float x1 = mix(
		a,
		b,
		f.x
	);

	float x2 = mix(
		c,
		d,
		f.x
	);

	float x3 = mix(
		e,
		f1,
		f.x
	);

	float x4 = mix(
		g,
		h,
		f.x
	);


	return mix(

		mix(
			x1,
			x2,
			f.y
		),

		mix(
			x3,
			x4,
			f.y
		),

		f.z
	);
}


float fbm(vec3 p)
{
	float total = 0.0;

	float amplitude = 0.5;


	for(int i = 0; i < 5; i++)
	{
		total += (
			noise3(p)
			*
			amplitude
		);

		p *= 2.03;

		amplitude *= 0.5;
	}


	return total;
}


void fragment()
{
	vec3 direcao = normalize(
		NORMAL
	);


	float nuvem = fbm(
		direcao * 3.2
		+
		vec3(
			1.7,
			4.1,
			2.3
		)
	);


	float detalhe = fbm(
		direcao * 7.5
		+
		vec3(
			5.3,
			1.4,
			7.2
		)
	);


	float densidade = (
		nuvem * 0.72
		+
		detalhe * 0.28
	);


	float faixa = abs(
		direcao.y
		+
		direcao.x * 0.26
	);


	faixa = (
		1.0
		-
		smoothstep(
			0.05,
			0.58,
			faixa
		)
	);


	float mascara = smoothstep(
		0.48,
		0.78,
		densidade
	);


	mascara *= faixa;


	vec3 escuro = vec3(
		0.004,
		0.012,
		0.032
	);


	vec3 azul = vec3(
		0.025,
		0.105,
		0.24
	);


	vec3 violeta = vec3(
		0.16,
		0.035,
		0.21
	);


	vec3 cor = mix(
		escuro,
		azul,
		densidade
	);


	float violeta_mask = smoothstep(
		0.63,
		0.83,
		detalhe
	);


	cor = mix(
		cor,
		violeta,
		violeta_mask * 0.42
	);


	ALBEDO = cor;

	EMISSION = cor * 0.78;

	ALPHA = mascara * 0.34;
}
"""


	material.shader = shader


	nebulosa.material_override = material


# =========================================================
# MATERIAL DAS ESTRELAS
# =========================================================

func criar_material_estrelas() -> StandardMaterial3D:

	var material := StandardMaterial3D.new()


	material.albedo_color = Color.WHITE


	material.vertex_color_use_as_albedo = true


	material.shading_mode = (
		BaseMaterial3D.SHADING_MODE_UNSHADED
	)


	material.cull_mode = (
		BaseMaterial3D.CULL_DISABLED
	)


	return material


# =========================================================
# ESTRELAS
# =========================================================

func criar_estrelas():

	campo_estrelas = MultiMeshInstance3D.new()

	campo_estrelas.name = "StarField"


	fundo_espacial.add_child(
		campo_estrelas
	)


	var mesh := SphereMesh.new()


	mesh.radius = 0.065

	mesh.height = 0.13

	mesh.radial_segments = 4

	mesh.rings = 2


	mesh.material = criar_material_estrelas()


	var multi := MultiMesh.new()


	multi.transform_format = (
		MultiMesh.TRANSFORM_3D
	)


	multi.use_colors = true

	multi.mesh = mesh


	multi.instance_count = (
		quantidade_estrelas
	)


	for i in range(
		quantidade_estrelas
	):

		var direcao := Vector3(

			randf_range(
				-1.0,
				1.0
			),

			randf_range(
				-1.0,
				1.0
			),

			randf_range(
				-1.0,
				1.0
			)
		)


		if direcao.length() < 0.01:

			direcao = Vector3.FORWARD


		direcao = direcao.normalized()


		var distancia: float = randf_range(
			350.0,
			1080.0
		)


		var posicao: Vector3 = (
			direcao * distancia
		)


		var tamanho: float = randf_range(
			0.45,
			1.75
		)


		var sorte_tamanho: float = randf()


		if sorte_tamanho < 0.015:

			tamanho *= 5.0


		elif sorte_tamanho < 0.065:

			tamanho *= 2.3


		multi.set_instance_transform(
			i,

			Transform3D(

				Basis.IDENTITY.scaled(
					Vector3.ONE * tamanho
				),

				posicao
			)
		)


		var sorte_cor: float = randf()

		var cor := Color.WHITE


		if sorte_cor < 0.10:

			cor = Color(
				0.55,
				0.72,
				1.0
			)


		elif sorte_cor < 0.18:

			cor = Color(
				1.0,
				0.84,
				0.55
			)


		elif sorte_cor < 0.22:

			cor = Color(
				1.0,
				0.52,
				0.40
			)


		elif sorte_cor < 0.28:

			cor = Color(
				0.72,
				0.90,
				1.0
			)


		else:

			var brilho: float = randf_range(
				0.72,
				1.0
			)


			cor = Color(
				brilho,
				brilho,

				randf_range(
					brilho,
					1.0
				)
			)


		multi.set_instance_color(
			i,
			cor
		)


	campo_estrelas.multimesh = multi


# =========================================================
# ESTRELAS PISCANTES
# =========================================================

func criar_estrelas_piscantes():

	var mesh := SphereMesh.new()


	mesh.radius = 0.20

	mesh.height = 0.40

	mesh.radial_segments = 6

	mesh.rings = 4


	for i in range(
		quantidade_estrelas_piscantes
	):

		var estrela := MeshInstance3D.new()


		estrela.name = (
			"BrightStar_%02d"
			%
			i
		)


		estrela.mesh = mesh


		var direcao := Vector3(

			randf_range(
				-1.0,
				1.0
			),

			randf_range(
				-0.75,
				0.75
			),

			randf_range(
				-1.0,
				1.0
			)
		)


		if direcao.length() < 0.01:

			direcao = Vector3.FORWARD


		direcao = direcao.normalized()


		estrela.position = (
			direcao
			*
			randf_range(
				500.0,
				950.0
			)
		)


		var material := StandardMaterial3D.new()


		var cor := Color(
			0.85,
			0.93,
			1.0
		)


		var sorte: float = randf()


		if sorte < 0.30:

			cor = Color(
				0.50,
				0.72,
				1.0
			)


		elif sorte < 0.48:

			cor = Color(
				1.0,
				0.78,
				0.50
			)


		material.albedo_color = cor


		material.emission_enabled = true

		material.emission = cor

		material.emission_energy_multiplier = 3.0


		material.shading_mode = (
			BaseMaterial3D.SHADING_MODE_UNSHADED
		)


		estrela.material_override = material


		fundo_espacial.add_child(
			estrela
		)


		estrelas_piscantes.append(
			estrela
		)


		estrelas_tamanhos.append(
			randf_range(
				0.9,
				2.1
			)
		)


		estrelas_fases.append(
			randf_range(
				0.0,
				TAU
			)
		)


		estrelas_velocidades.append(
			randf_range(
				0.65,
				1.8
			)
		)


# =========================================================
# ATUALIZAR ESTRELAS PISCANTES
# =========================================================

func atualizar_estrelas_piscantes():

	for i in range(
		estrelas_piscantes.size()
	):

		if !is_instance_valid(
			estrelas_piscantes[i]
		):

			continue


		var pulsacao: float = (
			sin(
				tempo
				*
				estrelas_velocidades[i]
				+
				estrelas_fases[i]
			)
			+
			1.0
		) * 0.5


		var escala: float = (
			estrelas_tamanhos[i]
			*
			(
				0.72
				+
				pulsacao * 0.42
			)
		)


		estrelas_piscantes[i].scale = (
			Vector3.ONE
			*
			escala
		)


# =========================================================
# PLANETA AVANCADO
# =========================================================

func criar_planeta():

	planeta = MeshInstance3D.new()

	planeta.name = "Planet"


	add_child(
		planeta
	)


	planeta.position = planeta_posicao


	var esfera := SphereMesh.new()


	esfera.radius = planeta_raio

	esfera.height = (
		planeta_raio * 2.0
	)


	esfera.radial_segments = 96

	esfera.rings = 48


	planeta.mesh = esfera


	var material := ShaderMaterial.new()

	var shader := Shader.new()


	shader.code = """
shader_type spatial;

render_mode
	unshaded,
	cull_back;


float hash(vec2 p)
{
	return fract(
		sin(
			dot(
				p,
				vec2(
					127.1,
					311.7
				)
			)
		)
		*
		43758.5453
	);
}


float noise2(vec2 p)
{
	vec2 i = floor(p);

	vec2 f = fract(p);

	f = f * f * (3.0 - 2.0 * f);


	float a = hash(i);

	float b = hash(
		i + vec2(1.0, 0.0)
	);

	float c = hash(
		i + vec2(0.0, 1.0)
	);

	float d = hash(
		i + vec2(1.0, 1.0)
	);


	return mix(
		mix(
			a,
			b,
			f.x
		),

		mix(
			c,
			d,
			f.x
		),

		f.y
	);
}


float fbm(vec2 p)
{
	float total = 0.0;

	float amplitude = 0.5;


	for(int i = 0; i < 7; i++)
	{
		total += (
			noise2(p)
			*
			amplitude
		);


		p *= 2.03;

		amplitude *= 0.5;
	}


	return total;
}


void fragment()
{
	vec2 p = vec2(
		UV.x * 6.8,
		UV.y * 4.15
	);


	float grande = fbm(p);


	float medio = fbm(
		p * 2.3
		+
		vec2(
			5.4,
			2.1
		)
	);


	float pequeno = fbm(
		p * 5.8
		+
		vec2(
			1.6,
			7.2
		)
	);


	float terreno = (
		grande * 0.62
		+
		medio * 0.28
		+
		pequeno * 0.10
	);


	float terra = smoothstep(
		0.505,
		0.565,
		terreno
	);


	float costa = smoothstep(
		0.46,
		0.53,
		terreno
	);


	float montanha = smoothstep(
		0.64,
		0.78,
		terreno
	);


	float alta_montanha = smoothstep(
		0.73,
		0.84,
		terreno
	);


	vec3 oceano_profundo = vec3(
		0.002,
		0.020,
		0.075
	);


	vec3 oceano_medio = vec3(
		0.006,
		0.105,
		0.235
	);


	vec3 oceano_raso = vec3(
		0.015,
		0.32,
		0.44
	);


	vec3 oceano = mix(
		oceano_profundo,
		oceano_medio,

		smoothstep(
			0.25,
			0.47,
			terreno
		)
	);


	oceano = mix(
		oceano,
		oceano_raso,
		costa
	);


	float umidade = fbm(
		p * 0.72
		+
		vec2(
			7.4,
			1.9
		)
	);


	float latitude = abs(
		UV.y - 0.5
	) * 2.0;


	float calor = (
		1.0
		-
		smoothstep(
			0.25,
			0.82,
			latitude
		)
	);


	vec3 floresta = vec3(
		0.018,
		0.115,
		0.045
	);


	vec3 vegetacao = vec3(
		0.075,
		0.255,
		0.075
	);


	vec3 campo = vec3(
		0.22,
		0.36,
		0.10
	);


	vec3 deserto = vec3(
		0.52,
		0.39,
		0.17
	);


	vec3 pedra = vec3(
		0.31,
		0.29,
		0.25
	);


	vec3 neve = vec3(
		0.84,
		0.90,
		0.94
	);


	vec3 solo = mix(
		floresta,
		vegetacao,
		umidade
	);


	solo = mix(
		solo,
		campo,
		0.26
	);


	float mascara_deserto = (
		smoothstep(
			0.54,
			0.76,
			1.0 - umidade
		)
		*
		calor
	);


	solo = mix(
		solo,
		deserto,
		mascara_deserto
	);


	float praia = (
		smoothstep(
			0.50,
			0.525,
			terreno
		)
		-
		smoothstep(
			0.535,
			0.56,
			terreno
		)
	);


	solo = mix(
		solo,

		vec3(
			0.62,
			0.53,
			0.29
		),

		clamp(
			praia * 3.0,
			0.0,
			1.0
		)
	);


	solo = mix(
		solo,
		pedra,
		montanha
	);


	float neve_altitude = (
		alta_montanha
		*
		smoothstep(
			0.20,
			0.75,
			latitude + 0.18
		)
	);


	solo = mix(
		solo,
		neve,
		neve_altitude
	);


	float gelo = smoothstep(
		0.80,
		0.96,
		latitude
	);


	solo = mix(
		solo,
		neve,
		gelo
	);


	vec3 cor = mix(
		oceano,
		solo,
		terra
	);


	float dia = (
		cos(
			(UV.x - 0.61)
			*
			6.283185
		)
		*
		0.5
		+
		0.5
	);


	dia = smoothstep(
		0.07,
		0.82,
		dia
	);


	float iluminacao = mix(
		0.055,
		1.0,
		dia
	);


	vec3 cor_final = (
		cor * iluminacao
	);


	float cidade1 = noise2(
		UV * 105.0
		+
		vec2(
			4.7,
			8.1
		)
	);


	float cidade2 = noise2(
		UV * 210.0
		+
		vec2(
			13.2,
			2.4
		)
	);


	float cidades = (
		cidade1 * 0.65
		+
		cidade2 * 0.35
	);


	cidades = smoothstep(
		0.80,
		0.95,
		cidades
	);


	cidades *= terra;

	cidades *= (
		1.0 - montanha
	);


	cidades *= (
		1.0 - gelo
	);


	cidades *= (
		1.0 - dia
	);


	vec3 luzes_cidade = (
		vec3(
			1.0,
			0.43,
			0.075
		)
		*
		cidades
		*
		2.3
	);


	float facing = clamp(
		dot(
			normalize(NORMAL),
			normalize(VIEW)
		),
		0.0,
		1.0
	);


	float fresnel = pow(
		1.0 - facing,
		3.0
	);


	float mascara_oceano = (
		1.0 - terra
	);


	vec3 reflexo = (
		vec3(
			0.03,
			0.18,
			0.48
		)
		*
		fresnel
		*
		mascara_oceano
		*
		dia
	);


	cor_final += reflexo;


	ALBEDO = cor_final;


	EMISSION = (
		luzes_cidade
		+
		reflexo * 0.18
	);
}
"""


	material.shader = shader


	planeta.material_override = material


# =========================================================
# NUVENS DO PLANETA
# =========================================================

func criar_nuvens():

	nuvens = MeshInstance3D.new()

	nuvens.name = "PlanetClouds"


	add_child(
		nuvens
	)


	nuvens.position = planeta_posicao


	var esfera := SphereMesh.new()


	esfera.radius = (
		planeta_raio * 1.012
	)


	esfera.height = (
		planeta_raio * 2.024
	)


	esfera.radial_segments = 80

	esfera.rings = 40


	nuvens.mesh = esfera


	var material := ShaderMaterial.new()

	var shader := Shader.new()


	shader.code = """
shader_type spatial;

render_mode
	unshaded,
	blend_mix,
	cull_back,
	depth_draw_never;


float hash(vec2 p)
{
	return fract(
		sin(
			dot(
				p,
				vec2(
					127.1,
					311.7
				)
			)
		)
		*
		43758.5453
	);
}


float noise2(vec2 p)
{
	vec2 i = floor(p);

	vec2 f = fract(p);

	f = f * f * (3.0 - 2.0 * f);


	float a = hash(i);

	float b = hash(
		i + vec2(1.0, 0.0)
	);

	float c = hash(
		i + vec2(0.0, 1.0)
	);

	float d = hash(
		i + vec2(1.0, 1.0)
	);


	return mix(
		mix(
			a,
			b,
			f.x
		),

		mix(
			c,
			d,
			f.x
		),

		f.y
	);
}


float fbm(vec2 p)
{
	float valor = 0.0;

	float amplitude = 0.5;


	for(int i = 0; i < 5; i++)
	{
		valor += (
			noise2(p)
			*
			amplitude
		);


		p *= 2.03;

		amplitude *= 0.5;
	}


	return valor;
}


void fragment()
{
	vec2 p = vec2(
		UV.x * 10.0,
		UV.y * 5.0
	);


	float camada1 = fbm(
		p
		+
		vec2(
			TIME * 0.006,
			0.0
		)
	);


	float camada2 = fbm(
		p * 2.1
		+
		vec2(
			TIME * 0.011,
			3.7
		)
	);


	float nuvem = (
		camada1 * 0.76
		+
		camada2 * 0.24
	);


	float mascara = smoothstep(
		0.58,
		0.75,
		nuvem
	);


	float dia = (
		cos(
			(UV.x - 0.61)
			*
			6.283185
		)
		*
		0.5
		+
		0.5
	);


	dia = smoothstep(
		0.07,
		0.82,
		dia
	);


	vec3 cor = vec3(
		0.82,
		0.88,
		0.94
	);


	cor *= mix(
		0.10,
		1.0,
		dia
	);


	ALBEDO = cor;


	EMISSION = (
		cor * 0.07
	);


	ALPHA = (
		mascara * 0.46
	);
}
"""


	material.shader = shader


	nuvens.material_override = material


# =========================================================
# ATMOSFERA
# =========================================================

func criar_atmosfera():

	atmosfera = MeshInstance3D.new()

	atmosfera.name = "Atmosphere"


	add_child(
		atmosfera
	)


	atmosfera.position = planeta_posicao


	var esfera := SphereMesh.new()


	esfera.radius = (
		planeta_raio * 1.038
	)


	esfera.height = (
		planeta_raio * 2.076
	)


	esfera.radial_segments = 80

	esfera.rings = 40


	atmosfera.mesh = esfera


	var material := ShaderMaterial.new()

	var shader := Shader.new()


	shader.code = """
shader_type spatial;

render_mode
	unshaded,
	blend_add,
	cull_back,
	depth_draw_never;


void fragment()
{
	float facing = clamp(
		dot(
			normalize(NORMAL),
			normalize(VIEW)
		),
		0.0,
		1.0
	);


	float fresnel = pow(
		1.0 - facing,
		2.7
	);


	vec3 azul = vec3(
		0.035,
		0.30,
		0.95
	);


	ALBEDO = azul;


	EMISSION = (
		azul * 1.65
	);


	ALPHA = (
		fresnel * 0.52
	);
}
"""


	material.shader = shader


	atmosfera.material_override = material


# =========================================================
# ATUALIZAR PLANETA
# =========================================================

func atualizar_planeta(delta: float):

	if planeta != null:

		planeta.rotate_y(
			delta * 0.008
		)


	if nuvens != null:

		nuvens.rotate_y(
			delta * 0.014
		)


	if atmosfera != null:

		atmosfera.rotate_y(
			delta * 0.006
		)


# =========================================================
# CORPOS DISTANTES
# =========================================================

func criar_corpos_distantes():

	criar_corpo_distante(

		"MoonA",

		Vector3(
			-420.0,
			125.0,
			-930.0
		),

		38.0,

		Color(
			0.42,
			0.46,
			0.53
		)
	)


	criar_corpo_distante(

		"MoonB",

		Vector3(
			470.0,
			-150.0,
			-1050.0
		),

		24.0,

		Color(
			0.52,
			0.23,
			0.18
		)
	)


func criar_corpo_distante(
	nome: String,
	posicao: Vector3,
	raio: float,
	cor: Color
):

	var corpo := MeshInstance3D.new()


	corpo.name = nome

	corpo.position = posicao


	var esfera := SphereMesh.new()


	esfera.radius = raio

	esfera.height = raio * 2.0

	esfera.radial_segments = 32

	esfera.rings = 16


	corpo.mesh = esfera


	var material := StandardMaterial3D.new()


	material.albedo_color = cor

	material.roughness = 1.0


	corpo.material_override = material


	fundo_espacial.add_child(
		corpo
	)


# =========================================================
# ASTEROIDES
# =========================================================

func criar_asteroides():

	var mesh_base := SphereMesh.new()


	mesh_base.radius = 1.0

	mesh_base.height = 2.0

	mesh_base.radial_segments = 18

	mesh_base.rings = 12


	for i in range(
		quantidade_asteroides
	):

		var asteroide := MeshInstance3D.new()


		asteroide.name = (
			"Asteroid_%02d"
			%
			i
		)


		asteroide.mesh = mesh_base


		asteroide.position = Vector3(

			randf_range(
				-135.0,
				135.0
			),

			randf_range(
				-80.0,
				80.0
			),

			randf_range(
				-720.0,
				-65.0
			)
		)


		var tamanho: float = randf_range(
			0.9,
			4.5
		)


		if randf() < 0.08:

			tamanho *= randf_range(
				1.8,
				2.8
			)


		asteroide.scale = Vector3(

			tamanho
			*
			randf_range(
				0.58,
				1.42
			),

			tamanho
			*
			randf_range(
				0.54,
				1.35
			),

			tamanho
			*
			randf_range(
				0.60,
				1.50
			)
		)


		asteroide.rotation = Vector3(

			randf_range(
				0.0,
				TAU
			),

			randf_range(
				0.0,
				TAU
			),

			randf_range(
				0.0,
				TAU
			)
		)


		asteroide.material_override = (
			criar_material_asteroide(
				randf_range(
					0.0,
					1000.0
				)
			)
		)


		add_child(
			asteroide
		)


		asteroides.append(
			asteroide
		)


		velocidades_asteroides.append(

			Vector3(

				randf_range(
					-0.16,
					0.16
				),

				randf_range(
					-0.20,
					0.20
				),

				randf_range(
					-0.14,
					0.14
				)
			)
		)


func atualizar_asteroides(delta: float):

	for i in range(
		asteroides.size()
	):

		if is_instance_valid(
			asteroides[i]
		):

			asteroides[i].rotation += (
				velocidades_asteroides[i]
				*
				delta
			)


# =========================================================
# MATERIAL DOS ASTEROIDES
# =========================================================

func criar_material_asteroide(
	seed: float
) -> ShaderMaterial:

	var material := ShaderMaterial.new()

	var shader := Shader.new()


	shader.code = """
shader_type spatial;

render_mode
	unshaded,
	cull_back;


uniform float seed = 1.0;


float hash3(vec3 p)
{
	p = fract(
		p * 0.3183099
		+
		vec3(
			0.10,
			0.20,
			0.30
		)
	);

	p *= 17.0;

	return fract(
		p.x
		*
		p.y
		*
		p.z
		*
		(
			p.x + p.y + p.z
		)
	);
}


float noise3(vec3 p)
{
	vec3 i = floor(p);

	vec3 f = fract(p);

	f = f * f * (3.0 - 2.0 * f);


	float a = hash3(i);

	float b = hash3(
		i + vec3(1.0,0.0,0.0)
	);

	float c = hash3(
		i + vec3(0.0,1.0,0.0)
	);

	float d = hash3(
		i + vec3(1.0,1.0,0.0)
	);

	float e = hash3(
		i + vec3(0.0,0.0,1.0)
	);

	float f1 = hash3(
		i + vec3(1.0,0.0,1.0)
	);

	float g = hash3(
		i + vec3(0.0,1.0,1.0)
	);

	float h = hash3(
		i + vec3(1.0,1.0,1.0)
	);


	float x1 = mix(
		a,
		b,
		f.x
	);

	float x2 = mix(
		c,
		d,
		f.x
	);

	float x3 = mix(
		e,
		f1,
		f.x
	);

	float x4 = mix(
		g,
		h,
		f.x
	);


	return mix(

		mix(
			x1,
			x2,
			f.y
		),

		mix(
			x3,
			x4,
			f.y
		),

		f.z
	);
}


void vertex()
{
	vec3 p = (
		normalize(VERTEX)
		*
		3.3
	);


	float grande = noise3(
		p + vec3(seed)
	);


	float medio = noise3(
		p * 2.1
		+
		vec3(
			seed * 0.43
		)
	);


	float pequeno = noise3(
		p * 5.0
		+
		vec3(
			seed * 0.17
		)
	);


	float deformacao = (
		(grande - 0.5) * 0.70
		+
		(medio - 0.5) * 0.30
		+
		(pequeno - 0.5) * 0.09
	);


	VERTEX *= (
		1.0
		+
		deformacao
	);
}


void fragment()
{
	vec3 luz = normalize(
		vec3(
			-0.45,
			0.72,
			0.62
		)
	);


	float iluminacao = max(
		dot(
			normalize(NORMAL),
			luz
		),
		0.0
	);


	float superficie = noise3(
		vec3(
			UV * 11.0,
			seed
		)
	);


	float detalhe = noise3(
		vec3(
			UV * 31.0,
			seed * 0.37
		)
	);


	float crateras = noise3(
		vec3(
			UV * 54.0,
			seed * 0.72
		)
	);


	float textura = (
		superficie * 0.55
		+
		detalhe * 0.30
		+
		crateras * 0.15
	);


	vec3 base = vec3(
		0.31,
		0.27,
		0.22
	);


	vec3 escuro = (
		base * 0.38
	);


	vec3 claro = (
		base * 1.30
	);


	vec3 cor = mix(
		escuro,
		claro,
		textura
	);


	cor *= (
		0.23
		+
		iluminacao * 0.77
	);


	ALBEDO = cor;
}
"""


	material.shader = shader


	material.set_shader_parameter(
		"seed",
		seed
	)


	return material


# =========================================================
# TURBO VISUAL
# =========================================================

func criar_riscos_turbo():

	if player == null:
		return


	riscos_turbo = MultiMeshInstance3D.new()

	riscos_turbo.name = "TurboStarStreaks"


	player.add_child(
		riscos_turbo
	)


	var mesh_risco := BoxMesh.new()


	mesh_risco.size = Vector3(
		0.035,
		0.035,
		1.0
	)


	var material := StandardMaterial3D.new()


	material.albedo_color = Color(
		0.82,
		0.92,
		1.0,
		0.85
	)


	material.transparency = (
		BaseMaterial3D.TRANSPARENCY_ALPHA
	)


	material.vertex_color_use_as_albedo = true


	material.emission_enabled = true


	material.emission = Color(
		0.55,
		0.80,
		1.0
	)


	material.emission_energy_multiplier = 3.0


	material.shading_mode = (
		BaseMaterial3D.SHADING_MODE_UNSHADED
	)


	material.cull_mode = (
		BaseMaterial3D.CULL_DISABLED
	)


	mesh_risco.material = material


	multimesh_turbo = MultiMesh.new()


	multimesh_turbo.transform_format = (
		MultiMesh.TRANSFORM_3D
	)


	multimesh_turbo.use_colors = true

	multimesh_turbo.mesh = mesh_risco


	multimesh_turbo.instance_count = (
		quantidade_riscos_turbo
	)


	for i in range(
		quantidade_riscos_turbo
	):

		var posicao: Vector3 = (
			criar_posicao_risco(
				true
			)
		)


		riscos_posicoes.append(
			posicao
		)


		riscos_comprimentos.append(
			randf_range(
				2.5,
				9.0
			)
		)


		riscos_larguras.append(
			randf_range(
				0.55,
				1.45
			)
		)


		multimesh_turbo.set_instance_transform(
			i,

			Transform3D(
				Basis.IDENTITY,
				posicao
			)
		)


		multimesh_turbo.set_instance_color(
			i,

			Color(
				0.78,
				0.90,
				1.0,

				randf_range(
					0.35,
					0.85
				)
			)
		)


	riscos_turbo.multimesh = (
		multimesh_turbo
	)


	riscos_turbo.visible = false


# =========================================================
# POSICAO DOS RISCOS DO TURBO
# =========================================================

func criar_posicao_risco(
	inicial: bool
) -> Vector3:

	var z: float = randf_range(
		-145.0,
		-15.0
	)


	if !inicial:

		z = randf_range(
			-150.0,
			-100.0
		)


	var profundidade: float = absf(
		z
	)


	var abertura: float = lerpf(
		8.0,
		38.0,

		clampf(
			profundidade / 150.0,
			0.0,
			1.0
		)
	)


	return Vector3(

		randf_range(
			-abertura,
			abertura
		),

		randf_range(
			-abertura * 0.56,
			abertura * 0.56
		),

		z
	)


# =========================================================
# ATUALIZAR TURBO
# =========================================================

func atualizar_turbo(delta: float):

	if player == null:
		return


	if riscos_turbo == null:
		return


	if multimesh_turbo == null:
		return


	var turbo_ativo: bool = (
		Input.is_key_pressed(
			KEY_SHIFT
		)
	)


	var alvo: float = 0.0


	if turbo_ativo:

		alvo = 1.0


	var transicao: float = 4.5


	if turbo_ativo:

		transicao = 7.0


	intensidade_turbo = lerpf(
		intensidade_turbo,
		alvo,

		minf(
			1.0,
			delta * transicao
		)
	)


	riscos_turbo.visible = (
		intensidade_turbo > 0.025
	)


	if !riscos_turbo.visible:

		return


	var velocidade: float = lerpf(
		35.0,
		230.0,
		intensidade_turbo
	)


	for i in range(
		quantidade_riscos_turbo
	):

		var posicao: Vector3 = (
			riscos_posicoes[i]
		)


		posicao.z += (
			velocidade * delta
		)


		if posicao.z > -3.0:

			posicao = criar_posicao_risco(
				false
			)


		riscos_posicoes[i] = posicao


		var comprimento: float = lerpf(
			0.08,
			riscos_comprimentos[i],
			intensidade_turbo
		)


		var largura: float = (
			riscos_larguras[i]
			*
			lerpf(
				0.20,
				1.0,
				intensidade_turbo
			)
		)


		var escala: Vector3 = Vector3(
			largura,
			largura,
			comprimento
		)


		multimesh_turbo.set_instance_transform(
			i,

			Transform3D(

				Basis.IDENTITY.scaled(
					escala
				),

				posicao
			)
		)
