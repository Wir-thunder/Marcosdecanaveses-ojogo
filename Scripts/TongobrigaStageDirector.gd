class_name TongobrigaStageDirector extends Node2D

const STAGES: Array[Dictionary] = [
	{
		"id": "castro",
		"name": "Castro Celta & Pedra Formosa",
		"subtitle": "Santuário Castrejo ao Pôr do Sol",
		"bg": "res://Assets/Environment/backgrounds/tongobriga_stage1_castro.png",
		"bgm": "stage1_castro",
		"braziers_visible": true,
		"brazier_left": Vector2(232.0, 206.0),
		"brazier_right": Vector2(408.0, 206.0),
		"brazier_scale": Vector2(0.95, 0.95),
		"tint": Color(1.0, 0.94, 0.88),
		"haze_color": Color(0.85, 0.65, 0.40),
		"haze_amount": 0.16,
		"npcs": [
			{"stage": "castro", "x_min": 105.0, "x_max": 150.0, "y": 248.0, "scale": 0.52, "speed": 14.0},
			{"stage": "castro", "x_min": 420.0, "x_max": 470.0, "y": 248.0, "scale": 0.52, "speed": 15.0},
		]
	},
	{
		"id": "termas",
		"name": "Termas & Fórum Romano",
		"subtitle": "Balneário Sagrado de Tongóbriga",
		"bg": "res://Assets/Environment/backgrounds/tongobriga_stage2_termas.png",
		"bgm": "stage2_termas_forum",
		"braziers_visible": true,
		"brazier_left": Vector2(72.0, 204.0),
		"brazier_right": Vector2(576.0, 204.0),
		"brazier_scale": Vector2(0.88, 0.88),
		"tint": Color(1.0, 0.98, 0.96),
		"haze_color": Color(0.70, 0.85, 0.90),
		"haze_amount": 0.18,
		"npcs": [
			{"stage": "termas", "x_min": 140.0, "x_max": 200.0, "y": 244.0, "scale": 0.50, "speed": 12.0},
			{"stage": "termas", "x_min": 520.0, "x_max": 590.0, "y": 112.0, "scale": 0.35, "speed": 9.0},
		]
	},
	{
		"id": "ponte",
		"name": "Ponte Medieval do Tâmega",
		"subtitle": "Travessia de Granito sobre o Vale",
		"bg": "res://Assets/Environment/backgrounds/tongobriga_stage3_ponte.png",
		"bgm": "stage3_ponte_tamega",
		"braziers_visible": false,
		"brazier_left": Vector2(66.0, 232.0),
		"brazier_right": Vector2(574.0, 232.0),
		"brazier_scale": Vector2.ONE,
		"tint": Color(1.0, 0.96, 0.90),
		"haze_color": Color(0.88, 0.72, 0.55),
		"haze_amount": 0.17,
		"npcs": [
			{"stage": "ponte", "x_min": 240.0, "x_max": 330.0, "y": 252.0, "scale": 0.52, "speed": 15.0},
			{"stage": "ponte", "x_min": 340.0, "x_max": 420.0, "y": 252.0, "scale": 0.52, "speed": 16.0},
		]
	},
	{
		"id": "praca_noite",
		"name": "Praça da Taverna & Botica",
		"subtitle": "Feira Noturna frente à Loja do Alquimista",
		"bg": "res://Assets/Environment/backgrounds/tongobriga_stage4_praca_noite.png",
		"bgm": "stage4_feira_noite",
		"braziers_visible": true,
		"brazier_left": Vector2(18.0, 198.0),
		"brazier_right": Vector2(136.0, 110.0),
		"brazier_scale": Vector2(0.75, 0.75),
		"tint": Color(0.92, 0.88, 1.0),
		"haze_color": Color(0.22, 0.24, 0.38),
		"haze_amount": 0.22,
		"npcs": [
			{"stage": "praca", "x_min": 230.0, "x_max": 320.0, "y": 182.0, "scale": 0.48, "speed": 13.0},
			{"stage": "ponte", "x_min": 260.0, "x_max": 340.0, "y": 178.0, "scale": 0.46, "speed": 14.0},
		]
	}
]

static var _npc_frames_cache: Dictionary = {}
static var _spectator_shader: Shader = null

var current_stage_index: int = 0
var _time: float = 0.0
var _cheer_timer: float = 0.0
var _rng := RandomNumberGenerator.new()

