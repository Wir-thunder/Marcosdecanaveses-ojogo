class_name TongobrigaProjectile extends Node2D

signal hit_target(target: TongobrigaChampion, damage: int)

const HIT_SPARK_SCRIPT: Script = preload("res://Scripts/TongobrigaHitSpark.gd")

const TEX_FALCATA: String    = "res://Assets/Effects/Tongobriga/especial_falcata_viriato.png"
const TEX_FLECHA: String     = "res://Assets/Effects/Tongobriga/especial_flecha_nabia.png"
const TEX_FOGO: String       = "res://Assets/Effects/Tongobriga/especial_fogo_endovelico.png"
const TEX_ESCUDO: String     = "res://Assets/Effects/Tongobriga/especial_escudo_aunia.png"
const TEX_CARNYX: String     = "res://Assets/Effects/Tongobriga/especial_carnyx_breno.png"
const TEX_SISMO: String      = "res://Assets/Effects/Tongobriga/especial_sismo_bracaro.png"
const TEX_PILUM: String      = "res://Assets/Effects/Tongobriga/especial_pilum_decimo.png"
const TEX_FOICES: String     = "res://Assets/Effects/Tongobriga/especial_foices_trebaruna.png"
const TEX_PERUN: String      = "res://Assets/Effects/Tongobriga/especial_perun_klaudia.png"
const TEX_FOGOGREGO: String  = "res://Assets/Effects/Tongobriga/especial_fogogrego_marco.png"

var attacker: TongobrigaChampion
var target: TongobrigaChampion
var projectile_type: String = "falcata"
var damage: int = 25
var facing: float = 1.0
var speed: float = 500.0
var is_aoe: bool = false
var lifetime: float = 2.5
var _time: float = 0.0
var _hit_already: bool = false
var _hitbox_half_extents: Vector2 = Vector2(22.0, 18.0)

var _sprite: Sprite2D

func _init() -> void:
	z_index = 25
	_sprite = Sprite2D.new()
	_sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	add_child(_sprite)

static func _load_tex_safe(path: String) -> Texture2D:
	if ResourceLoader.exists(path):
		var res := load(path)
		if res is Texture2D:
			return res as Texture2D
	if FileAccess.file_exists(path):
		var img := Image.load_from_file(ProjectSettings.globalize_path(path))
		if img != null:
			return ImageTexture.create_from_image(img)
	return null

func setup(
	p_attacker: TongobrigaChampion,
	p_target: TongobrigaChampion,
	p_type: String,
	p_damage: int,
	p_spawn_pos: Vector2,
	p_facing: float
) -> void:
	attacker = p_attacker
	target = p_target
	projectile_type = p_type
	damage = p_damage
	facing = p_facing
	global_position = p_spawn_pos

	var tex_path := TEX_FALCATA
	is_aoe = false

	match projectile_type:
		"falcata":
			tex_path = TEX_FALCATA
			speed = 520.0
			_sprite.scale = Vector2(0.55, 0.55)
			_hitbox_half_extents = Vector2(24.0, 22.0)
		"water_arrow", "flecha":
			tex_path = TEX_FLECHA
			speed = 630.0
			_sprite.scale = Vector2(0.52, 0.52)
			_hitbox_half_extents = Vector2(26.0, 12.0)
		"fireball", "fogo":
			tex_path = TEX_FOGO
			speed = 460.0
			_sprite.scale = Vector2(0.56, 0.56)
			_hitbox_half_extents = Vector2(24.0, 20.0)
		"celtic_nova", "escudo":
			tex_path = TEX_ESCUDO
			is_aoe = true
			speed = 0.0
			_sprite.scale = Vector2(0.30, 0.30)
			lifetime = 0.75
			_hitbox_half_extents = Vector2(75.0, 75.0)
		"carnyx":
			tex_path = TEX_CARNYX
			speed = 490.0
			_sprite.scale = Vector2(0.28, 0.28)
			_hitbox_half_extents = Vector2(28.0, 24.0)
		"sismo":
			tex_path = TEX_SISMO
			speed = 420.0
			_sprite.scale = Vector2(0.30, 0.30)
			_hitbox_half_extents = Vector2(30.0, 24.0)
		"pilum":
			tex_path = TEX_PILUM
			speed = 660.0
			_sprite.scale = Vector2(0.30, 0.30)
			_hitbox_half_extents = Vector2(30.0, 14.0)
		"foices":
			tex_path = TEX_FOICES
			speed = 590.0
			_sprite.scale = Vector2(0.27, 0.27)
			_hitbox_half_extents = Vector2(26.0, 22.0)
		"perun":
			tex_path = TEX_PERUN
			speed = 560.0
			_sprite.scale = Vector2(0.27, 0.27)
			_hitbox_half_extents = Vector2(26.0, 26.0)
		"fogogrego":
			tex_path = TEX_FOGOGREGO
			speed = 480.0
			_sprite.scale = Vector2(0.29, 0.29)
			_hitbox_half_extents = Vector2(26.0, 18.0)
		_:
			tex_path = TEX_FALCATA
			speed = 500.0
			_sprite.scale = Vector2(0.55, 0.55)
			_hitbox_half_extents = Vector2(22.0, 18.0)

	_sprite.texture = _load_tex_safe(tex_path)

	if not is_aoe:
		_sprite.flip_h = (facing < 0.0)
	else:
		var tw := create_tween()
		tw.tween_property(_sprite, "scale", Vector2(1.25, 1.25), 0.55).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		tw.parallel().tween_property(_sprite, "modulate:a", 0.0, 0.55).set_ease(Tween.EASE_IN)

