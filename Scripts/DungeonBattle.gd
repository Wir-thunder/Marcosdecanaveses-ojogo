extends Control

const CENA_TAVERNA: String = "res://Cenas/Taverna.tscn"
const CENA_DUNGEON: String = "res://Cenas/Dungeon.tscn"

const TEXTURAS_HEROIS: Dictionary = {
	"Guerreiro": preload("res://Assets/Characters/Adventurers/guerreiro.png"),
	"Arqueiro": preload("res://Assets/Characters/Adventurers/arqueiro.png"),
	"Mago": preload("res://Assets/Characters/Adventurers/mago.png"),
	"Curandeiro": preload("res://Assets/Characters/Adventurers/curandeiro.png"),
}

const TEXTURAS_INIMIGOS: Dictionary = {
	"Goblin saqueador": preload("res://Assets/Characters/Monsters/goblin.png"),
	"Morcego das ruínas": preload("res://Assets/Characters/Monsters/morcego.png"),
	"Lobo das sombras": preload("res://Assets/Characters/Monsters/lobo.png"),
	"Saqueador das minas": preload("res://Assets/Characters/Monsters/saqueador.png"),
	"Sentinela de osso": preload("res://Assets/Characters/Monsters/sentinela.png"),
	"Guardião de xisto": preload("res://Assets/Characters/Monsters/guardiao.png"),
}

const INIMIGOS_BASE: Array[Dictionary] = [
	{"nome": "Goblin saqueador", "vida": 24, "ataque": 6, "fraqueza": "Arqueiro"},
	{"nome": "Morcego das ruínas", "vida": 20, "ataque": 5, "fraqueza": "Mago"},
	{"nome": "Lobo das sombras", "vida": 26, "ataque": 6, "fraqueza": "Arqueiro"},
	{"nome": "Saqueador das minas", "vida": 28, "ataque": 7, "fraqueza": "Guerreiro"},
	{"nome": "Sentinela de osso", "vida": 30, "ataque": 7, "fraqueza": "Guerreiro"},
	{"nome": "Guardião de xisto", "vida": 38, "ataque": 8, "fraqueza": "Mago"},
]

@onready var interface_layer: CanvasLayer = $Interface
@onready var sala_label: Label = $Interface/Conteudo/Sala
@onready var estado_label: Label = $Interface/Conteudo/Estado
@onready var inimigos_box: HBoxContainer = $Interface/Conteudo/Inimigos
@onready var equipa_box: HBoxContainer = $Interface/Conteudo/Equipa
@onready var turno_label: Label = $Interface/Conteudo/Turno
@onready var acoes_box: HBoxContainer = $Interface/Conteudo/Comandos
@onready var atacar_botao: Button = $Interface/Conteudo/Comandos/Atacar
@onready var habilidade_botao: Button = $Interface/Conteudo/Comandos/Habilidade
@onready var defender_botao: Button = $Interface/Conteudo/Comandos/Defender
@onready var fugir_botao: Button = $Interface/Conteudo/Comandos/Recuar
@onready var registo_label: Label = $Interface/Conteudo/Registo

var _pocao_botao: Button = null
var _explorar_mina_botao: Button = null

var _rng := RandomNumberGenerator.new()
var _equipa: Array[Dictionary] = []
var _inimigos: Array[Dictionary] = []
var _indice_aventureiro: int = 0
var _alvo_inimigo: int = 0
var _ouro_saqueado: int = 0
var _fim_de_combate: bool = false
var _animando_turno: bool = false
var _tempo_anim: float = 0.0

var _cards_equipa: Array[Dictionary] = []
var _cards_inimigos: Array[Dictionary] = []
var _painel_evento: PanelContainer = null

func _ready() -> void:
	_rng.randomize()
	AudioManager.tocar_musica_area("combate", true)
	_criar_botoes_extras()
	atacar_botao.pressed.connect(_atacar)
	habilidade_botao.pressed.connect(_usar_habilidade)
	defender_botao.pressed.connect(_defender)
	fugir_botao.pressed.connect(_recuar)

	if not bool(CampaignManager.expedicao.get("ativa", false)):
		SceneRouter.ir_para(CENA_TAVERNA, Vector2(80.0, 255.0))
		return

	_equipa = CampaignManager.obter_equipa_expedicao()
	if _equipa.is_empty():
		SceneRouter.ir_para(CENA_TAVERNA, Vector2(80.0, 255.0))
		return

	for combatente in _equipa:
		combatente["defendendo"] = false

	_ouro_saqueado = int(CampaignManager.expedicao.get("ouro_saqueado", 0))
	_gerar_inimigos()
	_indice_aventureiro = _proximo_aventureiro_vivo(0)
	_atualizar_interface("⚔️ Sala %d: Clica num monstro para mirar e comanda os teus aventureiros!" % int(CampaignManager.expedicao.get("sala", 1)))

func _criar_botoes_extras() -> void:
	if acoes_box == null:
		return
	atacar_botao.custom_minimum_size = Vector2(96, 30)
	habilidade_botao.custom_minimum_size = Vector2(142, 30)
	defender_botao.custom_minimum_size = Vector2(96, 30)
	fugir_botao.custom_minimum_size = Vector2(92, 30)

	_pocao_botao = Button.new()
	_pocao_botao.name = "PocaoAlquimica"
	_pocao_botao.focus_mode = Control.FOCUS_NONE
	_pocao_botao.custom_minimum_size = Vector2(132, 30)
	_pocao_botao.add_theme_font_size_override("font_size", 11)
	_pocao_botao.text = "🧪 POÇÃO"
	_pocao_botao.pressed.connect(_usar_pocao_alquimica)
	acoes_box.add_child(_pocao_botao)
	acoes_box.move_child(_pocao_botao, 3)

	_explorar_mina_botao = Button.new()
	_explorar_mina_botao.name = "ExplorarMina"
	_explorar_mina_botao.focus_mode = Control.FOCUS_NONE
	_explorar_mina_botao.custom_minimum_size = Vector2(160, 30)
	_explorar_mina_botao.text = "⛏️ EXPLORAR MINA"
	_explorar_mina_botao.visible = false
	_explorar_mina_botao.pressed.connect(func():
		AudioManager.tocar_sfx("porta_transicao")
		SceneRouter.ir_para(CENA_DUNGEON, Vector2(320.0, 280.0))
	)
	acoes_box.add_child(_explorar_mina_botao)

