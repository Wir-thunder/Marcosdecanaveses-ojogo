extends Node2D

const CENA_CLIENTE: PackedScene = preload("res://Cenas/ClienteNPC.tscn")
const INGREDIENTES_INICIAIS: Array[ItemData] = [
	preload("res://Recursos/Recursos_ingredientes/hortela_nobre.tres"),
	preload("res://Recursos/Recursos_ingredientes/musgo_aboboreira.tres"),
	preload("res://Recursos/Recursos_ingredientes/arnica_selvagem.tres"),
	preload("res://Recursos/Recursos_ingredientes/calcedonia_fina.tres"),
	preload("res://Recursos/Recursos_ingredientes/erva_cidreira.tres"),
	preload("res://Recursos/Recursos_ingredientes/po_granito_tongobriga.tres"),
	preload("res://Recursos/Recursos_ingredientes/azeite_do_olival.tres"),
]
const POCOES: Array[ItemData] = [
	preload("res://Recursos/Recursos_pocoes/pocao_vento_ligeiro.tres"),
	preload("res://Recursos/Recursos_pocoes/pocao_espinheira_real.tres"),
	preload("res://Recursos/Recursos_pocoes/pocao_mente_limpida.tres"),
	preload("res://Recursos/Recursos_pocoes/pocao_escudo_do_lago.tres"),
]

@onready var jogador: Player = $Player
@onready var balcao: BalcaoAtendimento = $Balcao
@onready var caldeirao: Caldeirao = $Caldeirao
@onready var fornecedor: Fornecedor = $Fornecedor
@onready var temporizador_cliente: Timer = $TemporizadorCliente
@onready var estado_label: Label = $Interface/Painel/Margem/Coluna/Estado
@onready var receita_label: Label = $Interface/Rodape/Margem/Coluna/Receita
@onready var inventario_label: Label = $Interface/Rodape/Margem/Coluna/Inventario
@onready var instrucoes_label: Label = $Interface/Rodape/Margem/Coluna/Instrucoes
@onready var barra_pocoes: HBoxContainer = $Interface/BarraPocoes
@onready var temporizador_feedback: Timer = $TemporizadorFeedback
@onready var pausa_overlay: CanvasLayer = $Pausa
@onready var botao_retomar: Button = $Pausa/Painel/Margem/Coluna/Retomar
@onready var botao_reiniciar: Button = $Pausa/Painel/Margem/Coluna/Reiniciar
@onready var botao_sair: Button = $Pausa/Painel/Margem/Coluna/Sair

var estado_padrao: String = ""
var clientes_ativos: Array[ClienteNPC] = []
var clientes_gerados: int = 0
var _tipos_visuais_do_turno: Array[int] = [0, 1, 2, 3, 4]

func _ready() -> void:
	_tipos_visuais_do_turno.shuffle()
	_inicializar_inventario()
	jogador.pocoes_disponiveis = POCOES
	if jogador.pocao_ativa == null:
		jogador.pocao_ativa = POCOES[0]

	balcao.feedback.connect(_mostrar_feedback)
	caldeirao.feedback.connect(_mostrar_feedback)
	fornecedor.feedback.connect(_mostrar_feedback)
	caldeirao.receita_alterada.connect(_ao_alterar_receita)
	jogador.pocao_selecionada_alterada.connect(_ao_selecionar_pocao)
	jogador.pocao_indisponivel.connect(_ao_pocao_indisponivel)
	pausa_overlay.connect("escape_pressed", _alternar_pausa)
	temporizador_cliente.timeout.connect(_criar_cliente)
	CampaignManager.fase_alterada.connect(_ao_alterar_fase)
	temporizador_feedback.one_shot = true
	_criar_botoes_pocoes()
	botao_retomar.pressed.connect(retomar_jogo)
	botao_reiniciar.pressed.connect(reiniciar_jogo)
	botao_sair.pressed.connect(sair_do_jogo)
	if CampaignManager.fase == CampaignManager.Fase.LOJA:
		temporizador_cliente.start(2.0)
	else:
		temporizador_cliente.stop()
	instrucoes_label.text = "WASD mover · E usar · Q pedido/ciclo · 1–4 escolher · TAB receita · F ingrediente · ESC pausa"
	_atualizar_receita()

