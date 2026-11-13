extends Node2D

const CHAMPION_SCRIPT: Script = preload("res://Scripts/TongobrigaChampion.gd")
const STAGE_DIRECTOR_SCRIPT: Script = preload("res://Scripts/TongobrigaStageDirector.gd")
const PLAZA_SCENE: String = "res://Cenas/PracaCentral.tscn"

const CHAMPIONS: Array[Dictionary] = [
	{
		"name": "Viriato",
		"archetype": "Caudilho Lusitano",
		"origin": "Montes Hermínios & Castros",
		"class_id": "warrior",
		"voice_id": "vox_viriato",
		"hit_sfx": "corte_lamina",
		"special_sfx": "especial_disparo",
		"projectile": "falcata",
		"special": "Fúria de Hermínio (Falcata Flamejante)",
		"description": "Líder lendário da resistência lusitana. Domina a meia distância com cortes velozes da sua falcata ibérica curva e broquel caetra de bronze.",
		"health": 128,
		"strength": 15,
		"speed": 194.0,
		"defense": 0.13,
		"color": Color(0.65, 0.23, 0.20),
		"trim": Color(0.90, 0.68, 0.29),
		"portrait": "res://Assets/Characters/Tongobriga/warrior/portrait.png",
	},
	{
		"name": "Nábia",
		"archetype": "Caçadora das Águas",
		"origin": "Margens Sagradas do Tâmega",
		"class_id": "archer",
		"voice_id": "vox_nabia",
		"hit_sfx": "corte_lamina",
		"special_sfx": "especial_disparo",
		"projectile": "flecha",
		"special": "Torrente Sagrada do Tâmega",
		"description": "Guerreira ágil consagrada à deusa das águas. Combina acrobacias velozes com adagas gêmeas e disparos torrenciais à distância.",
		"health": 114,
		"strength": 14,
		"speed": 224.0,
		"defense": 0.06,
		"color": Color(0.20, 0.56, 0.45),
		"trim": Color(0.55, 0.92, 0.88),
		"portrait": "res://Assets/Characters/Tongobriga/archer/portrait.png",
	},
	{
		"name": "Endovélico",
		"archetype": "Arquidruida Ctónico",
		"origin": "Santuário Sagrado do Freixo",
		"class_id": "mage",
		"voice_id": "vox_endovelico",
		"hit_sfx": "soco",
		"special_sfx": "especial_disparo",
		"projectile": "fogo",
		"special": "Ira Ctónica da Pedra Formosa",
		"description": "Místico ancestral coroado de carvalho. Canaliza chamas ctónicas e poder telúrico através do seu cajado-braseiro para controlar o espaço.",
		"health": 118,
		"strength": 16,
		"speed": 180.0,
		"defense": 0.08,
		"color": Color(0.46, 0.24, 0.56),
		"trim": Color(0.92, 0.74, 0.36),
		"portrait": "res://Assets/Characters/Tongobriga/mage/portrait.png",
	},
	{
		"name": "Aunia",
		"archetype": "Guardiã da Pedra Formosa",
		"origin": "Balneário Castrejo de Tongóbriga",
		"class_id": "healer",
		"voice_id": "vox_aunia",
		"hit_sfx": "impacto_macico_pedra",
		"special_sfx": "impacto_macico_pedra",
		"projectile": "escudo",
		"special": "Nova Solar dos Trísqueles",
		"description": "Defensora juramentada do monólito sagrado. Escudo gravado com trísqueles celtas intransponível e explosão solar de curto alcance.",
		"health": 132,
		"strength": 14,
		"speed": 176.0,
		"defense": 0.20,
		"color": Color(0.82, 0.62, 0.24),
		"trim": Color(0.96, 0.88, 0.65),
		"portrait": "res://Assets/Characters/Tongobriga/healer/portrait.png",
	},
	{
		"name": "Breno",
		"archetype": "Campeão Celta da Gália",
		"origin": "Tribos Gaulesas Transpirenaicas",
		"class_id": "breno",
		"voice_id": "vox_breno",
		"hit_sfx": "corte_lamina",
		"special_sfx": "carnyx_trombeta_gaulesa",
		"projectile": "carnyx",
		"special": "Rugido do Carnyx (Onda Sónica)",
		"description": "Veterano gaulês de bigode loiro, torque de ouro e pinturas azuis de woad. Empunha espadão de ferro e sopra a feroz trombeta de javali Carnyx!",
		"health": 132,
		"strength": 16,
		"speed": 188.0,
		"defense": 0.15,
		"color": Color(0.22, 0.48, 0.78),
		"trim": Color(0.94, 0.78, 0.28),
		"portrait": "res://Assets/Characters/Tongobriga/breno/portrait.png",
	},
	{
		"name": "Brácaro",
		"archetype": "Colosso de Granito Celta",
		"origin": "Serra da Aboboreira",
		"class_id": "bracaro",
		"voice_id": "vox_bracaro",
		"hit_sfx": "impacto_macico_pedra",
		"special_sfx": "impacto_macico_pedra",
		"projectile": "sismo",
		"special": "Sismo da Citânia",
		"description": "Gigante galaico-lusitano com elmo celta de crista de javali e manoplas maciças de granito. Agarrões demolidores e ondas sísmicas.",
		"health": 140,
		"strength": 17,
		"speed": 166.0,
		"defense": 0.22,
		"color": Color(0.28, 0.46, 0.26),
		"trim": Color(0.76, 0.62, 0.32),
		"portrait": "res://Assets/Characters/Tongobriga/bracaro/portrait.png",
	},
	{
		"name": "Décimo Bruto",
		"archetype": "Centurião Gladiador",
		"origin": "Fórum Romano de Tongóbriga",
		"class_id": "decimo",
		"voice_id": "vox_decimo",
		"hit_sfx": "corte_lamina",
		"special_sfx": "especial_disparo",
		"projectile": "pilum",
		"special": "Pilum Fulminante de Júpiter",
		"description": "Centurião renegado que trocou as legiões pela glória da arena. O maior alcance de estocada normal graças à sua lança romana.",
		"health": 128,
		"strength": 16,
		"speed": 186.0,
		"defense": 0.14,
		"color": Color(0.72, 0.16, 0.16),
		"trim": Color(0.88, 0.72, 0.30),
		"portrait": "res://Assets/Characters/Tongobriga/decimo/portrait.png",
	},
	{
		"name": "Trebaruna",
		"archetype": "Loba das Sombras",
		"origin": "Serras Ocultas do Marão",
		"class_id": "trebaruna",
		"voice_id": "vox_trebaruna",
		"hit_sfx": "corte_lamina",
		"special_sfx": "especial_disparo",
		"projectile": "foices",
		"special": "Julgamento da Lua Negra",
		"description": "Sacerdotisa-caçadora envolta em manto de lobo. A mais veloz em investidas aéreas, retalhando a defesa rival com duas foices de prata.",
		"health": 112,
		"strength": 15,
		"speed": 228.0,
		"defense": 0.07,
		"color": Color(0.36, 0.20, 0.44),
		"trim": Color(0.82, 0.84, 0.92),
		"portrait": "res://Assets/Characters/Tongobriga/trebaruna/portrait.png",
	},
	{
		"name": "Klaudia, The Slav",
		"archetype": "Espadachim Eslava",
		"origin": "Terras Eslavas do Leste",
		"class_id": "klaudia",
		"voice_id": "vox_klaudia",
		"hit_sfx": "corte_lamina",
		"special_sfx": "trovao_eslavo_perun",
		"projectile": "perun",
		"special": "Dança da Szabla & Trovão de Perun",
		"description": "Viajante destemida em traje típico eslavo (vyshyvanka, gorset floral e colares korale). Une esgrima ágil de sabre curvo aos raios de Perun e gelo.",
		"health": 118,
		"strength": 15,
		"speed": 220.0,
		"defense": 0.10,
		"color": Color(0.80, 0.14, 0.20),
		"trim": Color(0.98, 0.84, 0.32),
		"portrait": "res://Assets/Characters/Tongobriga/klaudia/portrait.png",
		"is_hidden": true,
	},
	{
		"name": "Marco",
		"archetype": "Mestre Alquimista (Secreto)",
		"origin": "A Botica de Marco de Canaveses",
		"class_id": "marco",
		"voice_id": "vox_marco",
		"hit_sfx": "soco",
		"special_sfx": "frasco_alquimico_explosao",
		"projectile": "fogogrego",
		"special": "Fogo-Grego da Botica de Canaveses",
		"description": "O próprio protagonista da Loja do Alquimista! Desbloqueável ao vencer o Torneio. Combate arremessando reagentes voláteis esmeralda e carmesim.",
		"health": 124,
		"strength": 16,
		"speed": 206.0,
		"defense": 0.12,
		"color": Color(0.18, 0.52, 0.28),
		"trim": Color(0.94, 0.76, 0.30),
		"portrait": "res://Assets/Characters/Tongobriga/marco/portrait.png",
		"is_secret": true,
	},
]

# Cenário & Diretor de Arenas Vivas
@onready var cenario_sprite: Sprite2D = $Cenario
@onready var braseiro_esq: Node2D = $BraseiroEsquerdo
@onready var braseiro_dir: Node2D = $BraseiroDireito

# UI Nodes - Character Select
@onready var selecao_painel: PanelContainer = $UI/Selecao
@onready var grade_retratos: HBoxContainer = $UI/Selecao/Margem/Conteudo/GradeRetratos
@onready var retrato_grande: TextureRect = $UI/Selecao/Margem/Conteudo/Showcase/PainelRetratoGrande/RetratoGrande
@onready var nome_grande: Label = $UI/Selecao/Margem/Conteudo/Showcase/Bio/NomeGrande
@onready var arquetipo_label: Label = $UI/Selecao/Margem/Conteudo/Showcase/Bio/Arquetipo
@onready var origem_label: Label = $UI/Selecao/Margem/Conteudo/Showcase/Bio/Origem
@onready var especial_detalhe: Label = $UI/Selecao/Margem/Conteudo/Showcase/Bio/EspecialDetalhe
@onready var desc_label: Label = $UI/Selecao/Margem/Conteudo/Showcase/Bio/Descricao

@onready var barra_vida_stat: ProgressBar = $UI/Selecao/Margem/Conteudo/Showcase/Stats/BarraVida
@onready var barra_forca_stat: ProgressBar = $UI/Selecao/Margem/Conteudo/Showcase/Stats/BarraForca
@onready var barra_vel_stat: ProgressBar = $UI/Selecao/Margem/Conteudo/Showcase/Stats/BarraVel
@onready var barra_def_stat: ProgressBar = $UI/Selecao/Margem/Conteudo/Showcase/Stats/BarraDef

@onready var iniciar_botao: Button = $UI/Selecao/Margem/Conteudo/Botoes/Iniciar
@onready var sair_botao: Button = $UI/Selecao/Margem/Conteudo/Botoes/Sair

# UI Nodes - Arena Combat
@onready var arena_hud: Control = $UI/Arena
@onready var retrato_p1: TextureRect = $UI/Arena/TopBar/P1_Box/RetratoP1
@onready var nome_jogador: Label = $UI/Arena/TopBar/P1_Box/Info/LinhaNome/NomeP1
@onready var vida_dano_jogador: ProgressBar = $UI/Arena/TopBar/P1_Box/Info/BarraContainer/VidaDanoP1
@onready var vida_jogador: ProgressBar = $UI/Arena/TopBar/P1_Box/Info/BarraContainer/VidaP1
@onready var vitorias_p1_label: Label = $UI/Arena/TopBar/P1_Box/Info/LinhaNome/VitoriasP1

@onready var timer_label: Label = $UI/Arena/TopBar/TimerBox/VBox/TimerLabel
@onready var round_info_label: Label = $UI/Arena/TopBar/TimerBox/VBox/RoundInfoLabel

@onready var retrato_p2: TextureRect = $UI/Arena/TopBar/P2_Box/RetratoP2
@onready var nome_oponente: Label = $UI/Arena/TopBar/P2_Box/Info/LinhaNome/NomeP2
@onready var vida_dano_oponente: ProgressBar = $UI/Arena/TopBar/P2_Box/Info/BarraContainer/VidaDanoP2
@onready var vida_oponente: ProgressBar = $UI/Arena/TopBar/P2_Box/Info/BarraContainer/VidaP2
@onready var vitorias_p2_label: Label = $UI/Arena/TopBar/P2_Box/Info/LinhaNome/VitoriasP2

@onready var especial_jogador_barra: ProgressBar = $UI/Arena/BottomBar/EspecialP1
@onready var especial_oponente_barra: ProgressBar = $UI/Arena/BottomBar/EspecialP2
@onready var especial_label: Label = $UI/Arena/BottomBar/EspecialLabel
@onready var barra_container_p1: MarginContainer = $UI/Arena/TopBar/P1_Box/Info/BarraContainer
@onready var barra_container_p2: MarginContainer = $UI/Arena/TopBar/P2_Box/Info/BarraContainer

