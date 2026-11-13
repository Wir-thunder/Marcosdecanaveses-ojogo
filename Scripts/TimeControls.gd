extends HBoxContainer

@onready var play_button: Button = $Play
@onready var pause_button: Button = $Pause
@onready var accelerate_button: Button = $Accelerate

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	for btn: Button in [play_button, accelerate_button, pause_button]:
		btn.focus_mode = Control.FOCUS_NONE
		btn.custom_minimum_size = Vector2(26.0, 20.0)
		btn.add_theme_font_size_override("font_size", 10)
	play_button.pressed.connect(_play)
	accelerate_button.pressed.connect(_accelerate)
	pause_button.pressed.connect(_pause)
	_atualizar_botoes()

func _process(_delta: float) -> void:
	_atualizar_botoes()

func _play() -> void:
	if CampaignManager.fase == CampaignManager.Fase.MANHA:
		CampaignManager.iniciar_turno_loja()
	if CampaignManager.velocidade_acelerada:
		CampaignManager.alternar_velocidade()
	var cena := get_tree().current_scene
	if cena != null and cena.has_method("retomar_jogo"):
		cena.retomar_jogo()
	else:
		get_tree().paused = false
	_atualizar_botoes()

func _pause() -> void:
	var cena := get_tree().current_scene
	if get_tree().paused:
		if cena != null and cena.has_method("retomar_jogo"):
			cena.retomar_jogo()
		else:
			get_tree().paused = false
	else:
		if cena != null and cena.has_method("pausar_jogo"):
			cena.pausar_jogo()
		else:
			get_tree().paused = true
	_atualizar_botoes()

func _accelerate() -> void:
	if CampaignManager.fase == CampaignManager.Fase.MANHA:
		CampaignManager.iniciar_turno_loja()
	if get_tree().paused:
		var cena := get_tree().current_scene
		if cena != null and cena.has_method("retomar_jogo"):
			cena.retomar_jogo()
		else:
			get_tree().paused = false
	if not CampaignManager.velocidade_acelerada:
		CampaignManager.alternar_velocidade()
	else:
		CampaignManager.alternar_velocidade()
	_atualizar_botoes()

func _atualizar_botoes() -> void:
	play_button.text = ">"
	accelerate_button.text = ">>"
	pause_button.text = "II"

	var pausado := get_tree().paused
	var em_manha := CampaignManager.fase == CampaignManager.Fase.MANHA
	var rapido := CampaignManager.velocidade_acelerada

	play_button.modulate = Color(1.0, 0.9, 0.45, 1.0) if (not pausado and not em_manha and not rapido) else Color(0.85, 0.82, 0.75, 0.9)
	accelerate_button.modulate = Color(1.0, 0.9, 0.45, 1.0) if (not pausado and rapido) else Color(0.85, 0.82, 0.75, 0.9)
	pause_button.modulate = Color(1.0, 0.75, 0.35, 1.0) if pausado else Color(0.85, 0.82, 0.75, 0.9)

	play_button.tooltip_text = "Iniciar / Velocidade 1× (>)"
	accelerate_button.tooltip_text = "Velocidade 2× (>>)"
	pause_button.tooltip_text = "Pausar / Retomar (II)"