func _process(_delta: float) -> void:
	if get_tree().paused:
		return

	var pocao_texto := "Nenhuma"
	var quantidade := 0
	if jogador.pocao_ativa != null:
		pocao_texto = jogador.pocao_ativa.nome_do_item
		quantidade = InventoryManager.obter_quantidade(jogador.pocao_ativa.id)

	var pedido_texto := "Clientes: %d/5" % clientes_gerados
	var cliente := balcao.obter_cliente_atual()
	if cliente != null and cliente.item_desejado != null:
		pedido_texto = "N%d · PEDIDO: %s · %ds · %d ouro" % [
			cliente.nivel_cliente,
			cliente.item_desejado.nome_do_item,
			ceili(cliente.timer_paciencia.time_left),
			cliente.calcular_preco(cliente.item_desejado),
		]
	elif not clientes_ativos.is_empty():
		pedido_texto = "Clientes a chegar/atender · %d/5" % clientes_gerados

	if CampaignManager.fase == CampaignManager.Fase.MANHA:
		estado_padrao = "DIA %d · MANHÃ · ABASTECE AS POÇÕES — PLAY PARA ABRIR\nOURO %d · POÇÃO %s ×%d" % [
			CampaignManager.dia,
			jogador.escudos,
			pocao_texto,
			quantidade,
		]
	else:
		estado_padrao = "DIA %d · LOJA %s · OURO %d · POÇÃO %s ×%d\n%s" % [
			CampaignManager.dia,
			_formata_tempo(CampaignManager.tempo_turno),
			jogador.escudos,
			pocao_texto,
			quantidade,
			pedido_texto,
		]
	if temporizador_feedback.is_stopped():
		estado_label.text = estado_padrao
	inventario_label.text = "%s · %s" % [
		_resumo_inventario(),
		_resumo_fornecedor(),
	]
	receita_label.text = _resumo_receita()
	_atualizar_botoes_pocoes()

	var alvo := jogador.obter_alvo_interacao()
	instrucoes_label.text = _obter_instrucao_contextual(alvo)

func _inicializar_inventario() -> void:
	if not InventoryManager.inventario.is_empty():
		return
	for ingrediente in INGREDIENTES_INICIAIS:
		InventoryManager.adicionar_item(ingrediente.id, 4)
	for pocao in POCOES:
		InventoryManager.adicionar_item(pocao.id, 1)

func _resumo_inventario() -> String:
	var nomes_curto: Array[String] = ["Vento", "Cura", "Mente", "Escudo"]
	var linhas: PackedStringArray = ["STOCK"]
	for indice in range(POCOES.size()):
		var pocao: ItemData = POCOES[indice]
		linhas.append("%s %d" % [nomes_curto[indice], InventoryManager.obter_quantidade(pocao.id)])
	return "  |  ".join(linhas)

func _resumo_receita() -> String:
	return "RECEITA  " + caldeirao.obter_resumo_receita()

func _atualizar_receita() -> void:
	receita_label.text = _resumo_receita()

func _resumo_fornecedor() -> String:
	var ingrediente := fornecedor.obter_ingrediente_selecionado()
	if ingrediente != null:
		return "%s %d · preço %d ouro" % [
			ingrediente.nome_do_item,
			InventoryManager.obter_quantidade(ingrediente.id),
			fornecedor.custo_por_ingrediente,
		]
	return "FORNECEDOR indisponível"

func _formata_tempo(segundos: float) -> String:
	var minutos := floori(segundos / 60.0)
	var segundos_restantes := int(segundos) % 60
	return "%02d:%02d" % [minutos, segundos_restantes]

func _mostrar_feedback(mensagem: String) -> void:
	estado_label.text = mensagem
	temporizador_feedback.start(2.5)

func _ao_alterar_receita(_receita: PotionRecipeData) -> void:
	_atualizar_receita()

