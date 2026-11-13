class_name Caldeirao extends Area2D

signal receita_alterada(receita: PotionRecipeData)
signal pocao_preparada(pocao: ItemData)
signal feedback(mensagem: String)

@export var receitas: Array[PotionRecipeData] = []

var indice_receita: int = 0
var _tempo_anim: float = 0.0
var _escala_base_caldeirao: Vector2 = Vector2.ONE

func _ready() -> void:
	add_to_group("interactables")
	var spr := get_node_or_null("Sprite2D") as Sprite2D
	if spr != null:
		_escala_base_caldeirao = spr.scale
	_carregar_receitas_desbloqueadas()
	_atualizar_visual_caldeirao()
	if not InventoryManager.loja_melhorada.is_connected(_ao_loja_melhorada):
		InventoryManager.loja_melhorada.connect(_ao_loja_melhorada)
	if not InventoryManager.mestria_desbloqueada.is_connected(_ao_mestria_desbloqueada):
		InventoryManager.mestria_desbloqueada.connect(_ao_mestria_desbloqueada)
	if receitas.is_empty():
		push_error("O caldeirão precisa de pelo menos uma receita configurada.")

func _ao_mestria_desbloqueada(_pocao_id: String, _nova_receita: String, _nome_pocao: String) -> void:
	_carregar_receitas_desbloqueadas()

func _process(delta: float) -> void:
	_tempo_anim += delta * 2.6
	var spr := get_node_or_null("Sprite2D") as Sprite2D
	if spr != null:
		var pulso_x := 1.0 + sin(_tempo_anim) * 0.018
		var pulso_y := 1.0 - sin(_tempo_anim) * 0.018
		spr.scale = Vector2(_escala_base_caldeirao.x * pulso_x, _escala_base_caldeirao.y * pulso_y)

func _ao_loja_melhorada(_id_upgrade: String, _novo_nivel: int) -> void:
	_carregar_receitas_desbloqueadas()
	_atualizar_visual_caldeirao()
	var r := obter_receita_atual()
	if r != null:
		receita_alterada.emit(r)

func _atualizar_visual_caldeirao() -> void:
	var spr := get_node_or_null("Sprite2D") as Sprite2D
	if spr == null:
		return
	match InventoryManager.nivel_caldeirao:
		1:
			spr.modulate = Color(0.76, 0.64, 0.56, 1.0) # Ferro enferrujado / gasto
		2:
			spr.modulate = Color(1.04, 0.94, 0.84, 1.0) # Cobre polido
		_:
			spr.modulate = Color(1.18, 1.08, 0.78, 1.0) # Athanor dourado

func _carregar_receitas_desbloqueadas() -> void:
	receitas.clear()
	for caminho in InventoryManager.receitas_desbloqueadas:
		var r: PotionRecipeData = load(caminho) as PotionRecipeData
		if r != null and not _tem_receita(r):
			receitas.append(r)
	if receitas.is_empty():
		var fallback := load("res://Recursos/Recursos_receitas/receita_vento_ligeiro.tres") as PotionRecipeData
		if fallback != null:
			receitas.append(fallback)

func _tem_receita(receita_nova: PotionRecipeData) -> bool:
	if receita_nova == null or receita_nova.pocao_resultante == null:
		return false
	for r in receitas:
		if r != null and r.pocao_resultante != null and r.pocao_resultante.id == receita_nova.pocao_resultante.id:
			return true
	return false

func obter_receita_por_pocao(pocao_id: String) -> PotionRecipeData:
	_carregar_receitas_desbloqueadas()
	for r in receitas:
		if r != null and r.pocao_resultante != null and r.pocao_resultante.id == pocao_id:
			return r
	return null

func pode_preparar_receita(receita: PotionRecipeData) -> bool:
	if receita == null or receita.pocao_resultante == null or receita.ingredientes_necessarios.is_empty():
		return false
	var quantidades_necessarias: Dictionary = {}
	for ingrediente in receita.ingredientes_necessarios:
		if ingrediente == null:
			return false
		quantidades_necessarias[ingrediente.id] = int(quantidades_necessarias.get(ingrediente.id, 0)) + 1
	for ingrediente_id in quantidades_necessarias:
		if InventoryManager.obter_quantidade(str(ingrediente_id)) < int(quantidades_necessarias[ingrediente_id]):
			return false
	return true

func selecionar_receita_indice(idx: int) -> void:
	if receitas.is_empty():
		return
	indice_receita = posmod(idx, receitas.size())
	var r := obter_receita_atual()
	if r != null:
		receita_alterada.emit(r)

func preparar_receita_especifica(receita: PotionRecipeData, jogador: Player) -> bool:
	if receita == null:
		return false
	for i in range(receitas.size()):
		if receitas[i] == receita or (receitas[i].pocao_resultante != null and receita.pocao_resultante != null and receitas[i].pocao_resultante.id == receita.pocao_resultante.id):
			indice_receita = i
			break
	var qtd_antes := InventoryManager.obter_quantidade(receita.pocao_resultante.id) if receita.pocao_resultante != null else 0
	interagir(jogador)
	var qtd_depois := InventoryManager.obter_quantidade(receita.pocao_resultante.id) if receita.pocao_resultante != null else 0
	return qtd_depois > qtd_antes