@onready var banner_arcade: Label = $UI/Arena/BannerArcade
@onready var combo_label: Label = $UI/Arena/ComboLabel
@onready var mensagem_label: Label = $UI/Arena/Mensagem
@onready var controlos_label: Label = $UI/Arena/Controlos
@onready var regressar_botao: Button = $UI/Arena/Regressar

var _stage_director: TongobrigaStageDirector = null
var _arena_escolhida: int = 0
var _botoes_arena: Array[Button] = []
var _dificuldade_ia: int = 0 # 0: Easy, 1: Intermediate, 2: Hard
var _botoes_dificuldade: Array[Button] = []
var _dificuldade_hint_label: Label = null

const DIFICULDADE_NOMES: Array[String] = [
	"🟢 EASY (FÁCIL)",
	"🟡 INTERMEDIATE",
	"🔴 HARD (DIFÍCIL)"
]

const DIFICULDADE_DESCRICOES: Array[String] = [
	"Acolhedor: dano 0.68x, vida 0.88x, bloqueio ~12%, pausas longas.",
	"Equilibrado: dano 0.90x, vida 1.0x, bloqueio ~30%, ritmo arcade.",
	"Intenso: dano 1.06x, vida 1.10x, bloqueio até 55% (sem leitura robótica)."
]

var _rng := RandomNumberGenerator.new()
var _escolhido: int = 0
var _treino_oponente_idx: int = 4 # Breno por defeito no treino
var _ordem_oponentes: Array[int] = []
var _luta_atual: int = 0
var _jogador: TongobrigaChampion
var _oponente: TongobrigaChampion

var _jogo_ativo: bool = false
var _lutadores_travados: bool = true
var _match_finalizado: bool = false
var _selecionando_personagem: bool = true

var _tempo_ronda: float = 99.0
var _ultimo_segundo_alerta: int = -1

# Sistema de Rounds - Melhor de Três (FT2: 2 Rounds para Vencer)
var _rounds_p1: int = 0
var _rounds_p2: int = 0
var _round_num: int = 1
const ROUNDS_PARA_VENCER: int = 2

# Sistema de Chaveamento do Torneio (Brackets)
var _bracket_quartas: Array[Dictionary] = []
var _bracket_semis: Array[Dictionary] = []
var _bracket_final: Dictionary = {}
var _bracket_boss: Dictionary = {}
var _bracket_etapa: int = 0 # 0: Quartas, 1: Semis, 2: Final Tongobriga, 3: Grande Final Marco
var _bracket_tela_ativa: bool = false
var _bracket_overlay: Control = null
var _modal_overlay: Control = null

var _ia_proximo_golpe: float = 0.0
var _bloqueio_ia: float = 0.0
var _ia_reacao_bloqueio: float = -1.0
var _ia_ataque_observado: bool = false
var _ia_bloqueio_agachado: bool = false
var _salto_pendente: bool = false
var _ataque_pendente: String = ""

var _combo_count: int = 0
var _combo_timer: float = 0.0
var _shake_timer: float = 0.0
var _shake_amount: float = 0.0

var _shake_hud_p1_timer: float = 0.0
var _shake_hud_p1_amount: float = 0.0
var _shake_hud_p2_timer: float = 0.0
var _shake_hud_p2_amount: float = 0.0
var _flash_p1_timer: float = 0.0
var _flash_p2_timer: float = 0.0
var _especial_estava_pronto: bool = false

var _botoes_elenco: Array[Button] = []
var _badges_cadeado: Array[Label] = []
var _tween_vida_p1: Tween
var _tween_vida_p2: Tween

var _modo_treino: bool = false
var _dummy_mode: int = 0 # 0: Parado, 1: Defesa Alta, 2: Defesa Baixa, 3: IA Combate
var _treino_regen_timer: float = 0.0
var _treino_botao: Button = null
var _debug_hud_label: Label = null

const DUMMY_NOMES: Array[String] = [
	"PARADO (NEUTRO)",
	"DEFESA ALTA (EM PÉ)",
	"DEFESA BAIXA (AGACHADO)",
	"IA DE COMBATE ATIVA"
]

func _ready() -> void:
	_rng.randomize()

	# Instanciar Diretor de Arenas Vivas (4 cenários + NPCs móveis de fundo + partículas)
	var sd_node := Node2D.new()
	sd_node.set_script(STAGE_DIRECTOR_SCRIPT)
	_stage_director = sd_node as TongobrigaStageDirector
	_stage_director.name = "StageDirector"
	add_child(_stage_director)
	move_child(_stage_director, 3)

	iniciar_botao.focus_mode = Control.FOCUS_NONE
	sair_botao.focus_mode = Control.FOCUS_NONE
	regressar_botao.focus_mode = Control.FOCUS_NONE

	iniciar_botao.custom_minimum_size = Vector2(225, 28)
	sair_botao.custom_minimum_size = Vector2(120, 28)

	# Botão de Laboratório / Modo Treino de Colisões antes de compilar
	_treino_botao = Button.new()
	_treino_botao.name = "TreinoBtn"
	_treino_botao.focus_mode = Control.FOCUS_NONE
	_treino_botao.custom_minimum_size = Vector2(195, 28)
	_treino_botao.text = tr("TONGO_BTN_TREINO")
	_treino_botao.pressed.connect(_iniciar_modo_treino)
	iniciar_botao.get_parent().add_child(_treino_botao)
	iniciar_botao.get_parent().move_child(_treino_botao, 1)
	sair_botao.text = tr("TONGO_BTN_VOLTAR")
	var tongo_titulo := get_node_or_null("UI/Selecao/Margem/Conteudo/Titulo") as Label
	if tongo_titulo != null:
		tongo_titulo.text = tr("TONGO_TITULO")
	if not CampaignManager.idioma_alterado.is_connected(_atualizar_idioma_tongobriga):
		CampaignManager.idioma_alterado.connect(_atualizar_idioma_tongobriga)

	# Construir Barra de Seleção das 4 Arenas Ilustradas abaixo da grade de retratos
	_construir_barra_arenas()

	# Painel de Telemetria de Caixas de Colisão [F2]
	_debug_hud_label = Label.new()
	_debug_hud_label.name = "DebugColisaoHUD"
	_debug_hud_label.position = Vector2(14.0, 56.0)
	_debug_hud_label.add_theme_font_size_override("font_size", 9)
	_debug_hud_label.add_theme_color_override("font_color", Color(0.55, 0.98, 1.0))
	_debug_hud_label.add_theme_color_override("font_outline_color", Color.BLACK)
	_debug_hud_label.add_theme_constant_override("outline_size", 2)
	_debug_hud_label.visible = TongobrigaChampion.debug_hitboxes
	arena_hud.add_child(_debug_hud_label)

	iniciar_botao.pressed.connect(_confirmar_selecao)
	sair_botao.pressed.connect(_sair_para_praca)
	regressar_botao.pressed.connect(_sair_para_praca)

	var cm_init := get_node_or_null("/root/CampaignManager")
	if cm_init != null and "dificuldade_ia" in cm_init:
		_dificuldade_ia = int(cm_init.dificuldade_ia)

	_construir_grade_selecao()
	selecionar_arena_inicial(0, false)

func _atualizar_idioma_tongobriga(_novo: String) -> void:
	if _treino_botao != null:
		_treino_botao.text = tr("TONGO_BTN_TREINO")
	if sair_botao != null:
		sair_botao.text = tr("TONGO_BTN_VOLTAR")
	var tongo_titulo := get_node_or_null("UI/Selecao/Margem/Conteudo/Titulo") as Label
	if tongo_titulo != null:
		tongo_titulo.text = tr("TONGO_TITULO")
	selecionar_dificuldade_ia(_dificuldade_ia, false)
	selecionar_campeao(0, false)

	if get_node_or_null("/root/AudioManager") != null:
		get_node("/root/AudioManager").tocar_bgm_id("select_tongobriga")

	arena_hud.visible = false
	selecao_painel.visible = true
	banner_arcade.visible = false
	combo_label.visible = false
	_selecionando_personagem = true

static func _carregar_retrato_seguro(caminho: String) -> Texture2D:
	return TongobrigaChampion._load_tex_safe(caminho)

func _marco_esta_desbloqueado() -> bool:
	var cm = get_node_or_null("/root/CampaignManager")
	if cm != null and "marco_lutador_desbloqueado" in cm:
		return bool(cm.marco_lutador_desbloqueado)
	return false

func _campeao_oculto(indice: int) -> bool:
	if indice < 0 or indice >= CHAMPIONS.size():
		return true
	return bool(CHAMPIONS[indice].get("is_hidden", false))

func _proximo_campeao_visivel(atual: int, passo: int) -> int:
	var n := CHAMPIONS.size()
	var idx := atual
	for _tentativa in range(n):
		idx = posmod(idx + passo, n)
		if not _campeao_oculto(idx):
			return idx
	return 0

func _campeao_bloqueado_no_torneio(indice: int) -> bool:
	if indice < 0 or indice >= CHAMPIONS.size():
		return false
	return bool(CHAMPIONS[indice].get("is_secret", false)) and not _marco_esta_desbloqueado()

func _construir_barra_arenas() -> void:
	var conteudo_vbox := grade_retratos.get_parent()
	var barra := HBoxContainer.new()
	barra.name = "BarraArenas"
	barra.alignment = BoxContainer.ALIGNMENT_CENTER
	barra.add_theme_constant_override("separation", 4)

	var lbl := Label.new()
	lbl.text = "🏛️ ARENA [1-4]:"
	lbl.add_theme_font_size_override("font_size", 8)
	lbl.add_theme_color_override("font_color", Color(0.95, 0.84, 0.45))
	barra.add_child(lbl)

	var nomes_curtos := ["1.Castro", "2.Termas", "3.Ponte", "4.Praça"]
	_botoes_arena.clear()
	for idx in range(nomes_curtos.size()):
		var b := Button.new()
		b.focus_mode = Control.FOCUS_NONE
		b.custom_minimum_size = Vector2(58.0, 20.0)
		b.add_theme_font_size_override("font_size", 8)
		b.text = nomes_curtos[idx]
		b.pressed.connect(selecionar_arena_inicial.bind(idx, true))
		barra.add_child(b)
		_botoes_arena.append(b)

	var sep := Label.new()
	sep.text = "  |  🎚️ IA [F1]:"
	sep.add_theme_font_size_override("font_size", 8)
	sep.add_theme_color_override("font_color", Color(0.65, 0.92, 1.0))
	barra.add_child(sep)

	var dif_curtos := ["🟢 Easy", "🟡 Interm.", "🔴 Hard"]
	_botoes_dificuldade.clear()
	for d_idx in range(dif_curtos.size()):
		var db := Button.new()
		db.focus_mode = Control.FOCUS_NONE
		db.custom_minimum_size = Vector2(64.0, 20.0)
		db.add_theme_font_size_override("font_size", 8)
		db.text = dif_curtos[d_idx]
		db.tooltip_text = "%s\n%s" % [DIFICULDADE_NOMES[d_idx], DIFICULDADE_DESCRICOES[d_idx]]
		db.pressed.connect(selecionar_dificuldade_ia.bind(d_idx, true))
		barra.add_child(db)
		_botoes_dificuldade.append(db)

	conteudo_vbox.add_child(barra)
	conteudo_vbox.move_child(barra, grade_retratos.get_index() + 1)

	_dificuldade_hint_label = Label.new()
	_dificuldade_hint_label.name = "DificuldadeHint"
	_dificuldade_hint_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_dificuldade_hint_label.add_theme_font_size_override("font_size", 8)
	_dificuldade_hint_label.add_theme_color_override("font_color", Color(0.76, 0.88, 0.96))
	conteudo_vbox.add_child(_dificuldade_hint_label)
	conteudo_vbox.move_child(_dificuldade_hint_label, barra.get_index() + 1)

