extends Node2D

const RETRATOS_PROFISSAO: Dictionary = {
	"Guerreiro": preload("res://Assets/Characters/Adventurers/guerreiro.png"),
	"Arqueiro": preload("res://Assets/Characters/Adventurers/arqueiro.png"),
	"Mago": preload("res://Assets/Characters/Adventurers/mago.png"),
	"Curandeiro": preload("res://Assets/Characters/Adventurers/curandeiro.png"),
}

@onready var estado_label: Label = $Interface/Painel/Coluna/Estado
@onready var expedicao_label: Label = $Interface/Painel/Coluna/Expedicao
@onready var progresso_barra: ProgressBar = $Interface/Painel/Coluna/Progresso
@onready var ofertas_lista: VBoxContainer = $Interface/Painel/Coluna/OfertasScroll/Ofertas
@onready var equipa_lista: VBoxContainer = $Interface/Painel/Coluna/EquipaScroll/Equipa
@onready var relatorio_label: Label = $Interface/Painel/Coluna/Relatorio
@onready var enviar_botao: Button = $Interface/Painel/Coluna/Botoes/Enviar
@onready var jogador: Player = $Player
@onready var painel: PanelContainer = $Interface/Painel
@onready var fundo_pop_up: ColorRect = $Interface/FundoPopUp
@onready var fechar_botao: Button = $Interface/Painel/Coluna/Cabecalho/Fechar
@onready var instrucao_label: Label = $Interface/Instrucao

var _mercenarios_selecionados: Array[String] = []
var _painel_aberto: bool = false

func _ready() -> void:
	CampaignManager.progresso_alterado.connect(_atualizar_progresso)
	CampaignManager.expedicao_concluida.connect(_mostrar_relatorio)
	enviar_botao.pressed.connect(_enviar_equipa)
	fechar_botao.pressed.connect(_fechar_painel)
	$Interface/Painel/Coluna/Botoes/ProximoTurno.pressed.connect(
		CampaignManager.iniciar_novo_turno
	)
	_atualizar_listas()
	_atualizar_progresso()

func obter_texto_interacao() -> String:
	return "E  FECHAR TAVERNA" if _painel_aberto else "E  ABRIR TAVERNA"

func alternar_painel() -> void:
	_definir_painel_aberto(not _painel_aberto)

func _fechar_painel() -> void:
	_definir_painel_aberto(false)

func _definir_painel_aberto(aberto: bool) -> void:
	_painel_aberto = aberto
	painel.visible = aberto
	fundo_pop_up.visible = aberto
	instrucao_label.visible = not aberto

func _unhandled_key_input(event: InputEvent) -> void:
	if _painel_aberto and event.is_action_pressed("ui_cancel"):
		_fechar_painel()
		get_viewport().set_input_as_handled()

func _process(_delta: float) -> void:
	_atualizar_progresso()
	_atualizar_instrucao()

func _atualizar_instrucao() -> void:
	if _painel_aberto:
		return

	var alvo := jogador.obter_alvo_interacao()
	if alvo != null and alvo.has_method("obter_texto_interacao"):
		instrucao_label.text = str(alvo.call("obter_texto_interacao"))
	else:
		instrucao_label.text = "Aproxima-te do balcão e carrega em E · Esc fecha o painel"

