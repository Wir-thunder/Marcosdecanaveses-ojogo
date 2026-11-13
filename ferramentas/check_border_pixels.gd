@tool
extends SceneTree

func _init() -> void:
	var path := "C:/Users/Icaro/.gemini/antigravity/brain/d230022c-e2cb-4685-b15f-9b28e390df89/.user_uploaded/media_1793748585066_83022b51.jpg"
	var img := Image.load_from_file(path)
	
	# Let's inspect the corner border:
	# Gold border line: let's see where the border pixels are:
	print("Pixel at (15, 15): ", img.get_pixel(15, 15))
	print("Pixel at (25, 25): ", img.get_pixel(25, 25))
	print("Pixel at (30, 30): ", img.get_pixel(30, 30))
	print("Pixel at (100, 20): ", img.get_pixel(100, 20))
	
	# In opt1: rect was (10, 25, 390, 390).
	# At (10, 25), the left edge x=10 might catch the border line if border is at x=10..14.
	# Let's see: hair starts at x ~ 25..35.
	# Top of hair is y ~ 35.
	quit(0)

