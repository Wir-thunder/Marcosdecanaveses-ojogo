class_name TongobrigaChampion extends CharacterBody2D

signal health_changed(champion: TongobrigaChampion)
signal special_changed(champion: TongobrigaChampion)
signal knocked_out(champion: TongobrigaChampion)
signal attack_landed(attacker: TongobrigaChampion, target: TongobrigaChampion, kind: String, damage: int, blocked: bool)

const HIT_SPARK_SCRIPT: Script = preload("res://Scripts/TongobrigaHitSpark.gd")
const PROJECTILE_SCRIPT: Script = preload("res://Scripts/TongobrigaProjectile.gd")

static var _frames_cache: Dictionary = {}
static var debug_hitboxes: bool = false

var champion_name: String = ""
var archetype: String = ""
var special_name: String = ""
var class_id: String = "warrior"
var voice_id: String = "vox_viriato"
var hit_sfx: String = "soco"
var special_sfx: String = "especial_disparo"
var projectile_id: String = "falcata"

var max_health: int = 100
var health: int = 100
var strength: int = 10
var speed: float = 180.0
var defense: float = 0.0
var tunic_color: Color = Color.WHITE
var trim_color: Color = Color.GOLD
var facing: float = 1.0
var player_slot: int = 0
var blocking: bool = false
var crouching: bool = false
var defeated: bool = false
var grounded: bool = true

var special_gauge: float = 0.0
const MAX_SPECIAL: float = 100.0

var _vertical_speed: float = 0.0
var _attack_cooldown: float = 0.0
var _hit_flash: float = 0.0
var _hitstun_timer: float = 0.0
var _knockdown_timer: float = 0.0
var _attack_pose: float = 0.0
var _current_attack: String = "punch"
var _time: float = 0.0
var _floor_y: float = 304.0
var _was_grounded: bool = true
var _anim_sprite: AnimatedSprite2D

# Frame Data State Machine (Startup -> Active -> Recovery)
var _startup_timer: float = 0.0
var _active_timer: float = 0.0
var _recovery_timer: float = 0.0
var _attack_connected: bool = false
var _active_target: TongobrigaChampion = null

var _pushback_vel: float = 0.0
var _spark_timer: float = 0.0
var _spark_pos: Vector2 = Vector2.ZERO
var _spark_is_block: bool = false
var _hitstop_timer: float = 0.0

const BASE_SCALE: Vector2 = Vector2(0.82, 0.82)

func _init() -> void:
	_anim_sprite = AnimatedSprite2D.new()
	_anim_sprite.name = "Anim"
	_anim_sprite.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	_anim_sprite.scale = BASE_SCALE
	_anim_sprite.offset = Vector2(0.0, -64.0)
	add_child(_anim_sprite)

func configure(data: Dictionary, floor_y: float) -> void:
	champion_name = str(data["name"])
	archetype = str(data["archetype"])
	special_name = str(data["special"])
	max_health = int(data["health"])
	health = max_health
	special_gauge = 0.0
	strength = int(data["strength"])
	speed = float(data["speed"])
	defense = float(data["defense"])
	tunic_color = data["color"]
	trim_color = data["trim"]
	_floor_y = floor_y

	class_id = str(data.get("class_id", _determinar_classe()))
	voice_id = str(data.get("voice_id", "vox_" + class_id))
	hit_sfx = str(data.get("hit_sfx", _padrao_hit_sfx(class_id)))
	special_sfx = str(data.get("special_sfx", _padrao_special_sfx(class_id)))
	projectile_id = str(data.get("projectile", _obter_tipo_projetil()))

	_anim_sprite.sprite_frames = _obter_sprite_frames(class_id)
	_anim_sprite.play("idle")

func _determinar_classe() -> String:
	match archetype:
		"Guerreiro Lusitano", "Gladiador", "Campeão", "Lutador":
			return "warrior"
		"Caçadora Castreja", "Caçadora":
			return "archer"
		"Druida do Castro", "Mago":
			return "mage"
		"Sacerdotisa Celta", "Guardião", "Curandeira":
			return "healer"
		_:
			return "warrior"

static func _padrao_hit_sfx(cid: String) -> String:
	match cid:
		"warrior", "archer", "breno", "decimo", "trebaruna", "klaudia":
			return "corte_lamina"
		"healer", "bracaro":
			return "impacto_macico_pedra"
		_:
			return "soco"

static func _padrao_special_sfx(cid: String) -> String:
	match cid:
		"breno":
			return "carnyx_trombeta_gaulesa"
		"bracaro", "healer":
			return "impacto_macico_pedra"
		"klaudia":
			return "trovao_eslavo_perun"
		"marco":
			return "frasco_alquimico_explosao"
		_:
			return "especial_disparo"

