extends Node2D

const CENA_CLIENTE: PackedScene = preload("res://Cenas/ClienteNPC.tscn")
const INGREDIENTES_INICIAIS: Array[ItemData] = [
	preload("res://Recursos/Recursos_ingredientes/hortela_nobre.tres"),
	preload("res://Recursos/Recursos_ingredientes/musgo_aboboreira.tres"),
	preload("res://Recursos/Recursos_ingredientes/arnica_selvagem.tres"),
	preload("res://Recursos/Recursos_ingredientes/calcedonia_fina.tres"),
	preload("res://Recursos/Recursos_ingredientes/erva_cidreira.tres"),
	preload("res://Recursos/Recursos_ingredientes/po_granito_tongobriga.tres"),
	preload("res://Recursos/Recursos_ingredientes/azeite_do_olival.tres"),
]
const POCOES: Array[ItemData] = [
	preload("res://Recursos/Recursos_pocoes/pocao_vento_ligeiro.tres"),
	preload("res://Recursos/Recursos_pocoes/pocao_espinheira_real.tres"),
	preload("res://Recursos/Recursos_pocoes/pocao_mente_limpida.tres"),
	preload("res://Recursos/Recursos_pocoes/pocao_escudo_do_lago.tres"),
]

@onready var jogador: Player = $Player
@onready var balcao: BalcaoAtendimento = $Balcao
@onready var caldeirao: Caldeirao = $Caldeirao
@onready var fornecedor: Fornecedor = $Fornecedor
@onready var prateleira: PrateleiraExibicao = get_node_or_null("PrateleiraExibicao")
@onready var painel_atendimento: PainelAtendimentoBalcao = get_node_or_null("PainelAtendimento")
@onready var temporizador_cliente: Timer = $TemporizadorCliente
@onready var estado_label: Label = $Interface/Painel/Margem/Coluna/Estado
@onready var receita_label: Label = $Interface/Rodape/Margem/Coluna/Receita
@onready var inventario_label: Label = $Interface/Rodape/Margem/Coluna/Inventario
@onready var instrucoes_label: Label = $Interface/Rodape/Margem/Coluna/Instrucoes
@onready var barra_pocoes: HBoxContainer = $Interface/BarraPocoes
@onready var temporizador_feedback: Timer = $TemporizadorFeedback
@onready var pausa_overlay: CanvasLayer = $Pausa
@onready var botao_retomar: Button = $Pausa/Painel/Margem/Coluna/Retomar
@onready var botao_reiniciar: Button = $Pausa/Painel/Margem/Coluna/Reiniciar
@onready var botao_sair: Button = $Pausa/Painel/Margem/Coluna/Sair

var estado_padrao: String = ""
var clientes_ativos: Array[ClienteNPC] = []
var clientes_gerados: int = 0
var _tipos_visuais_do_turno: Array[int] = [0, 1, 2, 3, 4]
var _painel_obras: Control = null
var _painel_grimorio: Control = null
var _painel_mercador: Control = null
var _botao_obras: Button = null
var _botao_grimorio: Button = null
var _botao_mercador: Button = null
var _ultimo_dia_tendencia: int = -1
var _reconstruindo_botoes_pocoes: bool = false
var _objetivo_label: Label = null

func _ready() -> void:
	_tipos_visuais_do_turno.shuffle()
	clientes_gerados = CampaignManager.clientes_gerados_hoje
	_inicializar_inventario()
	_sincronizar_pocoes_desbloqueadas()
	if _ultimo_dia_tendencia != CampaignManager.dia:
		_ultimo_dia_tendencia = CampaignManager.dia
		InventoryManager.sortear_tendencia_diaria()
	_aplicar_estilo_hud_loja()
	_criar_etiquetas_estacoes_mundo()
	_atualizar_visuais_loja()

	balcao.feedback.connect(_mostrar_feedback)
	caldeirao.feedback.connect(_mostrar_feedback)
	fornecedor.feedback.connect(_mostrar_feedback)
	if prateleira != null:
		prateleira.feedback.connect(_mostrar_feedback)
	if painel_atendimento != null:
		balcao.painel_atendimento = painel_atendimento
		painel_atendimento.atendimento_concluido.connect(func(_suc: bool, msg: String): _mostrar_feedback(msg))
	caldeirao.receita_alterada.connect(_ao_alterar_receita)
	jogador.pocao_selecionada_alterada.connect(_ao_selecionar_pocao)
	jogador.pocao_indisponivel.connect(_ao_pocao_indisponivel)
	if not InventoryManager.loja_melhorada.is_connected(_ao_loja_melhorada):
		InventoryManager.loja_melhorada.connect(_ao_loja_melhorada)
	if not InventoryManager.mestria_desbloqueada.is_connected(_ao_mestria_desbloqueada):
		InventoryManager.mestria_desbloqueada.connect(_ao_mestria_desbloqueada)
	pausa_overlay.connect("escape_pressed", _alternar_pausa)
	temporizador_cliente.timeout.connect(_criar_cliente)
	CampaignManager.fase_alterada.connect(_ao_alterar_fase)
	if not CampaignManager.idioma_alterado.is_connected(_on_idioma_alterado):
		CampaignManager.idioma_alterado.connect(_on_idioma_alterado)
	temporizador_feedback.one_shot = true
	_criar_botoes_pocoes()
	_criar_botao_obras_hud()
	_desativar_foco_hud($Interface)
	botao_retomar.pressed.connect(retomar_jogo)
	botao_reiniciar.pressed.connect(reiniciar_jogo)
	botao_sair.pressed.connect(sair_do_jogo)
	var max_cli := InventoryManager.obter_max_clientes_turno()
	if CampaignManager.fase == CampaignManager.Fase.LOJA and clientes_gerados < max_cli:
		temporizador_cliente.start(2.0)
	else:
		temporizador_cliente.stop()
	_atualizar_textos_idioma()
	AudioManager.tocar_musica_area("loja", CampaignManager.esta_de_noite())
	AudioManager.tocar_sfx_volume("ambiente_loja", -9.0, 0.04)
	_atualizar_receita()

func _ao_alterar_dia(_novo_dia: int) -> void:
	_ultimo_dia_tendencia = _novo_dia
	var tend := InventoryManager.sortear_tendencia_diaria()
	_atualizar_visuais_loja()
	_reconstruir_botoes_pocoes()
	_mostrar_feedback("🔥 Tendência do Dia %d: %s (+35%% Ouro)!" % [_novo_dia, str(tend.get("nome", ""))])

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		var k := (event as InputEventKey).physical_keycode
		if k == KEY_M:
			_alternar_painel_obras()
			get_viewport().set_input_as_handled()
		elif k == KEY_C:
			_alternar_painel_grimorio()
			get_viewport().set_input_as_handled()
		elif k == KEY_V:
			_alternar_painel_mercador()
			get_viewport().set_input_as_handled()