func selecionar_dificuldade_ia(nivel: int, tocar_som: bool = true) -> void:
	_dificuldade_ia = posmod(nivel, 3)
	var cm := get_node_or_null("/root/CampaignManager")
	if cm != null and "dificuldade_ia" in cm:
		cm.dificuldade_ia = _dificuldade_ia
	var cores_ativas := [
		Color(0.55, 1.35, 0.65),
		Color(1.30, 1.15, 0.50),
		Color(1.35, 0.55, 0.55)
	]
	for i in range(_botoes_dificuldade.size()):
		_botoes_dificuldade[i].modulate = cores_ativas[i] if i == _dificuldade_ia else Color(0.68, 0.68, 0.68)
	if _dificuldade_hint_label != null:
		_dificuldade_hint_label.text = "🎚️ %s — %s" % [DIFICULDADE_NOMES[_dificuldade_ia], DIFICULDADE_DESCRICOES[_dificuldade_ia]]
		_dificuldade_hint_label.add_theme_color_override("font_color", cores_ativas[_dificuldade_ia])
	if _selecionando_personagem and _escolhido >= 0 and _escolhido < CHAMPIONS.size():
		if not _campeao_bloqueado_no_torneio(_escolhido):
			iniciar_botao.text = "⚔️ TORNEIO (%s) COM %s [ENTER]" % [DIFICULDADE_NOMES[_dificuldade_ia], str(CHAMPIONS[_escolhido]["name"]).to_upper()]
	if tocar_som and get_node_or_null("/root/AudioManager") != null:
		AudioManager.tocar_sfx("cursor_selecao_lutador", 0.04)

func selecionar_arena_inicial(idx: int, tocar_som: bool = true) -> void:
	_arena_escolhida = posmod(idx, TongobrigaStageDirector.get_stage_count())
	for i in range(_botoes_arena.size()):
		_botoes_arena[i].modulate = Color(1.2, 1.15, 0.75) if i == _arena_escolhida else Color(0.72, 0.72, 0.72)
	if _stage_director != null:
		_stage_director.apply_stage(_arena_escolhida, cenario_sprite, braseiro_esq, braseiro_dir, false)
	if tocar_som:
		AudioManager.tocar_sfx("cursor_selecao_lutador", 0.04)

func _construir_grade_selecao() -> void:
	for c in grade_retratos.get_children():
		c.queue_free()
	_botoes_elenco.clear()
	_badges_cadeado.clear()

	grade_retratos.custom_minimum_size = Vector2(0.0, 56.0)
	grade_retratos.add_theme_constant_override("separation", 6)

	for i in range(CHAMPIONS.size()):
		var champ: Dictionary = CHAMPIONS[i]
		var btn := Button.new()
		btn.focus_mode = Control.FOCUS_NONE
		btn.custom_minimum_size = Vector2(54.0, 52.0)
		btn.expand_icon = true
		btn.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
		btn.visible = not _campeao_oculto(i)
		var portrait_path := str(champ.get("portrait", ""))
		var tex := _carregar_retrato_seguro(portrait_path)
		if tex != null:
			btn.icon = tex
		btn.pressed.connect(selecionar_campeao.bind(i, true))
		grade_retratos.add_child(btn)
		_botoes_elenco.append(btn)

		var badge := Label.new()
		badge.text = "🔒" if _campeao_bloqueado_no_torneio(i) else ""
		badge.add_theme_font_size_override("font_size", 11)
		badge.position = Vector2(33.0, 2.0)
		btn.add_child(badge)
		_badges_cadeado.append(badge)

func _atualizar_visuais_cadeado() -> void:
	for i in range(_badges_cadeado.size()):
		if is_instance_valid(_badges_cadeado[i]):
			_badges_cadeado[i].text = "🔒" if _campeao_bloqueado_no_torneio(i) else ""

func selecionar_campeao(indice: int, tocar_som: bool = true) -> void:
	if indice < 0 or indice >= CHAMPIONS.size():
		return
	if _campeao_oculto(indice):
		indice = _proximo_campeao_visivel(indice, 1)
	_escolhido = indice
	var c: Dictionary = CHAMPIONS[indice]
	var trancado := _campeao_bloqueado_no_torneio(indice)

	if tocar_som:
		AudioManager.tocar_sfx("cursor_selecao_lutador", 0.05)

	_atualizar_visuais_cadeado()
	for i in range(_botoes_elenco.size()):
		var btn := _botoes_elenco[i]
		var slot_trancado := _campeao_bloqueado_no_torneio(i)
		if i == _escolhido:
			btn.modulate = Color(0.65, 0.65, 0.72) if slot_trancado else Color(1.25, 1.25, 1.25)
		else:
			btn.modulate = Color(0.28, 0.28, 0.34) if slot_trancado else Color(0.65, 0.65, 0.65)

	var p_tex := _carregar_retrato_seguro(str(c["portrait"]))
	if p_tex != null:
		retrato_grande.texture = p_tex
	retrato_grande.modulate = Color(0.32, 0.32, 0.38) if trancado else Color.WHITE

	if trancado:
		nome_grande.text = "🔒 MARCO (SECRETO)"
		arquetipo_label.text = "PERSONAGEM DESBLOQUEÁVEL PÓS-TORNEIO"
		origem_label.text = "ORIGEM: " + str(c.get("origin", "")).to_upper()
		especial_detalhe.text = "GOLPE SECRETO: " + str(c["special"]).to_upper()
		desc_label.text = "Vence as 4 Arenas do Torneio com um dos 8 campeões titulares para desbloquear Marco! (Disponível já no Treino [T] ou com [F5] para teste)."
		iniciar_botao.text = "🔒 VENCE O TORNEIO PARA DESBLOQUEAR"
	else:
		nome_grande.text = c["name"].to_upper()
		arquetipo_label.text = c["archetype"].to_upper()
		origem_label.text = "ORIGEM: " + str(c.get("origin", "Marco de Canaveses")).to_upper()
		especial_detalhe.text = "GOLPE ESPECIAL: " + str(c["special"]).to_upper()
		desc_label.text = str(c.get("description", ""))
		iniciar_botao.text = "⚔️ TORNEIO (%s) COM %s [ENTER]" % [DIFICULDADE_NOMES[_dificuldade_ia], c["name"].to_upper()]

	barra_vida_stat.value = float(c["health"]) / 155.0 * 100.0
	barra_forca_stat.value = float(c["strength"]) / 20.0 * 100.0
	barra_vel_stat.value = float(c["speed"]) / 250.0 * 100.0
	barra_def_stat.value = float(c["defense"]) / 0.25 * 100.0

func _input(event: InputEvent) -> void:
	if _selecionando_personagem:
		if event.is_action_pressed("ui_left") or (event is InputEventKey and event.pressed and event.physical_keycode == KEY_A):
			var novo := _proximo_campeao_visivel(_escolhido, -1)
			selecionar_campeao(novo, true)
			get_viewport().set_input_as_handled()
		elif event.is_action_pressed("ui_right") or (event is InputEventKey and event.pressed and event.physical_keycode == KEY_D):
			var novo := _proximo_campeao_visivel(_escolhido, 1)
			selecionar_campeao(novo, true)
			get_viewport().set_input_as_handled()
		elif event is InputEventKey and event.pressed and not event.echo and event.physical_keycode == KEY_F1:
			selecionar_dificuldade_ia(_dificuldade_ia + 1, true)
			get_viewport().set_input_as_handled()
		elif event is InputEventKey and event.pressed and not event.echo and event.physical_keycode in [KEY_1, KEY_2, KEY_3, KEY_4]:
			selecionar_arena_inicial(event.physical_keycode - KEY_1, true)
			get_viewport().set_input_as_handled()
		elif event is InputEventKey and event.pressed and not event.echo and event.physical_keycode == KEY_F5:
			var cm := get_node_or_null("/root/CampaignManager")
			if cm != null and "marco_lutador_desbloqueado" in cm:
				cm.marco_lutador_desbloqueado = not cm.marco_lutador_desbloqueado
			var am := get_node_or_null("/root/AudioManager")
			if am != null:
				am.tocar_sfx("especial_pronto", 0.0)
			selecionar_campeao(_escolhido, false)
			get_viewport().set_input_as_handled()
		elif event is InputEventKey and event.pressed and not event.echo and event.physical_keycode == KEY_T:
			_iniciar_modo_treino()
			get_viewport().set_input_as_handled()
		elif event.is_action_pressed("ui_accept") or (event is InputEventKey and event.pressed and (event.physical_keycode == KEY_ENTER or event.physical_keycode == KEY_KP_ENTER or event.physical_keycode == KEY_SPACE)):
			_confirmar_selecao()
			get_viewport().set_input_as_handled()
		elif event.is_action_pressed("ui_cancel") or (event is InputEventKey and event.pressed and event.physical_keycode == KEY_ESCAPE):
			_sair_para_praca()
			get_viewport().set_input_as_handled()
		return

	if not _jogo_ativo:
		if _bracket_tela_ativa:
			if event.is_action_pressed("ui_accept") or (event is InputEventKey and event.pressed and not event.echo and (event.physical_keycode == KEY_ENTER or event.physical_keycode == KEY_KP_ENTER or event.physical_keycode == KEY_SPACE)):
				_iniciar_luta_do_bracket()
				get_viewport().set_input_as_handled()
				return
			elif event.is_action_pressed("ui_cancel") or (event is InputEventKey and event.pressed and not event.echo and event.physical_keycode == KEY_ESCAPE):
				_voltar_para_selecao()
				get_viewport().set_input_as_handled()
				return
		if event is InputEventKey and event.pressed and not event.echo:
			if event.physical_keycode == KEY_ENTER or event.physical_keycode == KEY_KP_ENTER or event.physical_keycode == KEY_SPACE or event.physical_keycode == KEY_ESCAPE:
				_sair_para_praca()
				get_viewport().set_input_as_handled()
		return

	if event is InputEventJoypadButton:
		var jb := event as InputEventJoypadButton
		if not jb.pressed:
			return
		match jb.button_index:
			JOY_BUTTON_DPAD_UP, JOY_BUTTON_B:
				_salto_pendente = true
			JOY_BUTTON_Y:
				_ataque_pendente = "punch"
			JOY_BUTTON_X:
				_ataque_pendente = "kick"
			JOY_BUTTON_A:
				_ataque_pendente = "throw"
			JOY_BUTTON_RIGHT_SHOULDER:
				_ataque_pendente = "special"
			JOY_BUTTON_START:
				if _modo_treino:
					_voltar_para_selecao()
				else:
					_mostrar_modal_derrota("Combate interrompido pelo jogador.")
				get_viewport().set_input_as_handled()
		return

	if not event is InputEventKey:
		return
	var tecla := event as InputEventKey
	if not tecla.pressed or tecla.echo:
		return
	match tecla.physical_keycode:
		KEY_W, KEY_UP, KEY_SPACE:
			_salto_pendente = true
		KEY_J:
			_ataque_pendente = "punch"
		KEY_K:
			_ataque_pendente = "kick"
		KEY_U:
			_ataque_pendente = "throw"
		KEY_I:
			_ataque_pendente = "special"
		KEY_F1:
			selecionar_dificuldade_ia(_dificuldade_ia + 1, true)
			mensagem_label.text = "🎚️ IA: %s — %s" % [DIFICULDADE_NOMES[_dificuldade_ia], DIFICULDADE_DESCRICOES[_dificuldade_ia]]
		KEY_F2:
			TongobrigaChampion.debug_hitboxes = not TongobrigaChampion.debug_hitboxes
			if _debug_hud_label != null:
				_debug_hud_label.visible = TongobrigaChampion.debug_hitboxes
			mensagem_label.text = "Visualizador de Caixas de Colisão (Hitbox/Hurtbox/Pushbox): %s" % ("LIGADO" if TongobrigaChampion.debug_hitboxes else "DESLIGADO")
		KEY_F3:
			if _modo_treino:
				_dummy_mode = (_dummy_mode + 1) % DUMMY_NOMES.size()
				mensagem_label.text = "Boneco de Treino: %s" % DUMMY_NOMES[_dummy_mode]
		KEY_F4:
			if _modo_treino and _stage_director != null:
				_arena_escolhida = (_stage_director.current_stage_index + 1) % TongobrigaStageDirector.get_stage_count()
				var s_info := _stage_director.apply_stage(_arena_escolhida, cenario_sprite, braseiro_esq, braseiro_dir, true)
				mensagem_label.text = "🏛️ Arena trocada ao vivo: %s — %s" % [str(s_info["name"]), str(s_info["subtitle"])]
		KEY_F6:
			if _modo_treino:
				_treino_oponente_idx = _proximo_campeao_visivel(_treino_oponente_idx, 1)
				if _treino_oponente_idx == _escolhido:
					_treino_oponente_idx = _proximo_campeao_visivel(_treino_oponente_idx, 1)
				_iniciar_luta_treino()
		KEY_R:
			if _modo_treino and _jogador != null and _oponente != null:
				_jogador.heal(_jogador.max_health)
				_oponente.heal(_oponente.max_health)
				_jogador.special_gauge = 100.0
				_oponente.special_gauge = 100.0
				_jogador.global_position = Vector2(210.0, 304.0)
				_oponente.global_position = Vector2(430.0, 304.0)
				_atualizar_especial_ui()
				mensagem_label.text = "Treino resetado! HP 100% + Especial Cheio!"
		KEY_ESCAPE:
			if _modo_treino:
				_voltar_para_selecao()
			else:
				_mostrar_modal_derrota("Combate interrompido pelo jogador.")
			get_viewport().set_input_as_handled()

