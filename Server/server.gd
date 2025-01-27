## AxoBubble Server

class_name Bubbly extends Node

const IP_ADDRESS := "127.0.0.1"
const PORT := 12398
const MAX_CLIENTS := 8
const TIMEOUT_DURATION := 5.0


class Player:
	var id := -1

	func is_host() -> bool:
		return id == 0


var connected_peers: Dictionary = {}

var _peer: ENetMultiplayerPeer = null:
	get():
		return _peer
	set(val):
		if _peer != null and val != null:
			assert(false)
		_peer = val

@onready var _join_timeout: SceneTreeTimer = get_tree().create_timer(TIMEOUT_DURATION)
@onready var _create_server_button: Button = $MainContainer/CreateServer
@onready var _join_server_button: Button = $MainContainer/JoinServer
@onready var _disconnect_client_button: Button = $MainContainer/DisconnectClient
@onready var _error_display: Label = $MainContainer/ErrorBox/ErrorDisplay
@onready var _success_display: Label = $MainContainer/SuccessBox/SuccessDisplay
@onready var _info_display: Label = $MainContainer/InfoBox/InfoDisplay
@onready var _connections: HBoxContainer = $MainContainer/Connections


func _ready() -> void:
	_create_server_button.pressed.connect(create_server)
	_join_server_button.pressed.connect(connect_to_server)
	_disconnect_client_button.pressed.connect(disconnect_from_server)

	multiplayer.peer_connected.connect(_on_peer_connected)
	multiplayer.peer_disconnected.connect(_on_peer_disconnected)
	multiplayer.connected_to_server.connect(_c_on_connected_to_server)
	multiplayer.server_disconnected.connect(_c_on_server_disconnected)
	multiplayer.connection_failed.connect(_c_connection_failed)


func _print_error_message(msg: String) -> void:
	print_stack()
	if _error_display:
		_error_display.text = msg
	print()


func _print_error(err: Error) -> void:
	printerr(error_string(err))
	print_stack()
	if _error_display:
		_error_display.text = error_string(err)
	print()


func _print_success(msg: String) -> void:
	print(msg)
	if _success_display:
		_success_display.text = msg
	print()


func _print_info(msg: String) -> void:
	print(msg)
	if _info_display:
		_info_display.text = msg
	print()


func create_server(
	ip: String = IP_ADDRESS, port: int = PORT, max_clients: int = MAX_CLIENTS
) -> Error:
	if _peer != null:
		_print_error_message("You already have a connection open")
		return ERR_CANT_CREATE

	_peer = ENetMultiplayerPeer.new()
	_peer.set_bind_ip(ip)

	var err := _peer.create_server(port, max_clients)
	match err:
		OK:
			pass
		ERR_ALREADY_IN_USE:
			_print_error(err)
			return err
		ERR_CANT_CREATE:
			_print_error(err)
			return err

	multiplayer.multiplayer_peer = _peer
	multiplayer.peer_connected.emit(multiplayer.get_unique_id())

	_print_success("Created server with ip " + ip + ":" + str(port))
	return OK


func connect_to_server(ip: String = IP_ADDRESS, port: int = PORT) -> Error:
	if _peer != null:
		_print_error_message("You already have a connection open")
		return ERR_CANT_CREATE

	_peer = ENetMultiplayerPeer.new()
	var err := _peer.create_client(ip, port)
	match err:
		OK:
			pass
		ERR_ALREADY_IN_USE:
			_print_error(err)
			return err
		ERR_CANT_CREATE:
			_print_error(err)
			return err
	_join_timeout.timeout.connect(_connection_timeout)

	multiplayer.multiplayer_peer = _peer

	return OK


func disconnect_from_server() -> Error:
	if _join_timeout.timeout.is_connected(_connection_timeout):
		_print_error_message("Can't disconnect while attempting a connection")
		return ERR_CANT_CREATE
	if _peer == null:
		_print_error_message("You're not connected to a server")
		return ERR_CANT_CREATE

	_peer = null
	multiplayer.multiplayer_peer = null
	_clear_players()

	_print_info("Disconnected from server")
	return OK


func _connection_timeout() -> void:
	_join_timeout.timeout.disconnect(_connection_timeout)
	_peer = null
	multiplayer.multiplayer_peer = null
	multiplayer.connection_failed.emit()


func _on_peer_connected(id: int) -> void:
	rpc_id(id, "_add_player", multiplayer.get_unique_id())
	if multiplayer.is_server():
		_s_on_peer_connected(id)
	else:
		_c_on_peer_connected(id)


func _on_peer_disconnected(id: int) -> void:
	rpc("_remove_player", id)
	if multiplayer.is_server():
		_s_on_peer_disconnected(id)
	else:
		_c_on_peer_disconnected(id)


func _s_on_peer_connected(id: int) -> void:
	_print_success("Peer connected " + str(id))


func _s_on_peer_disconnected(id: int) -> void:
	_print_info("Peer disconnected " + str(id))


func _c_on_peer_connected(id: int) -> void:
	if id == 1:
		_join_timeout.timeout.disconnect(_connection_timeout)
	_print_success("Peer connected " + str(id))


func _c_on_peer_disconnected(id: int) -> void:
	_print_info("Peer disconnected " + str(id))


func _c_on_connected_to_server() -> void:
	_add_player(multiplayer.get_unique_id())
	_print_success("Successfully connected to the server")


func _c_on_server_disconnected() -> void:
	_peer = null
	multiplayer.multiplayer_peer = null
	_clear_players()
	_print_error_message("Disconnected from server")


func _c_connection_failed() -> void:
	_peer = null
	multiplayer.multiplayer_peer = null
	_print_error_message("Couldn't connect to server")


@rpc("any_peer", "reliable", "call_local")
func _add_player(id: int) -> void:
	var connection := Label.new()
	connection.text = str(id)
	connection.name = str(id)
	_connections.add_child(connection)

	var player: Player = connected_peers.get_or_add(id, Player.new())
	player.id = id


@rpc("any_peer", "reliable", "call_local")
func _remove_player(id: int) -> void:
	var connection: Node = _connections.find_child(str(id), false, false)
	if connection:
		connection.queue_free()
	else:
		_print_error_message("Cant' disconnect " + str(id) + ", not found")

	connected_peers.erase(id)


func _clear_players() -> void:
	for c: Node in _connections.get_children():
		c.queue_free()
	connected_peers.clear()