func _process(delta: float) -> void:
	_tempo_anim += delta
	for info in _cards_equipa:
		var ret: TextureRect = info.get("retrato")
		var vivo: bool = bool(info.get("vivo", false))
		var ativo: bool = bool(info.get("ativo", false))
		var fase: float = float(info.get("fase", 0.0))
		if is_instance_valid(ret) and vivo:
			var freq: float = 4.2 if ativo else 2.5
			var amp: float = 0.05 if ativo else 0.025
			var sy: float = 1.0 + sin(_tempo_anim * freq + fase) * amp
			var sx: float = 1.0 - sin(_tempo_anim * freq + fase) * (amp * 0.6)
			ret.scale = Vector2(sx, sy)
			ret.rotation = sin(_tempo_anim * (freq * 0.5) + fase) * (0.045 if ativo else 0.015)

	for info in _cards_inimigos:
		var ret: TextureRect = info.get("retrato")
		var vivo: bool = bool(info.get("vivo", false))
		var alvo: bool = bool(info.get("alvo", false))
		var fase: float = float(info.get("fase", 0.0))
		if is_instance_valid(ret) and vivo:
			var freq: float = 3.8 if alvo else 2.6
			var amp: float = 0.048 if alvo else 0.028
			var sy: float = 1.0 + sin(_tempo_anim * freq + fase) * amp
			var sx: float = 1.0 - sin(_tempo_anim * freq + fase) * (amp * 0.6)
			ret.scale = Vector2(sx, sy)
			ret.rotation = sin(_tempo_anim * 2.2 + fase) * 0.035

func _gerar_inimigos() -> void:
	_inimigos.clear()
	var sala := int(CampaignManager.expedicao.get("sala", 1))
	var quantidade := mini(4, 1 + sala)
	var mult_dif: float = 0.85 if CampaignManager.dificuldade_ia == CampaignManager.DificuldadeIA.EASY else (1.0 if CampaignManager.dificuldade_ia == CampaignManager.DificuldadeIA.INTERMEDIATE else 1.15)
	for indice in range(quantidade):
		var molde: Dictionary = INIMIGOS_BASE[
			(sala + indice - 1) % INIMIGOS_BASE.size()
		]
		var vida := maxi(12, roundi(float(int(molde["vida"]) + (sala - 1) * 7 + _rng.randi_range(0, 4)) * mult_dif))
		var atq := maxi(3, roundi(float(int(molde["ataque"]) + sala - 1) * mult_dif))
		_inimigos.append({
			"nome": "%s #%d" % [molde["nome"], indice + 1],
			"tipo_base": str(molde["nome"]),
			"fraqueza": str(molde.get("fraqueza", "Guerreiro")),
			"vida_maxima": vida,
			"vida_atual": vida,
			"ataque": atq,
			"armadura": 0,
			"veneno": 0,
			"atordoado": false,
			"intencao": "ataque",
			"intencao_valor": atq,
		})
		_sortear_intencao_inimigo(_inimigos[_inimigos.size() - 1])
	_alvo_inimigo = _primeiro_inimigo_vivo()

func _sortear_intencao_inimigo(inimigo: Dictionary) -> void:
	var atq := int(inimigo.get("ataque", 5))
	var roll := _rng.randf()
	if roll < 0.45:
		inimigo["intencao"] = "ataque"
		inimigo["intencao_valor"] = atq
	elif roll < 0.68:
		inimigo["intencao"] = "pesado"
		inimigo["intencao_valor"] = roundi(float(atq) * 1.45)
	elif roll < 0.85:
		inimigo["intencao"] = "escudo"
		inimigo["intencao_valor"] = maxi(4, roundi(float(atq) * 0.85))
	else:
		inimigo["intencao"] = "veneno"
		inimigo["intencao_valor"] = maxi(3, roundi(float(atq) * 0.7))

func _texto_intencao_inimigo(inimigo: Dictionary) -> String:
	if bool(inimigo.get("atordoado", false)):
		return "💫 Atordoado (Pula)"
	var val := int(inimigo.get("intencao_valor", 0))
	match str(inimigo.get("intencao", "ataque")):
		"pesado":
			return "💢 Golpe %d" % val
		"escudo":
			return "🛡️ Escudo +%d" % val
		"veneno":
			return "🧪 Veneno %d" % val
		_:
			return "⚔️ Ataque %d" % val

func _icone_fraqueza(fraq: String) -> String:
	match fraq:
		"Arqueiro":
			return "🏹"
		"Mago":
			return "🔮"
		_:
			return "🛡️"

func _atualizar_interface(mensagem: String) -> void:
	var sala := int(CampaignManager.expedicao.get("sala", 1))
	var salas_total := int(CampaignManager.expedicao.get("salas_total", 3))
	sala_label.text = "⚔️ DUNGEON DE CANAVESES · SALA %d/%d  ·  💰 SAQUE +%d 🪙" % [sala, salas_total, _ouro_saqueado]
	estado_label.text = "Clica num inimigo para escolher o alvo · Usa habilidades de classe e poções da tua Botica!"
	registo_label.text = mensagem

	if not _fim_de_combate and _indice_aventureiro >= 0 and _indice_aventureiro < _equipa.size():
		var comb: Dictionary = _equipa[_indice_aventureiro]
		turno_label.text = "▶ VEZ DE %s (%s)  ·  ⚔️ ATQ %d  ·  💨 VEL %d" % [
			str(comb["nome"]).to_upper(),
			str(comb["profissao"]).to_upper(),
			int(comb["poder"]),
			int(comb["velocidade"])
		]
	elif _fim_de_combate:
		turno_label.text = "🏁 COMBATE ENCERRADO"

	_reconstruir_inimigos()
	_reconstruir_equipa()
	_atualizar_botoes()

func _criar_estilo_card(cor_fundo: Color, cor_borda: Color, largura_borda: int = 1) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = cor_fundo
	sb.border_color = cor_borda
	sb.set_border_width_all(largura_borda)
	sb.set_corner_radius_all(5)
	sb.content_margin_left = 5
	sb.content_margin_right = 5
	sb.content_margin_top = 4
	sb.content_margin_bottom = 4
	return sb