func get_hitbox_rect() -> Rect2:
	if is_aoe:
		var raio_atual := 115.0 * clampf(_sprite.scale.x / 1.25, 0.25, 1.0)
		return Rect2(
			global_position.x - raio_atual,
			global_position.y - raio_atual,
			raio_atual * 2.0,
			raio_atual * 2.0
		)
	var center := global_position + _sprite.position
	return Rect2(
		center - _hitbox_half_extents,
		_hitbox_half_extents * 2.0
	)

func _process(delta: float) -> void:
	_time += delta
	lifetime -= delta

	if lifetime <= 0.0:
		queue_free()
		return

	if not is_aoe:
		global_position.x += facing * speed * delta

		if projectile_type in ["fireball", "fogo", "fogogrego"]:
			_sprite.position.y = sin(_time * 16.0) * 4.0
		elif projectile_type in ["falcata", "foices"]:
			_sprite.rotation = facing * sin(_time * 12.0) * 0.14
		elif projectile_type == "carnyx":
			var pulse := 0.28 + sin(_time * 18.0) * 0.025
			_sprite.scale = Vector2(pulse, pulse)

		if global_position.x < 15.0 or global_position.x > 625.0:
			queue_free()
			return

	# Verificação de colisão real contra as Hurtboxes do alvo
	if not _hit_already and target != null and not target.defeated:
		var proj_box := get_hitbox_rect()
		for hurtbox: Rect2 in target.get_hurtboxes():
			if proj_box.intersects(hurtbox):
				_ao_atingir_alvo(target, proj_box.intersection(hurtbox).get_center())
				break

	queue_redraw()

func _draw() -> void:
	if not TongobrigaChampion.debug_hitboxes or _hit_already:
		return
	var hb := get_hitbox_rect()
	var local_rect := Rect2(hb.position - global_position, hb.size)
	draw_rect(local_rect, Color(1.0, 0.12, 0.12, 0.35), true)
	draw_rect(local_rect, Color(1.0, 0.3, 0.2, 0.95), false, 1.5)

func _ao_atingir_alvo(alvo: TongobrigaChampion, impact_point: Vector2) -> void:
	_hit_already = true
	hit_target.emit(alvo, damage)

	var spark := Node2D.new()
	spark.set_script(HIT_SPARK_SCRIPT)
	var hs := spark as TongobrigaHitSpark
	if get_parent() != null:
		get_parent().add_child(hs)
		hs.setup(impact_point, "block" if alvo.blocking else "special")

	alvo.receive_hit(damage, attacker, "special")

	var tw := create_tween()
	tw.tween_property(_sprite, "scale", _sprite.scale * 1.35, 0.1)
	tw.parallel().tween_property(_sprite, "modulate:a", 0.0, 0.1)
	tw.finished.connect(queue_free)
