# ap_component.gd
# Verwaltet AP (Action Points) für jeden Merc
# Speicherort: res://scripts/components/ap_component.gd

extends Node

class_name APComponent

var current_ap: int = 0
var max_ap: int = 50

func _ready():
	pass

func initialize(max_ap_value: int = 50) -> void:
	max_ap = max_ap_value
	current_ap = max_ap
	print("[APComponent] Initialisiert | Max AP: %d" % max_ap)

func spend_ap(amount: int) -> bool:
	if current_ap >= amount:
		current_ap -= amount
		print("[APComponent] AP ausgegeben: %d | Remaining: %d/%d" % [amount, current_ap, max_ap])
		return true
	else:
		print("[APComponent] FEHLER: Nicht genug AP! Benötigt: %d, Verfügbar: %d" % [amount, current_ap])
		return false

func has_ap(amount: int) -> bool:
	return current_ap >= amount

func get_remaining_ap() -> int:
	return current_ap

func get_max_ap() -> int:
	return max_ap

func reset_ap() -> void:
	current_ap = max_ap
	print("[APComponent] AP Reset | AP: %d/%d" % [current_ap, max_ap])

func get_ap_percentage() -> float:
	if max_ap == 0:
		return 0.0
	return float(current_ap) / float(max_ap)