func _iniciar_modo_treino() -> void:
	if not _selecionando_personagem:
		return
	_selecionando_personagem = false
	_modo_treino = true
	_dummy_mode = 0
	TongobrigaChampion.debug_hitboxes = true
	if _debug_hud_label != null:
		_debug_hud_label.visible = true

	AudioManager.tocar_sfx("confirmar_lutador_gongo", 0.0)
	_treino_oponente_idx = _proximo_campeao_visivel(_escolhido, 1)
	_rounds_p1 = 0
	_rounds_p2 = 0
	_round_num = 1

	selecao_painel.visible = false
	if _bracket_overlay != null and is_instance_valid(_bracket_overlay):
		_bracket_overlay.visible = false
	arena_hud.visible = true
	regressar_botao.visible = false
	_iniciar_luta_treino()

func _voltar_para_selecao() -> void:
	_jogo_ativo = false
	_modo_treino = false
	_bracket_tela_ativa = false
	_lutadores_travados = true
	if _jogador != null:
		_jogador.queue_free()
		_jogador = null
	if _oponente != null:
		_oponente.queue_free()
		_oponente = null
	if _bracket_overlay != null and is_instance_valid(_bracket_overlay):
		_bracket_overlay.queue_free()
		_bracket_overlay = null
	if _modal_overlay != null and is_instance_valid(_modal_overlay):
		_modal_overlay.queue_free()
		_modal_overlay = null
	arena_hud.visible = false
	selecao_painel.visible = true
	_selecionando_personagem = true
	selecionar_campeao(_escolhido, false)
	if get_node_or_null("/root/AudioManager") != null:
		get_node("/root/AudioManager").tocar_bgm_id("select_tongobriga")

func _confirmar_selecao() -> void:
	if not _selecionando_personagem:
		return
	if _campeao_bloqueado_no_torneio(_escolhido):
		AudioManager.tocar_sfx("pechincha_falha", 0.0)
		desc_label.text = "🔒 Marco é um lutador secreto desbloqueável! Conquista o Torneio com um dos 8 campeões titulares primeiro (ou prime [T] para testá-lo no Laboratório de Hitboxes / [F5] para desbloqueio rápido)."
		return

	_selecionando_personagem = false
	_modo_treino = false
	AudioManager.tocar_sfx("confirmar_lutador_gongo", 0.0)

	var btn_escolhido: Button = _botoes_elenco[_escolhido]
	var tw := create_tween()
	tw.set_loops(4)
	tw.tween_property(btn_escolhido, "modulate", Color(2.5, 2.5, 2.5), 0.08)
	tw.tween_property(btn_escolhido, "modulate", Color.WHITE, 0.08)
	await tw.finished

	_iniciar_torneio()

# ==============================================================================
# SISTEMA DE CHAVEAMENTO (BRACKETS) & LUTA FINAL COM MARCO DE CANAVESES
# ==============================================================================

func _iniciar_torneio() -> void:
	var cm := get_node_or_null("/root/CampaignManager")
	if cm != null and cm.has_method("iniciar_torneio"):
		cm.iniciar_torneio()
	_construir_chaveamento()
	selecao_painel.visible = false
	arena_hud.visible = false
	regressar_botao.visible = false
	_mostrar_tela_chaveamento()

func _reiniciar_torneio() -> void:
	if _modal_overlay != null and is_instance_valid(_modal_overlay):
		_modal_overlay.queue_free()
		_modal_overlay = null
	_iniciar_torneio()

func _construir_chaveamento() -> void:
	_bracket_quartas.clear()
	_bracket_semis.clear()
	_bracket_final = {}
	_bracket_boss = {}
	_bracket_etapa = 0

	var rivais: Array[int] = []
	for i in range(CHAMPIONS.size()):
		if i != _escolhido and not bool(CHAMPIONS[i].get("is_secret", false)) and not _campeao_oculto(i):
			rivais.append(i)
	rivais.shuffle()

	# 4 Lutas de Quartas de Final (Arena 1: Castro Celta & Pedra Formosa)
	# Luta 0 é sempre a do jogador!
	_bracket_quartas = [
		{"p1": _escolhido, "p2": rivais[0], "score": [0, 0], "winner": -1, "stage": 0, "stage_name": "Castro Celta & Pedra Formosa"},
		{"p1": rivais[1], "p2": rivais[2], "score": [0, 0], "winner": -1, "stage": 0, "stage_name": "Castro Celta & Pedra Formosa"},
		{"p1": rivais[3], "p2": rivais[4], "score": [0, 0], "winner": -1, "stage": 0, "stage_name": "Castro Celta & Pedra Formosa"},
		{"p1": rivais[5], "p2": rivais[6], "score": [0, 0], "winner": -1, "stage": 0, "stage_name": "Castro Celta & Pedra Formosa"}
	]

	# Simular os outros 3 confrontos das Quartas
	for k in range(1, 4):
		var w_p1: bool = _rng.randf() > 0.5
		_bracket_quartas[k]["score"] = [2, 1] if w_p1 else [1, 2]
		_bracket_quartas[k]["winner"] = _bracket_quartas[k]["p1"] if w_p1 else _bracket_quartas[k]["p2"]

	# Semifinais (Arena 2: Termas & Fórum Romano)
	_bracket_semis = [
		{"p1": _escolhido, "p2": _bracket_quartas[1]["winner"], "score": [0, 0], "winner": -1, "stage": 1, "stage_name": "Termas & Fórum Romano"},
		{"p1": _bracket_quartas[2]["winner"], "p2": _bracket_quartas[3]["winner"], "score": [0, 0], "winner": -1, "stage": 1, "stage_name": "Termas & Fórum Romano"}
	]
	var w_s2: bool = _rng.randf() > 0.5
	_bracket_semis[1]["score"] = [2, 1] if w_s2 else [0, 2]
	_bracket_semis[1]["winner"] = _bracket_semis[1]["p1"] if w_s2 else _bracket_semis[1]["p2"]

	# Final de Tongóbriga (Arena 3: Ponte Medieval do Tâmega)
	_bracket_final = {
		"p1": _escolhido,
		"p2": _bracket_semis[1]["winner"],
		"score": [0, 0],
		"winner": -1,
		"stage": 2,
		"stage_name": "Ponte Medieval do Tâmega"
	}

	# Grande Final Secreta: O Desafio do Alquimista (Arena 4: Praça da Taverna & Botica à Noite)
	_bracket_boss = {
		"p1": _escolhido,
		"p2": 9, # Marco
		"score": [0, 0],
		"winner": -1,
		"stage": 3,
		"stage_name": "Praça da Taverna & Botica à Noite"
	}

func _obter_partida_atual_do_jogador() -> Dictionary:
	match _bracket_etapa:
		0:
			return _bracket_quartas[0]
		1:
			return _bracket_semis[0]
		2:
			return _bracket_final
		3:
			return _bracket_boss
		_:
			return _bracket_quartas[0]

func _mostrar_tela_chaveamento() -> void:
	_bracket_tela_ativa = true
	_jogo_ativo = false
	_lutadores_travados = true

	if _bracket_overlay != null and is_instance_valid(_bracket_overlay):
		_bracket_overlay.queue_free()

	_bracket_overlay = ColorRect.new()
	_bracket_overlay.name = "TelaChaveamento"
	_bracket_overlay.color = Color(0.04, 0.04, 0.06, 0.96)
	_bracket_overlay.z_index = 40
	$UI.add_child(_bracket_overlay)
	_bracket_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_bracket_overlay.size = Vector2(640.0, 360.0)

	var margem := MarginContainer.new()
	_bracket_overlay.add_child(margem)
	margem.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	margem.size = Vector2(640.0, 360.0)
	margem.add_theme_constant_override("margin_left", 14)
	margem.add_theme_constant_override("margin_top", 10)
	margem.add_theme_constant_override("margin_right", 14)
	margem.add_theme_constant_override("margin_bottom", 10)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 6)
	margem.add_child(vbox)

	# 1. Cabeçalho do Chaveamento
	var header_box := HBoxContainer.new()
	var tit := Label.new()
	tit.text = "🏆 TORNEIO DE TONGÓBRIGA — CHAVEAMENTO DO CAMPEONATO ⚔️"
	tit.add_theme_font_size_override("font_size", 12)
	tit.add_theme_color_override("font_color", Color(1.0, 0.88, 0.28))
	header_box.add_child(tit)
	vbox.add_child(header_box)

	var sub := Label.new()
	sub.text = "Partidas em Melhor de Três (FT2 · 2 Rounds para Vencer) · 4 Arenas Vivas · Grande Final com Marco de Canaveses"
	sub.add_theme_font_size_override("font_size", 8)
	sub.add_theme_color_override("font_color", Color(0.85, 0.80, 0.70))
	vbox.add_child(sub)

	vbox.add_child(HSeparator.new())

	# 2. Painel de Árvore de Confrontos
	var tree_hbox := HBoxContainer.new()
	tree_hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	tree_hbox.add_theme_constant_override("separation", 10)
	tree_hbox.size_flags_vertical = Control.SIZE_EXPAND_FILL

	# Coluna 1: Quartas de Final
	var col_qf := _criar_coluna_bracket("QUARTAS (ARENA 1)", [
		_bracket_quartas[0], _bracket_quartas[1], _bracket_quartas[2], _bracket_quartas[3]
	], _bracket_etapa == 0)
	tree_hbox.add_child(col_qf)

	# Conector 1
	var arr1 := Label.new()
	arr1.text = "➔"
	arr1.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	arr1.add_theme_color_override("font_color", Color(0.65, 0.65, 0.75))
	tree_hbox.add_child(arr1)

	# Coluna 2: Semifinais
	var col_sf := _criar_coluna_bracket("SEMIFINAIS (ARENA 2)", [
		_bracket_semis[0], _bracket_semis[1]
	], _bracket_etapa == 1)
	tree_hbox.add_child(col_sf)

	# Conector 2
	var arr2 := Label.new()
	arr2.text = "➔"
	arr2.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	arr2.add_theme_color_override("font_color", Color(0.65, 0.65, 0.75))
	tree_hbox.add_child(arr2)

	# Coluna 3: Final de Tongóbriga
	var col_fn := _criar_coluna_bracket("FINAL TONGÓBRIGA", [
		_bracket_final
	], _bracket_etapa == 2)
	tree_hbox.add_child(col_fn)

	# Conector 3
	var arr3 := Label.new()
	arr3.text = "👑➔"
	arr3.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	arr3.add_theme_color_override("font_color", Color(1.0, 0.85, 0.2))
	tree_hbox.add_child(arr3)

	# Coluna 4: Grande Final Secreta (Marco)
	var col_boss := _criar_coluna_bracket("GRANDE FINAL CANAVESES", [
		_bracket_boss
	], _bracket_etapa == 3, true)
	tree_hbox.add_child(col_boss)

	vbox.add_child(tree_hbox)
	vbox.add_child(HSeparator.new())

	# 3. Barra de Ação
	var bottom_hbox := HBoxContainer.new()
	bottom_hbox.add_theme_constant_override("separation", 10)

	var p_atual := _obter_partida_atual_do_jogador()
	var p1_data: Dictionary = CHAMPIONS[p_atual["p1"]]
	var p2_data: Dictionary = CHAMPIONS[p_atual["p2"]]
	var etapa_nome := ""
	match _bracket_etapa:
		0: etapa_nome = "QUARTAS DE FINAL"
		1: etapa_nome = "SEMIFINAL"
		2: etapa_nome = "FINAL DE TONGÓBRIGA"
		3: etapa_nome = "👑 GRANDE FINAL: DESAFIO DO ALQUIMISTA!"

	var info_lbl := Label.new()
	info_lbl.text = "⚔️ %s: %s VS %s — %s" % [etapa_nome, p1_data["name"].to_upper(), p2_data["name"].to_upper(), p_atual.get("stage_name", "Arena")]
	info_lbl.add_theme_font_size_override("font_size", 9)
	info_lbl.add_theme_color_override("font_color", Color(1.0, 0.92, 0.45) if _bracket_etapa == 3 else Color(0.9, 0.9, 0.9))
	info_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	info_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	bottom_hbox.add_child(info_lbl)

	var btn_lutar := Button.new()
	btn_lutar.text = "⚔️ ENTRAR NA ARENA (MELHOR DE 3) [ENTER]"
	btn_lutar.custom_minimum_size = Vector2(240.0, 26.0)
	btn_lutar.focus_mode = Control.FOCUS_NONE
	btn_lutar.add_theme_font_size_override("font_size", 9)
	btn_lutar.pressed.connect(_iniciar_luta_do_bracket)
	bottom_hbox.add_child(btn_lutar)

	var btn_desistir := Button.new()
	btn_desistir.text = "🏃 VOLTAR [ESC]"
	btn_desistir.custom_minimum_size = Vector2(100.0, 26.0)
	btn_desistir.focus_mode = Control.FOCUS_NONE
	btn_desistir.add_theme_font_size_override("font_size", 9)
	btn_desistir.pressed.connect(_voltar_para_selecao)
	bottom_hbox.add_child(btn_desistir)

	vbox.add_child(bottom_hbox)

