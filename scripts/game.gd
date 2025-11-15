extends Node2D
@onready var player: CharacterBody2D = $Player
@onready var soul_status_label: Label = $CanvasLayer/SoulStatus
@onready var reset_button: Button = $CanvasLayer/ResetButton
@onready var game_over_music: AudioStreamPlayer = $GameOverMusic
var stream: AudioStreamSynchronized
var soul_collected: bool = false
var level_completed: bool = false
var game_stopped: bool = false
var homing_timer: float = 0.0
var homing_active: bool = false
var bullet_homing_manager: Node = null

func _ready() -> void:
	if player == null:
		push_error("Player node not found! Make sure it has a unique name (%) in the scene tree.")
		return
	
	stream = $AudioStreamPlayer.stream
	# Start with only the first stream (least intense) audible
	stream.set_sync_stream_volume(0, 0.0)  # nopads-nodrums
	stream.set_sync_stream_volume(1, -80.0)  # pads-nodrums
	stream.set_sync_stream_volume(2, -80.0)  # pads-drums
	$AudioStreamPlayer.play()
	
	# Initialize soul status label
	if soul_status_label:
		soul_status_label.text = "Soul lost."
	
	# Initialize reset button
	if reset_button:
		reset_button.disabled = true
		reset_button.pressed.connect(_on_reset_button_pressed)
	
	# Connect to soul collection signal
	var soul_node = $Soul
	if soul_node:
		soul_node.soul_collected.connect(_on_soul_collected)
	
	# Connect to door level completion signal
	var door_node = $Door
	if door_node:
		door_node.level_completed.connect(_on_level_completed)
	
	# Create bullet homing managersdddddddddddddddddd
	#bullet_homing_manager = preload("res://scripts/bullet_homing_manager.gd").new()
	#bullet_homing_manager.name = "BulletHomingManager"
	#add_child(bullet_homing_manager)

func _process(delta: float) -> void:
	# If game is stopped, don't process anything
	if game_stopped:
		return
	
	# Update homing timer if active
	if homing_active:
		homing_timer += delta
		update_bullet_homing()
	
	# If soul is collected, don't process normal music (drums handle this separately)
	if soul_collected:
		return
	
	# Calculate proximity to soul (closer = more pads, no drums)
	var soul_node = get_node_or_null("Soul")
	if soul_node and player:
		var distance = player.position.distance_to(soul_node.position)
		var proximity = clamp(1.0 - (distance / 400.0), 0, 1)  # 400 units is max distance
		
		# Crossfade between no pads and pads (no drums ever)
		var fade_out = cos(proximity * PI * 0.5)  # Cosine fade
		var fade_in = sin(proximity * PI * 0.5)   # Sine fade
		stream.set_sync_stream_volume(0, linear_to_db(fade_out))  # nopads-nodrums
		stream.set_sync_stream_volume(1, linear_to_db(fade_in))   # pads-nodrums
		stream.set_sync_stream_volume(2, -80.0)  # pads-drums (always off)

func _on_soul_collected() -> void:
	soul_collected = true
	if soul_status_label:
		soul_status_label.text = "Soul recollected."
	
	# Stop normal music and play only drums from beginning
	$AudioStreamPlayer.stop()
	# Create a new AudioStreamPlayer for just the drums
	var drum_player = AudioStreamPlayer.new()
	drum_player.stream = preload("res://assets/music/thememusic-pads-drums.ogg")
	drum_player.volume_db = -5.0
	drum_player.name = "DrumPlayer"
	add_child(drum_player)
	drum_player.play()
	
	# Start bullet homing when soul is collected
	start_bullet_homing()
	#var tween = create_tween()
	#tween.parallel().tween_property($BulletProperties/BasicBullet, "homing.homing_steer", 200, 10)
	#tween.play()
	#print("Tween playing")

func is_soul_collected() -> bool:
	return soul_collected

func _on_level_completed() -> void:
	if not level_completed and soul_collected:
		level_completed = true
		game_stopped = true
		if soul_status_label:
			soul_status_label.text = "Soul Returned."
		if reset_button:
			reset_button.disabled = false
		# Stop player movement
		if player:
			player.set_physics_process(false)

func _on_reset_button_pressed() -> void:
	# Reset game state
	soul_collected = false
	level_completed = false
	game_stopped = false
	homing_active = false
	homing_timer = 0.0
	
	# Reset UI
	if soul_status_label:
		soul_status_label.text = "Soul lost."
	if reset_button:
		reset_button.disabled = true
	
	# Reset player
	if player:
		player.position = Vector2(474, 259)
		player.set_physics_process(true)
		player.revive()
	
	# Respawn soul
	var soul_node = get_node_or_null("Soul")
	if soul_node:
		soul_node.queue_free()
	# Wait a frame for the node to be fully removed
	await get_tree().process_frame
	var new_soul = preload("res://scenes/soul.tscn").instantiate()
	new_soul.position = Vector2(300, 200)
	new_soul.name = "Soul"
	add_child(new_soul)
	new_soul.soul_collected.connect(_on_soul_collected)
	
	# Reset door
	var door_node = $Door
	if door_node:
		door_node.get_node("Sprite2D").modulate = Color(0.7, 0.5, 0.3, 1)
		door_node.set_process(true)
	
	# Reset bullet properties to non-homing
	reset_bullet_homing()
	
	# Stop drum player and resume normal music
	var drum_player = get_node_or_null("DrumPlayer")
	if drum_player:
		drum_player.queue_free()
	if game_over_music:
		game_over_music.stop()
	$AudioStreamPlayer.play()

func play_game_over_music() -> void:
	"""Stop all music and play game over music"""
	$AudioStreamPlayer.stop()
	# Stop drum player if it exists
	var drum_player = get_node_or_null("DrumPlayer")
	if drum_player:
		drum_player.stop()
		drum_player.queue_free()
	if game_over_music:
		game_over_music.play()

func resume_normal_music() -> void:
	"""Stop game over music and resume normal music"""
	if game_over_music:
		game_over_music.stop()
	$AudioStreamPlayer.play()

func start_bullet_homing() -> void:
	"""Start the bullet homing system - increases over 30 seconds"""
	homing_active = true
	homing_timer = 0.0

func update_bullet_homing() -> void:
	"""Update bullet homing strength based on timer"""
	if not homing_active or not player:
		return
	
	# Calculate homing strength (0 to 1 over 30 seconds)
	var homing_strength = min(homing_timer / 5.0, 5000000)
	
	# Update existing bullets directly
	update_existing_bullets_homing(homing_strength, player)

func update_existing_bullets_homing(strength: float, target: Node2D) -> void:
	"""Update existing bullets with new homing properties"""
	# Access the Spawning singleton to modify bullet properties
	Spawning.set_dynamic_homing(strength, target)

func reset_bullet_homing() -> void:
	"""Reset all bullets to non-homing state"""
	Spawning.reset_dynamic_homing()
