class_name Caldeirao extends Area2D

signal receita_alterada(receita: PotionRecipeData)
signal pocao_preparada(pocao: ItemData)
signal feedback(mensagem: String)

@export var receitas: Array[PotionRecipeData] = []

var indice_receita: int = 0

func _ready() -> void:
	add_to_group("interactables")
	if receitas.is_empty():
		push_error("O caldeirão precisa de pelo menos uma receita configurada.")

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
	InventoryManager.adicionar_item(pocao.id)
	jogador.selecionar_pocao(pocao)
	pocao_preparada.emit(pocao)
	feedback.emit("Preparaste " + pocao.nome_do_item + ".")

func ciclar_receita() -> void:
	if receitas.is_empty():
		feedback.emit("O caldeirão não tem receitas.")
		return
	indice_receita = (indice_receita + 1) % receitas.size()
	var receita := obter_receita_atual()
	if receita != null:
		receita_alterada.emit(receita)
		feedback.emit("Receita selecionada: " + receita.pocao_resultante.nome_do_item + ".")

func obter_receita_atual() -> PotionRecipeData:
	if receitas.is_empty():
		return null
	indice_receita = posmod(indice_receita, receitas.size())
	return receitas[indice_receita]

func obter_resumo_receita() -> String:
	var receita := obter_receita_atual()
	if receita == null or receita.pocao_resultante == null:
		return "Sem receita"

	var ingredientes: PackedStringArray = []
	for ingrediente in receita.ingredientes_necessarios:
		if ingrediente != null:
			ingredientes.append("%s x%d" % [
				ingrediente.nome_do_item,
				InventoryManager.obter_quantidade(ingrediente.id),
			])
	return "%s: %s" % [receita.pocao_resultante.nome_do_item, ", ".join(ingredientes)]
