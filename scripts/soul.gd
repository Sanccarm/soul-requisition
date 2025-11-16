extends Area2D
signal soul_collected

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
		# Emit signal to notify that soul was collected
		soul_collected.emit()
		# Hide the soul item
		visible = false
		# Disable collision detection
		set_process(false)
		# Remove the soul item after a short delay
		await get_tree().create_timer(0.1).timeout
		queue_free()
