# path_renderer.gd
# Visualisiert die geplante Bewegungsroute mit Linien
# Speicherort: res://scripts/systems/path_renderer.gd

extends Node3D

class_name PathRenderer

var path_container: Node3D = null
var path_lines: MeshInstance3D = null
var current_path: Array = []

const TILE_SIZE = 1.0
const LINE_HEIGHT = 0.02
const LINE_COLOR = Color.GREEN

func _ready():
	pass

func initialize() -> void:
	# Container für alle Path-Linien
	path_container = Node3D.new()
	path_container.name = "PathContainer"
	add_child(path_container)

func draw_path(walkable_path: Array, blocked_path: Array = []) -> void:
	if walkable_path.is_empty() and blocked_path.is_empty():
		clear_path()
		return
	
	current_path = walkable_path.duplicate()
	render_path_lines(walkable_path, blocked_path)

func render_path_lines(path: Array, _blocked_path: Array) -> void:
	# Cleanup altes
	clear_path()
	
	# Grüne Linien
	var immediate_mesh = ImmediateMesh.new()
	immediate_mesh.surface_begin(Mesh.PRIMITIVE_LINES)
	
	for i in range(path.size() - 1):
		var current_grid = path[i]
		var next_grid = path[i + 1]
		
		var current_world = grid_to_world(current_grid)
		var next_world = grid_to_world(next_grid)
		
		immediate_mesh.surface_add_vertex(current_world)
		immediate_mesh.surface_add_vertex(next_world)
	
	immediate_mesh.surface_end()
	
	# Material grün
	var line_material = StandardMaterial3D.new()
	line_material.albedo_color = Color.GREEN
	line_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	line_material.no_depth_test = false
	
	path_lines = MeshInstance3D.new()
	path_lines.name = "PathLines"
	path_lines.mesh = immediate_mesh
	path_lines.set_surface_override_material(0, line_material)
	path_container.add_child(path_lines)
	
	# Rote Linien (blocked part)
	if _blocked_path.size() > 1:
		var blocked_mesh = ImmediateMesh.new()
		blocked_mesh.surface_begin(Mesh.PRIMITIVE_LINES)
		
		for i in range(_blocked_path.size() - 1):
			var current_grid = _blocked_path[i]
			var next_grid = _blocked_path[i + 1]
			
			var current_world = grid_to_world(current_grid)
			var next_world = grid_to_world(next_grid)
			
			blocked_mesh.surface_add_vertex(current_world)
			blocked_mesh.surface_add_vertex(next_world)
		
		blocked_mesh.surface_end()
		
		var red_material = StandardMaterial3D.new()
		red_material.albedo_color = Color.RED
		red_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		red_material.no_depth_test = false
		
		var blocked_lines = MeshInstance3D.new()
		blocked_lines.name = "BlockedPathLines"
		blocked_lines.mesh = blocked_mesh
		blocked_lines.set_surface_override_material(0, red_material)
		path_container.add_child(blocked_lines)

func grid_to_world(grid_pos: Vector2i) -> Vector3:
	var world_x = grid_pos.x * TILE_SIZE + TILE_SIZE / 2.0
	var world_z = grid_pos.y * TILE_SIZE + TILE_SIZE / 2.0
	var world_y = LINE_HEIGHT
	return Vector3(world_x, world_y, world_z)

func clear_path() -> void:
	if path_container:
		for child in path_container.get_children():
			child.queue_free()
	current_path = []

func get_current_path() -> Array:
	return current_path
