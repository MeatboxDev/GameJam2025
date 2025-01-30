class_name LobbyController extends Node

const PLAYER_SCENE := preload("res://Player/PlayerCharacter.tscn")

@export var _bubbly_server: Bubbly
@export var spawn_points: Array[Node3D]

var _player_instance: CharacterBody3D = null
var _player_instance_list: Dictionary = {}

# @onready var _lobby_interface: Control = $LobbyInterface
@onready var _join_interface: Control = $JoinInterface
@onready var _name_interface: Control = $NameInterface


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
	_player_spawn(1)


func join_server() -> void:
	print("Showing join server prompt...")
	_join_interface.visible = true
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

	var join_container: HBoxContainer = _join_interface.get_child(0)
	var join_button: Button = join_container.get_child(0)
	var input_container: VBoxContainer = join_container.get_child(1)
	var ip_input: TextEdit = input_container.get_child(0)
	var port_input: TextEdit = input_container.get_child(1)
	
	ip_input.grab_focus()

	await join_button.pressed

	print("Join pressed")
	_join_interface.visible = false

	if is_multiplayer_authority():
		close_server()
	else:
		leave_server()

	_bubbly_server.connect_to_server(
		_bubbly_server.IP_ADDRESS if ip_input.text == "" else ip_input.text,
		_bubbly_server.PORT if port_input.text == "" else (port_input.text).to_int()
	)

	var res: bool = await _bubbly_server.connection_result
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

	if res:
		print("Connection successful " + str(multiplayer.get_unique_id()))
		clear_players()
		_player_spawn(multiplayer.get_unique_id())
	else:
		print("Connection unsuccessful")


func leave_server() -> void:
	if is_multiplayer_authority():
		print("You're the host, use the close option")
		return

	print("LEAVE NOW")

	_bubbly_server.disconnect_from_server()
	clear_players()
	_player_spawn(1)


func change_name() -> void:
	if multiplayer.multiplayer_peer is ENetMultiplayerPeer:
		print("Go to your own crib to change your name >:(")
		return
	print("Changing username...")
	_name_interface.visible = true
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	
	var _name_container: HBoxContainer = _name_interface.get_child(0)
	var _confirm_button: Button = _name_container.get_child(0)
	var _username_input: TextEdit = _name_container.get_child(1)
	
	await _confirm_button.pressed
	
	var config := ConfigFile.new()
	var username := _username_input.text
	config.set_value("Userdata", "username", username)
	config.save("user://userdata.cfg")
	
	_player_instance.username = username
	_name_interface.visible = false
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED


func clear_players() -> void:
	for id: int in _player_instance_list.duplicate():
		remove_player(id)


func remove_player(id: int) -> void:
	if not _player_instance_list.has(id):
		print_debug("Player instance " + str(id) + " not found")
		return

	var player_instance: CharacterBody3D = _player_instance_list[id]
	player_instance.free()
	_player_instance_list.erase(id)


func _ready() -> void:
	assert(spawn_points.size() > 0, "You need to specify at least one spawn point")
	# assert(_lobby_interface, "Lobby interface is missing")
	assert(_bubbly_server, "Server not set!")

	_bubbly_server.multiplayer.peer_connected.connect(
		func(id: int) -> void:
			print("INFO: Player Joined: " + str(id))
			if id != multiplayer.get_unique_id():
				rpc_id(id, "_player_spawn", multiplayer.get_unique_id())
				
	)

	_bubbly_server.multiplayer.peer_disconnected.connect(remove_player)
	_bubbly_server.multiplayer.server_disconnected.connect(
		func() -> void:
			clear_players()
			_player_spawn(1)
	)

	_player_spawn(1)


func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.is_pressed() and event.keycode == KEY_E and _join_interface.visible:
		get_viewport().set_input_as_handled()
		# TODO: Find a better way to not let the E go through when interacting
		return
	if event is InputEventKey and event.is_pressed() and event.keycode == KEY_ESCAPE:
		_join_interface.visible = false
		_name_interface.visible = false
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED 

@rpc("reliable", "any_peer", "call_remote")
func _player_spawn(id: int) -> void:
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