func _sincronizar_pocoes_desbloqueadas() -> void:
	var lista: Array[ItemData] = []
	for caminho in InventoryManager.receitas_desbloqueadas:
		if not ResourceLoader.exists(caminho):
			continue
		var rec := load(caminho) as PotionRecipeData
		if rec != null and rec.pocao_resultante != null:
			var ja_tem := false
			for p in lista:
				if p != null and p.id == rec.pocao_resultante.id:
					ja_tem = true
					break
			if not ja_tem:
				lista.append(rec.pocao_resultante)
	if lista.is_empty():
		lista.append(POCOES[0])
	jogador.pocoes_disponiveis = lista
	if jogador.pocao_ativa == null or not lista.has(jogador.pocao_ativa):
		jogador.pocao_ativa = lista[0]

func _ao_loja_melhorada(_id_upgrade: String, _novo_nivel: int) -> void:
	_sincronizar_pocoes_desbloqueadas()
	_reconstruir_botoes_pocoes()
	_atualizar_visuais_loja()
	_atualizar_receita()

func _ao_mestria_desbloqueada(_pocao_id: String, _nova_receita_caminho: String, _nome_nova: String) -> void:
	_sincronizar_pocoes_desbloqueadas()
	_reconstruir_botoes_pocoes()
	_atualizar_receita()

func _aplicar_estilo_hud_loja() -> void:
	var painel_topo := get_node_or_null("Interface/Painel") as PanelContainer
	if painel_topo != null:
		var st_topo := StyleBoxFlat.new()
		st_topo.bg_color = Color(0.09, 0.07, 0.05, 0.93)
		st_topo.border_color = Color(0.78, 0.60, 0.26, 0.96)
		st_topo.set_border_width_all(1)
		st_topo.border_width_bottom = 2
		st_topo.set_corner_radius_all(5)
		st_topo.shadow_color = Color(0, 0, 0, 0.45)
		st_topo.shadow_size = 4
		painel_topo.add_theme_stylebox_override("panel", st_topo)

	var painel_rodape := get_node_or_null("Interface/Rodape") as PanelContainer
	if painel_rodape != null:
		var st_rod := StyleBoxFlat.new()
		st_rod.bg_color = Color(0.09, 0.07, 0.05, 0.93)
		st_rod.border_color = Color(0.72, 0.54, 0.24, 0.95)
		st_rod.set_border_width_all(1)
		st_rod.border_width_top = 2
		st_rod.set_corner_radius_all(5)
		painel_rodape.add_theme_stylebox_override("panel", st_rod)

	var hud := get_node_or_null("Interface") as CanvasLayer
	if hud != null and not hud.has_node("ObjetivoBadge"):
		var badge := PanelContainer.new()
		badge.name = "ObjetivoBadge"
		badge.position = Vector2(12, 92)
		badge.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var st_obj := StyleBoxFlat.new()
		st_obj.bg_color = Color(0.09, 0.07, 0.05, 0.90)
		st_obj.border_color = Color(0.78, 0.60, 0.26, 0.92)
		st_obj.set_border_width_all(1)
		st_obj.set_corner_radius_all(4)
		badge.add_theme_stylebox_override("panel", st_obj)

		var marg := MarginContainer.new()
		marg.mouse_filter = Control.MOUSE_FILTER_IGNORE
		marg.add_theme_constant_override("margin_left", 8)
		marg.add_theme_constant_override("margin_right", 8)
		marg.add_theme_constant_override("margin_top", 2)
		marg.add_theme_constant_override("margin_bottom", 2)
		badge.add_child(marg)

		_objetivo_label = Label.new()
		_objetivo_label.name = "Texto"
		_objetivo_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_objetivo_label.add_theme_font_size_override("font_size", 9)
		_objetivo_label.add_theme_color_override("font_color", Color(0.98, 0.88, 0.56, 1.0))
		_objetivo_label.add_theme_color_override("font_outline_color", Color(0.04, 0.03, 0.02, 0.95))
		_objetivo_label.add_theme_constant_override("outline_size", 2)
		marg.add_child(_objetivo_label)
		hud.add_child(badge)

func _criar_etiquetas_estacoes_mundo() -> void:
	var estacoes := [
		{"no": caldeirao, "texto": "⚗️ Caldeirão [E / C]", "pos": Vector2(-52, -48), "cor": Color(0.75, 0.96, 0.72)},
		{"no": fornecedor, "texto": "🛒 Mercador [E / V]", "pos": Vector2(-52, -46), "cor": Color(0.98, 0.88, 0.55)},
		{"no": balcao, "texto": "🛎️ Balcão [E]", "pos": Vector2(-42, -38), "cor": Color(1.0, 0.94, 0.76)},
	]
	for info in estacoes:
		var alvo: Node2D = info["no"]
		if alvo == null or alvo.has_node("EtiquetaEstacao"):
			continue
		var lbl := Label.new()
		lbl.name = "EtiquetaEstacao"
		lbl.text = str(info["texto"])
		lbl.position = info["pos"]
		lbl.custom_minimum_size = Vector2(104, 16)
		lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		lbl.add_theme_font_size_override("font_size", 8)
		lbl.add_theme_color_override("font_color", info["cor"])
		lbl.add_theme_color_override("font_outline_color", Color(0.05, 0.03, 0.02, 0.95))
		lbl.add_theme_constant_override("outline_size", 2)
		lbl.z_index = 6
		alvo.add_child(lbl)

func _atualizar_visuais_loja() -> void:
	var titulo_lbl := get_node_or_null("Interface/Painel/Margem/Coluna/Titulo") as Label
	if titulo_lbl != null:
		var nome_tend := InventoryManager.nome_pocao_tendencia_dia.replace("Poção ", "")
		titulo_lbl.text = tr("LOJA_TRENDING") % [
			InventoryManager.obter_titulo_fama().to_upper(),
			InventoryManager.obter_soma_niveis_loja(),
			nome_tend.to_upper()
		]
	var spr_balcao := get_node_or_null("Balcao/Sprite2D") as Sprite2D
	if spr_balcao != null:
		match InventoryManager.nivel_balcao:
			1:
				spr_balcao.modulate = Color(0.78, 0.70, 0.62, 1.0) # Tábuas velhas
			2:
				spr_balcao.modulate = Color(1.0, 0.94, 0.86, 1.0) # Carvalho reformado
			_:
				spr_balcao.modulate = Color(1.16, 1.06, 0.84, 1.0) # Balcão Nobre dourado
	var spr_fundo := get_node_or_null("Sprite2D") as Sprite2D
	if spr_fundo != null:
		var soma := InventoryManager.obter_soma_niveis_loja()
		if soma <= 5:
			spr_fundo.modulate = Color(0.84, 0.80, 0.76, 1.0) # Aspecto mais rústico/gasto no início
		elif soma <= 9:
			spr_fundo.modulate = Color(0.96, 0.94, 0.90, 1.0)
		else:
			spr_fundo.modulate = Color(1.05, 1.02, 0.96, 1.0) # Botica próspera e iluminada

