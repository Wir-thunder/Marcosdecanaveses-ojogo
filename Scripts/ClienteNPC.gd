class_name ClienteNPC extends CharacterBody2D

const TEXTURA_CLIENTES: Texture2D = preload("res://Sprites/5clientes_transparente.png")
const LINHAS_VISUAIS: Array[int] = [0, 2, 3, 5, 6]
const LINHAS_TRASEIRAS: Array[int] = [1, 2, 4, 5, 7]
const DIRECOES: Array[String] = ["down", "up", "left", "right"]
const LARGURA_FRAME: float = 212.0
const ALTURA_FRAME: float = 316.0

signal venda_sucesso(item: ItemData, valor: int)
signal venda_fracassada(item: ItemData)

enum Estado { ENTRANDO, ESPERANDO, SAINDO }

@export var itens_possiveis: Array[ItemData] = []
@export var velocidade: float = 42.0
@export var paciencia_total: float = 40.0
@export_range(1, 5) var nivel_cliente: int = 1
@export_range(0.5, 3.0, 0.05) var multiplicador_preco: float = 1.0
@export var tipo_visual: int = -1
@export var ponto_entrada: Vector2
@export var ponto_espera: Vector2
@export var ponto_saida: Vector2

@onready var timer_paciencia: Timer = get_node_or_null("TimerPaciencia")
@onready var pedido_label: Label = get_node_or_null("Pedido")
@onready var anim: AnimatedSprite2D = get_node_or_null("Anim")

var estado: Estado = Estado.ENTRANDO
var item_desejado: ItemData
var feliz: bool = false
var direcao_atual: String = "down"

func _ready() -> void:
	if timer_paciencia == null:
		push_error("ClienteNPC precisa de um Timer filho chamado TimerPaciencia.")
		set_physics_process(false)
		return
	timer_paciencia.one_shot = true
	timer_paciencia.timeout.connect(_on_timer_paciencia_timeout)
	if anim == null:
		push_error("ClienteNPC precisa de um AnimatedSprite2D filho chamado Anim.")
		set_physics_process(false)
		return
	_preparar_visual()
	global_position = ponto_entrada

	if itens_possiveis.is_empty():
		push_error("ClienteNPC precisa de pelo menos uma poção em itens_possiveis.")
		set_physics_process(false)
		return

func _process(_delta: float) -> void:
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
				_atualizar_animacao()
			else:
				_atualizar_animacao()
		Estado.ESPERANDO:
			velocity = Vector2.ZERO
			move_and_slide()
			_atualizar_animacao()
		Estado.SAINDO:
			if _mover_para(ponto_saida):
				queue_free()
			else:
				_atualizar_animacao()

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

func _atualizar_animacao() -> void:
	if anim == null or anim.sprite_frames == null:
		return

	if absf(velocity.x) > absf(velocity.y):
		direcao_atual = "right" if velocity.x > 0.0 else "left"
	elif absf(velocity.y) > 0.01:
		direcao_atual = "down" if velocity.y > 0.0 else "up"

	var nome_animacao := "walk_" + direcao_atual
	if velocity.length_squared() <= 0.01:
		if anim.animation != nome_animacao:
			anim.play(nome_animacao)
		anim.pause()
		anim.set_frame_and_progress(0, 0.0)
		return

	if anim.animation != nome_animacao or not anim.is_playing():
		anim.play(nome_animacao)

func _preparar_visual() -> void:
	if anim == null:
		return
	if tipo_visual < 0 or tipo_visual >= LINHAS_VISUAIS.size():
		tipo_visual = randi_range(0, LINHAS_VISUAIS.size() - 1)

	var linha_frente: int = LINHAS_VISUAIS[tipo_visual]
	var linha_costas: int = LINHAS_TRASEIRAS[tipo_visual]
	var frames := SpriteFrames.new()
	frames.remove_animation(&"default")

	for indice in range(DIRECOES.size()):
		var direcao: String = DIRECOES[indice]
		var linha := linha_costas if direcao == "up" else linha_frente
		var nome_animacao := "walk_" + direcao
		frames.add_animation(nome_animacao)
		frames.set_animation_speed(nome_animacao, 8.0)
		frames.set_animation_loop(nome_animacao, true)
		frames.add_frame(nome_animacao, _obter_textura_frame(linha, indice))
		frames.add_frame(nome_animacao, _obter_textura_frame(linha, indice + 4))

	anim.sprite_frames = frames
	anim.scale = Vector2(0.13, 0.13)
	anim.offset = Vector2(0.0, -18.0)
	anim.visible = true
	anim.play("walk_down")
	anim.pause()

func _obter_textura_frame(linha: int, coluna: int) -> AtlasTexture:
	var textura := AtlasTexture.new()
	textura.atlas = TEXTURA_CLIENTES
	textura.region = Rect2(
		float(coluna) * LARGURA_FRAME,
		float(linha) * ALTURA_FRAME,
		LARGURA_FRAME,
		ALTURA_FRAME
	)
	return textura

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
	var valor: int = calcular_preco(pocao)
	var jogador := get_tree().get_first_node_in_group("player") as Player
	if jogador != null:
		jogador.escudos += valor

	feliz = true
	estado = Estado.SAINDO
	venda_sucesso.emit(pocao, valor)
	return true

func calcular_preco(pocao: ItemData) -> int:
	if pocao == null:
		return 0
	return maxi(1, roundi(float(pocao.valor_em_escudos) * multiplicador_preco))

func _on_timer_paciencia_timeout() -> void:
	if estado != Estado.ESPERANDO:
		return
	estado = Estado.SAINDO
	if item_desejado != null:
		venda_fracassada.emit(item_desejado)