static func _load_tex_safe(tex_path: String) -> Texture2D:
	if ResourceLoader.exists(tex_path):
		var res := load(tex_path)
		if res is Texture2D:
			return res as Texture2D
	if FileAccess.file_exists(tex_path):
		var img := Image.load_from_file(ProjectSettings.globalize_path(tex_path))
		if img != null:
			return ImageTexture.create_from_image(img)
	return null

static func _obter_sprite_frames(classe: String) -> SpriteFrames:
	if _frames_cache.has(classe):
		return _frames_cache[classe]

	var frames := SpriteFrames.new()
	frames.remove_animation(&"default")
	var basePath: String = "res://Assets/Characters/Tongobriga/" + classe + "/"
	var estados: Array[String] = ["idle", "move", "jump", "punch", "kick", "special", "block", "damage", "defeated"]

	for est: String in estados:
		frames.add_animation(est)
		frames.set_animation_loop(est, est == "idle" or est == "move")
		var vel: float = 8.0
		if est == "punch" or est == "kick":
			vel = 12.0
		elif est == "special":
			vel = 9.0
		frames.set_animation_speed(est, vel)

		for idx: int in range(1, 6):
			var tex_path: String = basePath + "%s_%d.png" % [est, idx]
			var tex := _load_tex_safe(tex_path)
			if tex != null:
				frames.add_frame(est, tex)

	_frames_cache[classe] = frames
	return frames

# ==============================================================================
# CAIXAS DE COLISÃO REAIS (PUSHBOX, HURTBOXES E HITBOXES — PADRÃO ARCADE 2D)
# ==============================================================================

func get_pushbox_rect() -> Rect2:
	var h := 46.0 if crouching else (70.0 if class_id == "bracaro" else 66.0)
	var w := 40.0 if class_id == "bracaro" else (36.0 if class_id in ["breno", "decimo"] else 34.0)
	return Rect2(global_position.x - w * 0.5, global_position.y - h, w, h)

func get_hurtboxes() -> Array[Rect2]:
	if defeated or _knockdown_timer > 0.0:
		return []
	var boxes: Array[Rect2] = []
	var body_w := 38.0 if class_id == "bracaro" else (30.0 if class_id in ["archer", "trebaruna", "klaudia"] else 33.0)
	var stand_h := 92.0 if class_id == "bracaro" else 86.0

	if crouching:
		# Agachado: tronco baixo + pernas (esquiva projéteis altos!)
		boxes.append(Rect2(global_position.x - (body_w * 0.55), global_position.y - 54.0, body_w * 1.1, 28.0))
		boxes.append(Rect2(global_position.x - (body_w * 0.62), global_position.y - 26.0, body_w * 1.24, 26.0))
	elif not grounded:
		# No ar: corpo recolhido (salta sobre rasteiras!)
		boxes.append(Rect2(global_position.x - (body_w * 0.54), global_position.y - 84.0, body_w * 1.08, 56.0))
	else:
		# Em pé: Cabeça/Peito + Cintura/Pernas
		var half_h := stand_h * 0.5
		boxes.append(Rect2(global_position.x - (body_w * 0.5), global_position.y - stand_h, body_w, half_h))
		boxes.append(Rect2(global_position.x - (body_w * 0.58), global_position.y - half_h, body_w * 1.16, half_h))

	# Hurtbox estendida do membro atacante durante frames ativos (permite whiff punish / counter!)
	if is_in_active_frames() and _current_attack != "special" and _current_attack != "throw":
		var hb := get_attack_hitbox_for(_current_attack)
		var limb_hurt := hb.grow(-5.0)
		if limb_hurt.size.x > 8.0 and limb_hurt.size.y > 8.0:
			boxes.append(limb_hurt)
	return boxes

func _obter_alcance_arma() -> float:
	match class_id:
		"decimo":
			return 18.0 # Lança romana longa
		"breno":
			return 12.0 # Espadão gaulês
		"klaudia":
			return 11.0 # Sabre eslavo curvo Szabla
		"warrior", "mage":
			return 10.0 # Falcata / Cajado
		"bracaro", "trebaruna", "marco":
			return 8.0
		"healer", "archer":
			return 6.0
		_:
			return 8.0

