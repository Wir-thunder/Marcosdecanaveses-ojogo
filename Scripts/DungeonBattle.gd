extends Control

const CENA_DUNGEON: String = "res://Cenas/DungeonCombate.tscn"
const CENA_TAVERNA: String = "res://Cenas/Taverna.tscn"
const RETRATOS_PROFISSAO: Dictionary = {
	"Guerreiro": preload("res://Assets/Characters/Adventurers/guerreiro.png"),
	"Arqueiro": preload("res://Assets/Characters/Adventurers/arqueiro.png"),
	"Mago": preload("res://Assets/Characters/Adventurers/mago.png"),
	"Curandeiro": preload("res://Assets/Characters/Adventurers/curandeiro.png"),
}

@onready var sala_label: Label = $Interface/Conteudo/Sala
@onready var estado_label: Label = $Interface/Conteudo/Estado
@onready var inimigos_lista: HBoxContainer = $Interface/Conteudo/Inimigos
@onready var equipa_lista: HBoxContainer = $Interface/Conteudo/Equipa
@onready var turno_label: Label = $Interface/Conteudo/Turno
@onready var registo_label: Label = $Interface/Conteudo/Registo
@onready var atacar_botao: Button = $Interface/Conteudo/Comandos/Atacar
@onready var habilidade_botao: Button = $Interface/Conteudo/Comandos/Habilidade
@onready var defender_botao: Button = $Interface/Conteudo/Comandos/Defender
@onready var fugir_botao: Button = $Interface/Conteudo/Comandos/Recuar

var _equipa: Array[Dictionary] = []
var _inimigos: Array[Dictionary] = []
var _protegidos: Dictionary = {}
var _alvo_selecionado: int = 0
var _indice_turno: int = 0
var _vez_da_equipa: bool = true
var _fim_de_combate: bool = false
var _ouro_saqueado: int = 0
var _sala_atual: int = 1
var _salas_total: int = 1
var _rng := RandomNumberGenerator.new()

func _ready() -> void:
	_rng.randomize()
	if not bool(CampaignManager.expedicao.get("ativa", false)):
		_ir_para_taverna()
		return

	_equipa = CampaignManager.obter_equipa_expedicao()
	_sala_atual = int(CampaignManager.expedicao["sala"])
	_salas_total = int(CampaignManager.expedicao["salas_total"])
	_ouro_saqueado = int(CampaignManager.expedicao.get("ouro_saqueado", 0))
	if _equipa.is_empty():
		push_error("A expedição ativa não tem aventureiros disponíveis.")
		CampaignManager.finalizar_expedicao(false, 0)
		_ir_para_taverna()
		return

	atacar_botao.pressed.connect(_atacar)
	habilidade_botao.pressed.connect(_usar_habilidade)
	defender_botao.pressed.connect(_defender)
	fugir_botao.pressed.connect(_recuar)
	_gerar_inimigos()
	_atualizar_interface("Escolhe um inimigo e uma ação para cada aventureiro.")

func _unhandled_key_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel") and not _fim_de_combate:
		_recuar()
		get_viewport().set_input_as_handled()

func _gerar_inimigos() -> void:
	var sala := int(CampaignManager.expedicao["sala"])
	var nivel_medio := 0
	for combatente in _equipa:
		nivel_medio += int(combatente["nivel"])
	nivel_medio = maxi(1, roundi(float(nivel_medio) / float(_equipa.size())))

	var encontros: Array[Array] = [
		[["Goblin", 24, 5], ["Lobo das cavernas", 28, 6]],
		[["Saqueador", 34, 7], ["Morcego sombrio", 25, 6], ["Saqueador", 34, 7]],
		[["Guardião antigo", 90, 10], ["Sentinela", 38, 8]],
	]
	var encontro: Array = encontros[mini(sala - 1, encontros.size() - 1)]
	for entrada in encontro:
		var multiplicador := 1.0 + float(nivel_medio - 1) * 0.12
		var vida := roundi(float(entrada[1]) * multiplicador)
		_inimigos.append({
			"nome": str(entrada[0]),
			"vida": vida,
			"vida_maxima": vida,
			"poder": maxi(1, roundi(float(entrada[2]) * multiplicador)),
		})

