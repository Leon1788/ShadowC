# grid_manager.gd
# Verwaltet das 40x40 Grid, liest TileMap, stellt Grid-Daten bereit
# Speicherort: res://scripts/managers/grid_manager.gd

extends Node

class_name GridManager

const GRID_SIZE = 40
const TILE_SIZE = 1.0
const GROUND_LEVEL = 0.0
const FLOOR_HEIGHT = 3.0

var grid_size: Vector2i = Vector2i(GRID_SIZE, GRID_SIZE)
var tile_size: float = TILE_SIZE
var grid_data: Dictionary = {}  # Vector2i -> tile_type
var tilemap: TileMap = null

func _ready():
	pass

func initialize(scene_root: Node3D) -> bool:
	print("\n[GridManager] Initialisiere Grid...")
	
	# Initialisiere leeres Grid mit allen Tiles walkable
	initialize_empty_grid()
	
	# Lese Cover-Objekte
	read_cover_objects(scene_root)
	
	print("[GridManager] Grid initialisiert")
	print("[GridManager] Groesse: %d x %d" % [grid_size.x, grid_size.y])
	print("[GridManager] Tile Size: %.1f" % tile_size)
	print("[GridManager] Tiles in Grid: %d" % grid_data.size())
	
	return true

func initialize_empty_grid() -> void:
	for z in range(grid_size.y):
		for x in range(grid_size.x):
			var pos = Vector2i(x, z)
			grid_data[pos] = {
				"type": "grass",
				"walkable": true,
				"source_id": 0
			}

func read_tilemap_data() -> void:
	var used_cells = tilemap.get_used_cells(0)
	
	for cell_pos in used_cells:
		var source_id = tilemap.get_cell_source_id(0, cell_pos)
		var tile_type = get_tile_type_from_source(source_id)
		var walkable = tile_type != "wall"
		
		grid_data[cell_pos] = {
			"type": tile_type,
			"walkable": walkable,
			"source_id": source_id
		}

func get_tile_type_from_source(source_id: int) -> String:
	match source_id:
		0:
			return "grass"
		1:
			return "wall"
		_:
			return "grass"

func read_cover_objects(scene_root: Node3D) -> void:
	var blocked_count = 0
	var children = scene_root.get_children()
	
	for child in children:
		if child.name.begins_with("Cover"):
			var world_pos = child.global_position
			var grid_pos = world_to_grid(world_pos)
			
			if is_valid_position(grid_pos):
				if grid_data.has(grid_pos):
					grid_data[grid_pos]["walkable"] = false
					blocked_count += 1
				else:
					grid_data[grid_pos] = {
						"type": "cover",
						"walkable": false,
						"source_id": -1
					}
					blocked_count += 1
	
	print("[GridManager] Cover-Objekte gelesen: %d" % blocked_count)

func is_valid_position(grid_pos: Vector2i) -> bool:
	return grid_pos.x >= 0 and grid_pos.x < grid_size.x and grid_pos.y >= 0 and grid_pos.y < grid_size.y

func is_walkable(grid_pos: Vector2i) -> bool:
	if not is_valid_position(grid_pos):
		return false
	
	if not grid_data.has(grid_pos):
		return false
	
	return grid_data[grid_pos]["walkable"]

func get_tile_at(grid_pos: Vector2i) -> Dictionary:
	if grid_data.has(grid_pos):
		return grid_data[grid_pos]
	return {}

func grid_to_world(grid_pos: Vector2i, floor_level: int = 0) -> Vector3:
	var x = grid_pos.x * tile_size
	var z = grid_pos.y * tile_size
	var y = GROUND_LEVEL + (floor_level * FLOOR_HEIGHT)
	return Vector3(x, y, z)

func world_to_grid(world_pos: Vector3) -> Vector2i:
	var grid_x = int(world_pos.x / tile_size)
	var grid_y = int(world_pos.z / tile_size)
	return Vector2i(grid_x, grid_y)

func get_grid_bounds() -> Rect2i:
	return Rect2i(0, 0, grid_size.x, grid_size.y)

func get_all_walkable_tiles() -> Array:
	var walkable_tiles = []
	for pos in grid_data.keys():
		if grid_data[pos]["walkable"]:
			walkable_tiles.append(pos)
	return walkable_tiles

func print_grid_info() -> void:
	print("\n[GridManager] === GRID INFO ===")
	print("Groesse: %d x %d" % [grid_size.x, grid_size.y])
	print("Tile Size: %.1f" % tile_size)
	print("Walkable Tiles: %d" % get_all_walkable_tiles().size())
	print("World Bounds: (0,0) bis (%.1f, %.1f)" % [grid_size.x * tile_size, grid_size.y * tile_size])
	print("================\n")
