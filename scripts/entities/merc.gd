# merc.gd
# Söldner Entity mit AP-System und Bewegung
# Speicherort: res://scripts/entities/merc.gd

@tool
extends Node3D

class_name Merc

# Inspector Properties - wie Cover editierbar
@export var grid_x: int = 0:
	set(value):
		grid_x = clamp(value, 0, 39)
		update_position()

@export var grid_z: int = 0:
	set(value):
		grid_z = clamp(value, 0, 39)
		update_position()

@export var merc_name: String = "Merc_01"
@export var health: int = 100
@export var max_health: int = 100

# Internal vars
var heights = [0.3, 0.8, 3.0]
var current_height: float = 0.8
var capsule_mesh: MeshInstance3D = null
var collision_shape: CollisionShape3D = null
var character_body: CharacterBody3D = null
var material: StandardMaterial3D = null

# Stance System
enum STANCE { STANDING, CROUCH, PRONE }
var current_stance: int = STANCE.STANDING
var stance_height = {
	STANCE.STANDING: 1.6,
	STANCE.CROUCH: 1.0,
	STANCE.PRONE: 0.3
}
var facing_direction: Vector2i = Vector2i(1, 0)

const TILE_SIZE = 1.0
const CAPSULE_HEIGHT = 1.8
const CAPSULE_RADIUS = 0.3
const MAX_AP = 50

# Runtime
var is_selected: bool = false
var current_ap: int = MAX_AP
var max_ap: int = MAX_AP
var is_moving: bool = false
var move_path: Array = []
var move_progress: float = 0.0
var move_speed: float = 5.0
var current_path_idx: int = 0

func _ready():
	if Engine.is_editor_hint():
		return
	setup_merc()
	current_ap = MAX_AP

func _process(delta: float):
	if Engine.is_editor_hint():
		return
	
	if is_moving:
		update_movement(delta)

func setup_merc() -> void:
	if Engine.is_editor_hint():
		return
	
	print("[Merc %s] Setup startet" % merc_name)
	current_height = heights[1]
	
	# Cleanup
	if capsule_mesh:
		capsule_mesh.queue_free()
	if character_body:
		character_body.queue_free()
	
	# CharacterBody3D für Bewegung
	character_body = CharacterBody3D.new()
	character_body.name = "MercBody"
	add_child(character_body)
	print("[Merc %s] CharacterBody3D erstellt" % merc_name)
	
	# Capsule Mesh
	capsule_mesh = MeshInstance3D.new()
	capsule_mesh.name = "MercMesh"
	var capsule = CapsuleMesh.new()
	capsule.height = CAPSULE_HEIGHT
	capsule.radius = CAPSULE_RADIUS
	capsule_mesh.mesh = capsule
	character_body.add_child(capsule_mesh)
	
	# Material
	material = StandardMaterial3D.new()
	material.albedo_color = Color.BLUE
	capsule_mesh.set_surface_override_material(0, material)
	
	# Collider
	collision_shape = CollisionShape3D.new()
	collision_shape.name = "MercCollider"
	var capsule_shape = CapsuleShape3D.new()
	capsule_shape.height = CAPSULE_HEIGHT
	capsule_shape.radius = CAPSULE_RADIUS
	collision_shape.shape = capsule_shape
	character_body.add_child(collision_shape)
	
	print("[Merc %s] Setup fertig" % merc_name)
	update_position()
	update_visual()

func update_position() -> void:
	var world_x = grid_x * TILE_SIZE + TILE_SIZE / 2.0
	var world_z = grid_z * TILE_SIZE + TILE_SIZE / 2.0
	var world_y = CAPSULE_HEIGHT / 2.0
	
	position = Vector3(world_x, world_y, world_z)

func update_movement(delta: float) -> void:
	if move_path.is_empty() or current_path_idx >= move_path.size():
		is_moving = false
		current_path_idx = 0
		return
	
	var target_grid = move_path[current_path_idx]
	var target_world = grid_to_world(target_grid)
	
	var current_world = position
	var distance = current_world.distance_to(target_world)
	
	if distance < 0.1:
		# Tile erreicht
		grid_x = target_grid.x
		grid_z = target_grid.y
		current_path_idx += 1
		return
	
	# Lerp zu nächstem Tile
	var direction = (target_world - current_world).normalized()
	position += direction * move_speed * delta

func grid_to_world(grid_pos: Vector2i) -> Vector3:
	var world_x = grid_pos.x * TILE_SIZE + TILE_SIZE / 2.0
	var world_z = grid_pos.y * TILE_SIZE + TILE_SIZE / 2.0
	var world_y = CAPSULE_HEIGHT / 2.0
	return Vector3(world_x, world_y, world_z)

func move_to(path: Array) -> bool:
	if path.is_empty():
		return false
	
	var cost = (path.size() - 1) * 2
	
	if cost > current_ap:
		return false
	
	current_ap -= cost
	move_path = path
	current_path_idx = 0
	is_moving = true
	
	return true

func select() -> void:
	is_selected = true
	update_visual()

func deselect() -> void:
	is_selected = false
	update_visual()

func update_visual() -> void:
	if not material:
		return
	
	if is_selected:
		material.albedo_color = Color.YELLOW
		material.emission = Color.YELLOW * 0.5
		material.emission_enabled = true
	else:
		material.albedo_color = Color.BLUE
		material.emission_enabled = false

func get_grid_position() -> Vector2i:
	return Vector2i(grid_x, grid_z)

func set_grid_position(new_x: int, new_z: int) -> void:
	grid_x = clamp(new_x, 0, 39)
	grid_z = clamp(new_z, 0, 39)
	update_position()

func take_damage(damage: int) -> void:
	health -= damage
	print("[%s] Damage: %d | Health: %d/%d" % [merc_name, damage, health, max_health])
	if health <= 0:
		die()

func die() -> void:
	print("[%s] Gefallen!" % merc_name)
	queue_free()

func get_merc_name() -> String:
	return merc_name

func reset_ap() -> void:
	current_ap = max_ap

func change_stance(new_stance: int) -> bool:
	if new_stance == current_stance:
		return false
	
	if current_ap < 1:
		print("[Merc %s] Nicht genug AP für Stance-Wechsel!" % merc_name)
		return false
	
	if new_stance == STANCE.PRONE:
		var behind_pos = Vector2i(grid_x, grid_z) + facing_direction
		print("[Merc %s] Prone Check: hinter Position (%d, %d)" % [merc_name, behind_pos.x, behind_pos.y])
	
	current_stance = new_stance
	current_ap -= 1
	update_stance_visual()
	
	var stance_names = ["Standing", "Crouch", "Prone"]
	print("[Merc %s] Stance wechsel: %s (AP: %d)" % [merc_name, stance_names[new_stance], current_ap])
	
	return true

func update_stance_visual() -> void:
	var eye_height = stance_height[current_stance]
	print("[Merc %s] Eye Height: %.1f" % [merc_name, eye_height])