func _criar_coluna_bracket(titulo_coluna: String, partidas: Array, is_etapa_ativa: bool, is_boss: bool = false) -> Control:
	var container := VBoxContainer.new()
	container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	container.alignment = BoxContainer.ALIGNMENT_CENTER
	container.add_theme_constant_override("separation", 6)

	var lbl_col := Label.new()
	lbl_col.text = titulo_coluna
	lbl_col.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl_col.add_theme_font_size_override("font_size", 8)
	lbl_col.add_theme_color_override("font_color", Color(1.0, 0.85, 0.3) if is_etapa_ativa else Color(0.65, 0.65, 0.70))
	container.add_child(lbl_col)

	for p: Dictionary in partidas:
		var panel := PanelContainer.new()
		var sb := StyleBoxFlat.new()
		var e_luta_jogador: bool = (int(p.get("p1", -1)) == _escolhido)
		if is_etapa_ativa and e_luta_jogador:
			sb.bg_color = Color(0.22, 0.16, 0.08, 0.95)
			sb.border_color = Color(1.0, 0.85, 0.25)
			sb.set_border_width_all(2)
		elif is_boss:
			sb.bg_color = Color(0.14, 0.08, 0.18, 0.90)
			sb.border_color = Color(0.65, 0.35, 0.85)
			sb.set_border_width_all(1)
		else:
			sb.bg_color = Color(0.08, 0.08, 0.11, 0.85)
			sb.border_color = Color(0.25, 0.25, 0.32)
			sb.set_border_width_all(1)
		sb.set_corner_radius_all(5)
		sb.content_margin_left = 6.0
		sb.content_margin_top = 4.0
		sb.content_margin_right = 6.0
		sb.content_margin_bottom = 4.0
		panel.add_theme_stylebox_override("panel", sb)

		var card_vbox := VBoxContainer.new()
		card_vbox.add_theme_constant_override("separation", 2)

		var p1_idx: int = int(p.get("p1", -1))
		var p2_idx: int = int(p.get("p2", -1))
		var score: Array = p.get("score", [0, 0])
		var winner: int = int(p.get("winner", -1))

		card_vbox.add_child(_criar_linha_lutador_bracket(p1_idx, score[0], winner == p1_idx and winner != -1))
		card_vbox.add_child(_criar_linha_lutador_bracket(p2_idx, score[1], winner == p2_idx and winner != -1, is_boss))

		panel.add_child(card_vbox)
		container.add_child(panel)

	return container

func _criar_linha_lutador_bracket(idx: int, score: int, is_winner: bool, is_secret_boss: bool = false) -> Control:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 4)

	var tex_rect := TextureRect.new()
	tex_rect.custom_minimum_size = Vector2(20.0, 20.0)
	tex_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	tex_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED

	var nome_lutador := "A DEFINIR"
	if idx >= 0 and idx < CHAMPIONS.size():
		var c: Dictionary = CHAMPIONS[idx]
		nome_lutador = str(c["name"])
		var ptex := _carregar_retrato_seguro(str(c.get("portrait", "")))
		if ptex != null:
			tex_rect.texture = ptex
	row.add_child(tex_rect)

	var lbl := Label.new()
	if is_secret_boss:
		lbl.text = "🧪 MARCO (BOSS)"
		lbl.add_theme_color_override("font_color", Color(0.4, 1.0, 0.7))
	else:
		lbl.text = nome_lutador
		if is_winner:
			lbl.add_theme_color_override("font_color", Color(1.0, 0.9, 0.3))
		else:
			lbl.add_theme_color_override("font_color", Color(0.85, 0.85, 0.85))
	lbl.add_theme_font_size_override("font_size", 8)
	lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	row.add_child(lbl)

	var sc_lbl := Label.new()
	sc_lbl.text = str(score)
	sc_lbl.add_theme_font_size_override("font_size", 8)
	sc_lbl.add_theme_color_override("font_color", Color(1.0, 0.85, 0.2) if is_winner else Color(0.65, 0.65, 0.65))
	row.add_child(sc_lbl)

	return row

func _iniciar_luta_do_bracket() -> void:
	if _bracket_overlay != null and is_instance_valid(_bracket_overlay):
		_bracket_overlay.visible = false
	_bracket_tela_ativa = false

	var partida: Dictionary = _obter_partida_atual_do_jogador()
	_rounds_p1 = 0
	_rounds_p2 = 0
	_round_num = 1

	var stage_idx: int = int(partida.get("stage", 0))
	var p2_idx: int = int(partida.get("p2", 0))

	_preparar_combate(_escolhido, p2_idx, stage_idx)

func _iniciar_luta_treino() -> void:
	_rounds_p1 = 0
	_rounds_p2 = 0
	_round_num = 1
	_preparar_combate(_escolhido, _treino_oponente_idx, _arena_escolhida)

func _preparar_combate(p1_idx: int, p2_idx: int, stage_idx: int) -> void:
	if _jogador != null:
		_jogador.queue_free()
	if _oponente != null:
		_oponente.queue_free()

	var stage_info: Dictionary = {}
	if _stage_director != null:
		stage_info = _stage_director.apply_stage(stage_idx, cenario_sprite, braseiro_esq, braseiro_dir, true)

	_match_finalizado = false
	_lutadores_travados = true
	_jogo_ativo = true
	_ia_proximo_golpe = _rng.randf_range(0.35, 0.65)
	_bloqueio_ia = 0.0
	_ia_reacao_bloqueio = -1.0
	_ia_ataque_observado = false
	_ia_bloqueio_agachado = false
	_tempo_ronda = 99.0
	_ultimo_segundo_alerta = -1
	_combo_count = 0
	combo_label.visible = false

	var dados_p1: Dictionary = CHAMPIONS[p1_idx].duplicate(true)
	var dados_p2: Dictionary = CHAMPIONS[p2_idx].duplicate(true)
	if not _modo_treino:
		match _dificuldade_ia:
			0: # EASY — acolhedor e acessível para jogadores casuais
				dados_p2["health"] = maxi(80, roundi(float(dados_p2.get("health", 120)) * 0.88))
				dados_p2["strength"] = maxi(7, roundi(float(dados_p2.get("strength", 15)) * 0.68))
				dados_p2["speed"] = float(dados_p2.get("speed", 185.0)) * 0.80
			1: # INTERMEDIATE — desafio arcade equilibrado
				dados_p2["strength"] = maxi(10, roundi(float(dados_p2.get("strength", 15)) * 0.90))
				dados_p2["speed"] = float(dados_p2.get("speed", 185.0)) * 0.94
			2: # HARD — desafio arcade intenso sem leitura robótica
				dados_p2["health"] = roundi(float(dados_p2.get("health", 120)) * 1.10)
				dados_p2["strength"] = maxi(12, roundi(float(dados_p2.get("strength", 15)) * 1.06))
				dados_p2["speed"] = float(dados_p2.get("speed", 185.0)) * 1.05

	_jogador = _criar_lutador(dados_p1, Vector2(190.0, 304.0), 1.0)
	_oponente = _criar_lutador(dados_p2, Vector2(450.0, 304.0), -1.0)

	_jogador.health_changed.connect(_ao_vida_mudada)
	_oponente.health_changed.connect(_ao_vida_mudada)
	_jogador.knocked_out.connect(_ao_lutador_derrotado)
	_oponente.knocked_out.connect(_ao_lutador_derrotado)
	_jogador.attack_landed.connect(_ao_golpe_conectado)
	_oponente.attack_landed.connect(_ao_golpe_conectado)

	nome_jogador.text = dados_p1["name"].to_upper()
	nome_oponente.text = dados_p2["name"].to_upper()

	retrato_p1.texture = _carregar_retrato_seguro(str(dados_p1["portrait"]))
	retrato_p2.texture = _carregar_retrato_seguro(str(dados_p2["portrait"]))

	round_info_label.text = "LAB TREINO" if _modo_treino else ("ROUND %d" % _round_num)
	vitorias_p1_label.text = "TREINO" if _modo_treino else _formatar_rounds(_rounds_p1)
	vitorias_p2_label.text = "DUMMY" if _modo_treino else _formatar_rounds(_rounds_p2)

	vida_jogador.max_value = _jogador.max_health
	vida_jogador.value = _jogador.health
	vida_dano_jogador.max_value = _jogador.max_health
	vida_dano_jogador.value = _jogador.health

	vida_oponente.max_value = _oponente.max_health
	vida_oponente.value = _oponente.health
	vida_dano_oponente.max_value = _oponente.max_health
	vida_dano_oponente.value = _oponente.health

	if especial_jogador_barra != null:
		especial_jogador_barra.max_value = 100.0
		especial_jogador_barra.value = _jogador.special_gauge
	if especial_oponente_barra != null:
		especial_oponente_barra.max_value = 100.0
		especial_oponente_barra.value = _oponente.special_gauge

	arena_hud.visible = true
	var nome_arena := str(stage_info.get("name", "Arena de Tongóbriga"))

	if _modo_treino:
		_jogador.special_gauge = 100.0
		_atualizar_especial_ui()
		mensagem_label.text = "LAB [%s]: [F2] Caixas · [F3] Dummy · [F4] Arena · [F6] Rival · [R] Reset" % nome_arena
		controlos_label.text = "WASD: Mover/Saltar/Agachar · J: Golpe · K: Chute · S+K: Rasteira · U: Agarrão · L: Defesa · I: Super"
		_tocar_anuncio_arcade("LAB TREINO", "FIGHT!", "announcer_round_1")
	else:
		var banner_r := "ROUND 1"
		var vox_round := "announcer_round_1"
		mensagem_label.text = "🏛️ %s — %s VS %s! (Melhor de Três)" % [nome_arena, dados_p1["name"], dados_p2["name"]]
		controlos_label.text = "WASD: Mover/Saltar/Agachar · J: Golpe · K: Chute · S+K: Rasteira · U: Agarrão · L: Defesa · I: Super"
		_tocar_anuncio_arcade(banner_r, "FIGHT!", vox_round)

func _tocar_anuncio_arcade(texto_inicial: String, texto_seguinte: String, vox_id: String = "") -> void:
	_lutadores_travados = true
	if vox_id != "":
		AudioManager.tocar_voz(vox_id, 2.2, 1.0, true)
	banner_arcade.visible = true
	banner_arcade.text = texto_inicial
	banner_arcade.scale = Vector2(1.5, 1.5)
	banner_arcade.modulate = Color(1.0, 0.9, 0.2, 1.0)

	var tw := create_tween()
	tw.tween_property(banner_arcade, "scale", Vector2.ONE, 0.35).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	await tw.finished
	await get_tree().create_timer(0.40).timeout

	if not is_inside_tree() or not _jogo_ativo:
		return

	banner_arcade.text = texto_seguinte
	banner_arcade.scale = Vector2(1.8, 1.8)
	banner_arcade.modulate = Color(1.0, 0.2, 0.1, 1.0)

	var tw2 := create_tween()
	tw2.tween_property(banner_arcade, "scale", Vector2.ONE, 0.25).set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)
	await tw2.finished
	await get_tree().create_timer(0.35).timeout

	if is_inside_tree():
		banner_arcade.visible = false
		_lutadores_travados = false

