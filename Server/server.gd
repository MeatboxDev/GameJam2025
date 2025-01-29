class_name Bubbly extends Node

const IP_ADDRESS := "127.0.0.1"
const PORT := 2100
const MAX_CLIENTS := 8
const TIMEOUT_DURATION := 5.0

signal connection_result(result: bool)

var connected_peers: Array[int] = []

var _peer: ENetMultiplayerPeer = null:
	get():
		return _peer
	set(val):
		if _peer != null and val != null:
			assert(false)
		_peer = val
		if _peer == null:
			multiplayer.multiplayer_peer = OfflineMultiplayerPeer.new()

@onready var _join_timeout: Timer = Timer.new()


func _ready() -> void:
	add_child(_join_timeout)
	_join_timeout.autostart = false
	_join_timeout.one_shot = true

	multiplayer.peer_connected.connect(_on_peer_connected)
	multiplayer.peer_disconnected.connect(_on_peer_disconnected)
	multiplayer.connected_to_server.connect(_c_on_connected_to_server)
	multiplayer.server_disconnected.connect(_c_on_server_disconnected)
	multiplayer.connection_failed.connect(_c_connection_failed)


func _print_error_message(msg: String) -> void:
	print("ERROR: " + msg)
	print_stack()


func _print_error(err: Error) -> void:
	printerr(error_string(err))
	print_stack()


func _print_success(msg: String) -> void:
	print("SUCCESS: " + msg)


func _print_info(msg: String) -> void:
	print("INFO: " + msg)

## Creates a server for players
func create_server(
	ip: String = IP_ADDRESS, port: int = PORT, max_clients: int = MAX_CLIENTS
) -> Error:
	if _join_timeout.timeout.is_connected(_connection_timeout):
		_print_error_message("Can't create a server while attempting a connection")
		return ERR_CANT_CREATE
	if _peer != null or _join_timeout.timeout.is_connected(_connection_timeout):
		_print_error_message("You already have a connection open")
		return ERR_CANT_CREATE
	if _is_valid_ip(ip):
		_print_error_message("This shit ain't a valit IP")
		return ERR_CANT_CREATE
	if clamp(port, 0, 65535) != port:
		_print_error_message("This shit ain't a valit PORT")
		return ERR_CANT_CREATE
	
	_peer = ENetMultiplayerPeer.new()
	_peer.set_bind_ip(ip)

	var err := _peer.create_server(port, max_clients)
	match err:
		OK:
			pass
		ERR_ALREADY_IN_USE:
			_peer = null
			_print_error(err)
			return err
		ERR_CANT_CREATE:
			_peer = null
			_print_error(err)
			return err

	multiplayer.multiplayer_peer = _peer
	multiplayer.peer_connected.emit(multiplayer.get_unique_id())

	_print_success("Created server with ip " + ip + ":" + str(port))
	return OK

func _is_valid_ip(str: String) -> bool:
	var split := str.split(".")
	if split.size() != 4:
		return false
	for s in split:
		if clamp(s.to_int(), 0, 255) != s.to_int():
			return false
	return true


func connect_to_server(ip: String = IP_ADDRESS, port: int = PORT) -> Error:
	if _join_timeout.timeout.is_connected(_connection_timeout):
		_print_error_message("Can't connect while attempting a connection")
		return ERR_CANT_CREATE
	if _peer != null:
		_print_error_message("You already have a connection open")
		return ERR_CANT_CREATE
	if not _is_valid_ip(ip):
		print(ip)
		_print_error_message("This shit ain't a valit IP")
		return ERR_CANT_CREATE
	if clamp(port, 0, 65535) != port:
		_print_error_message("This shit ain't a valit PORT")
		return ERR_CANT_CREATE

	_peer = ENetMultiplayerPeer.new()
	var err := _peer.create_client(ip, port)
	match err:
		OK:
			pass
		ERR_ALREADY_IN_USE:
			_peer = null
			_print_error(err)
			return err
		ERR_CANT_CREATE:
			_peer = null
			_print_error(err)
			return err

	_join_timeout.start(TIMEOUT_DURATION)
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
	multiplayer.server_disconnected.emit()
	_clear_players()

	_print_info("Disconnected from server")
	return OK


func _connection_timeout() -> void:
	_join_timeout.timeout.disconnect(_connection_timeout)
	_peer = null
	multiplayer.connection_failed.emit()


func _on_peer_connected(id: int) -> void:
	rpc_id(id, "_add_player", multiplayer.get_unique_id())
	if multiplayer.is_server():
		_s_on_peer_connected(id)
	else:
		_c_on_peer_connected(id)


func _on_peer_disconnected(id: int) -> void:
	if id == 1:
		print("Host disconnected, letting _c_on_server_disconnected handle it")
		return
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
	connection_result.emit(true)


func _c_on_server_disconnected() -> void:
	_peer = null
	_clear_players()
	_print_error_message("Disconnected from server")


func _c_connection_failed() -> void:
	_peer = null
	_print_error_message("Couldn't connect to server")
	connection_result.emit(false)

@rpc("any_peer", "reliable", "call_local")
func _add_player(id: int) -> void:
	connected_peers.append(id)


@rpc("any_peer", "reliable", "call_local")
func _remove_player(id: int) -> void:
	if not connected_peers.has(id):
		_print_error_message("Cant' disconnect " + str(id) + ", not found")
	connected_peers.erase(id)


func _clear_players() -> void:
	connected_peers.clear()
