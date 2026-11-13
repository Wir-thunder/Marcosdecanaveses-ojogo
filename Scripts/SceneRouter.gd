extends Node

const DURACAO_FADE: float = 0.22

var _entrada_pendente: bool = false
var _posicao_entrada: Vector2 = Vector2.ZERO
var _transicao_em_andamento: bool = false
var _fade_layer: CanvasLayer = null
var _fade_rect: ColorRect = null

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_criar_overlay_fade()

func _criar_overlay_fade() -> void:
	_fade_layer = CanvasLayer.new()
	_fade_layer.name = "SceneFadeLayer"
	_fade_layer.layer = 100
	add_child(_fade_layer)

	_fade_rect = ColorRect.new()
	_fade_rect.name = "FadeRect"
	_fade_rect.color = Color(0.03, 0.02, 0.02, 0.0)
	_fade_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_fade_rect.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_fade_layer.add_child(_fade_rect)

func ir_para(caminho_cena: String, posicao_entrada: Vector2, auto_salvar: bool = true) -> void:
	if _transicao_em_andamento:
		return
	if not ResourceLoader.exists(caminho_cena):
		push_error("Cena de destino não encontrada: " + caminho_cena)
		return

	if auto_salvar and has_node("/root/SaveManager"):
		get_node("/root/SaveManager").salvar_jogo()

	_posicao_entrada = posicao_entrada
	_entrada_pendente = true
	_transicao_em_andamento = true
	call_deferred("_mudar_cena_com_fade", caminho_cena)

func consumir_entrada(posicao_padrao: Vector2) -> Vector2:
	if not _entrada_pendente:
		return posicao_padrao

	_entrada_pendente = false
	if _posicao_entrada == Vector2.ZERO:
		return posicao_padrao
	return _posicao_entrada

func _mudar_cena_com_fade(caminho_cena: String) -> void:
	if _fade_rect != null:
		_fade_rect.mouse_filter = Control.MOUSE_FILTER_STOP
		var tween_out := create_tween()
		tween_out.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
		tween_out.tween_property(_fade_rect, "color:a", 1.0, DURACAO_FADE).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
		await tween_out.finished

	var erro := get_tree().change_scene_to_file(caminho_cena)
	if erro != OK:
		_entrada_pendente = false
		push_error("Não foi possível carregar a cena: %s (erro %d)." % [caminho_cena, erro])

	await get_tree().process_frame

	if _fade_rect != null:
		var tween_in := create_tween()
		tween_in.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
		tween_in.tween_property(_fade_rect, "color:a", 0.0, DURACAO_FADE).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
		await tween_in.finished
		_fade_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE

	_transicao_em_andamento = false
