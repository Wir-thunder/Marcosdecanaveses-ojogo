@tool
extends SceneTree

func _init() -> void:
	var current_port := Image.load_from_file("res://Assets/Characters/Tongobriga/klaudia/portrait.png")
	var crop_optB := Image.load_from_file("C:/Users/Icaro/.gemini/antigravity/brain/d230022c-e2cb-4685-b15f-9b28e390df89/scratch/klaudia_cropB_arcade.png")
	
	print("Current portrait size: ", current_port.get_size())
	print("Crop B size: ", crop_optB.get_size())
	
	# Let's see the difference
	current_port.convert(Image.FORMAT_RGBA8)
	crop_optB.convert(Image.FORMAT_RGBA8)
	
	var diff_sum: float = 0.0
	for y in range(128):
		for x in range(128):
			var c1 := current_port.get_pixel(x, y)
			var c2 := crop_optB.get_pixel(x, y)
			diff_sum += absf(c1.r - c2.r) + absf(c1.g - c2.g) + absf(c1.b - c2.b)
			
	print("Average pixel difference: ", diff_sum / (128.0 * 128.0))
	quit(0)

