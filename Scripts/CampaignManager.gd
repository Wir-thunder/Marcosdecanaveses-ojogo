extends Node

signal fase_alterada(fase: int)
signal progresso_alterado
signal expedicao_concluida(relatorio: String)

enum Fase { MANHA, LOJA, NOITE }

const DURACAO_TURNO: float = 180.0
const SALAS_EXPEDICAO: int = 3
const PROFISSOES: Array[String] = ["Guerreiro", "Arqueiro", "Mago", "Curandeiro"]
const TESOUROS_POR_QUALIDADE: Array[Array] = [
	["calcedonia_fina", "po_granito_tongobriga", "azeite_do_olival"],
	["mel_do_olival", "pinho_resinato", "musgo_do_pombal"],
	["raiz_mandrago", "raiz_celeste", "basalto_fervente"],
	["lagrima_douro", "calcedonia_fina", "basalto_fervente"],
]
const NOMES_MERCENARIOS: Array[String] = [
	"Alba", "Bruno", "Catarina", "Duarte", "Eva", "Filipe", "Gonçalo",
	"Inês", "Joana", "Lourenço", "Marta", "Nuno", "Rita", "Tomás",
]

var fase: Fase = Fase.MANHA
var dia: int = 1
var tempo_turno: float = DURACAO_TURNO
var velocidade_acelerada: bool = false
var mercenarios: Array[Dictionary] = []
var ofertas: Array[Dictionary] = []
var expedicao: Dictionary = {}
var ultimo_relatorio: String = ""
var torneio_jogado_dia: int = -1

var _rng := RandomNumberGenerator.new()
var _proximo_id_mercenario: int = 1
var _tempo_sinal: float = 0.0

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_PAUSABLE
	_rng.randomize()
	Engine.time_scale = 1.0
	if InventoryManager.escudos == 0:
		InventoryManager.escudos = 100
	_gerar_ofertas()

func _process(delta: float) -> void:
	if fase == Fase.LOJA:
		tempo_turno = maxf(tempo_turno - delta, 0.0)
		_tempo_sinal += delta
		if _tempo_sinal >= 0.5:
			_tempo_sinal = 0.0
			progresso_alterado.emit()
		if tempo_turno <= 0.0:
			encerrar_turno()

func esta_de_noite() -> bool:
	return fase == Fase.NOITE

func iniciar_torneio() -> bool:
	if torneio_jogado_dia == dia:
		return false
	torneio_jogado_dia = dia
	return true

func iniciar_turno_loja() -> void:
	if fase != Fase.MANHA:
		return
	tempo_turno = DURACAO_TURNO
	fase = Fase.LOJA
	fase_alterada.emit(fase)
	progresso_alterado.emit()

func alternar_velocidade() -> void:
	velocidade_acelerada = not velocidade_acelerada
	Engine.time_scale = 2.0 if velocidade_acelerada else 1.0
	progresso_alterado.emit()

func encerrar_turno() -> void:
	_terminar_turno()

func contratar_mercenario(id_oferta: int) -> bool:
	for indice in range(ofertas.size()):
		var oferta: Dictionary = ofertas[indice]
		if int(oferta["id"]) != id_oferta:
			continue
		var preco := int(oferta["preco"])
		if InventoryManager.escudos < preco:
			return false

		InventoryManager.escudos -= preco
		mercenarios.append(oferta.duplicate(true))
		ofertas.remove_at(indice)
		progresso_alterado.emit()
		return true
	return false

