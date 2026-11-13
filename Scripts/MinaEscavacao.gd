class_name MinaEscavacao extends Control

const DUNGEON_SCENE: String = "res://Cenas/Dungeon.tscn"

enum TipoBloco {
	VAZIO,
	TERRA,              # 1 golpe
	GRANITO,            # 2 golpes
	VEIO_OURO,          # 1 golpe -> +25 escudos
	CRISTAL_CALCEDONIA, # 2 golpes -> calcedonia_fina (Ouro)
	BASALTO_FERVENTE    # 2 golpes -> basalto_fervente (Ouro)
}

const COLS: int = 8
const ROWS: int = 6
const CELL_SIZE: float = 38.0

@onready var grid_container: Control = $Centro/GridArea
@onready var picareta_label: Label = $HUD/Topo/HBox/PicaretaLabel
@onready var recompensa_label: Label = $HUD/Topo/HBox/RecompensaLabel
@onready var instrucao_label: Label = $HUD/InstrucaoLabel
@onready var botao_sair: Button = $HUD/Topo/HBox/BotaoSair
@onready var painel_vitoria: PanelContainer = $PainelVitoria
@onready var vitoria_resumo: Label = $PainelVitoria/VBox/ResumoLabel
@onready var botao_confirmar_vitoria: Button = $PainelVitoria/VBox/BotaoOk
@onready var faíscas: CPUParticles2D = $Faiscas
@onready var player_token: ColorRect = $Centro/GridArea/PlayerToken

var _tex_terra: Texture2D = preload("res://Assets/Environment/props/mina_blocos/bloco_terra.png")
var _tex_granito: Texture2D = preload("res://Assets/Environment/props/mina_blocos/bloco_granito.png")
var _tex_ouro: Texture2D = preload("res://Assets/Environment/props/mina_blocos/bloco_veio_ouro.png")
var _tex_calcedonia: Texture2D = preload("res://Assets/Environment/props/mina_blocos/bloco_calcedonia.png")
var _tex_basalto: Texture2D = preload("res://Assets/Environment/props/mina_blocos/bloco_basalto_fervente.png")

var durabilidade_picareta: int = 16
var max_durabilidade: int = 16
var grid: Array[Array] = []
var vida_blocos: Array[Array] = []
var player_grid: Vector2i = Vector2i(3, 0)
var ouro_ganho: int = 0
var itens_ganhos: Dictionary = {}
var jogo_finalizado: bool = false

func _ready() -> void:
	painel_vitoria.visible = false
	botao_sair.pressed.connect(_finalizar_minigame)
	botao_confirmar_vitoria.pressed.connect(_voltar_para_dungeon)
	AudioManager.tocar_musica_area("mina", true)
	_gerar_mapa()
	_desenhar_grid()
	_atualizar_hud()

func _gerar_mapa() -> void:
	grid.clear()
	vida_blocos.clear()
	
	for y in range(ROWS):
		var linha: Array = []
		var linha_vida: Array = []
		for x in range(COLS):
			if y == 0:
				# Linha de entrada sempre vazia
				linha.append(TipoBloco.VAZIO)
				linha_vida.append(0)
			else:
				var sorteio := randf()
				var tipo := TipoBloco.TERRA
				var vida := 1
				
				if sorteio < 0.12:
					tipo = TipoBloco.CRISTAL_CALCEDONIA
					vida = 2
				elif sorteio < 0.22:
					tipo = TipoBloco.VEIO_OURO
					vida = 1
				elif sorteio < 0.30:
					tipo = TipoBloco.BASALTO_FERVENTE
					vida = 2
				elif sorteio < 0.65:
					tipo = TipoBloco.GRANITO
					vida = 2
				else:
					tipo = TipoBloco.TERRA
					vida = 1
					
				linha.append(tipo)
				linha_vida.append(vida)
		grid.append(linha)
		vida_blocos.append(linha_vida)
		
	# Posição inicial do jogador
	grid[0][3] = TipoBloco.VAZIO
	player_grid = Vector2i(3, 0)

func _desenhar_grid() -> void:
	for c in grid_container.get_children():
		if c != player_token:
			c.queue_free()
			
	for y in range(ROWS):
		for x in range(COLS):
			var tipo: int = grid[y][x]
			if tipo == TipoBloco.VAZIO:
				continue
				
			var b := Button.new()
			b.custom_minimum_size = Vector2(CELL_SIZE - 2, CELL_SIZE - 2)
			b.position = Vector2(x * CELL_SIZE, y * CELL_SIZE)
			b.focus_mode = Control.FOCUS_NONE
			
			var tex: Texture2D = null
			match tipo:
				TipoBloco.TERRA:
					tex = _tex_terra
				TipoBloco.GRANITO:
					tex = _tex_granito
				TipoBloco.VEIO_OURO:
					tex = _tex_ouro
				TipoBloco.CRISTAL_CALCEDONIA:
					tex = _tex_calcedonia
				TipoBloco.BASALTO_FERVENTE:
					tex = _tex_basalto
					
			b.icon = tex
			b.expand_icon = true
			if tipo == TipoBloco.GRANITO and vida_blocos[y][x] == 1:
				b.modulate = Color(0.7, 0.7, 0.7)
			else:
				b.modulate = Color.WHITE
			b.text = ""
			b.pressed.connect(_ao_clicar_bloco.bind(Vector2i(x, y)))
			grid_container.add_child(b)
			
	player_token.position = Vector2(player_grid.x * CELL_SIZE + 4, player_grid.y * CELL_SIZE + 4)
	player_token.size = Vector2(CELL_SIZE - 8, CELL_SIZE - 8)

