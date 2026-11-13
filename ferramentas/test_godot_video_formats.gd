@tool
extends SceneTree

func _init() -> void:
	# Check what VideoStream resource loaders Godot registers:
	var loaders := ResourceLoader.get_recognized_extensions_for_type("VideoStream")
	print("Recognized VideoStream extensions: ", loaders)
	quit(0)

