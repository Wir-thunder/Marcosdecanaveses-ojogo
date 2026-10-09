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
@onready var receita_label: Label = $Interface/Painel/Margem/Coluna/Receita
@onready var inventario_label: Label = $Interface/Painel/Margem/Coluna/Inventario
@onready var fornecedor_label: Label = $Interface/Painel/Margem/Coluna/Fornecedor
@onready var instrucoes_label: Label = $Interface/Painel/Margem/Coluna/Instrucoes
@onready var temporizador_feedback: Timer = $TemporizadorFeedback

var cliente_atual: ClienteNPC
var estado_padrao: String = ""

func _ready() -> void:
	_inicializar_inventario()
	jogador.pocoes_disponiveis = POCOES
	if jogador.pocao_ativa == null:
		jogador.pocao_ativa = POCOES[0]

	balcao.feedback.connect(_mostrar_feedback)
	caldeirao.feedback.connect(_mostrar_feedback)
	fornecedor.feedback.connect(_mostrar_feedback)
	caldeirao.receita_alterada.connect(_ao_alterar_receita)
	temporizador_cliente.timeout.connect(_criar_cliente)
	temporizador_feedback.one_shot = true
	temporizador_cliente.start(0.5)
	instrucoes_label.text = "WASD/setas mover | E/Espaço usar | Q trocar poção | Tab receita | F ingrediente\nVende poções no balcão; repõe ingredientes no fornecedor."
	_atualizar_receita()

func _process(_delta: float) -> void:
	var pocao_texto := "Nenhuma"
	var quantidade := 0
	if jogador.pocao_ativa != null:
		pocao_texto = jogador.pocao_ativa.nome_do_item
		quantidade = InventoryManager.obter_quantidade(jogador.pocao_ativa.id)

	var pedido_texto := "A aguardar cliente..."
	var cliente := balcao.obter_cliente_atual()
	if cliente != null and cliente.item_desejado != null:
		pedido_texto = "Pedido: %s | Paciência: %ds" % [
			cliente.item_desejado.nome_do_item,
			ceili(cliente.timer_paciencia.time_left),
		]
	elif cliente_atual != null and is_instance_valid(cliente_atual):
		pedido_texto = "Cliente a sair..." if cliente_atual.estado == ClienteNPC.Estado.SAINDO else "Cliente a caminho..."

	estado_padrao = "ESCUDOS %d  |  %s x%d\n%s" % [
		jogador.escudos,
		pocao_texto,
		quantidade,
		pedido_texto,
	]
	if temporizador_feedback.is_stopped():
		estado_label.text = estado_padrao
	inventario_label.text = _resumo_inventario()
	var ingrediente := fornecedor.obter_ingrediente_selecionado()
	if ingrediente != null:
		fornecedor_label.text = "Fornecedor (F/E): %s x%d — %d escudos" % [
			ingrediente.nome_do_item,
			InventoryManager.obter_quantidade(ingrediente.id),
			fornecedor.custo_por_ingrediente,
		]

func _inicializar_inventario() -> void:
	if not InventoryManager.inventario.is_empty():
		return
	for ingrediente in INGREDIENTES_INICIAIS:
		InventoryManager.adicionar_item(ingrediente.id, 4)
	for pocao in POCOES:
		InventoryManager.adicionar_item(pocao.id, 1)

func _resumo_inventario() -> String:
	var linhas: PackedStringArray = ["POÇÕES"]
	var nomes_curto: Array[String] = ["Vento", "Cura", "Mente", "Escudo"]
	for indice in range(POCOES.size()):
		var pocao: ItemData = POCOES[indice]
		linhas.append("%s x%d" % [nomes_curto[indice], InventoryManager.obter_quantidade(pocao.id)])
	return "  |  ".join(linhas)

func _atualizar_receita() -> void:
	receita_label.text = "Receita (Tab): " + caldeirao.obter_resumo_receita()

func _mostrar_feedback(mensagem: String) -> void:
	estado_label.text = mensagem
	temporizador_feedback.start(2.5)

func _ao_alterar_receita(_receita: PotionRecipeData) -> void:
	_atualizar_receita()

func _criar_cliente() -> void:
	if cliente_atual != null and is_instance_valid(cliente_atual):
		return

	var pocoes_com_stock: Array[ItemData] = []
	for pocao in POCOES:
		if InventoryManager.obter_quantidade(pocao.id) > 0:
			pocoes_com_stock.append(pocao)
	if pocoes_com_stock.is_empty():
		temporizador_cliente.start(2.0)
		_mostrar_feedback("Sem stock: prepara poções no caldeirão.")
		return

	cliente_atual = CENA_CLIENTE.instantiate() as ClienteNPC
	cliente_atual.itens_possiveis = pocoes_com_stock
	cliente_atual.ponto_entrada = Vector2(600.0, 300.0)
	cliente_atual.ponto_espera = Vector2(330.0, 300.0)
	cliente_atual.ponto_saida = Vector2(600.0, 345.0)
	cliente_atual.tree_exited.connect(_ao_cliente_sair)
	cliente_atual.venda_fracassada.connect(_ao_cliente_desistir)
	add_child(cliente_atual)

func _ao_cliente_desistir(_pocao: ItemData) -> void:
	_mostrar_feedback("O cliente perdeu a paciência. Mantém a loja abastecida.")

func _ao_cliente_sair() -> void:
	cliente_atual = null
	if temporizador_cliente.is_inside_tree():
		temporizador_cliente.start(1.5)
