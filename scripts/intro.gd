extends Control
const level_select = preload("res://scenes/level_select.tscn")
@onready var wind = $AudioStreamPlayer
@onready var continue_button = $continue

func _ready():
	wind.play()
	await get_tree().create_timer(3).timeout
	$VBoxContainer/Line1.advance()
	await get_tree().create_timer(3).timeout
	$VBoxContainer/Line2.advance()
	await get_tree().create_timer(3).timeout
	$VBoxContainer/Line3.advance()
	ready_click_to_continue()

func ready_click_to_continue():
	var tween = create_tween()
	tween.tween_property(continue_button, "modulate:a", 1, 1)


func _on_continue_pressed() -> void:
	TransitionScene.transition()
	await TransitionScene.on_transmission_finished
	get_tree().change_scene_to_packed(level_select)