var _npc_Layer: Node2D
var _fx_Layer: Node2D
var _walkers: Array[Dictionary] = []
var _particles: Array[Dictionary] = []

func _init() -> void:
	z_index = 2
	_rng.randomize()
	_npc_Layer = Node2D.new()
	_npc_Layer.name = "MovingBackgroundNPCs"
	add_child(_npc_Layer)

	_fx_Layer = Node2D.new()
	_fx_Layer.name = "StageDynamicVFX"
	add_child(_fx_Layer)

	if _spectator_shader == null:
		_spectator_shader = Shader.new()
		_spectator_shader.code = """
shader_type canvas_item;

uniform vec4 haze_color : source_color = vec4(0.85, 0.75, 0.65, 1.0);
uniform float haze_amount : hint_range(0.0, 1.0) = 0.16;
uniform float depth_contrast : hint_range(0.5, 1.5) = 0.92;

void fragment() {
	vec4 col = texture(TEXTURE, UV);
	if (col.a < 0.08) {
		discard;
	}
	vec3 c = mix(vec3(0.5), col.rgb, depth_contrast);
	c = mix(c, haze_color.rgb, haze_amount);
	COLOR = vec4(c, col.a) * COLOR;
}
"""

static func get_stage_count() -> int:
	return STAGES.size()

static func get_stage_info(idx: int) -> Dictionary:
	return STAGES[posmod(idx, STAGES.size())]

func apply_stage(
	idx: int,
	bg_sprite: Sprite2D,
	brazier_left: Node2D = null,
	brazier_right: Node2D = null,
	play_music: bool = true
) -> Dictionary:
	current_stage_index = posmod(idx, STAGES.size())
	_cheer_timer = 0.0
	var info: Dictionary = STAGES[current_stage_index]

	if bg_sprite != null:
		var bg_path := str(info["bg"])
		if ResourceLoader.exists(bg_path):
			bg_sprite.texture = load(bg_path)
		elif FileAccess.file_exists(bg_path):
			var img := Image.load_from_file(ProjectSettings.globalize_path(bg_path))
			if img != null:
				bg_sprite.texture = ImageTexture.create_from_image(img)
		if bg_sprite.texture != null:
			var ts := bg_sprite.texture.get_size()
			if ts.x > 0.0 and ts.y > 0.0:
				bg_sprite.scale = Vector2(640.0 / ts.x, 360.0 / ts.y)

	if brazier_left != null:
		brazier_left.visible = bool(info["braziers_visible"])
		brazier_left.position = info["brazier_left"]
		brazier_left.scale = info["brazier_scale"]
		var anim_l := brazier_left.get_node_or_null("Anim")
		if anim_l:
			anim_l.visible = false
	if brazier_right != null:
		brazier_right.visible = bool(info["braziers_visible"])
		brazier_right.position = info["brazier_right"]
		brazier_right.scale = info["brazier_scale"]
		var anim_r := brazier_right.get_node_or_null("Anim")
		if anim_r:
			anim_r.visible = false

	_spawn_stage_npcs(info)
	_init_stage_particles(str(info["id"]))

	if play_music and get_node_or_null("/root/AudioManager") != null:
		get_node("/root/AudioManager").tocar_bgm_id(str(info["bgm"]), -9.5)

	queue_redraw()
	return info

func trigger_crowd_cheer(duration: float = 1.1, play_crowd_sfx: bool = false) -> void:
	_cheer_timer = maxf(_cheer_timer, duration)
	if play_crowd_sfx and get_node_or_null("/root/AudioManager") != null:
		get_node("/root/AudioManager").tocar_ambiente("torcida_arena_reacao", -7.5, 0.06)

