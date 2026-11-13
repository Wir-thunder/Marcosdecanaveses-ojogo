class_name PainelAtendimentoBalcao extends CanvasLayer

signal atendimento_concluido(sucesso: bool, mensagem: String)
signal atendimento_encerrado

@onready var root_control: Control = $Control
@onready var painel_caixa: PanelContainer = $Control/Painel
@onready var label_fama: Label = $Control/Painel/Margem/VBox/Header/LabelFama
@onready var col_cliente: VBoxContainer = $Control/Painel/Margem/VBox/Conteudo/ColCliente
@onready var label_nome_cliente: Label = $Control/Painel/Margem/VBox/Conteudo/ColCliente/LabelNome
@onready var label_classe_cliente: Label = $Control/Painel/Margem/VBox/Conteudo/ColCliente/LabelClasse
@onready var barra_paciencia: ProgressBar = $Control/Painel/Margem/VBox/Conteudo/ColCliente/BarPaciencia
@onready var painel_fala: PanelContainer = $Control/Painel/Margem/VBox/Conteudo/ColCliente/PainelFala
@onready var label_fala: Label = $Control/Painel/Margem/VBox/Conteudo/ColCliente/PainelFala/Margem/LabelFala

@onready var col_pedido: VBoxContainer = $Control/Painel/Margem/VBox/Conteudo/ColPedido
@onready var label_pedido: Label = $Control/Painel/Margem/VBox/Conteudo/ColPedido/LabelPedido
@onready var label_stock: Label = $Control/Painel/Margem/VBox/Conteudo/ColPedido/LabelStock
@onready var label_preco: Label = $Control/Painel/Margem/VBox/Conteudo/ColPedido/LabelPreco
@onready var painel_sugestoes: VBoxContainer = $Control/Painel/Margem/VBox/Conteudo/ColPedido/PainelSugestoes
@onready var lista_botoes_sugestao: HBoxContainer = $Control/Painel/Margem/VBox/Conteudo/ColPedido/PainelSugestoes/ListaBotoes

@onready var btn_vender: Button = $Control/Painel/Margem/VBox/BotoesAcao/BtnVender
@onready var btn_sugerir: Button = $Control/Painel/Margem/VBox/BotoesAcao/BtnSugerir
@onready var btn_pechinchar: Button = $Control/Painel/Margem/VBox/BotoesAcao/BtnPechinchar
@onready var btn_desconto: Button = $Control/Painel/Margem/VBox/BotoesAcao/BtnDesconto
@onready var btn_dispensar: Button = $Control/Painel/Margem/VBox/BotoesAcao/BtnDispensar
@onready var btn_fechar: Button = $Control/Painel/Margem/VBox/BotoesAcao/BtnFechar

var _cliente_atual: ClienteNPC = null
var _jogador_atual: Player = null
var _tex_retrato_cliente: TextureRect = null
var _tex_icone_pocao: TextureRect = null
var _lbl_badges_pedido: Label = null
var _lbl_feedback: Label = null
var _btn_destilar_agora: Button = null
var _estilo_paciencia_fill: StyleBoxFlat = null

func _ready() -> void:
	add_to_group("painel_atendimento")
	visible = false
	_aplicar_estilo_medieval()
	_criar_elementos_visuais_extras()
	btn_vender.pressed.connect(_on_entregar_pressed)
	btn_sugerir.pressed.connect(_on_sugerir_pressed)
	btn_pechinchar.pressed.connect(_on_pechinchar_pressed)
	btn_desconto.pressed.connect(_on_desconto_pressed)
	btn_dispensar.pressed.connect(_on_dispensar_pressed)
	btn_fechar.pressed.connect(fechar_painel)

