extends Control
@onready var title = $ColorRect/title


func _ready():
	await get_tree().create_timer(2).timeout
	move_title_up_and_play_music()

	
	
	pass


func move_title_up_and_play_music():
	var move_title = create_tween()
	move_title.tween_property(title, "position:y", 50, 1).set_trans(Tween.TRANS_QUINT).set_ease(Tween.EASE_IN_OUT)
	await move_title.finished
	$MenuMusic.play()
