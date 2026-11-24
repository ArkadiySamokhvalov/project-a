class_name SkillData
extends Resource

enum SkillType { MOVE, ACTIVE, PASSIVE }

@export var skill_name: String = ""
@export var type: SkillType = SkillType.ACTIVE
@export var icon: Texture2D
@export_multiline var description: String = ""
