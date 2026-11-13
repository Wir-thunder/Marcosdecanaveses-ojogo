class_name BalcaoAtendimento extends Area2D

signal feedback(mensagem: String)

@export var painel_atendimento: PainelAtendimentoBalcao

var fila: Array[ClienteNPC] = []

func _ready() -> void:
	add_to_group("interactables")
	monitoring = true
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	if painel_atendimento == null:
		painel_atendimento = get_tree().get_first_node_in_group("painel_atendimento") as PainelAtendimentoBalcao

func _on_body_entered(body: Node2D) -> void:
	if body is ClienteNPC:
		var cliente := body as ClienteNPC
		if not fila.has(cliente):
			fila.append(cliente)

func _on_body_exited(body: Node2D) -> void:
	if body is ClienteNPC:
		fila.erase(body as ClienteNPC)

func interagir(jogador: Player) -> void:
	if CampaignManager.fase == CampaignManager.Fase.MANHA:
		CampaignManager.iniciar_turno_loja()
		feedback.emit("Loja aberta! Os clientes estão a caminho.")
		return
		
	_limpar_fila()
	var cliente := obter_cliente_atual()
	if cliente == null:
		if fila.is_empty() and get_tree().get_nodes_in_group("clientes").is_empty():
			feedback.emit("Ainda não há clientes à espera no balcão.")
		else:
			feedback.emit("O cliente ainda está a chegar ao balcão.")
		return

	# Swords & Potions: Abre o Painel de Atendimento Interativo
	if painel_atendimento == null:
		painel_atendimento = get_tree().get_first_node_in_group("painel_atendimento") as PainelAtendimentoBalcao

	if painel_atendimento != null:
		painel_atendimento.abrir(cliente, jogador)
		feedback.emit("A negociar com %s..." % cliente.nome_cliente)
		return

	# Fallback legado se o painel não estiver instanciado
	if jogador == null or jogador.pocao_ativa == null:
		feedback.emit("Seleciona uma poção antes de atender o cliente.")
		return

	var pocao: ItemData = jogador.pocao_ativa
	if InventoryManager.obter_quantidade(pocao.id) <= 0:
		feedback.emit("Não tens unidades de " + pocao.nome_do_item + ".")
		return

	var preco_venda: int = cliente.calcular_preco(pocao)
	if cliente.receber_pocao(pocao):
		InventoryManager.remover_item(pocao.id)
		jogador.atualizar_pocao_apos_venda()
		fila.erase(cliente)
		feedback.emit("Venda concluída: " + pocao.nome_do_item + " (+" + str(preco_venda) + " ouro).")
	else:
		feedback.emit("Poção errada. O cliente pediu: " + cliente.item_desejado.nome_do_item + ".")

func obter_cliente_atual() -> ClienteNPC:
	_limpar_fila()
	for c_fila in fila:
		if is_instance_valid(c_fila) and c_fila.estado == ClienteNPC.Estado.ESPERANDO:
			return c_fila
	for no in get_tree().get_nodes_in_group("clientes"):
		if no is ClienteNPC:
			var c := no as ClienteNPC
			if is_instance_valid(c) and c.estado == ClienteNPC.Estado.ESPERANDO:
				if not fila.has(c):
					fila.append(c)
				return c
	return null

func obter_pocao_solicitada() -> ItemData:
	var cliente := obter_cliente_atual()
	if cliente == null:
		return null
	return cliente.item_desejado

func _limpar_fila() -> void:
	for indice in range(fila.size() - 1, -1, -1):
		if not is_instance_valid(fila[indice]) or fila[indice].estado == ClienteNPC.Estado.SAINDO:
			fila.remove_at(indice)
