@tool
extends SceneTree

func _init() -> void:
	var path := "C:/Users/Icaro/.gemini/antigravity/brain/d230022c-e2cb-4685-b15f-9b28e390df89/.user_uploaded/media_1793748585066_83022b51.jpg"
	var img := Image.load_from_file(path)
	img.convert(Image.FORMAT_RGBA8)
	var bg_color := Color("1b242d") # Dark slate

	# Crop A: Head & Neck (Tight - 360x360 centered on face x=215, y=210)
	# rect: x = 35, y = 30, w = 360, h = 360
	var cropA := Image.create(360, 360, false, Image.FORMAT_RGBA8)
	cropA.fill(bg_color)
	cropA.blit_rect(img, Rect2i(35, 30, 360, 360), Vector2i.ZERO)
	cropA.resize(128, 128, Image.INTERPOLATE_LANCZOS)
	cropA.save_png("C:/Users/Icaro/.gemini/antigravity/brain/d230022c-e2cb-4685-b15f-9b28e390df89/scratch/klaudia_cropA_tight.png")

	# Crop B: Classic Arcade Bust (x=15, y=25, w=400, h=400) -> captures full hair, earring, smile, neck, necklace
	var cropB := Image.create(400, 400, false, Image.FORMAT_RGBA8)
	cropB.fill(bg_color)
	cropB.blit_rect(img, Rect2i(15, 25, 400, 400), Vector2i.ZERO)
	# Clean any gold corner in top-left (x < 15, y < 15 in cropped coordinates)
	for y in range(18):
		for x in range(18):
			if x + y < 22:
				cropB.set_pixel(x, y, bg_color)
	cropB.resize(128, 128, Image.INTERPOLATE_LANCZOS)
	cropB.save_png("C:/Users/Icaro/.gemini/antigravity/brain/d230022c-e2cb-4685-b15f-9b28e390df89/scratch/klaudia_cropB_arcade.png")

	# Crop C: Full Folk Costume Bust (x=0, y=30, w=440, h=440) -> includes embroidered vest
	var cropC := Image.create(440, 440, false, Image.FORMAT_RGBA8)
	cropC.fill(bg_color)
	cropC.blit_rect(img, Rect2i(0, 30, 440, 440), Vector2i.ZERO)
	for y in range(25):
		for x in range(25):
			if x + y < 30:
				cropC.set_pixel(x, y, bg_color)
	cropC.resize(128, 128, Image.INTERPOLATE_LANCZOS)
	cropC.save_png("C:/Users/Icaro/.gemini/antigravity/brain/d230022c-e2cb-4685-b15f-9b28e390df89/scratch/klaudia_cropC_folk.png")

	# Let's create a side-by-side comparison image of all 3 + Breno's portrait
	var breno := Image.load_from_file("res://Assets/Characters/Tongobriga/breno/portrait.png")
	var comp := Image.create(128 * 4 + 30, 128 + 10, false, Image.FORMAT_RGBA8)
	comp.fill(Color.BLACK)
	if breno:
		comp.blit_rect(breno, Rect2i(0, 0, 128, 128), Vector2i(5, 5))
	comp.blit_rect(cropA, Rect2i(0, 0, 128, 128), Vector2i(138, 5))
	comp.blit_rect(cropB, Rect2i(0, 0, 128, 128), Vector2i(271, 5))
	comp.blit_rect(cropC, Rect2i(0, 0, 128, 128), Vector2i(404, 5))
	comp.save_png("C:/Users/Icaro/.gemini/antigravity/brain/d230022c-e2cb-4685-b15f-9b28e390df89/scratch/klaudia_portraits_comparison.png")
	comp.save_png("C:/Users/Icaro/.gemini/antigravity/brain/d230022c-e2cb-4685-b15f-9b28e390df89/klaudia_portraits_comparison.png")

	print("Comparison generated!")
	quit(0)
