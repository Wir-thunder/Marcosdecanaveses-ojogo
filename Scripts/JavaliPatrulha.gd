class_name JavaliPatrulha extends CharacterBody2D

enum Estado { PATRULHA, ALERTA, INVESTIDA, CONFUSO }

@export var pontos_patrulha: Array[Vector2] = [
	Vector2(160, 160),
	Vector2(320, 160),
	Vector2(480, 200),
	Vector2(320, 260)
]
@export var velocidade_patrulha: float = 48.0
@export var velocidade_investida: float = 165.0

@onready var sprite: Sprite2D = $Sprite2D
@onready var sombra: Sprite2D = get_node_or_null("Sombra")
@onready var cone_visao: Area2D = $ConeVisao
@onready var cone_visual: Polygon2D = $ConeVisao/Polygon2D
@onready var alerta_label: Label = $AlertaLabel
@onready var hitbox_investida: Area2D = $HitboxInvestida
@onready var fumaca: CPUParticles2D = $Fumaca

var _tex_walk: Texture2D = preload("res://Assets/Characters/Monsters/Javali/walk_1.png")
var _tex_alert: Texture2D = preload("res://Assets/Characters/Monsters/Javali/alert.png")
var _tex_charge: Texture2D = preload("res://Assets/Characters/Monsters/Javali/charge.png")
var _tex_stun: Texture2D = preload("res://Assets/Characters/Monsters/Javali/stun.png")

var estado: Estado = Estado.PATRULHA
var indice_ponto: int = 0
var alvo_jogador: Player = null
var direcao_mov: Vector2 = Vector2.RIGHT
var tempo_estado: float = 0.0
var _tempo_anim: float = 0.0

# Os PNGs têm o javali completo em cima (≈64x36) e uma cópia CORTADA em baixo:
# usamos só a pose de cima. O desenho original olha para a DIREITA.
const LARGURA_FRAME: float = 64.0
const ALTURA_FRAME: float = 38.0

func _ready() -> void:
	add_to_group("inimigos")
	cone_visao.body_entered.connect(_ao_entrar_visao)
	cone_visao.body_exited.connect(_ao_sair_visao)
	hitbox_investida.body_entered.connect(_ao_atingir_jogador)
	alerta_label.visible = false
	sprite.region_enabled = true
	sprite.region_rect = Rect2(0, 0, LARGURA_FRAME, ALTURA_FRAME)
	if pontos_patrulha.size() > 0:
		global_position = pontos_patrulha[0]

func _physics_process(delta: float) -> void:
	match estado:
		Estado.PATRULHA:
			_processar_patrulha(delta)
		Estado.ALERTA:
			_processar_alerta(delta)
		Estado.INVESTIDA:
			_processar_investida(delta)
		Estado.CONFUSO:
			_processar_confuso(delta)
			
	move_and_slide()
	_animar_sprite(delta)

func _animar_sprite(delta: float) -> void:
	# Trote procedural (só existe 1 pose válida): salto + leve balanço do corpo.
	var freq := 0.0
	var salto_max := 0.0
	var balanco := 0.0
	match estado:
		Estado.PATRULHA:
			if velocity.length() > 1.0:
				freq = 9.0; salto_max = 1.2; balanco = 0.035
		Estado.INVESTIDA:
			freq = 20.0; salto_max = 2.2; balanco = 0.07
		Estado.ALERTA:
			freq = 30.0; balanco = 0.02  # tremer de fúria antes do dash
		Estado.CONFUSO:
			freq = 3.0; balanco = 0.05
	_tempo_anim += delta
	var s := sin(_tempo_anim * freq)
	sprite.region_rect = Rect2(0, 0, LARGURA_FRAME, ALTURA_FRAME)
	sprite.position.y = -15.0 - absf(s) * salto_max
	sprite.rotation = s * balanco * (-1.0 if sprite.flip_h else 1.0)
	if sombra != null:
		sombra.scale = Vector2(3.2, 1.3) * (1.0 - absf(s) * salto_max * 0.05)