func _aplicar_estilo_medieval() -> void:
	if painel_caixa != null:
		var st_caixa := StyleBoxFlat.new()
		st_caixa.bg_color = Color(0.10, 0.08, 0.06, 0.97)
		st_caixa.border_color = Color(0.82, 0.64, 0.28, 1.0)
		st_caixa.set_border_width_all(2)
		st_caixa.set_corner_radius_all(6)
		st_caixa.shadow_color = Color(0, 0, 0, 0.65)
		st_caixa.shadow_size = 8
		painel_caixa.add_theme_stylebox_override("panel", st_caixa)

	if barra_paciencia != null:
		_estilo_paciencia_fill = StyleBoxFlat.new()
		_estilo_paciencia_fill.bg_color = Color(0.32, 0.78, 0.38, 1.0)
		_estilo_paciencia_fill.set_corner_radius_all(2)
		barra_paciencia.add_theme_stylebox_override("fill", _estilo_paciencia_fill)

	for b in [btn_vender, btn_sugerir, btn_pechinchar, btn_desconto, btn_dispensar, btn_fechar]:
		if b != null:
			_estilizar_botao_balcao(b, b == btn_vender)

func _estilizar_botao_balcao(btn: Button, destaque: bool = false) -> void:
	var st_normal := StyleBoxFlat.new()
	st_normal.bg_color = Color(0.16, 0.28, 0.16, 0.96) if destaque else Color(0.22, 0.15, 0.10, 0.95)
	st_normal.border_color = Color(0.52, 0.86, 0.44, 1.0) if destaque else Color(0.76, 0.58, 0.26, 0.95)
	st_normal.set_border_width_all(1)
	st_normal.set_corner_radius_all(4)
	st_normal.content_margin_left = 5
	st_normal.content_margin_right = 5
	st_normal.content_margin_top = 2
	st_normal.content_margin_bottom = 2

	var st_hover := st_normal.duplicate() as StyleBoxFlat
	st_hover.bg_color = Color(0.22, 0.38, 0.22, 0.98) if destaque else Color(0.32, 0.22, 0.14, 0.98)
	st_hover.border_color = Color(0.95, 0.82, 0.38, 1.0)

	var st_disabled := st_normal.duplicate() as StyleBoxFlat
	st_disabled.bg_color = Color(0.12, 0.10, 0.09, 0.70)
	st_disabled.border_color = Color(0.32, 0.28, 0.24, 0.55)

	btn.add_theme_stylebox_override("normal", st_normal)
	btn.add_theme_stylebox_override("hover", st_hover)
	btn.add_theme_stylebox_override("pressed", st_hover)
	btn.add_theme_stylebox_override("disabled", st_disabled)

