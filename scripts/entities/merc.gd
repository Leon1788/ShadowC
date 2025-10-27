# merc.gd
# Söldner - BLAU
# Speicherort: res://scripts/entities/merc.gd

extends MercEntity

class_name Merc

func _ready():
	if Engine.is_editor_hint():
		return
	
	super._ready()
	
	if selection_component:
		selection_component.base_color = Color.BLUE
		selection_component.selected_color = Color.YELLOW
