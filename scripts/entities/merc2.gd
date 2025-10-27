# merc2.gd
# Söldner 2 - ROT
# Speicherort: res://scripts/entities/merc2.gd

@tool
extends MercEntity

class_name Merc2

func _ready():
	if Engine.is_editor_hint():
		return
	
	super._ready()
	
	if selection_component:
		selection_component.base_color = Color.RED
		selection_component.selected_color = Color.YELLOW
