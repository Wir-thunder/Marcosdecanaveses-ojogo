@tool
extends SceneTree

func _init() -> void:
	var input_path := "C:/Users/Icaro/.gemini/antigravity/brain/d230022c-e2cb-4685-b15f-9b28e390df89/.user_uploaded/media_1793748585066_83022b51.jpg"
	var img := Image.load_from_file(input_path)
	if not img:
		print("ERROR loading image")
		quit(1)
		return

	var w := img.get_width()
	var h := img.get_height()
	print("Loaded image: ", w, "x", h)

	# The image is 1024x571.
	# Let's inspect the bounding box of the portrait on the left:
	# Hair starts around y ~ 35, x ~ 10.
	# Left border ends around x ~ 430.
	# Bottom of portrait goes down to y ~ 560.
	
	# Let's crop the portrait bust:
	# Let's try x: 10 to 420, y: 18 to 560
	var crop_portrait := Image.create(410, 542, false, img.get_format())
	crop_portrait.blit_rect(img, Rect2i(10, 18, 410, 542), Vector2i.ZERO)
	crop_portrait.save_png("C:/Users/Icaro/.gemini/antigravity/brain/d230022c-e2cb-4685-b15f-9b28e390df89/scratch/klaudia_portrait_raw_crop.png")

	# Let's also crop a square portrait (around head/shoulders):
	# Center of face is roughly x: 215, y: 270.
	# Let's crop square 480x480 from (0, 20) or (15, 20):
	var crop_sq := Image.create(430, 430, false, img.get_format())
	crop_sq.blit_rect(img, Rect2i(0, 30, 430, 430), Vector2i.ZERO)
	crop_sq.save_png("C:/Users/Icaro/.gemini/antigravity/brain/d230022c-e2cb-4685-b15f-9b28e390df89/scratch/klaudia_portrait_sq_crop.png")

	# Let's crop the middle standing character:
	# Middle char is roughly x: 410 to 660, y: 110 to 520
	var crop_mid := Image.create(260, 420, false, img.get_format())
	crop_mid.blit_rect(img, Rect2i(410, 110, 260, 420), Vector2i.ZERO)
	crop_mid.save_png("C:/Users/Icaro/.gemini/antigravity/brain/d230022c-e2cb-4685-b15f-9b28e390df89/scratch/klaudia_standing_crop.png")

	# Let's crop the right action/special character:
	# Right char is roughly x: 670 to 990, y: 70 to 520
	var crop_right := Image.create(330, 460, false, img.get_format())
	crop_right.blit_rect(img, Rect2i(670, 70, 330, 460), Vector2i.ZERO)
	crop_right.save_png("C:/Users/Icaro/.gemini/antigravity/brain/d230022c-e2cb-4685-b15f-9b28e390df89/scratch/klaudia_special_crop.png")

	print("Crops saved successfully!")
	quit(0)

