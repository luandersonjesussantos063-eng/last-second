extends Control

# =========================================================
# LAST SECOND - POLICE COCKPIT SYSTEM v6.3 // FREE FIRE + PHYSICS HIT
# E = scanner (SuspectTargetHUD)
# F = ordem de parada
# ESPACO = disparo livre; ABATE LIBERADO continua valendo para dano no suspeito
#
# NOVO v6.2:
# - usa a P-02 REAL estacionada no HangarBase
# - P-02 sai da vaga, entra na pista e cruza o portao
# - depois acelera por ~20 segundos ate a P-01
# - vem por tras, ultrapassa e assume a dianteira
# - ao fim da ocorrencia, retorna para a vaga
# =========================================================

@export var unidades_por_km: float = 1.0
@export var distancia_abordagem: float = 220.0

# Suspeito
@export var velocidade_fuga_inicial: float = 18.0
@export var velocidade_fuga_maxima: float = 32.0

# Reforco
@export var tempo_para_acionar_reforco: float = 1.0
@export var tempo_chegada_reforco: float = 20.0
@export var distancia_spawn_atras: float = 520.0
@export var distancia_final_a_frente: float = 150.0
@export var tempo_ultima_ordem: float = 2.0
@export var tempo_para_rendicao: float = 6.0
@export_range(0.0, 1.0) var chance_rendicao: float = 0.35

# Arma
@export var alcance_arma: float = 550.0
@export var velocidade_tiro: float = 300.0
@export var intervalo_disparo: float = 0.20
@export var dano_tiro: float = 20.0
@export var vida_alvo_maxima: float = 100.0

# Referencias
var player: Node3D = null
var nave_suspeita: Node3D = null
var scanner: Node = null
var suspect_test: Node = null
var hangar_base: Node = null

# Painel
var painel: Panel = null
var barra_status: ColorRect = null
var label_agencia: Label = null
var label_status: Label = null
var label_ocorrencia: Label = null
var label_setor: Label = null
var label_distancia: Label = null
var label_prioridade: Label = null
var label_objetivo: Label = null

# Dados da ocorrencia
var titulo_missao: String = "NAVE NAO IDENTIFICADA"
var setor_missao: String = "SETOR DESCONHECIDO"
var prioridade_missao: String = "MEDIA"
var objetivo_missao: String = "INTERCEPTAR E IDENTIFICAR"

# Tempo
var tempo: float = 0.0
var tempo_busca: float = 0.0
var tempo_pos_encerramento: float = 0.0

# Audio
var radio_player: AudioStreamPlayer = null
var explosion_player: AudioStreamPlayer = null
var arma_players: Array = []
var indice_audio_arma: int = 0
var som_tiro: AudioStreamWAV = null
var som_explosao: AudioStreamWAV = null

# Ordem inicial
enum EstadoOrdem {
	NAO_DISPONIVEL,
	AGUARDANDO_ORDEM,
	ORDEM_TRANSMITIDA,
	ALVO_EM_FUGA
}
var estado_ordem: int = EstadoOrdem.NAO_DISPONIVEL
var tempo_ordem: float = 0.0
var f_estava_pressionado: bool = false

# Procedimento
enum EstadoProcedimento {
	BLOQUEADO,
	ACIONANDO_REFORCO,
	REFORCO_A_CAMINHO,
	REFORCO_NO_LOCAL,
	ULTIMA_ORDEM,
	AGUARDANDO_RENDICAO,
	ABATE_LIBERADO,
	ALVO_RENDIDO,
	ALVO_ABATIDO
}
var estado_procedimento: int = EstadoProcedimento.BLOQUEADO
var tempo_procedimento: float = 0.0
var decisao_rendicao_feita: bool = false

# Fuga
var fuga_ativa: bool = false
var velocidade_fuga: float = 0.0
var direcao_fuga: Vector3 = Vector3.ZERO

# Reforco P-02
var reforco: Node3D = null
var reforco_no_local: bool = false
var reforco_tempo_voo: float = 0.0
var reforco_do_hangar: bool = false
var reforco_posicao_inicio: Vector3 = Vector3.ZERO
var reforco_corredor_hangar: Vector3 = Vector3.ZERO
var reforco_portao_hangar: Vector3 = Vector3.ZERO
var reforco_saida_hangar: Vector3 = Vector3.ZERO
var reforco_luz_vermelha: OmniLight3D = null
var reforco_luz_azul: OmniLight3D = null
var reforco_mesh_vermelho: MeshInstance3D = null
var reforco_mesh_azul: MeshInstance3D = null

# Giroflex P-01
var luz_vermelha: OmniLight3D = null
var luz_azul: OmniLight3D = null
var giroflex_ativo: bool = false
var tempo_giroflex: float = 0.0
var fase_giroflex: bool = false

# Arma / efeitos
var vida_alvo: float = 100.0
var cooldown_tiro: float = 0.0
var projeteis: Array = []
var efeitos: Array = []
var fragmentos: Array = []

var rng: RandomNumberGenerator = RandomNumberGenerator.new()

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	rng.randomize()
	vida_alvo = vida_alvo_maxima
	criar_painel_policial()
	criar_sistemas_audio()
	call_deferred("localizar_sistemas")

func localizar_sistemas() -> void:
	await get_tree().process_frame
	await get_tree().process_frame
	player = get_node_or_null("../Player") as Node3D
	scanner = get_node_or_null("../SuspectTargetHUD")
	suspect_test = get_node_or_null("../SuspectTest")
	hangar_base = get_node_or_null("../HangarBase")
	if player != null:
		criar_luzes_policiais()
	procurar_nave_suspeita()

func _process(delta: float) -> void:
	tempo += delta
	tempo_busca += delta

	if cooldown_tiro > 0.0:
		cooldown_tiro -= delta

	atualizar_projeteis(delta)
	atualizar_efeitos(delta)
	atualizar_fragmentos(delta)

	if player == null:
		player = get_node_or_null("../Player") as Node3D
		if player != null:
			criar_luzes_policiais()

	if scanner == null:
		scanner = get_node_or_null("../SuspectTargetHUD")
	if suspect_test == null:
		suspect_test = get_node_or_null("../SuspectTest")
	if hangar_base == null:
		hangar_base = get_node_or_null("../HangarBase")

	# Arma sempre disponivel para meteoros, destrocos e objetos fisicos.
	# A autorizacao do painel continua controlando dano letal no suspeito.
	processar_arma()

	if estado_procedimento == EstadoProcedimento.ALVO_RENDIDO:
		tempo_pos_encerramento += delta
		atualizar_reforco(delta)
		atualizar_luzes_policiais(delta)
		mostrar_alvo_rendido()
		if tempo_pos_encerramento >= 6.0:
			encerrar_ocorrencia_rendida()
		return

	if estado_procedimento == EstadoProcedimento.ALVO_ABATIDO:
		tempo_pos_encerramento += delta
		atualizar_reforco(delta)
		atualizar_luzes_policiais(delta)
		mostrar_alvo_abatido()
		if tempo_pos_encerramento >= 5.0:
			preparar_proxima_ocorrencia()
		return

	if nave_suspeita == null:
		if tempo_busca >= 0.5:
			tempo_busca = 0.0
			procurar_nave_suspeita()
		mostrar_patrulhamento()
		atualizar_luzes_policiais(delta)
		return

	if !is_instance_valid(nave_suspeita):
		nave_suspeita = null
		return

	processar_ordem_parada(delta)

	if fuga_ativa:
		atualizar_fuga(delta)

	processar_procedimento(delta)
	atualizar_reforco(delta)
	atualizar_luzes_policiais(delta)
	atualizar_painel()

