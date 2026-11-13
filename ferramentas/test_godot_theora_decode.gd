@tool
extends SceneTree

func _init() -> void:
	var stream: VideoStreamTheora = load("res://Assets/Environment/gibi/tongobriga_intro.ogv") as VideoStreamTheora
	if not stream:
		print("Failed to load stream")
		quit(1)
		return
		
	var playback: VideoStreamPlayback = stream.instantiate_playback()
	if not playback:
		print("Failed to instantiate playback")
		quit(1)
		return
		
	print("Playback instantiated successfully! Length: ", playback.get_length())
	playback.play()
	
	# Update playback for 2 seconds
	for f in range(60):
		playback.update(0.033)
		var tex: Texture2D = playback.get_texture()
		if tex != null:
			var img: Image = tex.get_image()
			if img != null:
				if f == 10:
					img.save_png("C:/Users/Icaro/.gemini/antigravity/brain/d230022c-e2cb-4685-b15f-9b28e390df89/scratch/godot_theora_frame_10.png")
					print("Frame 10 captured from Godot's internal Theora decoder! Size: ", img.get_size())
				elif f == 40:
					img.save_png("C:/Users/Icaro/.gemini/antigravity/brain/d230022c-e2cb-4685-b15f-9b28e390df89/scratch/godot_theora_frame_40.png")
					print("Frame 40 captured from Godot's internal Theora decoder! Size: ", img.get_size())
					
	playback.stop()
	print("Godot Theora decoding test finished!")
	quit(0)
