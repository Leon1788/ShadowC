# grid_data.gd
# Resource-Klasse für Grid-Daten
# Speicherort: res://scripts/resources/grid_data.gd

extends Resource

class_name GridData

const GRID_WIDTH = 40
const GRID_HEIGHT = 40

@export var grid_tiles: Dictionary = {}

func _init() -> void:
	initialize_grid()

func initialize_grid() -> void:
	for z in range(GRID_HEIGHT):
		for x in range(GRID_WIDTH):
			var pos = Vector2i(x, z)
			grid_tiles[pos] = {
				"type": "grass",
				"walkable": true
			}

func get_tile(pos: Vector2i) -> Dictionary:
	if grid_tiles.has(pos):
		return grid_tiles[pos]
	return {}

func set_tile(pos: Vector2i, tile_type: String, walkable: bool) -> void:
	grid_tiles[pos] = {
		"type": tile_type,
		"walkable": walkable
	}

func is_walkable(pos: Vector2i) -> bool:
	if grid_tiles.has(pos):
		return grid_tiles[pos]["walkable"]
	return false

func get_all_tiles() -> Dictionary:
	return grid_tiles
