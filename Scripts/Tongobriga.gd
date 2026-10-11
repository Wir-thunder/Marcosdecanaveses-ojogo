extends Node2D

const CHAMPION_SCRIPT: Script = preload("res://Scripts/TongobrigaChampion.gd")
const PLAZA_SCENE: String = "res://Cenas/PracaCentral.tscn"
const CHAMPIONS: Array[Dictionary] = [
	{"name": "Viriato", "archetype": "Gladiador", "special": "Investida", "health": 112, "strength": 12, "speed": 176.0, "defense": 0.08, "color": Color(0.65, 0.23, 0.2), "trim": Color(0.9, 0.68, 0.29)},
	{"name": "Nábia", "archetype": "Duelista", "special": "Lâmina veloz", "health": 92, "strength": 10, "speed": 224.0, "defense": 0.04, "color": Color(0.2, 0.42, 0.68), "trim": Color(0.74, 0.85, 0.91)},
	{"name": "Camalo", "archetype": "Lutador", "special": "Punho de pedra", "health": 126, "strength": 13, "speed": 154.0, "defense": 0.13, "color": Color(0.44, 0.39, 0.3), "trim": Color(0.78, 0.65, 0.43)},
	{"name": "Aunia", "archetype": "Guardião", "special": "Muralha", "health": 120, "strength": 9, "speed": 164.0, "defense": 0.2, "color": Color(0.27, 0.49, 0.35), "trim": Color(0.78, 0.83, 0.55)},
	{"name": "Brigo", "archetype": "Campeão", "special": "Golpe sísmico", "health": 108, "strength": 14, "speed": 166.0, "defense": 0.05, "color": Color(0.56, 0.29, 0.56), "trim": Color(0.91, 0.73, 0.39)},
	{"name": "Lara", "archetype": "Caçadora", "special": "Ataque surpresa", "health": 96, "strength": 11, "speed": 210.0, "defense": 0.06, "color": Color(0.72, 0.43, 0.19), "trim": Color(0.93, 0.82, 0.52)},
	{"name": "Reburrus", "archetype": "Berserker", "special": "Fúria", "health": 104, "strength": 15, "speed": 184.0, "defense": 0.02, "color": Color(0.65, 0.18, 0.18), "trim": Color(0.9, 0.85, 0.7)},
	{"name": "Sunua", "archetype": "Sentinela", "special": "Contra-ataque", "health": 116, "strength": 10, "speed": 182.0, "defense": 0.15, "color": Color(0.18, 0.48, 0.46), "trim": Color(0.84, 0.72, 0.38)},
]

@onready var selecao_painel: PanelContainer = $UI/Selecao
@onready var elenco_grade: GridContainer = $UI/Selecao/Margem/Conteudo/Elenco
@onready var selecao_label: Label = $UI/Selecao/Margem/Conteudo/SelecaoLabel
@onready var iniciar_botao: Button = $UI/Selecao/Margem/Conteudo/Botoes/Iniciar
@onready var sair_botao: Button = $UI/Selecao/Margem/Conteudo/Botoes/Sair
@onready var arena_hud: Control = $UI/Arena
@onready var nome_jogador: Label = $UI/Arena/NomeJogador
@onready var nome_oponente: Label = $UI/Arena/NomeOponente
@onready var vida_jogador: ProgressBar = $UI/Arena/VidaJogador
@onready var vida_oponente: ProgressBar = $UI/Arena/VidaOponente
@onready var round_label: Label = $UI/Arena/Ronda
@onready var mensagem_label: Label = $UI/Arena/Mensagem
@onready var controlos_label: Label = $UI/Arena/Controlos
@onready var regressar_botao: Button = $UI/Arena/Regressar

var _rng := RandomNumberGenerator.new()
var _escolhido: int = 0
var _ordem_oponentes: Array[int] = []
var _ronda: int = 0
var _jogador: TongobrigaChampion
var _oponente: TongobrigaChampion
var _ia_proximo_golpe: float = 0.0
var _bloqueio_ia: float = 0.0
var _jogo_ativo: bool = false
var _match_finalizado: bool = false
var _vida_entre_rondas: int = 0
var _tempo_especial_jogador: float = 0.0
var _salto_pendente: bool = false
var _ataque_pendente: String = ""

func _ready() -> void:
	_rng.randomize()
	iniciar_botao.pressed.connect(_iniciar_torneio)
	sair_botao.pressed.connect(_sair_para_praca)
	regressar_botao.pressed.connect(_sair_para_praca)
	_criar_elenco()
	selecionar_campeao(0)