func _ao_selecionar_pocao(_pocao: ItemData) -> void:
	if not is_node_ready():
		return
	temporizador_feedback.stop()
	_atualizar_botoes_pocoes()

func _ao_pocao_indisponivel(pocao: ItemData) -> void:
	_mostrar_feedback("Não tens unidades de %s." % pocao.nome_do_item)

func _criar_botoes_pocoes() -> void:
	var nomes: Array[String] = ["Vento", "Cura", "Mente", "Escudo"]
	for indice in range(jogador.pocoes_disponiveis.size()):
		var pocao := jogador.pocoes_disponiveis[indice]
		if pocao == null:
			continue
		var botao := Button.new()
		botao.custom_minimum_size = Vector2(0.0, 22.0)
		botao.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		botao.toggle_mode = true
		botao.add_theme_font_size_override("font_size", 9)
		botao.add_theme_color_override("font_color", Color(0.92, 0.88, 0.75, 1))
		botao.add_theme_color_override("font_hover_color", Color(1, 0.94, 0.72, 1))
		botao.add_theme_stylebox_override("normal", _estilo_botao_pocao(Color(0.16, 0.13, 0.11, 0.96)))
		botao.add_theme_stylebox_override("hover", _estilo_botao_pocao(Color(0.25, 0.2, 0.14, 1)))
		botao.add_theme_stylebox_override("pressed", _estilo_botao_pocao(Color(0.3, 0.25, 0.15, 1)))
		botao.add_theme_stylebox_override("disabled", _estilo_botao_pocao(Color(0.12, 0.11, 0.1, 0.7)))
		botao.pressed.connect(_selecionar_pocao_indice.bind(indice))
		barra_pocoes.add_child(botao)
	_atualizar_botoes_pocoes()

func _estilo_botao_pocao(cor_fundo: Color) -> StyleBoxFlat:
	var estilo := StyleBoxFlat.new()
	estilo.bg_color = cor_fundo
	estilo.border_width_left = 1
	estilo.border_width_top = 1
	estilo.border_width_right = 1
	estilo.border_width_bottom = 1
	estilo.border_color = Color(0.48, 0.34, 0.21, 1)
	estilo.content_margin_left = 3.0
	estilo.content_margin_right = 3.0
	return estilo

func _selecionar_pocao_indice(indice: int) -> void:
	jogador.selecionar_pocao_indice(indice)

func _atualizar_botoes_pocoes() -> void:
	if barra_pocoes == null or not is_node_ready():
		return
	var nomes: Array[String] = ["Vento", "Cura", "Mente", "Escudo"]
	for indice in range(barra_pocoes.get_child_count()):
		var botao := barra_pocoes.get_child(indice) as Button
		if botao == null or indice >= jogador.pocoes_disponiveis.size():
			continue
		var pocao := jogador.pocoes_disponiveis[indice]
		if pocao == null:
			continue
		var quantidade := InventoryManager.obter_quantidade(pocao.id)
		var nome_curto := nomes[indice] if indice < nomes.size() else pocao.nome_do_item
		botao.text = "%d  %s  ×%d" % [indice + 1, nome_curto, quantidade]
		botao.button_pressed = jogador.pocao_ativa == pocao
		botao.disabled = quantidade <= 0

func _obter_instrucao_contextual(alvo: Node2D) -> String:
	if alvo == balcao:
		var cliente := balcao.obter_cliente_atual()
		if cliente != null and cliente.item_desejado != null:
			if jogador.pocao_ativa == cliente.item_desejado:
				return "E  ENTREGAR %s" % cliente.item_desejado.nome_do_item.to_upper()
			return "Q  SELECIONAR %s  ·  E  ENTREGAR" % cliente.item_desejado.nome_do_item.to_upper()
		return "CLIENTE A CAMINHO"
	if alvo == caldeirao:
		return "E  PREPARAR POÇÃO  ·  TAB  TROCAR RECEITA"
	if alvo == fornecedor:
		return "E  COMPRAR INGREDIENTE     ·     F  TROCAR ITEM"
	if alvo != null and alvo.has_method("obter_texto_interacao"):
		return str(alvo.call("obter_texto_interacao"))
	var cliente := balcao.obter_cliente_atual()
	if cliente != null and cliente.item_desejado != null:
		if jogador.pocao_ativa == cliente.item_desejado:
			return "VAI AO BALCÃO E PRESSIONA E PARA ENTREGAR"
		return "Q  ESCOLHE %s  ·  VAI AO BALCÃO  ·  E  ENTREGA" % cliente.item_desejado.nome_do_item.to_upper()
	return "WASD / SETAS  MOVER     ·     APROXIMA-TE DE UMA ESTAÇÃO"