func _reconstruir_inimigos() -> void:
	_cards_inimigos.clear()
	for filho in inimigos_box.get_children():
		filho.queue_free()

	for indice in range(_inimigos.size()):
		var inimigo: Dictionary = _inimigos[indice]
		var vivo: bool = int(inimigo["vida_atual"]) > 0
		var eh_alvo: bool = (indice == _alvo_inimigo and vivo)

		var cor_bg := Color(0.24, 0.11, 0.11, 0.94) if eh_alvo else Color(0.12, 0.08, 0.09, 0.86)
		var cor_borda := Color(1.0, 0.42, 0.32, 1.0) if eh_alvo else (Color(0.55, 0.28, 0.28, 0.75) if vivo else Color(0.3, 0.2, 0.2, 0.4))
		var painel_card := PanelContainer.new()
		painel_card.custom_minimum_size = Vector2(138, 92)
		painel_card.add_theme_stylebox_override("panel", _criar_estilo_card(cor_bg, cor_borda, 2 if eh_alvo else 1))

		var col := VBoxContainer.new()
		col.alignment = BoxContainer.ALIGNMENT_CENTER
		col.add_theme_constant_override("separation", 2)
		painel_card.add_child(col)

		var botao := Button.new()
		botao.focus_mode = Control.FOCUS_NONE
		botao.disabled = not vivo or _fim_de_combate or _animando_turno
		botao.add_theme_font_size_override("font_size", 9)
		var marcador := "🎯 " if eh_alvo else ""
		botao.text = "%s%s (⚔️%d)" % [marcador, str(inimigo["nome"]), int(inimigo["ataque"])]
		botao.pressed.connect(_selecionar_inimigo.bind(indice))
		col.add_child(botao)

		var tipo_b := str(inimigo.get("tipo_base", "Goblin saqueador"))
		var retrato := TextureRect.new()
		retrato.custom_minimum_size = Vector2(44, 44)
		retrato.pivot_offset = Vector2(22, 22)
		retrato.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		retrato.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		retrato.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		retrato.texture = TEXTURAS_INIMIGOS.get(tipo_b, TEXTURAS_INIMIGOS["Goblin saqueador"])
		if not vivo:
			retrato.modulate = Color(0.3, 0.3, 0.3, 0.55)
		col.add_child(retrato)

		var barra_hp := ProgressBar.new()
		barra_hp.custom_minimum_size = Vector2(0, 10)
		barra_hp.max_value = maxf(1.0, float(inimigo["vida_maxima"]))
		barra_hp.value = clampf(float(inimigo["vida_atual"]), 0.0, barra_hp.max_value)
		barra_hp.show_percentage = false
		var sb_fill := StyleBoxFlat.new()
		sb_fill.bg_color = Color(0.86, 0.24, 0.24, 1.0)
		sb_fill.set_corner_radius_all(2)
		barra_hp.add_theme_stylebox_override("fill", sb_fill)
		col.add_child(barra_hp)

		var hp_txt := Label.new()
		hp_txt.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		hp_txt.add_theme_font_size_override("font_size", 9)
		if vivo:
			var arm := int(inimigo.get("armadura", 0))
			var ven := int(inimigo.get("veneno", 0))
			var extra := ""
			if arm > 0:
				extra += " 🛡️%d" % arm
			if ven > 0:
				extra += " 🧪%d" % ven
			hp_txt.text = "❤️ %d/%d%s" % [int(inimigo["vida_atual"]), int(inimigo["vida_maxima"]), extra]
		else:
			hp_txt.text = "💀 DERROTADO"
		col.add_child(hp_txt)

		if vivo:
			var int_lbl := Label.new()
			int_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			int_lbl.add_theme_font_size_override("font_size", 8)
			int_lbl.add_theme_color_override("font_color", Color(0.98, 0.86, 0.48))
			var fraq := str(inimigo.get("fraqueza", "Guerreiro"))
			int_lbl.text = "%s · Fraco %s" % [_texto_intencao_inimigo(inimigo), _icone_fraqueza(fraq)]
			col.add_child(int_lbl)

		inimigos_box.add_child(painel_card)
		_cards_inimigos.append({
			"card": painel_card,
			"retrato": retrato,
			"vivo": vivo,
			"alvo": eh_alvo,
			"fase": float(indice) * 1.7
		})