func iniciar_expedicao(ids_mercenarios: Array[String]) -> bool:
	if bool(expedicao.get("ativa", false)) or ids_mercenarios.is_empty():
		return false
	if ids_mercenarios.size() > 4:
		return false

	var equipa: Array[Dictionary] = []
	for mercenario in mercenarios:
		if ids_mercenarios.has(str(mercenario["id"])):
			equipa.append(mercenario)
	if equipa.size() != ids_mercenarios.size():
		return false

	var vidas: Dictionary = {}
	var nomes: Array[String] = []
	for mercenario in equipa:
		var vida_maxima := int(mercenario.get("vida_maxima", 40))
		mercenario["vida_maxima"] = vida_maxima
		vidas[str(mercenario["id"])] = vida_maxima
		nomes.append(str(mercenario["nome"]))
	expedicao = {
		"ativa": true,
		"mercenarios": ids_mercenarios.duplicate(),
		"nomes": nomes,
		"vidas": vidas,
		"ouro_saqueado": 0,
		"sala": 1,
		"salas_total": SALAS_EXPEDICAO,
	}
	ultimo_relatorio = ""
	progresso_alterado.emit()
	return true

func iniciar_novo_turno() -> void:
	if fase != Fase.NOITE:
		return
	dia += 1
	tempo_turno = DURACAO_TURNO
	fase = Fase.MANHA
	fase_alterada.emit(fase)
	progresso_alterado.emit()
	SceneRouter.ir_para("res://Cenas/cena_principal.tscn", Vector2(320.0, 292.0))

func reiniciar_turno() -> void:
	fase = Fase.MANHA
	tempo_turno = DURACAO_TURNO
	velocidade_acelerada = false
	Engine.time_scale = 1.0
	fase_alterada.emit(fase)
	progresso_alterado.emit()

func obter_progresso_expedicao() -> float:
	if not bool(expedicao.get("ativa", false)):
		return 0.0
	return float(int(expedicao["sala"]) - 1) / float(expedicao["salas_total"])

func obter_dias_expedicao() -> int:
	return int(expedicao.get("sala", 0))

func obter_dias_previstos_expedicao() -> int:
	return int(expedicao.get("salas_total", 0))

func obter_equipa_expedicao() -> Array[Dictionary]:
	var equipa: Array[Dictionary] = []
	if not bool(expedicao.get("ativa", false)):
		return equipa
	for mercenario in mercenarios:
		var id := str(mercenario["id"])
		if not expedicao["mercenarios"].has(id):
			continue
		var combatente: Dictionary = mercenario.duplicate(true)
		combatente["vida_atual"] = int(expedicao["vidas"].get(
			id,
			int(mercenario.get("vida_maxima", 40))
		))
		equipa.append(combatente)
	return equipa

func atualizar_vida_expedicao(id_mercenario: String, vida: int) -> void:
	if not bool(expedicao.get("ativa", false)):
		return
	if not expedicao["mercenarios"].has(id_mercenario):
		return
	expedicao["vidas"][id_mercenario] = maxi(vida, 0)

func avancar_sala_expedicao() -> bool:
	if not bool(expedicao.get("ativa", false)):
		return false
	if int(expedicao["sala"]) >= int(expedicao["salas_total"]):
		return false
	expedicao["sala"] = int(expedicao["sala"]) + 1
	for combatente in obter_equipa_expedicao():
		var vida := int(combatente["vida_atual"])
		var vida_maxima := int(combatente["vida_maxima"])
		expedicao["vidas"][str(combatente["id"])] = mini(
			vida_maxima,
			vida + maxi(1, ceili(float(vida_maxima) * 0.2))
		)
	progresso_alterado.emit()
	return true

