@tool
extends SceneTree

func _init() -> void:
	var path := "C:/Users/Icaro/.gemini/antigravity/brain/d230022c-e2cb-4685-b15f-9b28e390df89/.user_uploaded/media_1793748585066_83022b51.jpg"
	var img := Image.load_from_file(path)
	var bg := img.get_pixel(350, 50)
	
	var min_x := 1024
	var max_x := 0
	var min_y := 571
	var max_y := 0
	
	# Only scan the left section (x: 25 to 420, y: 25 to 565)
	for y in range(25, 565):
		for x in range(25, 420):
			var c := img.get_pixel(x, y)
			var diff: float = absf(c.r - bg.r) + absf(c.g - bg.g) + absf(c.b - bg.b)
			if diff > 0.08:
				if x < min_x: min_x = x
				if x > max_x: max_x = x
				if y < min_y: min_y = y
				if y > max_y: max_y = y
				
	print("Portrait bounds: min_x=", min_x, " max_x=", max_x, " min_y=", min_y, " max_y=", max_y)
	print("Width=", max_x - min_x, " Height=", max_y - min_y)
	quit(0)
