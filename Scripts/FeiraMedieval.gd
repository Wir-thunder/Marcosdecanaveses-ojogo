extends "res://Scripts/ExplorationScene.gd"

const CONTRATOS_FEIRA: Array[Dictionary] = [
	{"item_id": "pocao_vento_ligeiro", "nome": "Poção Vento Ligeiro", "qtd": 2, "ouro": 42},
	{"item_id": "pocao_espinheira_real", "nome": "Poção Espinheira Real", "qtd": 2, "ouro": 48},
	{"item_id": "pocao_escudo_do_lago", "nome": "Poção Escudo do Lago", "qtd": 2, "ouro": 52},
	{"item_id": "pocao_mente_limpida", "nome": "Poção Mente Límpida", "qtd": 2, "ouro": 56},
]

const ESCAMBOS: Array[Dictionary] = [
	{"dar_id": "pocao_vento_ligeiro", "dar_nome": "Poção Vento Ligeiro", "receber_id": "raiz_mandrago", "receber_nome": "Raiz de Mandrágora"},
	{"dar_id": "pocao_espinheira_real", "dar_nome": "Poção Espinheira Real", "receber_id": "basalto_fervente", "receber_nome": "Basalto Fervente"},
	{"dar_id": "pocao_escudo_do_lago", "dar_nome": "Poção Escudo do Lago", "receber_id": "lagrima_douro", "receber_nome": "Lágrima do Douro"},
]

const VIDEO_CARAVANA_PATH: String = "res://Assets/Video/feira_caravana.ogv"

var _painel_feira: PanelContainer = null
var _btn_feira: Button = null
var _rng_feira := RandomNumberGenerator.new()
var _contrato_entregue_dia: int = -1
var _overlay_video: ColorRect = null
var _video_player: VideoStreamPlayer = null

static var _intro_caravana_vista_sessao: bool = false

func _ready() -> void:
	super._ready()
	_rng_feira.randomize()
	_criar_botao_feira_hud()
	if not _intro_caravana_vista_sessao and FileAccess.file_exists(VIDEO_CARAVANA_PATH):
		_intro_caravana_vista_sessao = true
		call_deferred("_reproduzir_cutscene_caravana")

func _unhandled_input(event: InputEvent) -> void:
	if _overlay_video != null and is_instance_valid(_overlay_video):
		if event is InputEventKey and event.pressed and (event.keycode == KEY_ESCAPE or event.keycode == KEY_SPACE or event.keycode == KEY_ENTER):
			_fechar_cutscene_caravana()
			get_viewport().set_input_as_handled()
		return
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_B:
			_alternar_painel_feira()

func _criar_botao_feira_hud() -> void:
	var hud := get_node_or_null("Interface") as CanvasLayer
	if hud == null:
		return
	_btn_feira = Button.new()
	_btn_feira.name = "BotaoBancasFeira"
	_btn_feira.focus_mode = Control.FOCUS_NONE
	_btn_feira.position = Vector2(468, 34)
	_btn_feira.custom_minimum_size = Vector2(164, 22)
	_btn_feira.add_theme_font_size_override("font_size", 9)
	_btn_feira.text = "🎪 BANCAS DA FEIRA [B]"
	_btn_feira.modulate = Color(1.0, 0.90, 0.52)
	_btn_feira.pressed.connect(_alternar_painel_feira)
	hud.add_child(_btn_feira)

func _alternar_painel_feira() -> void:
	if _painel_feira != null and is_instance_valid(_painel_feira):
		_painel_feira.queue_free()
		_painel_feira = null
		return
	_abrir_painel_feira()

