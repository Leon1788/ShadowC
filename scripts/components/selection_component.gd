# selection_component.gd
# Verwaltet Selection und Highlight-Visual
# Speicherort: res://scripts/components/selection_component.gd

extends Node

class_name SelectionComponent

var is_selected: bool = false
var merc_mesh: MeshInstance3D = null
var material: StandardMaterial3D = null
var base_color: Color = Color.BLUE
var selected_color: Color = Color.YELLOW

func _ready():
	pass

func initialize(mesh_instance: MeshInstance3D, base_col: Color = Color.BLUE) -> void:
	merc_mesh = mesh_instance
	base_color = base_col
	
	if merc_mesh and merc_mesh.get_surface_override_material(0):
		material = merc_mesh.get_surface_override_material(0)
	else:
		material = StandardMaterial3D.new()
		if merc_mesh:
			merc_mesh.set_surface_override_material(0, material)
	
	update_visual()
	print("[SelectionComponent] Initialisiert | Base Color: %s" % base_color)

func select() -> void:
	is_selected = true
	update_visual()
	print("[SelectionComponent] Selected")

func deselect() -> void:
	is_selected = false
	update_visual()
	print("[SelectionComponent] Deselected")

func toggle_select() -> void:
	is_selected = !is_selected
	update_visual()

func update_visual() -> void:
	if not material:
		return
	
	if is_selected:
		material.albedo_color = selected_color
		material.emission = selected_color * 0.5
		material.emission_enabled = true
	else:
		material.albedo_color = base_color
		material.emission_enabled = false

func get_is_selected() -> bool:
	return is_selected