func _atualizar_interface(mensagem: String) -> void:
	sala_label.text = "DUNGEON · SALA %d/%d" % [_sala_atual, _salas_total]
	estado_label.text = "COMBATE TÁTICO · escolhe um alvo e uma ação para cada aventureiro."
	registo_label.text = mensagem
	_atualizar_lista_inimigos()
	_atualizar_lista_equipa()

	if _fim_de_combate:
		turno_label.text = "Combate terminado."
	elif _vez_da_equipa:
		var combatente := _equipa[_indice_turno]
		habilidade_botao.text = str(combatente["habilidade"]).to_upper()
		turno_label.text = "Vez de %s · %s · Nv.%d · HP %d/%d" % [
			combatente["nome"],
			combatente["profissao"],
			combatente["nivel"],
			combatente["vida_atual"],
			combatente["vida_maxima"],
		]
	else:
		turno_label.text = "Turno dos inimigos..."

	var pode_agir := _vez_da_equipa and not _fim_de_combate
	atacar_botao.disabled = not pode_agir
	habilidade_botao.disabled = not pode_agir
	defender_botao.disabled = not pode_agir
	fugir_botao.disabled = _fim_de_combate

func _atualizar_lista_inimigos() -> void:
	for filho in inimigos_lista.get_children():
		inimigos_lista.remove_child(filho)
		filho.queue_free()
	for indice in range(_inimigos.size()):
		var inimigo: Dictionary = _inimigos[indice]
		var botao := Button.new()
		botao.custom_minimum_size = Vector2(176, 54)
		botao.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		botao.toggle_mode = true
		botao.button_pressed = indice == _alvo_selecionado
		botao.disabled = int(inimigo["vida"]) <= 0 or not _vez_da_equipa
		botao.text = "%s\nHP %d/%d" % [
			inimigo["nome"],
			inimigo["vida"],
			inimigo["vida_maxima"],
		]
		botao.pressed.connect(_selecionar_alvo.bind(indice))
		inimigos_lista.add_child(botao)

func _atualizar_lista_equipa() -> void:
	for filho in equipa_lista.get_children():
		equipa_lista.remove_child(filho)
		filho.queue_free()
	for indice in range(_equipa.size()):
		var combatente: Dictionary = _equipa[indice]
		var cartao := VBoxContainer.new()
		cartao.custom_minimum_size = Vector2(140, 58)
		cartao.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		cartao.alignment = BoxContainer.ALIGNMENT_CENTER
		cartao.add_theme_constant_override("separation", 1)
		var retrato := TextureRect.new()
		retrato.custom_minimum_size = Vector2(28, 30)
		retrato.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		retrato.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		retrato.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		retrato.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		retrato.texture = RETRATOS_PROFISSAO.get(str(combatente["profissao"]))
		cartao.add_child(retrato)
		var etiqueta := Label.new()
		etiqueta.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		etiqueta.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		etiqueta.add_theme_font_size_override("font_size", 9)
		var estado := " · CAÍDO" if int(combatente["vida_atual"]) <= 0 else ""
		if _vez_da_equipa and indice == _indice_turno and not _fim_de_combate:
			estado = " · A AGIR"
		etiqueta.text = "%s Nv.%d%s · HP %d/%d" % [
			combatente["nome"],
			combatente["nivel"],
			estado,
			combatente["vida_atual"],
			combatente["vida_maxima"],
		]
		cartao.add_child(etiqueta)
		equipa_lista.add_child(cartao)

func _selecionar_alvo(indice: int) -> void:
	_alvo_selecionado = indice
	_atualizar_interface(estado_label.text)

