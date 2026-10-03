extends Node


# ============================================================
# LAST SECOND
# TRIPULACAO DO HANGAR v2.2
#
# CICLO DAS VIATURAS:
#
# JOGO INICIOU
#       ↓
# 30 segundos
#       ↓
# P-02 sai
#       ↓
# fica 60 segundos em ocorrencia
#       ↓
# retorna e estaciona
#       ↓
# sorteia entre 10 e 120 segundos
#       ↓
# P-03 sai
#       ↓
# retorna
#       ↓
# novo sorteio
#       ↓
# P-04 sai
#       ↓
# depois volta para P-02
#
# NUNCA DUAS UNIDADES SAEM AO MESMO TEMPO.
# ============================================================


# ============================================================
# DESPACHOS
# ============================================================

@export_category("Despachos")

# Primeira unidade sai 30 segundos apos abrir o jogo.
@export var tempo_primeiro_despacho: float = 30.0

# Depois de cada retorno:
# minimo de 10 segundos.
@export var intervalo_minimo_retorno: float = 10.0

# maximo de 2 minutos.
@export var intervalo_maximo_retorno: float = 120.0

# Unidade fica 1 minuto fora.
@export var duracao_ocorrencia: float = 60.0

# Tempo para aguardar o portao abrir.
@export var espera_portao: float = 4.8


# ============================================================
# MOVIMENTO
# ============================================================

@export_category("Movimento")

@export var velocidade_policial: float = 3.2

@export var velocidade_giro: float = 7.5

@export var distancia_chegada: float = 0.65

@export var distancia_separacao: float = 1.8

@export var forca_separacao: float = 1.25

@export var tempo_considerado_preso: float = 1.8


# ============================================================
# NAVEGACAO
# ============================================================

@export_category("Navegacao")

@export var tamanho_celula: float = 2.0


# ============================================================
# REFERENCIAS
# ============================================================

var cena: Node = null

var hangar: Node3D = null

var player_on_foot: CharacterBody3D = null

var visual_base: Node3D = null

var portao_saida: Node = null


# ============================================================
# TAMANHO DO HANGAR
# ============================================================

var largura_hangar: float = 150.0

var profundidade_hangar: float = 180.0


# ============================================================
# ASTAR
# ============================================================

var astar: AStarGrid2D = null

var grid_largura: int = 0

var grid_altura: int = 0

var origem_grid_x: float = 0.0

var origem_grid_z: float = 0.0


# ============================================================
# UNIDADES
# ============================================================

var unidades: Array[Dictionary] = []


# ============================================================
# SISTEMA DE DESPACHO
# ============================================================

var tempo_proximo_despacho: float = 30.0

var indice_proximo_despacho: int = 0

var despacho_agendado: bool = true

var unidade_fora_da_base: bool = false


# ============================================================
# READY
# ============================================================

func _ready() -> void:

	process_mode = Node.PROCESS_MODE_ALWAYS


	await get_tree().process_frame
	await get_tree().process_frame
	await get_tree().physics_frame
	await get_tree().process_frame


	localizar_sistemas()


	if hangar == null:

		push_error(
			"TRIPULACAO: HangarBase nao encontrado."
		)

		return


	if player_on_foot == null:

		push_error(
			"TRIPULACAO: PlayerOnFoot nao encontrado."
		)

		return


	ler_dimensoes_hangar()


	# ========================================================
	# ESPERA O TRAJE DO JOGADOR
	# ========================================================

	for i: int in range(30):

		visual_base = player_on_foot.get_node_or_null(
			"Visual"
		) as Node3D


		if visual_base != null:

			if visual_base.has_node(
				"TrajePoliciaInterplanetaria"
			):

				break


		await get_tree().process_frame


	criar_mapa_navegacao()

	criar_unidades()


	# ========================================================
	# PRIMEIRA SAIDA
	# ========================================================

	tempo_proximo_despacho = tempo_primeiro_despacho

	despacho_agendado = true

	unidade_fora_da_base = false

	indice_proximo_despacho = 0


	print(
		"============================================"
	)

	print(
		"TRIPULACAO DO HANGAR v2.2"
	)

	print(
		"PRIMEIRA OCORRENCIA EM ",
		tempo_primeiro_despacho,
		" SEGUNDOS"
	)

	print(
		"RETORNO APOS ",
		duracao_ocorrencia,
		" SEGUNDOS"
	)

	print(
		"PROXIMO DESPACHO: ALEATORIO ATE 2 MINUTOS"
	)

	print(
		"============================================"
	)



# ============================================================
# LOCALIZAR SISTEMAS
# ============================================================

func localizar_sistemas() -> void:

	cena = get_tree().current_scene


	if cena == null:

		return


	var encontrado_hangar: Node = cena.find_child(
		"HangarBase",
		true,
		false
	)


	if encontrado_hangar is Node3D:

		hangar = encontrado_hangar as Node3D


	var encontrado_pe: Node = cena.find_child(
		"PlayerOnFoot",
		true,
		false
	)


	if encontrado_pe is CharacterBody3D:

		player_on_foot = (
			encontrado_pe
			as CharacterBody3D
		)


	var encontrado_portao: Node = cena.find_child(
		"PortaoSaida",
		true,
		false
	)


	if encontrado_portao != null:

		portao_saida = encontrado_portao



# ============================================================
# DIMENSOES
# ============================================================

func ler_dimensoes_hangar() -> void:


	var valor_largura: Variant = hangar.get(
		"largura_hangar"
	)


	var valor_profundidade: Variant = hangar.get(
		"profundidade_hangar"
	)


	if valor_largura != null:

		largura_hangar = float(
			valor_largura
		)


	if valor_profundidade != null:

		profundidade_hangar = float(
			valor_profundidade
		)



# ============================================================
# CRIAR ASTAR
# ============================================================

