class_name Player extends CharacterBody2D

signal pocao_selecionada_alterada(pocao: ItemData)
signal pocao_indisponivel(pocao: ItemData)

# Requer:
# - Area2D filha chamada InteracaoArea com um CollisionShape2D.
# - AnimatedSprite2D filho chamado Anim (com as animações idle_* e walk_*).

const VELOCIDADE: float = 140.0

@export var distancia_interacao: float = 28.0
@export var alcance_interacao: float = 72.0
@export var pocoes_disponiveis: Array[ItemData] = []
@export var pocao_ativa: ItemData

var escudos: int:
	get:
		return InventoryManager.escudos
	set(valor):
		InventoryManager.escudos = valor

@onready var interacao_area: Area2D = get_node_or_null("InteracaoArea")
@onready var anim: AnimatedSprite2D = get_node_or_null("Anim")
@onready var visual_fallback: Node2D = get_node_or_null("Visual")

var olhando: Vector2 = Vector2.DOWN
var direcao_atual: String = "down"
var tempo_animacao: float = 0.0

func _ready() -> void:
	add_to_group("player")
	global_position = SceneRouter.consumir_entrada(global_position)
	if pocao_ativa == null and not pocoes_disponiveis.is_empty():
		pocao_ativa = pocoes_disponiveis[0]

	if interacao_area == null:
		push_error("Player precisa de uma Area2D filha chamada InteracaoArea.")
		return

	interacao_area.monitoring = true
	interacao_area.monitorable = false
	atualizar_posicao_interacao()
	_atualizar_animacao(Vector2.ZERO)

func _physics_process(_delta: float) -> void:
	tempo_animacao += _delta
	var movimento := Input.get_vector("mover_esquerda", "mover_direita", "mover_cima", "mover_baixo")
	velocity = movimento * VELOCIDADE

	if movimento != Vector2.ZERO:
		olhando = _determinar_direcao_cardinal(movimento)

	move_and_slide()
	_atualizar_animacao(movimento)
	if visual_fallback != null and visual_fallback.visible:
		var esta_a_mover := movimento.length_squared() > 0.01
		visual_fallback.position.y = sin(tempo_animacao * 11.0) * 1.2 if esta_a_mover else 0.0
		visual_fallback.scale.x = -1.0 if direcao_atual == "left" else 1.0

	global_position = global_position.clamp(
		Vector2(10.0, 28.0),
		get_viewport_rect().size - Vector2(10.0, 10.0)
	)
	atualizar_posicao_interacao()

	if Input.is_action_just_pressed("interact"):
		interagir()
	if Input.is_action_just_pressed("cycle_potion"):
		ciclar_pocao()
	if Input.is_action_just_pressed("cycle_recipe"):
		ciclar_receita()
	if Input.is_action_just_pressed("cycle_stock"):
		ciclar_stock()

func _unhandled_key_input(event: InputEvent) -> void:
	if get_tree().paused or not event is InputEventKey:
		return
	var tecla := event as InputEventKey
	if not tecla.pressed or tecla.echo:
		return

	if tecla.keycode >= KEY_1 and tecla.keycode <= KEY_4:
		selecionar_pocao_indice(tecla.keycode - KEY_1)

func _determinar_direcao_cardinal(vetor: Vector2) -> Vector2:
	# Prioriza o eixo com maior intensidade para evitar conflitos na diagonal
	if abs(vetor.x) >= abs(vetor.y):
		direcao_atual = "right" if vetor.x > 0.0 else "left"
		return Vector2.RIGHT if vetor.x > 0.0 else Vector2.LEFT
	else:
		direcao_atual = "down" if vetor.y > 0.0 else "up"
		return Vector2.DOWN if vetor.y > 0.0 else Vector2.UP