func procurar_nave_suspeita() -> void:
	if suspect_test == null:
		suspect_test = get_node_or_null("../SuspectTest")
	if suspect_test == null:
		return

	var resultado: Node = encontrar_node_recursivo(suspect_test, "NaveSuspeitaTeste")
	if !(resultado is Node3D):
		return

	nave_suspeita = resultado as Node3D
	garantir_colisao_e_radar_suspeito(nave_suspeita)
	vida_alvo = vida_alvo_maxima
	estado_ordem = EstadoOrdem.NAO_DISPONIVEL
	estado_procedimento = EstadoProcedimento.BLOQUEADO
	fuga_ativa = false
	velocidade_fuga = 0.0
	tempo_ordem = 0.0
	tempo_procedimento = 0.0
	tempo_pos_encerramento = 0.0
	decisao_rendicao_feita = false
	reforco_no_local = false
	reforco_tempo_voo = 0.0
	remover_reforco()
	carregar_dados_ocorrencia()
	resetar_scanner()
	tocar_alerta_radio()

func garantir_colisao_e_radar_suspeito(alvo: Node3D) -> void:
	if alvo == null:
		return

	alvo.add_to_group("radar_targets")
	alvo.add_to_group("suspect_target")
	alvo.set_meta("radar_kind", "suspect")

	if alvo.get_node_or_null("PhysicsProxy") != null:
		return

	var corpo := AnimatableBody3D.new()
	corpo.name = "PhysicsProxy"
	corpo.collision_layer = 1
	corpo.collision_mask = 1
	corpo.sync_to_physics = true
	corpo.add_to_group("suspect_target")

	var collision := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = Vector3(9.0, 4.0, 14.0)
	collision.shape = shape
	corpo.add_child(collision)
	alvo.add_child(corpo)


func carregar_dados_ocorrencia() -> void:
	if suspect_test == null:
		return

	var valor: Variant = suspect_test.get("titulo_ocorrencia")
	if valor != null:
		titulo_missao = String(valor)
	valor = suspect_test.get("setor_ocorrencia")
	if valor != null:
		setor_missao = String(valor)
	valor = suspect_test.get("prioridade_ocorrencia")
	if valor != null:
		prioridade_missao = String(valor)
	valor = suspect_test.get("objetivo_ocorrencia")
	if valor != null:
		objetivo_missao = String(valor)

func resetar_scanner() -> void:
	if scanner == null:
		return
	scanner.set("estado_scanner", 0)
	scanner.set("progresso_scan", 0.0)

func pegar_estado_scanner() -> int:
	if scanner == null:
		return 0
	var valor: Variant = scanner.get("estado_scanner")
	if valor == null:
		return 0
	return int(valor)

func processar_ordem_parada(delta: float) -> void:
	var scan: int = pegar_estado_scanner()

	if scan != 2:
		estado_ordem = EstadoOrdem.NAO_DISPONIVEL
		f_estava_pressionado = Input.is_key_pressed(KEY_F)
		return

	if estado_ordem == EstadoOrdem.NAO_DISPONIVEL:
		estado_ordem = EstadoOrdem.AGUARDANDO_ORDEM

	var f_pressionado: bool = Input.is_key_pressed(KEY_F)
	var acabou_de_apertar: bool = f_pressionado and !f_estava_pressionado
	f_estava_pressionado = f_pressionado

	if estado_ordem == EstadoOrdem.AGUARDANDO_ORDEM:
		if acabou_de_apertar:
			estado_ordem = EstadoOrdem.ORDEM_TRANSMITIDA
			tempo_ordem = 0.0
			tocar_confirmacao_central()
		return

	if estado_ordem == EstadoOrdem.ORDEM_TRANSMITIDA:
		tempo_ordem += delta
		if tempo_ordem >= 2.5:
			iniciar_fuga()

func iniciar_fuga() -> void:
	if fuga_ativa:
		return

	estado_ordem = EstadoOrdem.ALVO_EM_FUGA
	estado_procedimento = EstadoProcedimento.ACIONANDO_REFORCO
	tempo_procedimento = 0.0
	fuga_ativa = true
	velocidade_fuga = velocidade_fuga_inicial
	ativar_giroflex(true)

	if suspect_test != null and suspect_test.has_method("iniciar_perseguicao"):
		suspect_test.call("iniciar_perseguicao")

	if player != null and nave_suspeita != null:
		direcao_fuga = (nave_suspeita.global_position - player.global_position).normalized()
	else:
		direcao_fuga = Vector3.FORWARD

	tocar_alerta_radio()
	print("ALVO EM FUGA - CENTRAL ACIONANDO REFORCO")

func atualizar_fuga(delta: float) -> void:
	if nave_suspeita == null or player == null:
		return

	velocidade_fuga = move_toward(
		velocidade_fuga,
		velocidade_fuga_maxima,
		5.0 * delta
	)

	var longe_do_player: Vector3 = nave_suspeita.global_position - player.global_position
	if longe_do_player.length() < 0.01:
		longe_do_player = Vector3.FORWARD
	longe_do_player = longe_do_player.normalized()

	direcao_fuga = direcao_fuga.lerp(
		longe_do_player,
		clampf(delta * 0.55, 0.0, 1.0)
	).normalized()

	var lateral: Vector3 = Vector3.UP.cross(direcao_fuga)
	if lateral.length() < 0.01:
		lateral = Vector3.RIGHT
	lateral = lateral.normalized()

	var manobra: float = sin(tempo * 1.5) * 0.12
	var direcao_final: Vector3 = (direcao_fuga + lateral * manobra).normalized()

	nave_suspeita.global_position += direcao_final * velocidade_fuga * delta
	nave_suspeita.look_at(
		nave_suspeita.global_position + direcao_final * 20.0,
		Vector3.UP
	)

func processar_procedimento(delta: float) -> void:
	if estado_procedimento == EstadoProcedimento.BLOQUEADO:
		return

	if estado_procedimento == EstadoProcedimento.ACIONANDO_REFORCO:
		tempo_procedimento += delta
		if tempo_procedimento >= tempo_para_acionar_reforco:
			# v6.4: reforço P-02 removido temporariamente.
			# O procedimento não trava: a Central segue direto para a última ordem.
			estado_procedimento = EstadoProcedimento.ULTIMA_ORDEM
			tempo_procedimento = 0.0
			tocar_confirmacao_central()
			print("CENTRAL: REFORCO P-02 DESATIVADO - SEGUINDO PARA ULTIMA ORDEM")
		return

	if estado_procedimento == EstadoProcedimento.REFORCO_A_CAMINHO:
		if reforco_no_local:
			estado_procedimento = EstadoProcedimento.REFORCO_NO_LOCAL
			tempo_procedimento = 0.0
			tocar_confirmacao_central()
			print("P-02: REFORCO NO LOCAL - ASSUMINDO DIANTEIRA")
		return

	if estado_procedimento == EstadoProcedimento.REFORCO_NO_LOCAL:
		tempo_procedimento += delta
		if tempo_procedimento >= 1.5:
			estado_procedimento = EstadoProcedimento.ULTIMA_ORDEM
			tempo_procedimento = 0.0
			tocar_alerta_radio()
		return

	if estado_procedimento == EstadoProcedimento.ULTIMA_ORDEM:
		tempo_procedimento += delta
		if tempo_procedimento >= tempo_ultima_ordem:
			estado_procedimento = EstadoProcedimento.AGUARDANDO_RENDICAO
			tempo_procedimento = 0.0
		return

	if estado_procedimento == EstadoProcedimento.AGUARDANDO_RENDICAO:
		tempo_procedimento += delta
		if tempo_procedimento >= tempo_para_rendicao:
			decidir_rendicao()

func decidir_rendicao() -> void:
	if decisao_rendicao_feita:
		return
	decisao_rendicao_feita = true

	if rng.randf() <= chance_rendicao:
		suspeito_se_rende()
	else:
		liberar_abate()

