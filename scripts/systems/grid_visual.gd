# grid_visual.gd
# Grid Visualisierung mit Editor-Properties
# Speicherort: res://scripts/systems/grid_visual.gd

@tool
extends Node3D

class_name GridVisual

# Editor Properties
@export var grid_width: int = 40:
	set(value):
		grid_width = max(1, value)
		update_grid()

@export var grid_height: int = 40:
	set(value):
		grid_height = max(1, value)
		update_grid()

@export var tile_size: float = 1.0:
	set(value):
		tile_size = max(0.1, value)
		update_grid()

@export var show_grid_lines: bool = true:
	set(value):
		show_grid_lines = value
		if grid_lines:
			grid_lines.visible = show_grid_lines

@export var tile_color: Color = Color.BLACK:
	set(value):
		tile_color = value
		update_grid()

@export var line_color: Color = Color.WHITE:
	set(value):
		line_color = value
		update_grid()

# Internal
var mesh_instance: MeshInstance3D = null
var grid_lines: MeshInstance3D = null
var blocked_tiles: PackedInt32Array = []

func _ready():
	print("[GridVisual] Initialisiere...")
	create_grid()
	print("[GridVisual] Bereit")

func initialize(map_root: Node3D = null, grid_mgr: GridManager = null) -> void:
	print("[GridVisual] Initialize aufgerufen")
	create_grid()

func update_grid() -> void:
	if is_node_ready():
		create_grid()

func create_grid() -> void:
	# Cleanup alte Meshes
	if mesh_instance:
		mesh_instance.queue_free()
	if grid_lines:
		grid_lines.queue_free()
	
	create_grid_mesh()
	create_grid_lines()

func create_grid_mesh() -> void:
	var surface_tool = SurfaceTool.new()
	surface_tool.begin(Mesh.PRIMITIVE_TRIANGLES)
	
	for z in range(grid_height):
		for x in range(grid_width):
			var color = tile_color
			surface_tool.set_material(create_material(color))
			
			var x0 = x * tile_size
			var x1 = (x + 1) * tile_size
			var z0 = z * tile_size
			var z1 = (z + 1) * tile_size
			var y = 0.01
			
			surface_tool.add_vertex(Vector3(x0, y, z0))
			surface_tool.add_vertex(Vector3(x1, y, z0))
			surface_tool.add_vertex(Vector3(x1, y, z1))
			
			surface_tool.add_vertex(Vector3(x0, y, z0))
			surface_tool.add_vertex(Vector3(x1, y, z1))
			surface_tool.add_vertex(Vector3(x0, y, z1))
	
	var mesh = surface_tool.commit()
	mesh_instance = MeshInstance3D.new()
	mesh_instance.name = "GridMesh"
	mesh_instance.mesh = mesh
	add_child(mesh_instance)

func create_grid_lines() -> void:
	var points = PackedVector3Array()
	
	for x in range(grid_width + 1):
		points.append(Vector3(x * tile_size, 0.02, 0))
		points.append(Vector3(x * tile_size, 0.02, grid_height * tile_size))
	
	for z in range(grid_height + 1):
		points.append(Vector3(0, 0.02, z * tile_size))
		points.append(Vector3(grid_width * tile_size, 0.02, z * tile_size))
	
	var immediate_mesh = ImmediateMesh.new()
	immediate_mesh.surface_begin(Mesh.PRIMITIVE_LINES)
	
	for point in points:
		immediate_mesh.surface_add_vertex(point)
	
	immediate_mesh.surface_end()
	
	var line_material = StandardMaterial3D.new()
	line_material.albedo_color = line_color
	line_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	
	grid_lines = MeshInstance3D.new()
	grid_lines.name = "GridLines"
	grid_lines.mesh = immediate_mesh
	grid_lines.set_surface_override_material(0, line_material)
	grid_lines.visible = show_grid_lines
	add_child(grid_lines)

func create_material(color: Color) -> StandardMaterial3D:
	var material = StandardMaterial3D.new()
	material.albedo_color = color
	material.shading_mode = BaseMaterial3D.SHADING_MODE_PER_PIXEL
	return material

func get_grid_size() -> Vector2i:
	return Vector2i(grid_width, grid_height)

func get_tile_size() -> float:
	return tile_size
