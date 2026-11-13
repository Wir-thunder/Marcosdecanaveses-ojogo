@tool
extends SceneTree

func _init() -> void:
	var chars := ["breno", "viriato", "marco", "nabia", "klaudia"]
	for c in chars:
		var p := "res://Assets/Characters/Tongobriga/%s/portrait.png" % c
		var img := Image.load_from_file(ProjectSettings.globalize_path(p))
		if img:
			print(c, " portrait: ", img.get_size(), " format: ", img.get_format())
		else:
			print(c, " portrait NOT FOUND")
	quit(0)