func suspeito_se_rende() -> void:
	estado_procedimento = EstadoProcedimento.ALVO_RENDIDO
	fuga_ativa = false
	velocidade_fuga = 0.0
	tempo_pos_encerramento = 0.0
	if suspect_test != null and suspect_test.has_method("parar_movimento"):
		suspect_test.call("parar_movimento")
	tocar_confirmacao_central()
	print("SUSPEITO SE RENDEU - ABATE CANCELADO")

func liberar_abate() -> void:
	estado_procedimento = EstadoProcedimento.ABATE_LIBERADO
	tocar_alerta_radio()
	print("CENTRAL: SUSPEITO RECUSOU ULTIMA ORDEM - ABATE LIBERADO")

# =========================================================
# REFORCO P-02
# =========================================================

func criar_reforco() -> void:
	# v6.4: P-02 temporariamente removida do jogo.
	if reforco != null and is_instance_valid(reforco):
		reforco.queue_free()
	reforco = null
	reforco_no_local = false
	print("COCKPIT FX v6.4: tentativa de criar P-02 ignorada.")
	return

	if reforco != null or player == null:
		return

	if hangar_base == null:
		hangar_base = get_node_or_null("../HangarBase")

	reforco_do_hangar = false

	# Primeiro tenta usar a P-02 que esta realmente estacionada na base.
	if hangar_base != null and hangar_base.has_method("despachar_p02"):
		var resultado: Variant = hangar_base.call("despachar_p02")
		if resultado is Node3D:
			reforco = resultado as Node3D
			reforco_do_hangar = true

	# Fallback: se por algum motivo o hangar nao estiver disponivel,
	# ainda cria a P-02 antiga para nao quebrar a ocorrencia.
	if reforco == null:
		reforco = criar_nave_policial()
		reforco.name = "UnidadeP02"
		get_tree().current_scene.add_child(reforco)

		var frente_fallback: Vector3 = -player.global_transform.basis.z.normalized()
		var direita_fallback: Vector3 = player.global_transform.basis.x.normalized()

		reforco.global_position = (
			player.global_position
			- frente_fallback * distancia_spawn_atras
			+ direita_fallback * 70.0
			+ Vector3.UP * 35.0
		)
	else:
		configurar_referencias_reforco_hangar()
		reforco_posicao_inicio = reforco.global_position

		if hangar_base.has_method("get_p02_corredor_global"):
			var corredor: Variant = hangar_base.call("get_p02_corredor_global")
			if corredor is Vector3:
				reforco_corredor_hangar = corredor

		if hangar_base.has_method("get_p02_portao_global"):
			var portao: Variant = hangar_base.call("get_p02_portao_global")
			if portao is Vector3:
				reforco_portao_hangar = portao

		if hangar_base.has_method("get_p02_saida_global"):
			var saida: Variant = hangar_base.call("get_p02_saida_global")
			if saida is Vector3:
				reforco_saida_hangar = saida

	reforco_tempo_voo = 0.0
	reforco_no_local = false

	print("P-02: SAINDO DA BASE INTERPLANETARIA")

func atualizar_reforco(delta: float) -> void:
	if reforco == null or !is_instance_valid(reforco):
		reforco = null
		return
	if player == null:
		return

	if estado_procedimento == EstadoProcedimento.REFORCO_A_CAMINHO:
		reforco_tempo_voo += delta

		var t_total: float = maxf(tempo_chegada_reforco, 0.1)
		var t: float = clampf(reforco_tempo_voo, 0.0, t_total)
		var destino: Vector3 = reforco.global_position

		if reforco_do_hangar:
			# 0-2s: sai da vaga e entra no corredor central.
			if t <= 2.0:
				var q1: float = clampf(t / 2.0, 0.0, 1.0)
				var s1: float = q1 * q1 * (3.0 - 2.0 * q1)
				destino = reforco_posicao_inicio.lerp(
					reforco_corredor_hangar,
					s1
				)

			# 2-3.5s: acelera pelo corredor ate o portao.
			elif t <= 3.5:
				var q2: float = clampf((t - 2.0) / 1.5, 0.0, 1.0)
				var s2: float = q2 * q2 * (3.0 - 2.0 * q2)
				destino = reforco_corredor_hangar.lerp(
					reforco_portao_hangar,
					s2
				)

			# 3.5-4.5s: cruza o portao e deixa fisicamente a base.
			elif t <= 4.5:
				var q3: float = clampf((t - 3.5) / 1.0, 0.0, 1.0)
				var s3: float = q3 * q3 * (3.0 - 2.0 * q3)
				destino = reforco_portao_hangar.lerp(
					reforco_saida_hangar,
					s3
				)

			# 4.5-14s: viagem da base ate uma posicao bem atras da P-01.
			elif t <= 14.0:
				var frente_viagem: Vector3 = -player.global_transform.basis.z.normalized()
				var direita_viagem: Vector3 = player.global_transform.basis.x.normalized()

				var ponto_atras: Vector3 = (
					player.global_position
					- frente_viagem * 220.0
					+ direita_viagem * 50.0
					+ Vector3.UP * 25.0
				)

				var q4: float = clampf((t - 4.5) / 9.5, 0.0, 1.0)
				var s4: float = q4 * q4 * (3.0 - 2.0 * q4)
				destino = reforco_saida_hangar.lerp(
					ponto_atras,
					s4
				)

			# 14-20s: aparece atras, passa pela P-01 e toma a dianteira.
			else:
				var frente_ultrapassagem: Vector3 = -player.global_transform.basis.z.normalized()
				var direita_ultrapassagem: Vector3 = player.global_transform.basis.x.normalized()

				var q5: float = clampf(
					(t - 14.0) / maxf(t_total - 14.0, 0.1),
					0.0,
					1.0
				)
				var s5: float = q5 * q5 * (3.0 - 2.0 * q5)

				var distancia_frente: float = lerpf(
					-220.0,
					distancia_final_a_frente,
					s5
				)
				var lateral: float = lerpf(50.0, -32.0, s5)
				var altura: float = lerpf(25.0, 14.0, s5)

				destino = (
					player.global_position
					+ frente_ultrapassagem * distancia_frente
					+ direita_ultrapassagem * lateral
					+ Vector3.UP * altura
				)

		else:
			# Comportamento antigo usado apenas como fallback.
			var p: float = clampf(t / t_total, 0.0, 1.0)
			var curva: float = pow(p, 1.8)
			var frente: Vector3 = -player.global_transform.basis.z.normalized()
			var direita: Vector3 = player.global_transform.basis.x.normalized()

			var distancia_frente_fallback: float = lerpf(
				-distancia_spawn_atras,
				distancia_final_a_frente,
				curva
			)
			var deslocamento_lateral: float = lerpf(70.0, -32.0, curva)
			var altura_fallback: float = lerpf(35.0, 14.0, curva)

			destino = (
				player.global_position
				+ frente * distancia_frente_fallback
				+ direita * deslocamento_lateral
				+ Vector3.UP * altura_fallback
			)

		var posicao_anterior: Vector3 = reforco.global_position
		reforco.global_position = destino

		var movimento: Vector3 = destino - posicao_anterior
		if movimento.length() > 0.01:
			reforco.look_at(
				reforco.global_position + movimento.normalized() * 20.0,
				Vector3.UP
			)

		if reforco_tempo_voo >= t_total:
			reforco_no_local = true
		return

	# Depois da ultrapassagem, a P-02 permanece em formacao na dianteira,
	# proxima do suspeito.
	if nave_suspeita != null and is_instance_valid(nave_suspeita):
		var direcao_alvo: Vector3 = nave_suspeita.global_position - player.global_position
		if direcao_alvo.length() < 0.01:
			direcao_alvo = -player.global_transform.basis.z
		direcao_alvo = direcao_alvo.normalized()

		var lateral_alvo: Vector3 = Vector3.UP.cross(direcao_alvo)
		if lateral_alvo.length() < 0.01:
			lateral_alvo = Vector3.RIGHT
		lateral_alvo = lateral_alvo.normalized()

		var destino_formacao: Vector3 = (
			nave_suspeita.global_position
			- direcao_alvo * 34.0
			+ lateral_alvo * 32.0
			+ Vector3.UP * 10.0
		)

		mover_reforco_para(destino_formacao, delta, 68.0)
	else:
		var frente_player: Vector3 = -player.global_transform.basis.z.normalized()
		var destino_player: Vector3 = player.global_position + frente_player * 120.0
		mover_reforco_para(destino_player, delta, 60.0)

