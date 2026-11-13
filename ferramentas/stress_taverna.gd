extends SceneTree

func _initialize() -> void:
	print("Starting Taverna stress & interaction test...")
	var packed: PackedScene = load("res://Cenas/Taverna.tscn")
	var inst: Node = packed.instantiate()
	root.add_child(inst)

	for i in 10:
		await process_frame

	print("Testing movement...")
	for action in ["mover_direita", "mover_esquerda", "mover_cima", "mover_baixo"]:
		Input.action_press(action)
		for i in 15:
			await physics_frame
		Input.action_release(action)

	print("Testing keys Q, B, D, Tab, Esc...")
	var ev_q := InputEventKey.new()
	ev_q.keycode = KEY_Q
	ev_q.pressed = true
	root.push_input(ev_q)
	for i in 5: await process_frame
	ev_q.pressed = false
	root.push_input(ev_q)

	var ev_tab := InputEventKey.new()
	ev_tab.keycode = KEY_TAB
	ev_tab.pressed = true
	root.push_input(ev_tab)
	for i in 5: await process_frame
	ev_tab.pressed = false
	root.push_input(ev_tab)

	var ev_b := InputEventKey.new()
	ev_b.keycode = KEY_B
	ev_b.pressed = true
	root.push_input(ev_b)
	for i in 5: await process_frame

	var ev_d := InputEventKey.new()
	ev_d.keycode = KEY_D
	ev_d.pressed = true
	root.push_input(ev_d)
	for i in 5: await process_frame

	var ev_esc := InputEventKey.new()
	ev_esc.keycode = KEY_ESCAPE
	ev_esc.pressed = true
	root.push_input(ev_esc)
	for i in 5: await process_frame

	print("Testing E interaction near interactables...")
	var pl: Node2D = inst.get_node_or_null("YSort/Player") as Node2D
	if pl != null:
		# Teleport near Quadro
		pl.global_position = Vector2(75, 230)
		for i in 5: await physics_frame
		Input.action_press("interact")
		await physics_frame
		Input.action_release("interact")
		for i in 5: await process_frame

		# Teleport near Balcao
		pl.global_position = Vector2(240, 240)
		for i in 5: await physics_frame
		Input.action_press("interact")
		await physics_frame
		Input.action_release("interact")
		for i in 5: await process_frame

		# Teleport near Mesa de Dados
		pl.global_position = Vector2(550, 316)
		for i in 5: await physics_frame
		Input.action_press("interact")
		await physics_frame
		Input.action_release("interact")
		for i in 5: await process_frame

		# Teleport to Porta
		pl.global_position = Vector2(145, 350)
		for i in 5: await physics_frame
		Input.action_press("interact")
		await physics_frame
		Input.action_release("interact")
		for i in 5: await process_frame

	print("Taverna test finished successfully!")
	quit(0)
