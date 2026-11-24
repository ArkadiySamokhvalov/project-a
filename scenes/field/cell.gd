class_name Cell
extends Control

@export var team_id: String = "left"

func _can_drop_data(_at_position: Vector2, data: Variant) -> bool:
	print("НАВЕЛ НА ЯЧЕЙКУ: ", name, " команда: ", team_id)
	if data is DraggableItem:
		return data.team_id == team_id and get_child_count() == 0
	return false

func _drop_data(_at_position: Vector2, data: Variant) -> void:
	if data is DraggableItem:
		DragManager.move_item_to_cell(data, self)

func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		if DragManager.selected_item != null:
			DragManager.move_item_to_cell(DragManager.selected_item, self)
			accept_event()
