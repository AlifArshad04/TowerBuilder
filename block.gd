extends RigidBody2D

signal settled(block)
signal out_of_view(block)

const PARACHUTE_UPWARD_FORCE := 0.8
const SIDE_FORCE_STRENGTH := 700.0
const ROTATE_SPEED := 1.5
const MAX_VERTICAL_SPEED := 300.0

var is_parachute_active: bool = true
var is_settled: bool = false


func _ready() -> void:
	# Make sure the body is awake so it reacts to forces immediately
	sleeping = false

	# Connect to the sleeping_state_changed signal so we know when physics puts it to sleep
	sleeping_state_changed.connect(_on_sleeping_state_changed)
	
	$ScreenNotifier.screen_exited.connect(_on_screen_exited)

	print("Block ready")

func _on_screen_exited() -> void:
	# If the block leaves the visible screen area while it's still active,
	# we consider that a failure / game over condition.
	if not is_settled:
		print("Block went off-screen, emitting out_of_view")
		emit_signal("out_of_view", self)
		


func _physics_process(delta: float) -> void:
	if is_parachute_active and not is_settled:
		_handle_parachute_movement(delta)


func _handle_parachute_movement(_delta: float) -> void:
	# 1. Parachute effect (counter gravity)
	var default_gravity: float = ProjectSettings.get_setting("physics/2d/default_gravity")
	var gravity_dir: Vector2 = ProjectSettings.get_setting("physics/2d/default_gravity_vector")
	var gravity_vec: Vector2 = gravity_dir * default_gravity * mass

	apply_central_force(-gravity_vec * PARACHUTE_UPWARD_FORCE)

	# 2. Player input movement
	var input_detected := false

	if Input.is_action_pressed("ui_left"):
		apply_central_force(Vector2(-SIDE_FORCE_STRENGTH, 0.0))
		input_detected = true

	if Input.is_action_pressed("ui_right"):
		apply_central_force(Vector2(SIDE_FORCE_STRENGTH, 0.0))
		input_detected = true

	if Input.is_action_pressed("ui_up"):
		angular_velocity = clamp(angular_velocity - ROTATE_SPEED, -5.0, 5.0)
		input_detected = true

	if Input.is_action_pressed("ui_down"):
		apply_central_force(Vector2(0.0, SIDE_FORCE_STRENGTH * 2.0))
		input_detected = true

	if input_detected:
		sleeping = false

	# 3. Clamp fall speed
	if linear_velocity.y > MAX_VERTICAL_SPEED:
		linear_velocity.y = MAX_VERTICAL_SPEED
		

func _on_sleeping_state_changed() -> void:
	# This gets called whenever Godot toggles sleeping on/off.
	# We care about the moment it goes to sleep (has fully settled).
	if sleeping and not is_settled:
		is_settled = true
		is_parachute_active = false

		print("Block settled, emitting signal")
		emit_signal("settled", self)