func _process(_delta: float) -> void:
	if get_tree().paused:
		return

	var max_cli := InventoryManager.obter_max_clientes_turno()
	var pocao_texto := "Nenhuma"
	var quantidade := 0
	if jogador.pocao_ativa != null:
		pocao_texto = jogador.pocao_ativa.nome_do_item
		quantidade = InventoryManager.obter_quantidade(jogador.pocao_ativa.id)

	var pedido_texto := "Clientes: %d/%d" % [clientes_gerados, max_cli]
	var cliente := balcao.obter_cliente_atual()
	if cliente != null and cliente.item_desejado != null:
		pedido_texto = "N%d · PEDIDO: %s · %ds · %d ouro" % [
			cliente.nivel_cliente,
			cliente.item_desejado.nome_do_item,
			ceili(cliente.timer_paciencia.time_left),
			cliente.calcular_preco(cliente.item_desejado),
		]
	elif not clientes_ativos.is_empty():
		pedido_texto = "Clientes a chegar/atender · %d/%d" % [clientes_gerados, max_cli]

	if CampaignManager.fase == CampaignManager.Fase.MANHA:
		estado_padrao = (tr("LOJA_EST_MANHA") % [CampaignManager.dia]) + "\n%s %d 🪙 · %s %d · %s %s ×%d" % [
			tr("LOJA_OURO"), jogador.escudos,
			tr("LOJA_FAMA"), InventoryManager.renome_loja,
			tr("LOJA_POCAO"), pocao_texto,
			quantidade,
		]
	elif CampaignManager.fase == CampaignManager.Fase.NOITE:
		estado_padrao = (tr("LOJA_EST_NOITE") % [CampaignManager.dia, clientes_gerados, max_cli]) + "\n%s %d 🪙 · %s %d · %s %s ×%d" % [
			tr("LOJA_OURO"), jogador.escudos,
			tr("LOJA_FAMA"), InventoryManager.renome_loja,
			tr("LOJA_POCAO"), pocao_texto,
			quantidade,
		]
	else:
		estado_padrao = "%s %d · %s · %s %d 🪙 · %s %d · %s %s ×%d\n%s" % [
			tr("EXP_DIA"),
			CampaignManager.dia,
			_formata_tempo(CampaignManager.tempo_turno),
			tr("LOJA_OURO"), jogador.escudos,
			tr("LOJA_FAMA"), InventoryManager.renome_loja,
			tr("LOJA_POCAO"), pocao_texto,
			quantidade,
			pedido_texto,
		]
	if temporizador_feedback.is_stopped():
		estado_label.text = estado_padrao
	_atualizar_objetivo_hud()
	inventario_label.text = "%s · %s" % [
		_resumo_inventario(),
		_resumo_fornecedor(),
	]
	receita_label.text = _resumo_receita()
	_atualizar_botoes_pocoes()

	var alvo := jogador.obter_alvo_interacao()
	instrucoes_label.text = _obter_instrucao_contextual(alvo)

func _atualizar_objetivo_hud() -> void:
	if _objetivo_label == null:
		return
	if CampaignManager.fase == CampaignManager.Fase.MANHA:
		_objetivo_label.text = tr("LOJA_OBJ_MANHA")
	elif CampaignManager.fase == CampaignManager.Fase.NOITE:
		_objetivo_label.text = tr("LOJA_OBJ_NOITE")
	else:
		_objetivo_label.text = tr("LOJA_OBJ_ATENDER")

func _inicializar_inventario() -> void:
	if not InventoryManager.inventario.is_empty():
		return
	# Começa quebrado/humilde: apenas alguns ingredientes básicos e 1 poção de Vento Ligeiro
	InventoryManager.adicionar_item("hortela_nobre", 3)
	InventoryManager.adicionar_item("musgo_aboboreira", 3)
	InventoryManager.adicionar_item("arnica_selvagem", 2)
	InventoryManager.adicionar_item("pocao_vento_ligeiro", 1)

func _obter_nome_curto_pocao(pocao: ItemData) -> String:
	if pocao == null:
		return "Poção"
	var mapa := {
		"pocao_vento_ligeiro": "Vento",
		"pocao_espinheira_real": "Cura",
		"pocao_mente_limpida": "Mente",
		"pocao_escudo_do_lago": "Escudo",
		"pocao_rio_ensolarado": "Rio Sol",
		"pocao_fogo_do_paineiro": "Fogo",
		"pocao_sono_puro": "Sono",
		"pocao_pele_de_ferro": "Ferro",
		"pocao_pedra_viva": "Pedra",
		"pocao_furia_do_trigo": "Fúria",
		"elixir_da_flor": "Elixir Flor",
		"pocao_ascensao_dourada": "Ascensão"
	}
	return str(mapa.get(pocao.id, pocao.nome_do_item.replace("Poção ", "")))

func _resumo_inventario() -> String:
	var linhas: PackedStringArray = ["STOCK"]
	for indice in range(jogador.pocoes_disponiveis.size()):
		var pocao: ItemData = jogador.pocoes_disponiveis[indice]
		if pocao != null:
			linhas.append("%s %d" % [_obter_nome_curto_pocao(pocao), InventoryManager.obter_quantidade(pocao.id)])
	return "  |  ".join(linhas)

func _resumo_receita() -> String:
	return "RECEITA  " + caldeirao.obter_resumo_receita()

func _atualizar_receita() -> void:
	receita_label.text = _resumo_receita()

func _resumo_fornecedor() -> String:
	var ingrediente := fornecedor.obter_ingrediente_selecionado()
	if ingrediente != null:
		return "%s %d · preço %d ouro" % [
			ingrediente.nome_do_item,
			InventoryManager.obter_quantidade(ingrediente.id),
			fornecedor.custo_por_ingrediente,
		]
	return "FORNECEDOR indisponível"

func _formata_tempo(segundos: float) -> String:
	var minutos := floori(segundos / 60.0)
	var segundos_restantes := int(segundos) % 60
	return "%02d:%02d" % [minutos, segundos_restantes]

func _mostrar_feedback(mensagem: String) -> void:
	estado_label.text = mensagem
	temporizador_feedback.start(2.5)

func _ao_alterar_receita(_receita: PotionRecipeData) -> void:
	_atualizar_receita()

func _ao_selecionar_pocao(_pocao: ItemData) -> void:
	if not is_node_ready():
		return
	temporizador_feedback.stop()
	_atualizar_botoes_pocoes()

func _ao_pocao_indisponivel(pocao: ItemData) -> void:
	_mostrar_feedback("Não tens unidades de %s." % pocao.nome_do_item)

func _reconstruir_botoes_pocoes() -> void:
	if barra_pocoes == null or _reconstruindo_botoes_pocoes:
		return
	_reconstruindo_botoes_pocoes = true
	for c in barra_pocoes.get_children():
		barra_pocoes.remove_child(c)
		c.queue_free()
	_criar_botoes_pocoes()
	_atualizar_conteudo_botoes_pocoes()
	_reconstruindo_botoes_pocoes = false

