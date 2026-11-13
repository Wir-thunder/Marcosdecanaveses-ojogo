extends Control

const TONGOBRIGA_SELECT_SCENE: String = "res://Cenas/Tongobriga.tscn"

@onready var palco_cenario: Control = $PalcoCenario
@onready var cenario_arena: TextureRect = $PalcoCenario/CenarioArena
@onready var marco_sprite: TextureRect = $CampeoesCamada/MarcoSprite
@onready var decimo_sprite: TextureRect = $CampeoesCamada/DecimoSprite
@onready var banner_titulo: PanelContainer = $BannerTitulo
@onready var legenda_narrativa: Label = $BarraBase/LegendaNarrativa
@onready var clarao: ColorRect = $Clarao
@onready var dica_pular: Label = $DicaPular

var _transicao_em_curso: bool = false
var _tw_sequencia: Tween

func _ready() -> void:
	if CampaignManager.tongobriga_intro_vista:
		SceneRouter.call_deferred("ir_para", TONGOBRIGA_SELECT_SCENE)
		return
	CampaignManager.tongobriga_intro_vista = true
	SaveManager.salvar_jogo()
	_iniciar_animacoes()

	if dica_pular != null:
		var tw_dica := create_tween().set_loops()
		tw_dica.tween_property(dica_pular, "modulate:a", 0.45, 0.75)
		tw_dica.tween_property(dica_pular, "modulate:a", 1.0, 0.75)

func _iniciar_animacoes() -> void:
	# Movimento contínuo suave (Ken Burns) sobre o cenário
	if palco_cenario != null:
		var tw_cam := create_tween()
		tw_cam.set_parallel(true)
		tw_cam.tween_property(palco_cenario, "scale", Vector2(1.08, 1.08), 9.4).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		tw_cam.tween_property(palco_cenario, "position", Vector2(-8.0, -4.0), 9.4).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

	# Sequência narrativa em 3 atos
	_tw_sequencia = create_tween()

	# Ato 1 (0.0s -> 2.8s): Castro de Tongóbriga ao pôr-do-sol
	legenda_narrativa.modulate.a = 0.0
	_tw_sequencia.tween_property(legenda_narrativa, "modulate:a", 1.0, 0.6)
	_tw_sequencia.tween_interval(2.2)

	# Ato 2 (2.8s -> 6.0s): Transição para a Arena + Entrada dos Campeões
	_tw_sequencia.tween_property(legenda_narrativa, "modulate:a", 0.0, 0.25)
	_tw_sequencia.tween_callback(_atualizar_legenda.bind("Guerreiros celtas, legionários e alquimistas reúnem-se diante da Pedra Formosa."))
	_tw_sequencia.tween_property(cenario_arena, "modulate:a", 1.0, 0.9).set_trans(Tween.TRANS_SINE)
	_tw_sequencia.parallel().tween_property(legenda_narrativa, "modulate:a", 1.0, 0.45)

	# Campeões entram pelos flancos
	if marco_sprite != null and decimo_sprite != null:
		var marco_alvo_x: float = marco_sprite.position.x
		var decimo_alvo_x: float = decimo_sprite.position.x
		marco_sprite.position.x -= 48.0
		decimo_sprite.position.x += 48.0
		_tw_sequencia.parallel().tween_property(marco_sprite, "modulate:a", 1.0, 0.55)
		_tw_sequencia.parallel().tween_property(marco_sprite, "position:x", marco_alvo_x, 0.7).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		_tw_sequencia.parallel().tween_property(decimo_sprite, "modulate:a", 1.0, 0.55)
		_tw_sequencia.parallel().tween_property(decimo_sprite, "position:x", decimo_alvo_x, 0.7).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

	_tw_sequencia.tween_interval(2.1)

	# Ato 3 (6.0s -> 9.2s): Banner épico "ARENA DE TONGÓBRIGA" + clarão dourado
	_tw_sequencia.tween_callback(_disparar_clarao)
	_tw_sequencia.tween_property(legenda_narrativa, "modulate:a", 0.0, 0.2)
	_tw_sequencia.tween_callback(_atualizar_legenda.bind("Entra na arena. Só a lenda sobrevive ao juízo do aço!"))
	if banner_titulo != null:
		banner_titulo.scale = Vector2(0.86, 0.86)
		_tw_sequencia.parallel().tween_property(banner_titulo, "modulate:a", 1.0, 0.45)
		_tw_sequencia.parallel().tween_property(banner_titulo, "scale", Vector2.ONE, 0.55).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_tw_sequencia.parallel().tween_property(legenda_narrativa, "modulate:a", 1.0, 0.4)
	_tw_sequencia.tween_interval(2.4)

	# Fim automático: entra na Arena via SceneRouter (fade único)
	_tw_sequencia.tween_callback(_ir_para_arena)

func _atualizar_legenda(texto: String) -> void:
	if legenda_narrativa != null:
		legenda_narrativa.text = texto

func _disparar_clarao() -> void:
	if clarao == null:
		return
	clarao.visible = true
	clarao.color.a = 0.35
	var tw := create_tween()
	tw.tween_property(clarao, "color:a", 0.0, 0.45).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tw.tween_callback(func(): clarao.visible = false)

func _unhandled_input(event: InputEvent) -> void:
	if _transicao_em_curso:
		return

	if event is InputEventKey and event.pressed and not event.echo:
		match event.physical_keycode:
			KEY_ENTER, KEY_KP_ENTER, KEY_SPACE, KEY_ESCAPE, KEY_E:
				get_viewport().set_input_as_handled()
				_ir_para_arena()
				return

	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		get_viewport().set_input_as_handled()
		_ir_para_arena()

func _ir_para_arena() -> void:
	if _transicao_em_curso:
		return
	_transicao_em_curso = true

	if _tw_sequencia != null and _tw_sequencia.is_valid():
		_tw_sequencia.kill()

	# Fade único gerido pelo SceneRouter (sem double-fade)
	var router := get_node_or_null("/root/SceneRouter")
	if router != null:
		router.ir_para(TONGOBRIGA_SELECT_SCENE, Vector2.ZERO)
	else:
		get_tree().change_scene_to_file(TONGOBRIGA_SELECT_SCENE)
