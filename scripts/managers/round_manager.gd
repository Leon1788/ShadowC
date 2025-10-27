# round_manager.gd
# Verwaltet Runden - alle Mercs parallel, Spacebar = AP Reset
# Speicherort: res://scripts/managers/round_manager.gd

extends Node

class_name RoundManager

var merc_manager: MercManager = null
var current_round: int = 0

signal round_started(round: int)
signal round_ended(round: int)

func _ready():
	pass

func initialize(merc_mgr: MercManager) -> void:
	print("[RoundManager] Initialisiere...")
	merc_manager = merc_mgr
	print("[RoundManager] Bereit")

func start_game() -> void:
	print("[RoundManager] Spiel startet!")
	current_round = 0
	reset_all_ap()

func reset_all_ap() -> void:
	current_round += 1
	
	# AP Reset für alle Mercs
	for merc in merc_manager.get_all_mercs():
		merc.reset_ap()
	
	print("[RoundManager] === RUNDE %d | AP RESET ===" % current_round)
	round_started.emit(current_round)

func get_round_number() -> int:
	return current_round