func _atualizar_animacao(movimento: Vector2) -> void:
	if anim == null or anim.sprite_frames == null:
		if anim != null:
			anim.visible = false
		if visual_fallback != null:
			visual_fallback.visible = true
		return

	var esta_a_mover := movimento.length_squared() > 0.01
	var prefixo := "walk_" if esta_a_mover else "idle_"
	var anim_nome := _obter_animacao_disponivel(prefixo)
	if anim_nome.is_empty():
		anim.visible = false
		if visual_fallback != null:
			visual_fallback.visible = true
		return

	anim.visible = true
	if visual_fallback != null:
		visual_fallback.visible = false
	if anim.animation != anim_nome or not anim.is_playing():
		anim.play(anim_nome)

func _obter_animacao_disponivel(prefixo: String) -> String:
	for nome in [prefixo + direcao_atual, prefixo + "down", "idle_down"]:
		if anim.sprite_frames.has_animation(nome):
			return nome
	return ""

func atualizar_posicao_interacao() -> void:
	if interacao_area != null:
		interacao_area.position = olhando * distancia_interacao

func interagir() -> void:
	var alvo: Node2D = _obter_alvo(&"interagir")
	if alvo == null:
		return
	alvo.call("interagir", self)

func _obter_alvo(metodo: StringName) -> Node2D:
	var melhor_alvo: Node2D
	var menor_distancia := INF
	var alcance_quadrado := alcance_interacao * alcance_interacao
	for candidato in get_tree().get_nodes_in_group("interactables"):
		if not candidato is Node2D or not candidato.has_method(metodo):
			continue
		var alvo := candidato as Node2D
		var distancia := global_position.distance_squared_to(alvo.global_position)
		if distancia <= alcance_quadrado and distancia < menor_distancia:
			menor_distancia = distancia
			melhor_alvo = alvo

	return melhor_alvo

func obter_alvo_interacao() -> Node2D:
	return _obter_alvo(&"interagir")

func ciclar_receita() -> void:
	var alvo: Node2D = _obter_alvo(&"ciclar_receita")
	if alvo != null:
		alvo.call("ciclar_receita")

func ciclar_stock() -> void:
	var alvo: Node2D = _obter_alvo(&"ciclar_stock")
	if alvo != null:
		alvo.call("ciclar_stock")

func ciclar_pocao() -> void:
	var alvo := _obter_alvo(&"obter_pocao_solicitada")
	if alvo != null:
		var solicitada := alvo.call("obter_pocao_solicitada") as ItemData
		if solicitada != null:
			if InventoryManager.obter_quantidade(solicitada.id) > 0:
				selecionar_pocao(solicitada)
			else:
				pocao_indisponivel.emit(solicitada)
			return

	_ciclar_pocao_com_stock()

func _ciclar_pocao_com_stock() -> void:
	if pocoes_disponiveis.is_empty():
		pocao_ativa = null
		pocao_selecionada_alterada.emit(pocao_ativa)
		return

	var indice_atual := pocoes_disponiveis.find(pocao_ativa)
	for deslocamento in range(1, pocoes_disponiveis.size() + 1):
		var indice := (indice_atual + deslocamento) % pocoes_disponiveis.size()
		var candidata: ItemData = pocoes_disponiveis[indice]
		if candidata != null and InventoryManager.inventario.get(candidata.id, 0) > 0:
			pocao_ativa = candidata
			pocao_selecionada_alterada.emit(pocao_ativa)
			return
	pocao_ativa = null
	pocao_selecionada_alterada.emit(pocao_ativa)

func selecionar_pocao_indice(indice: int) -> bool:
	if indice < 0 or indice >= pocoes_disponiveis.size():
		return false
	return selecionar_pocao(pocoes_disponiveis[indice])

func selecionar_pocao(pocao: ItemData) -> bool:
	if pocao == null or not pocoes_disponiveis.has(pocao):
		return false
	if InventoryManager.obter_quantidade(pocao.id) <= 0:
		pocao_indisponivel.emit(pocao)
		return false
	pocao_ativa = pocao
	pocao_selecionada_alterada.emit(pocao_ativa)
	return true

func atualizar_pocao_apos_venda() -> void:
	if pocao_ativa != null and InventoryManager.inventario.get(pocao_ativa.id, 0) <= 0:
		_ciclar_pocao_com_stock()
