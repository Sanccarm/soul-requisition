extends Control
@onready var title = $ColorRect/title
@onready var start = $ColorRect/VBoxContainer/StartButton


func _ready():
	await get_tree().create_timer(2).timeout
	await move_title_up_and_play_music()
	button_fade_in()



func move_title_up_and_play_music():
	var move_title = create_tween()
	move_title.tween_property(title, "position:y", 278.0, 1).set_trans(Tween.TRANS_QUINT).set_ease(Tween.EASE_IN_OUT)
	await move_title.finished
	$MenuMusic.play()
	emit_signal("finished")
	
func button_fade_in():
	var starttween = create_tween()
	starttween.tween_property(start, "modulate:a", 1.0, 1.0)


func _on_start_button_pressed() -> void:
	pass # Replace with function body.
