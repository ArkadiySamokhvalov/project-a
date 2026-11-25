class_name DraggableItem
extends Control

# Принадлежность корабля к команде ("left" или "right")
@export var team_id: String = "left"

# Ссылка на исходный слот в боковой панели, куда корабль возвращается по ПКМ
var home_slot: Control = null

# Флаг блокировки: true после завершения расстановки, чтобы корабль нельзя было двигать
var is_locked: bool = false


# Системный метод Godot: вызывается при появлении узла на сцене
func _ready() -> void:
	if get_parent() is Control:
		home_slot = get_parent()
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)


# Системный метод Godot: обрабатывает клики мыши по кораблю
func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_LEFT:
			DragManager.select_item(self)
			accept_event()
		elif event.button_index == MOUSE_BUTTON_RIGHT:
			DragManager.return_item_home(self)
			accept_event()


# Системный метод Godot: запускает перетаскивание (drag-and-drop)
func _get_drag_data(_at_position: Vector2) -> Variant:
	# Запрещаем перетаскивание только если корабль уже заблокирован после расстановки
	if is_locked:
		return null

	DragManager.deselect_item()
	
	# Создаем полупрозрачную копию корабля, которая следует за курсором при перетаскивании
	var preview = duplicate()
	preview.modulate.a = 0.7
	preview.mouse_filter = Control.MOUSE_FILTER_IGNORE
	
	var preview_container = Control.new()
	preview_container.add_child(preview)
	preview.position = -size / 2
	set_drag_preview(preview_container)
	return self



# Кастомная проверка: может ли текущий активный игрок перемещать этот корабль
func can_interact() -> bool:
	return not is_locked and team_id == TurnManager.active_team
