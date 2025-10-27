# input_manager.gd
# Verwaltet Map-Input (Merc-Klicks, Bewegung)
# Speicherort: res://scripts/managers/input_manager.gd

extends Node

class_name InputManager

var merc_manager: MercManager = null
var camera: Camera3D = null
var path_renderer: PathRenderer = null
var pathfinder: Pathfinder = null
var round_manager: RoundManager = null
var last_preview_pos: Vector2i = Vector2i(-1, -1)
var last_preview_grid: Vector2i = Vector2i(-1, -1)
var path_cache: Dictionary = {}
var cached_merc = null
var cached_merc_pos: Vector2i = Vector2i(-1, -1)

signal merc_selected(merc: MercEntity)
signal merc_move_requested(target_grid: Vector2i)
signal grid_clicked(grid_pos: Vector2i)

func _ready():
	pass

func initialize(merc_mgr: MercManager, cam: Camera3D, path_rend: PathRenderer = null, pf: Pathfinder = null, round_mgr: RoundManager = null) -> void:
	print("[InputManager] Initialisiere...")
	merc_manager = merc_mgr
	camera = cam
	path_renderer = path_rend
	pathfinder = pf
	round_manager = round_mgr
	print("[InputManager] Bereit")

func _input(event: InputEvent):
	if event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_LEFT:
			handle_left_click(event.position)
		elif event.button_index == MOUSE_BUTTON_RIGHT:
			handle_right_click()
	elif event is InputEventKey and event.pressed:
		if event.keycode == KEY_SPACE:
			print("[InputManager] SPACE erkannt!")
			handle_spacebar()
		elif event.keycode == KEY_1:
			handle_stance_key(0)
		elif event.keycode == KEY_2:
			handle_stance_key(1)
		elif event.keycode == KEY_3:
			handle_stance_key(2)
	
	if event is InputEventMouseMotion:
		if path_renderer and merc_manager.get_selected_merc():
			preview_path(event.position)

func handle_spacebar() -> void:
	print("[InputManager] round_manager = %s" % round_manager)
	if round_manager:
		print("[InputManager] Spacebar: Runde beendet, AP Reset")
		round_manager.reset_all_ap()
	else:
		print("[InputManager] FEHLER: round_manager ist null!")

func handle_right_click() -> void:
	merc_manager.select_merc(null)
	path_renderer.clear_path()

func handle_left_click(screen_pos: Vector2) -> void:
	var grid_pos = screen_to_grid(screen_pos)
	
	if grid_pos == Vector2i(-1, -1):
		return
	
	print("[InputManager] Klick: Grid (%d, %d)" % [grid_pos.x, grid_pos.y])
	grid_clicked.emit(grid_pos)
	
	# Check ob Merc getroffen wurde
	var hit_merc = null
	for merc in merc_manager.get_all_mercs():
		var merc_pos = merc.get_grid_position()
		if merc_pos == grid_pos:
			hit_merc = merc
			break
	
	if hit_merc:
		merc_manager.select_merc(hit_merc)
		merc_selected.emit(hit_merc)
		print("[InputManager] Merc ausgewählt: %s" % hit_merc.merc_name)
	else:
		# Bewegung zum Grid-Tile
		if merc_manager.get_selected_merc():
			var selected_merc = merc_manager.get_selected_merc()
			var start = selected_merc.get_grid_position()
			var max_ap = selected_merc.get_current_ap()
			
			# Route mit AP Limit finden
			var path = pathfinder.find_path(start, grid_pos, max_ap)
			
			if not path.is_empty():
				var success = merc_manager.move_selected_merc(path)
				if success:
					merc_move_requested.emit(grid_pos)
					path_renderer.clear_path()
				print("[InputManager] Bewegungsbefehl zu Grid (%d, %d)" % [grid_pos.x, grid_pos.y])

func screen_to_grid(screen_pos: Vector2) -> Vector2i:
	if not camera:
		return Vector2i(-1, -1)
	
	var from = camera.project_ray_origin(screen_pos)
	var normal = camera.project_ray_normal(screen_pos)
	
	var t = -from.y / normal.y if normal.y != 0 else 0
	var hit_pos = from + normal * t
	
	var grid_x = int(hit_pos.x / 1.0)
	var grid_z = int(hit_pos.z / 1.0)
	
	# Bounds check
	if grid_x < 0 or grid_x >= 40 or grid_z < 0 or grid_z >= 40:
		return Vector2i(-1, -1)
	
	return Vector2i(grid_x, grid_z)

func preview_path(screen_pos: Vector2) -> void:
	var target_grid = screen_to_grid(screen_pos)
	
	# Nur updaten wenn Grid sich ändert
	if target_grid == last_preview_grid:
		return
	
	last_preview_grid = target_grid
	
	if target_grid == Vector2i(-1, -1):
		path_renderer.clear_path()
		return
	
	var selected_merc = merc_manager.get_selected_merc()
	if not selected_merc:
		return
	
	# Cache invalidieren wenn Merc wechselt oder bewegt
	if selected_merc != cached_merc or selected_merc.get_grid_position() != cached_merc_pos:
		path_cache.clear()
		cached_merc = selected_merc
		cached_merc_pos = selected_merc.get_grid_position()
	
	var start = selected_merc.get_grid_position()
	var max_ap = selected_merc.get_current_ap()
	var cache_key = str(start) + "_" + str(target_grid)
	
	var full_path
	
	# Aus Cache oder berechnen - VOLLE Route ohne AP-Limit
	if cache_key in path_cache:
		full_path = path_cache[cache_key]
	else:
		full_path = pathfinder.find_path(start, target_grid, 1000)
		path_cache[cache_key] = full_path
	
	if full_path.is_empty():
		path_renderer.clear_path()
		return
	
	# Teile in grün (läufbar) + rot (nicht läufbar)
	var walkable = []
	var blocked = []
	var ap_used = 0
	
	for i in range(full_path.size()):
		var tile = full_path[i]
		
		if i > 0:
			ap_used += 2
		
		if ap_used <= max_ap:
			walkable.append(tile)
		else:
			blocked.append(tile)
	
	path_renderer.draw_path(walkable, blocked)

func handle_stance_key(stance: int) -> void:
	var selected_merc = merc_manager.get_selected_merc()
	if selected_merc:
		selected_merc.change_stance(stance)
	else:
		print("[InputManager] Kein Merc selektiert!")
