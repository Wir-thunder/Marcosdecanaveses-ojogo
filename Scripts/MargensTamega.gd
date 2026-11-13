extends "res://Scripts/ExplorationScene.gd"

var _painel_rio: PanelContainer = null
var _btn_rio: Button = null
var _rng_rio := RandomNumberGenerator.new()
var _olival_colhido_dia: int = -1
var _pescas_hoje: int = 0
var _dia_pesca: int = -1

func _ready() -> void:
	super._ready()
	_rng_rio.randomize()
	_criar_botao_rio_hud()

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_P:
			_alternar_painel_rio()

func _criar_botao_rio_hud() -> void:
	var hud := get_node_or_null("Interface") as CanvasLayer
	if hud == null:
		return
	_btn_rio = Button.new()
	_btn_rio.name = "BotaoRioTamega"
	_btn_rio.focus_mode = Control.FOCUS_NONE
	_btn_rio.position = Vector2(468, 34)
	_btn_rio.custom_minimum_size = Vector2(164, 22)
	_btn_rio.add_theme_font_size_override("font_size", 9)
	_btn_rio.text = "🎣 RIO & OLIVAL [P]"
	_btn_rio.modulate = Color(0.68, 0.94, 1.0)
	_btn_rio.pressed.connect(_alternar_painel_rio)
	hud.add_child(_btn_rio)

func _alternar_painel_rio() -> void:
	if _painel_rio != null and is_instance_valid(_painel_rio):
		_painel_rio.queue_free()
		_painel_rio = null
		return
	_abrir_painel_rio()

func _abrir_painel_rio() -> void:
	var hud := get_node_or_null("Interface") as CanvasLayer
	if hud == null:
		return
	if _painel_rio != null and is_instance_valid(_painel_rio):
		_painel_rio.queue_free()

	if _dia_pesca != CampaignManager.dia:
		_dia_pesca = CampaignManager.dia
		_pescas_hoje = 0

	_painel_rio = PanelContainer.new()
	_painel_rio.position = Vector2(95, 72)
	_painel_rio.custom_minimum_size = Vector2(450, 190)
	var st := StyleBoxFlat.new()
	st.bg_color = Color(0.07, 0.10, 0.12, 0.96)
	st.border_color = Color(0.45, 0.78, 0.92, 1.0)
	st.set_border_width_all(2)
	st.set_corner_radius_all(6)
	st.content_margin_left = 10
	st.content_margin_right = 10
	st.content_margin_top = 8
	st.content_margin_bottom = 8
	_painel_rio.add_theme_stylebox_override("panel", st)
	hud.add_child(_painel_rio)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 8)
	_painel_rio.add_child(vbox)

	var header := HBoxContainer.new()
	vbox.add_child(header)
	var titulo := Label.new()
	titulo.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	titulo.add_theme_font_size_override("font_size", 12)
	titulo.add_theme_color_override("font_color", Color(0.68, 0.94, 1.0))
	titulo.text = "🎣 MARGENS DO TÂMEGA · PESCA & OLIVAL (Ouro: %d 🪙)" % InventoryManager.escudos
	header.add_child(titulo)

	var fechar := Button.new()
	fechar.focus_mode = Control.FOCUS_NONE
	fechar.text = "✖"
	fechar.pressed.connect(_alternar_painel_rio)
	header.add_child(fechar)

	var btn_pescar := Button.new()
	btn_pescar.focus_mode = Control.FOCUS_NONE
	btn_pescar.text = "🎣 Pescar com Velho Lourenço (%d/3 hoje) → Peixe, Água ou Alga" % _pescas_hoje
	btn_pescar.disabled = _pescas_hoje >= 3
	btn_pescar.pressed.connect(_pescar_no_rio)
	vbox.add_child(btn_pescar)

	var btn_cantil := Button.new()
	btn_cantil.focus_mode = Control.FOCUS_NONE
	btn_cantil.text = "💧 Encher Cantis na Corrente (Grátis · +2 Água Pura do Tâmega)"
	btn_cantil.pressed.connect(func():
		InventoryManager.adicionar_item("agua_tamega", 2)
		AudioManager.tocar_sfx("pocao_pronta")
		mostrar_mensagem("💧 Encheste 2x Água Pura do Tâmega direto na margem!")
		_abrir_painel_rio()
	)
	vbox.add_child(btn_cantil)

	var btn_olival := Button.new()
	btn_olival.focus_mode = Control.FOCUS_NONE
	var ja_colheu := _olival_colhido_dia == CampaignManager.dia
	btn_olival.text = "🫒 Prensa do Olival Antigo (Concluída hoje ✅)" if ja_colheu else "🫒 Prensa do Olival Antigo (+2 Azeite + 1 Mel · 1x/dia)"
	btn_olival.disabled = ja_colheu
	btn_olival.pressed.connect(func():
		_olival_colhido_dia = CampaignManager.dia
		InventoryManager.adicionar_item("azeite_do_olival", 2)
		InventoryManager.adicionar_item("mel_do_olival", 1)
		AudioManager.tocar_sfx("moeda")
		mostrar_mensagem("🫒 Prensa do Olival: +2 Azeite do Olival e +1 Mel do Olival!")
		_abrir_painel_rio()
	)
	vbox.add_child(btn_olival)

func _pescar_no_rio() -> void:
	if _pescas_hoje >= 3:
		return
	_pescas_hoje += 1
	var r := _rng_rio.randf()
	if r < 0.35:
		InventoryManager.escudos += 14
		AudioManager.tocar_sfx("moedas")
		mostrar_mensagem("🐟 Truta do Tâmega vendida ao Lourenço! +14 🪙")
	elif r < 0.72:
		InventoryManager.adicionar_item("alga_do_rio", 2)
		AudioManager.tocar_sfx("pocao_pronta")
		mostrar_mensagem("🌿 Pescaste 2x Alga Ribeirinha fresca!")
	else:
		InventoryManager.adicionar_item("agua_tamega", 2)
		InventoryManager.adicionar_item("pinho_resinato", 1)
		AudioManager.tocar_sfx("moeda")
		mostrar_mensagem("🪵 Rede trouxe 2x Água do Tâmega e 1x Resina de Pinho!")
	_abrir_painel_rio()
