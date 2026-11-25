extends CanvasLayer

# Ссылки на центральные элементы управления и заголовок фазы
@onready var phase_name: Label = %PhaseName
@onready var accept_button: BaseButton = %AcceptButton

# Ссылки на интерфейс левого игрока (Игрок 1)
@onready var p1_crown: TextureRect = %LeftPlayer/Crown
@onready var p1_nickname: Label = %LeftPlayer/Nickname
@onready var p1_time: Label = %LeftPlayer/Time
@onready var p1_checkbox: TextureButton = %LeftPlayer/Checkbox
@onready var p1_slots: VBoxContainer = %Left/VBoxContainer
@onready var left_skills_box: HBoxContainer = %LeftPlayerSkills/HBoxContainer

# Ссылки на интерфейс правого игрока (Игрок 2)
@onready var p2_crown: TextureRect = %RightPlayer/Crown
@onready var p2_nickname: Label = %RightPlayer/Nickname
@onready var p2_time: Label = %RightPlayer/Time
@onready var p2_checkbox: TextureButton = %RightPlayer/Checkbox
@onready var p2_slots: VBoxContainer = %Right/VBoxContainer
@onready var right_skills_box: HBoxContainer = %RightPlayerSkills/HBoxContainer

# Массивы узлов TextureRect для отображения иконок 4 навыков в нижней панели
var left_skill_icons: Array[TextureRect] = []
var right_skill_icons: Array[TextureRect] = []

# Список всех заблокированных кораблей, расставленных на игровом поле
var placed_ships: Array[DraggableItem] = []

# Флаг, позволяющий отличить нажатие кнопки игроком от автоматического срабатывания таймера
var is_manual_confirm: bool = false


# Системный метод Godot: инициализация интерфейса и подписка на сигналы
func _ready() -> void:
	# Собираем ссылки на узлы Icon внутри 4 слотов навыков левого и правого игроков
	for slot in left_skills_box.get_children():
		left_skill_icons.append(slot.get_node("Icon"))
		
	for slot in right_skills_box.get_children():
		right_skill_icons.append(slot.get_node("Icon"))

	# Подписываемся на выбор корабля и очищаем слоты навыков на старте
	DragManager.ship_selected.connect(on_ship_selected)
	clear_icons(left_skill_icons)
	clear_icons(right_skill_icons)
	
	# Подписываемся на все события конечного автомата TurnManager
	TurnManager.phase_changed.connect(on_phase_changed)
	TurnManager.timer_updated.connect(on_timer_updated)
	TurnManager.player_ready.connect(on_player_ready)
	TurnManager.banner_updated.connect(on_banner_updated)
	
	# Подключаем кнопку подтверждения хода/расстановки
	accept_button.pressed.connect(on_accept_pressed)


# Обновляет текст верхнего баннера по сигналу из TurnManager
func on_banner_updated(text: String) -> void:
	phase_name.text = text


# Отображает навыки выбранного корабля в нижней панели, если он установлен на поле
func on_ship_selected(item: Control) -> void:
	if item is Ship and item.data != null and item.get_parent() is Cell:
		var skills: Array[SkillData] = item.data.get_all_skills()
		if item.team_id == "left":
			fill_icons(left_skill_icons, skills)
			clear_icons(right_skill_icons)
		else:
			fill_icons(right_skill_icons, skills)
			clear_icons(left_skill_icons)
	else:
		clear_icons(left_skill_icons)
		clear_icons(right_skill_icons)


# Заполняет слоты нижней панели иконками навыков переданного корабля
func fill_icons(slots: Array[TextureRect], skills: Array[SkillData]) -> void:
	for i in range(slots.size()):
		if i < skills.size() and skills[i] != null and skills[i].icon != null:
			slots[i].texture = skills[i].icon
			slots[i].visible = true
		else:
			slots[i].texture = null
			slots[i].visible = false