func _criar_botoes_pocoes() -> void:
	var tex_btn_normal: Texture2D = preload("res://Assets/UI/botao_madeira_normal.png")
	var tex_btn_hover: Texture2D = preload("res://Assets/UI/botao_madeira_hover.png")
	var tex_btn_pressed: Texture2D = preload("res://Assets/UI/botao_madeira_pressed.png")
	var fonte_medieval: FontFile = preload("res://Assets/Fonts/MedievalSharp.ttf")

	for indice in range(jogador.pocoes_disponiveis.size()):
		var pocao := jogador.pocoes_disponiveis[indice]
		if pocao == null:
			continue
		var botao := Button.new()
		botao.focus_mode = Control.FOCUS_NONE
		botao.custom_minimum_size = Vector2(0.0, 24.0)
		botao.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		botao.toggle_mode = true
		botao.icon = pocao.icone
		botao.expand_icon = true
		botao.add_theme_font_override("font", fonte_medieval)
		botao.add_theme_font_size_override("font_size", 9 if jogador.pocoes_disponiveis.size() > 5 else 10)
		botao.add_theme_color_override("font_color", Color(0.95, 0.90, 0.78, 1))
		botao.add_theme_color_override("font_hover_color", Color(1, 0.96, 0.82, 1))
		botao.add_theme_color_override("font_pressed_color", Color(1, 0.95, 0.55, 1))
		botao.add_theme_stylebox_override("normal", _estilo_textura_pocao(tex_btn_normal))
		botao.add_theme_stylebox_override("hover", _estilo_textura_pocao(tex_btn_hover))
		botao.add_theme_stylebox_override("pressed", _estilo_textura_pocao(tex_btn_pressed))
		botao.add_theme_stylebox_override("disabled", _estilo_textura_pocao(tex_btn_normal))
		botao.pressed.connect(_selecionar_pocao_indice.bind(indice))
		barra_pocoes.add_child(botao)

func _criar_botao_obras_hud() -> void:
	var controles_tempo := get_node_or_null("Interface/ControlesTempo") as HBoxContainer
	if controles_tempo == null:
		return
	controles_tempo.offset_left = 265.0

	_botao_grimorio = Button.new()
	_botao_grimorio.name = "BotaoGrimorio"
	_botao_grimorio.focus_mode = Control.FOCUS_NONE
	_botao_grimorio.custom_minimum_size = Vector2(82.0, 20.0)
	_botao_grimorio.add_theme_font_size_override("font_size", 8)
	_botao_grimorio.text = tr("LOJA_BTN_GRIMORIO")
	_botao_grimorio.modulate = Color(0.76, 0.98, 0.82, 1.0)
	_botao_grimorio.pressed.connect(_alternar_painel_grimorio)
	controles_tempo.add_child(_botao_grimorio)
	controles_tempo.move_child(_botao_grimorio, 0)

	_botao_mercador = Button.new()
	_botao_mercador.name = "BotaoMercador"
	_botao_mercador.focus_mode = Control.FOCUS_NONE
	_botao_mercador.custom_minimum_size = Vector2(84.0, 20.0)
	_botao_mercador.add_theme_font_size_override("font_size", 8)
	_botao_mercador.text = tr("LOJA_BTN_MERCADOR")
	_botao_mercador.modulate = Color(0.98, 0.88, 0.62, 1.0)
	_botao_mercador.pressed.connect(_alternar_painel_mercador)
	controles_tempo.add_child(_botao_mercador)
	controles_tempo.move_child(_botao_mercador, 1)

	_botao_obras = Button.new()
	_botao_obras.name = "BotaoObras"
	_botao_obras.focus_mode = Control.FOCUS_NONE
	_botao_obras.custom_minimum_size = Vector2(78.0, 20.0)
	_botao_obras.add_theme_font_size_override("font_size", 8)
	_botao_obras.text = tr("LOJA_BTN_OBRAS")
	_botao_obras.modulate = Color(1.15, 0.98, 0.55, 1.0)
	_botao_obras.pressed.connect(_alternar_painel_obras)
	controles_tempo.add_child(_botao_obras)
	controles_tempo.move_child(_botao_obras, 2)

func _on_idioma_alterado(_novo: String) -> void:
	_atualizar_textos_idioma()
	_atualizar_visuais_loja()
	_atualizar_objetivo_hud()

func _atualizar_textos_idioma() -> void:
	if _botao_grimorio != null:
		_botao_grimorio.text = tr("LOJA_BTN_GRIMORIO")
	if _botao_mercador != null:
		_botao_mercador.text = tr("LOJA_BTN_MERCADOR")
	if _botao_obras != null:
		_botao_obras.text = tr("LOJA_BTN_OBRAS")
	if botao_retomar != null:
		botao_retomar.text = tr("UI_PAUSA_RETOMAR")
	if botao_reiniciar != null:
		botao_reiniciar.text = tr("UI_PAUSA_REINICIAR")
	if botao_sair != null:
		botao_sair.text = tr("UI_PAUSA_SAIR")
	if instrucoes_label != null:
		instrucoes_label.text = tr("LOJA_INST_BASE")

func _fechar_modais_secundarios() -> void:
	if _painel_obras != null and is_instance_valid(_painel_obras):
		_painel_obras.queue_free()
		_painel_obras = null
	if _painel_grimorio != null and is_instance_valid(_painel_grimorio):
		_painel_grimorio.queue_free()
		_painel_grimorio = null
	if _painel_mercador != null and is_instance_valid(_painel_mercador):
		_painel_mercador.queue_free()
		_painel_mercador = null

func _alternar_painel_obras() -> void:
	if _painel_obras != null and is_instance_valid(_painel_obras):
		_painel_obras.queue_free()
		_painel_obras = null
		return
	_fechar_modais_secundarios()
	AudioManager.tocar_sfx("ui_click")
	_construir_painel_obras()

func _alternar_painel_grimorio() -> void:
	if _painel_grimorio != null and is_instance_valid(_painel_grimorio):
		_painel_grimorio.queue_free()
		_painel_grimorio = null
		return
	_fechar_modais_secundarios()
	AudioManager.tocar_sfx("ui_click")
	_construir_painel_grimorio()

func _alternar_painel_mercador() -> void:
	if _painel_mercador != null and is_instance_valid(_painel_mercador):
		_painel_mercador.queue_free()
		_painel_mercador = null
		return
	_fechar_modais_secundarios()
	AudioManager.tocar_sfx("ui_click")
	_construir_painel_mercador()