func _criar_elementos_visuais_extras() -> void:
	if col_cliente != null and label_nome_cliente != null:
		var hbox_top_cli := HBoxContainer.new()
		hbox_top_cli.add_theme_constant_override("separation", 8)
		col_cliente.add_child(hbox_top_cli)
		col_cliente.move_child(hbox_top_cli, 0)

		var moldura_retrato := PanelContainer.new()
		moldura_retrato.custom_minimum_size = Vector2(44, 44)
		var st_ret := StyleBoxFlat.new()
		st_ret.bg_color = Color(0.14, 0.10, 0.07, 0.98)
		st_ret.border_color = Color(0.84, 0.66, 0.30, 1.0)
		st_ret.set_border_width_all(1)
		st_ret.set_corner_radius_all(4)
		moldura_retrato.add_theme_stylebox_override("panel", st_ret)
		hbox_top_cli.add_child(moldura_retrato)

		_tex_retrato_cliente = TextureRect.new()
		_tex_retrato_cliente.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		_tex_retrato_cliente.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		_tex_retrato_cliente.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		moldura_retrato.add_child(_tex_retrato_cliente)

		var vbox_id := VBoxContainer.new()
		vbox_id.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		vbox_id.add_theme_constant_override("separation", 1)
		hbox_top_cli.add_child(vbox_id)

		col_cliente.remove_child(label_nome_cliente)
		col_cliente.remove_child(label_classe_cliente)
		vbox_id.add_child(label_nome_cliente)
		vbox_id.add_child(label_classe_cliente)

	if col_pedido != null and label_pedido != null:
		var hbox_ped := HBoxContainer.new()
		hbox_ped.add_theme_constant_override("separation", 8)
		col_pedido.add_child(hbox_ped)
		col_pedido.move_child(hbox_ped, 0)

		var moldura_pocao := PanelContainer.new()
		moldura_pocao.custom_minimum_size = Vector2(40, 40)
		var st_poc := StyleBoxFlat.new()
		st_poc.bg_color = Color(0.15, 0.11, 0.08, 0.96)
		st_poc.border_color = Color(0.80, 0.62, 0.28, 0.96)
		st_poc.set_border_width_all(1)
		st_poc.set_corner_radius_all(4)
		moldura_pocao.add_theme_stylebox_override("panel", st_poc)
		hbox_ped.add_child(moldura_pocao)

		_tex_icone_pocao = TextureRect.new()
		_tex_icone_pocao.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		_tex_icone_pocao.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		_tex_icone_pocao.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		moldura_pocao.add_child(_tex_icone_pocao)

		var vbox_ped_txt := VBoxContainer.new()
		vbox_ped_txt.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		vbox_ped_txt.add_theme_constant_override("separation", 2)
		hbox_ped.add_child(vbox_ped_txt)

		col_pedido.remove_child(label_pedido)
		col_pedido.remove_child(label_stock)
		vbox_ped_txt.add_child(label_pedido)
		vbox_ped_txt.add_child(label_stock)

		_lbl_badges_pedido = Label.new()
		_lbl_badges_pedido.add_theme_font_size_override("font_size", 9)
		_lbl_badges_pedido.add_theme_color_override("font_color", Color(0.98, 0.84, 0.40))
		_lbl_badges_pedido.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		col_pedido.add_child(_lbl_badges_pedido)

		_btn_destilar_agora = Button.new()
		_btn_destilar_agora.custom_minimum_size = Vector2(0, 24)
		_btn_destilar_agora.focus_mode = Control.FOCUS_NONE
		_btn_destilar_agora.add_theme_font_size_override("font_size", 9)
		_btn_destilar_agora.add_theme_color_override("font_color", Color(1.0, 0.95, 0.72))
		_estilizar_botao_balcao(_btn_destilar_agora, true)
		_btn_destilar_agora.visible = false
		_btn_destilar_agora.pressed.connect(_on_destilar_agora_pressed)
		col_pedido.add_child(_btn_destilar_agora)

		_lbl_feedback = Label.new()
		_lbl_feedback.add_theme_font_size_override("font_size", 9)
		_lbl_feedback.add_theme_color_override("font_color", Color(0.72, 0.96, 0.76))
		_lbl_feedback.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		col_pedido.add_child(_lbl_feedback)

func abrir(cliente: ClienteNPC, jogador: Player) -> void:
	abrir_atendimento(cliente, jogador)

func abrir_atendimento(cliente: ClienteNPC, jogador: Player) -> void:
	if cliente == null or cliente.estado != ClienteNPC.Estado.ESPERANDO:
		return
	_cliente_atual = cliente
	_jogador_atual = jogador
	if _lbl_feedback != null:
		_lbl_feedback.text = ""
	if painel_sugestoes != null:
		painel_sugestoes.visible = false
	visible = true
	AudioManager.tocar_sfx("ui_click")
	_atualizar_dados()

func fechar_painel() -> void:
	if not visible:
		return
	visible = false
	_cliente_atual = null
	atendimento_encerrado.emit()

