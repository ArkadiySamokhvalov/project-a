extends Node

signal ship_selected(ship: Control)

var selected_item: Control = null

func select_item(item: Control) -> void:
	if selected_item == item:
		deselect_item()
		return
	deselect_item()
	selected_item = item
	selected_item.modulate = Color(1.3, 1.3, 1.3)

func deselect_item() -> void:
	if is_instance_valid(selected_item):
		selected_item.modulate = Color.WHITE
	selected_item = null

func move_item_to_cell(item: Control, target_cell: Control) -> void:
	if item.team_id != target_cell.team_id or target_cell.get_child_count() > 0:
		return
	item.get_parent().remove_child(item)
	target_cell.add_child(item)
	item.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	deselect_item()

func return_item_home(item: Control) -> void:
	if is_instance_valid(item.home_slot) and item.get_parent() != item.home_slot:
		item.get_parent().remove_child(item)
		item.home_slot.add_child(item)
		item.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	deselect_item()
