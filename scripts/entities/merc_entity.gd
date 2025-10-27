# merc_entity.gd
# Base-Klasse für alle Mercs - orchestriert Komponenten
# Speicherort: res://scripts/entities/merc_entity.gd

@tool
extends Node3D

class_name MercEntity

# Inspector Properties
@export var merc_name: String = "Merc_01"
@export var grid_x: int = 0:
	set(value):
		grid_x = clamp(value, 0, 39)
		if movement_component:
			movement_component.set_grid_position(grid_x, grid_z)

@export var grid_z: int = 0:
	set(value):
		grid_z = clamp(value, 0, 39)
		if movement_component:
			movement_component.set_grid_position(grid_x, grid_z)

@export var health: int = 100
@export var max_health: int = 100
@export var max_ap: int = 50

# Komponenten
var movement_component: MovementComponent = null
var ap_component: APComponent = null
var health_component: HealthComponent = null
var selection_component: SelectionComponent = null
var stance_component: StanceComponent = null

# References
var capsule_mesh: MeshInstance3D = null
var character_body: CharacterBody3D = null

const CAPSULE_HEIGHT = 1.8
const CAPSULE_RADIUS = 0.3

func _ready():
	if Engine.is_editor_hint():
		return
	
	setup_merc()

func _process(delta: float):
	if Engine.is_editor_hint():
		return
	
	if movement_component and movement_component.get_is_moving():
		movement_component.update_movement(delta)

func setup_merc() -> void:
	print("[MercEntity %s] Setup startet" % merc_name)
	
	# Suche bestehende Nodes
	character_body = get_node_or_null("MercBody")
	if character_body:
		capsule_mesh = character_body.get_node_or_null("MercMesh")
	
	# Erstelle Komponenten
	create_components()
	
	# Initialisiere Komponenten
	initialize_components()
	
	print("[MercEntity %s] Setup fertig" % merc_name)

func create_components() -> void:
	# APComponent
	ap_component = APComponent.new()
	ap_component.name = "APComponent"
	add_child(ap_component)
	
	# HealthComponent
	health_component = HealthComponent.new()
	health_component.name = "HealthComponent"
	add_child(health_component)
	
	# SelectionComponent
	selection_component = SelectionComponent.new()
	selection_component.name = "SelectionComponent"
	add_child(selection_component)
	
	# StanceComponent
	stance_component = StanceComponent.new()
	stance_component.name = "StanceComponent"
	add_child(stance_component)
	
	# MovementComponent (braucht andere Komponenten)
	movement_component = MovementComponent.new()
	movement_component.name = "MovementComponent"
	add_child(movement_component)

func initialize_components() -> void:
	# AP
	ap_component.initialize(max_ap)
	
	# Health
	health_component.initialize(max_health)
	health_component.health_changed.connect(_on_health_changed)
	health_component.died.connect(_on_died)
	
	# Selection
	if capsule_mesh:
		selection_component.initialize(capsule_mesh, Color.BLUE)
	
	# Stance (braucht AP)
	stance_component.initialize(ap_component)
	
	# Movement (braucht AP)
	movement_component.initialize(grid_x, grid_z, self, ap_component)
	movement_component.movement_started.connect(_on_movement_started)
	movement_component.movement_completed.connect(_on_movement_completed)

# ============ PUBLIC API ============

func select() -> void:
	if selection_component:
		selection_component.select()

func deselect() -> void:
	if selection_component:
		selection_component.deselect()

func get_is_selected() -> bool:
	if selection_component:
		return selection_component.get_is_selected()
	return false

# Movement
func move_to(path: Array) -> bool:
	if movement_component:
		return movement_component.move_to(path)
	return false

func get_grid_position() -> Vector2i:
	if movement_component:
		return movement_component.get_grid_position()
	return Vector2i(grid_x, grid_z)

func set_grid_position(new_x: int, new_z: int) -> void:
	if movement_component:
		movement_component.set_grid_position(new_x, new_z)
	grid_x = new_x
	grid_z = new_z

# AP
func get_current_ap() -> int:
	if ap_component:
		return ap_component.get_remaining_ap()
	return 0

func get_max_ap() -> int:
	if ap_component:
		return ap_component.get_max_ap()
	return max_ap

func reset_ap() -> void:
	if ap_component:
		ap_component.reset_ap()

# Health
func take_damage(damage: int) -> void:
	if health_component:
		health_component.take_damage(damage)

func heal(amount: int) -> void:
	if health_component:
		health_component.heal(amount)

func get_current_health() -> int:
	if health_component:
		return health_component.get_current_health()
	return health

func get_max_health() -> int:
	if health_component:
		return health_component.get_max_health()
	return max_health

func is_alive() -> bool:
	if health_component:
		return health_component.is_alive()
	return true

# Stance
func change_stance(new_stance: int) -> bool:
	if stance_component:
		return stance_component.change_stance(new_stance)
	return false

func get_current_stance() -> int:
	if stance_component:
		return stance_component.get_current_stance()
	return 0

func get_merc_name() -> String:
	return merc_name

# ============ SIGNALS ============

func _on_health_changed(current: int, max: int) -> void:
	print("[%s] Health changed: %d/%d" % [merc_name, current, max])

func _on_died() -> void:
	print("[%s] Merc ist gefallen!" % merc_name)
	queue_free()

func _on_movement_started(target: Vector2i) -> void:
	print("[%s] Bewegung zu Grid (%d, %d)" % [merc_name, target.x, target.y])

func _on_movement_completed(final_pos: Vector2i) -> void:
	print("[%s] Angekommen bei Grid (%d, %d)" % [merc_name, final_pos.x, final_pos.y])
