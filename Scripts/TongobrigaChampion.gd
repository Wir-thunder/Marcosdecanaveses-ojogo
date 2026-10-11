class_name TongobrigaChampion extends CharacterBody2D

signal health_changed(champion: TongobrigaChampion)
signal knocked_out(champion: TongobrigaChampion)

var champion_name: String = ""
var archetype: String = ""
var special_name: String = ""
var max_health: int = 100
var health: int = 100
var strength: int = 10
var speed: float = 180.0
var defense: float = 0.0
var tunic_color: Color = Color.WHITE
var trim_color: Color = Color.GOLD
var facing: float = 1.0
var blocking: bool = false
var defeated: bool = false
var grounded: bool = true

var _vertical_speed: float = 0.0
var _attack_cooldown: float = 0.0
var _special_cooldown: float = 0.0
var _hit_flash: float = 0.0
var _attack_pose: float = 0.0
var _time: float = 0.0
var _floor_y: float = 280.0

func configure(data: Dictionary, floor_y: float) -> void:
	champion_name = str(data["name"])
	archetype = str(data["archetype"])
	special_name = str(data["special"])
	max_health = int(data["health"])
	health = max_health
	strength = int(data["strength"])
	speed = float(data["speed"])
	defense = float(data["defense"])
	tunic_color = data["color"]
	trim_color = data["trim"]
	_floor_y = floor_y

func update_fighter(
	delta: float,
	horizontal: float,
	jump_pressed: bool,
	is_blocking: bool,
	opponent: TongobrigaChampion
) -> void:
	if defeated:
		return
	_time += delta
	_attack_cooldown = maxf(_attack_cooldown - delta, 0.0)
	_special_cooldown = maxf(_special_cooldown - delta, 0.0)
	_hit_flash = maxf(_hit_flash - delta, 0.0)
	_attack_pose = maxf(_attack_pose - delta, 0.0)
	grounded = global_position.y >= _floor_y - 0.1
	blocking = is_blocking and grounded
	if opponent != null and absf(horizontal) < 0.01:
		facing = signf(opponent.global_position.x - global_position.x)
	if jump_pressed and grounded and not blocking:
		_vertical_speed = -360.0
		grounded = false
	velocity.x = horizontal * speed * (0.35 if blocking else 1.0)
	_vertical_speed += 900.0 * delta
	global_position.x = clampf(
		global_position.x + velocity.x * delta,
		40.0,
		600.0
	)
	global_position.y = minf(
		global_position.y + _vertical_speed * delta,
		_floor_y
	)
	if global_position.y >= _floor_y:
		_vertical_speed = 0.0
		grounded = true
	queue_redraw()

func can_use_special() -> bool:
	return _special_cooldown <= 0.0 and not defeated

func attack(target: TongobrigaChampion, kind: String) -> int:
	if target == null or defeated or blocking or _attack_cooldown > 0.0:
		return 0
	if kind == "special" and not can_use_special():
		return 0

	var distance := absf(target.global_position.x - global_position.x)
	var attack_range := 150.0 if kind == "special" else (98.0 if kind == "kick" else 76.0)
	if distance > attack_range or absf(target.global_position.y - global_position.y) > 65.0:
		return 0
	if kind == "special":
		_special_cooldown = 5.0
		_attack_cooldown = 0.65
	elif kind == "kick":
		_attack_cooldown = 0.55
	else:
		_attack_cooldown = 0.32
	_attack_pose = 0.2

	var multiplier := 1.7 if kind == "special" else (1.25 if kind == "kick" else 0.8)
	var damage := maxi(1, roundi(float(strength) * multiplier))
	return target.receive_hit(damage)

func receive_hit(damage: int) -> int:
	if defeated:
		return 0
	var mitigated := roundi(float(damage) * (1.0 - defense))
	if blocking:
		mitigated = maxi(1, roundi(float(mitigated) * 0.25))
	var actual := maxi(1, mitigated)
	health = maxi(0, health - actual)
	_hit_flash = 0.16
	if health == 0:
		defeated = true
		blocking = false
		knocked_out.emit(self)
	health_changed.emit(self)
	queue_redraw()
	return actual

func heal(amount: int) -> void:
	health = mini(max_health, health + amount)
	health_changed.emit(self)
	queue_redraw()

func _draw() -> void:
	var flip := facing
	var bob := sin(_time * 9.0) * 1.5 if grounded and absf(velocity.x) > 1.0 else 0.0
	var hurt_color := Color(1.0, 0.55, 0.45) if _hit_flash > 0.0 else tunic_color

	draw_rect(Rect2(-13.0 * flip, -17.0 + bob, 10.0, 17.0), Color(0.22, 0.2, 0.2))
	draw_rect(Rect2(3.0 * flip, -17.0 + bob, 10.0, 17.0), Color(0.22, 0.2, 0.2))
	draw_rect(Rect2(-16.0 * flip, -4.0 + bob, 15.0, 6.0), trim_color)
	draw_rect(Rect2(1.0 * flip, -4.0 + bob, 15.0, 6.0), trim_color)

	if blocking:
		draw_colored_polygon(PackedVector2Array([
			Vector2(-15.0 * flip, -53.0 + bob),
			Vector2(14.0 * flip, -52.0 + bob),
			Vector2(17.0 * flip, -20.0 + bob),
			Vector2(-13.0 * flip, -18.0 + bob),
		]), hurt_color)
		draw_line(
			Vector2(8.0 * flip, -45.0 + bob),
			Vector2(25.0 * flip, -63.0 + bob),
			trim_color,
			7.0
		)
	else:
		draw_colored_polygon(PackedVector2Array([
			Vector2(-15.0 * flip, -53.0 + bob),
			Vector2(14.0 * flip, -53.0 + bob),
			Vector2(18.0 * flip, -20.0 + bob),
			Vector2(-16.0 * flip, -20.0 + bob),
		]), hurt_color)
		if _attack_pose > 0.0:
			draw_line(
				Vector2(9.0 * flip, -43.0 + bob),
				Vector2(39.0 * flip, -38.0 + bob),
				trim_color,
				8.0
			)
		else:
			draw_line(
				Vector2(10.0 * flip, -45.0 + bob),
				Vector2(20.0 * flip, -27.0 + bob),
				trim_color,
				7.0
			)

	draw_rect(Rect2(-15.0 * flip, -25.0 + bob, 30.0, 5.0), trim_color)
	draw_circle(Vector2(0.0, -65.0 + bob), 12.0, Color(0.73, 0.49, 0.32))
	draw_colored_polygon(PackedVector2Array([
		Vector2(-13.0 * flip, -68.0 + bob),
		Vector2(-9.0 * flip, -78.0 + bob),
		Vector2(6.0 * flip, -78.0 + bob),
		Vector2(13.0 * flip, -69.0 + bob),
	]), trim_color)
	draw_circle(Vector2(5.0 * flip, -65.0 + bob), 1.5, Color(0.12, 0.1, 0.08))

	if _special_cooldown <= 0.0:
		draw_circle(Vector2(0.0, -88.0 + bob), 3.0, Color(1.0, 0.82, 0.35))