func _unhandled_input(event: InputEvent) -> void:
	if jogo_finalizado:
		return
	if event.is_action_pressed("ui_left") or event.is_action_pressed("mover_esquerda"):
		_tentar_mover_ou_minerar(Vector2i(-1, 0))
	elif event.is_action_pressed("ui_right") or event.is_action_pressed("mover_direita"):
		_tentar_mover_ou_minerar(Vector2i(1, 0))
	elif event.is_action_pressed("ui_up") or event.is_action_pressed("mover_cima"):
		_tentar_mover_ou_minerar(Vector2i(0, -1))
	elif event.is_action_pressed("ui_down") or event.is_action_pressed("mover_baixo"):
		_tentar_mover_ou_minerar(Vector2i(0, 1))

func _ao_clicar_bloco(coord: Vector2i) -> void:
	if jogo_finalizado:
		return
	# Se for adjacente ao jogador
	var delta := coord - player_grid
	if abs(delta.x) + abs(delta.y) == 1:
		_minerar_bloco(coord)

func _tentar_mover_ou_minerar(dir: Vector2i) -> void:
	var destino := player_grid + dir
	if destino.x < 0 or destino.x >= COLS or destino.y < 0 or destino.y >= ROWS:
		return
		
	if grid[destino.y][destino.x] == TipoBloco.VAZIO:
		player_grid = destino
		_desenhar_grid()
	else:
		_minerar_bloco(destino)

func _minerar_bloco(coord: Vector2i) -> void:
	if durabilidade_picareta <= 0 or jogo_finalizado:
		return
		
	durabilidade_picareta -= 1
	vida_blocos[coord.y][coord.x] -= 1
	AudioManager.tocar_sfx("picareta")
	
	# Efeito de faíscas
	faíscas.position = grid_container.global_position + Vector2(coord.x * CELL_SIZE + CELL_SIZE / 2.0, coord.y * CELL_SIZE + CELL_SIZE / 2.0)
	faíscas.emitting = true
	
	if vida_blocos[coord.y][coord.x] <= 0:
		var tipo: int = grid[coord.y][coord.x]
		_coletar_recompensa_bloco(tipo)
		grid[coord.y][coord.x] = TipoBloco.VAZIO
		player_grid = coord # avança para o bloco escavado
		
	_desenhar_grid()
	_atualizar_hud()
	
	if durabilidade_picareta <= 0:
		_finalizar_minigame()

func _coletar_recompensa_bloco(tipo: int) -> void:
	match tipo:
		TipoBloco.VEIO_OURO:
			ouro_ganho += 30
			_adicionar_item_ganho("pepita_de_ouro", 1)
			AudioManager.tocar_sfx("moedas")
		TipoBloco.CRISTAL_CALCEDONIA:
			ouro_ganho += 15
			_adicionar_item_ganho("calcedonia_fina", 1)
			AudioManager.tocar_sfx("cristal_coleta")
		TipoBloco.BASALTO_FERVENTE:
			ouro_ganho += 20
			_adicionar_item_ganho("basalto_fervente", 1)
			AudioManager.tocar_sfx("cristal_coleta")
		TipoBloco.TERRA:
			ouro_ganho += 2
		TipoBloco.GRANITO:
			ouro_ganho += 5
			AudioManager.tocar_sfx_volume("impacto_macico_pedra", -6.0, 0.1)

func _adicionar_item_ganho(item_id: String, qtd: int) -> void:
	itens_ganhos[item_id] = int(itens_ganhos.get(item_id, 0)) + qtd

func _atualizar_hud() -> void:
	picareta_label.text = "🔨 PICARETA: %d/%d" % [durabilidade_picareta, max_durabilidade]
	var pct := float(durabilidade_picareta) / float(max_durabilidade)
	if pct > 0.5:
		picareta_label.modulate = Color.WHITE
	elif pct > 0.2:
		picareta_label.modulate = Color(1.0, 0.8, 0.2)
	else:
		picareta_label.modulate = Color(1.0, 0.3, 0.3)
		
	var itens_txt := ""
	for k in itens_ganhos.keys():
		itens_txt += "%s ×%d  " % [k.replace("_", " ").capitalize(), itens_ganhos[k]]
	recompensa_label.text = "💰 Ouro: +%d | Minérios: %s" % [ouro_ganho, itens_txt if not itens_txt.is_empty() else "Nenhum"]

func _finalizar_minigame() -> void:
	if jogo_finalizado:
		return
	jogo_finalizado = true
	
	# Depositar no InventoryManager com qualidade Ouro para cristais raros
	InventoryManager.escudos += ouro_ganho
	for item_id: String in itens_ganhos.keys():
		var qtd: int = itens_ganhos[item_id]
		# Cristais nobres vão como ouro
		if item_id in ["calcedonia_fina", "basalto_fervente", "pepita_de_ouro"]:
			InventoryManager.adicionar_item_ouro(item_id, qtd)
		else:
			InventoryManager.adicionar_item(item_id, qtd)
			
	var texto := "⛏️ A PICARETA QUEBROU!\n\n" if durabilidade_picareta <= 0 else "⛏️ ESCAVAÇÃO CONCLUÍDA!\n\n"
	texto += "✦ Ouro Escavado: +%d escudos\n" % ouro_ganho
	for k in itens_ganhos.keys():
		texto += "✦ %s ×%d (QUALIDADE PURA ✨)\n" % [k.replace("_", " ").capitalize(), itens_ganhos[k]]
	vitoria_resumo.text = texto
	painel_vitoria.visible = true
	AudioManager.tocar_sfx("fanfarra_vitoria")

func _voltar_para_dungeon() -> void:
	SceneRouter.ir_para(DUNGEON_SCENE, Vector2(320, 280))
