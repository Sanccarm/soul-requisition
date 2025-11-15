extends Area2D
signal soul_collected

func _ready() -> void:
	# Connect the body_entered signal for collision detection
	body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node) -> void:
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
