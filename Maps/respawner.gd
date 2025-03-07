class_name Respawner extends Node

@export var _spawn_points: Array[Node3D] = []

func _request_spawn_point() -> Vector3:
	if _spawn_points.size() == 0:
		return Vector3.ZERO
	return _spawn_points.front().global_position
	
func _respawn_player(player: CharacterBody3D) -> void:
	player.global_position = _request_spawn_point()
	Klog.debug(str(player.global_position))

func _init() -> void:
	SignalBus.respawn_player.connect(_respawn_player)