func mover_reforco_para(destino: Vector3, delta: float, velocidade: float) -> void:
	if reforco == null:
		return

	var vetor: Vector3 = destino - reforco.global_position
	if vetor.length() <= 1.0:
		return

	var direcao: Vector3 = vetor.normalized()
	var passo: float = minf(velocidade * delta, vetor.length())
	reforco.global_position += direcao * passo
	reforco.look_at(
		reforco.global_position + direcao * 20.0,
		Vector3.UP
	)

func configurar_referencias_reforco_hangar() -> void:
	if reforco == null:
		return

	reforco_mesh_vermelho = (
		encontrar_node_recursivo(reforco, "GiroflexVermelho")
		as MeshInstance3D
	)

	reforco_mesh_azul = (
		encontrar_node_recursivo(reforco, "GiroflexAzul")
		as MeshInstance3D
	)

	reforco_luz_vermelha = (
		encontrar_node_recursivo(reforco, "LuzGiroflexVermelha")
		as OmniLight3D
	)

	reforco_luz_azul = (
		encontrar_node_recursivo(reforco, "LuzGiroflexAzul")
		as OmniLight3D
	)


func criar_nave_policial() -> Node3D:
	var nave: Node3D = Node3D.new()

	var metal: StandardMaterial3D = StandardMaterial3D.new()
	metal.albedo_color = Color(0.08, 0.11, 0.16, 1.0)
	metal.metallic = 0.85
	metal.roughness = 0.28

	var detalhe: StandardMaterial3D = StandardMaterial3D.new()
	detalhe.albedo_color = Color(0.72, 0.78, 0.84, 1.0)
	detalhe.metallic = 0.70
	detalhe.roughness = 0.30

	var vidro: StandardMaterial3D = StandardMaterial3D.new()
	vidro.albedo_color = Color(0.02, 0.30, 0.55, 0.65)
	vidro.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	vidro.emission_enabled = true
	vidro.emission = Color(0.02, 0.28, 0.65)
	vidro.emission_energy_multiplier = 2.0

	var corpo: MeshInstance3D = MeshInstance3D.new()
	var corpo_mesh: BoxMesh = BoxMesh.new()
	corpo_mesh.size = Vector3(7.0, 2.0, 14.0)
	corpo.mesh = corpo_mesh
	corpo.material_override = metal
	nave.add_child(corpo)

	var nariz: MeshInstance3D = MeshInstance3D.new()
	var nariz_mesh: CylinderMesh = CylinderMesh.new()
	nariz_mesh.top_radius = 0.2
	nariz_mesh.bottom_radius = 3.0
	nariz_mesh.height = 5.5
	nariz_mesh.radial_segments = 8
	nariz.mesh = nariz_mesh
	nariz.material_override = metal
	nariz.position = Vector3(0.0, 0.0, -9.0)
	nariz.rotation.x = deg_to_rad(90.0)
	nave.add_child(nariz)

	var cockpit: MeshInstance3D = MeshInstance3D.new()
	var cockpit_mesh: SphereMesh = SphereMesh.new()
	cockpit_mesh.radius = 2.0
	cockpit_mesh.height = 2.8
	cockpit_mesh.radial_segments = 18
	cockpit_mesh.rings = 10
	cockpit.mesh = cockpit_mesh
	cockpit.material_override = vidro
	cockpit.position = Vector3(0.0, 1.7, -4.0)
	cockpit.scale = Vector3(1.0, 0.65, 1.4)
	nave.add_child(cockpit)

	for lado: float in [-1.0, 1.0]:
		var asa: MeshInstance3D = MeshInstance3D.new()
		var asa_mesh: BoxMesh = BoxMesh.new()
		asa_mesh.size = Vector3(7.0, 0.45, 6.0)
		asa.mesh = asa_mesh
		asa.material_override = metal
		asa.position = Vector3(4.5 * lado, -0.2, 1.0)
		nave.add_child(asa)

		var faixa: MeshInstance3D = MeshInstance3D.new()
		var faixa_mesh: BoxMesh = BoxMesh.new()
		faixa_mesh.size = Vector3(2.3, 0.12, 4.5)
		faixa.mesh = faixa_mesh
		faixa.material_override = detalhe
		faixa.position = Vector3(5.2 * lado, 0.1, 0.8)
		nave.add_child(faixa)

	var motor_mat: StandardMaterial3D = StandardMaterial3D.new()
	motor_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	motor_mat.emission_enabled = true
	motor_mat.emission = Color(0.03, 0.55, 1.0)
	motor_mat.emission_energy_multiplier = 7.0

	for x: float in [-2.3, 2.3]:
		var motor: MeshInstance3D = MeshInstance3D.new()
		var mesh_motor: SphereMesh = SphereMesh.new()
		mesh_motor.radius = 0.65
		mesh_motor.height = 1.2
		motor.mesh = mesh_motor
		motor.material_override = motor_mat
		motor.position = Vector3(x, 0.0, 7.5)
		nave.add_child(motor)

	reforco_mesh_vermelho = MeshInstance3D.new()
	var red_mesh: SphereMesh = SphereMesh.new()
	red_mesh.radius = 0.35
	red_mesh.height = 0.7
	reforco_mesh_vermelho.mesh = red_mesh
	var red_mat: StandardMaterial3D = StandardMaterial3D.new()
	red_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	red_mat.albedo_color = Color(1.0, 0.02, 0.02)
	red_mat.emission_enabled = true
	red_mat.emission = Color(1.0, 0.0, 0.0)
	red_mat.emission_energy_multiplier = 10.0
	reforco_mesh_vermelho.material_override = red_mat
	reforco_mesh_vermelho.position = Vector3(-0.7, 2.4, 0.0)
	nave.add_child(reforco_mesh_vermelho)

	reforco_mesh_azul = MeshInstance3D.new()
	var blue_mesh: SphereMesh = SphereMesh.new()
	blue_mesh.radius = 0.35
	blue_mesh.height = 0.7
	reforco_mesh_azul.mesh = blue_mesh
	var blue_mat: StandardMaterial3D = StandardMaterial3D.new()
	blue_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	blue_mat.albedo_color = Color(0.02, 0.20, 1.0)
	blue_mat.emission_enabled = true
	blue_mat.emission = Color(0.02, 0.18, 1.0)
	blue_mat.emission_energy_multiplier = 10.0
	reforco_mesh_azul.material_override = blue_mat
	reforco_mesh_azul.position = Vector3(0.7, 2.4, 0.0)
	nave.add_child(reforco_mesh_azul)

	reforco_luz_vermelha = OmniLight3D.new()
	reforco_luz_vermelha.light_color = Color(1.0, 0.02, 0.02)
	reforco_luz_vermelha.light_energy = 0.0
	reforco_luz_vermelha.omni_range = 18.0
	reforco_luz_vermelha.position = Vector3(-0.7, 2.5, 0.0)
	nave.add_child(reforco_luz_vermelha)

	reforco_luz_azul = OmniLight3D.new()
	reforco_luz_azul.light_color = Color(0.02, 0.20, 1.0)
	reforco_luz_azul.light_energy = 0.0
	reforco_luz_azul.omni_range = 18.0
	reforco_luz_azul.position = Vector3(0.7, 2.5, 0.0)
	nave.add_child(reforco_luz_azul)

	nave.scale = Vector3.ONE * 1.7
	return nave