func _reconstruir_equipa() -> void:
	_cards_equipa.clear()
	for filho in equipa_box.get_children():
		filho.queue_free()

	for indice in range(_equipa.size()):
		var combatente: Dictionary = _equipa[indice]
		var vivo: bool = int(combatente["vida_atual"]) > 0
		var ativo: bool = (indice == _indice_aventureiro and not _fim_de_combate and vivo)

		var cor_bg := Color(0.20, 0.16, 0.10, 0.95) if ativo else Color(0.11, 0.09, 0.08, 0.88)
		var cor_borda := Color(1.0, 0.84, 0.32, 1.0) if ativo else (Color(0.38, 0.56, 0.38, 0.75) if vivo else Color(0.35, 0.22, 0.22, 0.45))
		var painel_card := PanelContainer.new()
		painel_card.custom_minimum_size = Vector2(138, 76)
		painel_card.add_theme_stylebox_override("panel", _criar_estilo_card(cor_bg, cor_borda, 2 if ativo else 1))

		var linha := HBoxContainer.new()
		linha.add_theme_constant_override("separation", 6)
		painel_card.add_child(linha)

		var prof := str(combatente["profissao"])
		var retrato := TextureRect.new()
		retrato.custom_minimum_size = Vector2(44, 44)
		retrato.pivot_offset = Vector2(22, 22)
		retrato.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		retrato.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		retrato.texture = TEXTURAS_HEROIS.get(prof, TEXTURAS_HEROIS["Guerreiro"])
		if not vivo:
			retrato.modulate = Color(0.35, 0.35, 0.35, 0.65)
		elif ativo:
			retrato.modulate = Color(1.12, 1.08, 0.92, 1.0)
		linha.add_child(retrato)

		var col_info := VBoxContainer.new()
		col_info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		col_info.alignment = BoxContainer.ALIGNMENT_CENTER
		col_info.add_theme_constant_override("separation", 2)

		var marcador := "▶ " if ativo else ""
		var badge := " 🛡️" if bool(combatente.get("defendendo", false)) else ""
		var item := Label.new()
		item.add_theme_font_size_override("font_size", 9)
		item.add_theme_color_override("font_color", Color(1.0, 0.92, 0.65) if ativo else Color(0.92, 0.90, 0.85))
		item.text = "%s%s%s\n%s ⚔️%d" % [marcador, str(combatente["nome"]), badge, prof, int(combatente["poder"])]
		col_info.add_child(item)

		var barra_hp := ProgressBar.new()
		barra_hp.custom_minimum_size = Vector2(0, 9)
		barra_hp.max_value = maxf(1.0, float(combatente["vida_maxima"]))
		barra_hp.value = clampf(float(combatente["vida_atual"]), 0.0, barra_hp.max_value)
		barra_hp.show_percentage = false
		var sb_fill := StyleBoxFlat.new()
		sb_fill.bg_color = Color(0.26, 0.78, 0.38, 1.0) if barra_hp.value > barra_hp.max_value * 0.35 else Color(0.88, 0.52, 0.20, 1.0)
		sb_fill.set_corner_radius_all(2)
		barra_hp.add_theme_stylebox_override("fill", sb_fill)
		col_info.add_child(barra_hp)

		var hp_txt := Label.new()
		hp_txt.add_theme_font_size_override("font_size", 9)
		hp_txt.text = "❤️ %d/%d" % [int(combatente["vida_atual"]), int(combatente["vida_maxima"])] if vivo else "💀 CAÍDO"
		col_info.add_child(hp_txt)

		linha.add_child(col_info)
		equipa_box.add_child(painel_card)
		_cards_equipa.append({
			"card": painel_card,
			"retrato": retrato,
			"vivo": vivo,
			"ativo": ativo,
			"fase": float(indice) * 1.3
		})

func _obter_pocao_disponivel_combate() -> Dictionary:
	var opcoes: Array[Dictionary] = [
		{"id": "pocao_espinheira_real", "nome": "Poção Espinheira Real", "efeito": "cura"},
		{"id": "pocao_escudo_do_lago", "nome": "Poção Escudo do Lago", "efeito": "escudo"},
		{"id": "pocao_vento_ligeiro", "nome": "Poção Vento Ligeiro", "efeito": "furia"},
		{"id": "pocao_mente_limpida", "nome": "Poção Mente Límpida", "efeito": "explosao"},
	]
	for op in opcoes:
		var q := InventoryManager.obter_quantidade(str(op["id"]))
		if q > 0:
			var copia := op.duplicate()
			copia["qtd"] = q
			return copia
	return {}

func _atualizar_botoes() -> void:
	if _fim_de_combate or _animando_turno or _indice_aventureiro < 0 or _indice_aventureiro >= _equipa.size():
		atacar_botao.disabled = true
		habilidade_botao.disabled = true
		defender_botao.disabled = true
		if _pocao_botao != null:
			_pocao_botao.disabled = true
		return

	var combatente: Dictionary = _equipa[_indice_aventureiro]
	atacar_botao.disabled = false
	habilidade_botao.disabled = false
	defender_botao.disabled = false
	fugir_botao.disabled = false
	atacar_botao.text = tr("RPG_BTN_ATACAR")
	habilidade_botao.text = "✨ " + str(combatente.get("habilidade", tr("RPG_BTN_HABILIDADE"))).to_upper()
	fugir_botao.text = tr("RPG_BTN_FUGIR")
	defender_botao.text = "🛡️ DEFENDER"

	if _pocao_botao != null:
		var poc := _obter_pocao_disponivel_combate()
		if not poc.is_empty():
			_pocao_botao.disabled = false
			_pocao_botao.text = "🧪 %s (×%d)" % [str(poc["nome"]).replace("Poção ", ""), int(poc["qtd"])]
		else:
			_pocao_botao.disabled = InventoryManager.escudos < 8
			_pocao_botao.text = "🧪 ELIXIR (8 🪙)"

func _selecionar_inimigo(indice: int) -> void:
	if indice < 0 or indice >= _inimigos.size():
		return
	if int(_inimigos[indice]["vida_atual"]) <= 0:
		return
	AudioManager.tocar_sfx("ui_click")
	_alvo_inimigo = indice
	_atualizar_interface("🎯 Alvo selecionado: %s." % _inimigos[indice]["nome"])

func _animar_investida_card(eh_heroi: bool, indice: int) -> void:
	var lista := _cards_equipa if eh_heroi else _cards_inimigos
	if indice < 0 or indice >= lista.size():
		return
	var card: Control = lista[indice].get("card")
	if not is_instance_valid(card):
		return
	var dir_y: float = -14.0 if eh_heroi else 14.0
	var tw := create_tween()
	tw.tween_property(card, "position:y", card.position.y + dir_y, 0.09)
	tw.tween_property(card, "position:y", card.position.y, 0.14)

func _animar_impacto_card(eh_heroi: bool, indice: int, texto_popup: String, cor_popup: Color) -> void:
	var lista := _cards_equipa if eh_heroi else _cards_inimigos
	if indice < 0 or indice >= lista.size():
		return
	var card: Control = lista[indice].get("card")
	var ret: TextureRect = lista[indice].get("retrato")
	if is_instance_valid(ret):
		var tw_r := create_tween()
		tw_r.tween_property(ret, "modulate", cor_popup * 1.6, 0.08)
		tw_r.tween_property(ret, "modulate", Color.WHITE, 0.18)
	if is_instance_valid(card) and interface_layer != null:
		var lbl := Label.new()
		lbl.text = texto_popup
		lbl.z_index = 40
		lbl.add_theme_font_size_override("font_size", 13)
		lbl.add_theme_color_override("font_color", cor_popup)
		lbl.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.95))
		lbl.add_theme_constant_override("shadow_offset_x", 1)
		lbl.add_theme_constant_override("shadow_offset_y", 1)
		lbl.position = card.global_position + Vector2(24, 6)
		interface_layer.add_child(lbl)
		var tw := create_tween()
		tw.set_parallel(true)
		tw.tween_property(lbl, "position:y", lbl.position.y - 26.0, 0.65)
		tw.tween_property(lbl, "modulate:a", 0.0, 0.65)
		tw.chain().tween_callback(lbl.queue_free)

