extends Node3D

# =========================================================
# LAST SECOND - SISTEMA DE OCORRENCIAS v4.1
# Nave suspeita se movimenta desde o nascimento da ocorrencia.
# Quando a perseguicao comeca, o CockpitFX chama iniciar_perseguicao().
# =========================================================

@export var tempo_primeira_ocorrencia: float = 3.0
@export var tempo_entre_ocorrencias: float = 7.0
@export var escala_nave: float = 2.0

# Movimento antes da abordagem
@export var velocidade_patrulha_angular: float = 0.12
@export var raio_patrulha_x: float = 58.0
@export var raio_patrulha_z: float = 42.0
@export var altura_patrulha: float = 10.0

var nave_atual: Node3D = null
var planeta_atual: Node3D = null

var ocorrencia_ativa: bool = false
var esperando_ocorrencia: bool = true
var contador_ocorrencia: float = 3.0
var indice_anterior: int = -1

var movimento_pre_abordagem_ativo: bool = false
var centro_movimento: Vector3 = Vector3.ZERO
var angulo_movimento: float = 0.0

var rng: RandomNumberGenerator = RandomNumberGenerator.new()

# Dados lidos pelo cockpit
var titulo_ocorrencia: String = ""
var setor_ocorrencia: String = ""
var prioridade_ocorrencia: String = ""
var objetivo_ocorrencia: String = ""
var planeta_ocorrencia: String = ""

var ocorrencias: Array = [
	{
		"titulo": "TRANSPONDER DESLIGADO",
		"planeta": "Mercurio",
		"setor": "ORBITA DE MERCURIO",
		"prioridade": "MEDIA",
		"objetivo": "IDENTIFICAR NAVE",
		"distancia": 180.0
	},
	{
		"titulo": "SINAL DE SOCORRO SUSPEITO",
		"planeta": "Venus",
		"setor": "PROXIMIDADES DE VENUS",
		"prioridade": "MEDIA",
		"objetivo": "VERIFICAR SINAL",
		"distancia": 220.0
	},
	{
		"titulo": "NAVE SEM IDENTIFICACAO",
		"planeta": "Marte",
		"setor": "ORBITA DE MARTE",
		"prioridade": "MEDIA",
		"objetivo": "INTERCEPTAR E IDENTIFICAR",
		"distancia": 190.0
	},
	{
		"titulo": "SUSPEITA DE CONTRABANDO",
		"planeta": "Jupiter",
		"setor": "CORREDOR DE JUPITER",
		"prioridade": "ALTA",
		"objetivo": "LOCALIZAR E ESCANEAR",
		"distancia": 500.0
	},
	{
		"titulo": "NAVE ROUBADA LOCALIZADA",
		"planeta": "Saturno",
		"setor": "ORBITA DE SATURNO",
		"prioridade": "ALTA",
		"objetivo": "INTERCEPTAR VEICULO",
		"distancia": 550.0
	},
	{
		"titulo": "NAVE PROCURADA DETECTADA",
		"planeta": "Urano",
		"setor": "CORREDOR DE URANO",
		"prioridade": "ALTA",
		"objetivo": "INTERCEPTAR E ABORDAR",
		"distancia": 400.0
	},
	{
		"titulo": "INVASAO DE ROTA RESTRITA",
		"planeta": "Netuno",
		"setor": "SETOR RESTRITO DE NETUNO",
		"prioridade": "ALTA",
		"objetivo": "INTERCEPTAR NAVE",
		"distancia": 420.0
	}
]

func _ready() -> void:
	rng.randomize()
	contador_ocorrencia = tempo_primeira_ocorrencia
	print("CENTRAL DE OPERACOES ONLINE")
	print("PATRULHAMENTO ATIVO")
	print("OCORRENCIA EM ", tempo_primeira_ocorrencia, " SEGUNDOS")

func _process(delta: float) -> void:
	if ocorrencia_ativa:
		if movimento_pre_abordagem_ativo:
			atualizar_movimento_pre_abordagem(delta)
		return

	if !esperando_ocorrencia:
		return

	contador_ocorrencia -= delta
	if contador_ocorrencia > 0.0:
		return

	esperando_ocorrencia = false
	criar_nova_ocorrencia()

