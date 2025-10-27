# pathfinder.gd
# A* Pathfinding für Merc-Bewegung
# Speicherort: res://scripts/systems/pathfinder.gd

extends Node

class_name Pathfinder

class PathNode:
	var pos: Vector2i
	var g_cost: int
	var h_cost: int
	var f_cost: int
	var parent: PathNode = null

func create_path_node(p: Vector2i, g: int, h: int) -> PathNode:
	var node = PathNode.new()
	node.pos = p
	node.g_cost = g
	node.h_cost = h
	node.f_cost = g + h
	return node

const AP_PER_TILE = 2
const GRID_SIZE = 40

var grid_data: Dictionary = {}
var blocked_tiles: Array = []
var merc_manager: MercManager = null

func _ready():
	pass

func initialize(grid_mgr: GridManager, merc_mgr: MercManager = null) -> void:
	print("[Pathfinder] Initialisiere...")
	grid_data = grid_mgr.grid_data
	merc_manager = merc_mgr
	print("[Pathfinder] Bereit")

func find_path(start: Vector2i, goal: Vector2i, max_ap: int) -> Array:
	if not is_valid_pos(start) or not is_valid_pos(goal):
		return []
	
	if not is_walkable(goal):
		return []
	
	var open_list: Array = []
	var closed_list: Dictionary = {}
	
	var start_node = create_path_node(start, 0, calculate_heuristic(start, goal))
	open_list.append(start_node)
	
	while open_list.size() > 0:
		# Finde Node mit niedrigstem f_cost
		var current_idx = 0
		for i in range(open_list.size()):
			if open_list[i].f_cost < open_list[current_idx].f_cost:
				current_idx = i
		
		var current = open_list[current_idx]
		
		# Goal erreicht?
		if current.pos == goal:
			return reconstruct_path(current)
		
		open_list.remove_at(current_idx)
		closed_list[current.pos] = true
		
		# Überprüfe alle 8 Nachbarn (inkl. Diagonal)
		for neighbor_pos in get_neighbors(current.pos):
			if not is_valid_pos(neighbor_pos):
				continue
			
			if closed_list.has(neighbor_pos):
				continue
			
			if not is_walkable(neighbor_pos):
				continue
			
			# Diagonal-Bewegung: Überprüfe ob man um Ecke gehen kann
			var dx = neighbor_pos.x - current.pos.x
			var dy = neighbor_pos.y - current.pos.y
			
			if dx != 0 and dy != 0:  # Diagonal
				# Prüfe beide angrenzenden Tiles
				var side1 = current.pos + Vector2i(dx, 0)
				var side2 = current.pos + Vector2i(0, dy)
				
				if not is_walkable(side1) or not is_walkable(side2):
					continue  # Kann nicht diagonal gehen wenn eine Seite blockiert
			
			# g_cost = bisherige Kosten + AP für diesen Tile
			var new_g_cost = current.g_cost + AP_PER_TILE
			
			# AP-Limit überschritten?
			if new_g_cost > max_ap:
				continue
			
			# Schon in Open List?
			var existing = null
			for node in open_list:
				if node.pos == neighbor_pos:
					existing = node
					break
			
			if existing != null:
				# Besserer Weg gefunden?
				if new_g_cost < existing.g_cost:
					existing.g_cost = new_g_cost
					existing.f_cost = existing.g_cost + existing.h_cost
					existing.parent = current
			else:
				# Neuer Node
				var h = calculate_heuristic(neighbor_pos, goal)
				var new_node = create_path_node(neighbor_pos, new_g_cost, h)
				new_node.parent = current
				open_list.append(new_node)
	
	# Kein Weg gefunden
	return []

func reconstruct_path(node) -> Array:
	var path: Array = []
	var current = node
	
	while current != null:
		path.insert(0, current.pos)
		current = current.parent
	
	return path

func get_neighbors(pos: Vector2i) -> Array:
	var neighbors: Array = []
	
	# 8 Richtungen (inkl. Diagonal)
	for dx in [-1, 0, 1]:
		for dy in [-1, 0, 1]:
			if dx == 0 and dy == 0:
				continue
			
			var neighbor = pos + Vector2i(dx, dy)
			neighbors.append(neighbor)
	
	return neighbors

func calculate_heuristic(pos: Vector2i, goal: Vector2i) -> int:
	# Diagonal Distance
	var dx = abs(pos.x - goal.x)
	var dy = abs(pos.y - goal.y)
	var diagonal = min(dx, dy)
	var straight = max(dx, dy) - diagonal
	return (diagonal * 3 + straight * 2) * AP_PER_TILE

func is_valid_pos(pos: Vector2i) -> bool:
	return pos.x >= 0 and pos.x < GRID_SIZE and pos.y >= 0 and pos.y < GRID_SIZE

func is_walkable(pos: Vector2i) -> bool:
	if not grid_data.has(pos):
		return false
	
	var tile = grid_data[pos]
	if not tile.get("walkable", false):
		return false
	
	# Überprüfe ob Merc auf diesem Tile ist
	if merc_manager:
		for merc in merc_manager.get_all_mercs():
			if merc.get_grid_position() == pos:
				return false
	
	return true

func get_path_cost(path: Array) -> int:
	return (path.size() - 1) * AP_PER_TILE