func remover_reforco() -> void:
	if reforco != null and is_instance_valid(reforco):
		if reforco_do_hangar and hangar_base != null and hangar_base.has_method("recolher_p02"):
			hangar_base.call("recolher_p02")
		elif !reforco_do_hangar:
			reforco.queue_free()

	reforco = null
	reforco_luz_vermelha = null
	reforco_luz_azul = null
	reforco_mesh_vermelho = null
	reforco_mesh_azul = null
	reforco_no_local = false
	reforco_tempo_voo = 0.0
	reforco_do_hangar = false
	reforco_posicao_inicio = Vector3.ZERO
	reforco_corredor_hangar = Vector3.ZERO
	reforco_portao_hangar = Vector3.ZERO
	reforco_saida_hangar = Vector3.ZERO

# =========================================================
# ARMA
# =========================================================

func processar_arma() -> void:
	if cooldown_tiro > 0.0 or player == null:
		return
	if Input.is_key_pressed(KEY_SPACE):
		disparar()

func disparar() -> void:
	if player == null:
		return

	cooldown_tiro = intervalo_disparo
	var direcao: Vector3 = obter_direcao_tiro()
	var origem: Vector3 = obter_origem_tiro(direcao)

	tocar_som_tiro()
	criar_flash_tiro(origem, direcao)

	var tiro: MeshInstance3D = MeshInstance3D.new()
	var mesh: SphereMesh = SphereMesh.new()
	mesh.radius = 0.35
	mesh.height = 0.70
	mesh.radial_segments = 12
	mesh.rings = 6
	tiro.mesh = mesh
	tiro.scale = Vector3(0.50, 0.50, 4.5)

	var material: StandardMaterial3D = StandardMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.albedo_color = Color(0.15, 0.85, 1.0)
	material.emission_enabled = true
	material.emission = Color(0.02, 0.65, 1.0)
	material.emission_energy_multiplier = 9.0
	tiro.material_override = material

	get_tree().current_scene.add_child(tiro)
	tiro.global_position = origem
	tiro.look_at(origem + direcao, Vector3.UP)

	projeteis.append({
		"node": tiro,
		"direcao": direcao,
		"vida": 4.0
	})

func obter_direcao_tiro() -> Vector3:
	if player == null:
		return Vector3.FORWARD

	var camera_tiro: Camera3D = player.get_node_or_null("Camera3D") as Camera3D
	if camera_tiro == null:
		var cena: Node = get_tree().current_scene
		if cena != null:
			var encontrada: Node = cena.find_child("Camera3D", true, false)
			if encontrada is Camera3D:
				camera_tiro = encontrada as Camera3D

	if camera_tiro != null:
		return -camera_tiro.global_transform.basis.z.normalized()
	return -player.global_transform.basis.z.normalized()

func obter_origem_tiro(direcao: Vector3) -> Vector3:
	if player == null:
		return Vector3.ZERO
	var camera_tiro: Camera3D = player.get_node_or_null("Camera3D") as Camera3D
	if camera_tiro != null:
		return camera_tiro.global_position + direcao * 3.0
	return player.global_position + direcao * 4.0

func criar_flash_tiro(posicao: Vector3, direcao: Vector3) -> void:
	var flash: Node3D = Node3D.new()
	get_tree().current_scene.add_child(flash)
	flash.global_position = posicao

	for i: int in range(3):
		var esfera: MeshInstance3D = MeshInstance3D.new()
		var mesh: SphereMesh = SphereMesh.new()
		mesh.radius = 0.45 + i * 0.20
		mesh.height = mesh.radius * 2.0
		esfera.mesh = mesh
		esfera.position = direcao * float(i) * 0.7
		esfera.scale = Vector3(1.0, 1.0, 1.8)

		var material: StandardMaterial3D = StandardMaterial3D.new()
		material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		material.emission_enabled = true
		if i == 0:
			material.albedo_color = Color(1.0, 0.95, 0.50)
			material.emission = Color(1.0, 0.85, 0.25)
		else:
			material.albedo_color = Color(1.0, 0.25, 0.02)
			material.emission = Color(1.0, 0.10, 0.01)
		material.emission_energy_multiplier = 12.0
		esfera.material_override = material
		flash.add_child(esfera)

	var luz: OmniLight3D = OmniLight3D.new()
	luz.light_color = Color(1.0, 0.30, 0.05)
	luz.light_energy = 12.0
	luz.omni_range = 20.0
	flash.add_child(luz)

	efeitos.append({"node": flash, "vida": 0.09, "crescimento": 5.0})

func atualizar_projeteis(delta: float) -> void:
	for i: int in range(projeteis.size() - 1, -1, -1):
		var dados: Dictionary = projeteis[i]
		var tiro: MeshInstance3D = dados["node"] as MeshInstance3D

		if tiro == null or !is_instance_valid(tiro):
			projeteis.remove_at(i)
			continue

		dados["vida"] = float(dados["vida"]) - delta
		if float(dados["vida"]) <= 0.0:
			tiro.queue_free()
			projeteis.remove_at(i)
			continue

		var direcao: Vector3 = dados["direcao"]
		var origem_segmento: Vector3 = tiro.global_position
		var destino_segmento: Vector3 = origem_segmento + direcao * velocidade_tiro * delta

		var impacto_fisico: Dictionary = detectar_impacto_fisico(origem_segmento, destino_segmento)
		if !impacto_fisico.is_empty():
			var ponto: Vector3 = impacto_fisico.get("position", destino_segmento)
			var collider: Object = impacto_fisico.get("collider", null)
			criar_impacto(ponto)
			processar_objeto_atingido(collider, direcao, ponto)
			tiro.queue_free()
			projeteis.remove_at(i)
			continue

		# Compatibilidade com a nave suspeita antiga, que pode nao ter collider.
		if nave_suspeita != null and is_instance_valid(nave_suspeita):
			if distancia_ponto_segmento(nave_suspeita.global_position, origem_segmento, destino_segmento) <= 9.0:
				criar_impacto(nave_suspeita.global_position)
				if estado_procedimento == EstadoProcedimento.ABATE_LIBERADO:
					aplicar_dano_alvo(dano_tiro)
				tiro.queue_free()
				projeteis.remove_at(i)
				continue

		tiro.global_position = destino_segmento
		tiro.look_at(tiro.global_position + direcao, Vector3.UP)

func detectar_impacto_fisico(origem: Vector3, destino: Vector3) -> Dictionary:
	if player == null or !is_instance_valid(player):
		return {}
	var mundo: World3D = player.get_world_3d()
	if mundo == null:
		return {}

	var exclude: Array[RID] = []
	if player is CollisionObject3D:
		exclude.append((player as CollisionObject3D).get_rid())

	var query := PhysicsRayQueryParameters3D.create(origem, destino, 1, exclude)
	query.collide_with_bodies = true
	query.collide_with_areas = false
	return mundo.direct_space_state.intersect_ray(query)

func processar_objeto_atingido(collider: Object, direcao: Vector3, ponto: Vector3) -> void:
	if collider == null:
		return

	if collider is Node:
		var no: Node = collider as Node

		if no.is_in_group("space_debris"):
			if no is RigidBody3D:
				(no as RigidBody3D).apply_central_impulse(direcao * 18.0)
			criar_explosao_destroco(ponto)
			no.queue_free()
			return

		if no.is_in_group("suspect_target"):
			if estado_procedimento == EstadoProcedimento.ABATE_LIBERADO:
				aplicar_dano_alvo(dano_tiro)
			return

		if no is RigidBody3D:
			(no as RigidBody3D).apply_central_impulse(direcao * 10.0)

func criar_explosao_destroco(posicao: Vector3) -> void:
	criar_impacto(posicao)

func distancia_ponto_segmento(ponto: Vector3, a: Vector3, b: Vector3) -> float:
	var ab: Vector3 = b - a
	var len2: float = ab.length_squared()
	if len2 <= 0.000001:
		return ponto.distance_to(a)
	var t: float = clampf((ponto - a).dot(ab) / len2, 0.0, 1.0)
	var mais_proximo: Vector3 = a + ab * t
	return ponto.distance_to(mais_proximo)

