extends Area2D
signal soul_collected

@onready var collapse_sound: AudioStreamPlayer = $Collapse

func _ready() -> void:
	$AnimatedSprite2D.play()
	# Connect the body_entered signal for collision detection
	body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node) -> void:
	$"../CanvasLayer/GPUParticles2D".emitting = true
	var zoomout = get_tree().create_tween()
	zoomout.parallel().tween_property($"../Player/Camera2D", "zoom:x", 1.0, 1.5)
	zoomout.parallel().tween_property($"../Player/Camera2D", "zoom:y", 1.0, 1.5)

	
	# Check if the colliding body is the player
	if body.is_in_group("Player"):
		# Create a dedicated sound effect player that won't be affected by main music
		var sound_effect_player = AudioStreamPlayer.new()
		sound_effect_player.stream = preload("res://assets/collapse.wav")
		sound_effect_player.bus = "SoundEffect"
		# Add to the main game scene instead of the soul node
		get_tree().current_scene.add_child(sound_effect_player)
		sound_effect_player.play()
		# Auto-cleanup after sound finishes
		sound_effect_player.finished.connect(func(): sound_effect_player.queue_free())
		
		# Emit signal to notify that soul was collected
		soul_collected.emit()
		# Hide the soul item
		visible = false
		# Disable collision detection
		set_process(false)
	# Remove the soul item after a short delay
	await get_tree().create_timer(0.1).timeout
	queue_free()
