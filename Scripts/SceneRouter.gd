extends Node

var _entrada_pendente: bool = false
var _posicao_entrada: Vector2 = Vector2.ZERO

func ir_para(caminho_cena: String, posicao_entrada: Vector2) -> void:
	if not ResourceLoader.exists(caminho_cena):
		push_error("Cena de destino não encontrada: " + caminho_cena)
		return

	_posicao_entrada = posicao_entrada
	_entrada_pendente = true
	call_deferred("_mudar_cena", caminho_cena)

func consumir_entrada(posicao_padrao: Vector2) -> Vector2:
	if not _entrada_pendente:
		return posicao_padrao

	_entrada_pendente = false
	return _posicao_entrada

func _mudar_cena(caminho_cena: String) -> void:
	var erro := get_tree().change_scene_to_file(caminho_cena)
	if erro != OK:
		_entrada_pendente = false
		push_error("Não foi possível carregar a cena: %s (erro %d)." % [caminho_cena, erro])
