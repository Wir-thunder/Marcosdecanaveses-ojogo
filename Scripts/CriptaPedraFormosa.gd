extends "res://Scripts/ExplorationScene.gd"

const POCOES_ALTAR: Array[Dictionary] = [
	{"id": "pocao_vento_ligeiro", "nome": "Poção Vento Ligeiro"},
	{"id": "pocao_espinheira_real", "nome": "Poção Espinheira Real"},
	{"id": "pocao_escudo_do_lago", "nome": "Poção Escudo do Lago"},
	{"id": "pocao_mente_limpida", "nome": "Poção Mente Límpida"},
]

var _painel_altar: PanelContainer = null
var _btn_altar: Button = null
var _bencao_dia: int = -1

func _ready() -> void:
	super._ready()
	_criar_botao_altar_hud()

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_A:
			_alternar_painel_altar()

func _criar_botao_altar_hud() -> void:
	var hud := get_node_or_null("Interface") as CanvasLayer
	if hud == null:
		return
	_btn_altar = Button.new()
	_btn_altar.name = "BotaoAltarCripta"
	_btn_altar.focus_mode = Control.FOCUS_NONE
	_btn_altar.position = Vector2(468, 34)
	_btn_altar.custom_minimum_size = Vector2(164, 22)
	_btn_altar.add_theme_font_size_override("font_size", 9)
	_btn_altar.text = "🗿 ALTAR DA PEDRA [A]"
	_btn_altar.modulate = Color(0.68, 0.88, 1.0)
	_btn_altar.pressed.connect(_alternar_painel_altar)
	hud.add_child(_btn_altar)

func _alternar_painel_altar() -> void:
	if _painel_altar != null and is_instance_valid(_painel_altar):
		_painel_altar.queue_free()
		_painel_altar = null
		return
	_abrir_painel_altar()

func _abrir_painel_altar() -> void:
	var hud := get_node_or_null("Interface") as CanvasLayer
	if hud == null:
		return
	if _painel_altar != null and is_instance_valid(_painel_altar):
		_painel_altar.queue_free()

	_painel_altar = PanelContainer.new()
	_painel_altar.position = Vector2(85, 65)
	_painel_altar.custom_minimum_size = Vector2(470, 220)
	var st := StyleBoxFlat.new()
	st.bg_color = Color(0.07, 0.08, 0.12, 0.96)
	st.border_color = Color(0.45, 0.78, 0.98, 1.0)
	st.set_border_width_all(2)
	st.set_corner_radius_all(6)
	st.content_margin_left = 10
	st.content_margin_right = 10
	st.content_margin_top = 8
	st.content_margin_bottom = 8
	_painel_altar.add_theme_stylebox_override("panel", st)
	hud.add_child(_painel_altar)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 6)
	_painel_altar.add_child(vbox)

	var header := HBoxContainer.new()
	vbox.add_child(header)
	var titulo := Label.new()
	titulo.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	titulo.add_theme_font_size_override("font_size", 12)
	titulo.add_theme_color_override("font_color", Color(0.70, 0.90, 1.0))
	titulo.text = "🗿 ALTAR DA PEDRA FORMOSA (Ouro: %d 🪙)" % InventoryManager.escudos
	header.add_child(titulo)

	var fechar := Button.new()
	fechar.focus_mode = Control.FOCUS_NONE
	fechar.text = "✖"
	fechar.pressed.connect(_alternar_painel_altar)
	header.add_child(fechar)

	var lbl_sub := Label.new()
	lbl_sub.add_theme_font_size_override("font_size", 10)
	lbl_sub.add_theme_color_override("font_color", Color(0.86, 0.94, 0.98))
	lbl_sub.text = "✨ Transmutar Poção Comum → Poção Ouro ✨ (custo: 8 🪙):"
	vbox.add_child(lbl_sub)

	for p in POCOES_ALTAR:
		var p_id := str(p["id"])
		var p_nome := str(p["nome"])
		var qtd := InventoryManager.obter_quantidade(p_id)
		var btn_t := Button.new()
		btn_t.focus_mode = Control.FOCUS_NONE
		btn_t.add_theme_font_size_override("font_size", 9)
		btn_t.text = "Consagrar %s (tens %d) → +1 ✨ Ouro (8 🪙)" % [p_nome, qtd]
		btn_t.disabled = qtd <= 0 or InventoryManager.escudos < 8
		btn_t.pressed.connect(func():
			if InventoryManager.escudos >= 8 and InventoryManager.remover_item(p_id, 1):
				InventoryManager.escudos -= 8
				InventoryManager.adicionar_item_ouro(p_id, 1)
				AudioManager.tocar_sfx("pocao_magica")
				mostrar_mensagem("✨ %s consagrada em Poção Ouro!" % p_nome)
				_abrir_painel_altar()
		)
		vbox.add_child(btn_t)

	var btn_bencao := Button.new()
	btn_bencao.focus_mode = Control.FOCUS_NONE
	var ja_bencao := _bencao_dia == CampaignManager.dia
	btn_bencao.text = "🔮 Bênção Ancestral Recebida Hoje ✅" if ja_bencao else "🔮 Bênção da Pedra Formosa (+2 Poder RPG hoje · 1x/dia)"
	btn_bencao.disabled = ja_bencao
	btn_bencao.pressed.connect(func():
		_bencao_dia = CampaignManager.dia
		CampaignManager.buff_taverna_poder += 2
		AudioManager.tocar_sfx("fanfarra_vitoria")
		mostrar_mensagem("🔮 Bênção Ancestral! +2 Poder para os teus mercenários!")
		_abrir_painel_altar()
	)
	vbox.add_child(btn_bencao)