func get_attack_hitbox_for(kind: String) -> Rect2:
	var reach_bonus := _obter_alcance_arma()
	var w: float = 48.0
	var h: float = 24.0
	var y_top: float = -66.0
	var x_start: float = 10.0

	match kind:
		"punch":
			w = 50.0 + reach_bonus
			h = 22.0
			y_top = -68.0
			x_start = 10.0
		"kick":
			w = 64.0 + reach_bonus * 0.65
			h = 26.0
			y_top = -58.0
			x_start = 12.0
		"low_kick":
			w = 64.0 + reach_bonus * 0.55
			h = 20.0
			y_top = -22.0
			x_start = 10.0
		"air_punch", "air_kick":
			w = 54.0 + reach_bonus * 0.60
			h = 34.0
			y_top = -52.0
			x_start = 6.0
		"throw":
			w = 46.0 if class_id == "bracaro" else 38.0
			h = 46.0
			y_top = -68.0
			x_start = 4.0
		_:
			w = 50.0
			h = 24.0
			y_top = -64.0

	var gx: float = global_position.x + x_start if facing >= 0.0 else global_position.x - x_start - w
	return Rect2(gx, global_position.y + y_top, w, h)

func is_in_startup_frames() -> bool:
	return _startup_timer > 0.0

func is_in_active_frames() -> bool:
	return _startup_timer <= 0.0 and _active_timer > 0.0

func is_in_recovery_frames() -> bool:
	return _startup_timer <= 0.0 and _active_timer <= 0.0 and _recovery_timer > 0.0

func is_busy_attacking() -> bool:
	return _startup_timer > 0.0 or _active_timer > 0.0 or _recovery_timer > 0.0

func get_frame_state_label() -> String:
	if defeated:
		return "K.O."
	if _knockdown_timer > 0.0:
		return "CAÍDO (INVULN)"
	if _hitstun_timer > 0.0:
		return "BLOCKSTUN" if blocking else "HITSTUN"
	if is_in_startup_frames():
		return "STARTUP (%s)" % _current_attack.to_upper()
	if is_in_active_frames():
		return "ACTIVE HITBOX (%s)" % _current_attack.to_upper()
	if is_in_recovery_frames():
		return "RECOVERY (%s)" % _current_attack.to_upper()
	if blocking:
		return "DEFESA BAIXA" if crouching else "DEFESA ALTA"
	if crouching:
		return "AGACHADO"
	if not grounded:
		return "SALTO"
	if absf(velocity.x) > 6.0:
		return "ANDANDO"
	return "NEUTRO (IDLE)"

# ==============================================================================
# ATUALIZAÇÃO FÍSICA E DE COMBATE POR FRAME
# ==============================================================================