func _process(_delta: float) -> void:
	if not visible:
		return
	if _cliente_atual == null or not is_instance_valid(_cliente_atual) or _cliente_atual.estado != ClienteNPC.Estado.ESPERANDO:
		fechar_painel()
		return
	if _cliente_atual.timer_paciencia != null and barra_paciencia != null:
		barra_paciencia.max_value = _cliente_atual.paciencia_total
		var t_rest := _cliente_atual.timer_paciencia.time_left
		barra_paciencia.value = t_rest
		if _estilo_paciencia_fill != null:
			var frac := t_rest / maxf(1.0, _cliente_atual.paciencia_total)
			if frac > 0.50:
				_estilo_paciencia_fill.bg_color = Color(0.28, 0.78, 0.38, 1.0)
			elif frac > 0.25:
				_estilo_paciencia_fill.bg_color = Color(0.92, 0.72, 0.20, 1.0)
			else:
				_estilo_paciencia_fill.bg_color = Color(0.88, 0.28, 0.24, 1.0)

func _atualizar_dados() -> void:
	if _cliente_atual == null or _cliente_atual.item_desejado == null:
		return
	if label_fama != null:
		label_fama.text = "⭐ %s (%d Fama)" % [InventoryManager.obter_titulo_fama(), InventoryManager.renome_loja]

	var prefixo_vip := "👑 " if _cliente_atual.e_vip else "👤 "
	label_nome_cliente.text = prefixo_vip + _cliente_atual.nome_cliente
	label_classe_cliente.text = "[%s]" % _cliente_atual.classe_cliente
	label_fala.text = "\"" + _cliente_atual.fala_pedido + "\""

	if _tex_retrato_cliente != null:
		var idx_vis := posmod(_cliente_atual.tipo_visual, 4)
		var caminho_ret := "res://Assets/Characters/Clientes/cliente_%d/walk_down_1.png" % idx_vis
		if ResourceLoader.exists(caminho_ret):
			_tex_retrato_cliente.texture = load(caminho_ret) as Texture2D

	var pocao_desejada := _cliente_atual.item_desejado
	if _tex_icone_pocao != null:
		_tex_icone_pocao.texture = pocao_desejada.icone
		var pai_icone := _tex_icone_pocao.get_parent() as Control
		if pai_icone != null:
			pai_icone.visible = (pocao_desejada.icone != null)

	var em_stock := InventoryManager.obter_quantidade(pocao_desejada.id)
	var em_ouro := InventoryManager.obter_quantidade_ouro(pocao_desejada.id)
	var tag_ouro := " ✨[OURO]" if em_ouro > 0 else ""
	label_pedido.text = "PEDIDO: %s%s" % [pocao_desejada.nome_do_item, tag_ouro]
	label_stock.text = "Em Stock: %d un. disponíveis" % em_stock
	if em_stock > 0:
		label_stock.add_theme_color_override("font_color", Color(0.48, 0.95, 0.56))
	else:
		label_stock.add_theme_color_override("font_color", Color(1.0, 0.55, 0.45))

	var preco := _cliente_atual.calcular_preco(pocao_desejada)
	var pct := roundi(_cliente_atual.multiplicador_pechincha * 100.0)
	label_preco.text = "Oferta: %d 🪙 (%d%%)" % [preco, pct]

	if _lbl_badges_pedido != null:
		var tags: PackedStringArray = []
		if InventoryManager.e_pocao_tendencia(pocao_desejada.id):
			tags.append("🔥 EM ALTA HOJE (+35% Ouro & +3 ⭐)")
		if em_ouro > 0:
			tags.append("✨ Qualidade Ouro (+50% Valor)")
		if InventoryManager.bonus_ouro_vitrine_atual > 1.01:
			tags.append("🪟 Vitrine (+%d%%)" % roundi((InventoryManager.bonus_ouro_vitrine_atual - 1.0) * 100.0))
		_lbl_badges_pedido.text = " · ".join(tags) if not tags.is_empty() else "Dica: Pechincha para lucrar mais ou dá Desconto por Fama!"

	# Botão 1: Vender
	btn_vender.disabled = (em_stock <= 0)
	btn_vender.icon = pocao_desejada.icone
	btn_vender.expand_icon = true
	if em_stock > 0:
		btn_vender.text = "💰 VENDER (%d 🪙)" % preco
		if _btn_destilar_agora != null:
			_btn_destilar_agora.visible = false
	else:
		btn_vender.text = "SEM STOCK"
		_atualizar_botao_destilar_agora(pocao_desejada)

	# Botão 2: Sugerir outra poção
	btn_sugerir.text = "💡 SUGERIR OUTRA"

	# Botão 3: Pechinchar (+35% ou +50% para VIP)
	var chance_pech := _cliente_atual.obter_chance_pechincha()
	var bonus_pech := "+50%" if _cliente_atual.e_vip else "+35%"
	btn_pechinchar.disabled = _cliente_atual.pechincha_tentada or _cliente_atual.desconto_aplicado
	btn_pechinchar.text = "📈 PECHINCHAR (%s · %d%%)" % [bonus_pech, chance_pech] if not _cliente_atual.pechincha_tentada else "📈 JÁ NEGOCIADO"

	# Botão 4: Desconto
	btn_desconto.disabled = _cliente_atual.desconto_aplicado
	btn_desconto.text = "🏷️ DESCONTO (-20% · +10⭐)" if not _cliente_atual.desconto_aplicado else "🏷️ DESCONTO DADO"