func _construir_painel_grimorio() -> void:
	if _painel_grimorio != null and is_instance_valid(_painel_grimorio):
		_painel_grimorio.queue_free()

	_painel_grimorio = ColorRect.new()
	_painel_grimorio.name = "PainelGrimorioAlquimico"
	_painel_grimorio.color = Color(0.05, 0.04, 0.03, 0.94)
	_painel_grimorio.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	$Interface.add_child(_painel_grimorio)

	var margem := MarginContainer.new()
	margem.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	margem.add_theme_constant_override("margin_left", 20)
	margem.add_theme_constant_override("margin_top", 12)
	margem.add_theme_constant_override("margin_right", 20)
	margem.add_theme_constant_override("margin_bottom", 12)
	_painel_grimorio.add_child(margem)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 6)
	margem.add_child(vbox)

	var header := HBoxContainer.new()
	vbox.add_child(header)

	var titulo := Label.new()
	titulo.text = "📖 GRIMÓRIO ALQUÍMICO & CALDEIRÃO (Nv.%d · %d%% Dose Dupla)" % [
		InventoryManager.nivel_caldeirao,
		roundi(InventoryManager.obter_chance_dose_dupla() * 100.0)
	]
	titulo.add_theme_font_size_override("font_size", 13)
	titulo.add_theme_color_override("font_color", Color(0.75, 0.98, 0.80))
	titulo.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(titulo)

	var tend_lbl := Label.new()
	tend_lbl.text = "🔥 Em Alta: %s (+35%% 🪙)" % InventoryManager.nome_pocao_tendencia_dia
	tend_lbl.add_theme_font_size_override("font_size", 10)
	tend_lbl.add_theme_color_override("font_color", Color(1.0, 0.86, 0.38))
	header.add_child(tend_lbl)

	var sub := Label.new()
	sub.text = "Cada poção destilada 5 vezes atinge a Mestria ★5 e desbloqueia uma nova fórmula superior na Árvore Alquímica!"
	sub.add_theme_font_size_override("font_size", 9)
	sub.add_theme_color_override("font_color", Color(0.80, 0.78, 0.70))
	vbox.add_child(sub)

	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vbox.add_child(scroll)

	var lista_vbox := VBoxContainer.new()
	lista_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	lista_vbox.add_theme_constant_override("separation", 5)
	scroll.add_child(lista_vbox)

	caldeirao._carregar_receitas_desbloqueadas()
	for idx_rec in range(caldeirao.receitas.size()):
		var rec: PotionRecipeData = caldeirao.receitas[idx_rec]
		if rec == null or rec.pocao_resultante == null:
			continue
		var pocao: ItemData = rec.pocao_resultante
		var card := PanelContainer.new()
		var sb := StyleBoxFlat.new()
		var em_alta := InventoryManager.e_pocao_tendencia(pocao.id)
		sb.bg_color = Color(0.16, 0.13, 0.08, 0.96) if em_alta else Color(0.12, 0.10, 0.08, 0.96)
		sb.border_color = Color(0.95, 0.76, 0.28, 0.98) if em_alta else Color(0.62, 0.50, 0.26, 0.85)
		sb.set_border_width_all(1)
		sb.set_corner_radius_all(4)
		sb.content_margin_left = 8.0
		sb.content_margin_right = 8.0
		sb.content_margin_top = 4.0
		sb.content_margin_bottom = 4.0
		card.add_theme_stylebox_override("panel", sb)
		lista_vbox.add_child(card)

		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 8)
		card.add_child(row)

		var icone_rect := TextureRect.new()
		icone_rect.custom_minimum_size = Vector2(36, 36)
		icone_rect.texture = pocao.icone
		icone_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icone_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		icone_rect.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		row.add_child(icone_rect)

		var info_col := VBoxContainer.new()
		info_col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		info_col.add_theme_constant_override("separation", 2)
		row.add_child(info_col)

		var mestria := InventoryManager.obter_mestria(pocao.id)
		var estrelas := "★".repeat(mini(5, mestria)) + "☆".repeat(maxi(0, 5 - mini(5, mestria)))
		var stock_p := InventoryManager.obter_quantidade(pocao.id)
		var stock_ouro := InventoryManager.obter_quantidade_ouro(pocao.id)
		var tag_tend := "  🔥 [EM ALTA +35%]" if em_alta else ""
		var tag_ouro := (" · ✨%d Ouro" % stock_ouro) if stock_ouro > 0 else ""

		var nome_l := Label.new()
		nome_l.text = "%s (%d 🪙 base) · Stock: %d%s  |  Mestria %s (%s)%s" % [
			pocao.nome_do_item,
			pocao.valor_em_escudos,
			stock_p,
			tag_ouro,
			estrelas,
			InventoryManager.obter_nivel_mestria(pocao.id),
			tag_tend
		]
		nome_l.add_theme_font_size_override("font_size", 10)
		nome_l.add_theme_color_override("font_color", Color(1.0, 0.94, 0.72) if em_alta else Color(0.95, 0.92, 0.82))
		info_col.add_child(nome_l)

		var ing_hbox := HBoxContainer.new()
		ing_hbox.add_theme_constant_override("separation", 8)
		info_col.add_child(ing_hbox)

		for ing in rec.ingredientes_necessarios:
			if ing == null:
				continue
			var item_ing_box := HBoxContainer.new()
			item_ing_box.add_theme_constant_override("separation", 3)
			ing_hbox.add_child(item_ing_box)
			if ing.icone != null:
				var ir := TextureRect.new()
				ir.custom_minimum_size = Vector2(16, 16)
				ir.texture = ing.icone
				ir.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
				ir.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
				ir.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
				item_ing_box.add_child(ir)
			var q_ing := InventoryManager.obter_quantidade(ing.id)
			var lbl_i := Label.new()
			lbl_i.text = "%s (%d/1)" % [ing.nome_do_item, q_ing]
			lbl_i.add_theme_font_size_override("font_size", 9)
			lbl_i.add_theme_color_override("font_color", Color(0.65, 0.95, 0.68) if q_ing >= 1 else Color(0.98, 0.55, 0.48))
			item_ing_box.add_child(lbl_i)

		if InventoryManager.ARVORE_MESTRIA.has(pocao.id):
			var prox_dados: Dictionary = InventoryManager.ARVORE_MESTRIA[pocao.id]
			var lbl_arvore := Label.new()
			if mestria >= 5:
				lbl_arvore.text = "🌟 Desbloqueou: %s" % str(prox_dados["nome"])
				lbl_arvore.add_theme_color_override("font_color", Color(0.95, 0.82, 0.35))
			else:
				lbl_arvore.text = "🔒 Prepara mais %dx para descobrir: %s" % [5 - mestria, str(prox_dados["nome"])]
				lbl_arvore.add_theme_color_override("font_color", Color(0.68, 0.80, 0.92))
			lbl_arvore.add_theme_font_size_override("font_size", 8)
			ing_hbox.add_child(lbl_arvore)

		var pode_fazer := caldeirao.pode_preparar_receita(rec)
		var btn_destilar := Button.new()
		btn_destilar.focus_mode = Control.FOCUS_NONE
		btn_destilar.custom_minimum_size = Vector2(132.0, 28.0)
		btn_destilar.add_theme_font_size_override("font_size", 9)
		btn_destilar.disabled = not pode_fazer
		btn_destilar.text = "⚗️ DESTILAR AGORA" if pode_fazer else "Falta Ingrediente"
		var r_ref := rec
		btn_destilar.pressed.connect(func():
			if caldeirao.preparar_receita_especifica(r_ref, jogador):
				_sincronizar_pocoes_desbloqueadas()
				_reconstruir_botoes_pocoes()
				_construir_painel_grimorio()
		)
		row.add_child(btn_destilar)

	var rodape_hbox := HBoxContainer.new()
	rodape_hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	rodape_hbox.add_theme_constant_override("separation", 12)
	vbox.add_child(rodape_hbox)

	var ir_mercador_btn := Button.new()
	ir_mercador_btn.focus_mode = Control.FOCUS_NONE
	ir_mercador_btn.custom_minimum_size = Vector2(175.0, 26.0)
	ir_mercador_btn.add_theme_font_size_override("font_size", 10)
	ir_mercador_btn.text = "🛒 COMPRAR INGREDIENTES [V]"
	ir_mercador_btn.pressed.connect(_alternar_painel_mercador)
	rodape_hbox.add_child(ir_mercador_btn)

	var fechar_btn := Button.new()
	fechar_btn.focus_mode = Control.FOCUS_NONE
	fechar_btn.custom_minimum_size = Vector2(175.0, 26.0)
	fechar_btn.add_theme_font_size_override("font_size", 10)
	fechar_btn.text = "FECHAR GRIMÓRIO [C]"
	fechar_btn.pressed.connect(_alternar_painel_grimorio)
	rodape_hbox.add_child(fechar_btn)