func _process(delta: float) -> void:
	# Screen shake
	if _shake_timer > 0.0:
		_shake_timer -= delta
		position = Vector2(
			_rng.randf_range(-_shake_amount, _shake_amount),
			_rng.randf_range(-_shake_amount, _shake_amount)
		)
		if _shake_timer <= 0.0:
			position = Vector2.ZERO

	# HUD Shake no P1 e P2 ao sofrer dano
	if _shake_hud_p1_timer > 0.0 and barra_container_p1 != null:
		_shake_hud_p1_timer -= delta
		barra_container_p1.position = Vector2(
			_rng.randf_range(-_shake_hud_p1_amount, _shake_hud_p1_amount),
			_rng.randf_range(-_shake_hud_p1_amount, _shake_hud_p1_amount)
		)
		if _shake_hud_p1_timer <= 0.0:
			barra_container_p1.position = Vector2.ZERO

	if _shake_hud_p2_timer > 0.0 and barra_container_p2 != null:
		_shake_hud_p2_timer -= delta
		barra_container_p2.position = Vector2(
			_rng.randf_range(-_shake_hud_p2_amount, _shake_hud_p2_amount),
			_rng.randf_range(-_shake_hud_p2_amount, _shake_hud_p2_amount)
		)
		if _shake_hud_p2_timer <= 0.0:
			barra_container_p2.position = Vector2.ZERO

	# Batimento cardíaco pulsante na vida crítica (< 30% HP)
	if _flash_p1_timer > 0.0:
		_flash_p1_timer -= delta
	elif _jogador != null and vida_jogador != null and not _match_finalizado:
		var perc_p1 := float(_jogador.health) / float(maxi(1, _jogador.max_health))
		if perc_p1 < 0.30:
			var pulso := sin(Time.get_ticks_msec() * 0.01) * 0.5 + 0.5
			vida_jogador.modulate = Color(1.0, 0.35, 0.3).lerp(Color(1.0, 0.95, 0.3), pulso)
		else:
			vida_jogador.modulate = Color.WHITE

	if _flash_p2_timer > 0.0:
		_flash_p2_timer -= delta
	elif _oponente != null and vida_oponente != null and not _match_finalizado:
		var perc_p2 := float(_oponente.health) / float(maxi(1, _oponente.max_health))
		if perc_p2 < 0.30:
			var pulso := sin(Time.get_ticks_msec() * 0.01) * 0.5 + 0.5
			vida_oponente.modulate = Color(1.0, 0.35, 0.3).lerp(Color(1.0, 0.95, 0.3), pulso)
		else:
			vida_oponente.modulate = Color.WHITE

	# Combo timer
	if _combo_timer > 0.0:
		_combo_timer -= delta
		if _combo_timer <= 0.0:
			_combo_count = 0
			combo_label.visible = false

	if not _jogo_ativo or _jogador == null or _oponente == null:
		return

	# Timer da Ronda (Street Fighter II 99s — infinito no Modo Treino)
	if not _lutadores_travados and not _match_finalizado:
		if _modo_treino:
			timer_label.text = "∞"
			timer_label.modulate = Color(0.4, 0.95, 1.0)
			if _treino_regen_timer > 0.0:
				_treino_regen_timer -= delta
				if _treino_regen_timer <= 0.0:
					if _jogador.health < _jogador.max_health:
						_jogador.heal(_jogador.max_health)
					if _oponente.health < _oponente.max_health:
						_oponente.heal(_oponente.max_health)
		else:
			_tempo_ronda = maxf(_tempo_ronda - delta, 0.0)
			var seg_int := ceili(_tempo_ronda)
			timer_label.text = "%02d" % seg_int
			if _tempo_ronda <= 10.0 and seg_int > 0 and seg_int != _ultimo_segundo_alerta:
				_ultimo_segundo_alerta = seg_int
				AudioManager.tocar_sfx("timer_10s_alerta", 0.0)
			if _tempo_ronda <= 15.0:
				timer_label.modulate = Color(1.0, 0.3, 0.3) if fmod(_tempo_ronda * 4.0, 1.0) > 0.5 else Color.WHITE
			else:
				timer_label.modulate = Color(1.0, 0.88, 0.2)
			if _tempo_ronda <= 0.0:
				_tempo_esgotado()
				return

	# Movimento, Agachamento e Bloqueio do Jogador
	var movimento := 0.0
	var agachando_p1 := false
	var bloqueando_p1 := false
	if not _lutadores_travados:
		if Input.is_key_pressed(KEY_A) or Input.is_key_pressed(KEY_LEFT) or Input.is_action_pressed("mover_esquerda"):
			movimento -= 1.0
		if Input.is_key_pressed(KEY_D) or Input.is_key_pressed(KEY_RIGHT) or Input.is_action_pressed("mover_direita"):
			movimento += 1.0
		agachando_p1 = Input.is_key_pressed(KEY_S) or Input.is_key_pressed(KEY_DOWN) or Input.is_action_pressed("mover_baixo")
		bloqueando_p1 = Input.is_key_pressed(KEY_L) or Input.is_joy_button_pressed(0, JOY_BUTTON_LEFT_SHOULDER)

	_jogador.update_fighter(
		delta,
		movimento,
		_salto_pendente and not _lutadores_travados,
		bloqueando_p1,
		_oponente,
		_lutadores_travados,
		agachando_p1
	)

	# Movimento da IA ou Boneco de Treino
	var mov_p2 := 0.0
	var bloq_p2 := false
	var agach_p2 := false
	if not _lutadores_travados:
		if _modo_treino:
			match _dummy_mode:
				0:
					mov_p2 = 0.0
				1:
					bloq_p2 = true
				2:
					bloq_p2 = true
					agach_p2 = true
				3:
					mov_p2 = _movimento_ia()
					bloq_p2 = _bloqueio_ia > 0.0
					agach_p2 = bloq_p2 and _ia_bloqueio_agachado
		else:
			mov_p2 = _movimento_ia()
			bloq_p2 = _bloqueio_ia > 0.0
			agach_p2 = bloq_p2 and _ia_bloqueio_agachado

	_oponente.update_fighter(
		delta,
		mov_p2,
		false,
		bloq_p2,
		_jogador,
		_lutadores_travados,
		agach_p2
	)

	_salto_pendente = false

	# Execução de Golpes (Startup -> Active -> Recovery)
	if not _lutadores_travados and not _match_finalizado:
		if _ataque_pendente == "punch":
			_executar_ataque(_jogador, _oponente, "punch")
		elif _ataque_pendente == "kick":
			_executar_ataque(_jogador, _oponente, "kick")
		elif _ataque_pendente == "throw":
			_executar_ataque(_jogador, _oponente, "throw")
		elif _ataque_pendente == "special":
			if _jogador.can_use_special():
				_executar_ataque(_jogador, _oponente, "special")
			else:
				mensagem_label.text = "Especial a carregar... Causa ou recebe dano para encher o medidor!"
	_ataque_pendente = ""

	# Telemetria ao vivo das Caixas de Colisão [F2]
	if TongobrigaChampion.debug_hitboxes and _debug_hud_label != null:
		var dist_px := absf(_jogador.global_position.x - _oponente.global_position.x)
		var st_name := str(TongobrigaStageDirector.get_stage_info(_stage_director.current_stage_index)["id"]).to_upper() if _stage_director != null else "ARENA"
		_debug_hud_label.text = "🟨Pushbox  🟦Hurtbox(🟩Defesa)  🟥Hitbox  🟪Agarrão | Dist:%dpx | Arena:%s\nP1 %s [%s]  ·  P2 %s [%s]" % [
			roundi(dist_px),
			st_name,
			_jogador.champion_name,
			_jogador.get_frame_state_label(),
			_oponente.champion_name,
			_oponente.get_frame_state_label()
		]

	_atualizar_especial_ui()

func _criar_lutador(dados: Dictionary, posicao: Vector2, direcao: float) -> TongobrigaChampion:
	var lutador_base := CharacterBody2D.new()
	lutador_base.set_script(CHAMPION_SCRIPT)
	var lutador := lutador_base as TongobrigaChampion
	lutador.z_index = 10
	lutador.configure(dados, 304.0)
	lutador.global_position = posicao
	lutador.facing = direcao
	lutador.player_slot = -1 if direcao >= 0.0 else 1
	add_child(lutador)
	return lutador

func _tempo_reacao_ia() -> float:
	if _modo_treino:
		return 0.23
	match _dificuldade_ia:
		0: # EASY (~0.40s)
			return maxf(0.36, 0.44 - float(_bracket_etapa) * 0.02)
		1: # INTERMEDIATE (~0.23s)
			return maxf(0.20, 0.25 - float(_bracket_etapa) * 0.015)
		_: # HARD (~0.14s, piso humano de 0.12s)
			return maxf(0.12, 0.16 - float(_bracket_etapa) * 0.01 - float(_round_num - 1) * 0.005)

func _ia_golpe_ao_alcance(tipo: String) -> bool:
	var hitbox := _oponente.get_attack_hitbox_for(tipo)
	for hurtbox: Rect2 in _jogador.get_hurtboxes():
		if hitbox.intersects(hurtbox):
			return true
	return false

func _movimento_ia() -> float:
	var delta_ia := get_process_delta_time()
	_ia_proximo_golpe = maxf(_ia_proximo_golpe - delta_ia, 0.0)
	_bloqueio_ia = maxf(_bloqueio_ia - delta_ia, 0.0)
	if _bloqueio_ia <= 0.0:
		_ia_bloqueio_agachado = false

	var distancia := absf(_jogador.global_position.x - _oponente.global_position.x)
	var jogador_atacando := _jogador.is_in_startup_frames() or _jogador.is_in_active_frames()
	if jogador_atacando and not _ia_ataque_observado:
		_ia_ataque_observado = true
		var tipo_jogador := _jogador._current_attack
		var alcance_reacao := 170.0 if tipo_jogador == "special" else 132.0
		var prob_base := 0.10
		var prob_etapa := 0.013
		var prob_teto := 0.14
		if _dificuldade_ia == 1:
			prob_base = 0.26
			prob_etapa = 0.025
			prob_teto = 0.34
		elif _dificuldade_ia >= 2:
			prob_base = 0.45
			prob_etapa = 0.035
			prob_teto = 0.55
		var probabilidade_leitura := 0.30 if _modo_treino else minf(prob_teto, prob_base + float(_bracket_etapa) * prob_etapa)
		if distancia <= alcance_reacao and _rng.randf() < probabilidade_leitura:
			if tipo_jogador == "throw":
				_ia_reacao_bloqueio = -1.0
			else:
				_ia_reacao_bloqueio = _tempo_reacao_ia()
				_ia_bloqueio_agachado = tipo_jogador == "low_kick"
	elif not jogador_atacando:
		_ia_ataque_observado = false
		_ia_reacao_bloqueio = -1.0

	if _ia_reacao_bloqueio >= 0.0:
		_ia_reacao_bloqueio = maxf(_ia_reacao_bloqueio - delta_ia, 0.0)
		if _ia_reacao_bloqueio <= 0.0:
			var dur_bloq := 0.14 if _dificuldade_ia == 0 else (0.20 if _dificuldade_ia == 1 else 0.24)
			_bloqueio_ia = maxf(_bloqueio_ia, dur_bloq)
			_ia_reacao_bloqueio = -1.0

	var direcao_ataque := signf(_jogador.global_position.x - _oponente.global_position.x)
	if _dificuldade_ia >= 2 and _jogador.is_in_active_frames() and _jogador._current_attack == "throw" and distancia < 76.0:
		return -direcao_ataque

	if _ia_proximo_golpe <= 0.0 and _bloqueio_ia <= 0.0 and not _oponente.is_busy_attacking():
		var tipo_ataque := ""
		var chance_especial := 0.18 if _dificuldade_ia == 0 else (0.48 if _dificuldade_ia == 1 else 0.78)
		var chance_quebra_guarda := 0.06 if _dificuldade_ia == 0 else (0.28 if _dificuldade_ia == 1 else 0.62)
		var chance_punicao := 0.0 if _dificuldade_ia == 0 else (0.55 if _dificuldade_ia == 1 else 0.85)
		if _oponente.can_use_special() and not _jogador.blocking and (
			_jogador.is_in_recovery_frames() or distancia > 185.0
		) and _rng.randf() < chance_especial:
			tipo_ataque = "special"
		elif _jogador.blocking and _rng.randf() < chance_quebra_guarda:
			if distancia < 58.0 and _ia_golpe_ao_alcance("throw"):
				tipo_ataque = "throw"
			elif not _jogador.crouching and _ia_golpe_ao_alcance("low_kick"):
				tipo_ataque = "low_kick"
		elif _jogador.is_in_recovery_frames() and _rng.randf() < chance_punicao:
			if _ia_golpe_ao_alcance("kick"):
				tipo_ataque = "kick"
			elif _ia_golpe_ao_alcance("punch"):
				tipo_ataque = "punch"
		elif _ia_golpe_ao_alcance("kick") and _rng.randf() < (0.35 if _dificuldade_ia == 0 else (0.55 if _dificuldade_ia == 1 else 0.65)):
			tipo_ataque = "kick"
		elif _ia_golpe_ao_alcance("punch"):
			tipo_ataque = "punch"

		if not tipo_ataque.is_empty() and _executar_ataque(_oponente, _jogador, tipo_ataque) > 0:
			var reducao := float(_bracket_etapa) * 0.03
			match _dificuldade_ia:
				0: # EASY — fôlego generoso entre ataques da IA
					_ia_proximo_golpe = _rng.randf_range(maxf(0.70, 0.85 - reducao), maxf(0.95, 1.25 - reducao))
				1: # INTERMEDIATE — ritmo equilibrado
					_ia_proximo_golpe = _rng.randf_range(maxf(0.36, 0.48 - reducao), maxf(0.52, 0.72 - reducao))
				_: # HARD — ritmo arcade intenso
					_ia_proximo_golpe = _rng.randf_range(maxf(0.18, 0.26 - reducao), maxf(0.26, 0.40 - reducao))

	var distancia_objetivo := 54.0 if _jogador.blocking else (96.0 if _dificuldade_ia == 0 else (82.0 if _dificuldade_ia == 1 else 76.0))
	if distancia > distancia_objetivo:
		return direcao_ataque
	return 0.0

