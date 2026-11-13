class_name MinaCarrinho extends Control

const DUNGEON_SCENE: String = "res://Cenas/Dungeon.tscn"

const DURACAO_TOTAL: float = 35.0
const VELOCIDADE_TRILHO: float = 230.0
const ALTURA_TRILHO: float = 240.0
const GRAVIDADE: float = 1100.0
const FORCA_PULO: float = -420.0

@onready var carrinho: Control = $Pista/Carrinho
@onready var carrinho_corpo: ColorRect = $Pista/Carrinho/Corpo
@onready var boneco_cabeca: ColorRect = $Pista/Carrinho/CabecaMarquinhos
@onready var faíscas_trilho: CPUParticles2D = $Pista/Carrinho/FaiscasTrilho
@onready var obstaculos_container: Control = $Pista/Obstaculos
@onready var cristais_container: Control = $Pista/Cristais
@onready var trilhos_container: Control = $Pista/Trilhos
@onready var progresso_barra: ProgressBar = $HUD/Topo/HBox/ProgressoBarra
@onready var vidas_label: Label = $HUD/Topo/HBox/VidasLabel
@onready var cristais_label: Label = $HUD/Topo/HBox/CristaisLabel
@onready var timer_label: Label = $HUD/Topo/HBox/TimerLabel
@onready var painel_fim: PanelContainer = $PainelFim
@onready var fim_resumo: Label = $PainelFim/VBox/ResumoLabel
@onready var botao_sair: Button = $PainelFim/VBox/BotaoSair
var camera_shake_offset: Vector2 = Vector2.ZERO

var _tex_carrinho_run: Texture2D = preload("res://Assets/Environment/props/mina_carrinho/carrinho_run.png")
var _tex_carrinho_jump: Texture2D = preload("res://Assets/Environment/props/mina_carrinho/carrinho_jump.png")
var _tex_carrinho_duck: Texture2D = preload("res://Assets/Environment/props/mina_carrinho/carrinho_duck.png")
var _tex_estalactite: Texture2D = preload("res://Assets/Environment/props/mina_carrinho/estalactite.png")
var _tex_trilho_quebrado: Texture2D = preload("res://Assets/Environment/props/mina_carrinho/trilho_quebrado.png")
var _sprite_carrinho: TextureRect

var tempo_decorrido: float = 0.0
var vidas: int = 3
var cristais_coletados: int = 0
var ouro_coletado: int = 0
var jogo_ativo: bool = true

var vel_y: float = 0.0
var esta_no_chao: bool = true
var esta_abaixado: bool = false
var proximo_spawn_obstaculo: float = 2.0
var proximo_spawn_cristal: float = 1.0
var invulneravel_tempo: float = 0.0

func _ready() -> void:
	painel_fim.visible = false
	botao_sair.pressed.connect(_voltar_dungeon)
	AudioManager.tocar_musica_area("carrinho", true)
	carrinho_corpo.visible = false
	boneco_cabeca.visible = false
	_sprite_carrinho = TextureRect.new()
	_sprite_carrinho.texture = _tex_carrinho_run
	_sprite_carrinho.size = Vector2(64, 48)
	_sprite_carrinho.position = Vector2(-8, -16)
	_sprite_carrinho.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	carrinho.add_child(_sprite_carrinho)
	_gerar_trilhos_iniciais()

func _gerar_trilhos_iniciais() -> void:
	for i in range(18):
		var t := ColorRect.new()
		t.size = Vector2(40, 10)
		t.position = Vector2(i * 40, ALTURA_TRILHO + 30)
		t.color = Color("5c4033")
		trilhos_container.add_child(t)

func _process(delta: float) -> void:
	if not jogo_ativo:
		return
		
	tempo_decorrido += delta
	progresso_barra.value = (tempo_decorrido / DURACAO_TOTAL) * 100.0
	timer_label.text = "⏱️ %ds" % ceili(DURACAO_TOTAL - tempo_decorrido)
	
	if invulneravel_tempo > 0.0:
		invulneravel_tempo -= delta
		carrinho.modulate.a = 0.5 if fmod(tempo_decorrido * 14.0, 1.0) > 0.5 else 1.0
	else:
		carrinho.modulate.a = 1.0
		
	_processar_fisica_carrinho(delta)
	_processar_trilhos(delta)
	_processar_obstaculos_e_cristais(delta)
	_verificar_colisoes()
	
	if tempo_decorrido >= DURACAO_TOTAL:
		_finalizar_corrida(true)

