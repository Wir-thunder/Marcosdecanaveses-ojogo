extends Node2D

@export var nome_local: String = "Exploração"

@onready var jogador: Player = $Player
@onready var estado_label: Label = $Interface/Estado
@onready var instrucao_label: Label = $Interface/Instrucao

var _mensagem_temporaria: String = ""
var _tempo_mensagem: float = 0.0

func _ready() -> void:
	_atualizar_interface()

func _process(delta: float) -> void:
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
		estado = "DIA %d · NOITE · OURO %d  ·  %s" % [
			CampaignManager.dia,
			jogador.escudos,
			nome_local.to_upper(),
		]
	else:
		estado = "DIA %d · LOJA %ds · OURO %d  ·  %s" % [
			CampaignManager.dia,
			ceili(CampaignManager.tempo_turno),
			jogador.escudos,
			nome_local.to_upper(),
		]
	estado_label.text = _mensagem_temporaria if _tempo_mensagem > 0.0 else estado

	var alvo := jogador.obter_alvo_interacao()
	if alvo != null and alvo.has_method("obter_texto_interacao"):
		instrucao_label.text = str(alvo.call("obter_texto_interacao"))
	else:
		instrucao_label.text = "WASD / SETAS mover  ·  E interagir"
