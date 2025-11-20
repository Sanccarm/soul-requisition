extends Control

const scene_intro = preload("res://scenes/intro.tscn")

@onready var title = $ColorRect/title
@onready var start = $ColorRect/VBoxContainer/StartButton
@onready var credit = $ColorRect/VBoxContainer/Credits


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
	starttween.tween_property(credit, "modulate:a", 1.0, 1.0)


func _on_start_button_pressed() -> void:
	TransitionScene.transition()
	await TransitionScene.on_transmission_finished
	get_tree().change_scene_to_packed(scene_intro)

func _on_credits_pressed() -> void:
	$ColorRect/VBoxContainer.visible = false
	$CanvasLayer/back.disabled = false
	var move_title = create_tween()
	move_title.tween_property(title, "position:y", 50.0, 1).set_trans(Tween.TRANS_QUINT).set_ease(Tween.EASE_IN_OUT)
	await move_title.finished
	$CanvasLayer.visible = true
	$CanvasLayer/Credits.advance()
	await get_tree().create_timer(1).timeout
	$CanvasLayer/Credits2.advance()
	


func _on_back_pressed() -> void:
	$CanvasLayer.visible = false
	var move_title = create_tween()
	move_title.tween_property(title, "position:y", 278.0, 1).set_trans(Tween.TRANS_QUINT).set_ease(Tween.EASE_IN_OUT)
	await move_title.finished
	$ColorRect/VBoxContainer.visible = true
	$CanvasLayer/back.disabled = true
