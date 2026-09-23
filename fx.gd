extends CharacterBody2D

@export var target: CharacterBody2D         # drag your player here in the Inspector
@export var goal: CharacterBody2D           # the Xi sprite - touching it wins
@export var speed := 120.0           # pixels per second (lower = slower)
@export var smoothing := 3.0        # how softly it speeds up / turns (lower = softer)

var message_label: Label
var game_over := false


func _ready() -> void:
	# Keep running while the game is paused, so Enter can still restart
	process_mode = Node.PROCESS_MODE_ALWAYS

	# Nothing assigned in the Inspector? Use the nodes from the main scene.
	if target == null:
		target = get_parent().get_node_or_null("CharacterBody2D")
		if target == null:
			push_error("fx: no target found - assign one in the Inspector")
	if goal == null:
		goal = get_parent().get_node_or_null("CharacterBody2D2")
		if goal == null:
			push_error("fx: no goal found - assign one in the Inspector")

	# Ignore the tiles' collision shapes so it can glide over the map
	collision_mask = 0

	# Lose: our own hitbox touches the player
	add_detector(self, _on_caught)
	# Win: the player touches the goal's hitbox
	if goal != null:
		add_detector(goal, _on_goal_reached)

	# End-of-game text, hidden until someone wins or loses
	var ui := CanvasLayer.new()
	message_label = Label.new()
	message_label.set_anchors_preset(Control.PRESET_FULL_RECT)
	message_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	message_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	# LaTeX look: italic Computer Modern if installed, otherwise Times New Roman italic
	var latex_font := SystemFont.new()
	latex_font.font_names = PackedStringArray(["CMU Serif", "Latin Modern Roman", "Times New Roman", "serif"])
	latex_font.font_italic = true
	message_label.add_theme_font_override("font", latex_font)
	message_label.add_theme_font_size_override("font_size", 64)
	message_label.add_theme_color_override("font_color", Color.BLACK)
	message_label.visible = false
	ui.add_child(message_label)
	add_child(ui)


# Adds an Area2D with a copy of `owner_body`'s CollisionShape2D,
# calling `callback` when the player enters it.
func add_detector(owner_body: Node2D, callback: Callable) -> void:
	var area := Area2D.new()
	area.collision_layer = 0
	area.collision_mask = 1          # the layer the player is on
	area.add_child(owner_body.get_node("CollisionShape2D").duplicate())
	owner_body.add_child.call_deferred(area)
	area.body_entered.connect(func(body: Node2D) -> void:
		if body == target:  # ignore the tiles and everything else
			callback.call()
	)


func _physics_process(delta: float) -> void:
	if target == null or game_over:
		return

	var to_target := target.global_position - global_position

	# Where it wants to go at full speed
	var desired := to_target.normalized() * speed
	# Ease the current velocity toward that, which makes it smooth
	velocity = velocity.lerp(desired, smoothing * delta)

	move_and_slide()


func _on_caught() -> void:
	end_game("Game over")


func _on_goal_reached() -> void:
	end_game("You won")


func end_game(text: String) -> void:
	if game_over:
		return  # already decided
	game_over = true
	message_label.text = text
	message_label.visible = true
	get_tree().paused = true   # freeze player and follower


func _unhandled_input(event: InputEvent) -> void:
	# Enter (main or numpad) restarts the game at any time
	if event is InputEventKey and event.pressed and not event.echo \
			and (event.keycode == KEY_ENTER or event.keycode == KEY_KP_ENTER):
		get_tree().paused = false
		get_tree().reload_current_scene()
