extends Control
@onready var wind = $AudioStreamPlayer


func _ready():
	wind.play()
	await get_tree().create_timer(3).timeout
	$VBoxContainer/Line1.advance()
	await get_tree().create_timer(3).timeout
	$VBoxContainer/Line2.advance()
	await get_tree().create_timer(3).timeout
	$VBoxContainer/Line3.advance()