func _atacar() -> void:
	var alvo := _obter_alvo_valido()
	if alvo < 0:
		return
	var combatente: Dictionary = _equipa[_indice_turno]
	var inimigo: Dictionary = _inimigos[alvo]
	var dano := maxi(1, int(combatente["poder"]) + _rng.randi_range(-2, 2))
	inimigo["vida"] = maxi(0, int(inimigo["vida"]) - dano)
	_finalizar_acao("%s ataca %s e causa %d de dano." % [
		combatente["nome"], inimigo["nome"], dano,
	])

func _usar_habilidade() -> void:
	var combatente: Dictionary = _equipa[_indice_turno]
	var profissao := str(combatente["profissao"])
	if profissao == "Curandeiro":
		var alvo_cura := _obter_alvo_de_cura()
		if alvo_cura < 0:
			return
		var aliado: Dictionary = _equipa[alvo_cura]
		var cura := 12 + int(combatente["nivel"]) * 4
		aliado["vida_atual"] = mini(
			int(aliado["vida_maxima"]),
			int(aliado["vida_atual"]) + cura
		)
		_guardar_vida(aliado)
		_finalizar_acao("%s usa %s e recupera HP de %s." % [
			combatente["nome"], combatente["habilidade"], aliado["nome"],
		])
		return

	if profissao == "Mago":
		var dano_total := 0
		for inimigo in _inimigos:
			if int(inimigo["vida"]) <= 0:
				continue
			var dano := maxi(1, roundi(float(combatente["poder"]) * 0.8))
			inimigo["vida"] = maxi(0, int(inimigo["vida"]) - dano)
			dano_total += dano
		_finalizar_acao("%s lança %s e causa %d de dano ao grupo inimigo." % [
			combatente["nome"], combatente["habilidade"], dano_total,
		])
		return

	var alvo := _obter_alvo_valido()
	if alvo < 0:
		return
	var inimigo: Dictionary = _inimigos[alvo]
	var multiplicador := 1.7 if profissao == "Guerreiro" else 1.45
	var dano := maxi(1, roundi(float(combatente["poder"]) * multiplicador))
	inimigo["vida"] = maxi(0, int(inimigo["vida"]) - dano)
	_finalizar_acao("%s usa %s contra %s e causa %d de dano." % [
		combatente["nome"], combatente["habilidade"], inimigo["nome"], dano,
	])

func _defender() -> void:
	var combatente: Dictionary = _equipa[_indice_turno]
	_protegidos[str(combatente["id"])] = true
	_finalizar_acao("%s prepara uma defesa." % combatente["nome"])

func _finalizar_acao(mensagem: String) -> void:
	_guardar_vidas_equipa()
	if _todos_inimigos_derrotados():
		_concluir_sala(mensagem)
		return
	_indice_turno += 1
	while _indice_turno < _equipa.size() and int(_equipa[_indice_turno]["vida_atual"]) <= 0:
		_indice_turno += 1
	if _indice_turno >= _equipa.size():
		_vez_da_equipa = false
		_turno_inimigos(mensagem)
		return
	_atualizar_interface(mensagem)

