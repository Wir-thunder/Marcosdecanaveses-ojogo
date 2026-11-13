class_name TavernaNpc extends Node2D

static var _cooldown_fala_global: float = 14.0
static var _npc_atual_falando: TavernaNpc = null

@export var nome_npc: String = "Habitante"
@export var profissao_npc: String = "Campesino"
@export var falas: Array[String] = [
	"Esta caneca de cerveja do Douro é formidável!",
	"Dizem que o torneio de Tongóbriga está renhido hoje.",
	"O alquimista Marco prepara as poções mais potentes da região!"
]
@export var intervalo_fala: float = 25.0
@export var animar_conversa: bool = true
@export var pose_indice: int = 0
@export var usar_sprite_campesino: bool = false
@export var textura_campesino: Texture2D = null

@onready var balao_label: Label = get_node_or_null("Balao/Texto")
@onready var balao_painel: PanelContainer = get_node_or_null("Balao")
@onready var anim_sprite: AnimatedSprite2D = get_node_or_null("Anim")
@onready var sprite_estatico: Sprite2D = get_node_or_null("Sprite")
@onready var sombra: Sprite2D = get_node_or_null("Sombra")

const LARGURA_CELULA: float = 128.0
const ALTURA_CELULA: float = 144.0
const OFFSET_Y_BASE: float = -36.0

var _tempo_proxima_fala: float = 0.0
var _tempo_balao_visivel: float = 0.0
var _tempo_anim: float = 0.0
var _tempo_nota: float = 1.2
var _escala_sprite_base: Vector2 = Vector2(0.58, 0.58)

func _ready() -> void:
	add_to_group("interactables")
	# Delay inicial longo e desfasado para não parecer o centro de Prontera
	_tempo_proxima_fala = randf_range(14.0, 35.0)
	_tempo_anim = randf_range(0.0, 6.28)
	
	if sombra != null:
		sombra.position = Vector2(0, 2)
		sombra.scale = Vector2(1.2, 0.6)
		sombra.modulate = Color(0, 0, 0, 0.45)
		
	if balao_painel != null:
		balao_painel.visible = false

	if sprite_estatico != null:
		if usar_sprite_campesino and textura_campesino != null:
			sprite_estatico.texture = textura_campesino
			sprite_estatico.region_enabled = false
			sprite_estatico.scale = Vector2(0.44, 0.44)
			sprite_estatico.position = Vector2(0, OFFSET_Y_BASE)
		elif sprite_estatico.region_enabled:
			sprite_estatico.region_rect = Rect2(
				float(pose_indice) * LARGURA_CELULA,
				0.0,
				LARGURA_CELULA,
				ALTURA_CELULA
			)
			sprite_estatico.position = Vector2(0, OFFSET_Y_BASE)
		_escala_sprite_base = sprite_estatico.scale

func _process(delta: float) -> void:
	_tempo_anim += delta
	_tempo_proxima_fala -= delta
	_cooldown_fala_global = maxf(_cooldown_fala_global - delta, 0.0)
	
	if animar_conversa and sprite_estatico != null:
		var eh_bardo := "bardo" in nome_npc.to_lower() or "trovador" in profissao_npc.to_lower()
		if eh_bardo:
			# Bardo apenas dedilha o alaúde suavemente sem flutuar
			sprite_estatico.rotation = sin(_tempo_anim * 2.2) * 0.03
			_tempo_nota -= delta
			if _tempo_nota <= 0.0:
				_tempo_nota = randf_range(1.5, 2.5)
				_emitir_nota_musical()
		if pose_indice == 0 and not usar_sprite_campesino and sprite_estatico.region_enabled:
			# Taberneiro limpa a caneca periodicamente sem flutuar
			var quadro_taberneiro: int = 7 if fmod(_tempo_anim, 6.0) > 3.8 else 0
			sprite_estatico.region_rect = Rect2(
				float(quadro_taberneiro) * LARGURA_CELULA,
				0.0,
				LARGURA_CELULA,
				ALTURA_CELULA
			)
		
	if _tempo_balao_visivel > 0.0:
		_tempo_balao_visivel -= delta
		if _tempo_balao_visivel <= 0.0:
			fechar_balao()
			
	if _tempo_proxima_fala <= 0.0 and not falas.is_empty():
		# Só fala espontaneamente se ninguém estiver a falar e o cooldown global da taverna tiver terminado
		if _cooldown_fala_global <= 0.0 and _npc_atual_falando == null:
			_mostrar_fala_aleatoria()
		else:
			# Adia a tentativa deste NPC para mais tarde
			_tempo_proxima_fala = randf_range(12.0, 24.0)