func criar_mapa_navegacao() -> void:


	origem_grid_x = (
		-largura_hangar / 2.0
		+ 2.0
	)


	origem_grid_z = (
		-profundidade_hangar / 2.0
		+ 2.0
	)


	grid_largura = int(
		floor(
			(largura_hangar - 4.0)
			/ tamanho_celula
		)
	) + 1


	grid_altura = int(
		floor(
			(profundidade_hangar - 4.0)
			/ tamanho_celula
		)
	) + 1


	astar = AStarGrid2D.new()


	astar.region = Rect2i(
		0,
		0,
		grid_largura,
		grid_altura
	)


	astar.cell_size = Vector2(
		tamanho_celula,
		tamanho_celula
	)


	astar.diagonal_mode = (
		AStarGrid2D.DIAGONAL_MODE_NEVER
	)


	astar.update()


	marcar_paredes_salas()

	marcar_obstaculos_naves()



# ============================================================
# SALAS
# ============================================================

func marcar_paredes_salas() -> void:


	var salas_z: Array[float] = [
		-67.0,
		-23.0,
		23.0,
		67.0
	]


	var lados: Array[float] = [
		-1.0,
		1.0
	]


	for lado: float in lados:

		var parede_x: float = lado * 65.0


		for z_sala: float in salas_z:


			marcar_retangulo(
				parede_x,
				z_sala,
				1.4,
				17.0,
				true
			)


			# Porta livre

			marcar_retangulo(
				parede_x,
				z_sala,
				2.6,
				3.7,
				false
			)


			marcar_retangulo(
				lado * 70.0,
				z_sala - 17.0,
				5.5,
				1.1,
				true
			)


			marcar_retangulo(
				lado * 70.0,
				z_sala + 17.0,
				5.5,
				1.1,
				true
			)



# ============================================================
# NAVES COMO OBSTACULOS
# ============================================================

func marcar_obstaculos_naves() -> void:


	marcar_retangulo(
		-36.0,
		-43.0,
		7.0,
		10.0,
		true
	)


	marcar_retangulo(
		-36.0,
		43.0,
		8.5,
		11.0,
		true
	)


	marcar_retangulo(
		36.0,
		43.0,
		9.5,
		12.0,
		true
	)


	marcar_retangulo(
		36.0,
		-43.0,
		10.0,
		13.0,
		true
	)



# ============================================================
# MARCAR AREA
# ============================================================

func marcar_retangulo(
	centro_x: float,
	centro_z: float,
	meia_largura: float,
	meia_profundidade: float,
	solido: bool
) -> void:


	if astar == null:

		return


	var minimo := Vector3(
		centro_x - meia_largura,
		0.0,
		centro_z - meia_profundidade
	)


	var maximo := Vector3(
		centro_x + meia_largura,
		0.0,
		centro_z + meia_profundidade
	)


	var celula_min: Vector2i = local_para_celula(
		minimo
	)


	var celula_max: Vector2i = local_para_celula(
		maximo
	)


	for x: int in range(
		celula_min.x,
		celula_max.x + 1
	):

		for y: int in range(
			celula_min.y,
			celula_max.y + 1
		):

			var id := Vector2i(
				x,
				y
			)


			if !celula_valida(
				id
			):

				continue


			astar.set_point_solid(
				id,
				solido
			)



# ============================================================
# LOCAL -> CELULA
# ============================================================

func local_para_celula(
	posicao: Vector3
) -> Vector2i:


	var x: int = int(
		round(
			(posicao.x - origem_grid_x)
			/ tamanho_celula
		)
	)


	var y: int = int(
		round(
			(posicao.z - origem_grid_z)
			/ tamanho_celula
		)
	)


	return Vector2i(
		x,
		y
	)



# ============================================================
# CELULA -> LOCAL
# ============================================================

func celula_para_local(
	id: Vector2i
) -> Vector3:


	return Vector3(
		origem_grid_x
		+ float(id.x) * tamanho_celula,

		0.08,

		origem_grid_z
		+ float(id.y) * tamanho_celula
	)



# ============================================================
# CELULA VALIDA
# ============================================================

func celula_valida(
	id: Vector2i
) -> bool:


	return (
		id.x >= 0
		and id.y >= 0
		and id.x < grid_largura
		and id.y < grid_altura
	)



# ============================================================
# CELULA LIVRE
# ============================================================

func encontrar_celula_livre(
	original: Vector2i
) -> Vector2i:


	if celula_valida(
		original
	):

		if !astar.is_point_solid(
			original
		):

			return original


	for raio: int in range(
		1,
		8
	):

		for x: int in range(
			-raio,
			raio + 1
		):

			for y: int in range(
				-raio,
				raio + 1
			):

				var candidato := Vector2i(
					original.x + x,
					original.y + y
				)


				if !celula_valida(
					candidato
				):

					continue


				if !astar.is_point_solid(
					candidato
				):

					return candidato


	return original



# ============================================================
# CRIAR CAMINHO
# ============================================================

func criar_caminho(
	inicio_global: Vector3,
	destino_local: Vector3
) -> Array:


	var resultado: Array = []


	if astar == null:

		resultado.append(
			hangar.to_global(
				destino_local
			)
		)

		return resultado


	var inicio_local: Vector3 = hangar.to_local(
		inicio_global
	)


	var celula_inicio: Vector2i = (
		encontrar_celula_livre(
			local_para_celula(
				inicio_local
			)
		)
	)


	var celula_destino: Vector2i = (
		encontrar_celula_livre(
			local_para_celula(
				destino_local
			)
		)
	)


	var caminho: Array = astar.get_id_path(
		celula_inicio,
		celula_destino,
		true
	)


	if caminho.is_empty():

		resultado.append(
			hangar.to_global(
				destino_local
			)
		)

		return resultado


	for i: int in range(
		caminho.size()
	):

		if i == 0:

			continue


		var valor_id: Variant = caminho[i]


		if !(valor_id is Vector2i):

			continue


		var id: Vector2i = valor_id


		resultado.append(
			hangar.to_global(
				celula_para_local(
					id
				)
			)
		)


	return resultado



# ============================================================
# CRIAR UNIDADES
# ============================================================

