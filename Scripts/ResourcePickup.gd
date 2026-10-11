extends Area2D

enum Tipo { INGREDIENTE, ESCUDOS }

const CRISTAL_PIXEL: Texture2D = preload("res://Assets/Environment/items/cristal_pixel.png")
const MOEDA_PIXEL: Texture2D = preload("res://Assets/Environment/items/moeda_pixel.png")

@export var tipo: Tipo = Tipo.INGREDIENTE
@export var item_id: String = ""
@export var recolha_id: String = ""
@export var nome_exibicao: String = ""
@export_range(1, 99) var quantidade: int = 1
@export var cor: Color = Color(0.52, 0.78, 0.42, 1.0)

@onready var icone: Sprite2D = $Icone
@onready var etiqueta: Label = $Etiqueta

func _ready() -> void:
	if recolha_id.is_empty():
		push_error("O recurso %s precisa de um recolha_id único." % name)
		queue_free()
		return
	if InventoryManager.foi_recolhido(recolha_id):
		queue_free()
		return
	icone.texture = MOEDA_PIXEL if tipo == Tipo.ESCUDOS else CRISTAL_PIXEL
	icone.modulate = cor
	etiqueta.text = nome_exibicao if not nome_exibicao.is_empty() else _nome()
	add_to_group("interactables")

func obter_texto_interacao() -> String:
	return "E  RECOLHER " + _nome()

func interagir(jogador: Player) -> void:
	if tipo == Tipo.ESCUDOS:
		jogador.escudos += quantidade
	else:
		if item_id.is_empty():
			push_error("O recurso %s não tem item_id configurado." % name)
			return
		InventoryManager.adicionar_item(item_id, quantidade)

	InventoryManager.marcar_recolhido(recolha_id)
	var mensagem := "Encontraste %d escudos." % quantidade if tipo == Tipo.ESCUDOS else "Recolheste %s ×%d." % [_nome(), quantidade]
	var cena_atual := get_tree().current_scene
	if cena_atual != null and cena_atual.has_method("mostrar_mensagem"):
		cena_atual.call("mostrar_mensagem", mensagem)
	queue_free()

func _nome() -> String:
	if not nome_exibicao.is_empty():
		return nome_exibicao
	if tipo == Tipo.ESCUDOS:
		return "ouro"
	return item_id.replace("_", " ").capitalize()
