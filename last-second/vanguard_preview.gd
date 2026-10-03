@tool
extends Node


@export var animar_preview: bool = true
@export var velocidade_animacao: float = 1.0
@export var nome_animacao: StringName = &"mixamo_com"


var personagem: Node = null
var animation_player: AnimationPlayer = null

var tempo_animacao: float = 0.0
var animacao_atual: StringName = &""


func _ready() -> void:
	localizar_personagem_e_animacao()


func _process(delta: float) -> void:

	if !animar_preview:
		return

	if animation_player == null:
		localizar_personagem_e_animacao()

	if animation_player == null:
		return

	if !is_instance_valid(animation_player):
		animation_player = null
		return

	if animacao_atual == &"":
		preparar_animacao()

	if animacao_atual == &"":
		return

	if !animation_player.has_animation(animacao_atual):
		return

	var animacao: Animation = animation_player.get_animation(
		animacao_atual
	)

	if animacao == null:
		return

	var duracao: float = animacao.length

	if duracao <= 0.0:
		return

	tempo_animacao += delta * velocidade_animacao

	if tempo_animacao >= duracao:
		tempo_animacao = fmod(
			tempo_animacao,
			duracao
		)

	# Forca a pose da animacao a ser aplicada.
	animation_player.seek(
		tempo_animacao,
		true
	)


func localizar_personagem_e_animacao() -> void:

	personagem = find_child(
		"policial_vanguard_idle",
		true,
		false
	)

	if personagem == null:
		return

	var encontrado: Node = personagem.find_child(
		"AnimationPlayer",
		true,
		false
	)

	if !(encontrado is AnimationPlayer):
		return

	animation_player = encontrado as AnimationPlayer

	animation_player.process_mode = Node.PROCESS_MODE_ALWAYS

	# ========================================================
	# CORRECAO IMPORTANTE
	#
	# As trilhas do Mixamo usam caminhos relativos ao
	# policial_vanguard_idle.
	# Aqui fazemos o AnimationPlayer apontar para a raiz certa.
	# ========================================================

	var caminho_raiz: NodePath = animation_player.get_path_to(
		personagem
	)

	animation_player.root_node = caminho_raiz

	preparar_animacao()


func preparar_animacao() -> void:

	if animation_player == null:
		return

	var lista: PackedStringArray = (
		animation_player.get_animation_list()
	)

	if lista.is_empty():
		push_warning(
			"VANGUARD: nenhuma animacao encontrada."
		)
		return

	if animation_player.has_animation(
		nome_animacao
	):
		animacao_atual = nome_animacao
	else:
		animacao_atual = StringName(
			lista[0]
		)

	tempo_animacao = 0.0

	animation_player.stop()

	animation_player.seek(
		0.0,
		true
	)

	print(
		"======================================"
	)

	print(
		"VANGUARD // ANIMACAO CORRIGIDA"
	)

	print(
		"Animacao: ",
		animacao_atual
	)

	print(
		"Root Node: ",
		animation_player.root_node
	)

	print(
		"======================================"
	)
