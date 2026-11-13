extends CanvasLayer

var _painel: PanelContainer = null
var _titulo_lbl: Label = null
var _idioma_lbl: Label = null
var _btn_pt: Button = null
var _btn_en: Button = null
var _btn_es: Button = null
var _musica_lbl: Label = null
var _musica_slider: HSlider = null
var _sfx_lbl: Label = null
var _sfx_slider: HSlider = null
var _vozes_lbl: Label = null
var _vozes_slider: HSlider = null
var _controles_lbl: Label = null
var _fechar_btn: Button = null

func _ready() -> void:
	layer = 100
	process_mode = Node.PROCESS_MODE_ALWAYS
	_construir_ui()
	if _painel != null:
		_painel.visible = false
	CampaignManager.idioma_alterado.connect(_on_idioma_alterado)

func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		var kev := event as InputEventKey
		if kev.keycode == KEY_F9 or kev.physical_keycode == KEY_F9:
			alternar()
			get_viewport().set_input_as_handled()
		elif (kev.keycode == KEY_ESCAPE or kev.physical_keycode == KEY_ESCAPE) and _painel != null and _painel.visible:
			fechar()
			get_viewport().set_input_as_handled()

func alternar() -> void:
	if _painel == null:
		return
	if _painel.visible:
		fechar()
	else:
		abrir()

func abrir() -> void:
	if _painel == null:
		return
	_atualizar_textos()
	if _musica_slider != null:
		_musica_slider.set_value_no_signal(AudioManager.obter_volume_musica() * 100.0)
	if _sfx_slider != null:
		_sfx_slider.set_value_no_signal(AudioManager.obter_volume_sfx() * 100.0)
	if _vozes_slider != null:
		_vozes_slider.set_value_no_signal(AudioManager.obter_volume_vozes() * 100.0)
	_painel.visible = true

func fechar() -> void:
	if _painel != null:
		_painel.visible = false

func _construir_ui() -> void:
	var root_ctrl := Control.new()
	root_ctrl.set_anchors_preset(Control.PRESET_FULL_RECT)
	root_ctrl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(root_ctrl)

	_painel = PanelContainer.new()
	_painel.custom_minimum_size = Vector2(440.0, 270.0)
	_painel.set_anchors_preset(Control.PRESET_CENTER)
	_painel.offset_left = -220.0
	_painel.offset_top = -135.0
	_painel.offset_right = 220.0
	_painel.offset_bottom = 135.0
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.09, 0.08, 0.07, 0.96)
	sb.border_color = Color(0.76, 0.61, 0.31, 0.95)
	sb.set_border_width_all(2)
	sb.set_corner_radius_all(8)
	sb.set_content_margin_all(12)
	_painel.add_theme_stylebox_override("panel", sb)
	root_ctrl.add_child(_painel)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 8)
	_painel.add_child(vbox)

	_titulo_lbl = Label.new()
	_titulo_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_titulo_lbl.add_theme_font_size_override("font_size", 11)
	_titulo_lbl.add_theme_color_override("font_color", Color(0.96, 0.84, 0.45))
	vbox.add_child(_titulo_lbl)

	_idioma_lbl = Label.new()
	_idioma_lbl.add_theme_font_size_override("font_size", 9)
	vbox.add_child(_idioma_lbl)

	var hbox_lang := HBoxContainer.new()
	hbox_lang.add_theme_constant_override("separation", 6)
	vbox.add_child(hbox_lang)

	_btn_pt = Button.new()
	_btn_pt.text = "Português (PT)"
	_btn_pt.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_btn_pt.add_theme_font_size_override("font_size", 9)
	_btn_pt.pressed.connect(func() -> void: CampaignManager.definir_idioma("pt"))
	hbox_lang.add_child(_btn_pt)

	_btn_en = Button.new()
	_btn_en.text = "English (EN)"
	_btn_en.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_btn_en.add_theme_font_size_override("font_size", 9)
	_btn_en.pressed.connect(func() -> void: CampaignManager.definir_idioma("en"))
	hbox_lang.add_child(_btn_en)

	_btn_es = Button.new()
	_btn_es.text = "Español (ES)"
	_btn_es.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_btn_es.add_theme_font_size_override("font_size", 9)
	_btn_es.pressed.connect(func() -> void: CampaignManager.definir_idioma("es"))
	hbox_lang.add_child(_btn_es)

	_musica_lbl = Label.new()
	_musica_lbl.add_theme_font_size_override("font_size", 9)
	vbox.add_child(_musica_lbl)
	_musica_slider = HSlider.new()
	_musica_slider.min_value = 0.0
	_musica_slider.max_value = 100.0
	_musica_slider.step = 5.0
	_musica_slider.value_changed.connect(func(val: float) -> void: AudioManager.definir_volume_musica(val / 100.0))
	vbox.add_child(_musica_slider)

	_sfx_lbl = Label.new()
	_sfx_lbl.add_theme_font_size_override("font_size", 9)
	vbox.add_child(_sfx_lbl)
	_sfx_slider = HSlider.new()
	_sfx_slider.min_value = 0.0
	_sfx_slider.max_value = 100.0
	_sfx_slider.step = 5.0
	_sfx_slider.value_changed.connect(func(val: float) -> void: AudioManager.definir_volume_sfx(val / 100.0))
	vbox.add_child(_sfx_slider)

	_vozes_lbl = Label.new()
	_vozes_lbl.add_theme_font_size_override("font_size", 9)
	vbox.add_child(_vozes_lbl)
	_vozes_slider = HSlider.new()
	_vozes_slider.min_value = 0.0
	_vozes_slider.max_value = 100.0
	_vozes_slider.step = 5.0
	_vozes_slider.value_changed.connect(func(val: float) -> void: AudioManager.definir_volume_vozes(val / 100.0))
	vbox.add_child(_vozes_slider)

	_controles_lbl = Label.new()
	_controles_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_controles_lbl.add_theme_font_size_override("font_size", 8)
	_controles_lbl.add_theme_color_override("font_color", Color(0.82, 0.86, 0.78))
	vbox.add_child(_controles_lbl)

	_fechar_btn = Button.new()
	_fechar_btn.add_theme_font_size_override("font_size", 9)
	_fechar_btn.pressed.connect(fechar)
	vbox.add_child(_fechar_btn)

	_atualizar_textos()

func _on_idioma_alterado(_novo: String) -> void:
	_atualizar_textos()

func _atualizar_textos() -> void:
	if _titulo_lbl == null:
		return
	_titulo_lbl.text = tr("UI_CFG_TITULO")
	_idioma_lbl.text = tr("UI_CFG_IDIOMA")
	_musica_lbl.text = tr("UI_CFG_MUSICA")
	_sfx_lbl.text = tr("UI_CFG_SFX")
	_vozes_lbl.text = tr("UI_CFG_VOZES")
	_controles_lbl.text = tr("UI_CFG_CONTROLES")
	_fechar_btn.text = tr("UI_CFG_FECHAR")
	var loc := TranslationServer.get_locale().substr(0, 2)
	_btn_pt.modulate = Color(1.0, 0.92, 0.55) if loc == "pt" else Color(0.78, 0.78, 0.78)
	_btn_en.modulate = Color(1.0, 0.92, 0.55) if loc == "en" else Color(0.78, 0.78, 0.78)
	_btn_es.modulate = Color(1.0, 0.92, 0.55) if loc == "es" else Color(0.78, 0.78, 0.78)
