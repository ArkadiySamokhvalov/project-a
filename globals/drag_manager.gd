extends Node

# Сигнал оповещает интерфейс (HUD), какой корабль сейчас выбран (или null, если выделение снято)
signal ship_selected(ship: Control)

# Ссылка на текущий выделенный корабль
var selected_item: Control = null


# Выбирает корабль по клику мыши (или снимает выделение при повторном клике)
func select_item(item: Control) -> void:
	# Игнорируем пустой объект или корабль чужой команды
	if item == null or item.team_id != TurnManager.active_team:
		return

	# Проверяем, идет ли сейчас фаза планирования хода
	var is_planning = TurnManager.current_phase in [TurnManager.Phase.PLANNING_P1, TurnManager.Phase.PLANNING_P2]
	
	# Во время расстановки заблокированные корабли выбирать нельзя,
	# а во время планирования — можно, чтобы просматривать и выбирать их навыки
	if item.is_locked and not is_planning:
		return

	# Если кликнули по уже выбранному кораблю — снимаем выделение
	if selected_item == item:
		deselect_item()
		return

	set_selected(item)


# Устанавливает визуальное выделение на переданный корабль и отправляет сигнал в HUD
func set_selected(item: Control) -> void:
	# Возвращаем нормальную яркость предыдущему выбранному кораблю
	if is_instance_valid(selected_item):
		selected_item.modulate = Color.WHITE

	selected_item = item
	
	# Подсвечиваем новый выбранный корабль и оповещаем интерфейс
	if is_instance_valid(selected_item):
		selected_item.modulate = Color(1.3, 1.3, 1.3)
	
	emit_signal("ship_selected", selected_item)


# Полностью снимает выделение с текущего корабля
func deselect_item() -> void:
	if is_instance_valid(selected_item):
		selected_item.modulate = Color.WHITE

	selected_item = null
	emit_signal("ship_selected", null)


# Перемещает корабль в указанную ячейку поля
func move_item_to_cell(item: Control, target_cell: Control) -> void:
	# Запрещаем перемещение, если корабль заблокирован или принадлежит неактивному игроку
	if item.is_locked or item.team_id != TurnManager.active_team:
		return

	# Проверяем, что ячейка принадлежит команде корабля и в ней еще нет другого корабля
	if item.team_id != target_cell.team_id or target_cell.get_child_count() > 0:
		return

	# Переносим узел корабля из текущего родителя (слота или другой ячейки) в целевую ячейку
	item.get_parent().remove_child(item)
	target_cell.add_child(item)
	item.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	
	# Оставляем поставленный корабль выделенным, чтобы сразу отобразить его навыки внизу экрана
	set_selected(item)


# Возвращает корабль обратно в его исходный слот в боковой панели (по правому клику)
func return_item_home(item: Control) -> void:
	# Запрещаем возврат, если корабль заблокирован или принадлежит неактивному игроку
	if item.is_locked or item.team_id != TurnManager.active_team:
		return

	# Если исходный слот существует и корабль сейчас не в нем — возвращаем обратно
	if is_instance_valid(item.home_slot) and item.get_parent() != item.home_slot:
		item.get_parent().remove_child(item)
		item.home_slot.add_child(item)
		item.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		
	deselect_item()
