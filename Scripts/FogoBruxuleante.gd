class_name FogoBruxuleante extends Node2D

@export var velocidade_flicker: float = 14.0
@export var intensidade_base: float = 1.0
@export var variacao_intensidade: float = 0.22
@export var cor_quente: Color = Color(1.0, 0.76, 0.42, 1.0)
@export var cor_alaranjada: Color = Color(1.0, 0.52, 0.22, 1.0)
@export var animar_escala: bool = true

@onready var anim_sprite: AnimatedSprite2D = get_node_or_null("Anim")
@onready var luz_ponto: PointLight2D = get_node_or_null("Luz")
@onready var halo_brilho: Sprite2D = get_node_or_null("HaloBrilho")

var _tempo: float = 0.0
var _offset_aleatorio: float = 0.0

func _ready() -> void:
	_offset_aleatorio = randf() * 100.0
	if anim_sprite != null and not anim_sprite.is_playing():
		anim_sprite.play()

func _process(delta: float) -> void:
	_tempo += delta * velocidade_flicker
	# Combinação de senos com frequências irracionais para criar oscilação orgânica contínua sem repetição robótica
	var ruido := (
		sin(_tempo + _offset_aleatorio) * 0.5 +
		sin(_tempo * 2.37 + _offset_aleatorio * 1.5) * 0.3 +
		sin(_tempo * 4.91) * 0.2
	)
	
	var fator := intensidade_base + (ruido * variacao_intensidade)
	var cor_atual := cor_quente.lerp(cor_alaranjada, clampf((ruido + 1.0) * 0.5, 0.0, 1.0))
	
	if luz_ponto != null:
		luz_ponto.energy = fator
		luz_ponto.color = cor_atual
		if animar_escala:
			var escala_fator := 1.0 + (ruido * 0.08)
			luz_ponto.texture_scale = escala_fator
			
	if halo_brilho != null:
		halo_brilho.modulate = Color(cor_atual.r, cor_atual.g, cor_atual.b, clampf(fator * 0.65, 0.3, 0.9))
		if animar_escala:
			var s := 1.0 + (ruido * 0.06)
			halo_brilho.scale = Vector2(s, s)