func _abrir_painel_feira() -> void:
	var hud := get_node_or_null("Interface") as CanvasLayer
	if hud == null:
		return
	if _painel_feira != null and is_instance_valid(_painel_feira):
		_painel_feira.queue_free()

	_painel_feira = PanelContainer.new()
	_painel_feira.name = "PainelBancasFeira"
	_painel_feira.position = Vector2(80, 58)
	_painel_feira.custom_minimum_size = Vector2(480, 250)
	var st := StyleBoxFlat.new()
	st.bg_color = Color(0.09, 0.07, 0.05, 0.96)
	st.border_color = Color(0.86, 0.68, 0.30, 1.0)
	st.set_border_width_all(2)
	st.set_corner_radius_all(6)
	st.content_margin_left = 10
	st.content_margin_right = 10
	st.content_margin_top = 8
	st.content_margin_bottom = 8
	_painel_feira.add_theme_stylebox_override("panel", st)
	hud.add_child(_painel_feira)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 6)
	_painel_feira.add_child(vbox)

	var header := HBoxContainer.new()
	vbox.add_child(header)
	var titulo := Label.new()
	titulo.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	titulo.add_theme_font_size_override("font_size", 12)
	titulo.add_theme_color_override("font_color", Color(1.0, 0.88, 0.45))
	titulo.text = "🎪 FEIRA MEDIEVAL · BANCAS & ATIVIDADES (Ouro: %d 🪙)" % InventoryManager.escudos
	header.add_child(titulo)

	var fechar := Button.new()
	fechar.focus_mode = Control.FOCUS_NONE
	fechar.text = "✖"
	fechar.pressed.connect(_alternar_painel_feira)
	header.add_child(fechar)

	# 1. Encomenda do Arauto
	var contrato := CONTRATOS_FEIRA[(CampaignManager.dia - 1) % CONTRATOS_FEIRA.size()]
	var c_id := str(contrato["item_id"])
	var c_qtd := int(contrato["qtd"])
	var c_ouro := int(contrato["ouro"])
	var tem_qtd := InventoryManager.obter_quantidade(c_id)
	var ja_fez := _contrato_entregue_dia == CampaignManager.dia

	var btn_contrato := Button.new()
	btn_contrato.focus_mode = Control.FOCUS_NONE
	btn_contrato.add_theme_font_size_override("font_size", 10)
	if ja_fez:
		btn_contrato.text = "📜 Encomenda de Hoje Concluída ✅"
		btn_contrato.disabled = true
	else:
		btn_contrato.text = "📜 Encomenda do Arauto: Entregar %dx %s (tens %d) → +%d 🪙" % [c_qtd, str(contrato["nome"]), tem_qtd, c_ouro]
		btn_contrato.disabled = tem_qtd < c_qtd
		btn_contrato.pressed.connect(func():
			if InventoryManager.remover_item(c_id, c_qtd):
				InventoryManager.escudos += c_ouro
				_contrato_entregue_dia = CampaignManager.dia
				AudioManager.tocar_sfx("moedas")
				mostrar_mensagem("📜 Encomenda entregue! +%d 🪙 recebidos do Arauto Fernão!" % c_ouro)
				_abrir_painel_feira()
		)
	vbox.add_child(btn_contrato)

	# 2. Escambo da Dona Guiomar
	var lbl_esc := Label.new()
	lbl_esc.add_theme_font_size_override("font_size", 10)
	lbl_esc.add_theme_color_override("font_color", Color(0.75, 0.94, 0.78))
	lbl_esc.text = "🔄 Escambo da Dona Guiomar (troca 1 poção por reagente raro):"
	vbox.add_child(lbl_esc)

	for esc in ESCAMBOS:
		var d_id := str(esc["dar_id"])
		var r_id := str(esc["receber_id"])
		var q_d := InventoryManager.obter_quantidade(d_id)
		var btn_esc := Button.new()
		btn_esc.focus_mode = Control.FOCUS_NONE
		btn_esc.add_theme_font_size_override("font_size", 9)
		btn_esc.text = "Trocar 1x %s (tens %d) → 1x %s" % [str(esc["dar_nome"]), q_d, str(esc["receber_nome"])]
		btn_esc.disabled = q_d <= 0
		btn_esc.pressed.connect(func():
			if InventoryManager.remover_item(d_id, 1):
				InventoryManager.adicionar_item(r_id, 1)
				AudioManager.tocar_sfx("moeda")
				mostrar_mensagem("🔄 Escambo feito! Recebeste 1x %s." % str(esc["receber_nome"]))
				_abrir_painel_feira()
		)
		vbox.add_child(btn_esc)

	# 3. Barraca de Argolas + 4. Promover Poção
	var h_extras := HBoxContainer.new()
	h_extras.add_theme_constant_override("separation", 6)
	vbox.add_child(h_extras)

	var btn_argolas := Button.new()
	btn_argolas.focus_mode = Control.FOCUS_NONE
	btn_argolas.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	btn_argolas.add_theme_font_size_override("font_size", 9)
	btn_argolas.text = "🎯 Barraca de Argolas (8 🪙)"
	btn_argolas.disabled = InventoryManager.escudos < 8
	btn_argolas.pressed.connect(_jogar_argolas)
	h_extras.add_child(btn_argolas)

	var btn_promo := Button.new()
	btn_promo.focus_mode = Control.FOCUS_NONE
	btn_promo.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	btn_promo.add_theme_font_size_override("font_size", 9)
	btn_promo.text = "📣 Promover %s (1x → Tendência 🔥)" % str(contrato["nome"]).replace("Poção ", "")
	btn_promo.disabled = InventoryManager.obter_quantidade(c_id) <= 0
	btn_promo.pressed.connect(func():
		if InventoryManager.remover_item(c_id, 1):
			InventoryManager.pocao_tendencia_dia_id = c_id
			InventoryManager.nome_pocao_tendencia_dia = str(contrato["nome"])
			InventoryManager.motivo_tendencia_dia = "Degustação na Feira Medieval (+35% Ouro)"
			AudioManager.tocar_sfx("fanfarra_vitoria")
			mostrar_mensagem("📣 %s agora é Tendência 🔥 na tua Botica (+35%% Ouro)!" % str(contrato["nome"]))
			_abrir_painel_feira()
	)
	h_extras.add_child(btn_promo)

	var btn_video := Button.new()
	btn_video.focus_mode = Control.FOCUS_NONE
	btn_video.add_theme_font_size_override("font_size", 9)
	btn_video.text = "🎬 Ver Chegada da Caravana (.ogv)"
	btn_video.pressed.connect(func():
		_alternar_painel_feira()
		_reproduzir_cutscene_caravana()
	)
	vbox.add_child(btn_video)

