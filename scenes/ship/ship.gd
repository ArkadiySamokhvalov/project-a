class_name Ship
extends DraggableItem

@export var data: ShipData

@onready var image: TextureRect = %ShipImage

func _ready() -> void:
	super._ready()
	if data:
		if data.ship_texture:
			image.texture = data.ship_texture
		
		_on_image_resized()
		image.scale = data.visual_scale
		
		if data.rotate_for_team:
			image.rotation_degrees = 90.0 if team_id == "left" else -90.0
		else:
			image.rotation_degrees = 0.0


func _on_image_resized() -> void:
	if is_instance_valid(image):
		image.pivot_offset = image.size / 2.0
