extends CharacterBody2D
const STARTING_HEALTH = 1.0
var HEALTH = STARTING_HEALTH
const SPEED = 200.0

func _ready() -> void:
	$"../CanvasLayer/Button".disabled = true
	print("DEBUG: Player _ready() called")
	add_to_group("Player")
	print("DEBUG: Manually added Player group")
	print("DEBUG: Player groups: ", get_groups())
	print("DEBUG: Player has take_damage method: ", has_method("take_damage"))
	print("player started")


func _physics_process(delta: float) -> void:
	var direction = Input.get_vector("left","right", "up", "down")
	velocity = direction * SPEED
	move_and_slide()
	for i in get_slide_collision_count():
		var collision = get_slide_collision(i)
		print("I collided with ", collision.get_collider().name)
		print("collision")
		if collision.get_collider().has_method("get_damage"):
			take_damage(collision.get_collider().get_damage())
			print("2d body entered:", HEALTH)

	
func take_damage(damage):
	print("DEBUG: take_damage called with damage: ", damage, " current health: ", HEALTH)
	if HEALTH <= 0:
		print("DEBUG: player took damage but dead")
		return
	var new_health = HEALTH - damage
	if new_health > 0:
		HEALTH = new_health
		print("DEBUG: take_damage completed, new health: ", HEALTH)
	if new_health <= 0:
		HEALTH = 0
		print("DEBUG: Player health reached 0, calling died()")
		$CollisionShape2D.disabled = true
		died()
	pass

func died():
	print("DEBUG: died() function called, health: ", HEALTH)
	print("DEBUG: Executing death sequence")
		# Stop movement
	set_physics_process(false)
		
	# Create a CanvasLayer for UI effects
	var canvas_layer = CanvasLayer.new()
	canvas_layer.layer = 100  # Ensure it's on top
	get_tree().current_scene.add_child(canvas_layer)
	
	# Screen flash effect
	var flash = ColorRect.new()
	flash.color = Color.WHITE
	flash.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	flash.mouse_filter = Control.MOUSE_FILTER_IGNORE
	canvas_layer.add_child(flash)
	
	# Make flash visible initially, then fade out
	flash.modulate.a = 1.0
	var tween = create_tween()
	tween.tween_property(flash, "modulate:a", 0, 0.3)
	tween.tween_callback(func(): canvas_layer.queue_free())
	
	# Fade out player sprite
	tween.parallel().tween_property(self, "modulate:a", 0, 1)

	print("DEBUG: Death sequence completed, health: ", HEALTH)
	$"../CanvasLayer/Button".disabled = false
	
func revive():
	print("DEBUG: Player revived")
	set_physics_process(true)
	var tween = create_tween()
	tween.parallel().tween_property(self, "modulate:a", 1, 1)
	HEALTH = STARTING_HEALTH
	$CollisionShape2D.disabled = false
	
	
#func _on_rigid_body_2d_body_entered(body: Node) -> void:
	#print("collision")
	#if body.has_method("get_damage"):
		#take_damage(body.get_damage())
		#print("2d body entered:", HEALTH)
		#if HEALTH <= 0:
			#died()


func _on_button_pressed() -> void:
	revive()
