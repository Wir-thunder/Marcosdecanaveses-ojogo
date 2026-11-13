extends Node2D

@export var nome_local: String = "Exploração"

@onready var jogador: Player = $Player
@onready var estado_label: Label = $Interface/Estado
@onready var instrucao_label: Label = $Interface/Instrucao
@onready var modulador_luz: CanvasModulate = get_node_or_null("ModuladorLuz")

var _mensagem_temporaria: String = ""
var _tempo_mensagem: float = 0.0
var _tempo_ambiente: float = 0.0
var _props_oscilantes: Array[Dictionary] = []
var _objetivo_label: Label = null

func _ready() -> void:
	_atualizar_iluminacao()
	_estilizar_hud_exploracao()
	AudioManager.tocar_musica_area(nome_local, CampaignManager.esta_de_noite())
	var chave := nome_local.to_lower()
	if "floresta" in chave or "tamega" in chave or "tâmega" in chave:
		AudioManager.tocar_sfx_volume("vento_floresta", -8.0, 0.06)
	elif "feira" in chave:
		AudioManager.tocar_sfx_volume("ambiente_loja", -8.5, 0.05)
	_registar_props_animados()
	for filho in get_children():
		if filho is Fornecedor:
			(filho as Fornecedor).feedback.connect(mostrar_mensagem)
	_atualizar_interface()

func _estilizar_hud_exploracao() -> void:
	var hud := get_node_or_null("Interface") as CanvasLayer
	if hud != null and not hud.has_node("FaixaTopoHUD"):
		var st_t := StyleBoxFlat.new()
		st_t.bg_color = Color(0.09, 0.07, 0.05, 0.91)
		st_t.border_color = Color(0.78, 0.60, 0.26, 0.95)
		st_t.set_border_width_all(1)
		st_t.border_width_bottom = 2
		st_t.set_corner_radius_all(5)
		st_t.shadow_color = Color(0, 0, 0, 0.45)
		st_t.shadow_size = 4

		var faixa_topo := Panel.new()
		faixa_topo.name = "FaixaTopoHUD"
		faixa_topo.position = Vector2(6, 5)
		faixa_topo.size = Vector2(628, 26)
		faixa_topo.mouse_filter = Control.MOUSE_FILTER_IGNORE
		faixa_topo.add_theme_stylebox_override("panel", st_t)
		hud.add_child(faixa_topo)
		hud.move_child(faixa_topo, 0)

		var st_r := StyleBoxFlat.new()
		st_r.bg_color = Color(0.09, 0.07, 0.05, 0.91)
		st_r.border_color = Color(0.72, 0.54, 0.24, 0.95)
		st_r.set_border_width_all(1)
		st_r.border_width_top = 2
		st_r.set_corner_radius_all(5)
		st_r.shadow_color = Color(0, 0, 0, 0.45)
		st_r.shadow_size = 4

		var faixa_rod := Panel.new()
		faixa_rod.name = "FaixaRodapeHUD"
		faixa_rod.position = Vector2(6, 330)
		faixa_rod.size = Vector2(628, 24)
		faixa_rod.mouse_filter = Control.MOUSE_FILTER_IGNORE
		faixa_rod.add_theme_stylebox_override("panel", st_r)
		hud.add_child(faixa_rod)
		hud.move_child(faixa_rod, 1)

	if hud != null and not hud.has_node("ObjetivoBadge"):
		var badge := PanelContainer.new()
		badge.name = "ObjetivoBadge"
		badge.position = Vector2(8, 34)
		badge.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var st_b := StyleBoxFlat.new()
		st_b.bg_color = Color(0.09, 0.07, 0.05, 0.88)
		st_b.border_color = Color(0.78, 0.60, 0.26, 0.90)
		st_b.set_border_width_all(1)
		st_b.set_corner_radius_all(4)
		badge.add_theme_stylebox_override("panel", st_b)

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

	if hud != null and not hud.has_node("PausaHintBadge"):
		var pausa_badge := PanelContainer.new()
		pausa_badge.name = "PausaHintBadge"
		pausa_badge.position = Vector2(556, 333)
		pausa_badge.size = Vector2(72, 18)
		pausa_badge.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var st_p := StyleBoxFlat.new()
		st_p.bg_color = Color(0.14, 0.10, 0.07, 0.95)
		st_p.border_color = Color(0.78, 0.60, 0.26, 0.90)
		st_p.set_border_width_all(1)
		st_p.set_corner_radius_all(3)
		pausa_badge.add_theme_stylebox_override("panel", st_p)

		var lbl_p := Label.new()
		lbl_p.text = "[ESC] Pausa"
		lbl_p.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		lbl_p.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		lbl_p.mouse_filter = Control.MOUSE_FILTER_IGNORE
		lbl_p.add_theme_font_size_override("font_size", 9)
		lbl_p.add_theme_color_override("font_color", Color(0.96, 0.85, 0.55, 1.0))
		lbl_p.add_theme_color_override("font_outline_color", Color(0.04, 0.03, 0.02, 0.95))
		lbl_p.add_theme_constant_override("outline_size", 2)
		pausa_badge.add_child(lbl_p)
		hud.add_child(pausa_badge)

	if estado_label != null:
		estado_label.add_theme_font_size_override("font_size", 12)
		estado_label.add_theme_color_override("font_color", Color(0.96, 0.90, 0.74, 1.0))
		estado_label.add_theme_color_override("font_outline_color", Color(0.04, 0.03, 0.02, 0.95))
		estado_label.add_theme_constant_override("outline_size", 2)
	if instrucao_label != null:
		instrucao_label.offset_right = 548.0
		instrucao_label.add_theme_font_size_override("font_size", 10)
		instrucao_label.add_theme_color_override("font_color", Color(0.96, 0.78, 0.48, 1.0))
		instrucao_label.add_theme_color_override("font_outline_color", Color(0.04, 0.03, 0.02, 0.95))
		instrucao_label.add_theme_constant_override("outline_size", 2)

