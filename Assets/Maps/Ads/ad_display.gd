extends Node3D

var _ads : Array [Sprite3D] = []

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	_ads.append($Ad_mount_collisions/Sprite_01)
	_ads.append($Ad_mount_collisions/Sprite_02)
	_ads.append($Ad_mount_collisions/Sprite_03)
	_ads.append($Ad_mount_collisions/Sprite_04)
	
	_ads.pick_random().show()
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
