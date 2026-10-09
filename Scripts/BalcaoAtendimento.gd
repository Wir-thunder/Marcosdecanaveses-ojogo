class_name BalcaoAtendimento extends Area2D

signal feedback(mensagem: String)

var fila: Array[ClienteNPC] = []

func _ready() -> void:
	add_to_group("interactables")
	monitoring = true
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)

func _on_body_entered(body: Node2D) -> void:
	if body is ClienteNPC:
		var cliente := body as ClienteNPC
		if not fila.has(cliente):
			fila.append(cliente)

func _on_body_exited(body: Node2D) -> void:
	if body is ClienteNPC:
		fila.erase(body as ClienteNPC)

func interagir(jogador: Player) -> void:
	_limpar_fila()
	if fila.is_empty():
		feedback.emit("Ainda não há clientes à espera no balcão.")
		return
	var cliente := obter_cliente_atual()
	if cliente == null:
		feedback.emit("O cliente ainda está a chegar ao balcão.")
		return
	if jogador == null or jogador.pocao_ativa == null:
		feedback.emit("Seleciona uma poção antes de atender o cliente.")
		return

	var pocao: ItemData = jogador.pocao_ativa
	if InventoryManager.obter_quantidade(pocao.id) <= 0:
		feedback.emit("Não tens unidades de " + pocao.nome_do_item + ".")
		return

	if cliente.receber_pocao(pocao):
		InventoryManager.remover_item(pocao.id)
		jogador.atualizar_pocao_apos_venda()
		fila.erase(cliente)
		feedback.emit("Venda concluída: " + pocao.nome_do_item + " (+" + str(pocao.valor_em_escudos) + " escudos).")
	else:
		feedback.emit("Poção errada. O cliente pediu: " + cliente.item_desejado.nome_do_item + ".")

func obter_cliente_atual() -> ClienteNPC:
	_limpar_fila()
	for cliente in fila:
		if cliente.estado == ClienteNPC.Estado.ESPERANDO:
			return cliente
	return null

func _limpar_fila() -> void:
	for indice in range(fila.size() - 1, -1, -1):
		if not is_instance_valid(fila[indice]):
			fila.remove_at(indice)