func _spawn_stage_npcs(info: Dictionary) -> void:
	for c in _npc_Layer.get_children():
		c.queue_free()
	_walkers.clear()

	var npc_defs: Array = info.get("npcs", [])
	var tint: Color = info.get("tint", Color.WHITE)
	var haze_col: Color = info.get("haze_color", Color(0.85, 0.75, 0.65))
	var haze_amt: float = float(info.get("haze_amount", 0.16))

	for i in range(npc_defs.size()):
		var d: Dictionary = npc_defs[i]
		var stage_id: String = str(d.get("stage", "castro"))
		var sf := _get_npc_sprite_frames(stage_id)
		if sf == null:
			continue

		var holder := Node2D.new()
		var x_min := float(d["x_min"])
		var x_max := float(d["x_max"])
		var base_y := float(d["y"])
		var sc := float(d.get("scale", 0.85))
		var start_x := lerpf(x_min, x_max, float(i + 1) / float(npc_defs.size() + 1))

		holder.position = Vector2(start_x, base_y)
		_npc_Layer.add_child(holder)

		var shadow := Polygon2D.new()
		var pts := PackedVector2Array()
		for k in range(10):
			var ang := float(k) * TAU / 10.0
			pts.append(Vector2(cos(ang) * 9.0 * sc, sin(ang) * 3.2 * sc))
		shadow.polygon = pts
		shadow.color = Color(0.0, 0.0, 0.0, 0.35)
		holder.add_child(shadow)

		var spr := AnimatedSprite2D.new()
		spr.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		spr.sprite_frames = sf
		spr.scale = Vector2(sc, sc)
		spr.offset = Vector2(0.0, -27.0)
		spr.modulate = tint

		if _spectator_shader != null:
			var mat := ShaderMaterial.new()
			mat.shader = _spectator_shader
			mat.set_shader_parameter("haze_color", haze_col)
			mat.set_shader_parameter("haze_amount", haze_amt)
			mat.set_shader_parameter("depth_contrast", 0.92)
			spr.material = mat

		spr.play("walk_right")
		holder.add_child(spr)

		_walkers.append({
			"holder": holder,
			"sprite": spr,
			"x_min": x_min,
			"x_max": x_max,
			"base_y": base_y,
			"dir": 1.0 if (i % 2 == 0) else -1.0,
			"speed": float(d.get("speed", 20.0)),
			"pause_timer": _rng.randf_range(0.0, 1.4),
			"phase": _rng.randf_range(0.0, TAU),
		})

static func _get_npc_sprite_frames(stage_id: String) -> SpriteFrames:
	if _npc_frames_cache.has(stage_id):
		return _npc_frames_cache[stage_id]

	var sf := SpriteFrames.new()
	sf.remove_animation(&"default")
	var base := "res://Assets/Characters/Tongobriga/Spectators/%s/" % stage_id
	for anim in ["walk_down", "walk_left", "walk_right"]:
		sf.add_animation(anim)
		sf.set_animation_loop(anim, true)
		sf.set_animation_speed(anim, 5.5 if anim != "walk_down" else 3.5)
		for f in range(1, 5):
			var p := base + "%s_%d.png" % [anim, f]
			var tex: Texture2D = null
			if ResourceLoader.exists(p):
				tex = load(p)
			elif FileAccess.file_exists(p):
				var img := Image.load_from_file(ProjectSettings.globalize_path(p))
				if img != null:
					tex = ImageTexture.create_from_image(img)
			if tex != null:
				sf.add_frame(anim, tex)

	_npc_frames_cache[stage_id] = sf
	return sf

func _init_stage_particles(stage_id: String) -> void:
	_particles.clear()
	match stage_id:
		"castro":
			for i in range(14):
				_particles.append({
					"kind": "ember",
					"pos": Vector2(_rng.randf_range(40.0, 600.0), _rng.randf_range(120.0, 275.0)),
					"vel": Vector2(_rng.randf_range(-10.0, 14.0), _rng.randf_range(-22.0, -9.0)),
					"life": _rng.randf_range(0.2, 1.0),
				})
		"termas":
			for i in range(16):
				_particles.append({
					"kind": "steam",
					"pos": Vector2(_rng.randf_range(205.0, 435.0), _rng.randf_range(185.0, 252.0)),
					"vel": Vector2(_rng.randf_range(-5.0, 5.0), _rng.randf_range(-18.0, -10.0)),
					"radius": _rng.randf_range(5.0, 11.0),
					"alpha": _rng.randf_range(0.10, 0.24),
				})
		"ponte":
			for i in range(4):
				_particles.append({
					"kind": "bird",
					"pos": Vector2(_rng.randf_range(30.0, 610.0), _rng.randf_range(28.0, 86.0)),
					"vel": Vector2(_rng.randf_range(14.0, 24.0), _rng.randf_range(-1.5, 1.5)),
					"phase": _rng.randf_range(0.0, TAU),
				})
		"praca_noite":
			for i in range(18):
				var angle := _rng.randf_range(-PI * 0.82, -PI * 0.18)
				_particles.append({
					"kind": "fountain" if i < 10 else "firefly",
					"pos": Vector2(382.0, 198.0) if i < 10 else Vector2(_rng.randf_range(70.0, 580.0), _rng.randf_range(95.0, 255.0)),
					"vel": Vector2(cos(angle) * _rng.randf_range(14.0, 28.0), sin(angle) * _rng.randf_range(26.0, 42.0)),
					"t": _rng.randf_range(0.0, 1.0),
				})

