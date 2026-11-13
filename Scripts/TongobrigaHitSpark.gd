class_name TongobrigaHitSpark extends Node2D

const TEX_SOCO: String = "res://Assets/Effects/Tongobriga/hitspark_soco.png"
const TEX_CRITICO: String = "res://Assets/Effects/Tongobriga/hitspark_critico.png"
const TEX_BLOQUEIO: String = "res://Assets/Effects/Tongobriga/hitspark_bloqueio.png"

var _sprite: Sprite2D

func _init() -> void:
	z_index = 35
	_sprite = Sprite2D.new()
	_sprite.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	add_child(_sprite)

func setup(pos: Vector2, tipo: String = "hit") -> void:
	global_position = pos
	var tex_path := TEX_SOCO
	var start_scale := Vector2(0.5, 0.5)
	var end_scale := Vector2(0.85, 0.85)
	var dur := 0.22
	
	match tipo:
		"block":
			tex_path = TEX_BLOQUEIO
			_sprite.modulate = Color(0.7, 1.3, 2.0, 1.0)
			end_scale = Vector2(0.8, 0.8)
		"special", "critical":
			tex_path = TEX_CRITICO
			_sprite.modulate = Color(2.5, 2.0, 1.2, 1.0)
			start_scale = Vector2(0.7, 0.7)
			end_scale = Vector2(1.25, 1.25)
			dur = 0.28
		_:
			tex_path = TEX_SOCO
			_sprite.modulate = Color(2.2, 1.8, 1.0, 1.0)
			end_scale = Vector2(0.85, 0.85)

	if ResourceLoader.exists(tex_path):
		_sprite.texture = load(tex_path)

	_sprite.scale = start_scale
	_sprite.rotation = randf_range(-0.35, 0.35)

	var tw := create_tween().set_parallel(true)
	tw.tween_property(_sprite, "scale", end_scale, dur).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_property(_sprite, "modulate:a", 0.0, dur).set_ease(Tween.EASE_IN)
	tw.finished.connect(queue_free)