func _construir_painel_mercador() -> void:
	if _painel_mercador != null and is_instance_valid(_painel_mercador):
		_painel_mercador.queue_free()

	_painel_mercador = ColorRect.new()
	_painel_mercador.name = "PainelBancaMercador"
	_painel_mercador.color = Color(0.05, 0.04, 0.03, 0.94)
	_painel_mercador.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	$Interface.add_child(_painel_mercador)

	var margem := MarginContainer.new()
	margem.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	margem.add_theme_constant_override("margin_left", 20)
	margem.add_theme_constant_override("margin_top", 12)
	margem.add_theme_constant_override("margin_right", 20)
	margem.add_theme_constant_override("margin_bottom", 12)
	_painel_mercador.add_child(margem)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 6)
	margem.add_child(vbox)

	var header := HBoxContainer.new()
	vbox.add_child(header)

	var titulo := Label.new()
	titulo.text = "🛒 BANCA DE REAGENTES DO MERCADOR (Rota Nv.%d)" % InventoryManager.nivel_fornecedor
	titulo.add_theme_font_size_override("font_size", 13)
	titulo.add_theme_color_override("font_color", Color(0.98, 0.86, 0.48))
	titulo.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(titulo)

	var ouro_lbl := Label.new()
	ouro_lbl.text = "TEU OURO: %d 🪙" % jogador.escudos
	ouro_lbl.add_theme_font_size_override("font_size", 11)
	ouro_lbl.add_theme_color_override("font_color", Color(0.95, 0.92, 0.72))
	header.add_child(ouro_lbl)

	var sub := Label.new()
	sub.text = "Abastece a tua botica com ervas, minerais e essências para todas as tuas receitas desbloqueadas!"
	sub.add_theme_font_size_override("font_size", 9)
	sub.add_theme_color_override("font_color", Color(0.80, 0.78, 0.70))
	vbox.add_child(sub)

	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vbox.add_child(scroll)

	var grid := GridContainer.new()
	grid.columns = 2
	grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	grid.add_theme_constant_override("h_separation", 6)
	grid.add_theme_constant_override("v_separation", 6)
	scroll.add_child(grid)

	for ing in fornecedor.obter_ingredientes_disponiveis():
		if ing == null:
			continue
		var card := PanelContainer.new()
		card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var sb := StyleBoxFlat.new()
		sb.bg_color = Color(0.13, 0.10, 0.08, 0.96)
		sb.border_color = Color(0.68, 0.54, 0.28, 0.88)
		sb.set_border_width_all(1)
		sb.set_corner_radius_all(4)
		sb.content_margin_left = 6.0
		sb.content_margin_right = 6.0
		sb.content_margin_top = 4.0
		sb.content_margin_bottom = 4.0
		card.add_theme_stylebox_override("panel", sb)
		grid.add_child(card)

		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 6)
		card.add_child(row)

		var icone_rect := TextureRect.new()
		icone_rect.custom_minimum_size = Vector2(28, 28)
		icone_rect.texture = ing.icone
		icone_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icone_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		icone_rect.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		row.add_child(icone_rect)

		var info_col := VBoxContainer.new()
		info_col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		info_col.add_theme_constant_override("separation", 1)
		row.add_child(info_col)

		var q_tenho := InventoryManager.obter_quantidade(ing.id)
		var custo_u := fornecedor.obter_custo_ingrediente(ing)
		var nome_l := Label.new()
		nome_l.text = "%s (Stock: %d)" % [ing.nome_do_item, q_tenho]
		nome_l.add_theme_font_size_override("font_size", 9)
		nome_l.add_theme_color_override("font_color", Color(0.98, 0.92, 0.76))
		info_col.add_child(nome_l)

		var preco_l := Label.new()
		preco_l.text = "Preço: %d 🪙 un." % custo_u
		preco_l.add_theme_font_size_override("font_size", 8)
		preco_l.add_theme_color_override("font_color", Color(0.75, 0.92, 0.72))
		info_col.add_child(preco_l)

		var ing_ref := ing
		var btn_1 := Button.new()
		btn_1.focus_mode = Control.FOCUS_NONE
		btn_1.custom_minimum_size = Vector2(46.0, 24.0)
		btn_1.add_theme_font_size_override("font_size", 8)
		btn_1.text = "+1 (%d🪙)" % custo_u
		btn_1.disabled = jogador.escudos < custo_u
		btn_1.pressed.connect(func():
			fornecedor.comprar_ingrediente_direto(ing_ref, 1, jogador)
			_construir_painel_mercador()
		)
		row.add_child(btn_1)

		var btn_5 := Button.new()
		btn_5.focus_mode = Control.FOCUS_NONE
		btn_5.custom_minimum_size = Vector2(50.0, 24.0)
		btn_5.add_theme_font_size_override("font_size", 8)
		btn_5.text = "+5 (%d🪙)" % (custo_u * 5)
		btn_5.disabled = jogador.escudos < (custo_u * 5)
		btn_5.pressed.connect(func():
			fornecedor.comprar_ingrediente_direto(ing_ref, 5, jogador)
			_construir_painel_mercador()
		)
		row.add_child(btn_5)

	var rodape_hbox := HBoxContainer.new()
	rodape_hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	rodape_hbox.add_theme_constant_override("separation", 12)
	vbox.add_child(rodape_hbox)

	var ir_grimorio_btn := Button.new()
	ir_grimorio_btn.focus_mode = Control.FOCUS_NONE
	ir_grimorio_btn.custom_minimum_size = Vector2(175.0, 26.0)
	ir_grimorio_btn.add_theme_font_size_override("font_size", 10)
	ir_grimorio_btn.text = "📖 ABRIR GRIMÓRIO [C]"
	ir_grimorio_btn.pressed.connect(_alternar_painel_grimorio)
	rodape_hbox.add_child(ir_grimorio_btn)

	var fechar_btn := Button.new()
	fechar_btn.focus_mode = Control.FOCUS_NONE
	fechar_btn.custom_minimum_size = Vector2(175.0, 26.0)
	fechar_btn.add_theme_font_size_override("font_size", 10)
	fechar_btn.text = "FECHAR MERCADOR [V]"
	fechar_btn.pressed.connect(_alternar_painel_mercador)
	rodape_hbox.add_child(fechar_btn)

