extends Control

@export_file("*.tscn") var proxima_cena: String = "res://Cenas/PracaCentral.tscn"

@onready var video: VideoStreamPlayer = $Video
@onready var fader: ColorRect = $Fader

const DURACAO_FADE: float = 0.8

var _transicao_em_curso: bool = false
var _fade_entrada: Tween

func _ready() -> void:
	if not ResourceLoader.exists(proxima_cena):
		push_error("Cena de destino da introdução não encontrada: " + proxima_cena)
		return

	if video.stream == null:
		push_error("O vídeo da introdução não está configurado.")
		return

	video.finished.connect(_ao_video_terminar)
	video.play()
	_fade_entrada = create_tween()
	_fade_entrada.tween_property(fader, "color:a", 0.0, DURACAO_FADE)

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_accept") or event.is_action_pressed("interact"):
		get_viewport().set_input_as_handled()
		_transicionar_para_jogo()

func _ao_video_terminar() -> void:
	_transicionar_para_jogo()

func _transicionar_para_jogo() -> void:
	if _transicao_em_curso:
		return
	_transicao_em_curso = true
	video.stop()

	if _fade_entrada != null and _fade_entrada.is_running():
		await _fade_entrada.finished

	var fade_saida := create_tween()
	fade_saida.tween_property(fader, "color:a", 1.0, DURACAO_FADE)
	await fade_saida.finished

	var erro := get_tree().change_scene_to_file(proxima_cena)
	if erro != OK:
		push_error("Não foi possível carregar a cena após a introdução: %s (erro %d)." % [proxima_cena, erro])
