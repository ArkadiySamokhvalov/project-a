class_name DraggableItem
extends Control

@export var team_id: String = "left"
var home_slot: Control = null

func _ready() -> void:
	if get_parent() is Control:
		home_slot = get_parent()
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_LEFT:
			DragManager.select_item(self)
			accept_event()
		elif event.button_index == MOUSE_BUTTON_RIGHT:
			DragManager.return_item_home(self)
			accept_event()

func _get_drag_data(_at_position: Vector2) -> Variant:
	print("ВЗЯЛ КОРАБЛЬ: ", name, " команда: ", team_id)
	DragManager.deselect_item()
	var preview = duplicate()
	preview.modulate.a = 0.7
	preview.mouse_filter = Control.MOUSE_FILTER_IGNORE
	
	var preview_container = Control.new()
	preview_container.add_child(preview)
	preview.position = -size / 2
	set_drag_preview(preview_container)
	return self