func criar_unidades() -> void:


	var tarefas_p02: Array = [

		{
			"nome": "SALA DE CONTROLE",
			"atividade": "CONSOLE",
			"tempo": 55.0,
			"destino": Vector3(
				66.0,
				0.08,
				67.0
			)
		},

		{
			"nome": "REFEITORIO",
			"atividade": "REFEICAO",
			"tempo": 45.0,
			"destino": Vector3(
				-66.0,
				0.08,
				23.0
			)
		},

		{
			"nome": "COMBUSTIVEL",
			"atividade": "INSPECAO",
			"tempo": 45.0,
			"destino": Vector3(
				-66.0,
				0.08,
				-23.0
			)
		}

	]


	var tarefas_p03: Array = [

		{
			"nome": "OFICINA MECANICA",
			"atividade": "MANUTENCAO",
			"tempo": 60.0,
			"destino": Vector3(
				-66.0,
				0.08,
				-67.0
			)
		},

		{
			"nome": "EQUIPAMENTOS",
			"atividade": "INSPECAO",
			"tempo": 50.0,
			"destino": Vector3(
				66.0,
				0.08,
				-23.0
			)
		},

		{
			"nome": "ZONA DE CARGA",
			"atividade": "INSPECAO",
			"tempo": 50.0,
			"destino": Vector3(
				66.0,
				0.08,
				-67.0
			)
		}

	]


	var tarefas_p04: Array = [

		{
			"nome": "DORMITORIOS",
			"atividade": "DORMIR",
			"tempo": 70.0,
			"destino": Vector3(
				-66.0,
				0.08,
				67.0
			)
		},

		{
			"nome": "SALA DE JOGOS",
			"atividade": "LAZER",
			"tempo": 55.0,
			"destino": Vector3(
				66.0,
				0.08,
				23.0
			)
		},

		{
			"nome": "REFEITORIO",
			"atividade": "REFEICAO",
			"tempo": 45.0,
			"destino": Vector3(
				-66.0,
				0.08,
				23.0
			)
		}

	]


	criar_unidade(
		"P02",
		"Policial_P02",
		tarefas_p02
	)


	criar_unidade(
		"P03",
		"Policial_P03",
		tarefas_p03
	)


	criar_unidade(
		"P04",
		"Policial_P04",
		tarefas_p04
	)



# ============================================================
# CRIAR UNIDADE
# ============================================================

func criar_unidade(
	codigo: String,
	nome_policial: String,
	tarefas: Array
) -> void:


	var nave: Node3D = encontrar_nave(
		codigo
	)


	var spawn_local: Vector3 = pegar_spawn_npc(
		codigo,
		nave
	)


	var policial := CharacterBody3D.new()

	policial.name = nome_policial

	policial.collision_layer = 1

	policial.collision_mask = 1

	policial.floor_snap_length = 0.55

	policial.floor_max_angle = deg_to_rad(
		48.0
	)


	cena.add_child(
		policial
	)


	policial.global_position = hangar.to_global(
		spawn_local
	)


	var collision := CollisionShape3D.new()


	var capsule := CapsuleShape3D.new()

	capsule.radius = 0.34

	capsule.height = 1.80


	collision.shape = capsule

	collision.position = Vector3(
		0.0,
		0.90,
		0.0
	)


	policial.add_child(
		collision
	)


	var visual_npc: Node3D = null


	if visual_base != null:

		var duplicado: Node = visual_base.duplicate()


		if duplicado is Node3D:

			visual_npc = duplicado as Node3D

			visual_npc.name = "Visual"

			visual_npc.visible = true


			policial.add_child(
				visual_npc
			)


	if visual_npc == null:

		visual_npc = criar_visual_fallback()


		policial.add_child(
			visual_npc
		)


	criar_identificacao_npc(
		visual_npc,
		codigo
	)


	var posicao_nave := Vector3.ZERO

	var rotacao_nave := Vector3.ZERO


	if nave != null:

		posicao_nave = nave.global_position

		rotacao_nave = nave.global_rotation


	var unidade: Dictionary = {

		"codigo": codigo,

		"policial": policial,

		"visual": visual_npc,

		"collision": collision,

		"nave": nave,

		"posicao_nave": posicao_nave,

		"rotacao_nave": rotacao_nave,

		"tarefas": tarefas,

		"indice_tarefa": 0,

		"tarefa_atual": {},

		"estado": "BASE",

		"atividade": "PARADO",

		"tempo_atividade": 0.0,

		"tempo_missao": 0.0,

		"rota": [],

		"destino_final_local": spawn_local,

		"fase_animacao": randf_range(
			0.0,
			TAU
		),

		"tempo_preso": 0.0,

		"visual_pos_original": visual_npc.position,

		"visual_rot_original": visual_npc.rotation,

		"perna_l": localizar_parte(
			visual_npc,
			[
				"PernaL_Pivo",
				"PernaL"
			]
		),

		"perna_r": localizar_parte(
			visual_npc,
			[
				"PernaR_Pivo",
				"PernaR"
			]
		),

		"braco_l": localizar_parte(
			visual_npc,
			[
				"BracoL_Pivo",
				"BracoL"
			]
		),

		"braco_r": localizar_parte(
			visual_npc,
			[
				"BracoR_Pivo",
				"BracoR"
			]
		)

	}


	unidades.append(
		unidade
	)


	var indice: int = unidades.size() - 1


	atribuir_proxima_tarefa(
		indice
	)



# ============================================================
# PROCESS
# ============================================================