func _construir_painel_obras() -> void:
	if _painel_obras != null and is_instance_valid(_painel_obras):
		_painel_obras.queue_free()

	_painel_obras = ColorRect.new()
	_painel_obras.name = "PainelObrasBotica"
	_painel_obras.color = Color(0.05, 0.04, 0.03, 0.92)
	_painel_obras.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	$Interface.add_child(_painel_obras)

	var margem := MarginContainer.new()
	margem.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	margem.add_theme_constant_override("margin_left", 24)
	margem.add_theme_constant_override("margin_top", 14)
	margem.add_theme_constant_override("margin_right", 24)
	margem.add_theme_constant_override("margin_bottom", 14)
	_painel_obras.add_child(margem)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 6)
	margem.add_child(vbox)

	var header := HBoxContainer.new()
	vbox.add_child(header)

	var titulo := Label.new()
	titulo.text = "🔨 REFORMAS & EVOLUÇÃO DA BOTICA (%s)" % InventoryManager.obter_titulo_fama().to_upper()
	titulo.add_theme_font_size_override("font_size", 13)
	titulo.add_theme_color_override("font_color", Color(0.98, 0.86, 0.45))
	titulo.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(titulo)

	var ouro_lbl := Label.new()
	ouro_lbl.text = "OURO: %d 🪙  |  FAMA: %d ⭐" % [jogador.escudos, InventoryManager.renome_loja]
	ouro_lbl.add_theme_font_size_override("font_size", 11)
	ouro_lbl.add_theme_color_override("font_color", Color(0.95, 0.92, 0.72))
	header.add_child(ouro_lbl)

	var sub := Label.new()
	sub.text = "Começaste numa cabana quebrada. Investe os teus escudos para restaurar estações, desbloquear receitas e atrair clientes nobres!"
	sub.add_theme_font_size_override("font_size", 9)
	sub.add_theme_color_override("font_color", Color(0.78, 0.76, 0.68))
	vbox.add_child(sub)

	var lista_vbox := VBoxContainer.new()
	lista_vbox.add_theme_constant_override("separation", 5)
	lista_vbox.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vbox.add_child(lista_vbox)

	for upg in InventoryManager.obter_catalogo_upgrades():
		var card := PanelContainer.new()
		var sb := StyleBoxFlat.new()
		sb.bg_color = Color(0.14, 0.11, 0.09, 0.96)
		sb.border_color = Color(0.68, 0.54, 0.28, 0.85)
		sb.set_border_width_all(1)
		sb.set_corner_radius_all(4)
		sb.content_margin_left = 8.0
		sb.content_margin_right = 8.0
		sb.content_margin_top = 4.0
		sb.content_margin_bottom = 4.0
		card.add_theme_stylebox_override("panel", sb)
		lista_vbox.add_child(card)

		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 8)
		card.add_child(row)

		var info_col := VBoxContainer.new()
		info_col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		info_col.add_theme_constant_override("separation", 1)
		row.add_child(info_col)

		var niv_atual := int(upg["nivel"])
		var max_niv := int(upg["max_nivel"])
		var custo := int(upg["custo"])

		var nome_l := Label.new()
		nome_l.text = "%s %s  [Nível %d/%d] — %s" % [
			str(upg["icone"]),
			str(upg["titulo"]),
			niv_atual,
			max_niv,
			str(upg["desc_atual"])
		]
		nome_l.add_theme_font_size_override("font_size", 10)
		nome_l.add_theme_color_override("font_color", Color(0.98, 0.92, 0.76))
		info_col.add_child(nome_l)

		var prox_l := Label.new()
		prox_l.text = "Próximo: " + str(upg["desc_prox"])
		prox_l.add_theme_font_size_override("font_size", 9)
		prox_l.add_theme_color_override("font_color", Color(0.68, 0.88, 0.68) if niv_atual < max_niv else Color(0.95, 0.82, 0.35))
		info_col.add_child(prox_l)

		var btn := Button.new()
		btn.focus_mode = Control.FOCUS_NONE
		btn.custom_minimum_size = Vector2(138.0, 26.0)
		btn.add_theme_font_size_override("font_size", 9)
		if niv_atual >= max_niv:
			btn.text = "✅ NÍVEL MÁXIMO"
			btn.disabled = true
		else:
			btn.text = "MELHORAR (%d 🪙)" % custo
			btn.disabled = jogador.escudos < custo
			var id_upg := str(upg["id"])
			btn.pressed.connect(func():
				var res := InventoryManager.comprar_upgrade_loja(id_upg)
				if bool(res.get("sucesso", false)):
					AudioManager.tocar_sfx("moeda", 0.0)
					_mostrar_feedback(str(res.get("mensagem", "")))
					_construir_painel_obras()
				else:
					AudioManager.tocar_sfx("pechincha_falha", 0.0)
					_mostrar_feedback(str(res.get("mensagem", "")))
			)
		row.add_child(btn)

	var rodape_hbox := HBoxContainer.new()
	rodape_hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_child(rodape_hbox)

	var fechar_btn := Button.new()
	fechar_btn.focus_mode = Control.FOCUS_NONE
	fechar_btn.custom_minimum_size = Vector2(190.0, 26.0)
	fechar_btn.add_theme_font_size_override("font_size", 10)
	fechar_btn.text = "FECHAR PAINEL DE OBRAS [M]"
	fechar_btn.pressed.connect(_alternar_painel_obras)
	rodape_hbox.add_child(fechar_btn)

func _desativar_foco_hud(no: Node) -> void:
	if no == null:
		return
	if no is Button:
		no.focus_mode = Control.FOCUS_NONE
	for filho in no.get_children():
		_desativar_foco_hud(filho)

func _estilo_textura_pocao(tex: Texture2D) -> StyleBoxTexture:
	var estilo := StyleBoxTexture.new()
	estilo.texture = tex
	estilo.texture_margin_left = 4.0
	estilo.texture_margin_top = 4.0
	estilo.texture_margin_right = 4.0
	estilo.texture_margin_bottom = 4.0
	estilo.content_margin_left = 6.0
	estilo.content_margin_right = 6.0
	return estilo

func _selecionar_pocao_indice(indice: int) -> void:
	jogador.selecionar_pocao_indice(indice)

func _atualizar_botoes_pocoes() -> void:
	if barra_pocoes == null or not is_node_ready() or _reconstruindo_botoes_pocoes:
		return
	if barra_pocoes.get_child_count() != jogador.pocoes_disponiveis.size():
		_reconstruir_botoes_pocoes()
		return
	_atualizar_conteudo_botoes_pocoes()

