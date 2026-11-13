class_name Player extends CharacterBody2D

signal pocao_selecionada_alterada(pocao: ItemData)
signal pocao_indisponivel(pocao: ItemData)

# Requer:
# - Area2D filha chamada InteracaoArea com um CollisionShape2D.
# - AnimatedSprite2D filho chamado Anim (com as animações idle_* e walk_*).

const VELOCIDADE: float = 105.0
const ACELERACAO: float = 900.0
const FRICCAO: float = 1100.0
# Passada do sprite: ~40 px de chão por ciclo de 4 frames (evita "patinar" sobre o cenário).
const PASSADA_PX: float = 40.0
const FPS_BASE_ANIM: float = 8.0

@export var distancia_interacao: float = 28.0
@export var alcance_interacao: float = 72.0
@export var pocoes_disponiveis: Array[ItemData] = []
@export var pocao_ativa: ItemData
@export var escala_multiplicador: float = 1.0
@export var camera_zoom: Vector2 = Vector2.ONE

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
var escondido: bool = false
var _sombra_contacto: Sprite2D = null
var _anim_offset_base: Vector2 = Vector2.ZERO
var _anim_escala_base: Vector2 = Vector2.ONE
var _fase_passada: float = 0.0

func _criar_sombra_contacto() -> void:
	# Sombra elíptica suave aos pés: ancora o personagem ao chão (a sombra antiga era
	# quase invisível e fazia-o parecer a planar).
	var antiga := get_node_or_null("Sombra") as Sprite2D
	if antiga != null:
		antiga.visible = false
	var grad := Gradient.new()
	grad.offsets = PackedFloat32Array([0.0, 0.55, 1.0])
	grad.colors = PackedColorArray([Color(0, 0, 0, 0.62), Color(0, 0, 0, 0.34), Color(0, 0, 0, 0.0)])
	var tex := GradientTexture2D.new()
	tex.gradient = grad
	tex.fill = GradientTexture2D.FILL_RADIAL
	tex.fill_from = Vector2(0.5, 0.5)
	tex.fill_to = Vector2(1.0, 0.5)
	tex.width = 64
	tex.height = 64
	_sombra_contacto = Sprite2D.new()
	_sombra_contacto.name = "SombraContacto"
	_sombra_contacto.texture = tex
	_sombra_contacto.show_behind_parent = true
	_sombra_contacto.position = Vector2(0, 1)
	_sombra_contacto.scale = Vector2(0.62, 0.24)
	add_child(_sombra_contacto)
	move_child(_sombra_contacto, 0)

func _emitir_poeira() -> void:
	var cena := get_tree().current_scene
	if cena == null:
		return
	for i in 2:
		var p := ColorRect.new()
		p.size = Vector2(2, 2)
		p.color = Color(0.82, 0.76, 0.64, 0.55)
		p.z_index = -1
		p.position = global_position + Vector2(randf_range(-5.0, 5.0), randf_range(-1.0, 1.0))
		cena.add_child(p)
		var tw := p.create_tween()
		tw.set_parallel(true)
		tw.tween_property(p, "position", p.position + Vector2(randf_range(-5.0, 5.0), -4.0), 0.35)
		tw.tween_property(p, "modulate:a", 0.0, 0.35)
		tw.chain().tween_callback(p.queue_free)

func set_escondido(val: bool) -> void:
	escondido = val
	if anim != null:
		var tw := create_tween()
		tw.tween_property(anim, "modulate:a", 0.45 if val else 1.0, 0.2)

func _ready() -> void:
	add_to_group("player")
	global_position = SceneRouter.consumir_entrada(global_position)
	if pocao_ativa == null and not pocoes_disponiveis.is_empty():
		pocao_ativa = pocoes_disponiveis[0]

	if interacao_area == null:
		push_error("Player precisa de uma Area2D filha chamada InteracaoArea.")
		return

	if anim != null:
		anim.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
		if escala_multiplicador != 1.0:
			anim.scale *= escala_multiplicador
			if visual_fallback != null:
				visual_fallback.scale *= escala_multiplicador
		_anim_offset_base = anim.offset
		_anim_escala_base = anim.scale
	_criar_sombra_contacto()
	if _sombra_contacto != null:
		_sombra_contacto.scale *= escala_multiplicador
	if escala_multiplicador != 1.0:
		var col := get_node_or_null("CollisionShape2D")
		if col != null:
			col.scale *= escala_multiplicador
		if interacao_area != null:
			var int_col := interacao_area.get_node_or_null("CollisionShape2D")
			if int_col != null:
				int_col.scale *= escala_multiplicador
	var cam: Camera2D = get_node_or_null("Camera2D")
	if cam != null and camera_zoom != Vector2.ONE:
		cam.zoom = camera_zoom
	interacao_area.monitoring = true
	interacao_area.monitorable = false
	atualizar_posicao_interacao()
	_atualizar_animacao(Vector2.ZERO)

func _physics_process(_delta: float) -> void:
	tempo_animacao += _delta
	var movimento := Input.get_vector("mover_esquerda", "mover_direita", "mover_cima", "mover_baixo")
	# Aceleração/fricção: arranque e travagem com inércia em vez de deslizar sobre carris.
	if movimento != Vector2.ZERO:
		velocity = velocity.move_toward(movimento * VELOCIDADE, ACELERACAO * _delta)
		olhando = _determinar_direcao_cardinal(movimento)
	else:
		velocity = velocity.move_toward(Vector2.ZERO, FRICCAO * _delta)

	move_and_slide()
	_atualizar_animacao(movimento)
	_animar_passada(_delta, movimento)
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

func _animar_passada(delta: float, movimento: Vector2) -> void:
	var vel := velocity.length()
	var andando := vel > 10.0 and movimento != Vector2.ZERO
	var altura_passo := 0.0
	if andando:
		# A animação acompanha a velocidade real: pés no ritmo do chão, sem patinar.
		if anim != null:
			anim.speed_scale = clampf(vel / (PASSADA_PX * 2.0), 0.6, 1.6)
		var fase_anterior := _fase_passada
		_fase_passada += (vel * delta / PASSADA_PX) * TAU * 2.0
		altura_passo = absf(sin(_fase_passada * 0.5)) * 1.7
		if floorf(fase_anterior / TAU) != floorf(_fase_passada / TAU):
			if get_node_or_null("/root/AudioManager") != null:
				AudioManager.tocar_sfx_volume("passo_madeira", -13.0, 0.14)
			_emitir_poeira()
	else:
		if anim != null:
			anim.speed_scale = 1.0
		_fase_passada = 0.0

	if anim != null:
		anim.position.y = lerpf(anim.position.y, -altura_passo, minf(1.0, delta * 30.0))
	if _sombra_contacto != null:
		var encolher := 1.0 - altura_passo * 0.06
		_sombra_contacto.scale = Vector2(0.62 * encolher, 0.24 * encolher) * escala_multiplicador

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
	if pocao == null:
		return false
	if not pocoes_disponiveis.has(pocao):
		pocoes_disponiveis.append(pocao)
	if InventoryManager.obter_quantidade(pocao.id) <= 0:
		pocao_indisponivel.emit(pocao)
		return false
	pocao_ativa = pocao
	pocao_selecionada_alterada.emit(pocao_ativa)
	return true

func atualizar_pocao_apos_venda() -> void:
	if pocao_ativa != null and InventoryManager.inventario.get(pocao_ativa.id, 0) <= 0:
		_ciclar_pocao_com_stock()