func _process(
	delta: float
) -> void:


	if get_tree().paused:

		return


	# ========================================================
	# CONTAGEM PARA A PROXIMA SAIDA
	#
	# So existe cronometro quando nenhuma unidade esta fora.
	# ========================================================

	if (
		despacho_agendado
		and !unidade_fora_da_base
	):

		tempo_proximo_despacho -= delta


		if tempo_proximo_despacho <= 0.0:

			despacho_agendado = false

			despachar_proxima_unidade()


	# ========================================================
	# TEMPO DAS OCORRENCIAS
	# ========================================================

	for i: int in range(
		unidades.size()
	):

		var unidade: Dictionary = unidades[i]


		var estado: String = String(
			unidade.get(
				"estado",
				""
			)
		)


		if estado != "MISSAO":

			continue


		var tempo: float = float(
			unidade.get(
				"tempo_missao",
				0.0
			)
		)


		tempo -= delta


		unidade["tempo_missao"] = tempo

		unidades[i] = unidade


		if tempo <= 0.0:

			unidade["estado"] = (
				"RETORNO_SOLICITADO"
			)


			unidades[i] = unidade


			retornar_unidade(
				i
			)


	# ========================================================
	# TAREFAS DA BASE
	# ========================================================

	for i: int in range(
		unidades.size()
	):

		atualizar_atividade(
			i,
			delta
		)



# ============================================================
# PHYSICS
# ============================================================

func _physics_process(
	delta: float
) -> void:


	if get_tree().paused:

		return


	for i: int in range(
		unidades.size()
	):

		processar_movimento(
			i,
			delta
		)



# ============================================================
# MOVIMENTO
# ============================================================

func processar_movimento(
	indice: int,
	delta: float
) -> void:


	if indice < 0:

		return


	if indice >= unidades.size():

		return


	var unidade: Dictionary = unidades[indice]


	var policial: CharacterBody3D = (
		unidade.get(
			"policial"
		)
		as CharacterBody3D
	)


	if policial == null:

		return


	if !policial.visible:

		return


	var rota: Array = unidade.get(
		"rota",
		[]
	)


	if rota.is_empty():

		policial.velocity.x = 0.0

		policial.velocity.z = 0.0

		return


	var alvo: Vector3 = rota[0]


	var diferenca: Vector3 = (
		alvo
		- policial.global_position
	)


	diferenca.y = 0.0


	var distancia: float = diferenca.length()


	if distancia <= distancia_chegada:

		rota.remove_at(
			0
		)


		unidade["rota"] = rota

		unidade["tempo_preso"] = 0.0


		unidades[indice] = unidade


		if rota.is_empty():

			chegou_destino(
				indice
			)


		return


	var direcao: Vector3 = diferenca.normalized()


	var separacao: Vector3 = calcular_separacao(
		indice
	)


	direcao += (
		separacao
		* forca_separacao
	)


	direcao.y = 0.0


	if direcao.length() > 0.01:

		direcao = direcao.normalized()


	policial.velocity.x = (
		direcao.x
		* velocidade_policial
	)


	policial.velocity.z = (
		direcao.z
		* velocidade_policial
	)


	var yaw_alvo: float = atan2(
		-direcao.x,
		-direcao.z
	)


	policial.rotation.y = lerp_angle(
		policial.rotation.y,
		yaw_alvo,
		clampf(
			delta * velocidade_giro,
			0.0,
			1.0
		)
	)


	if policial.is_on_floor():

		policial.velocity.y = -0.5

	else:

		policial.velocity.y -= (
			18.0
			* delta
		)


	var posicao_antes: Vector3 = (
		policial.global_position
	)


	policial.move_and_slide()


	var local: Vector3 = hangar.to_local(
		policial.global_position
	)


	if local.y < 0.02:

		local.y = 0.08


		policial.global_position = hangar.to_global(
			local
		)


		policial.velocity.y = 0.0


	# ========================================================
	# DETECTAR PRESO
	# ========================================================

	var movimento_real: float = (
		policial.global_position.distance_to(
			posicao_antes
		)
	)


	var tempo_preso: float = float(
		unidade.get(
			"tempo_preso",
			0.0
		)
	)


	if movimento_real < 0.008:

		tempo_preso += delta

	else:

		tempo_preso = 0.0


	unidade["tempo_preso"] = tempo_preso


	if tempo_preso >= tempo_considerado_preso:

		unidade["tempo_preso"] = 0.0

		unidades[indice] = unidade


		recalcular_rota(
			indice
		)

		return


	var fase: float = float(
		unidade.get(
			"fase_animacao",
			0.0
		)
	)


	fase += delta * 8.0


	unidade["fase_animacao"] = fase

	unidade["rota"] = rota


	animar_caminhada(
		unidade,
		fase
	)


	unidades[indice] = unidade



# ============================================================
# SEPARACAO
# ============================================================

func calcular_separacao(
	indice: int
) -> Vector3:


	var resultado := Vector3.ZERO


	var unidade_atual: Dictionary = unidades[
		indice
	]


	var atual: CharacterBody3D = (
		unidade_atual.get(
			"policial"
		)
		as CharacterBody3D
	)


	if atual == null:

		return resultado


	for i: int in range(
		unidades.size()
	):

		if i == indice:

			continue


		var outra_unidade: Dictionary = unidades[i]


		var outro: CharacterBody3D = (
			outra_unidade.get(
				"policial"
			)
			as CharacterBody3D
		)


		if outro == null:

			continue


		if !outro.visible:

			continue


		var diferenca: Vector3 = (
			atual.global_position
			- outro.global_position
		)


		diferenca.y = 0.0


		var distancia: float = diferenca.length()


		if distancia <= 0.01:

			continue


		if distancia > distancia_separacao:

			continue


		var peso: float = (
			1.0
			- distancia / distancia_separacao
		)


		resultado += (
			diferenca.normalized()
			* peso
		)


	return resultado



# ============================================================
# RECALCULAR ROTA
# ============================================================

func recalcular_rota(
	indice: int
) -> void:


	var unidade: Dictionary = unidades[indice]


	var policial: CharacterBody3D = (
		unidade.get(
			"policial"
		)
		as CharacterBody3D
	)


	if policial == null:

		return


	var destino: Vector3 = unidade.get(
		"destino_final_local",
		Vector3.ZERO
	)


	unidade["rota"] = criar_caminho(
		policial.global_position,
		destino
	)


	unidades[indice] = unidade



