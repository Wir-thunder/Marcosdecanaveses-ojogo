extends Area2D

@export_file("*.tscn") var cena_destino: String
@export var posicao_entrada: Vector2 = Vector2(320.0, 180.0)
@export var destino_label: String = "ENTRAR"
@export var titulo_area: String = ""
@export_multiline var descricao_area: String = ""
@export var icone_simbolo: String = "🏛️"
@export var apenas_a_noite: bool = false
@export var entrar_ao_tocar: bool = false

@onready var etiqueta: Label = get_node_or_null("Etiqueta")
@onready var plaquinha: PanelContainer = get_node_or_null("CamadaUI/Plaquinha")
@onready var titulo_label: Label = get_node_or_null("CamadaUI/Plaquinha/Conteudo/Cabecalho/Titulo")
@onready var icone_label: Label = get_node_or_null("CamadaUI/Plaquinha/Conteudo/Cabecalho/IconeBadge")
@onready var descricao_label: Label = get_node_or_null("CamadaUI/Plaquinha/Conteudo/Descricao")
@onready var botao_entrar: Button = get_node_or_null("CamadaUI/Plaquinha/Conteudo/BotaoEntrar")

var _transicao_em_curso: bool = false
var _jogador_no_alcance: bool = false
var _tween_fade: Tween

func _ready() -> void:
	_atualizar_etiqueta()
	if etiqueta != null:
		etiqueta.visible = false
	add_to_group("interactables")
	
	if plaquinha != null:
		plaquinha.visible = false
		plaquinha.modulate.a = 0.0

	if botao_entrar != null:
		botao_entrar.pressed.connect(_on_botao_entrar_pressed)

	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)

	if CampaignManager != null and not CampaignManager.fase_alterada.is_connected(_ao_mudar_fase):
		CampaignManager.fase_alterada.connect(_ao_mudar_fase)

func _ao_mudar_fase(_nova_fase: int) -> void:
	_atualizar_etiqueta()
	if _jogador_no_alcance:
		_atualizar_conteudo_plaquinha()

func _atualizar_etiqueta() -> void:
	if etiqueta == null:
		return
	if apenas_a_noite and not CampaignManager.esta_de_noite():
		if cena_destino.ends_with("PracaCentral.tscn"):
			etiqueta.text = "TRANCADO ATÉ TERMINAR O DIA"
		else:
			etiqueta.text = destino_label + " (NOITE)"
	else:
		etiqueta.text = destino_label

func _on_body_entered(body: Node2D) -> void:
	if body is Player:
		_jogador_no_alcance = true
		_mostrar_plaquinha()
		if entrar_ao_tocar:
			_mudar_de_cena()

func _on_body_exited(body: Node2D) -> void:
	if body is Player:
		_jogador_no_alcance = false
		_esconder_plaquinha()

func _mostrar_plaquinha() -> void:
	if plaquinha == null:
		return
	_atualizar_conteudo_plaquinha()
	_posicionar_plaquinha()
	if _tween_fade != null and _tween_fade.is_valid():
		_tween_fade.kill()
	plaquinha.visible = true
	_tween_fade = create_tween()
	_tween_fade.tween_property(plaquinha, "modulate:a", 1.0, 0.15)

func _esconder_plaquinha() -> void:
	if plaquinha == null or not plaquinha.visible:
		return
	if _tween_fade != null and _tween_fade.is_valid():
		_tween_fade.kill()
	_tween_fade = create_tween()
	_tween_fade.tween_property(plaquinha, "modulate:a", 0.0, 0.12)
	_tween_fade.tween_callback(func(): plaquinha.visible = false)

func _posicionar_plaquinha() -> void:
	if plaquinha == null:
		return
	var centro_x: float = clampf(global_position.x, 140.0, 500.0)
	var pos_x: float = centro_x - 130.0
	var pos_y: float
	if global_position.y > 180.0:
		pos_y = clampf(global_position.y - 122.0, 10.0, 240.0)
	else:
		pos_y = clampf(global_position.y + 26.0, 10.0, 240.0)
	plaquinha.position = Vector2(pos_x, pos_y)

func _atualizar_conteudo_plaquinha() -> void:
	if titulo_label != null:
		titulo_label.text = titulo_area if not titulo_area.is_empty() else destino_label.to_upper()
	if icone_label != null:
		icone_label.text = icone_simbolo if not icone_simbolo.is_empty() else "🏛️"
	if descricao_label != null:
		descricao_label.text = descricao_area if not descricao_area.is_empty() else ("Caminho para " + destino_label + ".")
	
	if botao_entrar != null:
		if apenas_a_noite and not CampaignManager.esta_de_noite():
			botao_entrar.disabled = true
			if cena_destino.ends_with("PracaCentral.tscn"):
				botao_entrar.text = "🔒 TRANCADO · Termina o dia na loja (5/5)"
			else:
				botao_entrar.text = "🔒 FECHADO DE DIA · Abre à noite"
		else:
			botao_entrar.disabled = false
			botao_entrar.text = "PRESSIONA [ENTER] OU [E] PARA ENTRAR"

func _unhandled_input(event: InputEvent) -> void:
	if not _jogador_no_alcance or _transicao_em_curso:
		return
	if event.is_action_pressed("interact") or event.is_action_pressed("ui_accept"):
		_mudar_de_cena()
		get_viewport().set_input_as_handled()

func _on_botao_entrar_pressed() -> void:
	_mudar_de_cena()

func obter_texto_interacao() -> String:
	if apenas_a_noite and not CampaignManager.esta_de_noite():
		if cena_destino.ends_with("PracaCentral.tscn"):
			return "PORTA TRANCADA · TERMINA O DIA NA LOJA PRIMEIRO"
		return "FECHADO DURANTE O DIA · ABRE À NOITE"
	return "ENTER / E  " + destino_label

func interagir(_jogador: Player) -> void:
	_mudar_de_cena()

func _mudar_de_cena() -> void:
	if _transicao_em_curso:
		return
	if apenas_a_noite and not CampaignManager.esta_de_noite():
		var msg: String = "Esta porta está fechada de dia. Abre à noite após a loja."
		if cena_destino.ends_with("PracaCentral.tscn"):
			msg = "A porta está trancada! Termina o expediente do dia (atende os clientes) antes de sair."
		var cena_atual := get_tree().current_scene
		if cena_atual != null and cena_atual.has_method("_mostrar_feedback"):
			cena_atual.call("_mostrar_feedback", msg)
		elif cena_atual != null and cena_atual.has_method("mostrar_mensagem"):
			cena_atual.call("mostrar_mensagem", msg)
		return
	if cena_destino.is_empty():
		push_error("A porta %s não tem uma cena de destino configurada." % name)
		return
	_transicao_em_curso = true
	AudioManager.tocar_sfx("porta_transicao")
	var destino_final := cena_destino
	if destino_final.ends_with("TongobrigaIntroGibi.tscn") and CampaignManager.tongobriga_intro_vista:
		destino_final = "res://Cenas/Tongobriga.tscn"
	SceneRouter.ir_para(destino_final, posicao_entrada)