func obter_texto_interacao() -> String:
	return "E  FALAR COM %s (%s)" % [nome_npc.to_upper(), profissao_npc.to_upper()]

func interagir(_jogador: Node2D = null) -> void:
	if falas.is_empty() or balao_label == null or balao_painel == null:
		return
		
	# Fecha qualquer balão de conversa ambiente para focar na interação com o Marco
	if _npc_atual_falando != null and _npc_atual_falando != self and is_instance_valid(_npc_atual_falando):
		_npc_atual_falando.fechar_balao()
		
	_npc_atual_falando = self
	var fala: String = falas.pick_random()
	balao_label.text = "💬 %s: \"%s\"" % [nome_npc, fala]
	balao_painel.visible = true
	_tempo_balao_visivel = 4.5
	_cooldown_fala_global = 18.0
	_tempo_proxima_fala = randf_range(30.0, 60.0)
	
	if get_node_or_null("/root/AudioManager") != null:
		get_node("/root/AudioManager").tocar_sfx("ui_click")

func fechar_balao() -> void:
	_tempo_balao_visivel = 0.0
	if balao_painel != null:
		balao_painel.visible = false
	if _npc_atual_falando == self:
		_npc_atual_falando = null

func _mostrar_fala_aleatoria() -> void:
	if balao_label == null or balao_painel == null:
		return
	_npc_atual_falando = self
	var fala: String = falas.pick_random()
	balao_label.text = "💬 %s: \"%s\"" % [nome_npc, fala]
	balao_painel.visible = true
	_tempo_balao_visivel = 3.6
	# Cooldown de 18 a 30 segundos entre falas espontâneas em toda a taverna
	_cooldown_fala_global = randf_range(18.0, 30.0)
	_tempo_proxima_fala = randf_range(45.0, 80.0)

func falar_brinde(fala_custom: String) -> void:
	if balao_label == null or balao_painel == null:
		return
	balao_label.text = "🍻 %s: \"%s\"" % [nome_npc, fala_custom]
	balao_painel.visible = true
	_tempo_balao_visivel = 4.2
	if sprite_estatico != null:
		var tw := create_tween()
		tw.tween_property(sprite_estatico, "position:y", OFFSET_Y_BASE - 7.0, 0.12)
		tw.tween_property(sprite_estatico, "position:y", OFFSET_Y_BASE, 0.18)

func _emitir_nota_musical() -> void:
	var nota := Label.new()
	var simbolos := ["♪", "♫", "♬", "♩"]
	nota.text = simbolos.pick_random()
	nota.z_index = 18
	nota.position = Vector2(randf_range(-14.0, 14.0), -58.0)
	nota.add_theme_font_size_override("font_size", 13)
	var cores := [
		Color(1.0, 0.86, 0.42, 0.95),
		Color(0.98, 0.68, 0.35, 0.95),
		Color(0.68, 0.92, 0.78, 0.95)
	]
	nota.add_theme_color_override("font_color", cores.pick_random())
	nota.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.85))
	nota.add_theme_constant_override("shadow_offset_x", 1)
	nota.add_theme_constant_override("shadow_offset_y", 1)
	add_child(nota)
	var tw := create_tween()
	tw.set_parallel(true)
	tw.tween_property(nota, "position:y", nota.position.y - 26.0, 1.35)
	tw.tween_property(nota, "position:x", nota.position.x + randf_range(-12.0, 12.0), 1.35)
	tw.tween_property(nota, "modulate:a", 0.0, 1.35)
	tw.chain().tween_callback(nota.queue_free)
