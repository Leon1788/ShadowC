# movement_component.gd
# Verwaltet Movement, Pathfinding und Grid-Position
# Speicherort: res://scripts/components/movement_component.gd

extends Node

class_name MovementComponent

const TILE_SIZE = 1.0
const CAPSULE_HEIGHT = 1.8
const AP_PER_TILE = 2

var grid_x: int = 0
var grid_z: int = 0
var world_position: Vector3 = Vector3.ZERO

var is_moving: bool = false
var move_path: Array = []
var move_progress: float = 0.0
var move_speed: float = 5.0
var current_path_idx: int = 0

var ap_component: APComponent = null
var parent_node: Node3D = null

signal movement_started(target: Vector2i)
signal movement_completed(final_pos: Vector2i)
signal position_changed(grid_pos: Vector2i)

func _ready():
	pass

func initialize(grid_pos_x: int, grid_pos_z: int, parent: Node3D, ap_comp: APComponent = null) -> void:
	grid_x = grid_pos_x
	grid_z = grid_pos_z
	parent_node = parent
	ap_component = ap_comp
	
	update_position()
	print("[MovementComponent] Initialisiert | Grid: (%d, %d)" % [grid_x, grid_z])

func update_position() -> void:
	world_position = grid_to_world(Vector2i(grid_x, grid_z))
	if parent_node:
		parent_node.position = world_position

func grid_to_world(grid_pos: Vector2i) -> Vector3:
	var world_x = grid_pos.x * TILE_SIZE + TILE_SIZE / 2.0
	var world_z = grid_pos.y * TILE_SIZE + TILE_SIZE / 2.0
	var world_y = CAPSULE_HEIGHT / 2.0
	return Vector3(world_x, world_y, world_z)

func get_grid_position() -> Vector2i:
	return Vector2i(grid_x, grid_z)

func set_grid_position(new_x: int, new_z: int) -> void:
	grid_x = clamp(new_x, 0, 39)
	grid_z = clamp(new_z, 0, 39)
	update_position()
	position_changed.emit(get_grid_position())

func move_to(path: Array) -> bool:
	if path.is_empty():
		return false
	
	var cost = (path.size() - 1) * AP_PER_TILE
	
	# AP Check
	if ap_component and not ap_component.has_ap(cost):
		print("[MovementComponent] Nicht genug AP! Benötigt: %d, Verfügbar: %d" % [cost, ap_component.get_remaining_ap()])
		return false
	
	# AP ausgeben
	if ap_component:
		ap_component.spend_ap(cost)
	
	move_path = path
	current_path_idx = 0
	is_moving = true
	
	movement_started.emit(path[-1])
	print("[MovementComponent] Bewegung gestartet zu Grid (%d, %d) | AP Cost: %d" % [path[-1].x, path[-1].y, cost])
	
	return true

func update_movement(delta: float) -> void:
	if move_path.is_empty() or current_path_idx >= move_path.size():
		is_moving = false
		current_path_idx = 0
		movement_completed.emit(get_grid_position())
		return
	
	var target_grid = move_path[current_path_idx]
	var target_world = grid_to_world(target_grid)
	
	var current_world = parent_node.position
	var distance = current_world.distance_to(target_world)
	
	if distance < 0.1:
		# Tile erreicht
		grid_x = target_grid.x
		grid_z = target_grid.y
		current_path_idx += 1
		position_changed.emit(get_grid_position())
		return
	
	# Lerp zu nächstem Tile
	var direction = (target_world - current_world).normalized()
	parent_node.position += direction * move_speed * delta

func get_is_moving() -> bool:
	return is_moving

func get_current_path() -> Array:
	return move_path
