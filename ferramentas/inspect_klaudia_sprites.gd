@tool
extends SceneTree

func _init() -> void:
	var dir := DirAccess.open("res://Assets/Characters/Tongobriga/klaudia")
	if dir:
		dir.list_dir_begin()
		var file := dir.get_next()
		while file != "":
			if file.ends_with(".png"):
				var img := Image.load_from_file("res://Assets/Characters/Tongobriga/klaudia/" + file)
				if img:
					print(file, " -> size: ", img.get_size(), " format: ", img.get_format())
			file = dir.get_next()
	quit(0)