func update_fighter(
	delta: float,
	horizontal: float,
	jump_pressed: bool,
	is_blocking: bool,
	opponent: TongobrigaChampion,
	locked_in_place: bool = false,
	is_crouching: bool = false
) -> void:
	if _hitstop_timer > 0.0:
		_hitstop_timer = maxf(_hitstop_timer - delta, 0.0)
		queue_redraw()
		return

	if defeated:
		_tocar_animacao("defeated")
		_anim_sprite.scale = BASE_SCALE
		queue_redraw()
		return

	_time += delta
	_attack_cooldown = maxf(_attack_cooldown - delta, 0.0)
	_hit_flash = maxf(_hit_flash - delta, 0.0)
	_hitstun_timer = maxf(_hitstun_timer - delta, 0.0)
	_knockdown_timer = maxf(_knockdown_timer - delta, 0.0)
	_attack_pose = maxf(_attack_pose - delta, 0.0)
	_spark_timer = maxf(_spark_timer - delta, 0.0)

	# Avançar fases de Frame Data (Startup -> Active -> Recovery)
	_processar_fases_ataque(delta, opponent)

	# Carga passiva sutil do medidor de especial
	var antes_special := special_gauge
	special_gauge = minf(special_gauge + 3.0 * delta, MAX_SPECIAL)
	if antes_special < MAX_SPECIAL and special_gauge >= MAX_SPECIAL:
		AudioManager.tocar_sfx_combate("especial_pronto", player_slot, -2.0, 0.03)
	special_changed.emit(self)

	grounded = global_position.y >= _floor_y - 0.1
	var em_controle := not locked_in_place and _hitstun_timer <= 0.0 and _knockdown_timer <= 0.0 and not is_busy_attacking()

	crouching = is_crouching and grounded and not locked_in_place and _knockdown_timer <= 0.0 and not is_busy_attacking()
	blocking = is_blocking and grounded and not locked_in_place and _knockdown_timer <= 0.0 and not is_busy_attacking()

	# Virar automaticamente para o oponente quando no chão e fora de golpe
	if opponent != null and grounded and not is_busy_attacking() and not locked_in_place:
		var dir_op := signf(opponent.global_position.x - global_position.x)
		if dir_op != 0.0:
			facing = dir_op

	if not em_controle:
		horizontal = 0.0
		jump_pressed = false

	if crouching:
		horizontal = 0.0

	if jump_pressed and grounded and not blocking and em_controle:
		_vertical_speed = -385.0
		AudioManager.tocar_sfx_combate("lutador_pulo", player_slot, -4.0, 0.06)
		grounded = false
		_was_grounded = false
		crouching = false

	var move_x := horizontal * speed * (0.25 if blocking else 1.0)
	if absf(_pushback_vel) > 1.0:
		move_x += _pushback_vel
		_pushback_vel = move_toward(_pushback_vel, 0.0, 820.0 * delta)

	velocity.x = move_x
	_vertical_speed += 940.0 * delta
	global_position.x = clampf(global_position.x + velocity.x * delta, 45.0, 595.0)
	global_position.y = minf(global_position.y + _vertical_speed * delta, _floor_y)

	if global_position.y >= _floor_y:
		if not _was_grounded and _vertical_speed > 80.0:
			AudioManager.tocar_sfx_combate("aterragem_arena", player_slot, -5.0, 0.08)
		_vertical_speed = 0.0
		grounded = true
		_was_grounded = true
	else:
		_was_grounded = false

	# Pushbox física corpo-a-corpo (impede atravessar o oponente no chão, permite Cross-Up aéreo!)
	if opponent != null and not opponent.defeated:
		_resolver_colisao_pushbox(opponent)

	# Atualizar pose e animação visual mantendo escala 1:1 sólida (sem achatamento de pixel art)
	_anim_sprite.scale = BASE_SCALE
	if _knockdown_timer > 0.0:
		_tocar_animacao("defeated")
		_anim_sprite.position.y = 10.0
	elif _hit_flash > 0.0:
		_tocar_animacao("damage")
		_anim_sprite.position.y = 0.0
	elif _attack_pose > 0.0 or is_busy_attacking():
		var anim_atk := "kick" if _current_attack in ["kick", "low_kick", "air_kick"] else ("special" if _current_attack == "special" else "punch")
		_tocar_animacao(anim_atk)
		_anim_sprite.position.y = 6.0 if _current_attack == "low_kick" else 0.0
	elif blocking:
		_tocar_animacao("block")
		_anim_sprite.position.y = 6.0 if crouching else 0.0
	elif crouching:
		_tocar_animacao("idle")
		_anim_sprite.position.y = 6.0
	elif not grounded:
		_tocar_animacao("jump")
		_anim_sprite.position.y = 0.0
	elif absf(velocity.x) > 6.0:
		_tocar_animacao("move")
		_anim_sprite.position.y = 0.0
	else:
		_tocar_animacao("idle")
		_anim_sprite.position.y = 0.0

	_anim_sprite.flip_h = (facing < 0.0)
	if _hit_flash > 0.16:
		_anim_sprite.modulate = Color(3.2, 3.2, 3.2)
	elif _hit_flash > 0.0:
		_anim_sprite.modulate = Color(2.2, 0.55, 0.55)
	else:
		_anim_sprite.modulate = Color.WHITE

	queue_redraw()

func _resolver_colisao_pushbox(opponent: TongobrigaChampion) -> void:
	var my_box := get_pushbox_rect()
	var op_box := opponent.get_pushbox_rect()
	if not my_box.intersects(op_box):
		return
	var inter := my_box.intersection(op_box)
	if inter.size.x <= 0.0:
		return
	var dir := signf(global_position.x - opponent.global_position.x)
	if dir == 0.0:
		dir = -facing if facing != 0.0 else 1.0
	var push := inter.size.x * 0.5 + 0.5
	global_position.x = clampf(global_position.x + dir * push, 45.0, 595.0)
	opponent.global_position.x = clampf(opponent.global_position.x - dir * push, 45.0, 595.0)

func _processar_fases_ataque(delta: float, opponent: TongobrigaChampion) -> void:
	var alvo := opponent if opponent != null else _active_target
	if _startup_timer > 0.0:
		_startup_timer = maxf(_startup_timer - delta, 0.0)
		if _startup_timer <= 0.0 and _current_attack == "special" and alvo != null:
			_spawn_special_projectile(alvo)

	elif _active_timer > 0.0:
		if not _attack_connected and _current_attack != "special" and alvo != null and not alvo.defeated:
			if _checar_intersecao_hitbox(alvo):
				_attack_connected = true
				_aplicar_acerto_ataque(alvo, _current_attack)

		_active_timer = maxf(_active_timer - delta, 0.0)
		if _active_timer <= 0.0 and not _attack_connected and _current_attack != "special":
			AudioManager.tocar_sfx_combate("golpe_ar", player_slot, -4.5, 0.08)

	elif _recovery_timer > 0.0:
		_recovery_timer = maxf(_recovery_timer - delta, 0.0)

