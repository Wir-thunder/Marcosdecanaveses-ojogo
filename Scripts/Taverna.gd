extends Node2D

const CENA_COMBATE: String = "res://Cenas/DungeonCombate.tscn"
const VIDEO_DESCIDA_PATH: String = "res://Assets/Video/taverna_dungeon_descent.ogv"

static var _cutscene_descida_vista: bool = false
var _overlay_video_descida: ColorRect = null

@onready var jogador: Player = get_node_or_null("YSort/Player") if has_node("YSort/Player") else get_node_or_null("Player")
@onready var estado_label: Label = $Interface/Painel/Coluna/Estado
@onready var instrucao_label: Label = $Interface/Instrucao
@onready var fundo_popup: ColorRect = $Interface/FundoPopUp
@onready var painel: PanelContainer = $Interface/Painel
@onready var coluna_principal: VBoxContainer = $Interface/Painel/Coluna
@onready var titulo_painel: Label = $Interface/Painel/Coluna/Cabecalho/Titulo
@onready var expedicao_label: Label = $Interface/Painel/Coluna/Expedicao
@onready var titulo_esquerda: Label = $Interface/Painel/Coluna/ConteudoDuplo/ColunaEsquerda/OfertasTitulo
@onready var titulo_direita: Label = $Interface/Painel/Coluna/ConteudoDuplo/ColunaDireita/EquipaTitulo
@onready var ofertas_box: VBoxContainer = $Interface/Painel/Coluna/ConteudoDuplo/ColunaEsquerda/OfertasScroll/Ofertas
@onready var equipa_box: VBoxContainer = $Interface/Painel/Coluna/ConteudoDuplo/ColunaDireita/EquipaScroll/Equipa
@onready var relatorio_label: Label = $Interface/Painel/Coluna/Relatorio
@onready var progresso_barra: ProgressBar = $Interface/Painel/Coluna/Progresso
@onready var iniciar_botao: Button = $Interface/Painel/Coluna/Botoes/EnviarBatalha
@onready var iniciar_idle_botao: Button = $Interface/Painel/Coluna/Botoes/EnviarIdle
@onready var descansar_botao: Button = $Interface/Painel/Coluna/Botoes/ProximoTurno
@onready var fechar_botao: Button = $Interface/Painel/Coluna/Cabecalho/Fechar

var _selecionados: Dictionary = {}
var _mensagem_temporaria: String = ""
var _tempo_mensagem: float = 0.0
var _aba_atual: String = "quadro" # "quadro", "balcao", "dados"
var _barra_abas: HBoxContainer = null
var _botoes_abas: Dictionary = {}
var _ultimo_resultado_dados: String = "🎲 Lança os dados de osso contra os veteranos da mesa! Se a soma dos teus 2 dados superar a banca, recebes o DOBRO da aposta na hora!"
var _ultimo_boato: String = "🍺 Paga uma rodada de Vinho Verde à casa para ouvir segredos do vale e receber presentes de habitantes agradecidos!"
var _hud_layer: CanvasLayer = null
var _hud_label_ouro: Label = null
var _hud_label_fama: Label = null
var _hud_label_dia: Label = null

const CARDAPIO_TAVERNA: Array[Dictionary] = [
	{
		"id": "vinho_verde",
		"nome": "🍷 Caneca de Vinho Verde de Canaveses",
		"custo": 8,
		"desc": "Frescura das encostas do Tâmega. Concede +15 Vida Máxima a toda a equipa na próxima expedição e +3 Fama.",
	},
	{
		"id": "cozido_tamega",
		"nome": "🍲 Cozido Farturento do Tâmega",
		"custo": 14,
		"desc": "Prato quente fumegante. Concede +3 Poder de Ataque a todos os mercenários na próxima expedição.",
	},
	{
		"id": "hidromel_tongobriga",
		"nome": "🍯 Hidromel Celta de Tongóbriga",
		"custo": 18,
		"desc": "Receita ancestral das termas. Concede +2 Velocidade e +30% Ouro saqueado na próxima expedição!",
	},
	{
		"id": "pao_de_lo",
		"nome": "🍰 Pão-de-Ló Conventual de Canaveses",
		"custo": 10,
		"desc": "Partilha a iguaria na taverna: +12 Fama para a tua Botica e atrai novos mercenários ao Quadro!",
	}
]

func _ready() -> void:
	painel.visible = false
	fundo_popup.visible = false
	AudioManager.tocar_musica_area("taverna", CampaignManager.esta_de_noite())
	AudioManager.tocar_sfx_volume("ambiente_loja", -8.0, 0.04)
	_criar_hud_superior()
	_criar_barra_abas()
	iniciar_botao.pressed.connect(_iniciar_expedicao.bind(false))
	iniciar_idle_botao.pressed.connect(_iniciar_expedicao.bind(true))
	descansar_botao.pressed.connect(_descansar)
	fechar_botao.pressed.connect(fechar_painel)
	fundo_popup.gui_input.connect(_ao_clicar_fundo)
	CampaignManager.progresso_alterado.connect(_atualizar_tudo)
	CampaignManager.expedicao_concluida.connect(_ao_concluir_expedicao)
	_atualizar_tudo()

