extends CharacterBody2D

const MOVE_TIME := 0.15

@export var tile_map: TileMapLayer

var moving := false


func _ready() -> void:
	# Snap to the center of the tile we're standing on
	position = tile_map.map_to_local(get_cell())


func _physics_process(_delta: float) -> void:
	if moving:
		return

	var dir := Vector2i.ZERO
	if Input.is_key_pressed(KEY_D):
		dir = Vector2i.RIGHT
	elif Input.is_key_pressed(KEY_A):
		dir = Vector2i.LEFT
	elif Input.is_key_pressed(KEY_W):
		dir = Vector2i.UP
	elif Input.is_key_pressed(KEY_S):
		dir = Vector2i.DOWN

	if dir != Vector2i.ZERO:
		step(dir)


func get_cell() -> Vector2i:
	return tile_map.local_to_map(tile_map.to_local(global_position))


func is_blocked(cell: Vector2i) -> bool:
	var data := tile_map.get_cell_tile_data(cell)
	if data == null:
		return true  # no tile there = outside the map
	return data.get_custom_data("solid")


func step(dir: Vector2i) -> void:
	var target_cell := get_cell() + dir
	if is_blocked(target_cell):
		return

	var target := tile_map.to_global(tile_map.map_to_local(target_cell))

	moving = true
	var tween := create_tween()
	tween.tween_property(self, "global_position", target, MOVE_TIME)
	await tween.finished
	global_position = target
	moving = false