func _reproduzir_cutscene_caravana() -> void:
	var hud := get_node_or_null("Interface") as CanvasLayer
	if hud == null or not FileAccess.file_exists(VIDEO_CARAVANA_PATH):
		return
	_fechar_cutscene_caravana()

	_overlay_video = ColorRect.new()
	_overlay_video.color = Color(0.03, 0.02, 0.02, 0.96)
	_overlay_video.set_anchors_preset(Control.PRESET_FULL_RECT)
	hud.add_child(_overlay_video)

	var stream := VideoStreamTheora.new()
	stream.file = VIDEO_CARAVANA_PATH
	_video_player = VideoStreamPlayer.new()
	_video_player.stream = stream
	_video_player.expand = true
	_video_player.set_anchors_preset(Control.PRESET_FULL_RECT)
	_video_player.finished.connect(_fechar_cutscene_caravana)
	_overlay_video.add_child(_video_player)
	_video_player.play()

	var dica := Label.new()
	dica.text = "Caravana da Feira Medieval · [ESPAÇO / ESC] para pular"
	dica.position = Vector2(18, 332)
	dica.add_theme_font_size_override("font_size", 10)
	dica.add_theme_color_override("font_color", Color(1.0, 0.92, 0.65))
	_overlay_video.add_child(dica)

func _fechar_cutscene_caravana() -> void:
	if _video_player != null and is_instance_valid(_video_player):
		_video_player.stop()
	_video_player = null
	if _overlay_video != null and is_instance_valid(_overlay_video):
		_overlay_video.queue_free()
	_overlay_video = null

func _jogar_argolas() -> void:
	if InventoryManager.escudos < 8:
		return
	InventoryManager.escudos -= 8
	var r := _rng_feira.randf()
	if r < 0.25:
		InventoryManager.escudos += 16
		InventoryManager.adicionar_item("lagrima_douro", 1)
		AudioManager.tocar_sfx("fanfarra_vitoria")
		mostrar_mensagem("🎯 ACERTOU NA MOSCA! +16 🪙 e 1x Lágrima do Douro!")
	elif r < 0.70:
		InventoryManager.adicionar_item("gengibre_do_vale", 2)
		AudioManager.tocar_sfx("moeda")
		mostrar_mensagem("🎯 Bom lançamento! Ganhaste 2x Gengibre do Vale!")
	else:
		AudioManager.tocar_sfx("pechincha_falha")
		mostrar_mensagem("🎯 A argola bateu na borda! Tenta novamente.")
	_abrir_painel_feira()