func _process(delta: float) -> void:
	_time += delta
	if _cheer_timer > 0.0:
		_cheer_timer = maxf(_cheer_timer - delta, 0.0)

	# 1. Atualizar NPCs móveis de fundo (caminhada + paragem para assistir + pulos de torcida!)
	for w: Dictionary in _walkers:
		var holder: Node2D = w["holder"]
		var spr: AnimatedSprite2D = w["sprite"]
		if not is_instance_valid(holder) or not is_instance_valid(spr):
			continue

		var base_y: float = w["base_y"]
		var phase: float = w["phase"]

		if _cheer_timer > 0.0:
			if spr.animation != &"walk_down":
				spr.play("walk_down")
			var hop := absf(sin(_time * 13.0 + phase)) * 6.5
			holder.position.y = base_y - hop
			continue

		var pause_t: float = w["pause_timer"]
		if pause_t > 0.0:
			pause_t -= delta
			w["pause_timer"] = pause_t
			if spr.animation != &"walk_down":
				spr.play("walk_down")
			holder.position.y = base_y - absf(sin(_time * 4.2 + phase)) * 1.4
		else:
			var dir: float = w["dir"]
			var spd: float = w["speed"]
			holder.position.x += dir * spd * delta
			holder.position.y = base_y
			var target_anim := "walk_right" if dir >= 0.0 else "walk_left"
			if spr.animation != target_anim:
				spr.play(target_anim)

			if holder.position.x >= float(w["x_max"]):
				holder.position.x = float(w["x_max"])
				w["dir"] = -1.0
				w["pause_timer"] = _rng.randf_range(1.0, 2.4)
			elif holder.position.x <= float(w["x_min"]):
				holder.position.x = float(w["x_min"])
				w["dir"] = 1.0
				w["pause_timer"] = _rng.randf_range(1.0, 2.4)

	# 2. Atualizar partículas ambientais específicas de cada arena
	var stage_id := str(STAGES[current_stage_index]["id"])
	for p: Dictionary in _particles:
		var kind := str(p["kind"])
		match kind:
			"ember":
				p["pos"] += p["vel"] * delta
				if p["pos"].y < 95.0 or p["pos"].x < 10.0 or p["pos"].x > 630.0:
					p["pos"] = Vector2(_rng.randf_range(60.0, 580.0), _rng.randf_range(220.0, 278.0))
			"steam":
				p["pos"] += p["vel"] * delta
				p["pos"].x += sin(_time * 2.0 + float(p["radius"])) * 6.0 * delta
				if p["pos"].y < 168.0:
					p["pos"] = Vector2(_rng.randf_range(205.0, 435.0), 252.0)
			"bird":
				p["pos"] += p["vel"] * delta
				if p["pos"].x > 652.0:
					p["pos"] = Vector2(-12.0, _rng.randf_range(28.0, 84.0))
			"fountain":
				var t_val: float = float(p["t"]) + delta * 1.35
				if t_val >= 1.0:
					t_val = fmod(t_val, 1.0)
				p["t"] = t_val
			"firefly":
				p["pos"].x += sin(_time * 1.7 + float(p["t"]) * TAU) * 10.0 * delta
				p["pos"].y += cos(_time * 2.1 + float(p["t"]) * TAU) * 8.0 * delta

	if stage_id != "":
		queue_redraw()

