# merc_manager.gd
# Verwaltet alle Söldner in der Map
# Speicherort: res://scripts/managers/merc_manager.gd

extends Node

class_name MercManager

var mercs: Dictionary = {}
var merc_scene: PackedScene = null
var merc_counter: int = 0
var selected_merc = null
var pathfinder: Pathfinder = null

func _ready():
	pass

func initialize(merc_scene_path: String, grid_mgr: GridManager = null) -> void:
	print("[MercManager] Initialisiere...")
	merc_scene = load(merc_scene_path)
	
	if not merc_scene:
		print("[MercManager] FEHLER: Merc Scene nicht gefunden!")
		return
	
	# Pathfinder initialisieren wenn GridManager vorhanden
	if grid_mgr:
		pathfinder = Pathfinder.new()
		pathfinder.initialize(grid_mgr, self)
		print("[MercManager] Pathfinder initialisiert")
	
	print("[MercManager] Bereit")

func spawn_merc(grid_x: int, grid_z: int, merc_name: String = "") -> Merc:
	if not merc_scene:
		print("[MercManager] FEHLER: Merc Scene nicht geladen!")
		return null
	
	merc_counter += 1
	
	if merc_name == "":
		merc_name = "Merc_%d" % merc_counter
	
	var merc = merc_scene.instantiate()
	merc.merc_name = merc_name
	merc.grid_x = grid_x
	merc.grid_z = grid_z
	merc.setup_merc()
	
	get_parent().add_child(merc)
	mercs[merc_name] = merc
	
	print("[MercManager] Spawned: %s at Grid (%d, %d)" % [merc_name, grid_x, grid_z])
	
	return merc

func spawn_merc2(grid_x: int, grid_z: int, merc_name: String = "") -> Merc2:
	var merc2_scene = load("res://scenes/entities/merc/merc2.tscn")
	
	if not merc2_scene:
		print("[MercManager] FEHLER: Merc2 Scene nicht geladen!")
		return null
	
	merc_counter += 1
	
	if merc_name == "":
		merc_name = "Merc_%d" % merc_counter
	
	var merc = merc2_scene.instantiate()
	merc.merc_name = merc_name
	merc.grid_x = grid_x
	merc.grid_z = grid_z
	merc.setup_merc()
	
	get_parent().add_child(merc)
	mercs[merc_name] = merc
	
	print("[MercManager] Spawned: %s at Grid (%d, %d)" % [merc_name, grid_x, grid_z])
	
	return merc

func get_merc(merc_name: String) -> Merc:
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