func _atualizar_botao_destilar_agora(pocao_desejada: ItemData) -> void:
	if _btn_destilar_agora == null:
		return
	var caldeirao := get_tree().current_scene.get_node_or_null("Caldeirao") as Caldeirao if get_tree().current_scene != null else null
	if caldeirao == null:
		_btn_destilar_agora.visible = false
		return
	var receita := caldeirao.obter_receita_por_pocao(pocao_desejada.id)
	if receita == null:
		_btn_destilar_agora.visible = false
		return
	_btn_destilar_agora.visible = true
	var nomes_ing: PackedStringArray = []
	for ing in receita.ingredientes_necessarios:
		if ing != null:
			nomes_ing.append("%s (%d)" % [ing.nome_do_item, InventoryManager.obter_quantidade(ing.id)])
	if caldeirao.pode_preparar_receita(receita):
		_btn_destilar_agora.disabled = false
		_btn_destilar_agora.text = "⚗️ DESTILAR AGORA [%s]" % ", ".join(nomes_ing)
	else:
		_btn_destilar_agora.disabled = true
		_btn_destilar_agora.text = "⚗️ Falta Ingrediente [%s]" % ", ".join(nomes_ing)

func _on_destilar_agora_pressed() -> void:
	if _cliente_atual == null or _cliente_atual.item_desejado == null or _jogador_atual == null:
		return
	var caldeirao := get_tree().current_scene.get_node_or_null("Caldeirao") as Caldeirao if get_tree().current_scene != null else null
	if caldeirao == null:
		return
	var receita := caldeirao.obter_receita_por_pocao(_cliente_atual.item_desejado.id)
	if receita != null and caldeirao.preparar_receita_especifica(receita, _jogador_atual):
		if _lbl_feedback != null:
			_lbl_feedback.text = "⚗️ Destilaste %s na hora! Podes vender agora!" % _cliente_atual.item_desejado.nome_do_item
		_atualizar_dados()

func _on_entregar_pressed() -> void:
	if _cliente_atual == null or _cliente_atual.item_desejado == null or _jogador_atual == null:
		return
	var pocao := _cliente_atual.item_desejado
	if InventoryManager.obter_quantidade(pocao.id) <= 0:
		AudioManager.tocar_sfx("pechincha_falha")
		if _lbl_feedback != null:
			_lbl_feedback.text = "Não tens %s em stock!" % pocao.nome_do_item
		return
	var preco_venda := _cliente_atual.calcular_preco(pocao)
	if _cliente_atual.receber_pocao(pocao):
		AudioManager.tocar_sfx("venda")
		AudioManager.tocar_sfx("moedas")
		InventoryManager.remover_item(pocao.id, 1)
		_jogador_atual.atualizar_pocao_apos_venda()
		atendimento_concluido.emit(true, "Venda concluída: %s (+%d 🪙)!" % [pocao.nome_do_item, preco_venda])
		fechar_painel()

