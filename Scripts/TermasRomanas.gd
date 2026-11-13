extends "res://Scripts/ExplorationScene.gd"

var _painel_termas: PanelContainer = null
var _btn_termas: Button = null
var _fonte_colhida_dia: int = -1

func _ready() -> void:
	super._ready()
	_criar_botao_termas_hud()

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_T:
			_alternar_painel_termas()

func _criar_botao_termas_hud() -> void:
	var hud := get_node_or_null("Interface") as CanvasLayer
	if hud == null:
		return
	_btn_termas = Button.new()
	_btn_termas.name = "BotaoTermas"
	_btn_termas.focus_mode = Control.FOCUS_NONE
	_btn_termas.position = Vector2(468, 34)
	_btn_termas.custom_minimum_size = Vector2(164, 22)
	_btn_termas.add_theme_font_size_override("font_size", 9)
	_btn_termas.text = "♨️ BANHOS TERMAIS [T]"
	_btn_termas.modulate = Color(0.75, 0.96, 0.88)
	_btn_termas.pressed.connect(_alternar_painel_termas)
	hud.add_child(_btn_termas)

func _alternar_painel_termas() -> void:
	if _painel_termas != null and is_instance_valid(_painel_termas):
		_painel_termas.queue_free()
		_painel_termas = null
		return
	_abrir_painel_termas()

func _abrir_painel_termas() -> void:
	var hud := get_node_or_null("Interface") as CanvasLayer
	if hud == null:
		return
	if _painel_termas != null and is_instance_valid(_painel_termas):
		_painel_termas.queue_free()

	_painel_termas = PanelContainer.new()
	_painel_termas.position = Vector2(95, 76)
	_painel_termas.custom_minimum_size = Vector2(450, 175)
	var st := StyleBoxFlat.new()
	st.bg_color = Color(0.08, 0.11, 0.11, 0.96)
	st.border_color = Color(0.50, 0.88, 0.78, 1.0)
	st.set_border_width_all(2)
	st.set_corner_radius_all(6)
	st.content_margin_left = 10
	st.content_margin_right = 10
	st.content_margin_top = 8
	st.content_margin_bottom = 8
	_painel_termas.add_theme_stylebox_override("panel", st)
	hud.add_child(_painel_termas)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 8)
	_painel_termas.add_child(vbox)

	var header := HBoxContainer.new()
	vbox.add_child(header)
	var titulo := Label.new()
	titulo.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	titulo.add_theme_font_size_override("font_size", 12)
	titulo.add_theme_color_override("font_color", Color(0.75, 0.96, 0.88))
	titulo.text = "♨️ TERMAS ROMANAS · CURA & DESTILAÇÃO (Ouro: %d 🪙)" % InventoryManager.escudos
	header.add_child(titulo)

	var fechar := Button.new()
	fechar.focus_mode = Control.FOCUS_NONE
	fechar.text = "✖"
	fechar.pressed.connect(_alternar_painel_termas)
	header.add_child(fechar)

	var btn_curar := Button.new()
	btn_curar.focus_mode = Control.FOCUS_NONE
	btn_curar.text = "♨️ Banho Sulfuroso: Curar 100% de todos os Mercenários (10 🪙)"
	btn_curar.disabled = InventoryManager.escudos < 10 or CampaignManager.mercenarios.is_empty()
	btn_curar.pressed.connect(func():
		if InventoryManager.escudos < 10:
			return
		InventoryManager.escudos -= 10
		for m in CampaignManager.mercenarios:
			m["vida_atual"] = int(m.get("vida_maxima", 30))
		AudioManager.tocar_sfx("pocao_pronta")
		mostrar_mensagem("♨️ Todos os mercenários recuperaram 100% da vida nas Termas!")
		_abrir_painel_termas()
	)
	vbox.add_child(btn_curar)

	var btn_fonte := Button.new()
	btn_fonte.focus_mode = Control.FOCUS_NONE
	var ja_colheu := _fonte_colhida_dia == CampaignManager.dia
	btn_fonte.text = "💧 Fonte Termal Colhida Hoje ✅" if ja_colheu else "💧 Recolher na Fonte Termal (+2 Vapor Condensado, +1 Basalto · 1x/dia)"
	btn_fonte.disabled = ja_colheu
	btn_fonte.pressed.connect(func():
		_fonte_colhida_dia = CampaignManager.dia
		InventoryManager.adicionar_item("orvalho_do_pico", 2)
		InventoryManager.adicionar_item("basalto_fervente", 1)
		AudioManager.tocar_sfx("moeda")
		mostrar_mensagem("💧 Fonte Termal: +2 Vapor Condensado e +1 Basalto Fervente!")
		_abrir_painel_termas()
	)
	vbox.add_child(btn_fonte)
