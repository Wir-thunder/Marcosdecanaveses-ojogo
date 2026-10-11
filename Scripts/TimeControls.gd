extends HBoxContainer

@onready var play_button: Button = $Play
@onready var pause_button: Button = $Pause
@onready var accelerate_button: Button = $Accelerate

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	play_button.pressed.connect(_play)
	pause_button.pressed.connect(_pause)
	accelerate_button.pressed.connect(_accelerate)
	_atualizar_botoes()

func _process(_delta: float) -> void:
	_atualizar_botoes()

func _play() -> void:
	if CampaignManager.fase == CampaignManager.Fase.MANHA:
		CampaignManager.iniciar_turno_loja()
	var cena := get_tree().current_scene
	if cena != null and cena.has_method("retomar_jogo"):
		cena.retomar_jogo()
	else:
		get_tree().paused = false
	_atualizar_botoes()

func _pause() -> void:
	var cena := get_tree().current_scene
	if cena != null and cena.has_method("pausar_jogo"):
		cena.pausar_jogo()
	else:
		get_tree().paused = true
	_atualizar_botoes()

func _accelerate() -> void:
	CampaignManager.alternar_velocidade()
	_atualizar_botoes()

func _atualizar_botoes() -> void:
	play_button.disabled = (
		CampaignManager.fase != CampaignManager.Fase.MANHA
		and not get_tree().paused
	)
	pause_button.text = "PAUSADO" if get_tree().paused else "PAUSE"
	play_button.tooltip_text = (
		"Começar o atendimento"
		if CampaignManager.fase == CampaignManager.Fase.MANHA
		else "Retomar o jogo"
	)
	pause_button.tooltip_text = "Pausar o jogo"
	accelerate_button.tooltip_text = (
		"Velocidade normal" if CampaignManager.velocidade_acelerada
		else "Acelerar para 2×"
	)
	accelerate_button.text = (
		"1×" if CampaignManager.velocidade_acelerada else "2×"
	)
