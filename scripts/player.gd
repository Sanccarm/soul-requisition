extends CharacterBody2D
var HEALTH = 1.0
const SPEED = 200.0

func _ready() -> void:
	print("player started")


func _physics_process(delta: float) -> void:
	var direction = Input.get_vector("left","right", "up", "down")
	velocity = direction * SPEED
	move_and_slide()
	for i in get_slide_collision_count():
		var collision = get_slide_collision(i)
		print("I collided with ", collision.get_collider().name)
		print("collision")
		if collision.has_method("get_damage"):
			take_damage(collision.get_damage())
			print("2d body entered:", HEALTH)
			died()

	
func take_damage(damage):
	HEALTH = HEALTH - damage
	print("take_damage:", HEALTH)
	pass

func died():
	var death = create_tween()
	death.tween_property($CharacterBody2D, "self_modulate.a", 0, 4)
	print("died:", HEALTH)
	pass

func _on_rigid_body_2d_body_entered(body: Node) -> void:
	print("collision")
	if body.has_method("get_damage"):
		take_damage(body.get_damage())
		print("2d body entered:", HEALTH)
		died()
