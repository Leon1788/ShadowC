# map_01.gd
# Map Orchestrator
# Speicherort: res://scenes/maps/map_01/map_01.gd

extends Node3D

var camera_manager: CameraManager = null
var grid_visual: GridVisual = null
var merc_manager: MercManager = null
var input_manager: InputManager = null
var grid_highlighter: GridHighlighter = null
var path_renderer: PathRenderer = null
var round_manager: RoundManager = null

func _ready():
	print("\n==================================================")
	print("MAP_01 STARTET")
	print("==================================================\n")
	
	setup_camera()
	setup_grid_visual()
	setup_merc_manager()
	setup_path_renderer()
	setup_round_manager()
	setup_input_manager()
	setup_grid_highlighter()
	
	print("Map bereit!\n")

func setup_camera() -> void:
	print("[Map01] Initialisiere Kamera...")
	
	var camera = get_node_or_null("Camera3D")
	
	if not camera:
		print("[Map01] FEHLER: Camera3D nicht gefunden!")
		return
	
	camera_manager = CameraManager.new()
	camera_manager.name = "CameraManager"
	add_child(camera_manager)
	camera_manager.initialize(camera, null)
	camera_manager.target_position = Vector3(20.0, 20.0, 20.0)
	camera_manager.current_position = Vector3(20.0, 20.0, 20.0)
	camera.global_position = camera_manager.target_position
	
	print("[Map01] Kamera bereit")

func setup_grid_visual() -> void:
	print("[Map01] Suche GridVisual...")
	
	grid_visual = get_node_or_null("GridVisual")
	
	if not grid_visual:
		print("[Map01] FEHLER: GridVisual nicht gefunden!")
		return
	
	print("[Map01] GridVisual gefunden und aktiv")

func setup_merc_manager() -> void:
	print("[Map01] Initialisiere MercManager...")
	
	merc_manager = MercManager.new()
	print("[Map01] MercManager.new() erfolgreich")
	
	merc_manager.name = "MercManager"
	add_child(merc_manager)
	print("[Map01] MercManager als Child hinzugefügt")
	
	# GridManager erstellen für Pathfinding
	var grid_manager = GridManager.new()
	grid_manager.initialize(self)
	
	merc_manager.initialize("res://scenes/entities/merc/merc.tscn", grid_manager)
	print("[Map01] MercManager.initialize() aufgerufen")
	
	# Spawn Test-Mercs
	merc_manager.spawn_merc(15, 15, "Merc_Alpha")
	merc_manager.spawn_merc2(20, 20, "Merc_Bravo")
	
	merc_manager.print_mercs()
	print("[Map01] MercManager bereit")

func setup_path_renderer() -> void:
	print("[Map01] Initialisiere PathRenderer...")
	
	path_renderer = PathRenderer.new()
	path_renderer.name = "PathRenderer"
	add_child(path_renderer)
	path_renderer.initialize()
	
	print("[Map01] PathRenderer bereit")

func setup_input_manager() -> void:
	print("[Map01] Initialisiere InputManager...")
	
	input_manager = InputManager.new()
	input_manager.name = "InputManager"
	add_child(input_manager)
	
	var camera = get_node("Camera3D")
	var pathfinder = merc_manager.pathfinder
	input_manager.initialize(merc_manager, camera, path_renderer, pathfinder, round_manager)
	
	print("[Map01] InputManager bereit")

func setup_grid_highlighter() -> void:
	print("[Map01] Initialisiere GridHighlighter...")
	
	grid_highlighter = GridHighlighter.new()
	grid_highlighter.name = "GridHighlighter"
	add_child(grid_highlighter)
	
	var camera = get_node("Camera3D")
	var pathfinder = merc_manager.pathfinder
	grid_highlighter.initialize(camera, pathfinder, merc_manager)
	
	print("[Map01] GridHighlighter bereit")

func setup_round_manager() -> void:
	print("[Map01] Initialisiere RoundManager...")
	
	round_manager = RoundManager.new()
	round_manager.name = "RoundManager"
	add_child(round_manager)
	round_manager.initialize(merc_manager)
	round_manager.start_game()
	
	print("[Map01] RoundManager bereit")

func _process(delta: float):
	if camera_manager:
		camera_manager._process(delta)