func _atacar() -> void:
	if _fim_de_combate or _animando_turno:
		return
	var atacante: Dictionary = _equipa[_indice_aventureiro]
	var alvo_idx := _obter_alvo_valido()
	if alvo_idx == -1:
		return

	var prof := str(atacante["profissao"])
	if prof == "Arqueiro":
		AudioManager.tocar_sfx("especial_disparo")
	elif prof == "Mago":
		AudioManager.tocar_sfx("frasco_alquimico_explosao")
	else:
		AudioManager.tocar_sfx("corte_lamina")
		AudioManager.tocar_sfx("soco")

	_animar_investida_card(true, _indice_aventureiro)
	var dano := maxi(1, int(atacante["poder"]) + _rng.randi_range(-1, 3))
	var eh_fraq := _calcular_bonus_fraqueza(alvo_idx, prof)
	if eh_fraq:
		dano = roundi(float(dano) * 1.35)
	_aplicar_dano_inimigo(alvo_idx, dano)
	var txt_pop := "FRAQUEZA -%d ⚔️" % dano if eh_fraq else "-%d ⚔️" % dano
	_animar_impacto_card(false, alvo_idx, txt_pop, Color(1.0, 0.82, 0.25) if eh_fraq else Color(1.0, 0.38, 0.32))
	_avancar_apos_acao(
		"⚔️ %s atacou %s e causou %d de dano%s!" % [
			atacante["nome"],
			_inimigos[alvo_idx]["nome"],
			dano,
			" (FRAQUEZA!)" if eh_fraq else "",
		]
	)

func _usar_habilidade() -> void:
	if _fim_de_combate or _animando_turno:
		return
	var atacante: Dictionary = _equipa[_indice_aventureiro]
	var profissao := str(atacante["profissao"])
	var mensagem := ""

	_animar_investida_card(true, _indice_aventureiro)
	match profissao:
		"Guerreiro":
			var alvo_idx := _obter_alvo_valido()
			if alvo_idx == -1:
				return
			AudioManager.tocar_sfx("bloqueio")
			AudioManager.tocar_sfx("impacto_macico_pedra")
			atacante["defendendo"] = true
			var dano := maxi(1, int(atacante["poder"]) + 4)
			if _calcular_bonus_fraqueza(alvo_idx, "Guerreiro"):
				dano = roundi(float(dano) * 1.35)
			_aplicar_dano_inimigo(alvo_idx, dano)
			var atord := false
			if int(_inimigos[alvo_idx]["vida_atual"]) > 0 and _rng.randf() < 0.45:
				_inimigos[alvo_idx]["atordoado"] = true
				atord = true
			_animar_impacto_card(false, alvo_idx, "💫 -%d 🛡️" % dano if atord else "-%d 🛡️" % dano, Color(1.0, 0.72, 0.28))
			mensagem = "🛡️ %s usou Guarda Firme em %s (%d de dano + Escudo%s)!" % [
				atacante["nome"],
				_inimigos[alvo_idx]["nome"],
				dano,
				" + 💫 ATORDOADO" if atord else "",
			]
		"Arqueiro":
			var alvo_idx := _inimigo_mais_fraco()
			if alvo_idx == -1:
				return
			AudioManager.tocar_sfx("especial_disparo")
			AudioManager.tocar_sfx("counter_hit_bell")
			var dano := maxi(1, int(atacante["poder"]) + int(atacante["velocidade"]) + 2)
			if _calcular_bonus_fraqueza(alvo_idx, "Arqueiro"):
				dano = roundi(float(dano) * 1.35)
			_aplicar_dano_inimigo(alvo_idx, dano)
			if int(_inimigos[alvo_idx]["vida_atual"]) > 0:
				_inimigos[alvo_idx]["veneno"] = int(_inimigos[alvo_idx].get("veneno", 0)) + 3
			_animar_impacto_card(false, alvo_idx, "CRÍTICO -%d 🏹" % dano, Color(1.0, 0.88, 0.25))
			mensagem = "🏹 %s disparou Olho Certeiro em %s (%d de dano crítico + Sangramento)!" % [
				atacante["nome"],
				_inimigos[alvo_idx]["nome"],
				dano,
			]
		"Mago":
			AudioManager.tocar_sfx("frasco_alquimico_explosao")
			AudioManager.tocar_sfx("trovao_eslavo_perun")
			var dano_total := 0
			for indice in range(_inimigos.size()):
				if int(_inimigos[indice]["vida_atual"]) <= 0:
					continue
				var dano := maxi(2, int(atacante["poder"]) - 1 + _rng.randi_range(0, 3))
				if _calcular_bonus_fraqueza(indice, "Mago"):
					dano = roundi(float(dano) * 1.35)
				_aplicar_dano_inimigo(indice, dano)
				if int(_inimigos[indice]["vida_atual"]) > 0:
					_inimigos[indice]["veneno"] = int(_inimigos[indice].get("veneno", 0)) + 2
				_animar_impacto_card(false, indice, "-%d 🔥" % dano, Color(0.75, 0.52, 1.0))
				dano_total += dano
			mensagem = "🔮 %s lançou Explosão Arcana + Queimadura (%d de dano total)!" % [
				atacante["nome"],
				dano_total,
			]
		"Curandeiro":
			AudioManager.tocar_sfx("pocao_pronta")
			var aliado_idx := _aliado_mais_ferido()
			var aliado: Dictionary = _equipa[aliado_idx]
			var cura := 12 + int(atacante["poder"])
			aliado["vida_atual"] = mini(
				int(aliado["vida_maxima"]),
				int(aliado["vida_atual"]) + cura
			)
			aliado["veneno"] = 0
			_guardar_vida(aliado)
			_animar_impacto_card(true, aliado_idx, "+%d HP 🌿" % cura, Color(0.35, 1.0, 0.52))
			mensagem = "✨ %s canalizou Cura de Campo + Purificação em %s (+%d HP)!" % [
				atacante["nome"],
				aliado["nome"],
				cura,
			]
		_:
			_atacar()
			return

	_avancar_apos_acao(mensagem)

