@tool
extends SceneTree

func _init() -> void:
	var breno_img := Image.load_from_file("res://Assets/Characters/Tongobriga/breno/portrait.png")
	var marco_img := Image.load_from_file("res://Assets/Characters/Tongobriga/marco/portrait.png")
	print("Breno size: ", breno_img.get_size(), " top-left pixel: ", breno_img.get_pixel(0, 0))
	print("Marco size: ", marco_img.get_size(), " top-left pixel: ", marco_img.get_pixel(0, 0))
	quit(0)