func _criar_hud_superior() -> void:
	if _hud_layer != null:
		return
	_hud_layer = CanvasLayer.new()
	_hud_layer.name = "HUDTavernaTop"
	add_child(_hud_layer)

	var panel_hud := PanelContainer.new()
	panel_hud.set_anchors_preset(Control.PRESET_TOP_WIDE)
	panel_hud.offset_left = 6.0
	panel_hud.offset_top = 4.0
	panel_hud.offset_right = -6.0
	panel_hud.offset_bottom = 32.0

	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.12, 0.08, 0.05, 0.92)
	style.border_color = Color(0.85, 0.68, 0.35, 0.95)
	style.set_border_width_all(1)
	style.set_corner_radius_all(3)
	style.content_margin_left = 8.0
	style.content_margin_right = 8.0
	style.content_margin_top = 2.0
	style.content_margin_bottom = 2.0
	panel_hud.add_theme_stylebox_override("panel", style)
	_hud_layer.add_child(panel_hud)

	var hbox := HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 6)
	panel_hud.add_child(hbox)

	_hud_label_dia = Label.new()
	_hud_label_dia.add_theme_font_size_override("font_size", 10)
	_hud_label_dia.add_theme_color_override("font_color", Color(1.0, 0.9, 0.7))
	hbox.add_child(_hud_label_dia)

	_hud_label_ouro = Label.new()
	_hud_label_ouro.add_theme_font_size_override("font_size", 10)
	_hud_label_ouro.add_theme_color_override("font_color", Color(1.0, 0.85, 0.4))
	hbox.add_child(_hud_label_ouro)

	_hud_label_fama = Label.new()
	_hud_label_fama.add_theme_font_size_override("font_size", 10)
	_hud_label_fama.add_theme_color_override("font_color", Color(0.9, 0.75, 1.0))
	hbox.add_child(_hud_label_fama)

	var sep := Control.new()
	sep.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hbox.add_child(sep)

	var btn_rpg := Button.new()
	btn_rpg.text = "⚔️ EXPEDIÇÃO RPG [Q]"
	btn_rpg.add_theme_font_size_override("font_size", 10)
	btn_rpg.custom_minimum_size = Vector2(120, 22)
	btn_rpg.focus_mode = Control.FOCUS_NONE
	btn_rpg.modulate = Color(1.2, 1.05, 0.75)
	btn_rpg.pressed.connect(func(): abrir_painel_modo("quadro"))
	hbox.add_child(btn_rpg)

	var btn_balcao := Button.new()
	btn_balcao.text = "🍷 BALCÃO [B]"
	btn_balcao.add_theme_font_size_override("font_size", 10)
	btn_balcao.custom_minimum_size = Vector2(84, 22)
	btn_balcao.focus_mode = Control.FOCUS_NONE
	btn_balcao.pressed.connect(func(): abrir_painel_modo("balcao"))
	hbox.add_child(btn_balcao)

	var btn_dados := Button.new()
	btn_dados.text = "🎲 DADOS [D]"
	btn_dados.add_theme_font_size_override("font_size", 10)
	btn_dados.custom_minimum_size = Vector2(78, 22)
	btn_dados.focus_mode = Control.FOCUS_NONE
	btn_dados.pressed.connect(func(): abrir_painel_modo("dados"))
	hbox.add_child(btn_dados)

	var btn_sair := Button.new()
	btn_sair.text = "🚪 SAIR"
	btn_sair.add_theme_font_size_override("font_size", 10)
	btn_sair.custom_minimum_size = Vector2(56, 22)
	btn_sair.focus_mode = Control.FOCUS_NONE
	btn_sair.pressed.connect(func():
		SceneRouter.ir_para("res://Cenas/PracaCentral.tscn", Vector2(320, 180))
	)
	hbox.add_child(btn_sair)

func _criar_barra_abas() -> void:
	if _barra_abas != null or coluna_principal == null:
		return
	_barra_abas = HBoxContainer.new()
	_barra_abas.name = "BarraAbasTaverna"
	_barra_abas.add_theme_constant_override("separation", 6)
	coluna_principal.add_child(_barra_abas)
	coluna_principal.move_child(_barra_abas, 1)

	var abas := [
		{"id": "quadro", "texto": "📜 QUADRO DE MISSÕES (RPG)"},
		{"id": "balcao", "texto": "🍷 BALCÃO DO AFONSO"},
		{"id": "dados", "texto": "🎲 DADOS & BOATOS"}
	]
	for info in abas:
		var btn := Button.new()
		btn.text = str(info["texto"])
		btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		btn.custom_minimum_size = Vector2(0, 26)
		btn.focus_mode = Control.FOCUS_NONE
		btn.add_theme_font_size_override("font_size", 11)
		var id_aba := str(info["id"])
		btn.pressed.connect(func():
			AudioManager.tocar_sfx("ui_click")
			_aba_atual = id_aba
			_atualizar_tudo()
		)
		_barra_abas.add_child(btn)
		_botoes_abas[id_aba] = btn

