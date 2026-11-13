class_name MoitaCamuflagem extends Area2D

@onready var feedback_label: Label = $Feedback
@onready var particulas: CPUParticles2D = $Folhas

func _ready() -> void:
	body_entered.connect(_ao_entrar)
	body_exited.connect(_ao_sair)
	if feedback_label != null:
		feedback_label.visible = false

func _ao_entrar(body: Node2D) -> void:
	if body.is_in_group("player") and body.has_method("set_escondido"):
		body.set_escondido(true)
		AudioManager.tocar_sfx("moita_farfalhar")
		if feedback_label != null:
			feedback_label.text = "🌿 ESCONDIDO"
			feedback_label.visible = true
		if particulas != null:
			particulas.emitting = true

func _ao_sair(body: Node2D) -> void:
	if body.is_in_group("player") and body.has_method("set_escondido"):
		body.set_escondido(false)
		if feedback_label != null:
			feedback_label.visible = false