func _usar_pocao_alquimica() -> void:
	if _fim_de_combate or _animando_turno:
		return
	var atacante: Dictionary = _equipa[_indice_aventureiro]
	var poc := _obter_pocao_disponivel_combate()
	var msg := ""

	if not poc.is_empty():
		var id_p := str(poc["id"])
		var nome_p := str(poc["nome"])
		InventoryManager.remover_item(id_p, 1)
		AudioManager.tocar_sfx("pocao_magica")
		AudioManager.tocar_sfx("pocao_pronta")
		match str(poc["efeito"]):
			"cura":
				for idx in range(_equipa.size()):
					if int(_equipa[idx]["vida_atual"]) > 0:
						_equipa[idx]["vida_atual"] = mini(int(_equipa[idx]["vida_maxima"]), int(_equipa[idx]["vida_atual"]) + 20)
						_guardar_vida(_equipa[idx])
						_animar_impacto_card(true, idx, "+20 HP 🧪", Color(0.35, 1.0, 0.55))
				msg = "🧪 %s usou %s! Toda a equipa recuperou +20 HP!" % [atacante["nome"], nome_p]
			"escudo":
				for idx in range(_equipa.size()):
					if int(_equipa[idx]["vida_atual"]) > 0:
						_equipa[idx]["defendendo"] = true
						_animar_impacto_card(true, idx, "🛡️ ESCUDO", Color(0.45, 0.85, 1.0))
				msg = "🧪 %s usou %s! Toda a equipa recebeu Escudo Protetor!" % [atacante["nome"], nome_p]
			"furia":
				atacante["poder"] = int(atacante["poder"]) + 4
				atacante["velocidade"] = int(atacante["velocidade"]) + 3
				_animar_impacto_card(true, _indice_aventureiro, "+4 ATQ / +3 VEL ⚡", Color(1.0, 0.88, 0.32))
				msg = "🧪 %s bebeu %s! Recebeu +4 Poder e +3 Velocidade!" % [atacante["nome"], nome_p]
			_:
				for indice in range(_inimigos.size()):
					if int(_inimigos[indice]["vida_atual"]) > 0:
						_aplicar_dano_inimigo(indice, 14)
						_animar_impacto_card(false, indice, "-14 ⚗️", Color(0.95, 0.45, 1.0))
				msg = "🧪 %s lançou %s! Causou 14 de dano alquímico a todos os inimigos!" % [atacante["nome"], nome_p]
	else:
		if InventoryManager.escudos < 8:
			AudioManager.tocar_sfx("pechincha_falha")
			return
		InventoryManager.escudos -= 8
		AudioManager.tocar_sfx("moedas")
		AudioManager.tocar_sfx("pocao_pronta")
		for idx in range(_equipa.size()):
			if int(_equipa[idx]["vida_atual"]) > 0:
				_equipa[idx]["vida_atual"] = mini(int(_equipa[idx]["vida_maxima"]), int(_equipa[idx]["vida_atual"]) + 16)
				_guardar_vida(_equipa[idx])
				_animar_impacto_card(true, idx, "+16 HP 💚", Color(0.35, 1.0, 0.55))
		msg = "🧪 Elixir de Campo consumido (-8 🪙)! Toda a equipa recuperou +16 HP!"

	_avancar_apos_acao(msg)

func _defender() -> void:
	if _fim_de_combate or _animando_turno:
		return
	var atacante: Dictionary = _equipa[_indice_aventureiro]
	AudioManager.tocar_sfx("bloqueio")
	atacante["defendendo"] = true
	var cura_def := 4
	atacante["vida_atual"] = mini(int(atacante["vida_maxima"]), int(atacante["vida_atual"]) + cura_def)
	_guardar_vida(atacante)
	_animar_impacto_card(true, _indice_aventureiro, "🛡️ DEFESA +%d HP" % cura_def, Color(0.52, 0.86, 1.0))
	_avancar_apos_acao("🛡️ %s assumiu postura defensiva (+%d HP e dano reduzido)." % [atacante["nome"], cura_def])

func _avancar_apos_acao(mensagem: String) -> void:
	if _todos_inimigos_derrotados():
		_concluir_sala(mensagem)
		return

	var proximo := _proximo_aventureiro_vivo(_indice_aventureiro + 1)
	if proximo != -1:
		_indice_aventureiro = proximo
		_atualizar_interface(mensagem)
		return

	_executar_turno_inimigos_animado(mensagem)