func _process(delta: float) -> void:
	if _tempo_mensagem > 0.0:
		_tempo_mensagem -= delta
		if _tempo_mensagem <= 0.0:
			_mensagem_temporaria = ""
			_atualizar_cabecalho()

	if painel.visible and bool(CampaignManager.expedicao.get("ativa", false)) and str(CampaignManager.expedicao.get("tipo", "")) == "idle":
		progresso_barra.value = CampaignManager.obter_progresso_expedicao() * 100.0
		var sala_atual: int = int(CampaignManager.expedicao.get("sala", 1))
		var salas_total: int = int(CampaignManager.expedicao.get("salas_total", 3))
		var t_restante: int = ceili(float(CampaignManager.expedicao.get("tempo_sala", 0.0)))
		relatorio_label.text = "⏳ Expedição em curso: Sala %d/%d (%ds para avançar)..." % [sala_atual, salas_total, t_restante]

	if painel.visible:
		instrucao_label.text = "ESC fecha · Alterna entre 📜 Missões, 🍷 Balcão e 🎲 Dados no topo"
	else:
		var alvo := jogador.obter_alvo_interacao() if jogador != null else null
		if alvo != null and alvo.has_method("obter_texto_interacao"):
			instrucao_label.text = str(alvo.call("obter_texto_interacao"))
		else:
			instrucao_label.text = "Aproxima-te do Quadro [E], Balcão [E] ou prime [Q] Missões · [B] Balcão · [D] Dados"

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel") and painel.visible:
		fechar_painel()
		get_viewport().set_input_as_handled()
		return
	elif event is InputEventKey and event.pressed and not event.echo:
		var key_event := event as InputEventKey
		match key_event.keycode:
			KEY_Q:
				if painel.visible and _aba_atual == "quadro":
					fechar_painel()
				else:
					abrir_painel_modo("quadro")
				get_viewport().set_input_as_handled()
			KEY_B:
				if painel.visible and _aba_atual == "balcao":
					fechar_painel()
				else:
					abrir_painel_modo("balcao")
				get_viewport().set_input_as_handled()
			KEY_D:
				if painel.visible and _aba_atual == "dados":
					fechar_painel()
				else:
					abrir_painel_modo("dados")
				get_viewport().set_input_as_handled()
			KEY_TAB:
				if painel.visible:
					var ordem := ["quadro", "balcao", "dados"]
					var idx := (ordem.find(_aba_atual) + 1) % ordem.size()
					_aba_atual = ordem[idx]
					AudioManager.tocar_sfx("ui_click")
					_atualizar_tudo()
					get_viewport().set_input_as_handled()