func _turno_inimigos(mensagem: String) -> void:
	var mensagens: Array[String] = []
	for inimigo in _inimigos:
		if int(inimigo["vida"]) <= 0:
			continue
		var alvos: Array[int] = []
		for indice in range(_equipa.size()):
			if int(_equipa[indice]["vida_atual"]) > 0:
				alvos.append(indice)
		if alvos.is_empty():
			break
		var indice_alvo: int = alvos[_rng.randi_range(0, alvos.size() - 1)]
		var combatente: Dictionary = _equipa[indice_alvo]
		var dano := maxi(1, int(inimigo["poder"]) + _rng.randi_range(-1, 1))
		if bool(_protegidos.get(str(combatente["id"]), false)):
			dano = maxi(1, ceili(float(dano) * 0.5))
		combatente["vida_atual"] = maxi(0, int(combatente["vida_atual"]) - dano)
		_guardar_vida(combatente)
		mensagens.append("%s atinge %s (%d)." % [
			inimigo["nome"], combatente["nome"], dano,
		])

	_protegidos.clear()
	_guardar_vidas_equipa()
	if _todos_aventureiros_derrotados():
		_finalizar_expedicao(false, "A equipa foi derrotada. Reagrupa-te na taverna.")
		return

	_vez_da_equipa = true
	_indice_turno = 0
	while _indice_turno < _equipa.size() and int(_equipa[_indice_turno]["vida_atual"]) <= 0:
		_indice_turno += 1
	_atualizar_interface("%s\n%s" % [mensagem, " ".join(mensagens)])

func _obter_alvo_valido() -> int:
	if _alvo_selecionado >= 0 and _alvo_selecionado < _inimigos.size():
		if int(_inimigos[_alvo_selecionado]["vida"]) > 0:
			return _alvo_selecionado
	for indice in range(_inimigos.size()):
		if int(_inimigos[indice]["vida"]) > 0:
			_alvo_selecionado = indice
			return indice
	return -1

func _obter_alvo_de_cura() -> int:
	var menor_vida := INF
	var escolhido := -1
	for indice in range(_equipa.size()):
		var combatente: Dictionary = _equipa[indice]
		if int(combatente["vida_atual"]) < int(combatente["vida_maxima"]):
			var proporcao := float(combatente["vida_atual"]) / float(combatente["vida_maxima"])
			if proporcao < menor_vida:
				menor_vida = proporcao
				escolhido = indice
	return escolhido

func _todos_inimigos_derrotados() -> bool:
	for inimigo in _inimigos:
		if int(inimigo["vida"]) > 0:
			return false
	return true

func _todos_aventureiros_derrotados() -> bool:
	for combatente in _equipa:
		if int(combatente["vida_atual"]) > 0:
			return false
	return true

func _guardar_vida(combatente: Dictionary) -> void:
	CampaignManager.atualizar_vida_expedicao(
		str(combatente["id"]),
		int(combatente["vida_atual"])
	)

func _guardar_vidas_equipa() -> void:
	for combatente in _equipa:
		_guardar_vida(combatente)

func _concluir_sala(mensagem: String) -> void:
	var sala_atual := int(CampaignManager.expedicao["sala"])
	_ouro_saqueado += 15 + sala_atual * 10
	CampaignManager.expedicao["ouro_saqueado"] = _ouro_saqueado
	if CampaignManager.avancar_sala_expedicao():
		estado_label.text = "%s\nSala concluída! A equipa avança..." % mensagem
		atacar_botao.disabled = true
		habilidade_botao.disabled = true
		defender_botao.disabled = true
		fugir_botao.disabled = true
		get_tree().call_deferred("change_scene_to_file", CENA_DUNGEON)
		return
	_finalizar_expedicao(true, "Vitória! A equipa limpou todas as salas.")

func _recuar() -> void:
	if _fim_de_combate:
		_ir_para_taverna()
		return
	_finalizar_expedicao(false, "A equipa recuou da dungeon.")

func _finalizar_expedicao(vitoria: bool, mensagem: String) -> void:
	if _fim_de_combate:
		return
	_fim_de_combate = true
	_guardar_vidas_equipa()
	CampaignManager.finalizar_expedicao(vitoria, _ouro_saqueado)
	_atualizar_interface(mensagem)
	atacar_botao.visible = false
	habilidade_botao.visible = false
	defender_botao.visible = false
	fugir_botao.text = "VOLTAR À TAVERNA"
	fugir_botao.disabled = false

func _ir_para_taverna() -> void:
	SceneRouter.ir_para(CENA_TAVERNA, Vector2(80.0, 255.0))
