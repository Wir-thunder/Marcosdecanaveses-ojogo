@tool
extends SceneTree

func _init() -> void:
	var path := "C:/Users/Icaro/.gemini/antigravity/brain/d230022c-e2cb-4685-b15f-9b28e390df89/.user_uploaded/media_1793748585066_83022b51.jpg"
	var img := Image.load_from_file(path)
	if not img:
		quit(1)
		return

	# Background slate color: sample at (20, 20) or (350, 50)
	var bg_col := img.get_pixel(350, 50)
	print("Sampled BG: ", bg_col)

	# In media_1793748585066_83022b51.jpg:
	# Top of hair is around y=30.
	# Chin is around y=320.
	# Neck is around y=360.
	# Red beaded necklace is around y=400-500.
	# Bottom of visible bust is y=550.
	# Hair on left reaches x=25.
	# Hair on right reaches x=375.
	# Center of face is roughly x=210, y=230.

	# Option 1: Standard arcade portrait framing (Head + collar + necklace, 400x400 scaled to 128x128)
	# Rect from x=10, y=25, size=390x390
	var opt1 := Image.create(390, 390, false, img.get_format())
	opt1.blit_rect(img, Rect2i(10, 25, 390, 390), Vector2i.ZERO)
	opt1.resize(128, 128, Image.INTERPOLATE_LANCZOS)
	opt1.save_png("C:/Users/Icaro/.gemini/antigravity/brain/d230022c-e2cb-4685-b15f-9b28e390df89/scratch/klaudia_crop_opt1.png")

	# Option 2: Full bust framing (includes more of the embroidered folk vest and red beads, 440x440 scaled to 128x128)
	# Rect from x=0, y=30, size=440x440
	var opt2 := Image.create(440, 440, false, img.get_format())
	opt2.blit_rect(img, Rect2i(0, 30, 440, 440), Vector2i.ZERO)
	opt2.resize(128, 128, Image.INTERPOLATE_LANCZOS)
	opt2.save_png("C:/Users/Icaro/.gemini/antigravity/brain/d230022c-e2cb-4685-b15f-9b28e390df89/scratch/klaudia_crop_opt2.png")

	# Option 3: Closer facial focus (highlights her facial features, eyeliner, smile, and gold earring, 340x340)
	# Rect from x=35, y=30, size=340x340
	var opt3 := Image.create(340, 340, false, img.get_format())
	opt3.blit_rect(img, Rect2i(35, 30, 340, 340), Vector2i.ZERO)
	opt3.resize(128, 128, Image.INTERPOLATE_LANCZOS)
	opt3.save_png("C:/Users/Icaro/.gemini/antigravity/brain/d230022c-e2cb-4685-b15f-9b28e390df89/scratch/klaudia_crop_opt3.png")

	print("Options saved!")
	quit(0)