# ============================================================
# CAMINHADA
# ============================================================

func animar_caminhada(
	unidade: Dictionary,
	fase: float
) -> void:


	var perna_l: Node3D = (
		unidade.get(
			"perna_l"
		)
		as Node3D
	)


	var perna_r: Node3D = (
		unidade.get(
			"perna_r"
		)
		as Node3D
	)


	var braco_l: Node3D = (
		unidade.get(
			"braco_l"
		)
		as Node3D
	)


	var braco_r: Node3D = (
		unidade.get(
			"braco_r"
		)
		as Node3D
	)


	var ciclo: float = sin(
		fase
	)


	if perna_l != null:

		perna_l.rotation.x = (
			ciclo
			* deg_to_rad(24.0)
		)


	if perna_r != null:

		perna_r.rotation.x = (
			-ciclo
			* deg_to_rad(24.0)
		)


	if braco_l != null:

		braco_l.rotation.x = (
			-ciclo
			* deg_to_rad(16.0)
		)


	if braco_r != null:

		braco_r.rotation.x = (
			ciclo
			* deg_to_rad(16.0)
		)



# ============================================================
# CHEGOU
# ============================================================

func chegou_destino(
	indice: int
) -> void:


	var unidade: Dictionary = unidades[indice]


	zerar_pose(
		unidade
	)


	var estado: String = String(
		unidade.get(
			"estado",
			""
		)
	)


	if estado == "INDO_NAVE":

		unidade["estado"] = "EMBARCANDO"

		unidades[indice] = unidade


		embarcar_e_sair(
			indice
		)

		return


	if estado == "INDO_TAREFA":

		unidade["estado"] = "TRABALHANDO"


		var tarefa: Dictionary = unidade.get(
			"tarefa_atual",
			{}
		)


		unidade["atividade"] = String(
			tarefa.get(
				"atividade",
				"PARADO"
			)
		)


		unidade["tempo_atividade"] = float(
			tarefa.get(
				"tempo",
				45.0
			)
		)


		unidades[indice] = unidade


		aplicar_pose_atividade(
			indice
		)



# ============================================================
# PROXIMA TAREFA
# ============================================================

func atribuir_proxima_tarefa(
	indice: int
) -> void:


	var unidade: Dictionary = unidades[
		indice
	]


	var estado: String = String(
		unidade.get(
			"estado",
			""
		)
	)


	if estado in [
		"MISSAO",
		"SAINDO",
		"RETORNANDO",
		"INDO_NAVE",
		"EMBARCANDO"
	]:

		return


	var policial: CharacterBody3D = (
		unidade.get(
			"policial"
		)
		as CharacterBody3D
	)


	if policial == null:

		return


	var atividade_anterior: String = String(
		unidade.get(
			"atividade",
			""
		)
	)


	zerar_pose(
		unidade
	)


	if atividade_anterior == "DORMIR":

		policial.global_position = hangar.to_global(
			Vector3(
				-66.0,
				0.08,
				67.0
			)
		)


	var tarefas: Array = unidade.get(
		"tarefas",
		[]
	)


	if tarefas.is_empty():

		return


	var indice_tarefa: int = int(
		unidade.get(
			"indice_tarefa",
			0
		)
	)


	if indice_tarefa >= tarefas.size():

		indice_tarefa = 0


	var tarefa: Dictionary = tarefas[
		indice_tarefa
	]


	unidade["indice_tarefa"] = (
		indice_tarefa + 1
	) % tarefas.size()


	unidade["tarefa_atual"] = tarefa

	unidade["estado"] = "INDO_TAREFA"

	unidade["atividade"] = "CAMINHANDO"


	var destino: Vector3 = tarefa.get(
		"destino",
		Vector3.ZERO
	)


	unidade["destino_final_local"] = destino


	unidade["rota"] = criar_caminho(
		policial.global_position,
		destino
	)


	unidades[indice] = unidade



# ============================================================
# ATIVIDADES
# ============================================================

func atualizar_atividade(
	indice: int,
	delta: float
) -> void:


	var unidade: Dictionary = unidades[
		indice
	]


	if String(
		unidade.get(
			"estado",
			""
		)
	) != "TRABALHANDO":

		return


	var tempo: float = float(
		unidade.get(
			"tempo_atividade",
			0.0
		)
	)


	tempo -= delta


	unidade["tempo_atividade"] = tempo


	var fase: float = float(
		unidade.get(
			"fase_animacao",
			0.0
		)
	)


	fase += delta * 2.0


	unidade["fase_animacao"] = fase


	var atividade: String = String(
		unidade.get(
			"atividade",
			""
		)
	)


	if atividade == "CONSOLE":

		animar_console(
			unidade,
			fase
		)


	elif atividade == "MANUTENCAO":

		animar_manutencao(
			unidade,
			fase
		)


	elif atividade == "INSPECAO":

		animar_inspecao(
			unidade,
			fase
		)


	elif atividade == "LAZER":

		animar_lazer(
			unidade,
			fase
		)


	unidades[indice] = unidade


	if tempo <= 0.0:

		atribuir_proxima_tarefa(
			indice
		)



# ============================================================
# POSE
# ============================================================

func aplicar_pose_atividade(
	indice: int
) -> void:


	var unidade: Dictionary = unidades[
		indice
	]


	var atividade: String = String(
		unidade.get(
			"atividade",
			""
		)
	)


	var policial: CharacterBody3D = (
		unidade.get(
			"policial"
		)
		as CharacterBody3D
	)


	var visual: Node3D = (
		unidade.get(
			"visual"
		)
		as Node3D
	)


	var collision: CollisionShape3D = (
		unidade.get(
			"collision"
		)
		as CollisionShape3D
	)


	if visual == null:

		return


	if atividade == "DORMIR":

		if policial != null:

			policial.global_position = hangar.to_global(
				Vector3(
					-71.0,
					0.55,
					72.5
				)
			)


		visual.rotation_degrees = Vector3(
			0.0,
			0.0,
			90.0
		)


		visual.position.y = 0.55


		if collision != null:

			collision.disabled = true



