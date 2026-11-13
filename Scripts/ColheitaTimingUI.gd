class_name ColheitaTimingUI extends CanvasLayer

signal colheita_concluida(sucesso_perfeito: bool)

@onready var painel: PanelContainer = $Painel
@onready var barra_fundo: ColorRect = $Painel/VBox/BarraContainer/BarraFundo
@onready var zona_verde: ColorRect = $Painel/VBox/BarraContainer/ZonaVerde
@onready var ponteiro: ColorRect = $Painel/VBox/BarraContainer/Ponteiro
@onready var feedback_label: Label = $Painel/VBox/FeedbackLabel
@onready var item_nome_label: Label = $Painel/VBox/ItemNomeLabel
@onready var botao_colher: Button = $Painel/VBox/BotaoColher

var _ativo: bool = false
var _tempo: float = 0.0
var _velocidade: float = 4.8
var _parado: bool = false
var _nome_erva: String = "Erva Rara"

# Dimensões da barra: largura 240px
const LARGURA_BARRA: float = 240.0
const ZONA_VERDE_INICIO: float = 95.0
const ZONA_VERDE_FIM: float = 145.0

func _ready() -> void:
	visible = false
	if botao_colher != null:
		botao_colher.focus_mode = Control.FOCUS_NONE
		botao_colher.pressed.connect(_tentar_colheita)

func iniciar(nome_erva: String) -> void:
	_nome_erva = nome_erva
	if item_nome_label != null:
		item_nome_label.text = "COLHEITA DELICADA · %s" % nome_erva.to_upper()
	if feedback_label != null:
		feedback_label.text = "Para o ponteiro na ZONA DOURADA!"
		feedback_label.modulate = Color.WHITE
	_parado = false
	_ativo = true
	_tempo = randf() * PI
	visible = true

func _process(delta: float) -> void:
	if not _ativo or _parado:
		return
		
	_tempo += delta * _velocidade
	# Onda senoidal normalizada de 0.0 a 1.0
	var pos_norm: float = (sin(_tempo) + 1.0) / 2.0
	var px: float = pos_norm * (LARGURA_BARRA - ponteiro.size.x)
	ponteiro.position.x = px

func _unhandled_input(event: InputEvent) -> void:
	if not _ativo or _parado:
		return
	if event.is_action_pressed("ui_accept") or event.is_action_pressed("interact") or (event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT):
		get_viewport().set_input_as_handled()
		_tentar_colheita()

func _tentar_colheita() -> void:
	if _parado:
		return
	_parado = true
	
	var pos_centro_ponteiro := ponteiro.position.x + (ponteiro.size.x / 2.0)
	var perfeito := (pos_centro_ponteiro >= ZONA_VERDE_INICIO and pos_centro_ponteiro <= ZONA_VERDE_FIM)
	
	if perfeito:
		AudioManager.tocar_sfx("colheita_perfeita")
		feedback_label.text = "✨ COLHEITA IMPECÁVEL! (Qualidade Ouro)"
		feedback_label.modulate = Color(1.0, 0.9, 0.25)
		ponteiro.color = Color(1.0, 0.95, 0.3)
	else:
		AudioManager.tocar_sfx("colheita_falha")
		feedback_label.text = "🍃 Colheita comum (Erva normal)"
		feedback_label.modulate = Color(0.85, 0.85, 0.85)
		ponteiro.color = Color(0.9, 0.3, 0.3)
		
	var tw := create_tween()
	tw.tween_interval(0.7)
	tw.finished.connect(func():
		_ativo = false
		visible = false
		colheita_concluida.emit(perfeito)
	)

