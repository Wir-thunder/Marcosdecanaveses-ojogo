extends Node

const SAVE_PATH: String = "user://savegame.json"
const SAVE_VERSION: int = 1

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	if tem_save():
		carregar_jogo()

func tem_save() -> bool:
	return FileAccess.file_exists(SAVE_PATH)

func salvar_jogo() -> bool:
	var dados := {
		"version": SAVE_VERSION,
		"timestamp": Time.get_unix_time_from_system(),
		"inventory": {
			"escudos": InventoryManager.escudos,
			"renome_loja": InventoryManager.renome_loja,
			"inventario": InventoryManager.inventario.duplicate(true),
			"inventario_ouro": InventoryManager.inventario_ouro.duplicate(true),
			"mestria_pocao": InventoryManager.mestria_pocao.duplicate(true),
			"receitas_desbloqueadas": Array(InventoryManager.receitas_desbloqueadas),
			"nivel_balcao": InventoryManager.nivel_balcao,
			"nivel_caldeirao": InventoryManager.nivel_caldeirao,
			"nivel_receitas": InventoryManager.nivel_receitas,
			"nivel_vitrine": InventoryManager.nivel_vitrine,
			"nivel_fornecedor": InventoryManager.nivel_fornecedor,
			"recolhas": InventoryManager.recolhas.duplicate(true),
			"tendencia": {
				"id": InventoryManager.pocao_tendencia_dia_id,
				"nome": InventoryManager.nome_pocao_tendencia_dia,
				"motivo": InventoryManager.motivo_tendencia_dia,
			},
		},
		"campaign": {
			"dia": CampaignManager.dia,
			"fase": int(CampaignManager.fase),
			"tempo_turno": CampaignManager.tempo_turno,
			"clientes_gerados_hoje": CampaignManager.clientes_gerados_hoje,
			"mercenarios": _duplicar_array_dicionarios(CampaignManager.mercenarios),
			"ofertas": _duplicar_array_dicionarios(CampaignManager.ofertas),
			"buffs": {
				"poder": CampaignManager.buff_taverna_poder,
				"vida_extra": CampaignManager.buff_taverna_vida_extra,
				"velocidade": CampaignManager.buff_taverna_velocidade,
				"ouro_mult": CampaignManager.buff_taverna_ouro_mult,
				"pratos_consumidos_hoje": Array(CampaignManager.pratos_consumidos_hoje),
			},
			"marco_lutador_desbloqueado": CampaignManager.marco_lutador_desbloqueado,
			"tongobriga_intro_vista": CampaignManager.tongobriga_intro_vista,
			"torneio_jogado_dia": CampaignManager.torneio_jogado_dia,
			"dificuldade_ia": CampaignManager.dificuldade_ia,
			"ultimo_relatorio": CampaignManager.ultimo_relatorio,
		},
	}

	var json_texto := JSON.stringify(dados, "\t")
	var arquivo := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if arquivo == null:
		push_warning("SaveManager: não foi possível abrir %s para escrita (erro %d)." % [SAVE_PATH, FileAccess.get_open_error()])
		return false
	arquivo.store_string(json_texto)
	arquivo.close()
	return true

func carregar_jogo() -> bool:
	if not tem_save():
		return false

	var arquivo := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if arquivo == null:
		push_warning("SaveManager: não foi possível abrir %s para leitura." % SAVE_PATH)
		return false
	var conteudo := arquivo.get_as_text()
	arquivo.close()

	if conteudo.strip_edges().is_empty():
		return false

	var parsed: Variant = JSON.parse_string(conteudo)
	if typeof(parsed) != TYPE_DICTIONARY:
		push_warning("SaveManager: ficheiro de save inválido.")
		return false

	var dados: Dictionary = parsed
	if dados.has("inventory") and typeof(dados["inventory"]) == TYPE_DICTIONARY:
		_aplicar_inventory(dados["inventory"])
	if dados.has("campaign") and typeof(dados["campaign"]) == TYPE_DICTIONARY:
		_aplicar_campaign(dados["campaign"])

	InventoryManager.renome_alterado.emit(InventoryManager.renome_loja, InventoryManager.obter_titulo_fama())
	CampaignManager.progresso_alterado.emit()
	return true

func apagar_save() -> void:
	if FileAccess.file_exists(SAVE_PATH):
		var err := DirAccess.remove_absolute(SAVE_PATH)
		if err != OK:
			push_warning("SaveManager: falha ao apagar save (erro %d)." % err)