# ============================================================
# RESET POSE
# ============================================================

func zerar_pose(
	unidade: Dictionary
) -> void:


	var visual: Node3D = (
		unidade.get(
			"visual"
		)
		as Node3D
	)


	var collision: CollisionShape3D = (
		unidade.get(
			"collision"
		)
		as CollisionShape3D
	)


	if visual != null:

		var posicao_original: Vector3 = unidade.get(
			"visual_pos_original",
			Vector3.ZERO
		)


		var rotacao_original: Vector3 = unidade.get(
			"visual_rot_original",
			Vector3.ZERO
		)


		visual.position = posicao_original

		visual.rotation = rotacao_original


	if collision != null:

		collision.disabled = false


	var membros: Array[String] = [
		"perna_l",
		"perna_r",
		"braco_l",
		"braco_r"
	]


	for chave: String in membros:

		var membro: Node3D = (
			unidade.get(
				chave
			)
			as Node3D
		)


		if membro != null:

			membro.rotation = Vector3.ZERO



# ============================================================
# ANIMACOES
# ============================================================

func animar_console(
	unidade: Dictionary,
	fase: float
) -> void:


	var esquerdo: Node3D = (
		unidade.get(
			"braco_l"
		)
		as Node3D
	)


	var direito: Node3D = (
		unidade.get(
			"braco_r"
		)
		as Node3D
	)


	if esquerdo != null:

		esquerdo.rotation.x = deg_to_rad(
			-35.0
			+ sin(fase * 3.0) * 8.0
		)


	if direito != null:

		direito.rotation.x = deg_to_rad(
			-35.0
			- sin(fase * 3.0) * 8.0
		)



func animar_manutencao(
	unidade: Dictionary,
	fase: float
) -> void:


	var esquerdo: Node3D = (
		unidade.get(
			"braco_l"
		)
		as Node3D
	)


	var direito: Node3D = (
		unidade.get(
			"braco_r"
		)
		as Node3D
	)


	if esquerdo != null:

		esquerdo.rotation.x = deg_to_rad(
			-40.0
			+ sin(fase * 4.0) * 20.0
		)


	if direito != null:

		direito.rotation.x = deg_to_rad(
			-55.0
			- sin(fase * 4.0) * 18.0
		)



func animar_inspecao(
	unidade: Dictionary,
	fase: float
) -> void:


	var policial: CharacterBody3D = (
		unidade.get(
			"policial"
		)
		as CharacterBody3D
	)


	if policial != null:

		policial.rotation.y += (
			sin(fase)
			* 0.002
		)



func animar_lazer(
	unidade: Dictionary,
	fase: float
) -> void:


	var direito: Node3D = (
		unidade.get(
			"braco_r"
		)
		as Node3D
	)


	if direito != null:

		direito.rotation.x = deg_to_rad(
			-20.0
			+ sin(fase * 2.0) * 10.0
		)



# ============================================================
# DESPACHAR PROXIMA UNIDADE
# ============================================================

func despachar_proxima_unidade() -> void:


	if unidades.is_empty():

		agendar_proximo_despacho()

		return


	# ========================================================
	# PROCURAR A UNIDADE DA VEZ
	# ========================================================

	for tentativa: int in range(
		unidades.size()
	):

		var indice: int = (
			indice_proximo_despacho
			+ tentativa
		) % unidades.size()


		var unidade: Dictionary = unidades[
			indice
		]


		var estado: String = String(
			unidade.get(
				"estado",
				""
			)
		)


		if estado in [
			"MISSAO",
			"SAINDO",
			"RETORNANDO",
			"INDO_NAVE",
			"EMBARCANDO"
		]:

			continue


		# ====================================================
		# PROXIMA SERA A UNIDADE SEGUINTE
		# ====================================================

		indice_proximo_despacho = (
			indice + 1
		) % unidades.size()


		unidade_fora_da_base = true

		despacho_agendado = false


		iniciar_despacho(
			indice
		)

		return


	# Caso nenhuma esteja disponivel.

	tempo_proximo_despacho = 10.0

	despacho_agendado = true



# ============================================================
# AGENDAR PROXIMA SAIDA
# ============================================================

func agendar_proximo_despacho() -> void:


	# ========================================================
	# SORTEIO ENTRE 10 SEGUNDOS E 2 MINUTOS
	# ========================================================

	tempo_proximo_despacho = randf_range(
		intervalo_minimo_retorno,
		intervalo_maximo_retorno
	)


	despacho_agendado = true


	print(
		">>> PROXIMA UNIDADE SAIRA EM ",
		roundf(
			tempo_proximo_despacho
		),
		" SEGUNDOS"
	)



# ============================================================
# INICIAR DESPACHO
# ============================================================

func iniciar_despacho(
	indice: int
) -> void:


	var unidade: Dictionary = unidades[
		indice
	]


	var policial: CharacterBody3D = (
		unidade.get(
			"policial"
		)
		as CharacterBody3D
	)


	var nave: Node3D = (
		unidade.get(
			"nave"
		)
		as Node3D
	)


	var codigo: String = String(
		unidade.get(
			"codigo",
			""
		)
	)


	if policial == null:

		unidade_fora_da_base = false

		agendar_proximo_despacho()

		return


	# ========================================================
	# ACORDAR
	# ========================================================

	if String(
		unidade.get(
			"atividade",
			""
		)
	) == "DORMIR":

		zerar_pose(
			unidade
		)


		policial.global_position = hangar.to_global(
			Vector3(
				-66.0,
				0.08,
				67.0
			)
		)


	zerar_pose(
		unidade
	)


	var destino: Vector3 = pegar_ponto_embarque(
		codigo,
		nave
	)


	unidade["estado"] = "INDO_NAVE"

	unidade["atividade"] = "OCORRENCIA"

	unidade["destino_final_local"] = destino


	unidade["rota"] = criar_caminho(
		policial.global_position,
		destino
	)


	unidades[indice] = unidade


	print(
		">>> ",
		codigo,
		" RECEBEU UMA OCORRENCIA"
	)



