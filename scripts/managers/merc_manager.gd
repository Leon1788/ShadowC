# merc_manager.gd
# Verwaltet alle Söldner in der Map - OHNE Spawning
# Speicherort: res://scripts/managers/merc_manager.gd

extends Node

class_name MercManager

var mercs: Dictionary = {}
var selected_merc = null
var pathfinder: Pathfinder = null

func _ready():
	pass

func initialize(grid_mgr: GridManager = null) -> void:
	print("[MercManager] Initialisiere...")
	
	# Pathfinder initialisieren wenn GridManager vorhanden
	if grid_mgr:
		pathfinder = Pathfinder.new()
		pathfinder.initialize(grid_mgr, self)
		print("[MercManager] Pathfinder initialisiert")
	
	print("[MercManager] Bereit")

func register_merc(merc) -> void:
	if merc:
		mercs[merc.merc_name] = merc
		print("[MercManager] Registered: %s at Grid (%d, %d)" % [merc.merc_name, merc.grid_x, merc.grid_z])

func get_merc(merc_name: String):
	return mercs.get(merc_name, null)

func get_all_mercs() -> Array:
	return mercs.values()

func remove_merc(merc_name: String) -> void:
	if mercs.has(merc_name):
		mercs[merc_name].queue_free()
		mercs.erase(merc_name)
		print("[MercManager] Removed: %s" % merc_name)

func print_mercs() -> void:
	print("[MercManager] === MERCS ===")
	for merc_name in mercs.keys():
		var merc = mercs[merc_name]
		var pos = merc.get_grid_position()
		print("  - %s: Grid (%d, %d) | Health: %d/%d | AP: %d/%d" % [merc_name, pos.x, pos.y, merc.health, merc.max_health, merc.current_ap, merc.max_ap])
	print("================")

func select_merc(merc) -> void:
	if selected_merc:
		selected_merc.deselect()
	
	selected_merc = merc
	if merc:
		merc.select()

func move_selected_merc(path) -> bool:
	if not selected_merc or path.is_empty():
		return false
	
	return selected_merc.move_to(path)

func get_selected_merc():
	return selected_merc