func criar_nova_ocorrencia() -> void:
	if ocorrencia_ativa:
		return

	var cena: Node = get_tree().current_scene
	if cena == null:
		reagendar()
		return

	var player: Node3D = cena.get_node_or_null("Player") as Node3D
	if player == null:
		push_warning("SuspectTest: Player nao encontrado.")
		reagendar()
		return

	var indice_inicial: int = rng.randi_range(0, ocorrencias.size() - 1)
	var dados_escolhidos: Dictionary = {}
	var planeta_encontrado: Node3D = null
	var indice_escolhido: int = -1

	for tentativa: int in range(ocorrencias.size()):
		var indice: int = (indice_inicial + tentativa) % ocorrencias.size()
		if indice == indice_anterior and ocorrencias.size() > 1:
			continue

		var dados: Dictionary = ocorrencias[indice]
		var nome_planeta: String = String(dados["planeta"])
		var resultado: Node = encontrar_node_recursivo(cena, nome_planeta)

		if resultado is Node3D:
			planeta_encontrado = resultado as Node3D
			dados_escolhidos = dados
			indice_escolhido = indice
			break

	if planeta_encontrado == null:
		# Segunda passada permitindo repeticao, caso apenas um planeta esteja disponivel.
		for indice: int in range(ocorrencias.size()):
			var dados: Dictionary = ocorrencias[indice]
			var resultado: Node = encontrar_node_recursivo(cena, String(dados["planeta"]))
			if resultado is Node3D:
				planeta_encontrado = resultado as Node3D
				dados_escolhidos = dados
				indice_escolhido = indice
				break

	if planeta_encontrado == null:
		push_warning("SuspectTest: nenhum planeta da lista foi encontrado.")
		reagendar()
		return

	indice_anterior = indice_escolhido
	planeta_atual = planeta_encontrado

	titulo_ocorrencia = String(dados_escolhidos["titulo"])
	planeta_ocorrencia = String(dados_escolhidos["planeta"])
	setor_ocorrencia = String(dados_escolhidos["setor"])
	prioridade_ocorrencia = String(dados_escolhidos["prioridade"])
	objetivo_ocorrencia = String(dados_escolhidos["objetivo"])

	nave_atual = criar_nave_procedural()
	nave_atual.name = "NaveSuspeitaTeste"
	add_child(nave_atual)
	nave_atual.scale = Vector3.ONE * escala_nave

	var direcao_player: Vector3 = player.global_position - planeta_atual.global_position
	if direcao_player.length() <= 0.01:
		direcao_player = Vector3(0.0, 0.0, 1.0)
	direcao_player = direcao_player.normalized()

	var distancia_planeta: float = float(dados_escolhidos["distancia"])
	var lateral: Vector3 = Vector3(
		rng.randf_range(-80.0, 80.0),
		rng.randf_range(25.0, 90.0),
		rng.randf_range(-80.0, 80.0)
	)

	nave_atual.global_position = (
		planeta_atual.global_position
		+ direcao_player * distancia_planeta
		+ lateral
	)

	centro_movimento = nave_atual.global_position
	angulo_movimento = rng.randf_range(0.0, TAU)
	movimento_pre_abordagem_ativo = true
	ocorrencia_ativa = true

	print("====================================")
	print("NOVA OCORRENCIA RECEBIDA")
	print("TIPO: ", titulo_ocorrencia)
	print("PLANETA: ", planeta_ocorrencia)
	print("SETOR: ", setor_ocorrencia)
	print("PRIORIDADE: ", prioridade_ocorrencia)
	print("====================================")

func atualizar_movimento_pre_abordagem(delta: float) -> void:
	if nave_atual == null or !is_instance_valid(nave_atual):
		return

	var posicao_anterior: Vector3 = nave_atual.global_position
	angulo_movimento += velocidade_patrulha_angular * delta

	var deslocamento: Vector3 = Vector3(
		cos(angulo_movimento) * raio_patrulha_x,
		sin(angulo_movimento * 1.35) * altura_patrulha,
		sin(angulo_movimento) * raio_patrulha_z
	)

	nave_atual.global_position = centro_movimento + deslocamento

	var direcao: Vector3 = nave_atual.global_position - posicao_anterior
	if direcao.length() > 0.01:
		nave_atual.look_at(
			nave_atual.global_position + direcao.normalized() * 20.0,
			Vector3.UP
		)

# Chamado pelo cockpit quando o suspeito ignora a ordem e inicia fuga.
func iniciar_perseguicao() -> void:
	movimento_pre_abordagem_ativo = false

# Chamado pelo cockpit quando o alvo se rende.
func parar_movimento() -> void:
	movimento_pre_abordagem_ativo = false

func encerrar_ocorrencia() -> void:
	ocorrencia_ativa = false
	movimento_pre_abordagem_ativo = false
	nave_atual = null
	planeta_atual = null
	esperando_ocorrencia = true
	contador_ocorrencia = tempo_entre_ocorrencias
	print("OCORRENCIA ENCERRADA - NOVA EM ", tempo_entre_ocorrencias, " SEGUNDOS")

func reagendar() -> void:
	ocorrencia_ativa = false
	movimento_pre_abordagem_ativo = false
	esperando_ocorrencia = true
	contador_ocorrencia = 2.0

