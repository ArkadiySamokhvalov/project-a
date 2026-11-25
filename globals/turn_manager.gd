extends Node

# Перечисление всех возможных состояний игры (состояния конечного автомата).
# В каждый момент времени игра находится строго в одном из этих состояний.
enum Phase {
	PLACEMENT_P1,  # Расстановка кораблей: ходит первый игрок
	PLACEMENT_P2,  # Расстановка кораблей: ходит второй игрок
	PLANNING_P1,   # Фаза хода (выбор действия): ходит первый игрок
	PLANNING_P2,   # Фаза хода (выбор действия): ходит второй игрок
	RESOLUTION,    # Фаза битвы: автоматическое проигрывание выбранных действий
	TRANSITION,    # Пауза 3-2-1 для передачи устройства/экрана другому игроку
	GAME_OVER      # Конец игры (один из игроков победил)
}

# Сигналы — способ сообщить интерфейсу (HUD) и полю, что в игре что-то произошло,
# не привязывая этот скрипт напрямую к конкретным узлам на сцене.
signal phase_changed(new_phase: Phase, active_team: String, initiative_team: String)
signal timer_updated(time_left: int, active_team: String)
signal player_ready(team: String, is_ready: bool)
signal banner_updated(text: String)

var current_phase: Phase = Phase.PLACEMENT_P1
var active_team: String = "left"      # Игрок, который прямо сейчас взаимодействует с экраном ("left" или "right")
var initiative_team: String = "left"  # Игрок с короной: его действие сработает первым в фазе Битвы

var time_left: float = 30.0           # Оставшееся время текущего хода в секундах
var is_running: bool = false          # Флаг: идет ли сейчас отсчет таймера


func _ready() -> void:
	# Ждем 1 кадр, чтобы сцена HUD и все её узлы успели полностью загрузиться
	# и подписаться на сигналы TurnManager до того, как мы отправим первый сигнал.
	await get_tree().process_frame
	
	# Случайно выбираем, кому достанется корона в первом раунде (50% шанс)
	initiative_team = "left" if randf() < 0.5 else "right"
	
	# Запускаем самую первую фазу — расстановку для левого игрока
	_start_phase(Phase.PLACEMENT_P1, "left")


# _process вызывается каждый кадр. delta — время в секундах, прошедшее с прошлого кадра.
func _process(delta: float) -> void:
	# Если таймер поставлен на паузу — ничего не делаем
	if not is_running:
		return
		
	# Вычитаем прошедшее время из остатка
	time_left -= delta
	
	# Отправляем сигнал в HUD для обновления цифр на экране.
	# ceili округляет вверх (например, 29.1 -> 30), maxi не дает уйти в минус.
	emit_signal("timer_updated", maxi(0, ceili(time_left)), active_team)
	
	# Если время вышло — останавливаем таймер и вызываем обработчик
	if time_left <= 0.0:
		is_running = false
		_on_timeout()


# Универсальная функция запуска любой фазы игры
func _start_phase(phase: Phase, team: String, duration: float = 30.0) -> void:
	current_phase = phase
	active_team = team
	time_left = duration
	# Таймер запускается только если задана длительность больше 0 (в фазе Битвы duration = 0)
	is_running = (duration > 0.0)
	
	# Оповещаем HUD: сменилась фаза, обнови активного игрока и проверь, у кого корона
	emit_signal("phase_changed", current_phase, active_team, initiative_team)


# Главный метод перехода между этапами. Вызывается из HUD при нажатии на галочку (AcceptButton).
func confirm_action() -> void:
	is_running = false # Останавливаем таймер игрока, который нажал галочку
	emit_signal("player_ready", active_team, true) # Ставим галочку в его чекбоксе
	
	# В зависимости от того, какая фаза была сейчас, решаем, что включать дальше:
	match current_phase:
		Phase.PLACEMENT_P1:
			# Первый расставил -> через паузу передаем расстановку второму
			_transition_to(Phase.PLACEMENT_P2, "right")
			
		Phase.PLACEMENT_P2:
			# Оба расставили корабли -> начинаем 1-й раунд (Фаза хода).
			# Первым планирует действие тот, у кого сейчас корона (initiative_team).
			var next_phase = Phase.PLANNING_P1 if initiative_team == "left" else Phase.PLANNING_P2
			_transition_to(next_phase, initiative_team)
			
		Phase.PLANNING_P1:
			# Если левый игрок ходил первым (у него корона) -> передаем планирование правому.
			# Если корона была у правого, значит правый уже сходил до этого -> начинаем Битву!
			if initiative_team == "left":
				_transition_to(Phase.PLANNING_P2, "right")
			else:
				_start_resolution()
				
		Phase.PLANNING_P2:
			# Зеркальная логика для правого игрока
			if initiative_team == "right":
				_transition_to(Phase.PLANNING_P1, "left")
			else:
				_start_resolution()


# Промежуточная фаза с обратным отсчетом 3-2-1, чтобы игроки успели передать экран друг другу
func _transition_to(next_phase: Phase, next_team: String) -> void:
	current_phase = Phase.TRANSITION
	# Передаем пустую строку "" вместо active_team, чтобы на время паузы заблокировать кнопки обоим
	emit_signal("phase_changed", current_phase, "", initiative_team)
	
	# Цикл отсчета: 3, затем 2, затем 1 с паузой в 1 секунду на каждом шаге
	for i in [3,2,1]:
		emit_signal("banner_updated", "ПЕРЕДАЧА ХОДА: %d" % i)
		await get_tree().create_timer(1.0).timeout
		
	# После отсчета запускаем целевую фазу для следующего игрока
	_start_phase(next_phase, next_team, 30.0)


# Запуск фазы Битвы (проигрывание выбранных игроками действий)
func _start_resolution() -> void:
	# Передаем duration = 0.0, чтобы 30-секундный таймер не тикал во время анимаций боя
	_start_phase(Phase.RESOLUTION, initiative_team, 0.0)
	emit_signal("banner_updated", "ФАЗА БИТВЫ!")


# Эту функцию нужно будет вызвать из боевого скрипта, когда анимации атак обоих игроков завершатся
func finish_resolution_round(is_game_over: bool = false) -> void:
	if is_game_over:
		_start_phase(Phase.GAME_OVER, "", 0.0)
		emit_signal("banner_updated", "ИГРА ОКОНЧЕНА!")
		return
		
	# Передаем корону другому игроку на новый раунд
	initiative_team = "right" if initiative_team == "left" else "left"
	
	# Снимаем галочки готовности с чекбоксов обоих игроков перед новым раундом
	emit_signal("player_ready", "left", false)
	emit_signal("player_ready", "right", false)
	
	# Запускаем новую фазу планирования, начиная с нового владельца короны
	var next_phase = Phase.PLANNING_P1 if initiative_team == "left" else Phase.PLANNING_P2
	_transition_to(next_phase, initiative_team)


# Срабатывает, если игрок не успел нажать галочку за 30 секунд
func _on_timeout() -> void:
	confirm_action()
