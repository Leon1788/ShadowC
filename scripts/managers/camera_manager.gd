# camera_manager.gd
# Verwaltet Kamera-Steuerung
# Speicherort: res://scripts/managers/camera_manager.gd

extends Node

class_name CameraManager

var camera: Camera3D = null
var grid_manager: GridManager = null

var camera_speed: float = 10.0
var height_speed: float = 5.0
var min_height: float = 5.0
var max_height: float = 50.0

var target_position: Vector3 = Vector3.ZERO
var current_position: Vector3 = Vector3.ZERO

func _ready():
	pass

func initialize(camera_ref: Camera3D, grid_mgr: GridManager) -> void:
	print("[CameraManager] Initialisiere...")
	camera = camera_ref
	grid_manager = grid_mgr
	current_position = camera.global_position
	target_position = current_position
	print("[CameraManager] Bereit")

func _process(delta: float) -> void:
	if not camera:
		return
	
	handle_input(delta)
	update_camera(delta)

func handle_input(delta: float) -> void:
	var input_vector = Vector3.ZERO
	
	# Pfeiltasten - Horizontale Bewegung
	if Input.is_action_pressed("ui_right"):
		input_vector.x += 1
	if Input.is_action_pressed("ui_left"):
		input_vector.x -= 1
	if Input.is_action_pressed("ui_down"):
		input_vector.z += 1
	if Input.is_action_pressed("ui_up"):
		input_vector.z -= 1
	
	# Page Up/Down - Höhe
	if Input.is_action_pressed("ui_page_up"):
		input_vector.y += 1
	if Input.is_action_pressed("ui_page_down"):
		input_vector.y -= 1
	
	# Normalisieren und Bewegung anwenden
	if input_vector != Vector3.ZERO:
		input_vector = input_vector.normalized()
		target_position += input_vector * camera_speed * delta
	
	# Höhen-Limits
	target_position.y = clamp(target_position.y, min_height, max_height)

func update_camera(delta: float) -> void:
	current_position = current_position.lerp(target_position, 5.0 * delta)
	camera.global_position = current_position

func reset_camera() -> void:
	if not grid_manager:
		target_position = Vector3(20.0, 20.0, 20.0)
		return
	
	var grid_size_float = Vector2(grid_manager.grid_size)
	var grid_center = grid_size_float * 0.5
	target_position = Vector3(grid_center.x, 20.0, grid_center.y)
	current_position = target_position
	if camera:
		camera.global_position = current_position

func get_camera_position() -> Vector3:
	return camera.global_position

func set_camera_target_position(pos: Vector3) -> void:
	target_position = pos
	target_position.y = clamp(target_position.y, min_height, max_height)