func _registar_props_animados() -> void:
	_props_oscilantes.clear()
	for filho in get_children():
		if filho is Sprite2D:
			var spr := filho as Sprite2D
			var n := spr.name.to_lower()
			if "arvore" in n or "planta" in n or "arbusto" in n:
				_props_oscilantes.append({
					"node": spr,
					"tipo": "vento",
					"pos_base": spr.position,
					"escala_base": spr.scale,
					"fase": randf_range(0.0, 6.28)
				})
			elif "fonte" in n or "agua" in n:
				_props_oscilantes.append({
					"node": spr,
					"tipo": "agua",
					"pos_base": spr.position,
					"escala_base": spr.scale,
					"fase": randf_range(0.0, 6.28)
				})
			elif "banca" in n or "tenda" in n:
				_props_oscilantes.append({
					"node": spr,
					"tipo": "banca",
					"pos_base": spr.position,
					"escala_base": spr.scale,
					"fase": randf_range(0.0, 6.28)
				})

func _atualizar_iluminacao() -> void:
	if modulador_luz == null:
		return
	var chave := nome_local.to_lower()
	if CampaignManager.esta_de_noite():
		if "praça" in chave or "praca" in chave:
			modulador_luz.color = Color(0.84, 0.85, 0.94, 1.0)
		else:
			modulador_luz.color = Color(0.55, 0.58, 0.76, 1.0)
	else:
		modulador_luz.color = Color(0.96, 0.94, 0.90, 1.0)

func _process(delta: float) -> void:
	_tempo_ambiente += delta
	for item in _props_oscilantes:
		var spr: Sprite2D = item["node"]
		if not is_instance_valid(spr):
			continue
		var fase: float = float(item["fase"])
		var tipo_p: String = str(item["tipo"])
		var esc_base: Vector2 = item["escala_base"]
		if tipo_p == "vento":
			spr.rotation = sin(_tempo_ambiente * 1.8 + fase) * 0.022
			spr.scale = Vector2(esc_base.x * (1.0 + sin(_tempo_ambiente * 1.4 + fase) * 0.012), esc_base.y)
		elif tipo_p == "agua":
			var p := 1.0 + sin(_tempo_ambiente * 3.2 + fase) * 0.018
			spr.scale = Vector2(esc_base.x * p, esc_base.y * (2.0 - p))
		elif tipo_p == "banca":
			spr.scale = Vector2(esc_base.x, esc_base.y * (1.0 + sin(_tempo_ambiente * 2.4 + fase) * 0.012))

	if _tempo_mensagem > 0.0:
		_tempo_mensagem -= delta
		if _tempo_mensagem <= 0.0:
			_mensagem_temporaria = ""
	_atualizar_interface()

func mostrar_mensagem(texto: String) -> void:
	_mensagem_temporaria = texto
	_tempo_mensagem = 3.0
	_atualizar_interface()

func _atualizar_interface() -> void:
	if estado_label == null or instrucao_label == null or jogador == null:
		return

	var estado: String
	if CampaignManager.esta_de_noite():
		estado = "🌙 %s %d (%s)  ·  🪙 %d %s  ·  ⭐ %d %s  ·  %s" % [
			tr("EXP_DIA"),
			CampaignManager.dia,
			tr("EXP_NOITE"),
			jogador.escudos,
			tr("LOJA_OURO"),
			InventoryManager.renome_loja,
			tr("LOJA_FAMA"),
			nome_local.to_upper(),
		]
	else:
		estado = "☀️ %s %d (%ds)  ·  🪙 %d %s  ·  ⭐ %d %s  ·  %s" % [
			tr("EXP_DIA"),
			CampaignManager.dia,
			ceili(CampaignManager.tempo_turno),
			jogador.escudos,
			tr("LOJA_OURO"),
			InventoryManager.renome_loja,
			tr("LOJA_FAMA"),
			nome_local.to_upper(),
		]
	estado_label.text = _mensagem_temporaria if _tempo_mensagem > 0.0 else estado

	if _objetivo_label != null:
		if CampaignManager.esta_de_noite():
			_objetivo_label.text = "🎯 Objetivo: Explora a Floresta / Taverna / Arena"
		else:
			_objetivo_label.text = "🎯 Objetivo: Entra na Botica do Marco a leste para preparar poções"

	var alvo := jogador.obter_alvo_interacao()
	if alvo is Fornecedor:
		var forn := alvo as Fornecedor
		var ing := forn.obter_ingrediente_selecionado()
		var nome_ing := ing.nome_do_item if ing != null else "Ingrediente"
		instrucao_label.text = "E  COMPRAR %s (%d 🪙)  ·  F  MUDAR MERCADORIA" % [nome_ing.to_upper(), forn.custo_por_ingrediente]
	elif alvo != null and alvo.has_method("obter_texto_interacao"):
		instrucao_label.text = str(alvo.call("obter_texto_interacao"))
	else:
		instrucao_label.text = "WASD / SETAS mover  ·  ENTER / E interagir"
