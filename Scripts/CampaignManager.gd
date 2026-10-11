extends Node

signal fase_alterada(fase: int)
signal progresso_alterado
signal expedicao_concluida(relatorio: String)

enum Fase { MANHA, LOJA, NOITE }

const DURACAO_TURNO: float = 180.0
const DURACAO_MINIMA_EXPEDICAO: float = 360.0
const DURACAO_MAXIMA_EXPEDICAO: float = 900.0
const PROFISSOES: Array[String] = ["Guerreiro", "Arqueiro", "Mago", "Curandeiro"]
const TESOUROS_POR_QUALIDADE: Array[Array] = [
	["calcedonia_fina", "po_granito_tongobriga", "azeite_do_olival"],
	["mel_do_olival", "pinho_resinato", "musgo_do_pombal"],
	["raiz_mandrago", "raiz_celeste", "basalto_fervente"],
	["lagrima_douro", "calcedonia_fina", "basalto_fervente"],
]
const NOMES_QUALIDADE: Array[String] = [
	"comum", "incomum", "raro", "lendário",
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

	if bool(expedicao.get("ativa", false)):
		expedicao["tempo_decorrido"] = minf(
			float(expedicao["tempo_decorrido"]) + delta,
			float(expedicao["duracao"])
		)
		progresso_alterado.emit()
		if float(expedicao["tempo_decorrido"]) >= float(expedicao["duracao"]):
			_concluir_expedicao()

func esta_de_noite() -> bool:
	return fase == Fase.NOITE

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

	var soma_velocidade: int = 0
	var soma_poder: int = 0
	var soma_niveis: int = 0
	var bonus_qualidade: int = 0
	var bonus_ouro: int = 0
	var bonus_recursos: int = 0
	var nomes: Array[String] = []
	for mercenario in equipa:
		soma_velocidade += int(mercenario["velocidade"])
		soma_poder += int(mercenario["poder"])
		soma_niveis += int(mercenario["nivel"])
		nomes.append(str(mercenario["nome"]))
		match str(mercenario["profissao"]):
			"Guerreiro":
				soma_poder += int(mercenario["nivel"])
			"Arqueiro":
				bonus_qualidade += 1
			"Mago":
				bonus_ouro += int(mercenario["nivel"]) * 8
			"Curandeiro":
				bonus_recursos += 1

	var duracao := clampf(
		DURACAO_MINIMA_EXPEDICAO + float(soma_poder * 15) - float(soma_velocidade * 10),
		DURACAO_MINIMA_EXPEDICAO,
		DURACAO_MAXIMA_EXPEDICAO
	)
	expedicao = {
		"ativa": true,
		"mercenarios": ids_mercenarios.duplicate(),
		"nomes": nomes,
		"tempo_decorrido": 0.0,
		"duracao": duracao,
		"dia_partida": dia,
		"nivel_medio": ceili(float(soma_niveis) / float(equipa.size())),
		"bonus_qualidade": bonus_qualidade,
		"bonus_ouro": bonus_ouro,
		"bonus_recursos": bonus_recursos,
		"soma_poder": soma_poder,
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
	return clampf(
		float(expedicao["tempo_decorrido"]) / float(expedicao["duracao"]),
		0.0,
		1.0
	)

func obter_tempo_expedicao() -> float:
	if not bool(expedicao.get("ativa", false)):
		return 0.0
	return maxf(
		float(expedicao["duracao"]) - float(expedicao["tempo_decorrido"]),
		0.0
	)

func obter_dias_expedicao() -> int:
	if not bool(expedicao.get("ativa", false)):
		return 0
	return maxi(1, ceili(
		float(expedicao["tempo_decorrido"]) / DURACAO_TURNO
	))

func obter_dias_previstos_expedicao() -> int:
	if not bool(expedicao.get("ativa", false)):
		return 0
	return maxi(1, ceili(float(expedicao["duracao"]) / DURACAO_TURNO))

func obter_qualidade_expedicao() -> int:
	if not bool(expedicao.get("ativa", false)):
		return 0
	return _calcular_qualidade(
		obter_dias_expedicao(),
		int(expedicao["nivel_medio"]),
		int(expedicao["dia_partida"]),
		int(expedicao["bonus_qualidade"])
	)

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
	for profissao in PROFISSOES:
		var nivel_maximo := mini(
			10,
			3 + floori(float(maxi(dia - 1, 0)) / 3.0)
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
		var preco := 18 + nivel * 9 + maxi(dia - 1, 0) * 2 + _rng.randi_range(0, 15)
		ofertas.append({
			"id": _proximo_id_mercenario,
			"nome": nome,
			"profissao": profissao,
			"nivel": nivel,
			"experiencia": 0,
			"poder": poder_base + nivel + _rng.randi_range(0, 3),
			"velocidade": velocidade_base + _rng.randi_range(0, 3),
			"habilidade": habilidade,
			"preco": preco,
		})
		_proximo_id_mercenario += 1

func _concluir_expedicao() -> void:
	var dias := obter_dias_expedicao()
	var equipa_ids: Array = expedicao["mercenarios"]
	var qualidade := _calcular_qualidade(
		dias,
		int(expedicao["nivel_medio"]),
		int(expedicao["dia_partida"]),
		int(expedicao["bonus_qualidade"])
	)
	var ouro := (
		20
		+ int(expedicao["soma_poder"]) * 2
		+ equipa_ids.size() * 8
		+ int(expedicao["bonus_ouro"])
		+ dias * 12
	) * (qualidade + 1)
	var quantidade_itens := clampi(
		1 + qualidade + floori(float(expedicao["soma_poder"]) / 20.0)
			+ int(expedicao["bonus_recursos"]),
		1,
		12
	)
	var itens_encontrados: Dictionary = {}
	for _indice in range(quantidade_itens):
		var tesouros: Array = TESOUROS_POR_QUALIDADE[qualidade]
		var item_id: String = tesouros[
			_rng.randi_range(0, tesouros.size() - 1)
		]
		itens_encontrados[item_id] = int(itens_encontrados.get(item_id, 0)) + 1

	for item_id in itens_encontrados:
		InventoryManager.adicionar_item(item_id, int(itens_encontrados[item_id]))

	var nomes_itens: Array[String] = []
	for item_id in itens_encontrados:
		var nome_item := str(item_id).replace("_", " ")
		nomes_itens.append("%dx %s" % [itens_encontrados[item_id], nome_item])

	for mercenario in mercenarios:
		if equipa_ids.has(str(mercenario["id"])):
			_adicionar_experiencia(
				mercenario,
				35 + equipa_ids.size() * 10 + dias * 15 + qualidade * 10
			)

	InventoryManager.escudos += ouro
	ultimo_relatorio = "Expedição de %d dias · saque %s: +%d ouro · %s." % [
		dias,
		NOMES_QUALIDADE[qualidade],
		ouro,
		", ".join(PackedStringArray(nomes_itens)),
	]
	expedicao.clear()
	expedicao_concluida.emit(ultimo_relatorio)
	progresso_alterado.emit()

func _adicionar_experiencia(mercenario: Dictionary, quantidade: int) -> void:
	mercenario["experiencia"] = int(mercenario["experiencia"]) + quantidade
	while int(mercenario["experiencia"]) >= int(mercenario["nivel"]) * 50:
		mercenario["experiencia"] = (
			int(mercenario["experiencia"]) - int(mercenario["nivel"]) * 50
		)
		mercenario["nivel"] = int(mercenario["nivel"]) + 1
		mercenario["poder"] = int(mercenario["poder"]) + 1
		mercenario["velocidade"] = int(mercenario["velocidade"]) + 1

func _calcular_qualidade(
	dias: int,
	nivel_medio: int,
	dia_partida: int,
	bonus_qualidade: int
) -> int:
	var progresso_mundo := floori(float(maxi(dia_partida - 1, 0)) / 4.0)
	var pontos := dias + floori(float(nivel_medio - 1) / 2.0)
	pontos += progresso_mundo + bonus_qualidade
	if pontos >= 9:
		return 3
	if pontos >= 6:
		return 2
	if pontos >= 3:
		return 1
	return 0
