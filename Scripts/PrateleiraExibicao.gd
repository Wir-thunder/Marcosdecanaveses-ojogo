class_name PrateleiraExibicao extends Area2D

signal feedback(mensagem: String)

@export var max_itens: int = 3
var itens_exibidos: Array[ItemData] = []

@onready var label_status: Label = get_node_or_null("LabelStatus")
@onready var particulas: CPUParticles2D = get_node_or_null("Particulas")

func _ready() -> void:
	add_to_group("interactables")
	if label_status != null:
		label_status.visible = false
	if not InventoryManager.loja_melhorada.is_connected(_ao_loja_melhorada):
		InventoryManager.loja_melhorada.connect(_ao_loja_melhorada)
	_atualizar_visual()

func _ao_loja_melhorada(_id_upgrade: String, _novo_nivel: int) -> void:
	_atualizar_visual()

func obter_texto_interacao() -> String:
	if InventoryManager.nivel_vitrine <= 0:
		return "VITRINE QUEBRADA  ·  PRIME [M] PARA CONSERTAR (15 OURO)"
	if itens_exibidos.is_empty():
		return "E  EXIBIR POÇÃO NA VITRINE (0/%d)" % max_itens
	var nomes: PackedStringArray = []
	for it in itens_exibidos:
		nomes.append(it.nome_do_item.replace("Poção ", ""))
	return "E  VITRINE (%d/%d: %s)" % [itens_exibidos.size(), max_itens, ", ".join(nomes)]

func interagir(jogador: Player) -> void:
	if jogador == null:
		return
	if InventoryManager.nivel_vitrine <= 0:
		AudioManager.tocar_sfx("pechincha_falha")
		feedback.emit("🪟 A vitrine está partida e cheia de teias! Abre o Menu de Obras [M] (15 escudos) para consertar.")
		return

	# Se tiver poção ativa e a estante não estiver cheia, coloca na exibição
	if jogador.pocao_ativa != null and itens_exibidos.size() < max_itens:
		var pocao := jogador.pocao_ativa
		if InventoryManager.obter_quantidade(pocao.id) > 0:
			InventoryManager.remover_item(pocao.id)
			itens_exibidos.append(pocao)
			InventoryManager.adicionar_renome(5)
			jogador.atualizar_pocao_apos_venda()
			AudioManager.tocar_sfx("pocao_pronta")
			_atualizar_visual()
			var pct := roundi((obter_bonus_ouro() - 1.0) * 100.0)
			feedback.emit("Colocaste %s na vitrine! (+5 Fama · +%d%% valor nas vendas)" % [pocao.nome_do_item, pct])
			return

	# Se já tiver itens e interagir sem poção ativa, recolhe da vitrine
	if not itens_exibidos.is_empty():
		var recolhida: ItemData = itens_exibidos.pop_back()
		InventoryManager.adicionar_item(recolhida.id)
		jogador.selecionar_pocao(recolhida)
		AudioManager.tocar_sfx("passo_madeira")
		_atualizar_visual()
		feedback.emit("Recolheste %s da vitrine." % recolhida.nome_do_item)
	else:
		AudioManager.tocar_sfx("ui_click")
		feedback.emit("Vitrine vazia! Seleciona uma poção e pressiona E para exibi-la.")

func obter_bonus_ouro() -> float:
	if InventoryManager.nivel_vitrine <= 0:
		return 1.0
	var por_pocao := 0.10 if InventoryManager.nivel_vitrine == 1 else 0.12
	return 1.0 + float(itens_exibidos.size()) * por_pocao

func _atualizar_visual() -> void:
	if InventoryManager.nivel_vitrine <= 0:
		max_itens = 0
		modulate = Color(0.48, 0.42, 0.38, 0.92) # Quebrada / escura
	elif InventoryManager.nivel_vitrine == 1:
		max_itens = 2
		modulate = Color(0.95, 0.90, 0.84, 1.0) # Madeira reparada
	else:
		max_itens = 4
		modulate = Color(1.15, 1.08, 0.86, 1.0) # Vitrine Real iluminada
	InventoryManager.bonus_ouro_vitrine_atual = obter_bonus_ouro()
	if particulas != null:
		particulas.emitting = (InventoryManager.nivel_vitrine > 0 and not itens_exibidos.is_empty())
	_atualizar_icones_prateleira()
	if label_status != null:
		if InventoryManager.nivel_vitrine <= 0:
			label_status.visible = true
			label_status.text = "🪟 Quebrada [M]"
			label_status.add_theme_color_override("font_color", Color(0.92, 0.55, 0.45))
		elif itens_exibidos.is_empty():
			label_status.visible = true
			label_status.text = "Vitrine (0/%d)" % max_itens
			label_status.add_theme_color_override("font_color", Color(0.88, 0.82, 0.65))
		else:
			label_status.visible = true
			var pct := roundi((obter_bonus_ouro() - 1.0) * 100.0)
			label_status.text = "✨ +%d%% Ouro (%d/%d)" % [pct, itens_exibidos.size(), max_itens]
			label_status.add_theme_color_override("font_color", Color(1.0, 0.90, 0.38))

func _atualizar_icones_prateleira() -> void:
	var container := get_node_or_null("ItensVisuais") as Node2D
	if container == null:
		container = Node2D.new()
		container.name = "ItensVisuais"
		container.z_index = 2
		add_child(container)
	for c in container.get_children():
		c.queue_free()
	var offsets: Array[Vector2] = [
		Vector2(-10, -24),
		Vector2(10, -24),
		Vector2(-10, -6),
		Vector2(10, -6),
	]
	for i in range(mini(itens_exibidos.size(), offsets.size())):
		var item: ItemData = itens_exibidos[i]
		if item == null or item.icone == null:
			continue
		var spr := Sprite2D.new()
		spr.texture = item.icone
		spr.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		var tam := item.icone.get_size()
		var esc := 15.0 / maxf(1.0, maxf(tam.x, tam.y))
		spr.scale = Vector2(esc, esc)
		spr.position = offsets[i]
		container.add_child(spr)
