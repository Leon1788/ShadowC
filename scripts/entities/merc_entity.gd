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
var collision_shape_node: CollisionShape3D = null
var capsule_shape: CapsuleShape3D = null
var character_body: CharacterBody3D = null
var grid_manager: GridManager = null

# Capsule Base Daten (aus merc.tscn)
var capsule_radius: float = 0.3
var capsule_base_height: float = 1.8

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
	# Suche bestehende Nodes
	character_body = get_node_or_null("MercBody")
	if character_body:
		capsule_mesh = character_body.get_node_or_null("MercMesh")
		var collider_node = character_body.get_node_or_null("MercCollider")
		if collider_node and collider_node is CollisionShape3D:
			collision_shape_node = collider_node
			capsule_shape = collider_node.shape as CapsuleShape3D
	
	# Lese Capsule Daten aus merc.tscn
	if capsule_shape:
		capsule_radius = capsule_shape.radius
		capsule_base_height = capsule_shape.height
	
	# Erstelle Komponenten
	create_components()
	
	# Initialisiere Komponenten
	initialize_components()

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
	stance_component.initialize(ap_component, grid_manager, self)
	stance_component.stance_changed.connect(_on_stance_changed)
	
	# Movement (braucht AP + Stance + GridManager)
	movement_component.initialize(grid_x, grid_z, self, ap_component, stance_component, grid_manager)
	movement_component.movement_started.connect(_on_movement_started)
	movement_component.movement_completed.connect(_on_movement_completed)
	
	# MercEntity Position auf Grid-Position setzen
	var grid_world_pos = movement_component.grid_to_world(Vector2i(grid_x, grid_z))
	position = grid_world_pos
	
	# Initiale Capsule-Höhe setzen
	update_capsule_for_stance()

func set_grid_manager(grid_mgr: GridManager) -> void:
	grid_manager = grid_mgr
	
	# Auch StanceComponent aktualisieren!
	if stance_component:
		stance_component.set_grid_manager(grid_mgr)

func update_capsule_for_stance() -> void:
	if not stance_component or not character_body:
		return
	
	var stance_height = stance_component.get_stance_height()
	
	# Update Mesh Height UND Radius (auf merc.tscn Base-Wert)
	if capsule_mesh and capsule_mesh.mesh is CapsuleMesh:
		var capsule_mesh_obj = capsule_mesh.mesh as CapsuleMesh
		capsule_mesh_obj.height = stance_height
		capsule_mesh_obj.radius = capsule_radius  # Immer Base-Radius aus merc.tscn!
		
		# Mesh Position.Y = Height/2 damit Bottom bei Y=0 bleibt!
		var mesh_y = stance_height / 2.0
		capsule_mesh.position.y = mesh_y
	
	# Update CollisionShape Height UND Radius (auf merc.tscn Base-Wert)
	if capsule_shape and collision_shape_node:
		capsule_shape.height = stance_height
		capsule_shape.radius = capsule_radius  # Immer Base-Radius aus merc.tscn!
		
		# CollisionShape3D Node Position.Y = Height/2 damit Bottom bei Y=0 bleibt!
		var shape_y = stance_height / 2.0
		collision_shape_node.position.y = shape_y

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

func get_stance_height() -> float:
	if stance_component:
		return stance_component.get_stance_height()
	return capsule_base_height

func get_merc_name() -> String:
	return merc_name

# ============ SIGNAL HANDLERS ============

func _on_health_changed(current: int, max: int) -> void:
	pass

func _on_died() -> void:
	queue_free()

func _on_stance_changed(stance: int) -> void:
	update_capsule_for_stance()

func _on_movement_started(target: Vector2i) -> void:
	pass

func _on_movement_completed(final_pos: Vector2i) -> void:
	pass