func finalizar_expedicao(vitoriosa: bool, ouro_saqueado: int) -> void:
	if not bool(expedicao.get("ativa", false)):
		return
	var ids: Array = expedicao["mercenarios"]
	var salas_concluidas := int(expedicao["sala"]) - 1
	if vitoriosa:
		salas_concluidas = int(expedicao["salas_total"])
	var experiencia := 20 + salas_concluidas * 30
	for mercenario in mercenarios:
		if ids.has(str(mercenario["id"])):
			_adicionar_experiencia(mercenario, experiencia)
			mercenario["vida_maxima"] = int(mercenario.get("vida_maxima", 40))

	if vitoriosa:
		InventoryManager.escudos += ouro_saqueado
		var tesouros: Array = TESOUROS_POR_QUALIDADE[mini(salas_concluidas, 3)]
		var item_id: String = tesouros[_rng.randi_range(0, tesouros.size() - 1)]
		InventoryManager.adicionar_item(
			item_id,
			1 + floori(float(salas_concluidas) / 2.0)
		)
		ultimo_relatorio = "Dungeon concluída · +%d ouro · saque: %s · +%d XP para a equipa." % [
			ouro_saqueado,
			item_id.replace("_", " "),
			experiencia,
		]
	else:
		ultimo_relatorio = "A equipa recuou após a sala %d · +%d XP para a equipa." % [
			maxi(salas_concluidas, 1),
			experiencia,
		]

	expedicao.clear()
	expedicao_concluida.emit(ultimo_relatorio)
	progresso_alterado.emit()

func _terminar_turno() -> void:
	if fase != Fase.LOJA:
		return
	tempo_turno = 0.0
	fase = Fase.NOITE
	_gerar_ofertas()
	fase_alterada.emit(fase)
	progresso_alterado.emit()

	var cena_atual := get_tree().current_scene
	if cena_atual != null and cena_atual.scene_file_path != "res://Cenas/PracaCentral.tscn":
		SceneRouter.ir_para("res://Cenas/PracaCentral.tscn", Vector2(540.0, 270.0))

func _gerar_ofertas() -> void:
	ofertas.clear()
	for indice_oferta in range(6):
		var profissao: String = (
			PROFISSOES[indice_oferta]
			if indice_oferta < PROFISSOES.size()
			else PROFISSOES[_rng.randi_range(0, PROFISSOES.size() - 1)]
		)
		var nivel_maximo := mini(
			10,
			5 + floori(float(maxi(dia - 1, 0)) / 2.0)
		)
		var nivel := _rng.randi_range(1, nivel_maximo)
		var poder_base := 4
		var velocidade_base := 4
		var habilidade := ""
		match profissao:
			"Guerreiro":
				poder_base = 7
				velocidade_base = 3
				habilidade = "Guarda firme"
			"Arqueiro":
				poder_base = 5
				velocidade_base = 7
				habilidade = "Olho certeiro"
			"Mago":
				poder_base = 8
				velocidade_base = 4
				habilidade = "Explosão arcana"
			"Curandeiro":
				poder_base = 4
				velocidade_base = 5
				habilidade = "Cura de campo"

		var nome: String = NOMES_MERCENARIOS[
			_rng.randi_range(0, NOMES_MERCENARIOS.size() - 1)
		]
		var vida_base := 30 + nivel * 8
		match profissao:
			"Guerreiro":
				vida_base += 18
			"Curandeiro":
				vida_base += 8
		var preco := 16 + nivel * 12 + maxi(dia - 1, 0) * 3 + _rng.randi_range(0, 18)
		ofertas.append({
			"id": _proximo_id_mercenario,
			"nome": nome,
			"profissao": profissao,
			"nivel": nivel,
			"experiencia": 0,
			"vida_maxima": vida_base,
			"poder": poder_base + nivel + _rng.randi_range(0, 3),
			"velocidade": velocidade_base + _rng.randi_range(0, 3),
			"habilidade": habilidade,
			"preco": preco,
		})
		_proximo_id_mercenario += 1

func _adicionar_experiencia(mercenario: Dictionary, quantidade: int) -> void:
	mercenario["experiencia"] = int(mercenario["experiencia"]) + quantidade
	while int(mercenario["experiencia"]) >= int(mercenario["nivel"]) * 50:
		mercenario["experiencia"] = (
			int(mercenario["experiencia"]) - int(mercenario["nivel"]) * 50
		)
		mercenario["nivel"] = int(mercenario["nivel"]) + 1
		mercenario["poder"] = int(mercenario["poder"]) + 1
		mercenario["velocidade"] = int(mercenario["velocidade"]) + 1
		mercenario["vida_maxima"] = int(mercenario.get("vida_maxima", 40)) + 8