func _ao_clicar_fundo(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed:
		fechar_painel()

func obter_texto_interacao() -> String:
	return obter_texto_interacao_modo("quadro")

func obter_texto_interacao_modo(modo: String) -> String:
	if painel.visible:
		return "E  FECHAR PAINEL DA TAVERNA"
	match modo:
		"balcao":
			return "E  BALCÃO DO AFONSO (VINHO VERDE, COZIDO & VENDA DE POÇÕES)"
		"dados":
			return "E  MESA DOS DADOS CELTAS & PAGAR RODADA À TAVERNA"
		_:
			return "E  QUADRO DE CONTRATOS, MERCENÁRIOS & EXPEDIÇÕES"

func abrir_painel_modo(modo: String) -> void:
	if painel.visible and _aba_atual == modo:
		fechar_painel()
		return
	_aba_atual = modo
	painel.visible = true
	fundo_popup.visible = true
	AudioManager.tocar_sfx("abrir_balcao")
	_atualizar_tudo()

func alternar_painel() -> void:
	if painel.visible:
		fechar_painel()
	else:
		abrir_painel_modo("quadro")

func fechar_painel() -> void:
	if painel.visible:
		AudioManager.tocar_sfx("ui_click")
	painel.visible = false
	fundo_popup.visible = false

func _atualizar_tudo() -> void:
	_atualizar_cabecalho()
	_atualizar_estilo_abas()
	match _aba_atual:
		"balcao":
			_reconstruir_aba_balcao()
		"dados":
			_reconstruir_aba_dados()
		_:
			_reconstruir_ofertas()
			_reconstruir_equipa()
	_atualizar_relatorio()

func _atualizar_estilo_abas() -> void:
	for id_aba in _botoes_abas.keys():
		var btn: Button = _botoes_abas[id_aba]
		var ativo: bool = (str(id_aba) == _aba_atual)
		btn.modulate = Color(1.0, 0.95, 0.72, 1.0) if ativo else Color(0.75, 0.70, 0.62, 0.88)

func _obter_resumo_buffs_taverna() -> String:
	var partes: PackedStringArray = []
	if CampaignManager.buff_taverna_vida_extra > 0:
		partes.append("🍷 +%d HP" % CampaignManager.buff_taverna_vida_extra)
	if CampaignManager.buff_taverna_poder > 0:
		partes.append("🍲 +%d ATQ" % CampaignManager.buff_taverna_poder)
	if CampaignManager.buff_taverna_velocidade > 0:
		partes.append("🍯 +%d VEL / +30%% Ouro" % CampaignManager.buff_taverna_velocidade)
	if partes.is_empty():
		return "Sem buffs de refeição ativos"
	return "Buffs ativos: " + " · ".join(partes)

func _atualizar_cabecalho() -> void:
	var fase_texto := "NOITE" if CampaignManager.esta_de_noite() else "DIA"
	if _hud_label_dia != null:
		_hud_label_dia.text = "📅 DIA %d (%s)" % [CampaignManager.dia, fase_texto]
	if _hud_label_ouro != null:
		_hud_label_ouro.text = "🪙 %d Ouro" % InventoryManager.escudos
	if _hud_label_fama != null:
		_hud_label_fama.text = "⭐ %d Fama" % InventoryManager.renome_loja

	if _tempo_mensagem > 0.0 and not _mensagem_temporaria.is_empty():
		estado_label.text = _mensagem_temporaria
		return

	estado_label.text = "TAVERNA DO VALE · DIA %d (%s) · 🪙 %d OURO · ⭐ %d FAMA" % [
		CampaignManager.dia,
		fase_texto,
		InventoryManager.escudos,
		InventoryManager.renome_loja,
	]

func _icone_profissao(prof: String) -> String:
	match prof:
		"Guerreiro":
			return "🛡️"
		"Arqueiro":
			return "🏹"
		"Mago":
			return "🔮"
		"Curandeiro":
			return "✨"
		_:
			return "⚔️"

func _reconstruir_ofertas() -> void:
	titulo_esquerda.text = "📜 CONTRATOS DE MERCENÁRIOS"
	for filho in ofertas_box.get_children():
		filho.queue_free()

	var btn_renovar := Button.new()
	btn_renovar.text = "🔔 Tocar Sino & Chamar Novos Aventureiros (6 🪙)"
	btn_renovar.disabled = InventoryManager.escudos < 6
	btn_renovar.add_theme_font_size_override("font_size", 11)
	btn_renovar.pressed.connect(func():
		if InventoryManager.escudos < 6:
			AudioManager.tocar_sfx("pechincha_falha")
			return
		InventoryManager.escudos -= 6
		AudioManager.tocar_sfx("sino_porta")
		CampaignManager._gerar_ofertas()
		_mostrar_mensagem("🔔 Novos aventureiros chegaram à Taverna do Vale!")
		_atualizar_tudo()
	)
	ofertas_box.add_child(btn_renovar)

	if CampaignManager.ofertas.is_empty():
		var vazio := Label.new()
		vazio.text = "Não há mais mercenários disponíveis hoje. Toca o sino acima ou descansa!"
		vazio.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		ofertas_box.add_child(vazio)
		return

	for oferta in CampaignManager.ofertas:
		var linha := VBoxContainer.new()
		linha.add_theme_constant_override("separation", 3)

		var prof := str(oferta["profissao"])
		var icone := _icone_profissao(prof)
		var descricao := Label.new()
		descricao.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		descricao.add_theme_font_size_override("font_size", 11)
		descricao.text = "%s %s · %s Nv.%d\n❤️ HP %d · ⚔️ ATQ %d · 💨 VEL %d · ✨ %s" % [
			icone,
			oferta["nome"],
			prof,
			int(oferta["nivel"]),
			int(oferta.get("vida_maxima", 40)),
			int(oferta["poder"]),
			int(oferta["velocidade"]),
			oferta["habilidade"],
		]
		linha.add_child(descricao)

		var botao := Button.new()
		var preco := int(oferta["preco"])
		botao.text = "CONTRATAR POR %d 🪙" % preco
		botao.disabled = InventoryManager.escudos < preco
		botao.add_theme_font_size_override("font_size", 11)
		botao.pressed.connect(_contratar.bind(int(oferta["id"])))
		linha.add_child(botao)

		var sep := HSeparator.new()
		linha.add_child(sep)
		ofertas_box.add_child(linha)

func _reconstruir_equipa() -> void:
	titulo_direita.text = "⚔️ A TUA COMPANHIA (MÁX. 4)"
	for filho in equipa_box.get_children():
		filho.queue_free()

	var lbl_buffs := Label.new()
	lbl_buffs.text = "🍽️ " + _obter_resumo_buffs_taverna()
	lbl_buffs.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	lbl_buffs.add_theme_font_size_override("font_size", 11)
	lbl_buffs.add_theme_color_override("font_color", Color(1.0, 0.88, 0.52, 1.0))
	equipa_box.add_child(lbl_buffs)

	var ids_validos: Dictionary = {}
	for mercenario in CampaignManager.mercenarios:
		ids_validos[str(mercenario["id"])] = true
	for id in _selecionados.keys():
		if not ids_validos.has(str(id)):
			_selecionados.erase(id)

	if CampaignManager.mercenarios.is_empty():
		var vazio := Label.new()
		vazio.text = "Ainda não contrataste mercenários.\nContrata aventureiros na coluna da esquerda ou serve refeições no Balcão do Afonso!"
		vazio.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		equipa_box.add_child(vazio)
		_atualizar_botoes()
		return

	if _selecionados.is_empty():
		for indice in range(mini(4, CampaignManager.mercenarios.size())):
			var id_inicial := str(CampaignManager.mercenarios[indice]["id"])
			_selecionados[id_inicial] = true

	var expedicao_ativa := bool(CampaignManager.expedicao.get("ativa", false))
	for mercenario in CampaignManager.mercenarios:
		var id := str(mercenario["id"])
		var prof := str(mercenario["profissao"])
		var botao := CheckBox.new()
		botao.button_pressed = bool(_selecionados.get(id, false))
		botao.disabled = expedicao_ativa
		botao.add_theme_font_size_override("font_size", 11)
		botao.text = "%s %s (%s Nv.%d) · ❤️%d ⚔️%d 💨%d · XP %d/%d" % [
			_icone_profissao(prof),
			mercenario["nome"],
			prof,
			int(mercenario["nivel"]),
			int(mercenario.get("vida_maxima", 40)) + CampaignManager.buff_taverna_vida_extra,
			int(mercenario["poder"]) + CampaignManager.buff_taverna_poder,
			int(mercenario["velocidade"]) + CampaignManager.buff_taverna_velocidade,
			int(mercenario["experiencia"]),
			int(mercenario["nivel"]) * 50,
		]
		botao.toggled.connect(_alternar_mercenario.bind(id))
		equipa_box.add_child(botao)

	_atualizar_botoes()

func _reconstruir_aba_balcao() -> void:
	titulo_esquerda.text = "🍷 IGUARIAS & VINHO VERDE DO AFONSO"
	titulo_direita.text = "🧪 FORNECER POÇÕES AOS AVENTUREIROS"
	for filho in ofertas_box.get_children():
		filho.queue_free()
	for filho in equipa_box.get_children():
		filho.queue_free()

	var lbl_status := Label.new()
	lbl_status.text = "✨ " + _obter_resumo_buffs_taverna()
	lbl_status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	lbl_status.add_theme_font_size_override("font_size", 11)
	lbl_status.add_theme_color_override("font_color", Color(0.98, 0.86, 0.48))
	ofertas_box.add_child(lbl_status)

	for prato in CARDAPIO_TAVERNA:
		var id_p := str(prato["id"])
		var custo := int(prato["custo"])
		var ja_consumiu := CampaignManager.pratos_consumidos_hoje.has(id_p) and id_p != "pao_de_lo"

		var card := VBoxContainer.new()
		card.add_theme_constant_override("separation", 3)

		var lbl := Label.new()
		lbl.text = "%s (%d 🪙)\n%s" % [prato["nome"], custo, prato["desc"]]
		lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		lbl.add_theme_font_size_override("font_size", 11)
		card.add_child(lbl)

		var btn := Button.new()
		btn.add_theme_font_size_override("font_size", 11)
		if ja_consumiu:
			btn.text = "✓ JÁ SERVIDO À COMPANHIA HOJE"
			btn.disabled = true
		else:
			btn.text = "PEDIR AO AFONSO (%d 🪙)" % custo
			btn.disabled = InventoryManager.escudos < custo
		btn.pressed.connect(_comprar_prato_taverna.bind(prato))
		card.add_child(btn)
		card.add_child(HSeparator.new())
		ofertas_box.add_child(card)

	# Coluna Direita: Venda direta de poções do inventário na Taverna
	var intro_dir := Label.new()
	intro_dir.text = "Os aventureiros da taverna compram as tuas poções à noite com +25% de bónus de urgência e +4 Fama!"
	intro_dir.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	intro_dir.add_theme_font_size_override("font_size", 11)
	equipa_box.add_child(intro_dir)
	equipa_box.add_child(HSeparator.new())

	var encontrou_pocao := false
	for caminho in InventoryManager.receitas_desbloqueadas:
		var rec := load(caminho) as PotionRecipeData
		if rec == null or rec.pocao_resultante == null:
			continue
		var pocao := rec.pocao_resultante
		var qtd := InventoryManager.obter_quantidade(pocao.id)
		if qtd <= 0:
			continue
		encontrou_pocao = true
		var preco_taverna := roundi(float(pocao.valor_em_escudos) * 1.25 * InventoryManager.obter_multiplicador_preco_loja())
		var box_p := HBoxContainer.new()
		var lbl_p := Label.new()
		lbl_p.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		lbl_p.add_theme_font_size_override("font_size", 11)
		lbl_p.text = "🧪 %s (×%d)" % [pocao.nome_do_item, qtd]
		box_p.add_child(lbl_p)

		var btn_vender := Button.new()
		btn_vender.text = "Vender +%d 🪙" % preco_taverna
		btn_vender.add_theme_font_size_override("font_size", 11)
		btn_vender.pressed.connect(func():
			if InventoryManager.remover_item(pocao.id, 1):
				InventoryManager.escudos += preco_taverna
				InventoryManager.adicionar_renome(4)
				AudioManager.tocar_sfx("venda_sucesso")
				AudioManager.tocar_sfx("moedas")
				_mostrar_mensagem("🧪 Vendeste %s a um aventureiro por %d 🪙 (+4 Fama)!" % [pocao.nome_do_item, preco_taverna])
				_atualizar_tudo()
		)
		box_p.add_child(btn_vender)
		equipa_box.add_child(box_p)

	if not encontrou_pocao:
		var sem_p := Label.new()
		sem_p.text = "Não tens poções prontas na mochila.\nPrepara poções no Caldeirão da tua Botica para as venderes também aos aventureiros da Taverna!"
		sem_p.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		sem_p.add_theme_font_size_override("font_size", 11)
		equipa_box.add_child(sem_p)

	_atualizar_botoes()

func _comprar_prato_taverna(prato: Dictionary) -> void:
	var custo := int(prato["custo"])
	var id_p := str(prato["id"])
	if InventoryManager.escudos < custo:
		AudioManager.tocar_sfx("pechincha_falha")
		_mostrar_mensagem("Ouro insuficiente para pedir %s." % prato["nome"])
		return
	InventoryManager.escudos -= custo
	if not CampaignManager.pratos_consumidos_hoje.has(id_p):
		CampaignManager.pratos_consumidos_hoje.append(id_p)

	AudioManager.tocar_sfx("moedas")
	AudioManager.tocar_sfx("pocao_pronta")

	match id_p:
		"vinho_verde":
			CampaignManager.buff_taverna_vida_extra += 15
			InventoryManager.adicionar_renome(3)
			_mostrar_mensagem("🍷 Vinho Verde servido! Equipa recebe +15 HP Máx na próxima expedição (+3 Fama)!")
		"cozido_tamega":
			CampaignManager.buff_taverna_poder += 3
			_mostrar_mensagem("🍲 Cozido do Tâmega servido! Equipa recebe +3 Poder de Ataque na próxima expedição!")
		"hidromel_tongobriga":
			CampaignManager.buff_taverna_velocidade += 2
			CampaignManager.buff_taverna_ouro_mult = 1.30
			_mostrar_mensagem("🍯 Hidromel de Tongóbriga servido! +2 Velocidade e +30% Ouro na próxima expedição!")
		"pao_de_lo":
			InventoryManager.adicionar_renome(12)
			CampaignManager._gerar_ofertas()
			_mostrar_mensagem("🍰 Pão-de-Ló partilhado! +12 Fama na Botica e novos mercenários no Quadro!")

	var taberneiro := get_node_or_null("YSort/Taberneiro") if has_node("YSort/Taberneiro") else get_node_or_null("Taberneiro")
	if taberneiro != null and taberneiro.has_method("falar_brinde"):
		taberneiro.call("falar_brinde", "Sai caprichado da cozinha do Vale! Saúde, Mestre Marco!")
	_atualizar_tudo()

func _reconstruir_aba_dados() -> void:
	titulo_esquerda.text = "🎲 DADOS DE OSSO DE TONGÓBRIGA"
	titulo_direita.text = "🍻 RODADA DA CASA & BOATOS DO VALE"
	for filho in ofertas_box.get_children():
		filho.queue_free()
	for filho in equipa_box.get_children():
		filho.queue_free()

	var lbl_dados := Label.new()
	lbl_dados.text = _ultimo_resultado_dados
	lbl_dados.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	lbl_dados.add_theme_font_size_override("font_size", 11)
	ofertas_box.add_child(lbl_dados)
	ofertas_box.add_child(HSeparator.new())

	for aposta in [10, 25]:
		var btn_aposta := Button.new()
		btn_aposta.text = "🎲 Apostar %d 🪙 nos Dados (Prémio: +%d 🪙)" % [aposta, aposta * 2]
		btn_aposta.disabled = InventoryManager.escudos < aposta
		btn_aposta.add_theme_font_size_override("font_size", 11)
		btn_aposta.pressed.connect(_jogar_dados.bind(aposta))
		ofertas_box.add_child(btn_aposta)

	var lbl_boato := Label.new()
	lbl_boato.text = _ultimo_boato
	lbl_boato.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	lbl_boato.add_theme_font_size_override("font_size", 11)
	equipa_box.add_child(lbl_boato)
	equipa_box.add_child(HSeparator.new())

	var btn_rodada := Button.new()
	btn_rodada.text = "🍻 Pagar Rodada à Taverna (12 🪙 · +8 Fama + Ingrediente)"
	btn_rodada.disabled = InventoryManager.escudos < 12
	btn_rodada.add_theme_font_size_override("font_size", 11)
	btn_rodada.pressed.connect(_pagar_rodada_taverna)
	equipa_box.add_child(btn_rodada)

	_atualizar_botoes()

func _jogar_dados(aposta: int) -> void:
	if InventoryManager.escudos < aposta:
		AudioManager.tocar_sfx("pechincha_falha")
		return
	InventoryManager.escudos -= aposta
	var d1_jog := randi_range(1, 6)
	var d2_jog := randi_range(1, 6)
	var soma_jog := d1_jog + d2_jog

	var d1_mesa := randi_range(1, 6)
	var d2_mesa := randi_range(1, 6)
	var soma_mesa := d1_mesa + d2_mesa

	if soma_jog > soma_mesa:
		var ganho := aposta * 2
		InventoryManager.escudos += ganho
		AudioManager.tocar_sfx("fanfarra_vitoria")
		AudioManager.tocar_sfx("moedas")
		_ultimo_resultado_dados = "🏆 VITÓRIA NOS DADOS!\nTu rolou [%d] + [%d] = %d\nBanca rolou [%d] + [%d] = %d\nGanhaste +%d 🪙 escudos!" % [
			d1_jog, d2_jog, soma_jog, d1_mesa, d2_mesa, soma_mesa, ganho
		]
		_mostrar_mensagem("🎲 Vitória nos dados! +%d 🪙!" % aposta)
	elif soma_jog == soma_mesa:
		InventoryManager.escudos += aposta
		AudioManager.tocar_sfx("ui_click")
		_ultimo_resultado_dados = "🤝 EMPATE NA MESA!\nTu rolou [%d] + [%d] = %d\nBanca rolou [%d] + [%d] = %d\nA tua aposta de %d 🪙 foi devolvida." % [
			d1_jog, d2_jog, soma_jog, d1_mesa, d2_mesa, soma_mesa, aposta
		]
		_mostrar_mensagem("🎲 Empate nos dados! Aposta devolvida.")
	else:
		AudioManager.tocar_sfx("pechincha_falha")
		_ultimo_resultado_dados = "💀 A BANCA VENCEU!\nTu rolou [%d] + [%d] = %d\nBanca rolou [%d] + [%d] = %d\nPerdeste %d 🪙 escudos. Tenta a desforra!" % [
			d1_jog, d2_jog, soma_jog, d1_mesa, d2_mesa, soma_mesa, aposta
		]
		_mostrar_mensagem("🎲 A banca tirou %d contra os teus %d." % [soma_mesa, soma_jog])
	_atualizar_tudo()

func _pagar_rodada_taverna() -> void:
	if InventoryManager.escudos < 12:
		AudioManager.tocar_sfx("pechincha_falha")
		return
	InventoryManager.escudos -= 12
	InventoryManager.adicionar_renome(8)
	AudioManager.tocar_sfx("moedas")
	AudioManager.tocar_sfx("torcida_arena_reacao")

	var presentes := [
		{"id": "hortela_nobre", "nome": "Hortelã Nobre"},
		{"id": "arnica_selvagem", "nome": "Arnica Selvagem"},
		{"id": "calcedonia_fina", "nome": "Calcedónia Fina"},
		{"id": "erva_cidreira", "nome": "Erva-Cidreira"},
		{"id": "po_granito_tongobriga", "nome": "Pó de Granito de Tongóbriga"}
	]
	var presente: Dictionary = presentes.pick_random()
	InventoryManager.adicionar_item(str(presente["id"]), 1)

	var boatos := [
		"💬 \"Sabias que as poções da tua mochila agora podem ser usadas diretamente durante os combates na Dungeon?\"",
		"💬 \"Nas Termas Romanas e na Cripta da Pedra Formosa crescem cristais e resinas que valem ouro no caldeirão!\"",
		"💬 \"Se melhorares a Vitrine e o Balcão da tua botica com [M], os nobres de Tongóbriga pagam muito mais!\"",
		"💬 \"O Cozido do Afonso e o Hidromel deixam os mercenários imparáveis nas 3 salas da Mina Antiga!\""
	]
	_ultimo_boato = "%s\n\n🎁 Um habitante agradecido ofereceu-te 1× %s (+8 Fama na Botica)!" % [
		boatos.pick_random(),
		presente["nome"]
	]

	var brindes := [
		"Viva o Alquimista Marco!",
		"À saúde da melhor botica de Canaveses!",
		"Que o vinho verde nunca falte no Vale!",
		"Pelos heróis do Tâmega!"
	]
	for filho in get_children():
		if filho is TavernaNpc:
			(filho as TavernaNpc).falar_brinde(brindes.pick_random())

	_mostrar_mensagem("🍻 A taverna inteira brinda a ti! +8 Fama e recebeste 1× %s!" % presente["nome"])
	_atualizar_tudo()

func _atualizar_relatorio() -> void:
	var ativa := bool(CampaignManager.expedicao.get("ativa", false))
	if ativa:
		var nomes: Array = CampaignManager.expedicao.get("nomes", [])
		var tipo_exp: String = str(CampaignManager.expedicao.get("tipo", "ativa"))
		progresso_barra.value = CampaignManager.obter_progresso_expedicao() * 100.0
		if tipo_exp == "idle":
			var t_restante: int = ceili(float(CampaignManager.expedicao.get("tempo_sala", 0.0)))
			relatorio_label.text = "⏳ Expedição Automática (%s): Sala %d/%d (%ds)..." % [
				", ".join(nomes),
				CampaignManager.obter_dias_expedicao(),
				CampaignManager.obter_dias_previstos_expedicao(),
				t_restante,
			]
		else:
			relatorio_label.text = "⚔️ Expedição pronta: %s · Sala %d/%d." % [
				", ".join(nomes),
				CampaignManager.obter_dias_expedicao(),
				CampaignManager.obter_dias_previstos_expedicao(),
			]
		return

	progresso_barra.value = 0.0
	if not CampaignManager.ultimo_relatorio.is_empty():
		relatorio_label.text = "🏆 " + CampaignManager.ultimo_relatorio
	else:
		relatorio_label.text = "Equipa os teus mercenários, serve-lhes uma refeição no Balcão e parte para a Dungeon!"

func _atualizar_botoes() -> void:
	var ativa := bool(CampaignManager.expedicao.get("ativa", false))
	var tipo_exp := str(CampaignManager.expedicao.get("tipo", ""))
	var ids := _ids_selecionados()
	if ativa and tipo_exp != "idle":
		iniciar_botao.disabled = false
		iniciar_botao.text = "⚔️ CONTINUAR COMBATE RPG"
		iniciar_botao.modulate = Color(1.2, 1.0, 0.7)
		iniciar_idle_botao.disabled = true
	elif ativa and tipo_exp == "idle":
		iniciar_botao.disabled = true
		iniciar_botao.text = "EM EXPEDIÇÃO AUTOMÁTICA..."
		iniciar_botao.modulate = Color(0.8, 0.8, 0.8)
		iniciar_idle_botao.disabled = true
	else:
		var sem_equipa := ids.is_empty() or ids.size() > 4
		iniciar_botao.disabled = sem_equipa
		if sem_equipa:
			iniciar_botao.text = "❌ SELECIONA 1 A 4 MERCENÁRIOS"
			iniciar_botao.modulate = Color(0.8, 0.8, 0.8)
		else:
			iniciar_botao.text = "⚔️ ENTRAR NO COMBATE RPG (%d/4)" % ids.size()
			iniciar_botao.modulate = Color(1.2, 1.05, 0.65)
		iniciar_idle_botao.disabled = sem_equipa
		iniciar_idle_botao.text = "⏳ EXPEDIÇÃO IDLE"
	descansar_botao.disabled = false

func _contratar(id_oferta: int) -> void:
	if CampaignManager.contratar_mercenario(id_oferta):
		AudioManager.tocar_sfx("moedas")
		AudioManager.tocar_sfx("confirmar_lutador_gongo")
		for mercenario in CampaignManager.mercenarios:
			if int(mercenario["id"]) == id_oferta and _ids_selecionados().size() < 4:
				_selecionados[str(id_oferta)] = true
		_mostrar_mensagem("⚔️ Mercenário contratado para a tua companhia!")
	else:
		AudioManager.tocar_sfx("pechincha_falha")
		_mostrar_mensagem("Não tens ouro suficiente para contratar este mercenário.")
	_atualizar_tudo()

func _alternar_mercenario(ativo: bool, id_mercenario: String) -> void:
	AudioManager.tocar_sfx("ui_click")
	if ativo and _ids_selecionados().size() >= 4:
		_selecionados.erase(id_mercenario)
		_mostrar_mensagem("A equipa pode ter no máximo 4 mercenários.")
		_reconstruir_equipa()
		return
	if ativo:
		_selecionados[id_mercenario] = true
	else:
		_selecionados.erase(id_mercenario)
	_atualizar_botoes()

func _ids_selecionados() -> Array[String]:
	var ids: Array[String] = []
	for id in _selecionados.keys():
		if bool(_selecionados[id]):
			ids.append(str(id))
	return ids

func _iniciar_expedicao(modo_idle: bool = false) -> void:
	if bool(CampaignManager.expedicao.get("ativa", false)):
		if str(CampaignManager.expedicao.get("tipo", "")) != "idle":
			AudioManager.tocar_sfx("porta_transicao")
			_entrar_combate_com_cutscene()
		return
	if CampaignManager.iniciar_expedicao(_ids_selecionados(), modo_idle):
		if modo_idle:
			AudioManager.tocar_sfx("carnyx_trombeta_gaulesa")
			_mostrar_mensagem("⏳ A equipa partiu em expedição automática!")
			_atualizar_tudo()
		else:
			AudioManager.tocar_sfx("carnyx_trombeta_gaulesa")
			_entrar_combate_com_cutscene()
	else:
		AudioManager.tocar_sfx("pechincha_falha")
		_mostrar_mensagem("Seleciona entre 1 e 4 mercenários.")

func _entrar_combate_com_cutscene() -> void:
	if _cutscene_descida_vista or not FileAccess.file_exists(VIDEO_DESCIDA_PATH):
		get_tree().change_scene_to_file(CENA_COMBATE)
		return
	_cutscene_descida_vista = true
	var hud := get_node_or_null("Interface") as CanvasLayer
	if hud == null:
		get_tree().change_scene_to_file(CENA_COMBATE)
		return
	if _overlay_video_descida != null and is_instance_valid(_overlay_video_descida):
		_overlay_video_descida.queue_free()

	_overlay_video_descida = ColorRect.new()
	_overlay_video_descida.color = Color(0.02, 0.02, 0.02, 0.98)
	_overlay_video_descida.set_anchors_preset(Control.PRESET_FULL_RECT)
	hud.add_child(_overlay_video_descida)

	var stream := VideoStreamTheora.new()
	stream.file = VIDEO_DESCIDA_PATH
	var vp := VideoStreamPlayer.new()
	vp.stream = stream
	vp.expand = true
	vp.set_anchors_preset(Control.PRESET_FULL_RECT)
	var ir_combate := func():
		if is_inside_tree():
			get_tree().change_scene_to_file(CENA_COMBATE)
	vp.finished.connect(ir_combate)
	_overlay_video_descida.add_child(vp)
	vp.play()

	var btn_pular := Button.new()
	btn_pular.focus_mode = Control.FOCUS_NONE
	btn_pular.text = "⏩ PULAR"
	btn_pular.position = Vector2(548, 322)
	btn_pular.pressed.connect(ir_combate)
	_overlay_video_descida.add_child(btn_pular)

func _descansar() -> void:
	AudioManager.tocar_sfx("porta_transicao")
	CampaignManager.descansar_e_avancar_dia()

func _ao_concluir_expedicao(relatorio: String) -> void:
	AudioManager.tocar_sfx("fanfarra_vitoria")
	_mostrar_mensagem(relatorio)
	_atualizar_tudo()

func _mostrar_mensagem(texto: String) -> void:
	_mensagem_temporaria = texto
	_tempo_mensagem = 3.5
	_atualizar_cabecalho()