func _process(delta: float) -> void:
	if not _jogo_ativo or _jogador == null or _oponente == null:
		return
	_tempo_especial_jogador = maxf(_tempo_especial_jogador - delta, 0.0)
	var movimento := 0.0
	if Input.is_key_pressed(KEY_A) or Input.is_key_pressed(KEY_LEFT):
		movimento -= 1.0
	if Input.is_key_pressed(KEY_D) or Input.is_key_pressed(KEY_RIGHT):
		movimento += 1.0
	_jogador.update_fighter(
		delta,
		movimento,
		_salto_pendente,
		Input.is_key_pressed(KEY_L),
		_oponente
	)
	_oponente.update_fighter(
		delta,
		_movimento_ia(),
		false,
		_bloqueio_ia > 0.0,
		_jogador
	)
	_salto_pendente = false
	if _ataque_pendente == "punch":
		_executar_ataque(_jogador, _oponente, "punch")
	elif _ataque_pendente == "kick":
		_executar_ataque(_jogador, _oponente, "kick")
	elif _ataque_pendente == "special":
		if _tempo_especial_jogador <= 0.0:
			var dano := _executar_ataque(_jogador, _oponente, "special")
			if dano > 0:
				_tempo_especial_jogador = 5.0
		else:
			mensagem_label.text = "Especial pronto em %ds." % ceili(_tempo_especial_jogador)
	_ataque_pendente = ""
	_atualizar_barras()

func _input(event: InputEvent) -> void:
	if not _jogo_ativo or not event is InputEventKey:
		return
	var tecla := event as InputEventKey
	if not tecla.pressed or tecla.echo:
		return
	match tecla.physical_keycode:
		KEY_W, KEY_UP:
			_salto_pendente = true
		KEY_J:
			_ataque_pendente = "punch"
		KEY_K:
			_ataque_pendente = "kick"
		KEY_I:
			_ataque_pendente = "special"
		KEY_ESCAPE:
			_terminar_torneio(false, "Abandonaste o torneio.")
			get_viewport().set_input_as_handled()

func _criar_elenco() -> void:
	for indice in range(CHAMPIONS.size()):
		var campeao: Dictionary = CHAMPIONS[indice]
		var botao := Button.new()
		botao.custom_minimum_size = Vector2(132.0, 55.0)
		botao.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		botao.add_theme_font_size_override("font_size", 11)
		botao.text = "%s\n%s · HP %d · FOR %d · VEL %d" % [
			campeao["name"],
			campeao["archetype"],
			campeao["health"],
			campeao["strength"],
			roundi(float(campeao["speed"]) / 20.0),
		]
		botao.pressed.connect(selecionar_campeao.bind(indice))
		elenco_grade.add_child(botao)

func selecionar_campeao(indice: int) -> void:
	if indice < 0 or indice >= CHAMPIONS.size():
		return
	_escolhido = indice
	var campeao: Dictionary = CHAMPIONS[indice]
	selecao_label.text = "%s · %s · Especial: %s · Defesa %d%%" % [
		campeao["name"],
		campeao["archetype"],
		campeao["special"],
		roundi(float(campeao["defense"]) * 100.0),
	]

func _iniciar_torneio() -> void:
	if not CampaignManager.iniciar_torneio():
		selecao_label.text = "Já lutaste hoje. Volta amanhã para um novo torneio."
		return
	_ordem_oponentes.clear()
	var opcoes: Array[int] = []
	for indice in range(CHAMPIONS.size()):
		if indice != _escolhido:
			opcoes.append(indice)
	opcoes.shuffle()
	for indice in range(3):
		_ordem_oponentes.append(opcoes[indice])
	_ronda = 0
	_vida_entre_rondas = int(CHAMPIONS[_escolhido]["health"])
	_jogo_ativo = true
	_match_finalizado = false
	regressar_botao.visible = false
	selecao_painel.visible = false
	arena_hud.visible = true
	_iniciar_ronda()

