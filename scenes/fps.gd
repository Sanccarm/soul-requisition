extends Node2D
@onready var bullet = $BulletPattern

func get_damage():
	return bullet.Damage

func _process(delta):
	$FPS.text = str(Engine.get_frames_per_second())+" FPS\n"+str(Spawning.poolBullets.size())
