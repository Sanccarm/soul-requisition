extends Node2D

# =============================================================================
# NODE REFERENCES & VARIABLES
# =============================================================================

@onready var player: CharacterBody2D = $Player
@onready var soul_status_label: RichTextAnimation = $CanvasLayer/SoulStatus
@onready var reset_button: Button = $CanvasLayer/ResetButton
@onready var game_over_music: AudioStreamPlayer = $GameOverMusic
@onready var game_win_music: AudioStreamPlayer = $GameWinMusic
@onready var timer_label: Label = $CanvasLayer/Timer

# Game state variables
var soul_collected: bool = false
var level_completed: bool = false
var game_stopped: bool = false

# Timer variables
var countdown_timer: float = 20.0
var countdown_active: bool = false

# Bullet system variables
var homing_timer: float = 0.0
var homing_active: bool = false
var bullet_homing_manager: Node = null

# Audio variables
var stream: AudioStreamSynchronized

# =============================================================================
# CORE GAME FUNCTIONS
# =============================================================================

func _ready() -> void:
	if player == null:
		push_error("Player node not found! Make sure it has a unique name (%) in the scene tree.")
		return
	
	# Initialize audio system
	initialize_audio()
	
	# Initialize UI elements
	initialize_ui()
	
	# Setup timer label
	setup_timer_label()
	
	# Connect signals
	connect_signals()

func _process(delta: float) -> void:
	# If game is stopped, don't process anything
	if game_stopped:
		return
	
	# Update countdown timer if active
	update_countdown_timer(delta)
	
	# Update homing timer if active
	update_homing_timer(delta)
	
	# Update music based on soul proximity
	update_music_proximity()

# =============================================================================
# AUDIO SYSTEM FUNCTIONS
# =============================================================================

func initialize_audio() -> void:
	"""Initialize the audio system and start background music"""
	stream = $AudioStreamPlayer.stream
	# Start with only the first stream (least intense) audible
	stream.set_sync_stream_volume(0, 0.0)  # nopads-nodrums
	stream.set_sync_stream_volume(1, -80.0)  # pads-nodrums
	stream.set_sync_stream_volume(2, -80.0)  # pads-drums
	$AudioStreamPlayer.play()

func update_music_proximity() -> void:
	"""Update music based on player's proximity to soul"""
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

func play_game_over_music() -> void:
	"""Stop all music and play game over music"""
	$AudioStreamPlayer.volume_db = -80.0
	# Stop drum player if it exists
	var drum_player = get_node_or_null("DrumPlayer")
	if drum_player:
		drum_player.stop()
		drum_player.queue_free()
	if game_over_music:
		game_over_music.play()

func play_game_win_music() -> void:
	"""Stop all music and play game over music"""
	$AudioStreamPlayer.volume_db = -80.0
	# Stop drum player if it exists
	var drum_player = get_node_or_null("DrumPlayer")
	if drum_player:
		drum_player.stop()
		drum_player.queue_free()
	if game_win_music:
		game_win_music.play()
		await game_win_music.finished

		# place menu music here

		resume_normal_music()

func resume_normal_music() -> void:
	"""Stop game over music and resume normal music"""
	if game_over_music:
		game_over_music.stop()
	$AudioStreamPlayer.stream_paused = false

func start_drum_music() -> void:
	"""Start drum-only music when soul is collected"""
	# Pause normal music instead of stopping/muting it
	$AudioStreamPlayer.stream_paused = true
	# Create a new AudioStreamPlayer for just the drums
	var drum_player = AudioStreamPlayer.new()
	drum_player.stream = preload("res://assets/music/thememusic-pads-drums.ogg")
	drum_player.volume_db = -5.0
	drum_player.name = "DrumPlayer"
	add_child(drum_player)
	drum_player.play()

func stop_drum_music() -> void:
	"""Stop drum music and cleanup"""
	var drum_player = get_node_or_null("DrumPlayer")
	if drum_player:
		drum_player.queue_free()

# =============================================================================
# BULLET SYSTEM FUNCTIONS
# =============================================================================

