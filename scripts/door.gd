extends Area2D
signal level_completed

func _ready() -> void:
	# Connect the body_entered signal for collision detection
	body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node) -> void:
	# Check if the colliding body is the player
	if body.is_in_group("Player"):
		# Get the main game script to check if soul is collected
		var main_game = get_tree().current_scene
		if main_game and main_game.has_method("is_soul_collected") and main_game.is_soul_collected():
			# Emit signal to notify that level is completed
			level_completed.emit()
			# Visual feedback - make door glow or change appearance
			$Sprite2D.modulate = Color.GREEN
			# Disable further collision detection
			set_process(false)