func _processar_fisica_carrinho(delta: float) -> void:
	# Abaixar
	if Input.is_action_pressed("ui_down") or Input.is_action_pressed("mover_baixo"):
		esta_abaixado = true
		boneco_cabeca.position.y = 8.0 # abaixa a cabeça dentro do carrinho
		carrinho_corpo.size.y = 16.0
	else:
		esta_abaixado = false
		boneco_cabeca.position.y = -8.0
		carrinho_corpo.size.y = 22.0

	# Pulo
	if (Input.is_action_just_pressed("ui_up") or Input.is_action_just_pressed("ui_accept") or Input.is_action_just_pressed("mover_cima")) and esta_no_chao:
		vel_y = FORCA_PULO
		esta_no_chao = false
		faíscas_trilho.emitting = false
		AudioManager.tocar_sfx("lutador_pulo")

	if not esta_no_chao:
		vel_y += GRAVIDADE * delta
		carrinho.position.y += vel_y * delta
		if carrinho.position.y >= ALTURA_TRILHO:
			carrinho.position.y = ALTURA_TRILHO
			vel_y = 0.0
			esta_no_chao = true
			faíscas_trilho.emitting = true
	else:
		carrinho.position.y = ALTURA_TRILHO

	if _sprite_carrinho != null:
		if not esta_no_chao:
			_sprite_carrinho.texture = _tex_carrinho_jump
		elif esta_abaixado:
			_sprite_carrinho.texture = _tex_carrinho_duck
		else:
			_sprite_carrinho.texture = _tex_carrinho_run

func _processar_trilhos(delta: float) -> void:
	for t in trilhos_container.get_children():
		var r := t as Control
		r.position.x -= VELOCIDADE_TRILHO * delta
		if r.position.x < -50.0:
			r.position.x += 18 * 40.0

func _processar_obstaculos_e_cristais(delta: float) -> void:
	# Mover obstáculos existentes
	for obs in obstaculos_container.get_children():
		var o := obs as Control
		o.position.x -= VELOCIDADE_TRILHO * delta
		if o.position.x < -60.0:
			o.queue_free()

	# Mover cristais existentes
	for cr in cristais_container.get_children():
		var c := cr as Control
		c.position.x -= VELOCIDADE_TRILHO * delta
		var base_y: float = float(c.get_meta("base_y", c.position.y))
		c.position.y = base_y + sin(tempo_decorrido * 6.0 + c.position.x * 0.04) * 3.5
		if c.position.x < -40.0:
			c.queue_free()

	# Gerador procedural de obstáculos
	proximo_spawn_obstaculo -= delta
	if proximo_spawn_obstaculo <= 0.0:
		proximo_spawn_obstaculo = randf_range(1.6, 2.6)
		var tipo_obs := randi() % 2 # 0: buraco no chão (exige pulo), 1: estalactite alta (exige abaixar)
		_criar_obstaculo(tipo_obs)

	# Gerador procedural de cristais
	proximo_spawn_cristal -= delta
	if proximo_spawn_cristal <= 0.0:
		proximo_spawn_cristal = randf_range(0.9, 1.8)
		_criar_cristal()

func _criar_obstaculo(tipo: int) -> void:
	var obs := Control.new()
	obs.position.x = 680.0
	
	if tipo == 0:
		# Trilho quebrado / buraco no chão (pular!)
		obs.position.y = ALTURA_TRILHO + 4.0
		obs.set_meta("tipo", "chao")
		var tr := TextureRect.new()
		tr.texture = _tex_trilho_quebrado
		tr.size = Vector2(64, 32)
		tr.position = Vector2(-12, 0)
		tr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		obs.add_child(tr)
	else:
		# Estalactite / rocha no teto (abaixar!)
		obs.position.y = ALTURA_TRILHO - 28.0
		obs.set_meta("tipo", "teto")
		var tr := TextureRect.new()
		tr.texture = _tex_estalactite
		tr.size = Vector2(36, 64)
		tr.position = Vector2(-4, -12)
		tr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		obs.add_child(tr)
		
	obstaculos_container.add_child(obs)