func _processar_patrulha(_delta: float) -> void:
	sprite.texture = _tex_walk
	fumaca.emitting = false
	cone_visual.color = Color(1.0, 0.4, 0.2, 0.18)
	
	if pontos_patrulha.is_empty():
		return
	var destino := pontos_patrulha[indice_ponto]
	var dist := global_position.distance_to(destino)
	if dist < 8.0:
		indice_ponto = (indice_ponto + 1) % pontos_patrulha.size()
		destino = pontos_patrulha[indice_ponto]
		
	direcao_mov = (destino - global_position).normalized()
	velocity = direcao_mov * velocidade_patrulha
	_atualizar_rotacao(direcao_mov)

func _processar_alerta(delta: float) -> void:
	sprite.texture = _tex_alert
	velocity = Vector2.ZERO
	tempo_estado -= delta
	cone_visual.color = Color(1.0, 0.1, 0.1, 0.45)
	
	if alvo_jogador != null:
		direcao_mov = (alvo_jogador.global_position - global_position).normalized()
		_atualizar_rotacao(direcao_mov)
		
	if tempo_estado <= 0.0:
		if alvo_jogador != null and not alvo_jogador.escondido:
			estado = Estado.INVESTIDA
			fumaca.emitting = true
			alerta_label.text = "💥 DASH!"
		else:
			_ficar_confuso()

func _processar_investida(_delta: float) -> void:
	sprite.texture = _tex_charge
	cone_visual.color = Color(1.0, 0.0, 0.0, 0.50)
	
	# Se o jogador se escondeu em uma moita durante o dash, o javali perde o rastro
	if alvo_jogador == null or alvo_jogador.escondido:
		_ficar_confuso()
		return
		
	direcao_mov = (alvo_jogador.global_position - global_position).normalized()
	velocity = direcao_mov * velocidade_investida
	_atualizar_rotacao(direcao_mov)

func _processar_confuso(delta: float) -> void:
	sprite.texture = _tex_stun
	velocity = Vector2.ZERO
	fumaca.emitting = false
	cone_visual.color = Color(0.8, 0.8, 0.8, 0.15)
	tempo_estado -= delta
	if tempo_estado <= 0.0:
		alerta_label.visible = false
		estado = Estado.PATRULHA

func _atualizar_rotacao(dir: Vector2) -> void:
	if dir.length_squared() > 0.01:
		cone_visao.rotation = dir.angle()
		# o desenho original olha para a direita: espelha ao andar para a esquerda
		if absf(dir.x) > 0.1:
			sprite.flip_h = (dir.x < 0.0)

func _ao_entrar_visao(body: Node2D) -> void:
	if body.is_in_group("player"):
		var p := body as Player
		if p != null and not p.escondido and estado == Estado.PATRULHA:
			alvo_jogador = p
			estado = Estado.ALERTA
			AudioManager.tocar_sfx("javali_alerta")
			tempo_estado = 0.45
			alerta_label.text = "⚠️ !"
			alerta_label.visible = true

func _ao_sair_visao(body: Node2D) -> void:
	if body == alvo_jogador and estado == Estado.ALERTA:
		_ficar_confuso()

func _ficar_confuso() -> void:
	estado = Estado.CONFUSO
	tempo_estado = 1.2
	alerta_label.text = "❓"
	alerta_label.visible = true
	alvo_jogador = null

func _ao_atingir_jogador(body: Node2D) -> void:
	if body.is_in_group("player") and estado == Estado.INVESTIDA:
		var p := body as Player
		if p != null:
			# Penalidade: perde recursos colhidos e 5 de ouro
			var perdidos := InventoryManager.perder_recursos_aleatorios(2)
			p.escudos = maxi(0, p.escudos - 5)
			
			var cena := get_tree().current_scene
			if cena != null and cena.has_method("mostrar_mensagem"):
				var msg := "💥 FOSTE ATROPELADO PELO JAVALI! Perdeste recursos na fuga!"
				if not perdidos.is_empty():
					msg = "💥 O JAVALI ATROPELOU-TE! Perdeste %d ervas na fuga!" % perdidos.size()
				cena.call("mostrar_mensagem", msg)
				
			# Empurrar o jogador de volta para a entrada sul
			p.global_position = Vector2(320, 310)
			_ficar_confuso()

