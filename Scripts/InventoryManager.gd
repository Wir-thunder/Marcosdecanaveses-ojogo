extends Node

# Um dicionário que guarda o ID do item e a quantidade que tens. Ex: {"musgo_aboboreira": 5}
var inventario: Dictionary = {}

# Função para adicionar itens
func adicionar_item(item_id: String, quantidade: int = 1):
	if inventario.has(item_id):
		inventario[item_id] += quantidade
	else:
		inventario[item_id] = quantidade
	print("Adicionaste ", quantidade, "x ", item_id, ". Total: ", inventario[item_id])

# Função para remover itens (ex: quando gastas num caldeirão)
func remover_item(item_id: String, quantidade: int = 1) -> bool:
	if inventario.has(item_id) and inventario[item_id] >= quantidade:
		inventario[item_id] -= quantidade
		if inventario[item_id] == 0:
			inventario.erase(item_id)
		print("Removeste ", quantidade, "x ", item_id)
		return true
	print("Não tens ingredientes suficientes!")
	return false

func obter_quantidade(item_id: String) -> int:
	return int(inventario.get(item_id, 0))