# Очищает и скрывает иконки в указанных слотах навыков
func clear_icons(slots: Array[TextureRect]) -> void:
	for slot in slots:
		if is_instance_valid(slot):
			slot.texture = null
			slot.visible = false


# Обрабатывает нажатие на кнопку подтверждения (AcceptButton) в зависимости от текущей фазы
func on_accept_pressed() -> void:
	var phase = TurnManager.current_phase
	var team = TurnManager.active_team
	
	match phase:
		TurnManager.Phase.PLACEMENT_P1, TurnManager.Phase.PLACEMENT_P2:
			# Не даем завершить расстановку, если в боковой панели еще остались корабли
			if not are_all_ships_placed(team):
				phase_name.text = "РАССТАВЬТЕ ВСЕ КОРАБЛИ!"
				return
			
			lock_team_ships(team)
			is_manual_confirm = true
			TurnManager.confirm_action()
			is_manual_confirm = false
			
		TurnManager.Phase.PLANNING_P1, TurnManager.Phase.PLANNING_P2:
			DragManager.deselect_item()
			is_manual_confirm = true
			TurnManager.confirm_action()
			is_manual_confirm = false
# Обновляет галочки готовности игроков и обрабатывает истечение таймера (таймаут)
func on_player_ready(team: String, is_ready: bool) -> void:
	if team == "left":
		p1_checkbox.button_pressed = is_ready
	elif team == "right":
		p2_checkbox.button_pressed = is_ready

	# Если игрок стал готов, но кнопка не была нажата вручную — значит вышло время таймера
	if is_ready and not is_manual_confirm:
		var phase = TurnManager.current_phase
		if phase in [TurnManager.Phase.PLACEMENT_P1, TurnManager.Phase.PLACEMENT_P2]:
			auto_place_remaining_ships(team)
			lock_team_ships(team)
		elif phase in [TurnManager.Phase.PLANNING_P1, TurnManager.Phase.PLANNING_P2]:
			DragManager.deselect_item()


# Проверяет, что все боковые слоты указанной команды пусты (все корабли перенесены на поле)
func are_all_ships_placed(team: String) -> bool:
	var slots_container = p1_slots if team == "left" else p2_slots
	for slot in slots_container.get_children():
		if slot.get_child_count() > 0:
			return false
	return true


# Блокирует корабли команды на поле после расстановки, чтобы их нельзя было сдвинуть
func lock_team_ships(team: String) -> void:
	DragManager.deselect_item()
	for node in get_tree().get_root().find_children("*", "DraggableItem", true, false):
		if node.team_id == team:
			node.is_locked = true
			if not placed_ships.has(node):
				placed_ships.append(node)


# Автоматически расставляет оставшиеся в панели корабли на случайные пустые клетки половины поля игрока
func auto_place_remaining_ships(team: String) -> void:
	var slots_container = p1_slots if team == "left" else p2_slots
	var unplaced_ships: Array[DraggableItem] = []
	
	# Собираем все корабли, которые игрок не успел выставить из боковой панели
	for slot in slots_container.get_children():
		if slot.get_child_count() > 0:
			var item = slot.get_child(0)
			if item is DraggableItem:
				unplaced_ships.append(item)
			
	if unplaced_ships.is_empty():
		return

	# Ищем все пустые ячейки на половине поля текущей команды
	var all_cells = get_tree().get_root().find_children("*", "Cell", true, false)
	var valid_empty_cells: Array[Cell] = []
	
	for node in all_cells:
		if node is Cell and node.team_id == team and node.get_child_count() == 0:
			valid_empty_cells.append(node)

	# Перемешиваем список свободных клеток и размещаем в них оставшиеся корабли
	valid_empty_cells.shuffle()
	
	for ship in unplaced_ships:
		if valid_empty_cells.is_empty():
			break
		var target_cell: Cell = valid_empty_cells.pop_back()
		DragManager.move_item_to_cell(ship, target_cell)