func _alternar_pausa() -> void:
	if get_tree().paused:
		retomar_jogo()
	else:
		pausar_jogo()

func pausar_jogo() -> void:
	pausa_overlay.visible = true
	get_tree().paused = true
	botao_retomar.grab_focus()

func retomar_jogo() -> void:
	pausa_overlay.visible = false
	get_tree().paused = false

func reiniciar_jogo() -> void:
	get_tree().paused = false
	CampaignManager.reiniciar_turno()
	get_tree().reload_current_scene()

func sair_do_jogo() -> void:
	get_tree().paused = false
	get_tree().quit()

func _criar_cliente() -> void:
	if CampaignManager.fase != CampaignManager.Fase.LOJA or clientes_gerados >= 5:
		temporizador_cliente.stop()
		return

	var cliente := CENA_CLIENTE.instantiate() as ClienteNPC
	if cliente == null:
		push_error("Não foi possível criar a cena do cliente.")
		return
	cliente.itens_possiveis = POCOES
	cliente.nivel_cliente = randi_range(1, 5)
	cliente.multiplicador_preco = randf_range(
		0.8 + float(cliente.nivel_cliente) * 0.12,
		1.0 + float(cliente.nivel_cliente) * 0.18
	)
	cliente.velocidade = randf_range(32.0, 50.0) + float(cliente.nivel_cliente) * 2.0
	cliente.paciencia_total = randf_range(28.0, 52.0) - float(cliente.nivel_cliente)
	cliente.tipo_visual = _tipos_visuais_do_turno[clientes_gerados]
	cliente.ponto_entrada = Vector2(600.0, 250.0)
	var posicao_fila := clientes_ativos.size()
	cliente.ponto_espera = Vector2(
		330.0 + float(posicao_fila - 2) * 24.0,
		250.0
	)
	cliente.ponto_saida = Vector2(600.0, 250.0)
	cliente.venda_fracassada.connect(_ao_cliente_desistir)
	cliente.venda_sucesso.connect(_ao_cliente_vender)
	cliente.tree_exited.connect(_ao_cliente_sair.bind(cliente.get_instance_id()))
	add_child(cliente)
	clientes_ativos.append(cliente)
	clientes_gerados += 1

	if clientes_gerados < 5:
		temporizador_cliente.start(randf_range(9.0, 19.0))

func _ao_cliente_vender(_pocao: ItemData, valor: int) -> void:
	_mostrar_feedback("Venda concluída: +%d ouro." % valor)

func _ao_cliente_desistir(_pocao: ItemData) -> void:
	_mostrar_feedback("O cliente perdeu a paciência. Mantém a loja abastecida.")

func _ao_cliente_sair(id_instancia: int) -> void:
	var cliente_removido := false
	for indice in range(clientes_ativos.size() - 1, -1, -1):
		if (
			not is_instance_valid(clientes_ativos[indice])
			or clientes_ativos[indice].get_instance_id() == id_instancia
		):
			clientes_ativos.remove_at(indice)
			cliente_removido = true
			break
	if (
		cliente_removido
		and clientes_gerados >= 5
		and clientes_ativos.is_empty()
		and CampaignManager.fase == CampaignManager.Fase.LOJA
	):
		CampaignManager.encerrar_turno()

func _ao_alterar_fase(nova_fase: int) -> void:
	if nova_fase == CampaignManager.Fase.LOJA:
		if clientes_gerados < 5:
			temporizador_cliente.start(2.0)
	elif nova_fase != CampaignManager.Fase.LOJA:
		temporizador_cliente.stop()