func _executar_turno_inimigos_animado(mensagem_jogador: String) -> void:
	_animando_turno = true
	_atualizar_botoes()
	_atualizar_interface(mensagem_jogador + " · ⏳ Turno dos monstros...")

	var ultimo_evento: String = mensagem_jogador
	for idx_ini in range(_inimigos.size()):
		var inimigo: Dictionary = _inimigos[idx_ini]
		if int(inimigo["vida_atual"]) <= 0:
			continue

		await get_tree().create_timer(0.42).timeout
		if not is_inside_tree():
			return

		var veneno_ini := int(inimigo.get("veneno", 0))
		if veneno_ini > 0:
			_aplicar_dano_inimigo(idx_ini, veneno_ini)
			inimigo["veneno"] = maxi(0, veneno_ini - 1)
			_animar_impacto_card(false, idx_ini, "-%d 🧪" % veneno_ini, Color(0.55, 0.95, 0.35))
			if int(inimigo["vida_atual"]) <= 0:
				ultimo_evento = "🧪 %s sucumbiu ao dano contínuo!" % inimigo["nome"]
				_atualizar_interface(ultimo_evento)
				if _todos_inimigos_derrotados():
					_animando_turno = false
					_concluir_sala(ultimo_evento)
					return
				continue

		if bool(inimigo.get("atordoado", false)):
			inimigo["atordoado"] = false
			_sortear_intencao_inimigo(inimigo)
			_animar_impacto_card(false, idx_ini, "💫 ATORDOADO", Color(1.0, 0.9, 0.35))
			ultimo_evento = "💫 %s estava atordoado e perdeu o turno!" % inimigo["nome"]
			_atualizar_interface(ultimo_evento)
			continue

		var intencao := str(inimigo.get("intencao", "ataque"))
		var val_int := int(inimigo.get("intencao_valor", int(inimigo["ataque"])))
		if intencao == "escudo":
			inimigo["armadura"] = int(inimigo.get("armadura", 0)) + val_int
			AudioManager.tocar_sfx("bloqueio")
			_animar_impacto_card(false, idx_ini, "+%d 🛡️" % val_int, Color(0.45, 0.85, 1.0))
			ultimo_evento = "🛡️ %s reforçou a guarda (+%d Armadura)!" % [inimigo["nome"], val_int]
			_sortear_intencao_inimigo(inimigo)
			_atualizar_interface(ultimo_evento)
			continue

		var alvo_idx := _aventureiro_alvo_aleatorio()
		if alvo_idx == -1:
			break
		var defensor: Dictionary = _equipa[alvo_idx]
		var dano := maxi(1, val_int + _rng.randi_range(-1, 1))
		var defendeu := bool(defensor.get("defendendo", false))
		if defendeu:
			dano = maxi(1, floori(float(dano) * 0.45))
			defensor["defendendo"] = false
			AudioManager.tocar_sfx("bloqueio")
		else:
			AudioManager.tocar_sfx("impacto_macico_pedra")

		_animar_investida_card(false, idx_ini)
		defensor["vida_atual"] = maxi(0, int(defensor["vida_atual"]) - dano)
		_guardar_vida(defensor)
		_animar_impacto_card(true, alvo_idx, "-%d 💥" % dano, Color(1.0, 0.32, 0.28))

		if intencao == "veneno" and int(defensor["vida_atual"]) > 0:
			defensor["veneno"] = int(defensor.get("veneno", 0)) + 2
			ultimo_evento = "🧪 %s envenenou %s (-%d HP + Veneno)!" % [inimigo["nome"], defensor["nome"], dano]
		elif intencao == "pesado":
			ultimo_evento = "💢 %s desferiu Golpe Pesado em %s (-%d HP)." % [inimigo["nome"], defensor["nome"], dano]
		else:
			ultimo_evento = "👹 %s atacou %s (-%d HP)." % [inimigo["nome"], defensor["nome"], dano]
		if int(defensor["vida_atual"]) <= 0:
			AudioManager.tocar_sfx("lutador_ko")
			ultimo_evento += " 💀 %s caiu!" % defensor["nome"]
		_sortear_intencao_inimigo(inimigo)
		_atualizar_interface(ultimo_evento)

		if _todos_aventureiros_derrotados():
			_animando_turno = false
			_finalizar_expedicao(false, ultimo_evento + " A equipa foi derrotada e recuou para a Taverna.")
			return

	await get_tree().create_timer(0.25).timeout
	if not is_inside_tree():
		return
	for combatente in _equipa:
		combatente["defendendo"] = false
	_animando_turno = false
	_indice_aventureiro = _proximo_aventureiro_vivo(0)
	_atualizar_interface(ultimo_evento)

func _calcular_bonus_fraqueza(indice: int, profissao: String) -> bool:
	if indice < 0 or indice >= _inimigos.size():
		return false
	return str(_inimigos[indice].get("fraqueza", "")) == profissao

func _aplicar_dano_inimigo(indice: int, dano: int) -> void:
	var inimigo: Dictionary = _inimigos[indice]
	var arm := int(inimigo.get("armadura", 0))
	var dano_restante := dano
	if arm > 0:
		var absorvido := mini(arm, dano_restante)
		inimigo["armadura"] = arm - absorvido
		dano_restante -= absorvido
	inimigo["vida_atual"] = maxi(0, int(inimigo["vida_atual"]) - dano_restante)
	if int(inimigo["vida_atual"]) <= 0:
		AudioManager.tocar_sfx("ko_impact_boom")
		_ouro_saqueado += 6 + int(CampaignManager.expedicao.get("sala", 1)) * 3
		CampaignManager.expedicao["ouro_saqueado"] = _ouro_saqueado
	if int(_inimigos[_alvo_inimigo]["vida_atual"]) <= 0:
		_alvo_inimigo = _primeiro_inimigo_vivo()

func _obter_alvo_valido() -> int:
	if (
		_alvo_inimigo >= 0
		and _alvo_inimigo < _inimigos.size()
		and int(_inimigos[_alvo_inimigo]["vida_atual"]) > 0
	):
		return _alvo_inimigo
	_alvo_inimigo = _primeiro_inimigo_vivo()
	return _alvo_inimigo

func _primeiro_inimigo_vivo() -> int:
	for indice in range(_inimigos.size()):
		if int(_inimigos[indice]["vida_atual"]) > 0:
			return indice
	return -1

func _inimigo_mais_fraco() -> int:
	var melhor := -1
	var menor_vida := INF
	for indice in range(_inimigos.size()):
		var vida := int(_inimigos[indice]["vida_atual"])
		if vida > 0 and vida < menor_vida:
			menor_vida = vida
			melhor = indice
	return melhor

func _aliado_mais_ferido() -> int:
	var melhor := _indice_aventureiro
	var menor_razao := 2.0
	for indice in range(_equipa.size()):
		var c: Dictionary = _equipa[indice]
		var vida := int(c["vida_atual"])
		if vida <= 0:
			continue
		var razao := float(vida) / maxf(1.0, float(c["vida_maxima"]))
		if razao < menor_razao:
			menor_razao = razao
			melhor = indice
	return melhor

func _proximo_aventureiro_vivo(inicio: int) -> int:
	for indice in range(inicio, _equipa.size()):
		if int(_equipa[indice]["vida_atual"]) > 0:
			return indice
	return -1

func _aventureiro_alvo_aleatorio() -> int:
	var vivos: Array[int] = []
	for indice in range(_equipa.size()):
		if int(_equipa[indice]["vida_atual"]) > 0:
			vivos.append(indice)
	if vivos.is_empty():
		return -1
	return vivos[_rng.randi_range(0, vivos.size() - 1)]

func _todos_inimigos_derrotados() -> bool:
	for inimigo in _inimigos:
		if int(inimigo["vida_atual"]) > 0:
			return false
	return true

func _todos_aventureiros_derrotados() -> bool:
	for combatente in _equipa:
		if int(combatente["vida_atual"]) > 0:
			return false
	return true

