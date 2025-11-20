extends CharacterBody2D
const STARTING_HEALTH = 1.0
var HEALTH = STARTING_HEALTH
const SPEED = 200.0

# Parry system variables
var parry_active: bool = false
var parry_cooldown: float = 0.0
const PARRY_DURATION: float = 0.5
const PARRY_COOLDOWN_TIME: float = 2.0

@onready var parry_shield: Area2D = $ParryShield
@onready var parry_sprite: Sprite2D = $ParryShield/ParrySprite
@onready var parry_sound: AudioStreamPlayer = $ParrySound

func _ready() -> void:
	$"../CanvasLayer/Button".disabled = true
	print("DEBUG: Player _ready() called")
	add_to_group("Player")
	print("DEBUG: Manually added Player group")
	print("DEBUG: Player groups: ", get_groups())
	print("DEBUG: Player has take_damage method: ", has_method("take_damage"))
	print("player started")
	
	# Initialize parry shield
	if parry_shield:
		parry_shield.monitoring = false
		parry_shield.get_node("ParryCollisionShape").disabled = true
		parry_shield.connect("area_entered", _on_parry_shield_area_entered)
	
	# Initialize parry sprite
	if parry_sprite:
		parry_sprite.visible = false


func _physics_process(delta: float) -> void:
	var direction = Input.get_vector("left","right", "up", "down")
	velocity = direction * SPEED
	rotation = lerp_angle(rotation, atan2(velocity.x, -velocity.y), delta*20.0)
	move_and_slide()
	
	# Handle parry cooldown
	if parry_cooldown > 0:
		parry_cooldown -= delta
	
	# Handle parry input
	if Input.is_action_just_pressed("parry"):
		if parry_cooldown <= 0:
			activate_parry()
		else:
			print("DEBUG: Parry on cooldown! ", parry_cooldown, " seconds remaining")
	
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
	
	# Update soul status label to "You're Lost."
	var soul_status_label = $"../CanvasLayer/SoulStatus"
	if soul_status_label:
		soul_status_label.bbcode = "[red][jit2 freq=50]You're Lost."
	
	# Play game over music
	var game_node = get_parent()
	if game_node and game_node.has_method("play_game_over_music"):
		game_node.play_game_over_music()
	
	if game_node and game_node.has_method("display_lose_stats"):
		game_node.display_lose_stats()
		
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
	
	# Reset soul status label when reviving
	var soul_status_label = $"../CanvasLayer/SoulStatus"
	if soul_status_label:
		soul_status_label.text = "Soul lost."
	
	# Resume normal music when reviving
	var game_node = get_parent()
	if game_node and game_node.has_method("resume_normal_music"):
		game_node.resume_normal_music()
	
	
#func _on_rigid_body_2d_body_entered(body: Node) -> void:
	#print("collision")
	#if body.has_method("get_damage"):
		#take_damage(body.get_damage())
		#print("2d body entered:", HEALTH)
		#if HEALTH <= 0:
			#died()


func _on_button_pressed() -> void:
	revive()

func activate_parry():
	if parry_active:
		return
	
	parry_active = true
	parry_cooldown = PARRY_COOLDOWN_TIME
	
	# Enable parry shield
	if parry_shield:
		parry_shield.monitoring = true
		parry_shield.get_node("ParryCollisionShape").disabled = false
	
	# Show parry sprite
	if parry_sprite:
		parry_sprite.visible = true
		#var tween = create_tween()
		#tween.tween_property(parry_sprite, "scale", Vector2(10, 10), 0.1)
		#tween.tween_property(parry_sprite, "scale", Vector2(8, 8), 0.1)
	
	# Play parry sound
	if parry_sound:
		parry_sound.play()
	
	# Visual feedback - flash effect
	var flash_tween = create_tween()
	flash_tween.tween_property(self, "modulate", Color.CYAN, 0.1)
	flash_tween.tween_property(self, "modulate", Color.WHITE, 0.1)
	
	# Show cooldown feedback
	if parry_cooldown > 0:
		print("DEBUG: Parry on cooldown for ", parry_cooldown, " seconds")
	
	# Schedule parry deactivation
	get_tree().create_timer(PARRY_DURATION).timeout.connect(deactivate_parry)
	
	print("DEBUG: Parry activated!")

func deactivate_parry():
	parry_active = false
	
	# Disable parry shield
	if parry_shield:
		parry_shield.monitoring = false
		parry_shield.get_node("ParryCollisionShape").disabled = true
	
	# Hide parry sprite
	if parry_sprite:
		parry_sprite.visible = false
	
	print("DEBUG: Parry deactivated!")

func _on_parry_shield_area_entered(area: Area2D):
	if not parry_active:
		return
	
	# Check if the area is a bullet from the BulletUpHell system
	if area.get_parent().name == "Spawning":
		print("DEBUG: Bullet blocked by parry shield!")
		# The bullet will be handled by the bullet system's collision logic
		# We just need to prevent damage to the player

func is_parrying() -> bool:
	return parry_active
