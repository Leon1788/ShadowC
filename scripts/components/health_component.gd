# health_component.gd
# Verwaltet Health und Damage
# Speicherort: res://scripts/components/health_component.gd

extends Node

class_name HealthComponent

var current_health: int = 100
var max_health: int = 100

signal health_changed(current: int, max: int)
signal died

func _ready():
	pass

func initialize(max_hp: int = 100) -> void:
	max_health = max_hp
	current_health = max_health
	print("[HealthComponent] Initialisiert | Health: %d/%d" % [current_health, max_health])

func take_damage(damage: int) -> void:
	current_health -= damage
	print("[HealthComponent] Damage: %d | Health: %d/%d" % [damage, current_health, max_health])
	
	health_changed.emit(current_health, max_health)
	
	if current_health <= 0:
		die()

func heal(amount: int) -> void:
	current_health = min(current_health + amount, max_health)
	print("[HealthComponent] Geheilt: %d | Health: %d/%d" % [amount, current_health, max_health])
	health_changed.emit(current_health, max_health)

func die() -> void:
	print("[HealthComponent] Merc ist gefallen!")
	died.emit()

func get_current_health() -> int:
	return current_health

func get_max_health() -> int:
	return max_health

func get_health_percentage() -> float:
	if max_health == 0:
		return 0.0
	return float(current_health) / float(max_health)

func is_alive() -> bool:
	return current_health > 0