func _checar_intersecao_hitbox(alvo: TongobrigaChampion) -> bool:
	var atk_box := get_attack_hitbox_for(_current_attack)
	if _current_attack == "throw":
		# Agarrão conecta contra a Pushbox no chão!
		return alvo.grounded and alvo._knockdown_timer <= 0.0 and atk_box.intersects(alvo.get_pushbox_rect().grow(6.0))
	for hurtbox: Rect2 in alvo.get_hurtboxes():
		if atk_box.intersects(hurtbox):
			return true
	return false

func _aplicar_acerto_ataque(alvo: TongobrigaChampion, kind: String) -> void:
	var multiplier := 0.90
	match kind:
		"kick":
			multiplier = 1.35
		"low_kick":
			multiplier = 1.15
		"air_kick", "air_punch":
			multiplier = 1.10
		"throw":
			multiplier = 1.45
		_:
			multiplier = 0.90

	var is_counter := alvo.is_in_startup_frames()
	if is_counter:
		multiplier *= 1.20

	var damage := maxi(1, roundi(float(strength) * multiplier))
	var stop_dur := 0.08 if kind in ["kick", "low_kick", "throw"] else 0.055
	apply_hitstop(stop_dur)
	alvo.apply_hitstop(stop_dur)

	var was_blocked := alvo.will_block_attack(kind)
	var real_dmg := alvo.receive_hit(damage, self, kind)
	attack_landed.emit(self, alvo, kind, real_dmg, was_blocked)

func will_block_attack(kind: String) -> bool:
	if not blocking or defeated or _knockdown_timer > 0.0:
		return false
	if kind == "throw":
		return false # Agarrão quebra bloqueio!
	if kind == "low_kick" and not crouching:
		return false # Rasteira baixa exige bloqueio agachado!
	if kind in ["air_punch", "air_kick"] and crouching:
		return false # Golpe aéreo Overhead quebra bloqueio agachado!
	return true

func _tocar_animacao(nome: String) -> void:
	if _anim_sprite == null or _anim_sprite.sprite_frames == null:
		return
	if not _anim_sprite.sprite_frames.has_animation(nome):
		return
	if _anim_sprite.animation != nome:
		_anim_sprite.play(nome)

func _obter_tipo_projetil() -> String:
	match class_id:
		"warrior":
			return "falcata"
		"archer":
			return "flecha"
		"mage":
			return "fogo"
		"healer":
			return "escudo"
		"breno":
			return "carnyx"
		"bracaro":
			return "sismo"
		"decimo":
			return "pilum"
		"trebaruna":
			return "foices"
		"klaudia":
			return "perun"
		"marco":
			return "fogogrego"
		_:
			return "falcata"

func can_use_special() -> bool:
	return special_gauge >= MAX_SPECIAL and not defeated

func apply_hitstop(duration: float = 0.06) -> void:
	_hitstop_timer = maxf(_hitstop_timer, duration)

func disparar_especial(target: TongobrigaChampion) -> int:
	_current_attack = "special"
	_active_target = target
	_attack_connected = true
	special_gauge = 0.0
	special_changed.emit(self)
	_startup_timer = 0.10
	_active_timer = 0.24
	_recovery_timer = 0.24
	_attack_cooldown = 0.65
	_attack_pose = 0.48
	_tocar_animacao("special")
	apply_hitstop(0.11)
	if target != null:
		target.apply_hitstop(0.11)
	AudioManager.tocar_sfx("super_flash_freeze", 0.0)
	AudioManager.tocar_voz(voice_id, 2.0, 1.0, true)
	AudioManager.tocar_sfx_combate(special_sfx, player_slot, -1.0, 0.04)
	return maxi(1, roundi(float(strength) * 2.2))

func _spawn_special_projectile(target: TongobrigaChampion) -> void:
	var dano := maxi(1, roundi(float(strength) * 2.2))
	var tipo_proj := projectile_id if projectile_id != "" else _obter_tipo_projetil()
	var spawn_pos := global_position + Vector2(facing * (34.0 if tipo_proj != "escudo" else 0.0), -48.0)

	var proj_node := Node2D.new()
	proj_node.set_script(PROJECTILE_SCRIPT)
	var proj := proj_node as TongobrigaProjectile
	if get_parent() != null:
		get_parent().add_child(proj)
		proj.setup(self, target, tipo_proj, dano, spawn_pos, facing)