func interagir(jogador: Player) -> void:
	var receita := obter_receita_atual()
	if receita == null or receita.pocao_resultante == null:
		feedback.emit("Não há receita selecionada.")
		return
	if receita.ingredientes_necessarios.is_empty():
		feedback.emit("Esta receita não tem ingredientes configurados.")
		return

	var quantidades_necessarias: Dictionary = {}
	var ingredientes_por_id: Dictionary = {}
	for ingrediente in receita.ingredientes_necessarios:
		if ingrediente == null:
			feedback.emit("A receita contém um ingrediente inválido.")
			return
		quantidades_necessarias[ingrediente.id] = int(quantidades_necessarias.get(ingrediente.id, 0)) + 1
		ingredientes_por_id[ingrediente.id] = ingrediente

	for ingrediente_id in quantidades_necessarias:
		var ingrediente: ItemData = ingredientes_por_id[ingrediente_id]
		var quantidade: int = quantidades_necessarias[ingrediente_id]
		if InventoryManager.obter_quantidade(ingrediente_id) < quantidade:
			feedback.emit("Falta ingrediente: " + ingrediente.nome_do_item)
			return

	for ingrediente_id in quantidades_necessarias:
		var quantidade: int = quantidades_necessarias[ingrediente_id]
		if not InventoryManager.remover_item(ingrediente_id, quantidade):
			push_error("O inventário mudou durante a preparação da receita.")
			return

	var pocao := receita.pocao_resultante
	var dose_dupla: bool = randf() < InventoryManager.obter_chance_dose_dupla()
	InventoryManager.adicionar_item(pocao.id, 2 if dose_dupla else 1)
	AudioManager.tocar_sfx("caldeirao")
	AudioManager.tocar_sfx("pocao_pronta")
	
	# Bônus de Mestria Swords & Potions
	var res_mestria: Dictionary = InventoryManager.registrar_preparo_pocao(pocao.id)
	var contagem: int = res_mestria["contagem"]
	
	# Chance de qualidade ouro automática baseada na mestria + nível do caldeirão
	var chance_ouro: float = 0.22 if InventoryManager.nivel_caldeirao >= 3 else 0.0
	if contagem >= 5:
		chance_ouro += 0.35
	elif contagem >= 3:
		chance_ouro += 0.20
		
	var bonus_ouro_obtido: bool = false
	if randf() < chance_ouro:
		InventoryManager.adicionar_item_ouro(pocao.id, 1)
		bonus_ouro_obtido = true
		
	# Desbloqueio de nova receita na árvore
	if bool(res_mestria.get("desbloqueou_receita", false)):
		var nova_caminho: String = str(res_mestria.get("nova_receita", ""))
		var r_nova: PotionRecipeData = load(nova_caminho) as PotionRecipeData
		if r_nova != null and not _tem_receita(r_nova):
			receitas.append(r_nova)
		feedback.emit("🌟 MESTRIA ALCANÇADA! Desbloqueaste a receita de %s!" % res_mestria["nome_nova_pocao"])
	elif dose_dupla and bonus_ouro_obtido:
		feedback.emit("✨⚗️ DOSE DUPLA + OURO! Preparaste 2× %s!" % pocao.nome_do_item)
	elif dose_dupla:
		feedback.emit("⚗️ DOSE DUPLA do Caldeirão! Preparaste 2× %s!" % pocao.nome_do_item)
	elif bonus_ouro_obtido:
		feedback.emit("✨ Destilação Perfeita! %s obteve QUALIDADE OURO!" % pocao.nome_do_item)
	else:
		feedback.emit("Preparaste %s (Mestria %d/5)." % [pocao.nome_do_item, mini(5, contagem)])

	jogador.selecionar_pocao(pocao)
	pocao_preparada.emit(pocao)

func ciclar_receita() -> void:
	if receitas.is_empty():
		feedback.emit("O caldeirão não tem receitas.")
		return
	indice_receita = (indice_receita + 1) % receitas.size()
	AudioManager.tocar_sfx("ui_click")
	var receita := obter_receita_atual()
	if receita != null:
		receita_alterada.emit(receita)
		var mestria := InventoryManager.obter_mestria(receita.pocao_resultante.id)
		feedback.emit("Receita: %s (Mestria: %d/5 · %s)." % [
			receita.pocao_resultante.nome_do_item,
			mini(5, mestria),
			InventoryManager.obter_nivel_mestria(receita.pocao_resultante.id)
		])

func obter_receita_atual() -> PotionRecipeData:
	if receitas.is_empty():
		return null
	indice_receita = posmod(indice_receita, receitas.size())
	return receitas[indice_receita]

func obter_resumo_receita() -> String:
	var receita := obter_receita_atual()
	if receita == null or receita.pocao_resultante == null:
		return "Sem receita"

	var mestria := InventoryManager.obter_mestria(receita.pocao_resultante.id)
	var nivel := InventoryManager.obter_nivel_mestria(receita.pocao_resultante.id)
	var ingredientes: PackedStringArray = []
	for ingrediente in receita.ingredientes_necessarios:
		if ingrediente != null:
			ingredientes.append("%s ×%d" % [
				ingrediente.nome_do_item,
				InventoryManager.obter_quantidade(ingrediente.id),
			])
	return "%s [%d/5 %s]: %s" % [
		receita.pocao_resultante.nome_do_item,
		mini(5, mestria),
		nivel,
		", ".join(ingredientes)
	]