func _iniciar_ronda() -> void:
	if _ronda >= _ordem_oponentes.size():
		_terminar_torneio(true, "Campeão de Tongóbriga! Recebeste %d escudos." % (
			80 + CampaignManager.dia * 10
		))
		InventoryManager.escudos += 80 + CampaignManager.dia * 10
		mensagem_label.text = "Campeão de Tongóbriga! +%d ouro." % (
			80 + CampaignManager.dia * 10
		)
		return

	_match_finalizado = false
	var dados_jogador: Dictionary = CHAMPIONS[_escolhido].duplicate(true)
	var dados_oponente: Dictionary = CHAMPIONS[_ordem_oponentes[_ronda]].duplicate(true)
	_jogador = _criar_lutador(dados_jogador, Vector2(175.0, 280.0), 1.0)
	_oponente = _criar_lutador(dados_oponente, Vector2(465.0, 280.0), -1.0)
	_jogador.health = _vida_entre_rondas
	_jogador.health_changed.connect(_atualizar_barras)
	_oponente.health_changed.connect(_atualizar_barras)
	_jogador.knocked_out.connect(_ao_ser_derrotado)
	_oponente.knocked_out.connect(_ao_ser_derrotado)
	nome_jogador.text = "%s · %s" % [dados_jogador["name"], dados_jogador["archetype"]]
	nome_oponente.text = "%s · %s" % [dados_oponente["name"], dados_oponente["archetype"]]
	round_label.text = "TORNEIO · LUTA %d/3" % (_ronda + 1)
	mensagem_label.text = "A/D mover · W saltar · J soco · K pontapé · L defender · I especial"
	controlos_label.text = "A/D ou ←/→ mover  ·  W/↑ saltar  ·  J soco  ·  K pontapé  ·  L defender  ·  I especial"
	_ia_proximo_golpe = 0.7
	_bloqueio_ia = 0.0
	_tempo_especial_jogador = 0.0
	_atualizar_barras()

func _criar_lutador(dados: Dictionary, posicao: Vector2, direcao: float) -> TongobrigaChampion:
	var lutador_base := CharacterBody2D.new()
	lutador_base.set_script(CHAMPION_SCRIPT)
	var lutador := lutador_base as TongobrigaChampion
	lutador.configure(dados, 280.0)
	lutador.global_position = posicao
	lutador.facing = direcao
	add_child(lutador)
	return lutador

func _movimento_ia() -> float:
	_ia_proximo_golpe -= get_process_delta_time()
	_bloqueio_ia = maxf(_bloqueio_ia - get_process_delta_time(), 0.0)
	var distancia := absf(_jogador.global_position.x - _oponente.global_position.x)
	if _ia_proximo_golpe <= 0.0:
		_ia_proximo_golpe = _rng.randf_range(0.55, 1.0)
		if _rng.randf() < 0.2:
			_bloqueio_ia = 0.45
		elif distancia < 145.0:
			var tipo := "special" if _oponente.can_use_special() and _rng.randf() < 0.28 else (
				"kick" if _rng.randf() < 0.55 else "punch"
			)
			_executar_ataque(_oponente, _jogador, tipo)
	if distancia > 72.0:
		return signf(_jogador.global_position.x - _oponente.global_position.x)
	return 0.0

func _executar_ataque(
	atacante: TongobrigaChampion,
	alvo: TongobrigaChampion,
	tipo: String
) -> int:
	if atacante == null or alvo == null:
		return 0
	var dano := atacante.attack(alvo, tipo)
	if dano <= 0:
		if atacante == _jogador and tipo != "special":
			mensagem_label.text = "Demasiado longe: aproxima-te para acertar."
		return 0
	var nome_golpe := atacante.special_name if tipo == "special" else (
		"pontapé" if tipo == "kick" else "soco"
	)
	mensagem_label.text = "%s usa %s! %d de dano." % [
		atacante.champion_name,
		nome_golpe,
		dano,
	]
	return dano

func _atualizar_barras(_campeao: TongobrigaChampion = null) -> void:
	if _jogador == null or _oponente == null:
		return
	vida_jogador.max_value = _jogador.max_health
	vida_jogador.value = _jogador.health
	vida_oponente.max_value = _oponente.max_health
	vida_oponente.value = _oponente.health

func _ao_ser_derrotado(campeao: TongobrigaChampion) -> void:
	if _match_finalizado or not _jogo_ativo:
		return
	_match_finalizado = true
	if campeao == _oponente:
		_ronda += 1
		_vida_entre_rondas = mini(
			int(CHAMPIONS[_escolhido]["health"]),
			_jogador.health + roundi(float(_jogador.max_health) * 0.25)
		)
		if _ronda >= 3:
			_jogo_ativo = false
			_iniciar_ronda()
			return
		mensagem_label.text = "Vitória! Prepara-te para o próximo combate..."
		_proxima_luta()
	else:
		_terminar_torneio(false, "Foste derrotado. O torneio terminou.")

func _proxima_luta() -> void:
	await get_tree().create_timer(1.2).timeout
	if is_inside_tree():
		if _jogador != null:
			_jogador.queue_free()
		if _oponente != null:
			_oponente.queue_free()
		_iniciar_ronda()

func _terminar_torneio(vitoria: bool, mensagem: String) -> void:
	_jogo_ativo = false
	mensagem_label.text = mensagem
	controlos_label.text = "Vitória!" if vitoria else "Tenta novamente noutro dia."
	regressar_botao.text = "VOLTAR À PRAÇA"
	regressar_botao.visible = true

func _sair_para_praca() -> void:
	SceneRouter.ir_para(PLAZA_SCENE, Vector2(225.0, 165.0))
