extends Node2D
@onready var player: CharacterBody2D = $Player
var stream: AudioStreamSynchronized

func _ready() -> void:
	if player == null:
		push_error("Player node not found! Make sure it has a unique name (%) in the scene tree.")
		return
	
	stream = $AudioStreamPlayer.stream
	# Start with only the first stream (least intense) audible
	stream.set_sync_stream_volume(0, 0.0)  # nopads-nodrums
	stream.set_sync_stream_volume(1, -80.0)  # pads-nodrums
	stream.set_sync_stream_volume(2, -80.0)  # pads-drums
	$AudioStreamPlayer.play()

func _process(delta: float) -> void:
	# Moving RIGHT increases intensity (0 to 1)
	var intensity = clamp((player.position.x - 64) / 1000.0, 0, 1)
	var mystery = clamp((player.position.y - 64) / 500.0, 0, 1)
	
	# Crossfade between three layers based on intensity
	if intensity < 0.5:
		# Crossfade between layer 0 and layer 1
		var blend = intensity * 2.0  # 0 to 1 over first half
		var fade_out = cos(blend * PI * 0.5)  # Cosine fade
		var fade_in = sin(blend * PI * 0.5)   # Sine fade
		stream.set_sync_stream_volume(0, linear_to_db(fade_out))
		stream.set_sync_stream_volume(1, linear_to_db(fade_in))
		stream.set_sync_stream_volume(2, -80.0)
	else:
		# Crossfade between layer 1 and layer 2
		var blend = (intensity - 0.5) * 2.0  # 0 to 1 over second half
		var fade_out = cos(blend * PI * 0.5)
		var fade_in = sin(blend * PI * 0.5)
		stream.set_sync_stream_volume(0, -80.0)
		stream.set_sync_stream_volume(1, linear_to_db(fade_out))
		stream.set_sync_stream_volume(2, linear_to_db(fade_in))
	
	# Display intensity and mystery percentages
	intensity = int(intensity * 100)
	mystery = int(mystery * 100)