func _draw() -> void:
	var stage_id := str(STAGES[current_stage_index]["id"])
	match stage_id:
		"castro":
			# Faíscas rítmicas da bigorna do ferreiro lusitano em (138, 232) + brilho da forja em (28, 212)
			var forge_pulse := (sin(_time * 6.5) + 1.0) * 0.5
			draw_circle(Vector2(28.0, 212.0), 16.0 + forge_pulse * 4.0, Color(1.0, 0.48, 0.12, 0.14 + forge_pulse * 0.10))
			var hammer_cycle := fmod(_time, 1.25)
			if hammer_cycle < 0.32:
				var u := hammer_cycle / 0.32
				draw_circle(Vector2(138.0, 232.0), (1.0 - u) * 7.0, Color(1.0, 0.92, 0.45, 0.75 * (1.0 - u)))
				for s in range(7):
					var ang := -PI * 0.15 - float(s) * 0.36
					var dist := u * (10.0 + float(s % 3) * 7.0)
					var sp := Vector2(138.0 + cos(ang) * dist, 232.0 + sin(ang) * dist + u * u * 11.0)
					draw_rect(Rect2(sp, Vector2(2.0, 2.0)), Color(1.0, 0.82 - u * 0.4, 0.2, 1.0 - u), true)
			for p: Dictionary in _particles:
				draw_rect(Rect2(p["pos"], Vector2(2.0, 2.0)), Color(1.0, 0.68, 0.22, 0.65), true)

		"termas":
			# Brilhos da água termal turquesa + plumas suaves de vapor
			for r in range(6):
				var rx := 215.0 + float(r) * 38.0 + sin(_time * 2.4 + float(r)) * 8.0
				var ry := 222.0 + float(r % 3) * 12.0
				var rw := 14.0 + sin(_time * 3.5 + float(r) * 1.3) * 5.0
				draw_line(Vector2(rx - rw * 0.5, ry), Vector2(rx + rw * 0.5, ry), Color(0.82, 1.0, 1.0, 0.32), 1.0)
			for p: Dictionary in _particles:
				var pos: Vector2 = p["pos"]
				var fade := clampf((pos.y - 168.0) / 84.0, 0.0, 1.0)
				draw_circle(pos, float(p["radius"]) * (1.25 - fade * 0.35), Color(0.92, 0.98, 1.0, float(p["alpha"]) * sin(fade * PI)))

		"ponte":
			# Reflexos vivos da corrente do Rio Tâmega + aves a planar sobre o vale
			for r in range(7):
				var rx := 240.0 + float(r) * 26.0 + sin(_time * 3.0 + float(r)) * 6.0
				var ry := 192.0 + float(r % 4) * 9.0
				draw_line(Vector2(rx - 5.0, ry), Vector2(rx + 5.0, ry), Color(1.0, 0.98, 0.85, 0.38), 1.0)
			for p: Dictionary in _particles:
				var bp: Vector2 = p["pos"]
				var flap := sin(_time * 9.0 + float(p["phase"])) * 2.2
				draw_line(bp + Vector2(-3.0, flap), bp, Color(0.18, 0.14, 0.12, 0.8), 1.0)
				draw_line(bp, bp + Vector2(3.0, flap), Color(0.18, 0.14, 0.12, 0.8), 1.0)

		"praca_noite":
			# Halos quentes da Taverna e Lampião + brilho alquímico verde/rubi na janela da Botica do Marco!
			var glow := (sin(_time * 4.2) + 1.0) * 0.5
			draw_circle(Vector2(225.0, 156.0), 20.0 + glow * 3.0, Color(1.0, 0.78, 0.32, 0.14 + glow * 0.05))
			draw_circle(Vector2(66.0, 224.0), 24.0 + glow * 4.0, Color(1.0, 0.68, 0.25, 0.12 + glow * 0.05))
			var alch := (sin(_time * 3.1) + 1.0) * 0.5
			draw_circle(Vector2(562.0, 245.0), 16.0 + alch * 3.0, Color(0.25, 1.0, 0.62, 0.13).lerp(Color(1.0, 0.30, 0.65, 0.13), alch))
			for p: Dictionary in _particles:
				if str(p["kind"]) == "fountain":
					var u: float = p["t"]
					var vel: Vector2 = p["vel"]
					var fp := Vector2(382.0, 196.0) + vel * u * 0.75 + Vector2(0.0, 56.0 * u * u)
					draw_rect(Rect2(fp, Vector2(2.0, 2.0)), Color(0.72, 0.94, 1.0, 0.82 * (1.0 - u * 0.5)), true)
				else:
					var f_alpha := 0.35 + 0.55 * absf(sin(_time * 3.5 + float(p["t"]) * TAU))
					draw_rect(Rect2(p["pos"], Vector2(2.0, 2.0)), Color(1.0, 0.92, 0.42, f_alpha), true)
