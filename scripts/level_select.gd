extends Control

@onready var level_select_music = $LevelSelect

func _ready():
	level_select_music.play()

func _on_level_1_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/demo_level.tscn")


func _on_back_pressed() -> void:
	TransitionScene.transition()
	await TransitionScene.on_transmission_finished
	get_tree().call_deferred("change_scene_to_file", "res://scenes/main_menu.tscn")
