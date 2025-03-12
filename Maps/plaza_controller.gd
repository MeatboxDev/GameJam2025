class_name LobbyController extends Node

const PLAYER_SCENE := preload("res://Player/PlayerCharacter.tscn")

@export var _interface_manager: InterfaceManager

var _player_instance: CharacterBody3D = null

var _player_instance_list: Dictionary = {}

func create_server() -> void:
	Server.create_server()


func close_server() -> void:
	var err := Server.close_server()
	if err == OK:
		clear_players()
		_player_spawn(1)


func join_server() -> void:
	_interface_manager.open("JoinLobby")


func change_name() -> void:
	_interface_manager.open("UsernameChange")


func leave_server() -> void:
	var err := Server.disconnect_from_server()
	if err == OK:
		clear_players()
		_player_spawn(1)
	SignalBus.clear_bubbles.emit()


func clear_players() -> void:
	for id: int in _player_instance_list.duplicate():
		remove_player(id)


func remove_player(id: int) -> void:
	if not _player_instance_list.has(id):
		KLog.warning("Player instance " + str(id) + " not found")
		return
	var player_instance: CharacterBody3D = _player_instance_list[id]
	player_instance.queue_free()
	_player_instance_list.erase(id)


func start_game() -> void:
	rpc("send_players_to_game")
	

@rpc("any_peer", "call_local", "reliable")
func send_players_to_game() -> void:
	get_tree().change_scene_to_file("uid://dyn4fu87v2v8r")


func _ready() -> void:
	assert(_interface_manager, "Interface manager not set")
	assert(Server, "Server not set!")

	Server.multiplayer.peer_connected.connect(
		func(id: int) -> void:
			KLog.info("Player Joined: " + str(id))
			if id != multiplayer.get_unique_id():
				rpc_id(id, "_player_spawn", multiplayer.get_unique_id())
				rpc_id(id, "_player_set_name", multiplayer.get_unique_id(), _player_instance.username)
	)

	Server.multiplayer.peer_disconnected.connect(remove_player)
	
	Server.multiplayer.connected_to_server.connect(
		func() -> void:
			SignalBus.clear_bubbles.emit()
			_player_spawn(multiplayer.get_unique_id())
	)
	
	Server.multiplayer.server_disconnected.connect(
		func() -> void:
			clear_players()
			_player_spawn(1)
			SignalBus.clear_bubbles.emit()
	)

	_player_spawn(1)


@rpc("reliable", "any_peer", "call_remote")
func _player_spawn(multiplayer_id: int) -> void:
	var found := find_child(str(multiplayer_id), false, false)
	if found:
		found.name = "old-" + str(multiplayer_id)
	var player_instance := PLAYER_SCENE.instantiate()

	player_instance.set_multiplayer_authority(multiplayer_id)
	player_instance.name = str(multiplayer_id)

	_player_instance_list[multiplayer_id] = player_instance
	add_child(player_instance)
	if multiplayer_id == multiplayer.get_unique_id():
		_player_instance = player_instance
		SignalBus.current_player_change.emit(_player_instance)


@rpc("reliable", "any_peer", "call_remote")
func _player_set_name(multiplayer_id: int, username: String) -> void:
	var player: CharacterBody3D = _player_instance_list[multiplayer_id]
	if not player:
		KLog.error("Could not find player " + username + " with id " + str(multiplayer_id))
		return
	player.username = username