func start_bullet_homing() -> void:
	"""Start the bullet homing system - increases over time"""
	homing_active = true
	homing_timer = 0.0
	
	# Initialize bullet properties for homing
	if Spawning.arrayProps.has("basic"):
		var bullet_props = Spawning.arrayProps["basic"]
		bullet_props["homing_type"] = 5  # TARGET_TYPE.Group
		bullet_props["homing_group"] = "Player"
		bullet_props["homing_steer"] = 10.0  # Start with immediate homing
		bullet_props["homing_time_start"] = 0.0
		bullet_props["homing_duration"] = 999.0
	
	# Apply initial homing immediately
	update_existing_bullets_homing(10.0, player)

func update_homing_timer(delta: float) -> void:
	"""Update the homing timer and apply homing effects"""
	if homing_active:
		homing_timer += delta
		# Calculate homing strength: starts immediately, increases over time
		# Base strength + time-based increase
		var base_strength = 10.0  # Immediate homing strength
		var time_bonus = min(homing_timer / 20.0, 1.0) * 90.0  # Additional strength over time
		var total_strength = base_strength + time_bonus
		
		update_existing_bullets_homing(total_strength, player)

func update_bullet_homing(time, intensity: int) -> void:
	"""Update bullet homing strength based on timer"""
	if not homing_active or not player:
		return
	
	# Calculate homing strength (0 to 1 over specified time)
	var homing_strength = min(homing_timer / time, intensity)
	
	# Update existing bullets directly
	update_existing_bullets_homing(homing_strength, player)

func update_existing_bullets_homing(strength: float, target: Node2D) -> void:
	"""Update existing bullets with new homing properties"""
	# Access the Spawning singleton to modify bullet properties
	Spawning.set_dynamic_homing(strength, target)
	
	# Also update bullet properties to enable homing
	if Spawning.arrayProps.has("basic"):
		var bullet_props = Spawning.arrayProps["basic"]
		bullet_props["homing_type"] = 5  # TARGET_TYPE.Group
		bullet_props["homing_group"] = "Player"
		bullet_props["homing_steer"] = strength
		bullet_props["homing_time_start"] = 0.0
		bullet_props["homing_duration"] = 999.0

func reset_bullet_homing() -> void:
	"""Reset all bullets to non-homing state"""
	Spawning.reset_dynamic_homing()
	
	# Reset bullet properties to disable homing
	if Spawning.arrayProps.has("basic"):
		var bullet_props = Spawning.arrayProps["basic"]
		bullet_props["homing_type"] = 0  # TARGET_TYPE.Nodepath (disabled)
		bullet_props["homing_target"] = NodePath("")
		bullet_props["homing_steer"] = 0.0

func set_bullet_speed(speed: int) -> void:
	"""Set the speed of all bullets to the specified value"""
	# Update the bullet properties in the Spawning system
	if Spawning.arrayProps.has("basic"):
		Spawning.arrayProps["basic"]["speed"] = float(speed)
	
	# Update speed of all currently active bullets
	for bullet_id in Spawning.poolBullets.keys():
		var bullet_data = Spawning.poolBullets[bullet_id]
		if bullet_data.has("speed"):
			bullet_data["speed"] = float(speed)

# =============================================================================
# TIMER SYSTEM FUNCTIONS
# =============================================================================

func setup_timer_label() -> void:
	"""Setup timer label with styling and initial position"""
	if timer_label:
		timer_label.modulate = Color.WHITE
		timer_label.visible = false

func animate_timer_position() -> void:
	"""Animate timer from center to top middle of canvas"""
	if timer_label:
		await get_tree().create_timer(1.4).timeout
		var tween = create_tween()
		tween.set_parallel(true)
		# Animate position from center to top middle
		tween.tween_property(timer_label, "position:y", 0, 0.9)
		# Animate font size from large to smaller
		tween.tween_property(timer_label, "theme_override_font_sizes/font_size", 24, 0.9)

func update_countdown_timer(delta: float) -> void:
	"""Update the countdown timer"""
	if countdown_active:
		countdown_timer -= delta
		update_timer_display()
		
		if countdown_timer <= 0:
			set_bullet_speed(500)
			# Timer expired - set maximum homing intensity
			countdown_timer = 0
			timer_label.bbcode = "00:00.00"
			countdown_active = false
			timer_label.modulate = Color.RED
			# Set maximum homing strength when timer reaches zero
			update_existing_bullets_homing(1000.0, player)



