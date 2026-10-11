extends Area2D

@export_file("*.tscn") var cena_destino: String
@export var posicao_entrada: Vector2 = Vector2(320.0, 180.0)
@export var destino_label: String = "ENTRAR"
@export var apenas_a_noite: bool = false
@export var entrar_ao_tocar: bool = false

@onready var etiqueta: Label = $Etiqueta

var _transicao_em_curso: bool = false

func _ready() -> void:
	etiqueta.text = destino_label
	add_to_group("interactables")
	if entrar_ao_tocar:
		body_entered.connect(_ao_jogador_entrar)

func obter_texto_interacao() -> String:
	if apenas_a_noite and not CampaignManager.esta_de_noite():
		return "FECHADO DURANTE O TURNO"
	return "E  " + destino_label

func interagir(_jogador: Player) -> void:
	_mudar_de_cena()

func _ao_jogador_entrar(body: Node2D) -> void:
	if body is Player:
		_mudar_de_cena()

func _mudar_de_cena() -> void:
	if _transicao_em_curso:
		return
	if apenas_a_noite and not CampaignManager.esta_de_noite():
		return
	if cena_destino.is_empty():
		push_error("A porta %s não tem uma cena de destino configurada." % name)
		return
	_transicao_em_curso = true
	SceneRouter.ir_para(cena_destino, posicao_entrada)
