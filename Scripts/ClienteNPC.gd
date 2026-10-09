class_name ClienteNPC extends CharacterBody2D

signal venda_sucesso(item: ItemData, valor: int)
signal venda_fracassada(item: ItemData)

enum Estado { ENTRANDO, ESPERANDO, SAINDO }

@export var itens_possiveis: Array[ItemData] = []
@export var velocidade: float = 42.0
@export var paciencia_total: float = 18.0
@export var ponto_entrada: Vector2
@export var ponto_espera: Vector2
@export var ponto_saida: Vector2

@onready var timer_paciencia: Timer = get_node_or_null("TimerPaciencia")
@onready var pedido_label: Label = get_node_or_null("Pedido")

var estado: Estado = Estado.ENTRANDO
var item_desejado: ItemData
var feliz: bool = false
var tempo_animacao: float = 0.0
var posicao_visual_base: Vector2

func _ready() -> void:
	if timer_paciencia == null:
		push_error("ClienteNPC precisa de um Timer filho chamado TimerPaciencia.")
		set_physics_process(false)
		return
	timer_paciencia.one_shot = true
	timer_paciencia.timeout.connect(_on_timer_paciencia_timeout)
	posicao_visual_base = $Visual.position
	global_position = ponto_entrada

	if itens_possiveis.is_empty():
		push_error("ClienteNPC precisa de pelo menos uma poção em itens_possiveis.")
		set_physics_process(false)
		return

func _process(_delta: float) -> void:
	tempo_animacao += _delta
	if estado == Estado.ESPERANDO:
		$Visual.position = posicao_visual_base + Vector2(0.0, sin(tempo_animacao * 2.5) * 1.2)
	else:
		$Visual.position = posicao_visual_base
	if pedido_label == null:
		return
	match estado:
		Estado.ENTRANDO:
			pedido_label.text = "A chegar..."
		Estado.ESPERANDO:
			if item_desejado != null:
				pedido_label.text = "%s\n%d s" % [
					item_desejado.nome_do_item.replace("Poção ", ""),
					ceili(timer_paciencia.time_left),
				]
		Estado.SAINDO:
			pedido_label.text = "Obrigado!" if feliz else "Vou-me embora!"

func _physics_process(_delta: float) -> void:
	match estado:
		Estado.ENTRANDO:
			if _mover_para(ponto_espera):
				estado = Estado.ESPERANDO
				escolher_pocao_aleatoria()
				timer_paciencia.start(paciencia_total)
		Estado.ESPERANDO:
			velocity = Vector2.ZERO
			move_and_slide()
		Estado.SAINDO:
			if _mover_para(ponto_saida):
				queue_free()

func _mover_para(destino: Vector2) -> bool:
	var deslocamento := destino - global_position
	if deslocamento.length() <= 3.0:
		global_position = destino
		velocity = Vector2.ZERO
		move_and_slide()
		return true

	velocity = deslocamento.normalized() * velocidade
	move_and_slide()
	return false

func escolher_pocao_aleatoria() -> void:
	var opcoes_validas: Array[ItemData] = []
	for item in itens_possiveis:
		if item != null:
			opcoes_validas.append(item)
	if opcoes_validas.is_empty():
		push_error("A lista itens_possiveis não contém poções válidas.")
		return
	item_desejado = opcoes_validas.pick_random()

func receber_pocao(pocao: ItemData) -> bool:
	if estado != Estado.ESPERANDO or pocao == null or item_desejado == null:
		return false
	if pocao != item_desejado:
		return false

	timer_paciencia.stop()
	var valor: int = pocao.valor_em_escudos
	var jogador := get_tree().get_first_node_in_group("player") as Player
	if jogador != null:
		jogador.escudos += valor

	feliz = true
	estado = Estado.SAINDO
	venda_sucesso.emit(pocao, valor)
	return true

func _on_timer_paciencia_timeout() -> void:
	if estado != Estado.ESPERANDO:
		return
	estado = Estado.SAINDO
	if item_desejado != null:
		venda_fracassada.emit(item_desejado)
