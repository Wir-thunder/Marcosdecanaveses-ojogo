extends CanvasLayer

signal escape_pressed

var _slider_musica: HSlider = null
var _slider_sfx: HSlider = null
var _botao_tela_cheia: Button = null
var _botao_salvar: Button = null
var _botao_novo_jogo: Button = null
var _label_feedback: Label = null
var _confirmar_novo_jogo: bool = false

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	visibility_changed.connect(_ao_mudar_visibilidade)
	_construir_secao_opcoes()
	_sincronizar_controles()

func _unhandled_input(event: InputEvent) -> void:
	if not (event is InputEventKey and event.pressed and not event.echo):
		return
	var key_event := event as InputEventKey
	if key_event.keycode == KEY_ESCAPE:
		escape_pressed.emit()
		get_viewport().set_input_as_handled()
	elif key_event.alt_pressed and (key_event.keycode == KEY_ENTER or key_event.keycode == KEY_KP_ENTER):
		_alternar_tela_cheia()
		get_viewport().set_input_as_handled()

func _construir_secao_opcoes() -> void:
	var painel := get_node_or_null("Painel") as PanelContainer
	var margem := get_node_or_null("Painel/Margem") as MarginContainer
	var coluna := get_node_or_null("Painel/Margem/Coluna") as VBoxContainer
	if coluna == null:
		return

	if painel != null:
		painel.offset_left = 150.0
		painel.offset_top = 18.0
		painel.offset_right = 490.0
		painel.offset_bottom = 342.0

	if margem != null:
		margem.add_theme_constant_override("margin_left", 16)
		margem.add_theme_constant_override("margin_right", 16)
		margem.add_theme_constant_override("margin_top", 10)
		margem.add_theme_constant_override("margin_bottom", 10)

	coluna.add_theme_constant_override("separation", 4)
	for nome_btn in ["Retomar", "Reiniciar", "Sair"]:
		var btn := coluna.get_node_or_null(nome_btn) as Button
		if btn != null:
			btn.custom_minimum_size = Vector2(0, 24)

	var separador := HSeparator.new()
	separador.name = "SeparadorOpcoes"
	coluna.add_child(separador)

	var titulo_opcoes := Label.new()
	titulo_opcoes.name = "TituloOpcoes"
	titulo_opcoes.text = "OPÇÕES & SISTEMA"
	titulo_opcoes.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	titulo_opcoes.add_theme_color_override("font_color", Color(0.91, 0.78, 0.49, 1.0))
	titulo_opcoes.add_theme_font_size_override("font_size", 13)
	coluna.add_child(titulo_opcoes)

	# Volume Música
	var linha_musica := HBoxContainer.new()
	linha_musica.add_theme_constant_override("separation", 8)
	var lbl_musica := Label.new()
	lbl_musica.text = "Música"
	lbl_musica.custom_minimum_size = Vector2(92, 0)
	lbl_musica.add_theme_font_size_override("font_size", 11)
	_slider_musica = HSlider.new()
	_slider_musica.min_value = 0.0
	_slider_musica.max_value = 1.0
	_slider_musica.step = 0.05
	_slider_musica.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_slider_musica.value_changed.connect(_ao_mudar_musica)
	linha_musica.add_child(lbl_musica)
	linha_musica.add_child(_slider_musica)
	coluna.add_child(linha_musica)

	# Volume Efeitos / Vozes
	var linha_sfx := HBoxContainer.new()
	linha_sfx.add_theme_constant_override("separation", 8)
	var lbl_sfx := Label.new()
	lbl_sfx.text = "Efeitos / Vozes"
	lbl_sfx.custom_minimum_size = Vector2(92, 0)
	lbl_sfx.add_theme_font_size_override("font_size", 11)
	_slider_sfx = HSlider.new()
	_slider_sfx.min_value = 0.0
	_slider_sfx.max_value = 1.0
	_slider_sfx.step = 0.05
	_slider_sfx.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_slider_sfx.value_changed.connect(_ao_mudar_sfx)
	linha_sfx.add_child(lbl_sfx)
	linha_sfx.add_child(_slider_sfx)
	coluna.add_child(linha_sfx)

	# Tela Cheia
	_botao_tela_cheia = Button.new()
	_botao_tela_cheia.name = "BotaoTelaCheia"
	_botao_tela_cheia.custom_minimum_size = Vector2(0, 24)
	_botao_tela_cheia.add_theme_font_size_override("font_size", 11)
	_botao_tela_cheia.pressed.connect(_alternar_tela_cheia)
	coluna.add_child(_botao_tela_cheia)

	# Salvar Agora & Novo Jogo
	var linha_save := HBoxContainer.new()
	linha_save.add_theme_constant_override("separation", 6)

	_botao_salvar = Button.new()
	_botao_salvar.name = "BotaoSalvarAgora"
	_botao_salvar.text = "Salvar Agora"
	_botao_salvar.custom_minimum_size = Vector2(0, 24)
	_botao_salvar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_botao_salvar.add_theme_font_size_override("font_size", 11)
	_botao_salvar.pressed.connect(_ao_clicar_salvar)
	linha_save.add_child(_botao_salvar)

	_botao_novo_jogo = Button.new()
	_botao_novo_jogo.name = "BotaoNovoJogo"
	_botao_novo_jogo.text = "Novo Jogo (Apagar Save)"
	_botao_novo_jogo.custom_minimum_size = Vector2(0, 24)
	_botao_novo_jogo.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_botao_novo_jogo.add_theme_font_size_override("font_size", 11)
	_botao_novo_jogo.pressed.connect(_ao_clicar_novo_jogo)
	linha_save.add_child(_botao_novo_jogo)

	coluna.add_child(linha_save)

	# Feedback label
	_label_feedback = Label.new()
	_label_feedback.name = "FeedbackSistema"
	_label_feedback.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_label_feedback.add_theme_font_size_override("font_size", 11)
	_label_feedback.text = ""
	coluna.add_child(_label_feedback)

