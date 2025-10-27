# stance_component.gd
# Verwaltet Stance-System (Standing, Crouch, Prone)
# Prone belegt 1 Tile dahinter relativ zur Facing-Richtung
# Speicherort: res://scripts/components/stance_component.gd

extends Node

class_name StanceComponent

enum STANCE { STANDING, CROUCH, PRONE }

var current_stance: int = STANCE.STANDING
var grid_manager: GridManager = null
var parent_merc: MercEntity = null
var facing_component: FacingComponent = null

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
	
	# Facing-Komponente vom Merc holen
	if merc and merc.facing_component:
		facing_component = merc.facing_component
	
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
	
	# Prone = 2 Tiles benötigt (Merc + 1 Tile dahinter)
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
		# Prone belegt 1 Tile DAHINTER relativ zur Facing-Richtung
		if facing_component:
			var facing_dir = facing_component.get_facing_direction()
			var rear_tile = calculate_rear_tile(merc_pos, facing_dir)
			tiles.append(rear_tile)
		else:
			# Fallback: wenn kein Facing, nutze Y+1 (Süd)
			tiles.append(Vector2i(merc_pos.x, merc_pos.y + 1))
	
	return tiles

func calculate_rear_tile(merc_pos: Vector2i, facing_direction: int) -> Vector2i:
	# Facing Directions (0-7):
	# 0=North(+Z), 1=NE, 2=East(+X), 3=SE, 4=South(-Z), 5=SW, 6=West(-X), 7=NW
	
	# In Grid-Koordinaten:
	# X = Ost/West, Y = Nord/Süd
	# +X = Ost (Right)
	# -X = West (Left)
	# +Y = Süd (Down/Hinten in Godot)
	# -Y = Nord (Up/Vorne in Godot)
	
	var dx = 0
	var dy = 0
	
	match facing_direction:
		0:  # North → rear ist +Y (Süd, hinter)
			dx = 0
			dy = 1
		1:  # NE → rear ist SE
			dx = 1
			dy = 1
		2:  # East → rear ist Ost
			dx = 1
			dy = 0
		3:  # SE → rear ist SW
			dx = 1
			dy = -1
		4:  # South → rear ist -Y (Nord, hinter)
			dx = 0
			dy = -1
		5:  # SW → rear ist NW
			dx = -1
			dy = -1
		6:  # West → rear ist West
			dx = -1
			dy = 0
		7:  # NW → rear ist NE
			dx = -1
			dy = 1
	
	return merc_pos + Vector2i(dx, dy)

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
