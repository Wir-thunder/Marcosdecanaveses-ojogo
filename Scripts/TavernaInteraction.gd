extends Node2D

@export var modo_painel: String = "quadro"
@export var texto_badge: String = ""

var _badge_label: Label = null

func _ready() -> void:
	add_to_group("interactables")
	_criar_badge_visual()

func _criar_badge_visual() -> void:
	if texto_badge.is_empty():
		return
	_badge_label = Label.new()
	_badge_label.text = texto_badge
	_badge_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_badge_label.position = Vector2(-75, -26)
	_badge_label.custom_minimum_size = Vector2(150, 18)
	_badge_label.add_theme_font_size_override("font_size", 10)
	_badge_label.add_theme_color_override("font_color", Color(1.0, 0.92, 0.65, 0.95))
	_badge_label.add_theme_color_override("font_outline_color", Color(0.1, 0.08, 0.05, 0.9))
	_badge_label.add_theme_constant_override("outline_size", 3)
	_badge_label.z_index = 20
	add_child(_badge_label)

func _process(_delta: float) -> void:
	if _badge_label != null:
		_badge_label.position.y = -26.0 + sin(Time.get_ticks_msec() / 1000.0 * 3.0) * 2.0

func _obter_taverna() -> Node:
	var n: Node = get_parent()
	while n != null:
		if n.has_method("alternar_painel"):
			return n
		n = n.get_parent()
	return get_tree().current_scene

func obter_texto_interacao() -> String:
	var tav := _obter_taverna()
	if tav != null and tav.has_method("obter_texto_interacao_modo"):
		return str(tav.call("obter_texto_interacao_modo", modo_painel))
	if tav != null and tav.has_method("obter_texto_interacao"):
		return str(tav.call("obter_texto_interacao"))
	return "E  INTERAGIR"

func interagir(_jogador: Node2D = null) -> void:
	var tav := _obter_taverna()
	if tav != null and tav.has_method("abrir_painel_modo"):
		tav.call("abrir_painel_modo", modo_painel)
	elif tav != null and tav.has_method("alternar_painel"):
		tav.call("alternar_painel")
