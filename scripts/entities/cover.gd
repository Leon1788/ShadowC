# cover.gd
# Cover Entity - auf Grid platzierbar
# Speicherort: res://scripts/entities/cover.gd

@tool
extends Node3D

class_name Cover

# Inspector Properties
@export var grid_x: int = 0:
	set(value):
		grid_x = clamp(value, 0, 39)
		update_position()

@export var grid_z: int = 0:
	set(value):
		grid_z = clamp(value, 0, 39)
		update_position()

@export_enum("0.3m", "0.8m", "3m") var height_type: int = 1:
	set(value):
		height_type = value
		update_cover()

# Internal
var heights = [0.3, 0.8, 3.0]
var current_height: float = 0.8
var mesh_instance: MeshInstance3D = null
var static_body: StaticBody3D = null
var collision_shape: CollisionShape3D = null
var selection_area: Area3D = null

const GROUND_LEVEL = 0.0
const TILE_SIZE = 1.0

func _ready():
	if Engine.is_editor_hint():
		return
	setup_cover()

func _process(_delta: float):
	pass

func setup_cover() -> void:
	current_height = heights[height_type]
	
	# Cleanup
	if mesh_instance:
		mesh_instance.queue_free()
	if static_body:
		static_body.queue_free()
	
	# Erstelle StaticBody3D
	static_body = StaticBody3D.new()
	static_body.name = "CoverPhysics"
	add_child(static_body)
	
	# Erstelle MeshInstance3D
	mesh_instance = MeshInstance3D.new()
	mesh_instance.name = "CoverMesh"
	add_child(mesh_instance)
	
	# Box Mesh
	var box_mesh = BoxMesh.new()
	box_mesh.size = Vector3(TILE_SIZE, current_height, TILE_SIZE)
	mesh_instance.mesh = box_mesh
	
	# Material
	var material = StandardMaterial3D.new()
	material.albedo_color = Color.GRAY
	mesh_instance.set_surface_override_material(0, material)
	
	# Collider
	collision_shape = CollisionShape3D.new()
	collision_shape.name = "CoverCollider"
	var box_shape = BoxShape3D.new()
	box_shape.size = Vector3(TILE_SIZE, current_height, TILE_SIZE)
	collision_shape.shape = box_shape
	static_body.add_child(collision_shape)
	
	# Editor Selection Area
	selection_area = Area3D.new()
	selection_area.name = "SelectionArea"
	add_child(selection_area)
	
	var selection_collider = CollisionShape3D.new()
	var selection_shape = BoxShape3D.new()
	selection_shape.size = Vector3(TILE_SIZE, current_height, TILE_SIZE)
	selection_collider.shape = selection_shape
	selection_area.add_child(selection_collider)
	
	# Position
	update_position()

func update_position() -> void:
	var world_x = grid_x * TILE_SIZE
	var world_z = grid_z * TILE_SIZE
	var world_y = GROUND_LEVEL
	
	position = Vector3(world_x, world_y, world_z)
	
	# Mesh + Collider + SelectionArea bei Tile-Ecke
	if mesh_instance:
		mesh_instance.position = Vector3(TILE_SIZE / 2.0, current_height / 2.0, TILE_SIZE / 2.0)
	if collision_shape:
		collision_shape.position = Vector3(TILE_SIZE / 2.0, current_height / 2.0, TILE_SIZE / 2.0)
	if selection_area:
		for child in selection_area.get_children():
			if child is CollisionShape3D:
				child.position = Vector3(TILE_SIZE / 2.0, current_height / 2.0, TILE_SIZE / 2.0)

func update_cover() -> void:
	if is_node_ready() or Engine.is_editor_hint():
		setup_cover()

func get_grid_position() -> Vector2i:
	return Vector2i(grid_x, grid_z)

func get_height() -> float:
	return current_height