func resetar_estado_novo_jogo() -> void:
	InventoryManager.inventario.clear()
	InventoryManager.inventario_ouro.clear()
	InventoryManager.recolhas.clear()
	InventoryManager.mestria_pocao.clear()
	InventoryManager.escudos = 20
	InventoryManager.renome_loja = 0
	InventoryManager.nivel_receitas = 1
	InventoryManager.nivel_vitrine = 0
	InventoryManager.nivel_caldeirao = 1
	InventoryManager.nivel_balcao = 1
	InventoryManager.nivel_fornecedor = 1
	InventoryManager.bonus_ouro_vitrine_atual = 1.0
	InventoryManager.receitas_desbloqueadas.clear()
	InventoryManager.receitas_desbloqueadas.append("res://Recursos/Recursos_receitas/receita_vento_ligeiro.tres")
	InventoryManager.pocao_tendencia_dia_id = "pocao_vento_ligeiro"
	InventoryManager.nome_pocao_tendencia_dia = "Poção Vento Ligeiro"
	InventoryManager.motivo_tendencia_dia = "Colheita nas Encostas"

	CampaignManager.dia = 1
	CampaignManager.fase = CampaignManager.Fase.MANHA
	CampaignManager.tempo_turno = CampaignManager.DURACAO_TURNO
	CampaignManager.clientes_gerados_hoje = 0
	CampaignManager.velocidade_acelerada = false
	CampaignManager.expedicao.clear()
	CampaignManager.ultimo_relatorio = ""
	CampaignManager.torneio_jogado_dia = -1
	CampaignManager.marco_lutador_desbloqueado = false
	CampaignManager.tongobriga_intro_vista = false
	CampaignManager.buff_taverna_poder = 0
	CampaignManager.buff_taverna_vida_extra = 0
	CampaignManager.buff_taverna_velocidade = 0
	CampaignManager.buff_taverna_ouro_mult = 1.0
	CampaignManager.pratos_consumidos_hoje.clear()
	CampaignManager.mercenarios.clear()
	CampaignManager._proximo_id_mercenario = 1
	CampaignManager.mercenarios.append({
		"id": 1,
		"nome": "Rodrigo",
		"profissao": "Guerreiro",
		"nivel": 1,
		"experiencia": 0,
		"vida_maxima": 45,
		"poder": 8,
		"velocidade": 4,
		"habilidade": "Guarda firme",
		"preco": 0
	})
	CampaignManager._proximo_id_mercenario = 2
	CampaignManager._gerar_ofertas()
	Engine.time_scale = 1.0

	InventoryManager.renome_alterado.emit(InventoryManager.renome_loja, InventoryManager.obter_titulo_fama())
	CampaignManager.fase_alterada.emit(CampaignManager.fase)
	CampaignManager.progresso_alterado.emit()

func _aplicar_inventory(inv: Dictionary) -> void:
	InventoryManager.escudos = int(inv.get("escudos", InventoryManager.escudos))
	InventoryManager.renome_loja = int(inv.get("renome_loja", InventoryManager.renome_loja))
	InventoryManager.nivel_balcao = int(inv.get("nivel_balcao", InventoryManager.nivel_balcao))
	InventoryManager.nivel_caldeirao = int(inv.get("nivel_caldeirao", InventoryManager.nivel_caldeirao))
	InventoryManager.nivel_receitas = int(inv.get("nivel_receitas", InventoryManager.nivel_receitas))
	if inv.has("nivel_vitrine"):
		InventoryManager.nivel_vitrine = int(inv.get("nivel_vitrine", 0))
	elif inv.has("nivel_prateleira"):
		InventoryManager.nivel_vitrine = int(inv.get("nivel_prateleira", 0))
	InventoryManager.nivel_fornecedor = int(inv.get("nivel_fornecedor", InventoryManager.nivel_fornecedor))

	if inv.has("inventario") and typeof(inv["inventario"]) == TYPE_DICTIONARY:
		InventoryManager.inventario = _converter_dict_int(inv["inventario"])
	if inv.has("inventario_ouro") and typeof(inv["inventario_ouro"]) == TYPE_DICTIONARY:
		InventoryManager.inventario_ouro = _converter_dict_int(inv["inventario_ouro"])
	if inv.has("mestria_pocao") and typeof(inv["mestria_pocao"]) == TYPE_DICTIONARY:
		InventoryManager.mestria_pocao = _converter_dict_int(inv["mestria_pocao"])
	if inv.has("recolhas") and typeof(inv["recolhas"]) == TYPE_DICTIONARY:
		var rec_dict: Dictionary = {}
		for k in inv["recolhas"].keys():
			rec_dict[str(k)] = bool(inv["recolhas"][k])
		InventoryManager.recolhas = rec_dict

	if inv.has("receitas_desbloqueadas") and typeof(inv["receitas_desbloqueadas"]) == TYPE_ARRAY:
		var arr: Array = inv["receitas_desbloqueadas"]
		if not arr.is_empty():
			InventoryManager.receitas_desbloqueadas.clear()
			for item in arr:
				var caminho := str(item)
				if not caminho.is_empty() and not InventoryManager.receitas_desbloqueadas.has(caminho):
					InventoryManager.receitas_desbloqueadas.append(caminho)

	if inv.has("tendencia") and typeof(inv["tendencia"]) == TYPE_DICTIONARY:
		var tend: Dictionary = inv["tendencia"]
		InventoryManager.pocao_tendencia_dia_id = str(tend.get("id", InventoryManager.pocao_tendencia_dia_id))
		InventoryManager.nome_pocao_tendencia_dia = str(tend.get("nome", InventoryManager.nome_pocao_tendencia_dia))
		InventoryManager.motivo_tendencia_dia = str(tend.get("motivo", InventoryManager.motivo_tendencia_dia))