func _ao_mudar_visibilidade() -> void:
	_confirmar_novo_jogo = false
	if _botao_novo_jogo != null:
		_botao_novo_jogo.text = "Novo Jogo (Apagar Save)"
		_botao_novo_jogo.remove_theme_color_override("font_color")
	if _label_feedback != null:
		_label_feedback.text = ""
	if visible:
		_sincronizar_controles()

func _sincronizar_controles() -> void:
	if _slider_musica != null:
		var vol_m: float = 0.5
		if has_node("/root/AudioManager"):
			var am := get_node("/root/AudioManager")
			if am.has_method("obter_volume_musica"):
				vol_m = float(am.obter_volume_musica())
			elif "volume_musica_db" in am:
				vol_m = clampf(db_to_linear(float(am.volume_musica_db)), 0.0, 1.0)
		_slider_musica.set_value_no_signal(vol_m)

	if _slider_sfx != null:
		var vol_s: float = 1.0
		if has_node("/root/AudioManager"):
			var am := get_node("/root/AudioManager")
			if am.has_method("obter_volume_sfx"):
				vol_s = float(am.obter_volume_sfx())
			elif "volume_sfx_db" in am:
				vol_s = clampf(db_to_linear(float(am.volume_sfx_db)), 0.0, 1.0)
		_slider_sfx.set_value_no_signal(vol_s)

	_atualizar_texto_tela_cheia()

func _ao_mudar_musica(valor: float) -> void:
	if has_node("/root/AudioManager"):
		var am := get_node("/root/AudioManager")
		if am.has_method("definir_volume_musica"):
			am.definir_volume_musica(valor)

func _ao_mudar_sfx(valor: float) -> void:
	if has_node("/root/AudioManager"):
		var am := get_node("/root/AudioManager")
		if am.has_method("definir_volume_sfx"):
			am.definir_volume_sfx(valor)
		if am.has_method("definir_volume_vozes"):
			am.definir_volume_vozes(valor)

func _alternar_tela_cheia() -> void:
	var modo_atual := DisplayServer.window_get_mode()
	var em_tela_cheia := (modo_atual == DisplayServer.WINDOW_MODE_FULLSCREEN or modo_atual == DisplayServer.WINDOW_MODE_EXCLUSIVE_FULLSCREEN)
	if em_tela_cheia:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
	else:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
	_atualizar_texto_tela_cheia()

func _atualizar_texto_tela_cheia() -> void:
	if _botao_tela_cheia == null:
		return
	var modo_atual := DisplayServer.window_get_mode()
	var em_tela_cheia := (modo_atual == DisplayServer.WINDOW_MODE_FULLSCREEN or modo_atual == DisplayServer.WINDOW_MODE_EXCLUSIVE_FULLSCREEN)
	_botao_tela_cheia.text = "Tela Cheia: LIGADA (Alt+Enter)" if em_tela_cheia else "Tela Cheia: DESLIGADA (Alt+Enter)"

func _ao_clicar_salvar() -> void:
	if not has_node("/root/SaveManager"):
		return
	var ok: bool = get_node("/root/SaveManager").salvar_jogo()
	if _label_feedback != null:
		if ok:
			_label_feedback.text = "✓ Progresso guardado com sucesso!"
			_label_feedback.add_theme_color_override("font_color", Color(0.55, 0.92, 0.55, 1.0))
		else:
			_label_feedback.text = "Erro ao guardar o progresso."
			_label_feedback.add_theme_color_override("font_color", Color(0.95, 0.45, 0.45, 1.0))

func _ao_clicar_novo_jogo() -> void:
	if not _confirmar_novo_jogo:
		_confirmar_novo_jogo = true
		if _botao_novo_jogo != null:
			_botao_novo_jogo.text = "Confirmar Apagar?"
			_botao_novo_jogo.add_theme_color_override("font_color", Color(1.0, 0.45, 0.4, 1.0))
		if _label_feedback != null:
			_label_feedback.text = "Clica novamente para apagar o save e recomeçar."
			_label_feedback.add_theme_color_override("font_color", Color(0.98, 0.78, 0.38, 1.0))
		return

	_confirmar_novo_jogo = false
	if has_node("/root/SaveManager"):
		var sm := get_node("/root/SaveManager")
		sm.apagar_save()
		sm.resetar_estado_novo_jogo()
	get_tree().paused = false
	visible = false
	if has_node("/root/SceneRouter"):
		get_node("/root/SceneRouter").ir_para("res://Cenas/cena_principal.tscn", Vector2(245.0, 175.0), false)