func attack(target: TongobrigaChampion, kind: String) -> int:
	if target == null or defeated or blocking or _hitstun_timer > 0.0 or _knockdown_timer > 0.0 or is_busy_attacking() or _attack_cooldown > 0.0:
		return 0
	if kind == "special":
		if not can_use_special():
			return 0
		return disparar_especial(target)

	var resolved_kind := kind
	if not grounded and kind in ["punch", "kick"]:
		resolved_kind = "air_" + kind
	elif crouching and kind == "kick":
		resolved_kind = "low_kick"

	_current_attack = resolved_kind
	_active_target = target
	_attack_connected = false

	match resolved_kind:
		"punch":
			_startup_timer = 0.05
			_active_timer = 0.09
			_recovery_timer = 0.11
			_attack_cooldown = 0.25
			_attack_pose = 0.22
			special_gauge = minf(special_gauge + 6.0, MAX_SPECIAL)
		"kick":
			_startup_timer = 0.09
			_active_timer = 0.11
			_recovery_timer = 0.17
			_attack_cooldown = 0.38
			_attack_pose = 0.30
			special_gauge = minf(special_gauge + 10.0, MAX_SPECIAL)
		"low_kick":
			_startup_timer = 0.07
			_active_timer = 0.11
			_recovery_timer = 0.19
			_attack_cooldown = 0.40
			_attack_pose = 0.30
			special_gauge = minf(special_gauge + 9.0, MAX_SPECIAL)
		"air_punch", "air_kick":
			_startup_timer = 0.06
			_active_timer = 0.16
			_recovery_timer = 0.08
			_attack_cooldown = 0.30
			_attack_pose = 0.26
			special_gauge = minf(special_gauge + 8.0, MAX_SPECIAL)
		"throw":
			_startup_timer = 0.05
			_active_timer = 0.07
			_recovery_timer = 0.22
			_attack_cooldown = 0.36
			_attack_pose = 0.28
			special_gauge = minf(special_gauge + 8.0, MAX_SPECIAL)

	special_changed.emit(self)
	return 1

func receive_hit(damage: int, attacker: TongobrigaChampion, kind: String) -> int:
	if defeated or _knockdown_timer > 0.0:
		return 0

	# Interrompe startup de ataque se tomou Counter Hit!
	var took_counter := is_in_startup_frames()
	if not will_block_attack(kind):
		_startup_timer = 0.0
		_active_timer = 0.0
		_recovery_timer = 0.0

	var blocked_hit := will_block_attack(kind)
	var mitigated := roundi(float(damage) * (1.0 - defense))

	if blocked_hit:
		mitigated = maxi(1, roundi(float(mitigated) * 0.20))
		_spark_is_block = true
		AudioManager.tocar_sfx_combate("bloqueio", player_slot, -1.5, 0.06)
		_hit_flash = 0.12
		_hitstun_timer = 0.16
		apply_hitstop(0.05)
	else:
		_spark_is_block = false
		_hit_flash = 0.28 if kind != "special" else 0.42
		_hitstun_timer = 0.26 if kind in ["kick", "special"] else 0.18
		if kind in ["low_kick", "throw"]:
			_knockdown_timer = 0.48
		apply_hitstop(0.08 if kind != "special" else 0.12)
		if took_counter:
			AudioManager.tocar_sfx_combate("counter_hit_bell", player_slot, 0.5, 0.04)
		if kind == "special":
			AudioManager.tocar_sfx_combate("especial_hit", player_slot, 0.0, 0.05)
		elif kind == "throw":
			AudioManager.tocar_sfx_combate("agarrao_trava", player_slot, 0.0, 0.05)
			AudioManager.tocar_sfx_combate("rasteira_poeira", player_slot, -2.0, 0.06)
		elif kind == "low_kick":
			AudioManager.tocar_sfx_combate("rasteira_poeira", player_slot, 0.0, 0.06)
		elif kind == "kick":
			AudioManager.tocar_sfx_combate("chute", player_slot, 0.0, 0.06)
		else:
			var sfx_atk := attacker.hit_sfx if attacker != null else "soco"
			var atk_slot := attacker.player_slot if attacker != null else player_slot
			AudioManager.tocar_sfx_combate(sfx_atk, atk_slot, 0.0, 0.06)

	var actual := maxi(1, mitigated)
	health = maxi(0, health - actual)
	_mostrar_numero_dano(actual, blocked_hit, kind, took_counter)

	if get_parent() != null:
		var spark := Node2D.new()
		spark.set_script(HIT_SPARK_SCRIPT)
		var hs := spark as TongobrigaHitSpark
		get_parent().add_child(hs)
		var spark_tipo := "block" if blocked_hit else ("special" if kind == "special" else "hit")
		var y_spark := -22.0 if kind == "low_kick" else -52.0
		hs.setup(global_position + Vector2(0.0, y_spark), spark_tipo)

	special_gauge = minf(special_gauge + (12.0 if not blocked_hit else 6.0), MAX_SPECIAL)
	special_changed.emit(self)

	var dir := 1.0
	if attacker != null:
		dir = signf(global_position.x - attacker.global_position.x)
		if dir == 0.0:
			dir = -facing
	var force := 260.0 if kind in ["special", "throw"] else (175.0 if kind in ["kick", "low_kick"] else 110.0)
	if blocked_hit:
		force *= 0.65
	_pushback_vel = dir * force

	_spark_timer = 0.14
	_spark_pos = Vector2(0.0, -52.0)

	if health == 0:
		defeated = true
		AudioManager.tocar_sfx_combate("ko_impact_boom", player_slot, 1.0, 0.0)
		AudioManager.tocar_sfx_combate("lutador_ko", player_slot, 0.5, 0.0)
		blocking = false
		_tocar_animacao("defeated")
		knocked_out.emit(self)

	health_changed.emit(self)
	queue_redraw()
	return actual

