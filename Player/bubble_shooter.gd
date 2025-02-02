extends Node3D

@export var player_model: CharacterBody3D

const _bubble_scene: PackedScene = preload("uid://duhicp2kli703")

func _shoot_bubble() -> void:
	var bubble_instance := _bubble_scene.instantiate()
	bubble_instance.position = self.global_position
	bubble_instance.speed = 0.3
	var dir: Vector3 = -player_model.find_child("CameraStick").basis.z
	var mod := dir.dot(player_model.velocity.normalized())
	mod = abs(mod)
	mod = clamp(mod, 0.0, 1)
	dir = dir + player_model.velocity.normalized() * mod
	
	bubble_instance.direction = dir
	get_tree().current_scene.add_child(bubble_instance)

func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		_shoot_bubble()
