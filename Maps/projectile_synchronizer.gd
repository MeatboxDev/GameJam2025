extends Node

const _bubble_scene: PackedScene = preload("uid://duhicp2kli703")

var bubble_number := 0
var _bubble_list: Dictionary = {}


@rpc("authority", "unreliable", "call_remote")
func _sync_position(index: int, pos: Vector3) -> void:
	if not _bubble_list.has(index):
		KLog.warning("Bubble with index " + str(index) + " not found over the net")
		return
	_bubble_list[index].global_position = pos


@rpc("any_peer", "reliable", "call_local")
func _net_spawn_bubble(bubble_info: Dictionary) -> void:
	var bubble_instance := _bubble_scene.instantiate()
	add_child(bubble_instance)
	for k: String in bubble_info:
		bubble_instance.set(k, bubble_info[k])
	bubble_instance.number = bubble_number
	bubble_instance.name = "bubble-" + str(bubble_number)
	bubble_instance.top_level = true
	_bubble_list[bubble_number] = bubble_instance
	bubble_number += 1
	

func _burst_bubble(num: int) -> void:
	var instance: Node3D = _bubble_list[num]
	if not instance:
		KLog.warning("Instance of bubble number " + str(num) + " not found, ignoring")
		return
	instance.queue_free()
	_bubble_list.erase(num)
	KLog.debug("Bursting " + str(num))

func _clear_bubbles() -> void:
	for i: int in _bubble_list.keys():
		_bubble_list[i].burst()
	bubble_number = 0

func _ready() -> void:
	multiplayer.peer_connected.connect(func(id: int) -> void:
		for i: int in _bubble_list.keys():
			var instance: StaticBody3D = _bubble_list[i]
			var info := {}
			info["collision_layer"] = 2 | 4
			info["collision_mask"] = 2 | 4
			info["position"] = instance.global_position
			info["speed"] = instance.speed
			info["decceleration"] = instance.decceleration
			info["direction"] = instance.direction
			rpc_id(id, "_net_spawn_bubble", info)
	)
	
	SignalBus.spawn_bubble.connect(func(info: Dictionary) -> void: rpc("_net_spawn_bubble", info))
	SignalBus.burst_bubble.connect(_burst_bubble)
	SignalBus.clear_bubbles.connect(_clear_bubbles)


func _physics_process(_delta: float) -> void:
	if not is_multiplayer_authority():
		return
	
	for i: int in _bubble_list.keys():
		rpc("_sync_position", i, _bubble_list[i].global_position)