# ============================================================
# EMBARCAR E SAIR
# ============================================================

func embarcar_e_sair(
	indice: int
) -> void:


	var unidade: Dictionary = unidades[
		indice
	]


	var policial: CharacterBody3D = (
		unidade.get(
			"policial"
		)
		as CharacterBody3D
	)


	var collision: CollisionShape3D = (
		unidade.get(
			"collision"
		)
		as CollisionShape3D
	)


	var nave: Node3D = (
		unidade.get(
			"nave"
		)
		as Node3D
	)


	var codigo: String = String(
		unidade.get(
			"codigo",
			""
		)
	)


	unidade["estado"] = "SAINDO"

	unidades[indice] = unidade


	if policial != null:

		policial.visible = false

		policial.velocity = Vector3.ZERO


	if collision != null:

		collision.disabled = true


	if nave == null:

		iniciar_tempo_missao(
			indice
		)

		return


	# ========================================================
	# LIGAR MOTOR / ABRIR PORTAO
	# ========================================================

	set_motor_portao(
		codigo,
		true
	)


	await get_tree().create_timer(
		espera_portao
	).timeout


	var metade: float = (
		profundidade_hangar / 2.0
	)


	var ponto_interno: Vector3 = hangar.to_global(
		Vector3(
			0.0,
			8.0,
			-68.0
		)
	)


	var ponto_portao: Vector3 = hangar.to_global(
		Vector3(
			0.0,
			10.0,
			-metade + 7.0
		)
	)


	var ponto_externo: Vector3 = hangar.to_global(
		Vector3(
			0.0,
			18.0,
			-metade - 70.0
		)
	)


	var tween := create_tween()


	tween.set_trans(
		Tween.TRANS_SINE
	)


	tween.set_ease(
		Tween.EASE_IN_OUT
	)


	tween.tween_property(
		nave,
		"global_position",
		ponto_interno,
		2.5
	)


	tween.tween_property(
		nave,
		"global_position",
		ponto_portao,
		3.0
	)


	tween.tween_property(
		nave,
		"global_position",
		ponto_externo,
		3.0
	)


	await tween.finished


	nave.visible = false


	set_motor_portao(
		codigo,
		false
	)


	iniciar_tempo_missao(
		indice
	)



# ============================================================
# MISSAO
# ============================================================

func iniciar_tempo_missao(
	indice: int
) -> void:


	var unidade: Dictionary = unidades[
		indice
	]


	unidade["estado"] = "MISSAO"

	unidade["tempo_missao"] = duracao_ocorrencia


	unidades[indice] = unidade


	print(
		">>> ",
		String(
			unidade.get(
				"codigo",
				""
			)
		),
		" EM OCORRENCIA POR ",
		duracao_ocorrencia,
		" SEGUNDOS"
	)



# ============================================================
# RETORNAR
# ============================================================

func retornar_unidade(
	indice: int
) -> void:


	var unidade: Dictionary = unidades[
		indice
	]


	var nave: Node3D = (
		unidade.get(
			"nave"
		)
		as Node3D
	)


	var codigo: String = String(
		unidade.get(
			"codigo",
			""
		)
	)


	unidade["estado"] = "RETORNANDO"

	unidades[indice] = unidade


	if nave == null:

		finalizar_retorno(
			indice
		)

		return


	var metade: float = (
		profundidade_hangar / 2.0
	)


	var ponto_externo: Vector3 = hangar.to_global(
		Vector3(
			0.0,
			18.0,
			-metade - 70.0
		)
	)


	var ponto_portao: Vector3 = hangar.to_global(
		Vector3(
			0.0,
			10.0,
			-metade + 7.0
		)
	)


	var ponto_interno: Vector3 = hangar.to_global(
		Vector3(
			0.0,
			8.0,
			-68.0
		)
	)


	nave.global_position = ponto_externo

	nave.visible = true


	set_motor_portao(
		codigo,
		true
	)


	await get_tree().create_timer(
		espera_portao
	).timeout


	var tween := create_tween()


	tween.set_trans(
		Tween.TRANS_SINE
	)


	tween.set_ease(
		Tween.EASE_IN_OUT
	)


	tween.tween_property(
		nave,
		"global_position",
		ponto_portao,
		3.0
	)


	tween.tween_property(
		nave,
		"global_position",
		ponto_interno,
		3.0
	)


	var posicao_original: Vector3 = unidade.get(
		"posicao_nave",
		Vector3.ZERO
	)


	tween.tween_property(
		nave,
		"global_position",
		posicao_original,
		3.5
	)


	await tween.finished


	nave.global_position = posicao_original


	var rotacao_original: Vector3 = unidade.get(
		"rotacao_nave",
		Vector3.ZERO
	)


	nave.global_rotation = rotacao_original


	set_motor_portao(
		codigo,
		false
	)


	finalizar_retorno(
		indice
	)



# ============================================================
# FINALIZAR RETORNO
# ============================================================

func finalizar_retorno(
	indice: int
) -> void:


	var unidade: Dictionary = unidades[
		indice
	]


	var policial: CharacterBody3D = (
		unidade.get(
			"policial"
		)
		as CharacterBody3D
	)


	var collision: CollisionShape3D = (
		unidade.get(
			"collision"
		)
		as CollisionShape3D
	)


	var nave: Node3D = (
		unidade.get(
			"nave"
		)
		as Node3D
	)


	var codigo: String = String(
		unidade.get(
			"codigo",
			""
		)
	)


	var embarque: Vector3 = pegar_ponto_embarque(
		codigo,
		nave
	)


	if policial != null:

		policial.global_position = hangar.to_global(
			embarque
		)


		policial.visible = true

		policial.velocity = Vector3.ZERO


	if collision != null:

		collision.disabled = false


	unidade["estado"] = "BASE"

	unidade["atividade"] = "PARADO"

	unidade["rota"] = []


	unidades[indice] = unidade


	print(
		">>> ",
		codigo,
		" RETORNOU PARA A BASE"
	)


	# ========================================================
	# AGORA SIM LIBERA A PROXIMA UNIDADE
	#
	# Nenhum cronometro comeca antes do retorno completo.
	# ========================================================

	unidade_fora_da_base = false


	agendar_proximo_despacho()


	# ========================================================
	# POLICIAL RETOMA SUA ROTINA
	# ========================================================

	atribuir_proxima_tarefa(
		indice
	)