func _atualizar_conteudo_botoes_pocoes() -> void:
	if barra_pocoes == null:
		return
	for indice in range(barra_pocoes.get_child_count()):
		var botao := barra_pocoes.get_child(indice) as Button
		if botao == null or indice >= jogador.pocoes_disponiveis.size():
			continue
		var pocao := jogador.pocoes_disponiveis[indice]
		if pocao == null:
			continue
		var quantidade := InventoryManager.obter_quantidade(pocao.id)
		var qtd_ouro := InventoryManager.obter_quantidade_ouro(pocao.id)
		var nome_curto := _obter_nome_curto_pocao(pocao)
		var sufixo_ouro := "✨" if qtd_ouro > 0 else ""
		var sufixo_tend := "🔥" if InventoryManager.e_pocao_tendencia(pocao.id) else ""
		botao.text = "%d %s ×%d%s%s" % [indice + 1, nome_curto, quantidade, sufixo_ouro, sufixo_tend]
		botao.button_pressed = jogador.pocao_ativa == pocao
		botao.disabled = quantidade <= 0
		if jogador.pocao_ativa == pocao:
			botao.modulate = Color(1.22, 1.12, 0.78, 1.0)
		else:
			botao.modulate = Color.WHITE

func _obter_instrucao_contextual(alvo: Node2D) -> String:
	var cliente_balcao := balcao.obter_cliente_atual()
	if alvo == balcao:
		if cliente_balcao != null and cliente_balcao.item_desejado != null:
			return "E  ATENDER FREGUÊS NO BALCÃO (%s)  ·  [C] GRIMÓRIO  ·  [M] OBRAS" % cliente_balcao.item_desejado.nome_do_item.to_upper()
		return "CLIENTE A CAMINHO  ·  [C] GRIMÓRIO  ·  [V] MERCADOR  ·  [M] OBRAS"
	if alvo == caldeirao:
		return "E  DESTILAR POÇÃO  ·  TAB  TROCAR RECEITA  ·  [C] ABRIR GRIMÓRIO COMPLETO"
	if alvo == fornecedor:
		return "E  COMPRAR INGREDIENTE  ·  F  TROCAR ITEM  ·  [V] ABRIR BANCA DO MERCADOR"
	if alvo != null and alvo.has_method("obter_texto_interacao"):
		return str(alvo.call("obter_texto_interacao"))
	if cliente_balcao != null and cliente_balcao.item_desejado != null:
		return "FREGUÊS NO BALCÃO (%s)! VAI AO BALCÃO E PRESSIONA [E]" % cliente_balcao.item_desejado.nome_do_item.to_upper()
	return "WASD MOVER  ·  E INTERAGIR  ·  [C] GRIMÓRIO  ·  [V] MERCADOR  ·  [M] OBRAS"

func _alternar_pausa() -> void:
	if get_tree().paused:
		retomar_jogo()
	else:
		pausar_jogo()

func pausar_jogo() -> void:
	pausa_overlay.visible = true
	get_tree().paused = true
	botao_retomar.grab_focus()

func retomar_jogo() -> void:
	pausa_overlay.visible = false
	get_tree().paused = false

func reiniciar_jogo() -> void:
	get_tree().paused = false
	CampaignManager.reiniciar_turno()
	get_tree().reload_current_scene()

func sair_do_jogo() -> void:
	get_tree().paused = false
	get_tree().quit()

func _criar_cliente() -> void:
	var max_cli := InventoryManager.obter_max_clientes_turno()
	if CampaignManager.fase != CampaignManager.Fase.LOJA or clientes_gerados >= max_cli:
		temporizador_cliente.stop()
		return

	var cliente := CENA_CLIENTE.instantiate() as ClienteNPC
	if cliente == null:
		push_error("Não foi possível criar a cena do cliente.")
		return
	_sincronizar_pocoes_desbloqueadas()
	cliente.itens_possiveis = jogador.pocoes_disponiveis
	var max_niv_cli := mini(5, 1 + floori(float(InventoryManager.obter_soma_niveis_loja()) / 3.0))
	cliente.nivel_cliente = randi_range(1, max_niv_cli)
	var chance_vip := 0.10 if InventoryManager.nivel_balcao == 1 else (0.24 if InventoryManager.nivel_balcao == 2 else 0.42)
	if randf() < chance_vip:
		cliente.e_vip = true
		cliente.nome_vip = "Nobre de Tongóbriga"
		cliente.modulate = Color(1.15, 1.05, 0.72, 1.0)
	cliente.multiplicador_preco = randf_range(
		0.85 + float(cliente.nivel_cliente) * 0.12,
		1.05 + float(cliente.nivel_cliente) * 0.18
	)
	cliente.velocidade = randf_range(34.0, 52.0) + float(cliente.nivel_cliente) * 2.0
	cliente.paciencia_total = randf_range(32.0, 54.0) - float(cliente.nivel_cliente) + InventoryManager.obter_bonus_paciencia_loja()
	cliente.tipo_visual = _tipos_visuais_do_turno[clientes_gerados % _tipos_visuais_do_turno.size()]
	cliente.ponto_entrada = Vector2(320.0, 335.0)
	var posicao_fila := clientes_ativos.size()
	cliente.ponto_espera = Vector2(
		245.0 + float(posicao_fila) * 28.0,
		245.0
	)
	cliente.ponto_saida = Vector2(320.0, 335.0)
	cliente.venda_fracassada.connect(_ao_cliente_desistir)
	cliente.venda_sucesso.connect(_ao_cliente_vender)
	cliente.tree_exited.connect(_ao_cliente_sair.bind(cliente.get_instance_id()))
	add_child(cliente)
	clientes_ativos.append(cliente)
	clientes_gerados += 1
	CampaignManager.clientes_gerados_hoje = clientes_gerados
	AudioManager.tocar_sfx("sino_porta")

	if clientes_gerados < max_cli:
		temporizador_cliente.start(randf_range(9.0, 18.0))

func _ao_cliente_vender(_pocao: ItemData, valor: int) -> void:
	_mostrar_feedback("Venda concluída: +%d ouro 🪙! (Usa [M] para evoluir a Botica)" % valor)

func _ao_cliente_desistir(_pocao: ItemData) -> void:
	_mostrar_feedback("O cliente perdeu a paciência. Mantém a loja abastecida.")

func _ao_cliente_sair(id_instancia: int) -> void:
	var cliente_removido := false
	for indice in range(clientes_ativos.size() - 1, -1, -1):
		if (
			not is_instance_valid(clientes_ativos[indice])
			or clientes_ativos[indice].get_instance_id() == id_instancia
		):
			clientes_ativos.remove_at(indice)
			cliente_removido = true
			break
	var max_cli := InventoryManager.obter_max_clientes_turno()
	if (
		cliente_removido
		and clientes_gerados >= max_cli
		and clientes_ativos.is_empty()
		and CampaignManager.fase == CampaignManager.Fase.LOJA
	):
		CampaignManager.encerrar_turno()

func _ao_alterar_fase(nova_fase: int) -> void:
	if _ultimo_dia_tendencia != CampaignManager.dia:
		_ao_alterar_dia(CampaignManager.dia)
	clientes_gerados = CampaignManager.clientes_gerados_hoje
	var max_cli := InventoryManager.obter_max_clientes_turno()
	if nova_fase == CampaignManager.Fase.LOJA:
		if clientes_gerados < max_cli:
			temporizador_cliente.start(2.0)
	elif nova_fase != CampaignManager.Fase.LOJA:
		temporizador_cliente.stop()
