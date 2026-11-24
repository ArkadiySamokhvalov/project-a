class_name ShipData
extends Resource

@export var ship_name: String = "Ship"
@export var ship_texture: Texture2D
@export var rotate_for_team: bool = false
@export var visual_scale: Vector2 = Vector2.ONE

@export_group("Abilities")
@export var move_skill: SkillData
@export var active_skill_1: SkillData
@export var active_skill_2: SkillData
@export var passive_skill: SkillData

func get_all_skills() -> Array[SkillData]:
	return [move_skill, active_skill_1, active_skill_2, passive_skill]