func _atualizar_listas() -> void:
	for filho in ofertas_lista.get_children():
		filho.queue_free()
	for filho in equipa_lista.get_children():
		filho.queue_free()

	for oferta in CampaignManager.ofertas:
		var botao := Button.new()
		botao.custom_minimum_size = Vector2(0.0, 28.0)
		botao.add_theme_font_size_override("font_size", 9)
		botao.text = "%s · %s Nv.%d · P%d V%d · %s · %d ouro" % [
			oferta["nome"],
			oferta["profissao"],
			oferta["nivel"],
			oferta["poder"],
			oferta["velocidade"],
			oferta["habilidade"],
			oferta["preco"],
		]
		botao.pressed.connect(_contratar.bind(int(oferta["id"])))
		var linha_oferta := HBoxContainer.new()
		linha_oferta.custom_minimum_size.y = 34.0
		linha_oferta.add_child(_criar_retrato(str(oferta["profissao"])))
		botao.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		linha_oferta.add_child(botao)
		ofertas_lista.add_child(linha_oferta)

	for mercenario in CampaignManager.mercenarios:
		var selecao := CheckButton.new()
		selecao.custom_minimum_size = Vector2(0.0, 24.0)
		selecao.add_theme_font_size_override("font_size", 9)
		selecao.text = "%s · %s Nv.%d · P%d V%d · %d/%d XP · %s" % [
			mercenario["nome"],
			mercenario["profissao"],
			mercenario["nivel"],
			mercenario["poder"],
			mercenario["velocidade"],
			mercenario["experiencia"],
			int(mercenario["nivel"]) * 50,
			mercenario["habilidade"],
		]
		selecao.button_pressed = _mercenarios_selecionados.has(str(mercenario["id"]))
		selecao.toggled.connect(
			_alternar_selecao.bind(str(mercenario["id"]))
		)
		var linha_mercenario := HBoxContainer.new()
		linha_mercenario.custom_minimum_size.y = 34.0
		linha_mercenario.add_child(_criar_retrato(str(mercenario["profissao"])))
		selecao.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		linha_mercenario.add_child(selecao)
		equipa_lista.add_child(linha_mercenario)

	estado_label.text = "DIA %d · OURO %d · contrata e gere a equipa durante a noite." % [
		CampaignManager.dia,
		InventoryManager.escudos,
	]
	relatorio_label.text = CampaignManager.ultimo_relatorio

func _criar_retrato(profissao: String) -> TextureRect:
	if not RETRATOS_PROFISSAO.has(profissao):
		push_error("Não existe retrato para a profissão: %s" % profissao)
		return TextureRect.new()

	var retrato := TextureRect.new()
	retrato.custom_minimum_size = Vector2(20.0, 30.0)
	retrato.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	retrato.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	retrato.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	retrato.texture = RETRATOS_PROFISSAO[profissao]
	return retrato

func _atualizar_progresso() -> void:
	var ativa := bool(CampaignManager.expedicao.get("ativa", false))
	progresso_barra.value = CampaignManager.obter_progresso_expedicao() * 100.0
	enviar_botao.disabled = ativa or _mercenarios_selecionados.is_empty()

	if ativa:
		expedicao_label.text = "EXPEDIÇÃO · SALA %d/%d · combate por turnos" % [
			CampaignManager.obter_dias_expedicao(),
			CampaignManager.obter_dias_previstos_expedicao(),
		]
		estado_label.text = "DIA %d · OURO %d · equipa: %s" % [
			CampaignManager.dia,
			InventoryManager.escudos,
			", ".join(PackedStringArray(CampaignManager.expedicao["nomes"])),
		]
	elif not CampaignManager.ultimo_relatorio.is_empty():
		expedicao_label.text = "A equipa regressou da dungeon."
	else:
		expedicao_label.text = "Sem expedições ativas."

func _contratar(id_oferta: int) -> void:
	if not CampaignManager.contratar_mercenario(id_oferta):
		relatorio_label.text = "Ouro insuficiente para contratar este aventureiro."
		return
	relatorio_label.text = "Aventureiro contratado."
	_atualizar_listas()
	_atualizar_progresso()

func _alternar_selecao(selecionado: bool, id_mercenario: String) -> void:
	if selecionado:
		if _mercenarios_selecionados.size() >= 4:
			_atualizar_listas()
			return
		if not _mercenarios_selecionados.has(id_mercenario):
			_mercenarios_selecionados.append(id_mercenario)
	else:
		_mercenarios_selecionados.erase(id_mercenario)
	_atualizar_progresso()

func _enviar_equipa() -> void:
	if CampaignManager.iniciar_expedicao(_mercenarios_selecionados):
		_mercenarios_selecionados.clear()
		_atualizar_listas()
		relatorio_label.text = "A equipa parte para a dungeon..."
		_atualizar_progresso()
		SceneRouter.ir_para("res://Cenas/DungeonCombate.tscn", Vector2.ZERO)
	else:
		relatorio_label.text = "Escolhe pelo menos um mercenário disponível."

func _mostrar_relatorio(relatorio: String) -> void:
	relatorio_label.text = relatorio
	_atualizar_listas()
	_atualizar_progresso()
