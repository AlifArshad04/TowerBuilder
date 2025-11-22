extends Node2D

@export var BlockScene: PackedScene

# --- Safe zone config ---
const SAFE_X_MIN := -200.0   # left edge of safe zone
const SAFE_X_MAX := 200.0   # right edge of safe zone
const GROUND_Y   := 300.0   # y-position of your ground line (adjust!)

const SPAWN_Y := -350.0
var active_block: Node2D = null
var game_over: bool = false

@onready var game_over_panel: Control = $UI/GameOverPanel
@onready var score_label: Label = $UI/GameOverPanel/ScoreLabel

func _ready() -> void:
	
	get_tree().paused = false
	randomize()
	if BlockScene == null:
		push_error("ERROR: Link Block.tscn to BlockScene in the Inspector!")
		return
	
	
	
	game_over_panel.visible = false
	game_over = false

	#reset scoring state ---
	$ScoreManager.reset()
	

	spawn_block()


func _draw() -> void:
	# Draw a translucent green rectangle as the safe landing area
	var width := SAFE_X_MAX - SAFE_X_MIN
	var height := 30.0  # thickness of the bar

	var top_left := Vector2(SAFE_X_MIN, GROUND_Y - height)
	var size := Vector2(width, height)

	draw_rect(Rect2(top_left, size), Color(0, 1, 0, 0.2), true)
	draw_rect(Rect2(top_left, size), Color(0, 1, 0, 0.8), false, 2.0)


func spawn_block() -> void:
	if game_over:
		return

	# Pick a random x inside (or slightly outside) the safe zone
	var spawn_x := randf_range(SAFE_X_MIN - 100.0, SAFE_X_MAX + 100.0)
	var spawn_pos := Vector2(spawn_x, SPAWN_Y)

	var new_block = BlockScene.instantiate()
	new_block.global_position = spawn_pos

	# Connect the 'settled' signal from this block to Main
	if new_block.has_signal("settled"):
		new_block.settled.connect(_on_block_settled)
	else:
		push_warning("Spawned block has no 'settled' signal!")
	
	if new_block.has_signal("out_of_view"):
		new_block.out_of_view.connect(_on_block_out_of_view)
	else:
		push_warning("Spawned block has no 'out_of_view' signal!")
	
	add_child(new_block)
	active_block = new_block
	print("Spawned new block at x =", spawn_x)


#track elapsed time for the score ---
func _process(delta: float) -> void:
	if game_over:
		return
	$ScoreManager.elapsed_time += delta


func _on_block_settled(block: Node) -> void:
	print("Main: Block settled:", block)
	
	#update max tower height for the score ---
	var height_above_ground = max(0.0, GROUND_Y - block.global_position.y)
	if height_above_ground > $ScoreManager.max_height:
		$ScoreManager.max_height = height_above_ground
	
	# Only react if it's the current active block
	if block == active_block:
		active_block = null
		# Defer spawning to the next frame so physics fully settles.
		call_deferred("spawn_block")


func _on_block_out_of_view(block: Node) -> void:
	print("Main: Block went out of view:", block)
	_game_over()


func _game_over() -> void:
	if game_over:
		return

	game_over = true
	print("=== GAME OVER ===")

	var final_score = $ScoreManager.get_total_score()
	print("Final score:", final_score)

	# Show score in the UI (adjust the node path if your label is different)
	if is_instance_valid(score_label):
		score_label.text = str(final_score)

	# Show the Game Over UI
	game_over_panel.visible = true

	# Pause the game so blocks stop moving
	get_tree().paused = true


func _unhandled_input(event: InputEvent) -> void:
	if game_over and event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_R:
			print("Restarting game...")
			get_tree().paused = false
			get_tree().reload_current_scene()
