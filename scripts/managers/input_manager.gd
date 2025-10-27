# input_manager.gd
# Verwaltet Map-Input (Merc-Klicks, Bewegung, Stance, Facing)
# Speicherort: res://scripts/managers/input_manager.gd

extends Node

class_name InputManager

var merc_manager: MercManager = null
var camera_manager: CameraManager = null
var path_renderer: PathRenderer = null
var grid_manager: GridManager = null
var map_root: Node3D = null

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

func initialize(merc_mgr: MercManager, camera_mgr: CameraManager, path_rend: PathRenderer = null, grid_mgr: GridManager = null, map: Node3D = null) -> void:
	print("[InputManager] Initialisiere...")
	merc_manager = merc_mgr
	camera_manager = camera_mgr
	path_renderer = path_rend
	grid_manager = grid_mgr
	map_root = map
	print("[InputManager] Bereit")

func update(delta: float) -> void:
	pass

func _input(event: InputEvent):
	if event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_LEFT:
			handle_left_click(event.position)
			get_tree().root.set_input_as_handled()
		elif event.button_index == MOUSE_BUTTON_RIGHT:
			handle_right_click()
			get_tree().root.set_input_as_handled()
	elif event is InputEventKey and event.pressed:
		if event.keycode == KEY_SPACE:
			handle_spacebar()
			get_tree().root.set_input_as_handled()
		elif event.keycode == KEY_1:
			handle_stance_key(0)
			get_tree().root.set_input_as_handled()
		elif event.keycode == KEY_2:
			handle_stance_key(1)
			get_tree().root.set_input_as_handled()
		elif event.keycode == KEY_3:
			handle_stance_key(2)
			get_tree().root.set_input_as_handled()
		elif event.keycode == KEY_Q:
			handle_rotate_left()
			get_tree().root.set_input_as_handled()
		elif event.keycode == KEY_E:
			handle_rotate_right()
			get_tree().root.set_input_as_handled()
	
	if event is InputEventMouseMotion:
		if path_renderer and merc_manager.get_selected_merc():
			preview_path(event.position)

func handle_spacebar() -> void:
	print("[InputManager] SPACE: Reset AP für alle Mercs")
	if map_root:
		var round_manager = map_root.get_round_manager()
		if round_manager:
			round_manager.reset_all_ap()
			print("[InputManager] AP Reset erfolgreich")

func handle_right_click() -> void:
	print("[InputManager] Rechts-Klick: Deselect Merc")
	merc_manager.select_merc(null)
	if path_renderer:
		path_renderer.clear_path()

func handle_left_click(screen_pos: Vector2) -> void:
	var grid_pos = screen_to_grid(screen_pos)
	
	if grid_pos == Vector2i(-1, -1):
		return
	
	print("[InputManager] Linke-Klick: Grid (%d, %d)" % [grid_pos.x, grid_pos.y])
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
		var merc_pos = hit_merc.get_grid_position()
		print("[InputManager] Merc selektiert: %s" % hit_merc.merc_name)
		print("[InputManager] Position: Grid (%d, %d) | AP: %d/%d | Stance: %s | Facing: %s" % [
			merc_pos.x, merc_pos.y, 
			hit_merc.get_current_ap(), 
			hit_merc.get_max_ap(),
			hit_merc.stance_component.get_stance_name(),
			hit_merc.get_facing_name()
		])
	else:
		# Bewegung zum Grid-Tile
		if merc_manager.get_selected_merc():
			var selected_merc = merc_manager.get_selected_merc()
			var start = selected_merc.get_grid_position()
			var max_ap = selected_merc.get_current_ap()
			
			# Pathfinding
			var pathfinder = merc_manager.pathfinder
			if not pathfinder:
				print("[InputManager] FEHLER: Pathfinder null!")
				return
			
			# Route mit AP Limit finden
			var path = pathfinder.find_path(start, grid_pos, max_ap)
			
			if not path.is_empty():
				var success = merc_manager.move_selected_merc(path)
				if success:
					merc_move_requested.emit(grid_pos)
					if path_renderer:
						path_renderer.clear_path()
					print("[InputManager] Bewegung zu Grid (%d, %d) erfolgreich" % [grid_pos.x, grid_pos.y])
				else:
					print("[InputManager] Bewegung fehlgeschlagen!")
			else:
				print("[InputManager] Kein Weg zu Grid (%d, %d)" % [grid_pos.x, grid_pos.y])

func handle_stance_key(stance: int) -> void:
	var selected_merc = merc_manager.get_selected_merc()
	
	if not selected_merc:
		print("[InputManager] Kein Merc selektiert!")
		return
	
	var stance_names = ["Standing", "Crouch", "Prone"]
	print("[InputManager] Taste %d gedrückt: Wechsel zu %s" % [stance + 1, stance_names[stance]])
	
	if selected_merc.change_stance(stance):
		print("[InputManager] Stance-Wechsel erfolgreich!")
		print("[InputManager] Neue Höhe: %.1f | AP: %d/%d" % [
			selected_merc.get_stance_height(),
			selected_merc.get_current_ap(),
			selected_merc.get_max_ap()
		])
	else:
		print("[InputManager] Stance-Wechsel fehlgeschlagen!")

func handle_rotate_left() -> void:
	var selected_merc = merc_manager.get_selected_merc()
	
	if not selected_merc:
		print("[InputManager] Kein Merc selektiert!")
		return
	
	print("[InputManager] Q: Drehen links")
	
	if selected_merc.rotate_left():
		print("[InputManager] Rotation erfolgreich!")
		print("[InputManager] Facing: %s | AP: %d/%d" % [
			selected_merc.get_facing_name(),
			selected_merc.get_current_ap(),
			selected_merc.get_max_ap()
		])
	else:
		print("[InputManager] Rotation fehlgeschlagen!")

func handle_rotate_right() -> void:
	var selected_merc = merc_manager.get_selected_merc()
	
	if not selected_merc:
		print("[InputManager] Kein Merc selektiert!")
		return
	
	print("[InputManager] E: Drehen rechts")
	
	if selected_merc.rotate_right():
		print("[InputManager] Rotation erfolgreich!")
		print("[InputManager] Facing: %s | AP: %d/%d" % [
			selected_merc.get_facing_name(),
			selected_merc.get_current_ap(),
			selected_merc.get_max_ap()
		])
	else:
		print("[InputManager] Rotation fehlgeschlagen!")

func screen_to_grid(screen_pos: Vector2) -> Vector2i:
	if not camera_manager:
		return Vector2i(-1, -1)
	
	var camera = camera_manager.camera
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
	
	var pathfinder = merc_manager.pathfinder
	if not pathfinder:
		return
	
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
