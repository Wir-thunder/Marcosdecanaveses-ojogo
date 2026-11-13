class_name Fornecedor extends Area2D

signal feedback(mensagem: String)

@export var ingredientes: Array[ItemData] = [
	preload("res://Recursos/Recursos_ingredientes/hortela_nobre.tres"),
	preload("res://Recursos/Recursos_ingredientes/musgo_aboboreira.tres"),
	preload("res://Recursos/Recursos_ingredientes/arnica_selvagem.tres"),
	preload("res://Recursos/Recursos_ingredientes/calcedonia_fina.tres"),
	preload("res://Recursos/Recursos_ingredientes/erva_cidreira.tres"),
	preload("res://Recursos/Recursos_ingredientes/po_granito_tongobriga.tres"),
	preload("res://Recursos/Recursos_ingredientes/azeite_do_olival.tres"),
]
@export var custo_por_ingrediente: int = 5

var indice_selecionado: int = 0

func _ready() -> void:
	add_to_group("interactables")
	if not InventoryManager.loja_melhorada.is_connected(_ao_loja_melhorada):
		InventoryManager.loja_melhorada.connect(_ao_loja_melhorada)
	if not InventoryManager.mestria_desbloqueada.is_connected(_ao_mestria_desbloqueada):
		InventoryManager.mestria_desbloqueada.connect(_ao_mestria_desbloqueada)
	_atualizar_nivel_fornecedor()
	_sincronizar_ingredientes_receitas()

func _ao_loja_melhorada(_id_upgrade: String, _novo_nivel: int) -> void:
	_atualizar_nivel_fornecedor()
	_sincronizar_ingredientes_receitas()

func _ao_mestria_desbloqueada(_pocao_id: String, _nova_receita: String, _nome_pocao: String) -> void:
	_sincronizar_ingredientes_receitas()

func _sincronizar_ingredientes_receitas() -> void:
	for caminho in InventoryManager.receitas_desbloqueadas:
		var rec := load(caminho) as PotionRecipeData
		if rec == null:
			continue
		for ing in rec.ingredientes_necessarios:
			if ing != null and not _tem_ingrediente(ing.id):
				ingredientes.append(ing)

func _tem_ingrediente(id_ing: String) -> bool:
	for it in ingredientes:
		if it != null and it.id == id_ing:
			return true
	return false

func _atualizar_nivel_fornecedor() -> void:
	match InventoryManager.nivel_fornecedor:
		1:
			custo_por_ingrediente = 5
		2:
			custo_por_ingrediente = 4
		_:
			custo_por_ingrediente = 3

func _obter_limite_stock() -> int:
	_sincronizar_ingredientes_receitas()
	if ingredientes.is_empty():
		return 0
	var min_necessarios: int = 3
	for caminho in InventoryManager.receitas_desbloqueadas:
		var rec := load(caminho) as PotionRecipeData
		if rec == null:
			continue
		for ing in rec.ingredientes_necessarios:
			if ing == null:
				continue
			for i in range(ingredientes.size()):
				if ingredientes[i] != null and ingredientes[i].id == ing.id:
					min_necessarios = maxi(min_necessarios, i + 1)
	match InventoryManager.nivel_fornecedor:
		1:
			return maxi(min_necessarios, mini(3, ingredientes.size()))
		2:
			return maxi(min_necessarios, mini(5, ingredientes.size()))
		_:
			return ingredientes.size()

func obter_ingredientes_disponiveis() -> Array[ItemData]:
	var lista: Array[ItemData] = []
	var lim := _obter_limite_stock()
	for i in range(lim):
		if ingredientes[i] != null:
			lista.append(ingredientes[i])
	return lista

func obter_custo_ingrediente(ingrediente: ItemData) -> int:
	if ingrediente == null:
		return custo_por_ingrediente
	var ids_basicos := ["hortela_nobre", "musgo_aboboreira", "arnica_selvagem", "calcedonia_fina", "erva_cidreira", "po_granito_tongobriga", "azeite_do_olival"]
	if ingrediente.id in ids_basicos:
		return custo_por_ingrediente
	return custo_por_ingrediente + 2

func comprar_ingrediente_direto(ingrediente: ItemData, qtd: int, jogador: Player) -> Dictionary:
	if ingrediente == null or jogador == null or qtd <= 0:
		return {"sucesso": false, "mensagem": "Ingrediente inválido."}
	var custo_unit := obter_custo_ingrediente(ingrediente)
	var custo_total := custo_unit * qtd
	if jogador.escudos < custo_total:
		AudioManager.tocar_sfx("pechincha_falha")
		return {"sucesso": false, "mensagem": "Precisas de %d escudos para comprar %dx %s." % [custo_total, qtd, ingrediente.nome_do_item]}
	jogador.escudos -= custo_total
	InventoryManager.adicionar_item(ingrediente.id, qtd)
	AudioManager.tocar_sfx("moedas")
	var spr := get_node_or_null("Sprite2D") as Sprite2D
	if spr != null:
		var escala_base := spr.scale
		var tw := create_tween()
		tw.tween_property(spr, "scale", escala_base * 1.12, 0.08)
		tw.tween_property(spr, "scale", escala_base, 0.12)
	var msg := "Compraste %dx %s por %d escudos." % [qtd, ingrediente.nome_do_item, custo_total]
	feedback.emit(msg)
	return {"sucesso": true, "mensagem": msg}

func obter_ingrediente_selecionado() -> ItemData:
	var limite := _obter_limite_stock()
	if limite <= 0:
		return null
	indice_selecionado = posmod(indice_selecionado, limite)
	return ingredientes[indice_selecionado]

func ciclar_stock() -> void:
	var limite := _obter_limite_stock()
	if limite <= 0:
		feedback.emit("O fornecedor não tem ingredientes.")
		return
	indice_selecionado = (indice_selecionado + 1) % limite
	AudioManager.tocar_sfx("ui_click")
	var ingrediente := obter_ingrediente_selecionado()
	feedback.emit("Ingrediente selecionado: %s (%d escudos · Nv.%d Fornecedor)." % [
		ingrediente.nome_do_item,
		custo_por_ingrediente,
		InventoryManager.nivel_fornecedor
	])

func interagir(jogador: Player) -> void:
	var ingrediente := obter_ingrediente_selecionado()
	if ingrediente == null:
		feedback.emit("O fornecedor não tem ingredientes.")
		return
	if jogador.escudos < custo_por_ingrediente:
		AudioManager.tocar_sfx("pechincha_falha")
		feedback.emit("Precisas de %d escudos para comprar %s." % [
			custo_por_ingrediente,
			ingrediente.nome_do_item,
		])
		return

	jogador.escudos -= custo_por_ingrediente
	InventoryManager.adicionar_item(ingrediente.id)
	AudioManager.tocar_sfx("moedas")
	var spr := get_node_or_null("Sprite2D") as Sprite2D
	if spr != null:
		var escala_base := spr.scale
		var tw := create_tween()
		tw.tween_property(spr, "scale", escala_base * 1.12, 0.08)
		tw.tween_property(spr, "scale", escala_base, 0.12)
	feedback.emit("Compraste %s por %d escudos." % [
		ingrediente.nome_do_item,
		custo_por_ingrediente,
	])
