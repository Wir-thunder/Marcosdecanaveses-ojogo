@tool
extends SceneTree

func _init() -> void:
	var path := "C:/Users/Icaro/.gemini/antigravity/brain/d230022c-e2cb-4685-b15f-9b28e390df89/.user_uploaded/media_1793748585066_83022b51.jpg"
	var img := Image.load_from_file(path)
	
	for y in range(0, 35, 5):
		var line_str := "y=%2d: " % y
		for x in range(0, 35, 5):
			var c := img.get_pixel(x, y)
			if c.r > 0.2:
				line_str += "#"
			else:
				line_str += "."
		print(line_str)
	quit(0)