func _aplicar_campaign(camp: Dictionary) -> void:
	CampaignManager.dia = maxi(1, int(camp.get("dia", CampaignManager.dia)))
	var fase_int: int = clampi(int(camp.get("fase", int(CampaignManager.fase))), 0, 2)
	CampaignManager.fase = fase_int as CampaignManager.Fase
	CampaignManager.tempo_turno = float(camp.get("tempo_turno", CampaignManager.tempo_turno))
	CampaignManager.clientes_gerados_hoje = int(camp.get("clientes_gerados_hoje", CampaignManager.clientes_gerados_hoje))
	CampaignManager.marco_lutador_desbloqueado = bool(camp.get("marco_lutador_desbloqueado", CampaignManager.marco_lutador_desbloqueado))
	CampaignManager.tongobriga_intro_vista = bool(camp.get("tongobriga_intro_vista", CampaignManager.tongobriga_intro_vista))
	CampaignManager.torneio_jogado_dia = int(camp.get("torneio_jogado_dia", CampaignManager.torneio_jogado_dia))
	CampaignManager.dificuldade_ia = int(camp.get("dificuldade_ia", CampaignManager.dificuldade_ia))
	CampaignManager.ultimo_relatorio = str(camp.get("ultimo_relatorio", CampaignManager.ultimo_relatorio))

	var max_id: int = 0
	if camp.has("mercenarios") and typeof(camp["mercenarios"]) == TYPE_ARRAY:
		var mercs: Array = camp["mercenarios"]
		if not mercs.is_empty():
			CampaignManager.mercenarios.clear()
			for m in mercs:
				if typeof(m) == TYPE_DICTIONARY:
					var normalizado := _normalizar_mercenario(m)
					max_id = maxi(max_id, int(normalizado.get("id", 0)))
					CampaignManager.mercenarios.append(normalizado)

	if camp.has("ofertas") and typeof(camp["ofertas"]) == TYPE_ARRAY:
		var of_arr: Array = camp["ofertas"]
		CampaignManager.ofertas.clear()
		for o in of_arr:
			if typeof(o) == TYPE_DICTIONARY:
				var normalizado := _normalizar_mercenario(o)
				max_id = maxi(max_id, int(normalizado.get("id", 0)))
				CampaignManager.ofertas.append(normalizado)

	CampaignManager._proximo_id_mercenario = maxi(CampaignManager._proximo_id_mercenario, max_id + 1)

	if camp.has("buffs") and typeof(camp["buffs"]) == TYPE_DICTIONARY:
		var buffs: Dictionary = camp["buffs"]
		CampaignManager.buff_taverna_poder = int(buffs.get("poder", 0))
		CampaignManager.buff_taverna_vida_extra = int(buffs.get("vida_extra", 0))
		CampaignManager.buff_taverna_velocidade = int(buffs.get("velocidade", 0))
		CampaignManager.buff_taverna_ouro_mult = float(buffs.get("ouro_mult", 1.0))
		if buffs.has("pratos_consumidos_hoje") and typeof(buffs["pratos_consumidos_hoje"]) == TYPE_ARRAY:
			CampaignManager.pratos_consumidos_hoje.clear()
			for prato in buffs["pratos_consumidos_hoje"]:
				CampaignManager.pratos_consumidos_hoje.append(str(prato))

func _converter_dict_int(origem: Dictionary) -> Dictionary:
	var resultado: Dictionary = {}
	for k in origem.keys():
		var val := int(origem[k])
		if val > 0:
			resultado[str(k)] = val
	return resultado

func _duplicar_array_dicionarios(lista: Array[Dictionary]) -> Array[Dictionary]:
	var copia: Array[Dictionary] = []
	for item in lista:
		copia.append(item.duplicate(true))
	return copia

func _normalizar_mercenario(m: Dictionary) -> Dictionary:
	var copia: Dictionary = m.duplicate(true)
	for campo_int in ["id", "nivel", "experiencia", "vida_maxima", "vida_maxima_base", "poder", "velocidade", "preco"]:
		if copia.has(campo_int):
			copia[campo_int] = int(copia[campo_int])
	return copia