func heal(amount: int) -> void:
	health = mini(max_health, health + amount)
	if health > 0 and defeated:
		defeated = false
		_knockdown_timer = 0.0
		_hitstun_timer = 0.0
		_tocar_animacao("idle")
	health_changed.emit(self)
	queue_redraw()

func reset_for_new_round(initial_pos: Vector2, initial_facing: float) -> void:
	global_position = initial_pos
	facing = initial_facing
	health = max_health
	defeated = false
	crouching = false
	blocking = false
	grounded = true
	_vertical_speed = 0.0
	_attack_cooldown = 0.0
	_hit_flash = 0.0
	_hitstun_timer = 0.0
	_knockdown_timer = 0.0
	_startup_timer = 0.0
	_active_timer = 0.0
	_recovery_timer = 0.0
	_attack_connected = false
	_active_target = null
	_pushback_vel = 0.0
	_spark_timer = 0.0
	_hitstop_timer = 0.0
	if _anim_sprite != null:
		_anim_sprite.position = Vector2.ZERO
		_anim_sprite.scale = BASE_SCALE
	_tocar_animacao("idle")
	health_changed.emit(self)
	queue_redraw()

func _draw() -> void:
	# Sombra nos pés
	_desenhar_sombra_elipse(Vector2.ZERO, 18.0, 6.0, Color(0, 0, 0, 0.45))

	# Aura dourada / mística de Especial Cheio
	if special_gauge >= MAX_SPECIAL and not defeated:
		var pulse := (sin(_time * 10.0) + 1.0) * 0.5
		var aura_col := Color(1.0, 0.85, 0.2, 0.25 + pulse * 0.25)
		draw_circle(Vector2(0.0, -55.0), 32.0 + pulse * 6.0, aura_col)
		draw_circle(Vector2(0.0, -96.0), 4.0, Color(1.0, 0.9, 0.4, 0.9))

	# Faíscas de Impacto / Bloqueio
	if _spark_timer > 0.0:
		var spark_scale := _spark_timer / 0.14
		if _spark_is_block:
			draw_arc(_spark_pos, 24.0 * spark_scale, -PI * 0.4, PI * 0.4, 8, Color(0.3, 0.8, 1.0, 0.9), 3.0)
		else:
			var r := 18.0 * spark_scale
			var spark_color := Color(1.0, 0.9, 0.2, 0.95)
			draw_line(_spark_pos - Vector2(r, 0), _spark_pos + Vector2(r, 0), spark_color, 2.5)
			draw_line(_spark_pos - Vector2(0, r), _spark_pos + Vector2(0, r), spark_color, 2.5)
			draw_line(_spark_pos - Vector2(r * 0.7, r * 0.7), _spark_pos + Vector2(r * 0.7, r * 0.7), Color(1.0, 0.3, 0.1, 0.9), 2.0)
			draw_line(_spark_pos - Vector2(-r * 0.7, r * 0.7), _spark_pos + Vector2(r * 0.7, -r * 0.7), Color(1.0, 0.3, 0.1, 0.9), 2.0)

	# ==========================================================================
	# MODO VISUALIZADOR DE CAIXAS DE COLISÃO [F2] (STREET FIGHTER TRAINING BOXES)
	# ==========================================================================
	if debug_hitboxes:
		# 1. Hurtboxes (Azul = vulnerável | Verde = bloqueando | Laranja = hitstun)
		var hurt_fill := Color(0.12, 0.65, 1.0, 0.22)
		var hurt_border := Color(0.25, 0.82, 1.0, 0.92)
		if blocking:
			hurt_fill = Color(0.15, 0.92, 0.35, 0.26)
			hurt_border = Color(0.25, 1.0, 0.45, 0.95)
		elif _hitstun_timer > 0.0:
			hurt_fill = Color(1.0, 0.55, 0.1, 0.28)
			hurt_border = Color(1.0, 0.7, 0.2, 0.95)

		for hb_global: Rect2 in get_hurtboxes():
			var hb_local := Rect2(hb_global.position - global_position, hb_global.size)
			draw_rect(hb_local, hurt_fill, true)
			draw_rect(hb_local, hurt_border, false, 1.2)

		# 2. Pushbox Física (Amarelo)
		var pb_global := get_pushbox_rect()
		var pb_local := Rect2(pb_global.position - global_position, pb_global.size)
		draw_rect(pb_local, Color(1.0, 0.88, 0.12, 0.15), true)
		draw_rect(pb_local, Color(1.0, 0.92, 0.25, 0.88), false, 1.2)

		# 3. Preview de Startup (Branco translúcido) ou Hitbox Ativa (Vermelho/Roxo)
		if is_in_startup_frames() and _current_attack != "special":
			var st_global := get_attack_hitbox_for(_current_attack)
			var st_local := Rect2(st_global.position - global_position, st_global.size)
			draw_rect(st_local, Color(1.0, 1.0, 1.0, 0.12), true)
			draw_rect(st_local, Color(1.0, 1.0, 1.0, 0.65), false, 1.0)
		elif is_in_active_frames() and _current_attack != "special":
			var ak_global := get_attack_hitbox_for(_current_attack)
			var ak_local := Rect2(ak_global.position - global_position, ak_global.size)
			var is_throw := (_current_attack == "throw")
			var atk_fill := Color(0.78, 0.2, 1.0, 0.38) if is_throw else Color(1.0, 0.1, 0.12, 0.40)
			var atk_border := Color(0.92, 0.45, 1.0, 1.0) if is_throw else Color(1.0, 0.28, 0.25, 1.0)
			draw_rect(ak_local, atk_fill, true)
			draw_rect(ak_local, atk_border, false, 1.8)

		# 4. Pivô exato nos pés (Cruz Ciano/Branca)
		draw_line(Vector2(-6, 0), Vector2(6, 0), Color.WHITE, 1.5)
		draw_line(Vector2(0, -6), Vector2(0, 6), Color.WHITE, 1.5)