func _criar_cristal() -> void:
	var cr := Control.new()
	cr.position.x = 680.0
	# Alguns no chão, outros no ar para pular
	var no_ar := (randf() < 0.45)
	cr.position.y = (ALTURA_TRILHO - 35.0) if no_ar else (ALTURA_TRILHO + 4.0)
	cr.set_meta("base_y", cr.position.y)
	
	var label := Label.new()
	label.text = "💎" if randf() < 0.6 else "🪙"
	cr.set_meta("tipo", label.text)
	cr.add_child(label)
	cristais_container.add_child(cr)

func _verificar_colisoes() -> void:
	var pos_carrinho := carrinho.position.x
	
	# Colisão com cristais
	for cr in cristais_container.get_children():
		var c := cr as Control
		if abs(c.position.x - pos_carrinho) < 24.0 and abs(c.position.y - carrinho.position.y) < 32.0:
			var tipo_item: String = str(c.get_meta("tipo", "💎"))
			if tipo_item == "💎":
				cristais_coletados += 1
				AudioManager.tocar_sfx("cristal_coleta")
			else:
				ouro_coletado += 15
				AudioManager.tocar_sfx("moedas")
			_atualizar_hud()
			c.queue_free()

	# Colisão com obstáculos
	if invulneravel_tempo > 0.0:
		return
		
	for obs in obstaculos_container.get_children():
		var o := obs as Control
		if abs(o.position.x - pos_carrinho) < 22.0:
			var tipo_obs: String = str(o.get_meta("tipo", "chao"))
			var bateu: bool = false
			
			if tipo_obs == "chao" and esta_no_chao:
				# Bateu na pedra por não pular
				bateu = true
			elif tipo_obs == "teto" and not esta_abaixado:
				# Bateu a cabeça por não abaixar
				bateu = true
				
			if bateu:
				_tomar_dano()
				o.queue_free()
				break

func _tomar_dano() -> void:
	vidas -= 1
	invulneravel_tempo = 1.4
	AudioManager.tocar_sfx("impacto_macico_pedra")
	_atualizar_hud()
	
	# Efeito de tremor e perda de cristal
	cristais_coletados = maxi(0, cristais_coletados - 1)
	
	if vidas <= 0:
		_finalizar_corrida(false)

func _atualizar_hud() -> void:
	var coracoes := ""
	for i in range(vidas):
		coracoes += "❤️ "
	for i in range(3 - vidas):
		coracoes += "🖤 "
	vidas_label.text = coracoes
	cristais_label.text = "💎 Cristais: %d | 🪙 Ouro: +%d" % [cristais_coletados, ouro_coletado]

func _finalizar_corrida(chegou_ao_fim: bool) -> void:
	if not jogo_ativo:
		return
	jogo_ativo = false
	faíscas_trilho.emitting = false
	
	# Guardar recursos no InventoryManager
	InventoryManager.escudos += ouro_coletado
	if cristais_coletados > 0:
		InventoryManager.adicionar_item_ouro("calcedonia_fina", cristais_coletados)
		
	var titulo := "🏆 CHEGADA À GRUTA DOS CRISTAIS!" if chegou_ao_fim else "💥 O CARRINHO DERRAPOU E PAROU!"
	var resumo := "%s\n\n" % titulo
	resumo += "✦ Cristais de Calcedónia [OURO]: ×%d\n" % cristais_coletados
	resumo += "✦ Ouro Recolhido nos Trilhos: +%d escudos\n" % ouro_coletado
	if chegou_ao_fim:
		resumo += "\n✨ Bónus de Percurso Completo Concedido!"
	fim_resumo.text = resumo
	painel_fim.visible = true
	AudioManager.tocar_sfx("fanfarra_vitoria" if chegou_ao_fim else "colheita_falha")

func _voltar_dungeon() -> void:
	SceneRouter.ir_para(DUNGEON_SCENE, Vector2(320, 280))