func criar_impacto(posicao: Vector3) -> void:
	var impacto: Node3D = Node3D.new()
	get_tree().current_scene.add_child(impacto)
	impacto.global_position = posicao

	var esfera: MeshInstance3D = MeshInstance3D.new()
	var mesh: SphereMesh = SphereMesh.new()
	mesh.radius = 1.0
	mesh.height = 2.0
	esfera.mesh = mesh

	var material: StandardMaterial3D = StandardMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.emission_enabled = true
	material.albedo_color = Color(1.0, 0.42, 0.04)
	material.emission = Color(1.0, 0.15, 0.01)
	material.emission_energy_multiplier = 12.0
	esfera.material_override = material
	impacto.add_child(esfera)

	efeitos.append({"node": impacto, "vida": 0.18, "crescimento": 10.0})

func aplicar_dano_alvo(dano: float) -> void:
	if estado_procedimento != EstadoProcedimento.ABATE_LIBERADO:
		return
	vida_alvo = maxf(vida_alvo - dano, 0.0)
	if vida_alvo <= 0.0:
		abater_alvo()

func abater_alvo() -> void:
	if estado_procedimento == EstadoProcedimento.ALVO_ABATIDO:
		return

	estado_procedimento = EstadoProcedimento.ALVO_ABATIDO
	tempo_pos_encerramento = 0.0
	fuga_ativa = false

	var posicao: Vector3 = Vector3.ZERO
	if nave_suspeita != null and is_instance_valid(nave_suspeita):
		posicao = nave_suspeita.global_position

	criar_explosao_grande(posicao)
	if explosion_player != null:
		explosion_player.stream = som_explosao
		explosion_player.play()

	if nave_suspeita != null and is_instance_valid(nave_suspeita):
		nave_suspeita.queue_free()
	nave_suspeita = null

	ativar_giroflex(false)

	if suspect_test != null and suspect_test.has_method("encerrar_ocorrencia"):
		suspect_test.call("encerrar_ocorrencia")

func criar_explosao_grande(posicao: Vector3) -> void:
	var explosao: Node3D = Node3D.new()
	get_tree().current_scene.add_child(explosao)
	explosao.global_position = posicao

	var cores: Array[Color] = [
		Color(1.0, 0.95, 0.55),
		Color(1.0, 0.38, 0.03),
		Color(1.0, 0.08, 0.01)
	]

	for i: int in range(3):
		var esfera: MeshInstance3D = MeshInstance3D.new()
		var mesh: SphereMesh = SphereMesh.new()
		mesh.radius = 2.0 + i * 1.6
		mesh.height = mesh.radius * 2.0
		mesh.radial_segments = 20
		mesh.rings = 12
		esfera.mesh = mesh

		var material: StandardMaterial3D = StandardMaterial3D.new()
		material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		material.albedo_color = cores[i]
		material.emission_enabled = true
		material.emission = cores[i]
		material.emission_energy_multiplier = 14.0 - i * 2.0
		esfera.material_override = material
		explosao.add_child(esfera)

	var luz: OmniLight3D = OmniLight3D.new()
	luz.light_color = Color(1.0, 0.24, 0.03)
	luz.light_energy = 35.0
	luz.omni_range = 90.0
	explosao.add_child(luz)

	efeitos.append({"node": explosao, "vida": 1.05, "crescimento": 7.0})

	for i: int in range(16):
		var pedaco: MeshInstance3D = MeshInstance3D.new()
		var mesh_fragmento: BoxMesh = BoxMesh.new()
		mesh_fragmento.size = Vector3(
			rng.randf_range(0.6, 2.2),
			rng.randf_range(0.4, 1.4),
			rng.randf_range(0.8, 3.0)
		)
		pedaco.mesh = mesh_fragmento

		var material_fragmento: StandardMaterial3D = StandardMaterial3D.new()
		material_fragmento.albedo_color = Color(0.12, 0.10, 0.08)
		material_fragmento.metallic = 0.8
		material_fragmento.roughness = 0.45
		material_fragmento.emission_enabled = true
		material_fragmento.emission = Color(0.35, 0.04, 0.01)
		material_fragmento.emission_energy_multiplier = 1.5
		pedaco.material_override = material_fragmento

		get_tree().current_scene.add_child(pedaco)
		pedaco.global_position = posicao

		fragmentos.append({
			"node": pedaco,
			"velocidade": Vector3(
				rng.randf_range(-28.0, 28.0),
				rng.randf_range(-22.0, 28.0),
				rng.randf_range(-28.0, 28.0)
			),
			"vida": rng.randf_range(1.5, 3.0)
		})

func atualizar_efeitos(delta: float) -> void:
	for i: int in range(efeitos.size() - 1, -1, -1):
		var dados: Dictionary = efeitos[i]
		var node: Node3D = dados["node"] as Node3D
		if node == null or !is_instance_valid(node):
			efeitos.remove_at(i)
			continue

		dados["vida"] = float(dados["vida"]) - delta
		node.scale += Vector3.ONE * float(dados["crescimento"]) * delta
		if float(dados["vida"]) <= 0.0:
			node.queue_free()
			efeitos.remove_at(i)

func atualizar_fragmentos(delta: float) -> void:
	for i: int in range(fragmentos.size() - 1, -1, -1):
		var dados: Dictionary = fragmentos[i]
		var node: MeshInstance3D = dados["node"] as MeshInstance3D
		if node == null or !is_instance_valid(node):
			fragmentos.remove_at(i)
			continue

		dados["vida"] = float(dados["vida"]) - delta
		var velocidade: Vector3 = dados["velocidade"]
		node.global_position += velocidade * delta
		node.rotation.x += delta * 3.2
		node.rotation.y += delta * 4.1

		if float(dados["vida"]) <= 0.0:
			node.queue_free()
			fragmentos.remove_at(i)

# =========================================================
# ENCERRAMENTO
# =========================================================

func encerrar_ocorrencia_rendida() -> void:
	if nave_suspeita != null and is_instance_valid(nave_suspeita):
		nave_suspeita.queue_free()
	nave_suspeita = null
	ativar_giroflex(false)

	if suspect_test != null and suspect_test.has_method("encerrar_ocorrencia"):
		suspect_test.call("encerrar_ocorrencia")

	preparar_proxima_ocorrencia()

func preparar_proxima_ocorrencia() -> void:
	tempo_pos_encerramento = 0.0
	estado_ordem = EstadoOrdem.NAO_DISPONIVEL
	estado_procedimento = EstadoProcedimento.BLOQUEADO
	fuga_ativa = false
	nave_suspeita = null
	resetar_scanner()
	remover_reforco()

# =========================================================
# LUZES P-01 / P-02
# =========================================================

func criar_luzes_policiais() -> void:
	if player == null or luz_vermelha != null:
		return

	luz_vermelha = OmniLight3D.new()
	luz_vermelha.light_color = Color(1.0, 0.02, 0.02)
	luz_vermelha.light_energy = 0.0
	luz_vermelha.omni_range = 18.0
	luz_vermelha.shadow_enabled = false
	luz_vermelha.position = Vector3(-2.5, 1.5, 0.5)
	player.add_child(luz_vermelha)

	luz_azul = OmniLight3D.new()
	luz_azul.light_color = Color(0.02, 0.25, 1.0)
	luz_azul.light_energy = 0.0
	luz_azul.omni_range = 18.0
	luz_azul.shadow_enabled = false
	luz_azul.position = Vector3(2.5, 1.5, 0.5)
	player.add_child(luz_azul)