func _on_sugerir_pressed() -> void:
	if _cliente_atual == null or _jogador_atual == null or painel_sugestoes == null or lista_botoes_sugestao == null:
		return
	painel_sugestoes.visible = not painel_sugestoes.visible
	if not painel_sugestoes.visible:
		return
	for c in lista_botoes_sugestao.get_children():
		c.queue_free()
	var encontrou := false
	for pocao in _jogador_atual.pocoes_disponiveis:
		if pocao == null or pocao == _cliente_atual.item_desejado:
			continue
		var qtd := InventoryManager.obter_quantidade(pocao.id)
		if qtd <= 0:
			continue
		encontrou = true
		var chance_s := _cliente_atual.obter_chance_sugestao(pocao)
		var b := Button.new()
		b.focus_mode = Control.FOCUS_NONE
		b.icon = pocao.icone
		b.expand_icon = true
		b.custom_minimum_size = Vector2(0, 22)
		b.add_theme_font_size_override("font_size", 8)
		b.text = "%s (%d%%)" % [pocao.nome_do_item.replace("Poção ", ""), chance_s]
		_estilizar_botao_balcao(b, false)
		var p_ref := pocao
		b.pressed.connect(func():
			var res := _cliente_atual.tentar_sugestao(p_ref)
			label_fala.text = "\"" + str(res.get("fala", "")) + "\""
			painel_sugestoes.visible = false
			if bool(res.get("aceitou", false)):
				AudioManager.tocar_sfx("pechincha_sucesso")
				if _lbl_feedback != null:
					_lbl_feedback.text = "✨ O cliente aceitou %s!" % p_ref.nome_do_item
			else:
				AudioManager.tocar_sfx("pechincha_falha")
				if _lbl_feedback != null:
					_lbl_feedback.text = "⚠️ O cliente recusou a sugestão e perdeu paciência!"
			_atualizar_dados()
		)
		lista_botoes_sugestao.add_child(b)
	if not encontrou:
		var lbl_vazio := Label.new()
		lbl_vazio.text = "Não tens outras poções em stock para sugerir."
		lbl_vazio.add_theme_font_size_override("font_size", 8)
		lista_botoes_sugestao.add_child(lbl_vazio)

func _on_pechinchar_pressed() -> void:
	if _cliente_atual == null:
		return
	var res := _cliente_atual.tentar_pechincha()
	label_fala.text = "\"" + str(res.get("fala", "")) + "\""
	if bool(res.get("sucesso", false)):
		AudioManager.tocar_sfx("pechincha_sucesso")
		if _lbl_feedback != null:
			_lbl_feedback.text = "💰 Negócio fechado! Preço subiu para %d 🪙!" % int(res.get("novo_preco", 0))
	else:
		AudioManager.tocar_sfx("pechincha_falha")
		if _lbl_feedback != null:
			_lbl_feedback.text = "😠 O freguês recusou a sobretaxa e perdeu paciência!"
	_atualizar_dados()

func _on_desconto_pressed() -> void:
	if _cliente_atual == null:
		return
	var res := _cliente_atual.aplicar_desconto()
	AudioManager.tocar_sfx("pechincha_sucesso")
	label_fala.text = "\"" + str(res.get("fala", "")) + "\""
	if _lbl_feedback != null:
		_lbl_feedback.text = "🌟 Desconto concedido! Ganhaste +10 ⭐ de Fama!"
	_atualizar_dados()

func _on_dispensar_pressed() -> void:
	if _cliente_atual == null:
		return
	AudioManager.tocar_sfx("ui_click")
	_cliente_atual.dispensar_cliente()
	atendimento_concluido.emit(false, "Cliente dispensado.")
	fechar_painel()
