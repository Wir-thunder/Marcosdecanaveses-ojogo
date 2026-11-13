@tool
extends SceneTree

func _init() -> void:
	var path := "C:/Users/Icaro/.gemini/antigravity/brain/d230022c-e2cb-4685-b15f-9b28e390df89/klaudia_slavic_folk_v2.jpg"
	var img := Image.load_from_file(path)
	if not img:
		quit(1)
		return
	img.convert(Image.FORMAT_RGBA8)

	var w := img.get_width() # 1376
	var h := img.get_height() # 768
	
	# Sample slate background color
	var bg_col := img.get_pixel(470, 70)
	print("Sampled BG: ", bg_col)
	
	# Portrait crop from high-res:
	# Bounding box of bust:
	# x from 30 to 540 (w=510)
	# y from 30 to 540 (h=510)
	var crop := Image.create(512, 512, false, Image.FORMAT_RGBA8)
	crop.fill(bg_col)
	crop.blit_rect(img, Rect2i(28, 28, 512, 512), Vector2i.ZERO)
	
	# Clear out any corner border remnants (x+y < 35)
	for y in range(40):
		for x in range(40):
			if x + y < 35:
				crop.set_pixel(x, y, bg_col)
				
	# Resize to 128x128
	crop.resize(128, 128, Image.INTERPOLATE_LANCZOS)
	
	# Save to portrait.png
	crop.save_png("res://Assets/Characters/Tongobriga/klaudia/portrait.png")
	crop.save_png("C:/Users/Icaro/.gemini/antigravity/brain/d230022c-e2cb-4685-b15f-9b28e390df89/klaudia_portrait_approved_128.png")
	print("Portrait saved successfully to Assets/Characters/Tongobriga/klaudia/portrait.png!")
	quit(0)

