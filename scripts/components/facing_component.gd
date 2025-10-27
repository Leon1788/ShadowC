# facing_component.gd
# Verwaltet Blickrichtung - 8 Richtungen (N, NE, E, SE, S, SW, W, NW)
# Speicherort: res://scripts/components/facing_component.gd

extends Node

class_name FacingComponent

enum DIRECTION { NORTH = 0, NE = 1, EAST = 2, SE = 3, SOUTH = 4, SW = 5, WEST = 6, NW = 7 }

var current_facing: int = DIRECTION.NORTH
var ap_component: APComponent = null
var parent_node: Node3D = null

# Winkel für jede Richtung (0-7 = 0°, 45°, 90°, etc)
var facing_angles = [0, 45, 90, 135, 180, 225, 270, 315]
var facing_names = ["North", "NE", "East", "SE", "South", "SW", "West", "NW"]

signal facing_changed(direction: int)

func _ready():
	pass

func initialize(ap_comp: APComponent = null, parent: Node3D = null) -> void:
	ap_component = ap_comp
	parent_node = parent
	current_facing = DIRECTION.NORTH
	print("[FacingComponent] Initialisiert | Facing: %s" % facing_names[current_facing])

func rotate_left() -> bool:
	return rotate_facing(-1)

func rotate_right() -> bool:
	return rotate_facing(1)

func rotate_facing(direction: int) -> bool:
	# AP Check - Drehen kostet 1 AP
	if ap_component and not ap_component.has_ap(1):
		print("[FacingComponent] FEHLER: Nicht genug AP!")
		return false
	
	# Neue Richtung berechnen (0-7, wraparound)
	var new_facing = (current_facing + direction) % 8
	if new_facing < 0:
		new_facing += 8
	
	# AP ausgeben
	if ap_component:
		ap_component.spend_ap(1)
	
	# Facing ändern
	current_facing = new_facing
	facing_changed.emit(current_facing)
	
	var angle = facing_angles[current_facing]
	print("[FacingComponent] Gedreht: %s (Index: %d, Winkel: %d°) | AP Kosten: 1" % [
		facing_names[current_facing], 
		current_facing,
		angle
	])
	
	return true

func get_facing_direction() -> int:
	return current_facing

func get_facing_angle() -> int:
	return facing_angles[current_facing]

func get_facing_name() -> String:
	return facing_names[current_facing]

func get_facing_vector() -> Vector3:
	# Gibt Richtungsvektor zurück für Facing
	var angle_rad = deg_to_rad(facing_angles[current_facing])
	return Vector3(sin(angle_rad), 0, cos(angle_rad)).normalized()

func set_facing(direction: int) -> void:
	if direction < 0 or direction >= 8:
		return
	current_facing = direction
	facing_changed.emit(current_facing)
	print("[FacingComponent] Facing gesetzt: %s" % facing_names[current_facing])
