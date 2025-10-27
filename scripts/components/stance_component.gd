# stance_component.gd
# Verwaltet Stance-System (Standing, Crouch, Prone)
# Speicherort: res://scripts/components/stance_component.gd

extends Node

class_name StanceComponent

enum STANCE { STANDING, CROUCH, PRONE }

var current_stance: int = STANCE.STANDING
var stance_height = {
	STANCE.STANDING: 1.6,
	STANCE.CROUCH: 1.0,
	STANCE.PRONE: 0.3
}
var ap_component: APComponent = null

signal stance_changed(stance: int)

func _ready():
	pass

func initialize(ap_comp: APComponent = null) -> void:
	ap_component = ap_comp
	current_stance = STANCE.STANDING
	print("[StanceComponent] Initialisiert | Stance: Standing")

func change_stance(new_stance: int) -> bool:
	# Gleiche Stance = kein Wechsel
	if new_stance == current_stance:
		return false
	
	# AP Check - Stance-Wechsel kostet 1 AP
	if ap_component and not ap_component.has_ap(1):
		print("[StanceComponent] Nicht genug AP für Stance-Wechsel!")
		return false
	
	# AP ausgeben
	if ap_component:
		ap_component.spend_ap(1)
	
	# Stance wechseln
	current_stance = new_stance
	stance_changed.emit(current_stance)
	
	var stance_names = ["Standing", "Crouch", "Prone"]
	print("[StanceComponent] Stance wechsel: %s" % stance_names[new_stance])
	
	return true

func get_current_stance() -> int:
	return current_stance

func get_stance_height() -> float:
	return stance_height[current_stance]

func get_stance_name() -> String:
	var stance_names = ["Standing", "Crouch", "Prone"]
	return stance_names[current_stance]

func is_prone() -> bool:
	return current_stance == STANCE.PRONE

func is_crouch() -> bool:
	return current_stance == STANCE.CROUCH

func is_standing() -> bool:
	return current_stance == STANCE.STANDING
