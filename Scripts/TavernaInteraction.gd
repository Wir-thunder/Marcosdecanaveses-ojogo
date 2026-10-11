extends Node2D

func _ready() -> void:
	add_to_group("interactables")

func obter_texto_interacao() -> String:
	return str(get_parent().call("obter_texto_interacao"))

func interagir(_jogador: Player) -> void:
	get_parent().call("alternar_painel")
