@tool
extends SceneTree

func _init() -> void:
	var stream := VideoStreamTheora.new()
	stream.file = "res://Assets/Environment/gibi/tongobriga_intro.ogv"
	var player := VideoStreamPlayer.new()
	player.stream = stream
	root.add_child(player)
	player.play()
	print("Godot VideoStreamPlayer started playing: is_playing=", player.is_playing(), " length=", stream.get_length())
	
	# Let's advance a few frames
	for i in range(30):
		player._process(0.033)
		
	print("Advanced 30 frames without crash. Stream position: ", player.stream_position)
	player.stop()
	player.queue_free()
	quit(0)

