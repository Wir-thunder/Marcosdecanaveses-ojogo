@tool
extends SceneTree

func _init() -> void:
	var img_user := Image.load_from_file("C:/Users/Icaro/.gemini/antigravity/brain/d230022c-e2cb-4685-b15f-9b28e390df89/.user_uploaded/media_1793748585066_83022b51.jpg")
	var img_v2 := Image.load_from_file("C:/Users/Icaro/.gemini/antigravity/brain/d230022c-e2cb-4685-b15f-9b28e390df89/klaudia_slavic_folk_v2.jpg")
	
	print("User image: ", img_user.get_size(), " format: ", img_user.get_format())
	print("v2 image:   ", img_v2.get_size(), " format: ", img_v2.get_format())
	
	# Compare aspect ratios:
	# 1024 / 571 = 1.793345
	# 1376 / 768 = 1.791666
	# If we scale img_user to 1376x768 and compare with img_v2:
	var user_scaled := Image.create(1376, 768, false, img_user.get_format())
	user_scaled.copy_from(img_user)
	user_scaled.resize(1376, 768, Image.INTERPOLATE_LANCZOS)
	
	var diff_sum: float = 0.0
	for y in range(100, 400, 10):
		for x in range(100, 400, 10):
			var c1 := user_scaled.get_pixel(x, y)
			var c2 := img_v2.get_pixel(x, y)
			diff_sum += absf(c1.r - c2.r) + absf(c1.g - c2.g) + absf(c1.b - c2.b)
			
	print("Average pixel difference on face/bust area: ", diff_sum / (30.0 * 30.0))
	quit(0)