func criar_nave_procedural() -> Node3D:
	var nave: Node3D = Node3D.new()

	var metal_escuro: StandardMaterial3D = StandardMaterial3D.new()
	metal_escuro.albedo_color = Color(0.07, 0.09, 0.12, 1.0)
	metal_escuro.metallic = 0.85
	metal_escuro.roughness = 0.30

	var metal_laranja: StandardMaterial3D = StandardMaterial3D.new()
	metal_laranja.albedo_color = Color(0.90, 0.20, 0.03, 1.0)
	metal_laranja.metallic = 0.65
	metal_laranja.roughness = 0.35

	var vidro: StandardMaterial3D = StandardMaterial3D.new()
	vidro.albedo_color = Color(0.03, 0.30, 0.55, 0.55)
	vidro.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	vidro.metallic = 0.25
	vidro.roughness = 0.12
	vidro.emission_enabled = true
	vidro.emission = Color(0.02, 0.20, 0.45, 1.0)
	vidro.emission_energy_multiplier = 1.6

	var motor_mat: StandardMaterial3D = StandardMaterial3D.new()
	motor_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	motor_mat.albedo_color = Color(0.05, 0.55, 1.0, 1.0)
	motor_mat.emission_enabled = true
	motor_mat.emission = Color(0.02, 0.45, 1.0, 1.0)
	motor_mat.emission_energy_multiplier = 6.0

	var corpo: MeshInstance3D = MeshInstance3D.new()
	var corpo_mesh: BoxMesh = BoxMesh.new()
	corpo_mesh.size = Vector3(8.0, 2.0, 16.0)
	corpo.mesh = corpo_mesh
	corpo.material_override = metal_escuro
	nave.add_child(corpo)

	var nariz: MeshInstance3D = MeshInstance3D.new()
	var nariz_mesh: CylinderMesh = CylinderMesh.new()
	nariz_mesh.top_radius = 0.15
	nariz_mesh.bottom_radius = 3.6
	nariz_mesh.height = 6.0
	nariz_mesh.radial_segments = 8
	nariz.mesh = nariz_mesh
	nariz.material_override = metal_escuro
	nariz.position = Vector3(0.0, 0.0, -10.0)
	nariz.rotation.x = deg_to_rad(90.0)
	nave.add_child(nariz)

	var cockpit: MeshInstance3D = MeshInstance3D.new()
	var cockpit_mesh: SphereMesh = SphereMesh.new()
	cockpit_mesh.radius = 2.4
	cockpit_mesh.height = 3.0
	cockpit_mesh.radial_segments = 20
	cockpit_mesh.rings = 10
	cockpit.mesh = cockpit_mesh
	cockpit.material_override = vidro
	cockpit.position = Vector3(0.0, 2.0, -4.8)
	cockpit.scale = Vector3(1.0, 0.65, 1.45)
	nave.add_child(cockpit)

	for lado: float in [-1.0, 1.0]:
		var asa: MeshInstance3D = MeshInstance3D.new()
		var asa_mesh: BoxMesh = BoxMesh.new()
		asa_mesh.size = Vector3(8.0, 0.55, 7.0)
		asa.mesh = asa_mesh
		asa.material_override = metal_escuro
		asa.position = Vector3(5.0 * lado, -0.2, 1.5)
		asa.rotation.z = deg_to_rad(-8.0 * lado)
		nave.add_child(asa)

		var detalhe: MeshInstance3D = MeshInstance3D.new()
		var detalhe_mesh: BoxMesh = BoxMesh.new()
		detalhe_mesh.size = Vector3(2.8, 0.18, 4.8)
		detalhe.mesh = detalhe_mesh
		detalhe.material_override = metal_laranja
		detalhe.position = Vector3(5.8 * lado, 0.15, 0.8)
		nave.add_child(detalhe)

	for x: float in [-2.6, 2.6]:
		var motor: MeshInstance3D = MeshInstance3D.new()
		var motor_mesh: CylinderMesh = CylinderMesh.new()
		motor_mesh.top_radius = 0.9
		motor_mesh.bottom_radius = 0.9
		motor_mesh.height = 2.0
		motor_mesh.radial_segments = 16
		motor.mesh = motor_mesh
		motor.material_override = motor_mat
		motor.position = Vector3(x, 0.0, 9.0)
		motor.rotation.x = deg_to_rad(90.0)
		nave.add_child(motor)

		var luz_motor: OmniLight3D = OmniLight3D.new()
		luz_motor.light_color = Color(0.05, 0.45, 1.0, 1.0)
		luz_motor.light_energy = 5.0
		luz_motor.omni_range = 10.0
		luz_motor.position = Vector3(x, 0.0, 10.0)
		nave.add_child(luz_motor)

	var luz_topo: OmniLight3D = OmniLight3D.new()
	luz_topo.light_color = Color(1.0, 0.12, 0.02, 1.0)
	luz_topo.light_energy = 3.5
	luz_topo.omni_range = 9.0
	luz_topo.position = Vector3(0.0, 3.0, 0.0)
	nave.add_child(luz_topo)

	return nave

func encontrar_node_recursivo(no_atual: Node, nome_procurado: String) -> Node:
	if String(no_atual.name) == nome_procurado:
		return no_atual

	for filho: Node in no_atual.get_children():
		var resultado: Node = encontrar_node_recursivo(filho, nome_procurado)
		if resultado != null:
			return resultado

	return null