func update_timer_display() -> void:
	"""Update the timer display with milliseconds"""
	if timer_label:
		@warning_ignore("integer_division")
		var minutes = int(countdown_timer) / 60
		var seconds = int(countdown_timer) % 60
		var milliseconds = int((countdown_timer - int(countdown_timer)) * 100)
		timer_label.text = "%02d:%02d.%02d" % [minutes, seconds, milliseconds]

# =============================================================================
# UI SYSTEM FUNCTIONS
# =============================================================================

func initialize_ui() -> void:
	"""Initialize UI elements"""
	# Initialize soul status label
	if soul_status_label:
		soul_status_label.bbcode = "[jit2][red]Soul lost."
	
	# Initialize reset button
	if reset_button:
		reset_button.disabled = true
		reset_button.pressed.connect(_on_reset_button_pressed)

func update_soul_status(text: String) -> void:
	"""Update the soul status label text"""
	if soul_status_label:
		soul_status_label.bbcode = text

# =============================================================================
# GAME LOGIC FUNCTIONS
# =============================================================================

func connect_signals() -> void:
	"""Connect all game signals"""
	# Connect to soul collection signal
	var soul_node = $Soul
	if soul_node:
		soul_node.soul_collected.connect(_on_soul_collected)
	
	# Connect to door level completion signal
	var door_node = $Door
	if door_node:
		door_node.level_completed.connect(_on_level_completed)

func _on_soul_collected() -> void:
	"""Handle soul collection event"""
	soul_collected = true
	update_soul_status("[yellow][jit2] Soul recollected.")
	
	# Start 20-second countdown timer
	countdown_timer = 20.0
	countdown_active = true
	timer_label.modulate = Color.WHITE
	timer_label.visible = true
	
	# Animate timer from center to top
	animate_timer_position()
	
	# Start drum music
	start_drum_music()
	

func _on_level_completed() -> void:
	"""Handle level completion event"""
	if not level_completed and soul_collected:
		var zoomout = get_tree().create_tween()
		zoomout.parallel().tween_property($"Player/Camera2D", "zoom:x", 3, 0.1)
		zoomout.parallel().tween_property($"Player/Camera2D", "zoom:y", 3, 0.1)
		var cameraslide = get_tree().create_tween()

		cameraslide.parallel().tween_property($"Player/Camera2D", "position:x", -100 , .1)
		play_game_win_music()
		level_completed = true
		game_stopped = true
		update_soul_status("[green][wave amp=20]Soul Returned.")
		if reset_button:
			reset_button.disabled = false
		# Stop player movement
		if player:
			player.remove_from_group("Player")
			player.set_physics_process(false)

func _on_reset_button_pressed() -> void:
	"""Handle game reset event"""
	# Reset game state
	player.add_to_group("Player")
	soul_collected = false
	level_completed = false
	game_stopped = false
	homing_active = false
	homing_timer = 0.0
	countdown_active = false
	countdown_timer = 20.0
	
	# Reset UI
	update_soul_status("Soul lost.")
	if reset_button:
		reset_button.disabled = true
	if timer_label:
		timer_label.visible = false
	
	# Reset player
	reset_player()
	
	# Respawn soul
	respawn_soul()
	
	# Reset door
	reset_door()
	
	# Reset bullet properties to non-homing
	reset_bullet_homing()
	
	# Stop drum music and resume normal music
	stop_drum_music()
	if game_over_music:
		game_over_music.stop()
	$AudioStreamPlayer.stream_paused = false

func reset_player() -> void:
	"""Reset player to starting position and state"""
	if player:
		player.position = Vector2(474, 259)
		player.set_physics_process(true)
		player.revive()

func respawn_soul() -> void:
	"""Respawn the soul at its starting position"""
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

func reset_door() -> void:
	"""Reset door to its initial state"""
	var door_node = $Door
	if door_node:
		door_node.get_node("Sprite2D").modulate = Color(0.7, 0.5, 0.3, 1)
		door_node.set_process(true)

# =============================================================================
# UTILITY FUNCTIONS
# =============================================================================

func is_soul_collected() -> bool:
	"""Check if soul has been collected"""
	return soul_collected
