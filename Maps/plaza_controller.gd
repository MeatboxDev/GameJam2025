class_name LobbyController extends Node

const PLAYER_SCENE := preload("res://Player/PlayerCharacter.tscn")

var _player_instance: CharacterBody3D = null
var _player_instance_list: Dictionary = {}

@export var _bubbly_server: Bubbly
@export var spawn_points: Array[Node3D]

@onready var _lobby_interface: Control = $LobbyInterface
@onready var _join_interface: Control = $JoinInterface

func create_server() -> void:
	print("Creating server for player...")
	var _err := _bubbly_server.create_server()


func close_server() -> void:
	if multiplayer.multiplayer_peer is OfflineMultiplayerPeer:
		print("You're already offline what are you on")
		return
	if not is_multiplayer_authority():
		print("You're not the Top G, can't close")
		return
		
	print("Closing server...")
	var _err := _bubbly_server.disconnect_from_server()
	remove_player(1)
	for p: int in _player_instance_list:
		remove_player(p) # Remove everyone else
	multiplayer.multiplayer_peer = OfflineMultiplayerPeer.new()
	_player_spawn(1) # Respawn player as host


func join_server() -> void:
	print("Showing join server prompt...")
	_join_interface.visible = true
	
	var join_container: HBoxContainer = _join_interface.get_child(0)
	var join_button: Button = join_container.get_child(0)
	var input_container: VBoxContainer = join_container.get_child(1)
	var ip_input: TextEdit = input_container.get_child(0)
	var port_input: TextEdit = input_container.get_child(1)
	
	await join_button.pressed
	
	print("Join pressed")
	_join_interface.visible = false
	
	_bubbly_server.connect_to_server(
		_bubbly_server.IP_ADDRESS if ip_input.text == "" else ip_input.text,
		_bubbly_server.PORT if port_input.text == "" else (port_input.text).to_int()
	)
	
	var res: bool = await _bubbly_server.connection_result
	
	if res:
		print("Connection successful")
		remove_player(1)
		_player_instance = null
		_player_spawn(multiplayer.get_unique_id())
	else:
		print("Connection unsuccessful")

@rpc("reliable", "any_peer", "call_remote")
func _player_spawn(id: int) -> void:
	var player_instance := PLAYER_SCENE.instantiate()
	var spawn_point: Node3D = spawn_points.front()
	spawn_points.push_back(spawn_points.pop_front())

	player_instance.set_multiplayer_authority(id)
	# player_instance.multiplayer.multiplayer_peer = _bubbly_server.multiplayer.multiplayer_peer
	
	player_instance.position = spawn_point.position
	player_instance.position.y = spawn_point.position.y + 2
	player_instance.name = str(id)
	
	_player_instance_list[id] = player_instance
	add_child(player_instance)
	if id == multiplayer.get_unique_id():
		_player_instance = player_instance

func remove_player(id: int) -> void:
	var player_instance: CharacterBody3D = _player_instance_list[id]
	if not player_instance:
		print_debug("Player instance " + str(id) + " not found")
		return
	player_instance.free()
	_player_instance_list.erase(id)


func _ready() -> void:
	assert(spawn_points.size() > 0, "You need to specify at least one spawn point")
	assert(_lobby_interface, "Lobby interface is missing")
	assert(_bubbly_server, "Server not set!")
	
	_bubbly_server.multiplayer.peer_connected.connect(
		func(id: int) -> void:
			print("INFO: Player Joined: " + str(id))
			if id != multiplayer.get_unique_id():
				rpc_id(id, "_player_spawn", multiplayer.get_unique_id())
	)
	
	_bubbly_server.multiplayer.peer_disconnected.connect(
		func(id: int) -> void:
			print("INFO: Player Left: " + str(id))
	)
	
	_bubbly_server.multiplayer.server_disconnected.connect(
		func() -> void:
			remove_player(1) # Remove host, traitor
			for p: int in _player_instance_list:
				remove_player(p) # Remove everyone else
			_player_instance_list.clear()
			multiplayer.multiplayer_peer = OfflineMultiplayerPeer.new()
			_player_spawn(1) # Respawn player as host
	)
	_player_spawn(1)

func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.is_pressed() and event.keycode == KEY_P:
		print(multiplayer.multiplayer_peer)
		print(_player_instance_list[1].multiplayer.multiplayer_peer)
		
