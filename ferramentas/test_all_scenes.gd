extends SceneTree

func _initialize() -> void:
	var dir := DirAccess.open("res://Cenas")
	if dir == null:
		print("DIR NULL")
		quit(1)
		return
	dir.list_dir_begin()
	var file_name := dir.get_next()
	var scenes: Array[String] = []
	while file_name != "":
		if not dir.current_is_dir() and file_name.ends_with(".tscn"):
			scenes.append("res://Cenas/" + file_name)
		file_name = dir.get_next()
	dir.list_dir_end()

	print("Testing ", scenes.size(), " scenes for recursion / stack overflow...")
	for sc_path in scenes:
		print("Loading: ", sc_path)
		var packed: PackedScene = load(sc_path)
		if packed == null:
			print("  FAILED TO LOAD: ", sc_path)
			continue
		var inst: Node = packed.instantiate()
		root.add_child(inst)
		for i in 6:
			await process_frame
		if is_instance_valid(inst):
			inst.queue_free()
		for i in 3:
			await process_frame
		print("  OK: ", sc_path)

	print("ALL SCENES PASSED TEST!")
	quit(0)