func _executar_ataque(atacante: TongobrigaChampion, alvo: TongobrigaChampion, tipo: String) -> int:
	if atacante == null or alvo == null:
		return 0
	var iniciou := atacante.attack(alvo, tipo)

	if tipo == "special" and iniciou > 0:
		_anunciar_especial(atacante.special_name)
		_shake(0.25, 5.0)
		if _stage_director != null:
			_stage_director.trigger_crowd_cheer(1.4, true)
		mensagem_label.text = "⚡ %s disparou %s!" % [atacante.champion_name, atacante.special_name]
		return iniciou

	return iniciou

func _ao_golpe_conectado(atacante: TongobrigaChampion, _alvo: TongobrigaChampion, tipo: String, dano: int, bloqueado: bool) -> void:
	_treino_regen_timer = 2.0
	var nomes_golpe := {
		"punch": "golpe rápido",
		"kick": "pontapé pesado",
		"low_kick": "rasteira baixa",
		"air_punch": "ataque aéreo",
		"air_kick": "voadora",
		"throw": "agarrão",
		"special": "super especial"
	}
	var nome_golpe: String = nomes_golpe.get(tipo, tipo)

	if bloqueado:
		_shake(0.06, 1.5)
		mensagem_label.text = "🛡️ Defesa firme contra %s de %s! (-%d chip)" % [nome_golpe, atacante.champion_name, dano]
		return

	if tipo in ["kick", "low_kick", "throw"]:
		_shake(0.14, 3.2)
		if _stage_director != null:
			_stage_director.trigger_crowd_cheer(0.85, false)
	else:
		_shake(0.08, 1.8)

	if atacante == _jogador:
		_combo_count += 1
		_combo_timer = 1.15
		if _combo_count >= 2:
			combo_label.visible = true
			combo_label.text = "%d HITS COMBO!" % _combo_count
			combo_label.scale = Vector2(1.3, 1.3)
			var tw := create_tween()
			tw.tween_property(combo_label, "scale", Vector2.ONE, 0.15)
			if _combo_count >= 3 and _stage_director != null:
				_stage_director.trigger_crowd_cheer(1.1, true)

	mensagem_label.text = "💥 %s conectou %s! (%d de dano)" % [
		atacante.champion_name,
		nome_golpe,
		dano,
	]

func _anunciar_especial(nome_especial: String) -> void:
	banner_arcade.visible = true
	banner_arcade.text = "★ " + nome_especial.to_upper() + " ★"
	banner_arcade.modulate = Color(1.0, 0.85, 0.2)
	banner_arcade.scale = Vector2(1.2, 1.2)
	var tw := create_tween()
	tw.tween_property(banner_arcade, "scale", Vector2.ONE, 0.2)
	await tw.finished
	await get_tree().create_timer(0.6).timeout
	if is_inside_tree() and not _match_finalizado:
		banner_arcade.visible = false

func _ao_vida_mudada(campeao: TongobrigaChampion, _extra: Variant = null) -> void:
	if campeao == _jogador:
		var novo_hp_p1 := float(_jogador.health)
		if novo_hp_p1 >= vida_jogador.value:
			if _tween_vida_p1 != null and _tween_vida_p1.is_valid():
				_tween_vida_p1.kill()
			vida_jogador.value = novo_hp_p1
			vida_dano_jogador.value = novo_hp_p1
			return
		_shake_hud_p1(0.22, 4.0)
		_flash_p1_timer = 0.14
		vida_jogador.modulate = Color(2.6, 2.6, 2.0, 1.0)
		var tw_flash := create_tween()
		tw_flash.tween_property(vida_jogador, "modulate", Color.WHITE, 0.14)

		var tw_amarelo := create_tween()
		tw_amarelo.tween_property(vida_jogador, "value", novo_hp_p1, 0.05)

		if _tween_vida_p1 != null and _tween_vida_p1.is_valid():
			_tween_vida_p1.kill()
		_tween_vida_p1 = create_tween()
		_tween_vida_p1.tween_interval(0.32)
		_tween_vida_p1.tween_property(vida_dano_jogador, "value", novo_hp_p1, 0.40).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	else:
		var novo_hp_p2 := float(_oponente.health)
		if novo_hp_p2 >= vida_oponente.value:
			if _tween_vida_p2 != null and _tween_vida_p2.is_valid():
				_tween_vida_p2.kill()
			vida_oponente.value = novo_hp_p2
			vida_dano_oponente.value = novo_hp_p2
			return
		_shake_hud_p2(0.22, 4.0)
		_flash_p2_timer = 0.14
		vida_oponente.modulate = Color(2.6, 2.6, 2.0, 1.0)
		var tw_flash := create_tween()
		tw_flash.tween_property(vida_oponente, "modulate", Color.WHITE, 0.14)

		var tw_amarelo := create_tween()
		tw_amarelo.tween_property(vida_oponente, "value", novo_hp_p2, 0.05)

		if _tween_vida_p2 != null and _tween_vida_p2.is_valid():
			_tween_vida_p2.kill()
		_tween_vida_p2 = create_tween()
		_tween_vida_p2.tween_interval(0.32)
		_tween_vida_p2.tween_property(vida_dano_oponente, "value", novo_hp_p2, 0.40).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)

func _atualizar_especial_ui() -> void:
	if _jogador != null and especial_jogador_barra != null:
		especial_jogador_barra.value = _jogador.special_gauge
		if _jogador.can_use_special():
			if not _especial_estava_pronto:
				_especial_estava_pronto = true
				if get_node_or_null("/root/AudioManager") != null:
					get_node("/root/AudioManager").tocar_sfx("especial_pronto")

			var t := fmod(Time.get_ticks_msec() * 0.006, 1.0)
			var pulso := sin(t * TAU) * 0.5 + 0.5
			especial_jogador_barra.modulate = Color(1.0, 0.92, 0.25).lerp(Color(0.2, 0.95, 1.0), pulso)
			especial_label.text = "⚡ SUPER ARCANO CHEIO! PRIME [I] ⚡"
			especial_label.modulate = Color(1.0, 0.92, 0.25).lerp(Color(1.0, 0.4, 0.1), pulso)
		else:
			_especial_estava_pronto = false
			especial_jogador_barra.modulate = Color.WHITE
			especial_label.text = "⚡ ESPECIAL ARCANO: %d%%" % roundi(_jogador.special_gauge)
			especial_label.modulate = Color(1.0, 0.9, 0.4)

	if _oponente != null and especial_oponente_barra != null:
		especial_oponente_barra.value = _oponente.special_gauge
		if _oponente.can_use_special():
			var t := fmod(Time.get_ticks_msec() * 0.006, 1.0)
			especial_oponente_barra.modulate = Color(1.0, 0.35, 0.2).lerp(Color(1.0, 0.85, 0.2), sin(t * TAU) * 0.5 + 0.5)
		else:
			especial_oponente_barra.modulate = Color.WHITE

func _shake_hud_p1(dur: float, amount: float) -> void:
	_shake_hud_p1_timer = dur
	_shake_hud_p1_amount = amount

func _shake_hud_p2(dur: float, amount: float) -> void:
	_shake_hud_p2_timer = dur
	_shake_hud_p2_amount = amount

func _shake(duration: float, amount: float) -> void:
	_shake_timer = duration
	_shake_amount = amount

func _tempo_esgotado() -> void:
	if _match_finalizado:
		return
	_match_finalizado = true
	_lutadores_travados = true
	banner_arcade.visible = true
	banner_arcade.text = "TIME OVER!"
	banner_arcade.modulate = Color(1.0, 0.8, 0.1)

	await get_tree().create_timer(1.2).timeout
	if not is_inside_tree():
		return

	if _jogador.health >= _oponente.health:
		_finalizar_ronda(true)
	else:
		_finalizar_ronda(false)

func _ao_lutador_derrotado(derrotado: TongobrigaChampion) -> void:
	if _match_finalizado or not _jogo_ativo:
		return
	_match_finalizado = true
	_lutadores_travados = true

	if _stage_director != null:
		_stage_director.trigger_crowd_cheer(2.2, true)
	AudioManager.tocar_voz("announcer_ko", 2.5, 1.0, true)

	_shake(0.4, 7.0)
	banner_arcade.visible = true
	banner_arcade.text = "K.O. DE TREINO!" if _modo_treino else "K. O. !"
	banner_arcade.modulate = Color(0.3, 0.95, 1.0) if _modo_treino else Color(1.0, 0.15, 0.1)
	banner_arcade.scale = Vector2(2.2, 2.2)

	var tw := create_tween()
	tw.tween_property(banner_arcade, "scale", Vector2.ONE, 0.2).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

	await tw.finished
	await get_tree().create_timer(0.85 if _modo_treino else 1.2).timeout
	if not is_inside_tree():
		return

	if _modo_treino:
		if _jogador != null:
			_jogador.heal(_jogador.max_health)
			_jogador.special_gauge = 100.0
		if _oponente != null:
			_oponente.heal(_oponente.max_health)
		_atualizar_especial_ui()
		banner_arcade.visible = false
		_match_finalizado = false
		_lutadores_travados = false
		mensagem_label.text = "Boneco recuperado! [F4] Trocar Arena · [F6] Trocar Rival · [F2] Caixas."
		return

	if derrotado == _oponente:
		_finalizar_ronda(true)
	else:
		_finalizar_ronda(false)

func _finalizar_ronda(vitoria: bool) -> void:
	if vitoria:
		_rounds_p1 += 1
		vitorias_p1_label.text = _formatar_rounds(_rounds_p1)
		var is_perfect := (_jogador != null and _jogador.health >= _jogador.max_health)
		if is_perfect:
			AudioManager.tocar_voz("announcer_perfect", 2.5, 1.0, true)
			banner_arcade.text = "PERFECT! %s VENCE O ROUND!" % _jogador.champion_name.to_upper()
		else:
			banner_arcade.text = "%s VENCE O ROUND!" % _jogador.champion_name.to_upper()
		banner_arcade.modulate = Color(1.0, 0.88, 0.2)
	else:
		_rounds_p2 += 1
		vitorias_p2_label.text = _formatar_rounds(_rounds_p2)
		banner_arcade.text = "%s VENCE O ROUND!" % _oponente.champion_name.to_upper()
		banner_arcade.modulate = Color(1.0, 0.35, 0.25)

	# Checar se alguém atingiu a condição de vitória da Melhor de Três (FT2)
	if _rounds_p1 >= ROUNDS_PARA_VENCER:
		mensagem_label.text = "🏆 %s venceu o confronto por %d a %d!" % [_jogador.champion_name, _rounds_p1, _rounds_p2]
		banner_arcade.text = "%s VENCE O COMBATE!" % _jogador.champion_name.to_upper()
		banner_arcade.modulate = Color(1.0, 0.9, 0.2)
		await get_tree().create_timer(1.6).timeout
		if not is_inside_tree():
			return
		_ao_vencer_partida_bracket()
	elif _rounds_p2 >= ROUNDS_PARA_VENCER:
		mensagem_label.text = "Derrota no confronto por %d a %d." % [_rounds_p1, _rounds_p2]
		banner_arcade.text = "DERROTA!"
		banner_arcade.modulate = Color(0.95, 0.2, 0.2)
		await get_tree().create_timer(1.6).timeout
		if not is_inside_tree():
			return
		_mostrar_modal_derrota("Foste eliminado do Torneio por %s (%d a %d)." % [_oponente.champion_name, _rounds_p2, _rounds_p1])
	else:
		# Empate 1-1 ou 1-0: Próximo Round
		if _rounds_p1 == 1 and _rounds_p2 == 1:
			_round_num = 3
		else:
			_round_num = 2
		await get_tree().create_timer(1.4).timeout
		if not is_inside_tree():
			return
		if _round_num == 3:
			_avancar_para_proximo_round("FINAL ROUND", "announcer_final_round")
		else:
			_avancar_para_proximo_round("ROUND 2", "announcer_round_2")

