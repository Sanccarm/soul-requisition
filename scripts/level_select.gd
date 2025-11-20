extends Control

@onready var level_select_music = $LevelSelect

func _ready():
	level_select_music.play()


func _on_button_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/demo_level.tscn")
