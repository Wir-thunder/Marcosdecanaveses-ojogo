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

func obter_ingrediente_selecionado() -> ItemData:
	if ingredientes.is_empty():
		return null
	indice_selecionado = posmod(indice_selecionado, ingredientes.size())
	return ingredientes[indice_selecionado]

func ciclar_stock() -> void:
	if ingredientes.is_empty():
		feedback.emit("O fornecedor não tem ingredientes.")
		return
	indice_selecionado = (indice_selecionado + 1) % ingredientes.size()
	var ingrediente := obter_ingrediente_selecionado()
	feedback.emit("Ingrediente selecionado: " + ingrediente.nome_do_item + ".")

func interagir(jogador: Player) -> void:
	var ingrediente := obter_ingrediente_selecionado()
	if ingrediente == null:
		feedback.emit("O fornecedor não tem ingredientes.")
		return
	if jogador.escudos < custo_por_ingrediente:
		feedback.emit("Precisas de %d escudos para comprar %s." % [
			custo_por_ingrediente,
			ingrediente.nome_do_item,
		])
		return

	jogador.escudos -= custo_por_ingrediente
	InventoryManager.adicionar_item(ingrediente.id)
	feedback.emit("Compraste %s por %d escudos." % [
		ingrediente.nome_do_item,
		custo_por_ingrediente,
	])