# ============================================================
# PORTAO
# ============================================================

func set_motor_portao(
	codigo: String,
	ligado: bool
) -> void:


	if portao_saida == null:

		localizar_sistemas()


	if portao_saida == null:

		return


	if portao_saida.has_method(
		"set_motor_nave"
	):

		portao_saida.call(
			"set_motor_nave",
			codigo,
			ligado
		)



# ============================================================
# ENCONTRAR NAVE
# ============================================================

func encontrar_nave(
	codigo: String
) -> Node3D:


	if cena == null:

		return null


	var nome_nave: String = ""


	match codigo:

		"P02":

			nome_nave = "P02_InterceptorPatrulha"


		"P03":

			nome_nave = "P03_CargueiroMilitar"


		"P04":

			nome_nave = "P04_CacaAvancado"


		_:

			return null


	var encontrado: Node = cena.find_child(
		nome_nave,
		true,
		false
	)


	if encontrado is Node3D:

		return encontrado as Node3D


	return null



# ============================================================
# SPAWN
# ============================================================

func pegar_spawn_npc(
	codigo: String,
	nave: Node3D
) -> Vector3:


	if nave != null:

		var local: Vector3 = hangar.to_local(
			nave.global_position
		)


		local.y = 0.08


		if local.x < 0.0:

			local.x += 12.0

		else:

			local.x -= 12.0


		return encontrar_posicao_local_livre(
			local
		)


	match codigo:

		"P02":

			return Vector3(
				-20.0,
				0.08,
				43.0
			)


		"P03":

			return Vector3(
				20.0,
				0.08,
				43.0
			)


		"P04":

			return Vector3(
				20.0,
				0.08,
				-43.0
			)


	return Vector3.ZERO



# ============================================================
# EMBARQUE
# ============================================================

func pegar_ponto_embarque(
	codigo: String,
	nave: Node3D
) -> Vector3:


	if nave == null:

		match codigo:

			"P02":

				return Vector3(
					-20.0,
					0.08,
					43.0
				)


			"P03":

				return Vector3(
					20.0,
					0.08,
					43.0
				)


			"P04":

				return Vector3(
					20.0,
					0.08,
					-43.0
				)


		return Vector3.ZERO


	var local: Vector3 = hangar.to_local(
		nave.global_position
	)


	local.y = 0.08


	if local.x < 0.0:

		local.x += 12.0

	else:

		local.x -= 12.0


	return encontrar_posicao_local_livre(
		local
	)



# ============================================================
# POSICAO LIVRE
# ============================================================

func encontrar_posicao_local_livre(
	posicao: Vector3
) -> Vector3:


	if astar == null:

		return posicao


	var celula: Vector2i = encontrar_celula_livre(
		local_para_celula(
			posicao
		)
	)


	return celula_para_local(
		celula
	)



# ============================================================
# LOCALIZAR MEMBRO
# ============================================================

func localizar_parte(
	raiz: Node,
	nomes: Array
) -> Node3D:


	for valor_nome: Variant in nomes:

		var nome: String = String(
			valor_nome
		)


		var encontrado: Node = raiz.find_child(
			nome,
			true,
			false
		)


		if encontrado is Node3D:

			return encontrado as Node3D


	return null



# ============================================================
# IDENTIFICACAO
# ============================================================

func criar_identificacao_npc(
	visual: Node3D,
	codigo: String
) -> void:


	var label := Label3D.new()


	label.name = (
		"Identificacao_"
		+ codigo
	)


	label.text = codigo.insert(
		1,
		"-"
	)


	label.position = Vector3(
		0.0,
		1.45,
		0.35
	)


	label.font_size = 32

	label.pixel_size = 0.004

	label.outline_size = 5


	label.modulate = Color(
		0.0,
		0.85,
		1.0
	)


	label.outline_modulate = Color.BLACK


	visual.add_child(
		label
	)



# ============================================================
# FALLBACK
# ============================================================

func criar_visual_fallback() -> Node3D:


	var root := Node3D.new()

	root.name = "Visual"


	var material := StandardMaterial3D.new()


	material.albedo_color = Color(
		0.025,
		0.045,
		0.075
	)


	material.metallic = 0.45


	criar_caixa_fallback(
		root,

		Vector3(
			0.88,
			0.78,
			0.42
		),

		Vector3(
			0.0,
			1.10,
			0.0
		),

		material
	)


	var pernas_x: Array[float] = [
		-0.20,
		0.20
	]


	for x: float in pernas_x:

		criar_caixa_fallback(
			root,

			Vector3(
				0.28,
				0.72,
				0.28
			),

			Vector3(
				x,
				0.42,
				0.0
			),

			material
		)


	var bracos_x: Array[float] = [
		-0.58,
		0.58
	]


	for x: float in bracos_x:

		criar_caixa_fallback(
			root,

			Vector3(
				0.24,
				0.72,
				0.24
			),

			Vector3(
				x,
				1.08,
				0.0
			),

			material
		)


	return root



# ============================================================
# CAIXA FALLBACK
# ============================================================

func criar_caixa_fallback(
	pai: Node3D,
	tamanho: Vector3,
	posicao: Vector3,
	material: Material
) -> void:


	var objeto := MeshInstance3D.new()


	var mesh := BoxMesh.new()

	mesh.size = tamanho


	objeto.mesh = mesh

	objeto.position = posicao

	objeto.material_override = material


	pai.add_child(
		objeto
	)
