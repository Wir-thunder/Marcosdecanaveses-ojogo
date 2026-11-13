extends SceneTree
# Renderiza uma cena e grava PNG(s).
# Uso: Godot.exe --path . -s ferramentas/captura.gd -- res://Cenas/X.tscn scratch/x.png [colisoes|sem] [frames] [acao_input] [n_capturas]
# Com acao_input (ex: mover_direita) mantém a tecla premida e grava n_capturas frames
# seguidos (x_0.png, x_1.png...) espaçados de 4 frames.

func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	var cena: String = args[0] if args.size() > 0 else "res://Cenas/PracaCentral.tscn"
	if cena == "testes_taverna":
		_capturar_testes_taverna()
		return
	if cena == "tudo":
		_capturar_tudo()
		return
	var saida: String = args[1] if args.size() > 1 else "scratch/captura.png"
	var colisoes: bool = args.size() > 2 and args[2] == "colisoes"
	var frames: int = int(args[3]) if args.size() > 3 else 20
	var acao: String = args[4] if args.size() > 4 else ""
	var n_capt: int = int(args[5]) if args.size() > 5 else 1
	debug_collisions_hint = colisoes
	var packed: PackedScene = load(cena)
	root.add_child(packed.instantiate())
	_capturar(saida, frames, acao, n_capt)

func _capturar_testes_taverna() -> void:
	# Testes de aceitação da Taverna (Etapa 1) com posicionamento coerente no chão
	debug_collisions_hint = false
	var testes := [
		{"pos": Vector2(385, 312), "nome": "scratch/taverna_teste1_player_frente_mesa.png"},
		{"pos": Vector2(415, 236), "nome": "scratch/taverna_teste2_player_atras_mesa.png"},
		{"pos": Vector2(252, 268), "nome": "scratch/taverna_teste3_player_balcao_afonso.png"},
		{"pos": Vector2(215, 275), "nome": "scratch/taverna_teste4_player_spawn_chao.png"}
	]
	for t in testes:
		var router: Node = root.get_node_or_null("SceneRouter")
		if router != null:
			router.set("posicao_alvo", Vector2.ZERO)
		var inst: Node2D = (load("res://Cenas/Taverna.tscn") as PackedScene).instantiate()
		root.add_child(inst)
		var pl: Node2D = inst.get_node_or_null("YSort/Player") as Node2D if inst.has_node("YSort/Player") else inst.get_node_or_null("Player") as Node2D
		if pl != null:
			pl.global_position = t.pos
			pl.velocity = Vector2.ZERO
		for i in 12:
			await process_frame
		_gravar(t.nome)
		inst.queue_free()
		for i in 4:
			await process_frame
	quit()

func _capturar_tudo() -> void:
	# 1. Capturar Marco andando nas 4 direções (sem caixas de colisão para ver o chapéu e os pés limpos)
	debug_collisions_hint = false
	var inst_praca: Node = (load("res://Cenas/PracaCentral.tscn") as PackedScene).instantiate()
	root.add_child(inst_praca)
	for i in 12:
		await process_frame
	for acao in ["mover_baixo", "mover_cima", "mover_esquerda", "mover_direita"]:
		Input.action_press(acao)
		for i in 10:
			await physics_frame
		_gravar("scratch/marco_%s.png" % acao)
		Input.action_release(acao)
		for i in 4:
			await physics_frame
	inst_praca.queue_free()
	for i in 4:
		await process_frame

	# 2. Capturar cenas revistas com debug_collisions_hint = true
	debug_collisions_hint = true
	var cenas := [
		["res://Cenas/Taverna.tscn", "scratch/fix_Taverna.png"],
		["res://Cenas/cena_principal.tscn", "scratch/fix_cena_principal.png"],
		["res://Cenas/MargensTamega.tscn", "scratch/fix_MargensTamega.png"],
		["res://Cenas/FeiraMedieval.tscn", "scratch/fix_FeiraMedieval.png"],
		["res://Cenas/TermasRomanas.tscn", "scratch/fix_TermasRomanas.png"],
		["res://Cenas/CriptaPedraFormosa.tscn", "scratch/fix_CriptaPedraFormosa.png"],
		["res://Cenas/Dungeon.tscn", "scratch/fix_Dungeon.png"],
	]
	for par in cenas:
		var inst: Node = (load(par[0]) as PackedScene).instantiate()
		root.add_child(inst)
		for i in 16:
			await process_frame
		_gravar(par[1])
		inst.queue_free()
		for i in 4:
			await process_frame
	quit()

func _gravar(caminho: String) -> void:
	var img := root.get_texture().get_image()
	img.save_png(ProjectSettings.globalize_path(caminho) if caminho.begins_with("res://") else caminho)
	print("CAPTURA OK ", caminho, " ", img.get_size())

func _capturar(saida: String, frames: int, acao: String, n_capt: int) -> void:
	for i in frames:
		await process_frame
	if acao.is_empty():
		_gravar(saida)
	else:
		Input.action_press(acao)
		for i in 12:
			await physics_frame
		for k in n_capt:
			for i in 4:
				await process_frame
			_gravar(saida.replace(".png", "_%d.png" % k))
		Input.action_release(acao)
	quit()
