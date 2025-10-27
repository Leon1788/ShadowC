# grid_highlighter.gd
# Hebt Grid-Tiles hervor: Grün = erreichbar, Rot = nicht erreichbar
# Speicherort: res://scripts/systems/grid_highlighter.gd

extends Node3D

class_name GridHighlighter

var camera: Camera3D = null
var pathfinder: Pathfinder = null
var merc_manager: MercManager = null
var highlighted_tile: Vector2i = Vector2i(-1, -1)
var highlight_mesh: MeshInstance3D = null
var highlight_material: StandardMaterial3D = null
var reachability_cache: Dictionary = {}
var last_selected_merc = null
var last_max_ap: int = 0

const TILE_SIZE = 1.0
const HIGHLIGHT_HEIGHT = 0.03
const GRID_SIZE = 40

func _ready():
	pass

func initialize(cam: Camera3D, pf: Pathfinder = null, merc_mgr: MercManager = null) -> void:
	print("[GridHighlighter] Initialisiere...")
	camera = cam
	pathfinder = pf
	merc_manager = merc_mgr
	setup_highlight_mesh()
	print("[GridHighlighter] Bereit")

func setup_highlight_mesh() -> void:
	# Material für Highlight
	highlight_material = StandardMaterial3D.new()
	highlight_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	highlight_material.albedo_color.a = 0.5

func _process(_delta: float):
	update_highlight()

func update_highlight() -> void:
	var mouse_pos = get_viewport().get_mouse_position()
	var grid_pos = screen_to_grid(mouse_pos)
	
	if grid_pos != highlighted_tile:
		if grid_pos != Vector2i(-1, -1):
			highlight_tile(grid_pos)
		else:
			clear_highlight()
		
		highlighted_tile = grid_pos

func screen_to_grid(screen_pos: Vector2) -> Vector2i:
	if not camera:
		return Vector2i(-1, -1)
	
	var from = camera.project_ray_origin(screen_pos)
	var normal = camera.project_ray_normal(screen_pos)
	
	var t = -from.y / normal.y if normal.y != 0 else 0
	var hit_pos = from + normal * t
	
	var grid_x = int(hit_pos.x / TILE_SIZE)
	var grid_z = int(hit_pos.z / TILE_SIZE)
	
	# Bounds check
	if grid_x < 0 or grid_x >= GRID_SIZE or grid_z < 0 or grid_z >= GRID_SIZE:
		return Vector2i(-1, -1)
	
	return Vector2i(grid_x, grid_z)

func highlight_tile(grid_pos: Vector2i) -> void:
	# Cleanup altes Mesh
	if highlight_mesh:
		highlight_mesh.queue_free()
	
	# Einfach gelb, keine Prüfung
	highlight_material.albedo_color = Color.YELLOW
	highlight_material.albedo_color.a = 0.5
	
	# Erstelle Quad für Highlight
	var surface_tool = SurfaceTool.new()
	surface_tool.begin(Mesh.PRIMITIVE_TRIANGLES)
	surface_tool.set_material(highlight_material)
	
	var x0 = grid_pos.x * TILE_SIZE
	var x1 = (grid_pos.x + 1) * TILE_SIZE
	var z0 = grid_pos.y * TILE_SIZE
	var z1 = (grid_pos.y + 1) * TILE_SIZE
	var y = 0.015
	
	surface_tool.add_vertex(Vector3(x0, y, z0))
	surface_tool.add_vertex(Vector3(x1, y, z0))
	surface_tool.add_vertex(Vector3(x1, y, z1))
	
	surface_tool.add_vertex(Vector3(x0, y, z0))
	surface_tool.add_vertex(Vector3(x1, y, z1))
	surface_tool.add_vertex(Vector3(x0, y, z1))
	
	var mesh = surface_tool.commit()
	
	highlight_mesh = MeshInstance3D.new()
	highlight_mesh.name = "HighlightMesh"
	highlight_mesh.mesh = mesh
	add_child(highlight_mesh)

func clear_highlight() -> void:
	if highlight_mesh:
		highlight_mesh.queue_free()
		highlight_mesh = null

func get_highlighted_tile() -> Vector2i:
	return highlighted_tile