func ativar_giroflex(ativo: bool) -> void:
	giroflex_ativo = ativo
	tempo_giroflex = 0.0
	fase_giroflex = false

	if !ativo:
		if luz_vermelha != null:
			luz_vermelha.light_energy = 0.0
		if luz_azul != null:
			luz_azul.light_energy = 0.0
		if reforco_luz_vermelha != null:
			reforco_luz_vermelha.light_energy = 0.0
		if reforco_luz_azul != null:
			reforco_luz_azul.light_energy = 0.0

func atualizar_luzes_policiais(delta: float) -> void:
	if !giroflex_ativo:
		return

	tempo_giroflex += delta
	if tempo_giroflex >= 0.15:
		tempo_giroflex = 0.0
		fase_giroflex = !fase_giroflex

	var energia_red: float = 9.0 if fase_giroflex else 0.4
	var energia_blue: float = 0.4 if fase_giroflex else 9.0

	if luz_vermelha != null:
		luz_vermelha.light_energy = energia_red
	if luz_azul != null:
		luz_azul.light_energy = energia_blue
	if reforco_luz_vermelha != null:
		reforco_luz_vermelha.light_energy = energia_red
	if reforco_luz_azul != null:
		reforco_luz_azul.light_energy = energia_blue
	if reforco_mesh_vermelho != null:
		reforco_mesh_vermelho.visible = fase_giroflex
	if reforco_mesh_azul != null:
		reforco_mesh_azul.visible = !fase_giroflex

# =========================================================
# PAINEL
# =========================================================

func atualizar_painel() -> void:
	if player == null or nave_suspeita == null:
		return

	var distancia: float = player.global_position.distance_to(nave_suspeita.global_position)
	label_setor.text = "SETOR: " + setor_missao
	label_distancia.text = "DISTANCIA: " + formatar_distancia(
		distancia / maxf(unidades_por_km, 0.001)
	)

	var scan: int = pegar_estado_scanner()

	if estado_procedimento == EstadoProcedimento.ABATE_LIBERADO:
		label_status.text = "STATUS: ARMAMENTO AUTORIZADO"
		label_ocorrencia.text = "⚠ ABATE LIBERADO"
		label_prioridade.text = "PRIORIDADE: CRITICA"
		var integridade: int = int(vida_alvo / vida_alvo_maxima * 100.0)
		if distancia <= alcance_arma:
			label_objetivo.text = "ESPACO = DISPARAR | ALVO " + str(integridade) + "%"
		else:
			label_objetivo.text = "APROXIME-SE | ALVO " + str(integridade) + "%"
		barra_status.color = Color(1.0, 0.03, 0.02)
		return

	if estado_procedimento == EstadoProcedimento.AGUARDANDO_RENDICAO:
		var restante: int = int(ceil(maxf(tempo_para_rendicao - tempo_procedimento, 0.0)))
		label_status.text = "STATUS: ULTIMA ADVERTENCIA"
		label_ocorrencia.text = "⚠ AGUARDANDO RENDICAO"
		label_prioridade.text = "PRIORIDADE: CRITICA"
		label_objetivo.text = "SUSPEITO TEM " + str(restante) + "s PARA OBEDECER"
		barra_status.color = Color(1.0, 0.30, 0.02)
		return

	if estado_procedimento == EstadoProcedimento.ULTIMA_ORDEM:
		label_status.text = "STATUS: ULTIMA ORDEM"
		label_ocorrencia.text = "⚠ CENTRAL AUTORIZOU ADVERTENCIA"
		label_prioridade.text = "PRIORIDADE: CRITICA"
		label_objetivo.text = "NAVE CX-7714: RENDA-SE IMEDIATAMENTE"
		barra_status.color = Color(1.0, 0.38, 0.03)
		return

	if estado_procedimento == EstadoProcedimento.REFORCO_NO_LOCAL:
		label_status.text = "STATUS: REFORCO NO LOCAL"
		label_ocorrencia.text = "◆ P-02 ASSUMIU A DIANTEIRA"
		label_prioridade.text = "PRIORIDADE: ALTA"
		label_objetivo.text = "CENTRAL PREPARANDO ULTIMA ORDEM"
		barra_status.color = Color(0.05, 0.65, 1.0)
		return

	if estado_procedimento == EstadoProcedimento.REFORCO_A_CAMINHO:
		var eta: int = int(ceil(maxf(tempo_chegada_reforco - reforco_tempo_voo, 0.0)))
		label_status.text = "STATUS: PERSEGUICAO"
		label_ocorrencia.text = "◆ UNIDADE P-02 A CAMINHO"
		label_prioridade.text = "PRIORIDADE: ALTA"
		label_objetivo.text = "REFORCO ETA: " + str(eta) + "s | MANTENHA O ALVO"
		barra_status.color = Color(0.05, 0.55, 1.0)
		return

	if estado_procedimento == EstadoProcedimento.ACIONANDO_REFORCO:
		label_status.text = "STATUS: PERSEGUICAO"
		label_ocorrencia.text = "⚠ ALVO EM FUGA"
		label_prioridade.text = "PRIORIDADE: ALTA"
		label_objetivo.text = "CENTRAL: ACIONANDO REFORCO"
		barra_status.color = Color(1.0, 0.45, 0.03)
		return

	if estado_ordem == EstadoOrdem.ORDEM_TRANSMITIDA:
		label_status.text = "STATUS: ORDEM TRANSMITIDA"
		label_ocorrencia.text = "◆ AGUARDANDO RESPOSTA"
		label_prioridade.text = "PRIORIDADE: ALTA"
		label_objetivo.text = "PARE E MANTENHA POSICAO"
		return

	if estado_ordem == EstadoOrdem.AGUARDANDO_ORDEM:
		label_status.text = "STATUS: IRREGULARIDADE"
		label_ocorrencia.text = "⚠ REGISTRO INVALIDO"
		label_prioridade.text = "PRIORIDADE: ALTA"
		label_objetivo.text = "PRESSIONE F PARA ORDEM DE PARADA"
		return

	if scan == 1:
		label_status.text = "STATUS: ANALISANDO ALVO"
		label_ocorrencia.text = "◆ SCANNER EM OPERACAO"
		label_prioridade.text = "PRIORIDADE: VERIFICACAO"
		label_objetivo.text = "MANTENHA-SE PROXIMO"
		return

	label_status.text = "STATUS: OCORRENCIA ATIVA"
	label_ocorrencia.text = "⚠ " + titulo_missao
	label_prioridade.text = "PRIORIDADE: " + prioridade_missao
	if distancia <= distancia_abordagem:
		label_objetivo.text = "OBJETIVO: ESCANEAR ALVO [E]"
	else:
		label_objetivo.text = "OBJETIVO: " + objetivo_missao

func mostrar_alvo_rendido() -> void:
	label_status.text = "STATUS: SUSPEITO DETIDO"
	label_ocorrencia.text = "✓ ALVO SE RENDEU"
	label_prioridade.text = "PRIORIDADE: CONTROLADA"
	label_objetivo.text = "P-02 REALIZANDO CUSTODIA"
	barra_status.color = Color(0.12, 0.90, 0.50)

func mostrar_alvo_abatido() -> void:
	label_status.text = "STATUS: OCORRENCIA ENCERRADA"
	label_ocorrencia.text = "✓ ALVO NEUTRALIZADO"
	label_distancia.text = "DISTANCIA: ---"
	label_prioridade.text = "PRIORIDADE: ENCERRADA"
	label_objetivo.text = "CENTRAL: RETORNE AO PATRULHAMENTO"
	barra_status.color = Color(0.15, 0.90, 0.48)

func mostrar_patrulhamento() -> void:
	if painel == null:
		return
	label_status.text = "STATUS: EM PATRULHA"
	label_ocorrencia.text = "AGUARDANDO NOVA OCORRENCIA"
	label_setor.text = "SETOR: SISTEMA SOLAR"
	label_distancia.text = "DISTANCIA: ---"
	label_prioridade.text = "PRIORIDADE: ---"
	label_objetivo.text = "OBJETIVO: PATRULHAMENTO"
	barra_status.color = Color(0.10, 0.55, 0.90)