# Обновляет текст таймера активного игрока каждую секунду
func on_timer_updated(time_left: int, active_team: String) -> void:
	if active_team == "left":
		p1_time.text = str(time_left)
	elif active_team == "right":
		p2_time.text = str(time_left)


# Настраивает видимость панелей, кораблей, короны и подсветки ников при смене фазы игры
func on_phase_changed(new_phase: TurnManager.Phase, active_team: String, initiative_team: String) -> void:
	var is_p1_active = (active_team == "left")
	var is_p2_active = (active_team == "right")
	
	# Корона отображается у игрока с инициативой (чей ход проиграется первым в фазе Битвы)
	p1_crown.modulate.a = 1.0 if initiative_team == "left" else 0.0
	p2_crown.modulate.a = 1.0 if initiative_team == "right" else 0.0
	
	# Золотой цвет ника показывает, кто из игроков прямо сейчас управляет экраном
	p1_nickname.modulate = Color.GOLD if is_p1_active else Color.WHITE
	p2_nickname.modulate = Color.GOLD if is_p2_active else Color.WHITE
	
	# Снимаем выделение с кораблей при каждом переходе между этапами
	DragManager.deselect_item()
	
	match new_phase:
		TurnManager.Phase.PLACEMENT_P1:
			phase_name.text = "РАССТАНОВКА: " + p1_nickname.text
			accept_button.disabled = false
			set_side_panel_visible("left", true)
			set_side_panel_visible("right", false)
			# Поле оппонента выглядит пустым во время расстановки первого игрока
			set_board_ships_visible("left", true)
			set_board_ships_visible("right", false)
			
		TurnManager.Phase.PLACEMENT_P2:
			phase_name.text = "РАССТАНОВКА: " + p2_nickname.text
			accept_button.disabled = false
			set_side_panel_visible("left", false)
			set_side_panel_visible("right", true)
			# Скрываем корабли первого игрока, чтобы второй расставлялся вслепую
			set_board_ships_visible("left", false)
			set_board_ships_visible("right", true)
			
		TurnManager.Phase.PLANNING_P1:
			phase_name.text = "ПЛАНИРОВАНИЕ: " + p1_nickname.text
			accept_button.disabled = false
			set_side_panel_visible("left", false)
			set_side_panel_visible("right", false)
			# В фазе планирования расстановка кораблей обеих сторон открыта
			set_board_ships_visible("left", true)
			set_board_ships_visible("right", true)
			
		TurnManager.Phase.PLANNING_P2:
			phase_name.text = "ПЛАНИРОВАНИЕ: " + p2_nickname.text
			accept_button.disabled = false
			set_side_panel_visible("left", false)
			set_side_panel_visible("right", false)
			set_board_ships_visible("left", true)
			set_board_ships_visible("right", true)
			
		TurnManager.Phase.TRANSITION:
			accept_button.disabled = true
			set_side_panel_visible("left", false)
			set_side_panel_visible("right", false)
			# На время передачи устройства прячем все корабли с поля
			set_board_ships_visible("left", false)
			set_board_ships_visible("right", false)
			
		TurnManager.Phase.RESOLUTION:
			accept_button.disabled = true
			set_board_ships_visible("left", true)
			set_board_ships_visible("right", true)
			
		TurnManager.Phase.GAME_OVER:
			accept_button.disabled = true
			set_board_ships_visible("left", true)
			set_board_ships_visible("right", true)


# Скрывает или показывает боковую панель со слотами кораблей для указанной команды
func set_side_panel_visible(team: String, is_vis: bool) -> void:
	if team == "left":
		p1_slots.visible = is_vis
	else:
		p2_slots.visible = is_vis


# Скрывает или показывает расставленные на игровом поле корабли указанной команды
func set_board_ships_visible(team: String, is_vis: bool) -> void:
	for ship in placed_ships:
		if is_instance_valid(ship) and ship.team_id == team:
			ship.visible = is_vis
