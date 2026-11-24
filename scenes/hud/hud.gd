extends CanvasLayer

@onready var left_skills_box: HBoxContainer = %LeftPlayerSkills/HBoxContainer
@onready var right_skills_box: HBoxContainer = %RightPlayerSkills/HBoxContainer

var left_skill_icons: Array[TextureRect] = []
var right_skill_icons: Array[TextureRect] = []

func _ready() -> void:
	for slot in left_skills_box.get_children():
		left_skill_icons.append(slot.get_node("Icon"))
		
	for slot in right_skills_box.get_children():
		right_skill_icons.append(slot.get_node("Icon"))

	DragManager.ship_selected.connect(_on_ship_selected)
	_clear_icons(left_skill_icons)
	_clear_icons(right_skill_icons)

func _on_ship_selected(item: Control) -> void:
	if item is Ship and item.data != null and item.get_parent() is Cell:
		var skills: Array[SkillData] = item.data.get_all_skills()
		if item.team_id == "left":
			_fill_icons(left_skill_icons, skills)
		else:
			_fill_icons(right_skill_icons, skills)
	else:
		_clear_icons(left_skill_icons)
		_clear_icons(right_skill_icons)

func _fill_icons(slots: Array[TextureRect], skills: Array[SkillData]) -> void:
	for i in range(slots.size()):
		if i < skills.size() and skills[i] != null:
			slots[i].texture = skills[i].icon
			slots[i].visible = true
		else:
			slots[i].texture = null
			slots[i].visible = false

func _clear_icons(slots: Array[TextureRect]) -> void:
	for slot in slots:
		if is_instance_valid(slot):
			slot.texture = null
			slot.visible = false
