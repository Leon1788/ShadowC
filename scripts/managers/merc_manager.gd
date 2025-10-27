# merc_manager.gd
# Verwaltet alle Söldner in der Map
# Speicherort: res://scripts/managers/merc_manager.gd

extends Node

class_name MercManager

var mercs: Dictionary = {}
var selected_merc = null
var pathfinder: Pathfinder = null
var grid_manager: GridManager = null

signal merc_selected(merc: MercEntity)
signal merc_deselected(merc: MercEntity)

func _ready():
	pass

func initialize() -> void:
	print("[MercManager] Initialisiere...")
	
	# Pathfinder wird später initialisiert
	print("[MercManager] Bereit")

func set_grid_manager(grid_mgr: GridManager) -> void:
	grid_manager = grid_mgr
	
	# Pathfinder initialisieren wenn GridManager da
	if grid_manager:
		pathfinder = Pathfinder.new()
		pathfinder.initialize(grid_manager, self)
		print("[MercManager] Pathfinder initialisiert")

func add_merc(merc: MercEntity) -> void:
	if merc and merc is MercEntity:
		mercs[merc.merc_name] = merc
		
		# Setze GridManager SOFORT wenn vorhanden
		if grid_manager:
			merc.set_grid_manager(grid_manager)
		
		var pos = merc.get_grid_position()
		print("[MercManager] Registered: %s at Grid (%d, %d)" % [merc.merc_name, pos.x, pos.y])

func get_merc(merc_name: String):
	return mercs.get(merc_name, null)

func get_all_mercs() -> Array:
	return mercs.values()

func remove_merc(merc_name: String) -> void:
	if mercs.has(merc_name):
		mercs[merc_name].queue_free()
		mercs.erase(merc_name)
		print("[MercManager] Removed: %s" % merc_name)

func select_merc(merc) -> void:
	if selected_merc:
		selected_merc.deselect()
		merc_deselected.emit(selected_merc)
	
	selected_merc = merc
	if merc:
		merc.select()
		merc_selected.emit(merc)

func get_selected_merc():
	return selected_merc

func move_selected_merc(path: Array) -> bool:
	if not selected_merc or path.is_empty():
		return false
	
	return selected_merc.move_to(path)

func reset_all_ap() -> void:
	for merc in mercs.values():
		merc.reset_ap()
	print("[MercManager] AP Reset für alle Mercs")

func print_mercs() -> void:
	print("[MercManager] === MERCS ===")
	for merc_name in mercs.keys():
		var merc = mercs[merc_name]
		var pos = merc.get_grid_position()
		var current_ap = merc.get_current_ap()
		var max_ap = merc.get_max_ap()
		var current_health = merc.get_current_health()
		var max_health = merc.get_max_health()
		var stance_name = merc.stance_component.get_stance_name() if merc.stance_component else "NONE"
		print("  - %s: Grid (%d, %d) | Health: %d/%d | AP: %d/%d | Stance: %s" % [
			merc_name, pos.x, pos.y, current_health, max_health, current_ap, max_ap, stance_name
		])
	print("================")

func _on_round_started(round: int) -> void:
	print("[MercManager] Runde %d gestartet" % round)
	print_mercs()

func _on_round_ended(round: int) -> void:
	print("[MercManager] Runde %d beendet" % round)
