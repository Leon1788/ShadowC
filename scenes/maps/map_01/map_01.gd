# map_01.gd
# Verwaltet Szene, initialisiert Manager
# Speicherort: res://scenes/maps/map_01/map_01.gd

extends Node3D

class_name Map01

var grid_manager: GridManager = null
var merc_manager: MercManager = null
var camera_manager: CameraManager = null
var input_manager: InputManager = null
var round_manager: RoundManager = null
var path_renderer: PathRenderer = null
var grid_visual: GridVisual = null
var grid_highlighter: GridHighlighter = null

func _ready():
	print("\n=== MAP 01 INIT START ===\n")
	
	setup_managers()
	setup_connections()
	
	print("\n=== MAP 01 INIT COMPLETE ===\n")

func _process(delta: float):
	if input_manager:
		input_manager.update(delta)
	
	if round_manager:
		round_manager.update(delta)

func setup_managers() -> void:
	print("[Map01] Initialisiere Manager...")
	
	# GridManager
	grid_manager = GridManager.new()
	grid_manager.name = "GridManager"
	add_child(grid_manager)
	grid_manager.initialize(self)
	grid_manager.print_grid_info()
	
	# MercManager
	merc_manager = MercManager.new()
	merc_manager.name = "MercManager"
	add_child(merc_manager)
	merc_manager.initialize()
	
	# GridManager an MercManager übergeben
	merc_manager.set_grid_manager(grid_manager)
	grid_manager.set_merc_manager(merc_manager)
	
	# Suche alle Mercs in der Szene und füge sie hinzu
	var merc_nodes = find_all_mercs()
	for merc in merc_nodes:
		merc_manager.add_merc(merc)
		merc.set_grid_manager(grid_manager)
	
	print("[Map01] Mercs gefunden: %d" % merc_nodes.size())
	
	# CameraManager
	camera_manager = CameraManager.new()
	camera_manager.name = "CameraManager"
	add_child(camera_manager)
	var camera = get_node_or_null("Camera3D")
	if camera:
		camera_manager.initialize(camera, self)
	else:
		print("[Map01] FEHLER: Camera3D nicht in Szene!")
	
	# PathRenderer
	path_renderer = PathRenderer.new()
	path_renderer.name = "PathRenderer"
	add_child(path_renderer)
	path_renderer.initialize(self, grid_manager)
	
	# GridVisual
	grid_visual = GridVisual.new()
	grid_visual.name = "GridVisual"
	add_child(grid_visual)
	grid_visual.initialize(self, grid_manager)
	
	# InputManager (braucht alle anderen)
	input_manager = InputManager.new()
	input_manager.name = "InputManager"
	add_child(input_manager)
	input_manager.initialize(merc_manager, camera_manager, path_renderer, grid_manager, self)
	
	# GridHighlighter
	var grid_highlighter = GridHighlighter.new()
	grid_highlighter.name = "GridHighlighter"
	add_child(grid_highlighter)
	grid_highlighter.initialize(camera_manager.camera, merc_manager.pathfinder, merc_manager)
	
	# RoundManager
	round_manager = RoundManager.new()
	round_manager.name = "RoundManager"
	add_child(round_manager)
	round_manager.initialize(merc_manager)

func find_all_mercs() -> Array:
	var mercs = []
	var all_children = get_all_children(self)
	
	for child in all_children:
		if child is MercEntity:
			mercs.append(child)
	
	return mercs

func get_all_children(node: Node) -> Array:
	var children = []
	for child in node.get_children():
		children.append(child)
		children += get_all_children(child)
	return children

func setup_connections() -> void:
	print("[Map01] Verbinde Signals...")
	
	if merc_manager and round_manager:
		round_manager.round_started.connect(merc_manager._on_round_started)
		round_manager.round_ended.connect(merc_manager._on_round_ended)
	
	if round_manager:
		round_manager.new_turn.connect(func(): print("[Map01] === NEUER ZUGE ==="))

func get_grid_manager() -> GridManager:
	return grid_manager

func get_merc_manager() -> MercManager:
	return merc_manager

func get_camera_manager() -> CameraManager:
	return camera_manager

func get_input_manager() -> InputManager:
	return input_manager

func get_path_renderer() -> PathRenderer:
	return path_renderer

func get_round_manager() -> RoundManager:
	return round_manager

func get_grid_highlighter() -> GridHighlighter:
	return grid_highlighter

func print_map_status() -> void:
	print("\n=== MAP 01 STATUS ===")
	print("Grid: %s" % ("OK" if grid_manager else "MISSING"))
	print("Mercs: %s" % ("OK (%d)" % merc_manager.get_all_mercs().size() if merc_manager else "MISSING"))
	print("Camera: %s" % ("OK" if camera_manager else "MISSING"))
	print("Input: %s" % ("OK" if input_manager else "MISSING"))
	print("Rounds: %s" % ("OK" if round_manager else "MISSING"))
	print("Path Renderer: %s" % ("OK" if path_renderer else "MISSING"))
	print("==================\n")
