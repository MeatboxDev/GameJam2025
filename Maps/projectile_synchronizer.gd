extends Node

const _bubble_scene: PackedScene = preload("uid://duhicp2kli703")

var _bubble_list: Array[Bubble] = []

@rpc("authority", "unreliable", "call_remote")
func _sync_position(index: int, pos: Vector3) -> void:
	var instance: Array[Bubble] = _bubble_list.filter(func(i: Bubble) -> bool: return i.number == index)
	if not instance.size():
		KLog.warning("Bubble with index " + str(index) + " not found over the net")
		return
	instance.front().global_position = pos


@rpc("any_peer", "reliable", "call_local")
func _net_spawn_bubble(bubble_info: Dictionary) -> void:
	var bubble_instance := _bubble_scene.instantiate()
	add_child(bubble_instance)
	
	bubble_instance.number = (_bubble_list.back().number + 1) if _bubble_list.size() else 0
	for k: String in bubble_info:
		bubble_instance.set(k, bubble_info[k])
	bubble_instance.name = "bubble-" + str(bubble_instance.number)
	bubble_instance.top_level = true
	
	_bubble_list.append(bubble_instance)


## [b][color=red]Server Function[/color][/b]
func _burst_bubble(num: int) -> void:
	assert(Server.is_server(), "_burst_bubble running on client not allowed")
	var index: int = _bubble_list.find_custom(func(i: Bubble) -> bool: return i.number == num)
	if index == -1:
		KLog.warning("Instance of bubble number " + str(num) + " not found, ignoring")
		return
	rpc("_burst_bubble_client", index)


## [b][color=red]Client Function[/color][/b]
@rpc("authority", "call_local", "reliable")
func _burst_bubble_client(index: int) -> void:
	KLog.debug("I be poppin bubbles")
	_bubble_list[index].queue_free()
	_bubble_list.remove_at(index)


func _clear_bubbles() -> void:
	for i: Node3D in _bubble_list.duplicate(false):
		i.burst()


func _ready() -> void:
	Server.server_player_connected.connect(_server_sync_projectiles)
	
	Server.client_disconnected_from_server.connect(_clear_bubbles)
	
	SignalBus.spawn_bubble.connect(func(info: Dictionary) -> void: rpc("_net_spawn_bubble", info))
	
	SignalBus.burst_bubble.connect(_burst_bubble)
	
	SignalBus.clear_bubbles.connect(_clear_bubbles)

func _server_sync_projectiles(id: int) -> void:
	for i: Node3D in _bubble_list:
		var info := {}
		# TODO: This is horrible, fix as soon as possible
		info["collision_layer"] = 2 | 4
		info["collision_mask"] = 2 | 4
		info["position"] = i.global_position
		info["speed"] = i.speed
		info["decceleration"] = i.decceleration
		info["direction"] = i.direction
		info["number"] = i.number
		info["team"] = i.team
		rpc_id(id, "_net_spawn_bubble", info)


func _physics_process(_delta: float) -> void:
	if not is_multiplayer_authority():
		return
	
	for i: Node3D in _bubble_list:
		rpc("_sync_position", i.number, i.global_position)