func _guardar_vida(combatente: Dictionary) -> void:
	CampaignManager.atualizar_vida_expedicao(
		str(combatente["id"]),
		int(combatente["vida_atual"])
	)

func _guardar_vidas_equipa() -> void:
	for combatente in _equipa:
		_guardar_vida(combatente)

func _concluir_sala(mensagem: String) -> void:
	var sala_atual := int(CampaignManager.expedicao["sala"])
	_ouro_saqueado += 18 + sala_atual * 12
	CampaignManager.expedicao["ouro_saqueado"] = _ouro_saqueado
	AudioManager.tocar_sfx("fanfarra_vitoria")
	AudioManager.tocar_sfx("moedas")

	if CampaignManager.avancar_sala_expedicao():
		_animando_turno = true
		_atualizar_botoes()
		var nova_sala := int(CampaignManager.expedicao["sala"])
		_equipa = CampaignManager.obter_equipa_expedicao()
		for combatente in _equipa:
			combatente["defendendo"] = false
		_atualizar_interface("%s · ✨ Sala %d limpa! Escolhe o próximo passo antes da Sala %d." % [mensagem, sala_atual, nova_sala])
		_mostrar_evento_entre_salas(nova_sala)
		return

	_finalizar_expedicao(true, "🏆 VITÓRIA ÉPICA! A equipa limpou todas as 3 salas da masmorra!")

func _mostrar_evento_entre_salas(nova_sala: int) -> void:
	if _painel_evento != null and is_instance_valid(_painel_evento):
		_painel_evento.queue_free()
	if interface_layer == null:
		_prosseguir_para_proxima_sala(nova_sala, "")
		return

	_painel_evento = PanelContainer.new()
	_painel_evento.position = Vector2(120, 95)
	_painel_evento.custom_minimum_size = Vector2(400, 170)
	_painel_evento.add_theme_stylebox_override("panel", _criar_estilo_card(Color(0.09, 0.07, 0.06, 0.96), Color(0.88, 0.72, 0.34, 1.0), 2))
	interface_layer.add_child(_painel_evento)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 8)
	_painel_evento.add_child(vbox)

	var titulo := Label.new()
	titulo.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	titulo.add_theme_font_size_override("font_size", 13)
	titulo.add_theme_color_override("font_color", Color(1.0, 0.88, 0.45))
	titulo.text = "🧭 ENCONTRO ANTES DA SALA %d" % nova_sala
	vbox.add_child(titulo)

	var desc := Label.new()
	desc.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	desc.add_theme_font_size_override("font_size", 10)
	desc.text = "A equipa encontrou uma encruzilhada nas ruínas. Escolhe uma vantagem:"
	vbox.add_child(desc)

	var b1 := Button.new()
	b1.focus_mode = Control.FOCUS_NONE
	b1.text = "🔥 Fogueira Segura (+10 HP em toda a equipa)"
	b1.pressed.connect(func():
		for c in _equipa:
			if int(c["vida_atual"]) > 0:
				c["vida_atual"] = mini(int(c["vida_maxima"]), int(c["vida_atual"]) + 10)
				_guardar_vida(c)
		AudioManager.tocar_sfx("pocao_pronta")
		_prosseguir_para_proxima_sala(nova_sala, "🔥 Equipa descansou na fogueira (+10 HP)!")
	)
	vbox.add_child(b1)

	var b2 := Button.new()
	b2.focus_mode = Control.FOCUS_NONE
	b2.text = "⚒️ Pedra de Afiar (+2 Poder na expedição)"
	b2.pressed.connect(func():
		for c in _equipa:
			if int(c["vida_atual"]) > 0:
				c["poder"] = int(c["poder"]) + 2
		AudioManager.tocar_sfx("bloqueio")
		_prosseguir_para_proxima_sala(nova_sala, "⚒️ Armas afiadas! +2 Poder para toda a equipa!")
	)
	vbox.add_child(b2)

	var b3 := Button.new()
	b3.focus_mode = Control.FOCUS_NONE
	b3.text = "💎 Veio Brilhante (+18 🪙 no saque)"
	b3.pressed.connect(func():
		_ouro_saqueado += 18
		CampaignManager.expedicao["ouro_saqueado"] = _ouro_saqueado
		AudioManager.tocar_sfx("moedas")
		_prosseguir_para_proxima_sala(nova_sala, "💎 Minério extra recolhido (+18 🪙)!")
	)
	vbox.add_child(b3)

func _prosseguir_para_proxima_sala(nova_sala: int, bonus_msg: String) -> void:
	if _painel_evento != null and is_instance_valid(_painel_evento):
		_painel_evento.queue_free()
		_painel_evento = null
	_gerar_inimigos()
	_indice_aventureiro = _proximo_aventureiro_vivo(0)
	_animando_turno = false
	var prefixo := (bonus_msg + " · ") if not bonus_msg.is_empty() else ""
	_atualizar_interface("%s⚔️ SALA %d/%d: Novos inimigos surgem das profundezas!" % [prefixo, nova_sala, int(CampaignManager.expedicao.get("salas_total", 3))])

func _recuar() -> void:
	if _fim_de_combate:
		_ir_para_taverna()
		return
	AudioManager.tocar_sfx("porta_transicao")
	_finalizar_expedicao(false, "A equipa recuou estrategicamente da dungeon com parte da experiência.")

func _finalizar_expedicao(vitoria: bool, mensagem: String) -> void:
	if _fim_de_combate:
		return
	_fim_de_combate = true
	_guardar_vidas_equipa()
	CampaignManager.finalizar_expedicao(vitoria, _ouro_saqueado)
	var rel := CampaignManager.ultimo_relatorio
	_atualizar_interface(mensagem + (" · " + rel if not rel.is_empty() else ""))
	atacar_botao.visible = false
	habilidade_botao.visible = false
	defender_botao.visible = false
	if _pocao_botao != null:
		_pocao_botao.visible = false
	if _explorar_mina_botao != null:
		_explorar_mina_botao.visible = true
	fugir_botao.text = "🍺 VOLTAR À TAVERNA"
	fugir_botao.disabled = false

func _ir_para_taverna() -> void:
	AudioManager.tocar_sfx("porta_transicao")
	SceneRouter.ir_para(CENA_TAVERNA, Vector2(80.0, 255.0))
