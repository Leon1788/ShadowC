# stance_component.gd
# Verwaltet Stance-System (Standing, Crouch, Prone)
# Speicherort: res://scripts/components/stance_component.gd

extends Node

class_name StanceComponent

enum STANCE { STANDING, CROUCH, PRONE }

var current_stance: int = STANCE.STANDING
var grid_manager: GridManager = null
var parent_merc: MercEntity = null

var stance_data = {
	STANCE.STANDING: {
		"height": 1.8,
		"eye_height": 1.6,
		"speed_multiplier": 1.0,
		"tiles_blocked": 1
	},
	STANCE.CROUCH: {
		"height": 1.0,
		"eye_height": 1.0,
		"speed_multiplier": 0.7,
		"tiles_blocked": 1
	},
	STANCE.PRONE: {
		"height": 0.3,
		"eye_height": 0.3,
		"speed_multiplier": 0.4,
		"tiles_blocked": 2
	}
}

var ap_component: APComponent = null

signal stance_changed(stance: int)

func _ready():
	pass

func initialize(ap_comp: APComponent = null, grid_mgr: GridManager = null, merc: MercEntity = null) -> void:
	ap_component = ap_comp
	grid_manager = grid_mgr
	parent_merc = merc
	current_stance = STANCE.STANDING
	print("[StanceComponent] Initialisiert | Stance: Standing")

func set_grid_manager(grid_mgr: GridManager) -> void:
	grid_manager = grid_mgr

func can_change_to_stance(new_stance: int) -> bool:
	# Gleiche Stance = kein Wechsel
	if new_stance == current_stance:
		return false
	
	# AP Check - Stance-Wechsel kostet 1 AP
	if ap_component and not ap_component.has_ap(1):
		return false
	
	# Prone = 2 Tiles benötigt
	if new_stance == STANCE.PRONE:
		if not grid_manager or not parent_merc:
			return false
		
		var merc_pos = parent_merc.get_grid_position()
		var occupied_tiles = get_occupied_tiles_for_stance(merc_pos, new_stance)
		
		# Prüfe ob alle Tiles frei sind
		for tile in occupied_tiles:
			if not grid_manager.is_tile_free(tile, parent_merc):
				return false
	
	return true

func change_stance(new_stance: int) -> bool:
	if not can_change_to_stance(new_stance):
		return false
	
	# AP ausgeben
	if ap_component:
		ap_component.spend_ap(1)
	
	# Stance wechseln
	current_stance = new_stance
	stance_changed.emit(current_stance)
	
	var stance_names = ["Standing", "Crouch", "Prone"]
	print("[StanceComponent] Stance wechsel: %s | AP Kosten: 1" % stance_names[new_stance])
	
	return true

func get_occupied_tiles_for_stance(merc_pos: Vector2i, stance: int) -> Array:
	var tiles = [merc_pos]
	
	if stance == STANCE.PRONE:
		# Prone belegt 2 Tiles in Z-Richtung (hinten)
		tiles.append(Vector2i(merc_pos.x, merc_pos.y + 1))
	
	return tiles

func get_current_stance() -> int:
	return current_stance

func get_stance_height() -> float:
	return stance_data[current_stance]["height"]

func get_eye_height() -> float:
	return stance_data[current_stance]["eye_height"]

func get_movement_speed_multiplier() -> float:
	return stance_data[current_stance]["speed_multiplier"]

func get_tiles_blocked() -> int:
	return stance_data[current_stance]["tiles_blocked"]

func get_stance_name() -> String:
	var stance_names = ["Standing", "Crouch", "Prone"]
	return stance_names[current_stance]

func is_prone() -> bool:
	return current_stance == STANCE.PRONE

func is_crouch() -> bool:
	return current_stance == STANCE.CROUCH

func is_standing() -> bool:
	return current_stance == STANCE.STANDING

func get_all_occupied_tiles() -> Array:
	if not parent_merc:
		return []
	var merc_pos = parent_merc.get_grid_position()
	return get_occupied_tiles_for_stance(merc_pos, current_stance)
