extends Node3D

@export var player_model: CharacterBody3D


#func _shoot_bubble_momentum() -> void:
	#var bubble_instance := _bubble_scene.instantiate()
	#bubble_instance.position = self.global_position
	#bubble_instance.speed = 0.5
	#var dir: Vector3 = -player_model.find_child("CameraStick").basis.z
	#var mod := dir.dot(player_model.velocity.normalized())
	#mod = abs(mod)
	#mod = clamp(mod, 0.0, 1)
	#dir = dir + player_model.velocity.normalized() * mod
	#
	#bubble_instance.direction = dir
	#get_tree().current_scene.add_child(bubble_instance)


func _shoot_bubble_stable() -> void:
	# Compose Bubble Information
	var bubble_info := {}
	bubble_info["position"] = self.global_position
	bubble_info["speed"] = player_model.bubble_speed
	bubble_info["decceleration"] = player_model.bubble_decceleration
	bubble_info["direction"] = -player_model.find_child("CameraStick").basis.z
	# Spawn on all clients
	SignalBus.spawn_bubble.emit(bubble_info)


func _input(event: InputEvent) -> void:
	if not is_multiplayer_authority():
		return
		
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		_shoot_bubble_stable()
