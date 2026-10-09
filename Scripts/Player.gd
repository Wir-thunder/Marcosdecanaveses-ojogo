class_name Player extends CharacterBody2D

signal pocao_selecionada_alterada(pocao: ItemData)

# Requer uma Area2D filha chamada InteracaoArea com um CollisionShape2D.

const VELOCIDADE: float = 140.0

@export var distancia_interacao: float = 28.0
@export var escudos: int = 0
@export var pocoes_disponiveis: Array[ItemData] = []
@export var pocao_ativa: ItemData

@onready var interacao_area: Area2D = get_node_or_null("InteracaoArea")
@onready var visual: Node2D = get_node_or_null("Visual")

var olhando: Vector2 = Vector2.DOWN
var tempo_animacao: float = 0.0

func _ready() -> void:
	add_to_group("player")
	if pocao_ativa == null and not pocoes_disponiveis.is_empty():
		pocao_ativa = pocoes_disponiveis[0]

	if interacao_area == null:
		push_error("Player precisa de uma Area2D filha chamada InteracaoArea.")
		return

	interacao_area.monitoring = true
	interacao_area.monitorable = false
	atualizar_posicao_interacao()

func _physics_process(_delta: float) -> void:
	var movimento := Input.get_vector("mover_esquerda", "mover_direita", "mover_cima", "mover_baixo")
	velocity = movimento * VELOCIDADE
	if movimento != Vector2.ZERO:
		olhando = movimento.normalized()

	move_and_slide()
	tempo_animacao += _delta
	if visual != null:
		var esta_a_mover := movimento.length_squared() > 0.01
		visual.position.y = sin(tempo_animacao * 11.0) * 1.2 if esta_a_mover else 0.0
		if movimento.x != 0.0:
			visual.scale.x = sign(movimento.x)
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

func atualizar_posicao_interacao() -> void:
	if interacao_area != null:
		interacao_area.position = olhando * distancia_interacao

func interagir() -> void:
	var alvo: Node2D = _obter_alvo(&"interagir")
	if alvo == null:
		return
	alvo.call("interagir", self)

func _obter_alvo(metodo: StringName) -> Node2D:
	if interacao_area == null:
		return null

	var melhor_alvo: Node2D
	var menor_distancia := INF
	for corpo in interacao_area.get_overlapping_bodies():
		if corpo is Node2D and corpo.has_method(metodo):
			var distancia: float = global_position.distance_squared_to(corpo.global_position)
			if distancia < menor_distancia:
				menor_distancia = distancia
				melhor_alvo = corpo

	for area in interacao_area.get_overlapping_areas():
		if area is Node2D and area.has_method(metodo):
			var distancia: float = global_position.distance_squared_to(area.global_position)
			if distancia < menor_distancia:
				menor_distancia = distancia
				melhor_alvo = area

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

func selecionar_pocao(pocao: ItemData) -> void:
	if pocoes_disponiveis.has(pocao):
		pocao_ativa = pocao
		pocao_selecionada_alterada.emit(pocao_ativa)
	elif pocao_ativa == null:
		pocao_ativa = pocao
		pocao_selecionada_alterada.emit(pocao_ativa)

func atualizar_pocao_apos_venda() -> void:
	if pocao_ativa != null and InventoryManager.inventario.get(pocao_ativa.id, 0) <= 0:
		ciclar_pocao()