func _avancar_para_proximo_round(texto_round: String, vox: String) -> void:
	_tempo_ronda = 99.0
	_ultimo_segundo_alerta = -1
	_match_finalizado = false
	_lutadores_travados = true

	if _tween_vida_p1 != null and _tween_vida_p1.is_valid():
		_tween_vida_p1.kill()
	if _tween_vida_p2 != null and _tween_vida_p2.is_valid():
		_tween_vida_p2.kill()

	if _jogador != null:
		_jogador.reset_for_new_round(Vector2(190.0, 304.0), 1.0)
		vida_jogador.value = _jogador.health
		vida_dano_jogador.value = _jogador.health
	if _oponente != null:
		_oponente.reset_for_new_round(Vector2(450.0, 304.0), -1.0)
		vida_oponente.value = _oponente.health
		vida_dano_oponente.value = _oponente.health

	round_info_label.text = texto_round
	mensagem_label.text = "⚔️ %s! O vencedor deste round decide o destino da arena!" % texto_round
	_tocar_anuncio_arcade(texto_round, "FIGHT!", vox)

func _ao_vencer_partida_bracket() -> void:
	var partida: Dictionary = _obter_partida_atual_do_jogador()
	partida["score"] = [_rounds_p1, _rounds_p2]
	partida["winner"] = _escolhido

	match _bracket_etapa:
		0:
			# Passou das Quartas -> Semifinais
			_bracket_semis[0]["p1"] = _escolhido
			_bracket_etapa = 1
			AudioManager.tocar_sfx("confirmar_lutador_gongo", 0.0)
			_mostrar_tela_chaveamento()
		1:
			# Passou das Semis -> Final de Tongóbriga
			_bracket_final["p1"] = _escolhido
			_bracket_etapa = 2
			AudioManager.tocar_sfx("confirmar_lutador_gongo", 0.0)
			_mostrar_tela_chaveamento()
		2:
			# Venceu a Final de Tongóbriga!
			# Revelar a Grande Final Secreta contra Marco!
			_bracket_boss["p1"] = _escolhido
			_bracket_boss["p2"] = 9 # Marco
			_bracket_etapa = 3
			AudioManager.tocar_sfx("especial_pronto", 0.0)
			_mostrar_tela_chaveamento()
		3:
			# Derrotou Marco na Grande Final! Conceder Vitória Total!
			_bracket_boss["winner"] = _escolhido
			_bracket_boss["score"] = [_rounds_p1, _rounds_p2]
			_conceder_vitoria_torneio()

func _mostrar_modal_derrota(motivo: String) -> void:
	_jogo_ativo = false
	_lutadores_travados = true
	_match_finalizado = true

	if _modal_overlay != null and is_instance_valid(_modal_overlay):
		_modal_overlay.queue_free()

	_modal_overlay = ColorRect.new()
	_modal_overlay.name = "ModalDerrota"
	_modal_overlay.color = Color(0.04, 0.02, 0.02, 0.92)
	_modal_overlay.z_index = 60
	$UI.add_child(_modal_overlay)
	_modal_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_modal_overlay.size = Vector2(640.0, 360.0)

	var center := CenterContainer.new()
	_modal_overlay.add_child(center)
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	center.size = Vector2(640.0, 360.0)
	center.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	center.size_flags_vertical = Control.SIZE_EXPAND_FILL

	var painel := PanelContainer.new()
	painel.custom_minimum_size = Vector2(460.0, 220.0)
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.12, 0.07, 0.07, 0.96)
	sb.border_color = Color(0.85, 0.25, 0.25)
	sb.set_border_width_all(2)
	sb.set_corner_radius_all(6)
	sb.content_margin_left = 20.0
	sb.content_margin_top = 16.0
	sb.content_margin_right = 20.0
	sb.content_margin_bottom = 16.0
	painel.add_theme_stylebox_override("panel", sb)
	center.add_child(painel)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 10)
	painel.add_child(vbox)

	var fonte_medieval: Font = load("res://Assets/Fonts/MedievalSharp.ttf")

	var tit := Label.new()
	tit.text = "💀 DERROTA NAS ARENAS DE TONGÓBRIGA 💀"
	tit.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	tit.add_theme_font_override("font", fonte_medieval)
	tit.add_theme_font_size_override("font_size", 14)
	tit.add_theme_color_override("font_color", Color(1.0, 0.35, 0.35))
	vbox.add_child(tit)

	var desc := Label.new()
	desc.text = motivo + "\nPodes tentar novamente esta partida na chave, reiniciar o torneio ou regressar à seleção de lutadores."
	desc.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	desc.add_theme_font_override("font", fonte_medieval)
	desc.add_theme_font_size_override("font_size", 9)
	desc.add_theme_color_override("font_color", Color(0.88, 0.82, 0.82))
	vbox.add_child(desc)

	vbox.add_child(HSeparator.new())

	var hbox_btns := HBoxContainer.new()
	hbox_btns.alignment = BoxContainer.ALIGNMENT_CENTER
	hbox_btns.add_theme_constant_override("separation", 8)

	var btn_retry := Button.new()
	btn_retry.text = "🔄 TENTAR NOVAMENTE [ENTER]"
	btn_retry.custom_minimum_size = Vector2(175.0, 28.0)
	btn_retry.focus_mode = Control.FOCUS_NONE
	btn_retry.pressed.connect(func():
		_modal_overlay.queue_free()
		_modal_overlay = null
		_iniciar_luta_do_bracket()
	)
	hbox_btns.add_child(btn_retry)

	var btn_reset := Button.new()
	btn_reset.text = "🏆 REINICIAR CHAVE"
	btn_reset.custom_minimum_size = Vector2(125.0, 28.0)
	btn_reset.focus_mode = Control.FOCUS_NONE
	btn_reset.pressed.connect(_reiniciar_torneio)
	hbox_btns.add_child(btn_reset)

	var btn_sair := Button.new()
	btn_sair.text = "🏃 VOLTAR [ESC]"
	btn_sair.custom_minimum_size = Vector2(95.0, 28.0)
	btn_sair.focus_mode = Control.FOCUS_NONE
	btn_sair.pressed.connect(_voltar_para_selecao)
	hbox_btns.add_child(btn_sair)

	vbox.add_child(hbox_btns)

func _conceder_vitoria_torneio() -> void:
	_jogo_ativo = false
	_lutadores_travados = true
	_match_finalizado = true

	var cm := get_node_or_null("/root/CampaignManager")
	var desbloqueou_marco_agora := false
	var dia_val: int = 1
	if cm != null:
		if "marco_lutador_desbloqueado" in cm:
			desbloqueou_marco_agora = not cm.marco_lutador_desbloqueado
			cm.marco_lutador_desbloqueado = true
		if "dia" in cm:
			dia_val = int(cm.dia)

	var premio_ouro := 350 + dia_val * 25
	var inv := get_node_or_null("/root/InventoryManager")
	if inv != null:
		if "escudos" in inv:
			inv.escudos += premio_ouro
		if inv.has_method("adicionar_item_ouro"):
			inv.adicionar_item_ouro("flor_de_urze", 3)
			inv.adicionar_item_ouro("musgo_aboboreira", 2)
			inv.adicionar_item_ouro("erva_estrela", 2)
		if inv.has_method("adicionar_renome"):
			inv.adicionar_renome(50)

	var am := get_node_or_null("/root/AudioManager")
	if am != null:
		am.parar_bgm()
		am.tocar_sfx("fanfarra_vitoria")

	var overlay := ColorRect.new()
	overlay.name = "ModalVitoria"
	overlay.color = Color(0.02, 0.02, 0.03, 0.88)
	overlay.z_index = 60
	$UI.add_child(overlay)
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay.size = Vector2(640.0, 360.0)

	var center := CenterContainer.new()
	overlay.add_child(center)
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	center.size = Vector2(640.0, 360.0)
	center.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	center.size_flags_vertical = Control.SIZE_EXPAND_FILL

	var painel := PanelContainer.new()
	painel.custom_minimum_size = Vector2(500.0, 282.0)
	var style := StyleBoxTexture.new()
	style.texture = load("res://Assets/UI/quadro_missoes_madeira.png")
	style.texture_margin_left = 24.0
	style.texture_margin_top = 34.0
	style.texture_margin_right = 24.0
	style.texture_margin_bottom = 20.0
	style.content_margin_left = 28.0
	style.content_margin_top = 34.0
	style.content_margin_right = 28.0
	style.content_margin_bottom = 20.0
	painel.add_theme_stylebox_override("panel", style)
	center.add_child(painel)

	var margem := MarginContainer.new()
	margem.add_theme_constant_override("margin_left", 6)
	margem.add_theme_constant_override("margin_top", 2)
	margem.add_theme_constant_override("margin_right", 6)
	margem.add_theme_constant_override("margin_bottom", 4)
	painel.add_child(margem)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 5)
	margem.add_child(vbox)

	var fonte_medieval: Font = load("res://Assets/Fonts/MedievalSharp.ttf")

	var titulo := Label.new()
	titulo.text = "👑 ★ GRANDE CAMPEÃO DAS 4 ARENAS DE TONGÓBRIGA! ★ 🏆"
	titulo.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	titulo.add_theme_font_override("font", fonte_medieval)
	titulo.add_theme_font_size_override("font_size", 14)
	titulo.add_theme_color_override("font_color", Color(1.0, 0.88, 0.28))
	vbox.add_child(titulo)

	var sub := Label.new()
	sub.text = "%s triunfou no Castro, nas Termas, na Ponte do Tâmega e na Praça contra Marco!" % _jogador.champion_name
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sub.add_theme_font_override("font", fonte_medieval)
	sub.add_theme_font_size_override("font_size", 10)
	sub.add_theme_color_override("font_color", Color(0.92, 0.88, 0.78))
	vbox.add_child(sub)

	vbox.add_child(HSeparator.new())

	var hbox := HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 14)

	var tex_rect := TextureRect.new()
	tex_rect.custom_minimum_size = Vector2(80.0, 80.0)
	tex_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	tex_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	var p_tex := _carregar_retrato_seguro(str(CHAMPIONS[_escolhido].get("portrait", "")))
	if p_tex != null:
		tex_rect.texture = p_tex
	hbox.add_child(tex_rect)

	var v_recompensas := VBoxContainer.new()
	v_recompensas.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	var lbl_rec_titulo := Label.new()
	lbl_rec_titulo.text = "✦ RECOMPENSAS ADICIONADAS À BOTICA ✦"
	lbl_rec_titulo.add_theme_font_override("font", fonte_medieval)
	lbl_rec_titulo.add_theme_font_size_override("font_size", 10)
	lbl_rec_titulo.add_theme_color_override("font_color", Color(0.4, 0.95, 1.0))
	v_recompensas.add_child(lbl_rec_titulo)

	var linhas_rec: Array[Array] = [
		["💰 +%d Escudos de Ouro" % premio_ouro, Color(1.0, 0.92, 0.35)],
		["🌿 3x Flor de Urze + 2x Musgo + 2x Erva Estrela (Ouro)", Color(0.4, 1.0, 0.5)],
		["👑 +50 Fama Mercantil em Marco de Canaveses", Color(1.0, 0.7, 0.25)],
	]
	if desbloqueou_marco_agora:
		linhas_rec.append(["🔓 LUTADOR SECRETO DESBLOQUEADO: MESTRE ALQUIMISTA MARCO!", Color(0.35, 1.0, 0.85)])

	for item in linhas_rec:
		var rl := Label.new()
		rl.text = str(item[0])
		rl.add_theme_font_override("font", fonte_medieval)
		rl.add_theme_font_size_override("font_size", 10)
		rl.add_theme_color_override("font_color", item[1])
		v_recompensas.add_child(rl)

	hbox.add_child(v_recompensas)
	vbox.add_child(hbox)

	vbox.add_child(HSeparator.new())

	var btn_sair := Button.new()
	btn_sair.text = "COLETAR RECOMPENSAS E REGRESSAR À PRAÇA / LOJA [ENTER] 🏆"
	btn_sair.custom_minimum_size = Vector2(0.0, 30.0)
	btn_sair.focus_mode = Control.FOCUS_NONE
	btn_sair.add_theme_font_override("font", fonte_medieval)
	btn_sair.add_theme_font_size_override("font_size", 11)
	btn_sair.pressed.connect(_sair_para_praca)
	vbox.add_child(btn_sair)

	overlay.modulate = Color(1.0, 1.0, 1.0, 0.0)
	var tw := create_tween()
	tw.tween_property(overlay, "modulate:a", 1.0, 0.35)

func _terminar_torneio(_vitoria: bool, msg: String) -> void:
	_mostrar_modal_derrota(msg)

func _sair_para_praca() -> void:
	AudioManager.parar_bgm()
	SceneRouter.ir_para(PLAZA_SCENE, Vector2(178.0, 156.0))

func _formatar_rounds(qtd: int) -> String:
	var res := ""
	for i in range(ROUNDS_PARA_VENCER):
		if i < qtd:
			res += "🟡 "
		else:
			res += "⚪ "
	return res.strip_edges()

func _formatar_vitorias(qtd: int) -> String:
	return _formatar_rounds(qtd)