# =========================================================
# AUDIO
# =========================================================

func criar_sistemas_audio() -> void:
	radio_player = AudioStreamPlayer.new()
	radio_player.name = "PoliceRadio"
	radio_player.volume_db = -3.0
	add_child(radio_player)

	explosion_player = AudioStreamPlayer.new()
	explosion_player.name = "ExplosionAudio"
	explosion_player.volume_db = 0.0
	add_child(explosion_player)

	som_tiro = criar_som_tiro()
	som_explosao = criar_som_explosao()

	for i: int in range(4):
		var canal: AudioStreamPlayer = AudioStreamPlayer.new()
		canal.name = "WeaponAudio" + str(i)
		canal.volume_db = -1.0
		canal.stream = som_tiro
		add_child(canal)
		arma_players.append(canal)

func tocar_alerta_radio() -> void:
	if radio_player == null:
		return
	radio_player.stream = criar_beep_radio(780.0, 1050.0, 880.0)
	radio_player.play()

func tocar_confirmacao_central() -> void:
	if radio_player == null:
		return
	radio_player.stream = criar_beep_radio(620.0, 880.0, 1180.0)
	radio_player.play()

func criar_som_tiro() -> AudioStreamWAV:
	var rate: int = 44100
	var duracao: float = 0.24
	var total: int = int(rate * duracao)
	var data: PackedByteArray = PackedByteArray()
	data.resize(total * 2)

	var random: RandomNumberGenerator = RandomNumberGenerator.new()
	random.randomize()

	for i: int in range(total):
		var t: float = float(i) / float(rate)
		var envelope: float = exp(-t * 17.0)
		var estampido: float = random.randf_range(-1.0, 1.0) * envelope * 0.78
		var grave: float = sin(TAU * 92.0 * t) * exp(-t * 12.0) * 0.60
		var energia: float = sin(TAU * 760.0 * t) * exp(-t * 25.0) * 0.25
		gravar_sample(data, i, (estampido + grave + energia) * 0.55)

	var wav: AudioStreamWAV = AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_16_BITS
	wav.mix_rate = rate
	wav.stereo = false
	wav.data = data
	return wav

func criar_som_explosao() -> AudioStreamWAV:
	var rate: int = 44100
	var duracao: float = 1.15
	var total: int = int(rate * duracao)
	var data: PackedByteArray = PackedByteArray()
	data.resize(total * 2)

	var random: RandomNumberGenerator = RandomNumberGenerator.new()
	random.randomize()

	for i: int in range(total):
		var t: float = float(i) / float(rate)
		var ruido: float = random.randf_range(-1.0, 1.0) * exp(-t * 3.8) * 0.72
		var grave: float = sin(TAU * 48.0 * t) * exp(-t * 4.5) * 0.75
		var subgrave: float = sin(TAU * 27.0 * t) * exp(-t * 3.0) * 0.40
		gravar_sample(data, i, (ruido + grave + subgrave) * 0.55)

	var wav: AudioStreamWAV = AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_16_BITS
	wav.mix_rate = rate
	wav.stereo = false
	wav.data = data
	return wav

func criar_beep_radio(f1: float, f2: float, f3: float) -> AudioStreamWAV:
	var rate: int = 22050
	var duracao: float = 1.0
	var total: int = int(rate * duracao)
	var data: PackedByteArray = PackedByteArray()
	data.resize(total * 2)

	for i: int in range(total):
		var t: float = float(i) / float(rate)
		var sample: float = 0.0
		if t < 0.22:
			sample = sin(TAU * f1 * t) * 0.42
		elif t >= 0.32 and t < 0.52:
			sample = sin(TAU * f2 * t) * 0.46
		elif t >= 0.62 and t < 0.86:
			sample = sin(TAU * f3 * t) * 0.48
		gravar_sample(data, i, sample)

	var wav: AudioStreamWAV = AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_16_BITS
	wav.mix_rate = rate
	wav.stereo = false
	wav.data = data
	return wav

func gravar_sample(data: PackedByteArray, indice: int, sample: float) -> void:
	var valor: int = int(clampf(sample, -1.0, 1.0) * 32767.0)
	if valor < 0:
		valor += 65536
	data[indice * 2] = valor & 0xFF
	data[indice * 2 + 1] = (valor >> 8) & 0xFF

func tocar_som_tiro() -> void:
	if arma_players.is_empty():
		return
	var canal: AudioStreamPlayer = arma_players[indice_audio_arma] as AudioStreamPlayer
	indice_audio_arma += 1
	if indice_audio_arma >= arma_players.size():
		indice_audio_arma = 0
	canal.stop()
	canal.play()

# =========================================================
# CRIAR PAINEL
# =========================================================

func criar_painel_policial() -> void:
	painel = Panel.new()
	painel.position = Vector2(20.0, 20.0)
	painel.size = Vector2(380.0, 188.0)
	painel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	painel.z_index = 50
	add_child(painel)

	var estilo: StyleBoxFlat = StyleBoxFlat.new()
	estilo.bg_color = Color(0.01, 0.025, 0.045, 0.82)
	estilo.border_color = Color(0.18, 0.60, 0.84, 0.82)
	estilo.border_width_left = 1
	estilo.border_width_right = 1
	estilo.border_width_top = 1
	estilo.border_width_bottom = 1
	estilo.corner_radius_top_left = 7
	estilo.corner_radius_top_right = 7
	estilo.corner_radius_bottom_left = 7
	estilo.corner_radius_bottom_right = 7
	painel.add_theme_stylebox_override("panel", estilo)

	barra_status = ColorRect.new()
	barra_status.size = Vector2(380.0, 4.0)
	barra_status.color = Color(0.10, 0.55, 0.90)
	barra_status.mouse_filter = Control.MOUSE_FILTER_IGNORE
	painel.add_child(barra_status)

	label_agencia = criar_label("POLICIA INTERPLANETARIA | UNIDADE P-01", Vector2(12, 10), 14, Color(0.42, 0.85, 1.0))
	label_status = criar_label("STATUS: EM PATRULHA", Vector2(12, 35), 11, Color(0.38, 0.96, 0.62))
	label_ocorrencia = criar_label("AGUARDANDO OCORRENCIA", Vector2(12, 61), 13, Color(1.0, 0.66, 0.25))
	label_setor = criar_label("SETOR: SISTEMA SOLAR", Vector2(12, 87), 11, Color(0.68, 0.80, 0.90))
	label_distancia = criar_label("DISTANCIA: ---", Vector2(12, 108), 11, Color(0.42, 0.87, 1.0))
	label_prioridade = criar_label("PRIORIDADE: ---", Vector2(12, 129), 11, Color(1.0, 0.54, 0.25))
	label_objetivo = criar_label("OBJETIVO: PATRULHAMENTO", Vector2(12, 153), 10, Color(0.88, 0.93, 0.96))

func criar_label(texto: String, posicao: Vector2, tamanho: int, cor: Color) -> Label:
	var label: Label = Label.new()
	label.text = texto
	label.position = posicao
	label.size = Vector2(358.0, 25.0)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.add_theme_font_size_override("font_size", tamanho)
	label.add_theme_color_override("font_color", cor)
	label.add_theme_color_override("font_outline_color", Color.BLACK)
	label.add_theme_constant_override("outline_size", 3)
	painel.add_child(label)
	return label

func formatar_distancia(distancia: float) -> String:
	if distancia < 1000.0:
		return "%.0f km" % distancia
	return "%.2f mil km" % (distancia / 1000.0)

func encontrar_node_recursivo(no_atual: Node, nome_procurado: String) -> Node:
	if String(no_atual.name) == nome_procurado:
		return no_atual
	for filho: Node in no_atual.get_children():
		var resultado: Node = encontrar_node_recursivo(filho, nome_procurado)
		if resultado != null:
			return resultado
	return null
