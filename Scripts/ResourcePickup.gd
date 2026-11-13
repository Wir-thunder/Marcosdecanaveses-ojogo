extends Area2D

enum Tipo { INGREDIENTE, ESCUDOS }

const CRISTAL_PIXEL: Texture2D = preload("res://Assets/Environment/items/cristal_pixel.png")
const MOEDA_PIXEL: Texture2D = preload("res://Assets/Environment/items/moeda_pixel.png")
const CENA_TIMING: PackedScene = preload("res://Cenas/ColheitaTimingUI.tscn")

@export var tipo: Tipo = Tipo.INGREDIENTE
@export var item_id: String = ""
@export var recolha_id: String = ""
@export var nome_exibicao: String = ""
@export_range(1, 99) var quantidade: int = 1
@export var cor: Color = Color(0.52, 0.78, 0.42, 1.0)
@export var requer_timing: bool = false

@onready var icone: Sprite2D = $Icone
@onready var etiqueta: Label = $Etiqueta

var _em_colheita: bool = false
var _tempo_anim: float = 0.0
var _pos_icone_base: Vector2 = Vector2.ZERO
var _escala_icone_base: Vector2 = Vector2.ONE

func _ready() -> void:
	if recolha_id.is_empty():
		push_error("O recurso %s precisa de um recolha_id único." % name)
		queue_free()
		return
	if InventoryManager.foi_recolhido(recolha_id):
		queue_free()
		return
	if tipo == Tipo.ESCUDOS:
		icone.texture = MOEDA_PIXEL
		icone.modulate = Color.WHITE
		var tam_moeda: Vector2 = icone.texture.get_size()
		if tam_moeda.x > 24.0:
			var escala_m: float = 20.0 / maxf(tam_moeda.x, tam_moeda.y)
			icone.scale = Vector2(escala_m, escala_m)
	else:
		var caminho_icone: String = "res://Assets/Icons/Ingredients/%s.png" % item_id
		var tex_ingrediente: Texture2D = null
		if ResourceLoader.exists(caminho_icone):
			tex_ingrediente = load(caminho_icone) as Texture2D
		else:
			var caminho_tres: String = "res://Recursos/Recursos_ingredientes/%s.tres" % item_id
			if ResourceLoader.exists(caminho_tres):
				var res_item := load(caminho_tres)
				if res_item != null and "icone" in res_item and res_item.icone != null:
					tex_ingrediente = res_item.icone as Texture2D
		if tex_ingrediente != null:
			icone.texture = tex_ingrediente
			icone.modulate = Color.WHITE
			var tam_tex: Vector2 = tex_ingrediente.get_size()
			var escala_i: float = 22.0 / maxf(tam_tex.x, tam_tex.y)
			icone.scale = Vector2(escala_i, escala_i)
		else:
			icone.texture = CRISTAL_PIXEL
			icone.modulate = cor
	etiqueta.text = nome_exibicao if not nome_exibicao.is_empty() else _nome()
	_pos_icone_base = icone.position
	_escala_icone_base = icone.scale
	_tempo_anim = randf_range(0.0, 6.28)
	add_to_group("interactables")

func _process(delta: float) -> void:
	_tempo_anim += delta * 2.8
	if icone != null:
		icone.position.y = _pos_icone_base.y + sin(_tempo_anim) * 2.2
		var pulso: float = 1.0 + sin(_tempo_anim * 1.5) * 0.05
		icone.scale = _escala_icone_base * pulso

func obter_texto_interacao() -> String:
	if requer_timing:
		return "E  COLHEITA DELICADA DE " + _nome()
	return "E  RECOLHER " + _nome()

func interagir(jogador: Player) -> void:
	if _em_colheita:
		return
		
	if tipo == Tipo.ESCUDOS:
		jogador.escudos += quantidade
		_finalizar_coleta(false)
		return

	if item_id.is_empty():
		push_error("O recurso %s não tem item_id configurado." % name)
		return

	if requer_timing:
		_em_colheita = true
		var ui := CENA_TIMING.instantiate() as ColheitaTimingUI
		get_tree().root.add_child(ui)
		ui.iniciar(_nome())
		var perfeito: bool = await ui.colheita_concluida
		ui.queue_free()
		
		if perfeito:
			InventoryManager.adicionar_item_ouro(item_id, quantidade)
		else:
			InventoryManager.adicionar_item(item_id, quantidade)
		_finalizar_coleta(perfeito)
	else:
		InventoryManager.adicionar_item(item_id, quantidade)
		_finalizar_coleta(false)

func _finalizar_coleta(perfeito: bool) -> void:
	InventoryManager.marcar_recolhido(recolha_id)
	var mensagem: String
	if tipo == Tipo.ESCUDOS:
		AudioManager.tocar_sfx("moedas")
		mensagem = "Encontraste %d escudos." % quantidade
	elif perfeito:
		AudioManager.tocar_sfx("colheita_perfeita")
		mensagem = "✨ COLHEITA PERFEITA! Obtiveste %s [OURO] ×%d!" % [_nome(), quantidade]
	else:
		AudioManager.tocar_sfx("colheita_sucesso")
		mensagem = "Recolheste %s ×%d." % [_nome(), quantidade]
		
	var cena_atual := get_tree().current_scene
	if cena_atual != null and cena_atual.has_method("mostrar_mensagem"):
		cena_atual.call("mostrar_mensagem", mensagem)
	queue_free()

func _nome() -> String:
	if not nome_exibicao.is_empty():
		return nome_exibicao
	if tipo == Tipo.ESCUDOS:
		return "ouro"
	return item_id.replace("_", " ").capitalize()
