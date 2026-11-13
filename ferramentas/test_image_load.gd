@tool
extends SceneTree

func _init() -> void:
	var path := "C:/Users/Icaro/.gemini/antigravity/brain/d230022c-e2cb-4685-b15f-9b28e390df89/.user_uploaded/media_1793748585066_83022b51.jpg"
	var img := Image.load_from_file(path)
	if img:
		print("SUCCESS: Image loaded! Size: ", img.get_size(), " Format: ", img.get_format())
	else:
		print("FAILED to load image")
	quit(0)

