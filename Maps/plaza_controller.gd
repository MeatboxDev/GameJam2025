class_name LobbyController extends Node

const PLAYER_SCENE := preload("res://Player/PlayerCharacter.tscn")

@export var _bubbly_server: Bubbly
@export var spawn_points: Array[Node3D]
@export var _interface_manager: InterfaceManager


var _player_instance: CharacterBody3D = null
var _player_instance_list: Dictionary = {}

func create_server() -> void:
	if multiplayer.multiplayer_peer is ENetMultiplayerPeer:
		print("You already have a connection open slow down ")
		return
	print("Creating server for player...")
	_bubbly_server.create_server()


func close_server() -> void:
	if multiplayer.multiplayer_peer is OfflineMultiplayerPeer:
		print("You're not online what are you on")
		return
	if not is_multiplayer_authority():
		print("You're not host, get rekt")
		return

	print("Closing server...")
	_bubbly_server.disconnect_from_server()
	clear_players()
	player_spawn(1)

func join_server() -> void:
	_interface_manager.open("JoinLobby")

func leave_server() -> void:
	if is_multiplayer_authority():
		print("You're the host, use the close option")
		return

	print("LEAVE NOW")

	_bubbly_server.disconnect_from_server()
	clear_players()
	player_spawn(1)

func change_name() -> void:
	_interface_manager.open("UsernameChange")

func clear_players() -> void:
	for id: int in _player_instance_list.duplicate():
		remove_player(id)


func remove_player(id: int) -> void:
	if not _player_instance_list.has(id):
		print_debug("Player instance " + str(id) + " not found")
		return
	var player_instance: CharacterBody3D = _player_instance_list[id]
	player_instance.queue_free()
	_player_instance_list.erase(id)


func _ready() -> void:
	assert(_interface_manager, "Interface manager not set")
	assert(spawn_points.size() > 0, "You need to specify at least one spawn point")
	assert(_bubbly_server, "Server not set!")

	_bubbly_server.multiplayer.peer_connected.connect(
		func(id: int) -> void:
			print("INFO: Player Joined: " + str(id))
			if id != multiplayer.get_unique_id():
				rpc_id(id, "player_spawn", multiplayer.get_unique_id())
				_player_instance.load_username()
	)

	_bubbly_server.multiplayer.peer_disconnected.connect(remove_player)
	
	_bubbly_server.multiplayer.connected_to_server.connect(
		func() -> void:
			player_spawn(multiplayer.get_unique_id())
	)
	
	_bubbly_server.multiplayer.server_disconnected.connect(
		func() -> void:
			clear_players()
			player_spawn(1)
	)

	player_spawn(1)


@rpc("reliable", "any_peer", "call_remote")
func player_spawn(id: int) -> void:
	var player_instance := PLAYER_SCENE.instantiate()
	var spawn_point: Node3D = spawn_points.front()
	spawn_points.push_back(spawn_points.pop_front())

	player_instance.set_multiplayer_authority(id)
	
	player_instance.position = spawn_point.position
	player_instance.position.y = spawn_point.position.y + 2
	player_instance.name = str(id)

	_player_instance_list[id] = player_instance
	add_child(player_instance)
	if id == multiplayer.get_unique_id():
		_player_instance = player_instance
		_interface_manager.focused_player = player_instance