func _desenhar_sombra_elipse(center: Vector2, rx: float, ry: float, color: Color) -> void:
	var points: Array[Vector2] = []
	for i in range(16):
		var angle := float(i) * TAU / 16.0
		points.append(center + Vector2(cos(angle) * rx, sin(angle) * ry))
	draw_colored_polygon(points, color)

func _mostrar_numero_dano(valor: int, bloq: bool, golpe: String, is_counter: bool = false) -> void:
	var lbl := Label.new()
	lbl.z_index = 30
	lbl.add_theme_font_size_override("font_size", 12 if golpe != "special" else 15)
	lbl.add_theme_color_override("font_shadow_color", Color.BLACK)
	lbl.add_theme_constant_override("shadow_offset_x", 1)
	lbl.add_theme_constant_override("shadow_offset_y", 1)
	if bloq:
		lbl.text = "🛡️ -%d" % valor
		lbl.add_theme_color_override("font_color", Color(0.4, 0.85, 1.0))
	elif golpe == "special":
		lbl.text = "💥 SUPER -%d!" % valor
		lbl.add_theme_color_override("font_color", Color(1.0, 0.3, 0.1))
	elif golpe == "throw":
		lbl.text = "🤼 AGARRÃO -%d!" % valor
		lbl.add_theme_color_override("font_color", Color(0.9, 0.45, 1.0))
	elif is_counter:
		lbl.text = "⚡ COUNTER -%d!" % valor
		lbl.add_theme_color_override("font_color", Color(1.0, 0.55, 0.15))
	elif golpe == "low_kick":
		lbl.text = "🦵 RASTEIRA -%d" % valor
		lbl.add_theme_color_override("font_color", Color(1.0, 0.82, 0.25))
	else:
		lbl.text = "-%d" % valor
		lbl.add_theme_color_override("font_color", Color(1.0, 0.9, 0.2))
	lbl.position = Vector2(-24.0, -90.0)
	add_child(lbl)
	var tw := create_tween().set_parallel(true)
	tw.tween_property(lbl, "position:y", lbl.position.y - 28.0, 0.55).set_ease(Tween.EASE_OUT)
	tw.tween_property(lbl, "modulate:a", 0.0, 0.55).set_ease(Tween.EASE_IN)
	tw.finished.connect(lbl.queue_free)
