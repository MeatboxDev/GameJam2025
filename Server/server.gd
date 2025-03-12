class_name Bubbly extends Node

signal connection_result(result: bool)

signal server_player_connected(id: int)
signal client_player_connected(id: int)

signal server_player_disconnected(id: int)
signal client_player_disconnected(id: int)
signal client_connected_to_server
signal client_disconnected_from_server

const IP_ADDRESS := "*"

const PORT := 2100

const MAX_CLIENTS := 8

const TIMEOUT_DURATION := 5.0

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
	
	SignalBus.connect_to_server.connect(
		func(ip: String, port: String) -> void:
			connect_to_server(ip, int(port))
	)
	
	SignalBus.disconnect_from_server.connect(disconnect_from_server)
	
	SignalBus.create_server.connect(
		func(ip: String, port: String) -> void:
			create_server(ip, int(port))
	)


## Creates a server for players
func create_server(
	ip: String = IP_ADDRESS, port: int = PORT, max_clients: int = MAX_CLIENTS
) -> Error:
	if _join_timeout.timeout.is_connected(_connection_timeout):
		KLog.error("Can't create server while attempting a connection")
		return ERR_CANT_CREATE
	if _peer != null or _join_timeout.timeout.is_connected(_connection_timeout):
		KLog.error("You already have a connection open")
		return ERR_CANT_CREATE
	if not _is_valid_ip(ip) or clamp(port, 1, 65535) != port:
		KLog.error("Invalid IP / PORT " + ip + ":" + str(port))
		return ERR_CANT_CREATE

	_peer = ENetMultiplayerPeer.new()
	_peer.set_bind_ip(ip)

	var err := _peer.create_server(port, max_clients)
	match err:
		OK:
			pass
		ERR_ALREADY_IN_USE:
			_peer = null
			KLog.error("Address " + ip + ":" + str(port) + " already in use!")
			return err
		ERR_CANT_CREATE:
			_peer = null
			KLog.error("Couldn't create server! (Reason Unknown)")
			return err

	multiplayer.multiplayer_peer = _peer

	KLog.info("Created server with ip " + ip + ":" + str(port))
	return OK


func _is_valid_ip(ip: String) -> bool:
	var split := ip.split(".")
	if ip == "*":
		return true
	if split.size() != 4:
		return false
	for s in split:
		if str(s.to_int()) != str(s):
			return false
	for s in split:
		if clamp(s.to_int(), 0, 255) != s.to_int():
			return false
	return true


func connect_to_server(ip: String = IP_ADDRESS, port: int = PORT) -> Error:
	if _join_timeout.timeout.is_connected(_connection_timeout):
		KLog.error("Can't connect while attempting a connection")
		return ERR_CANT_CREATE
	if ip == "*" or not _is_valid_ip(ip) or clamp(port, 1, 65535) != port:
		KLog.error("This shit ain't a valit PORT")
		return ERR_CANT_CREATE

	_peer = null
	multiplayer.multiplayer_peer = null

	_peer = ENetMultiplayerPeer.new()
	var err := _peer.create_client(ip, port)
	match err:
		OK:
			pass
		ERR_ALREADY_IN_USE:
			_peer = null
			KLog.error("Address " + ip + ":" + str(port) + " already in use!")
			return err
		ERR_CANT_CREATE:
			_peer = null
			KLog.error("Couldn't create server! (Reason Unknown)")
			return err

	_join_timeout.start(TIMEOUT_DURATION)
	_join_timeout.timeout.connect(_connection_timeout)

	multiplayer.multiplayer_peer = _peer

	client_connected_to_server.emit()
	KLog.info("Joined server " + ip + ":" + str(port))
	return OK


func disconnect_from_server() -> Error:
	if _peer == null:
		KLog.error("You're not connected to a server")
		return ERR_CANT_CREATE
	if _join_timeout.timeout.is_connected(_connection_timeout):
		KLog.error("Can't close server while attempting a connection")
		return ERR_CANT_CREATE
	if is_multiplayer_authority():
		KLog.error("Don't use this if you're host, close instead")
		return ERR_CANT_CREATE

	_c_on_server_disconnected()
	return OK


func close_server() -> Error:
	if _peer == null:
		KLog.error("You're not connected to a server")
		return ERR_CANT_CREATE
	if _join_timeout.timeout.is_connected(_connection_timeout):
		KLog.error("Can't close server while attempting a connection")
		return ERR_CANT_CREATE
	if not is_multiplayer_authority():
		KLog.error("Can't close a server you aren't host of")
		return ERR_CANT_CREATE
	
	_peer = null
	_clear_players()
	
	KLog.info("Closed server")
	return OK


## Returns [code]true[/code]
## if the caller is a server
func is_server() -> bool:
	return multiplayer.get_unique_id() == 1


## Returns [code]true[/code]
## if the caller is a client
func is_client() -> bool:
	return multiplayer.get_unique_id() != 1


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
		KLog.info("Host disconnected, letting _c_on_server_disconnected handle it")
		return
	rpc("_remove_player", id)
	if multiplayer.is_server():
		_s_on_peer_disconnected(id)
	else:
		_c_on_peer_disconnected(id)


func _s_on_peer_connected(id: int) -> void:
	server_player_connected.emit(id)
	KLog.info("Peer connected " + str(id))


func _s_on_peer_disconnected(id: int) -> void:
	server_player_disconnected.emit(id)
	KLog.info("Peer disconnected " + str(id))


func _c_on_peer_connected(id: int) -> void:
	if id == 1: # If peer connecting is id 1, connection succesful
		_join_timeout.timeout.disconnect(_connection_timeout)
	client_player_connected.emit(id)
	KLog.info("Peer connected " + str(id))


func _c_on_peer_disconnected(id: int) -> void:
	client_player_disconnected.emit(id)
	KLog.info("Peer disconnected " + str(id))


func _c_on_connected_to_server() -> void:
	_add_player(multiplayer.get_unique_id())
	KLog.info("Successfully connected to the server")
	connection_result.emit(true)


func _c_on_server_disconnected() -> void:
	_peer = null
	_clear_players()
	client_disconnected_from_server.emit()
	KLog.info("Disconnected from server")


func _c_connection_failed() -> void:
	_peer = null
	KLog.warning("Couldn't connect to server")
	connection_result.emit(false)


@rpc("any_peer", "reliable", "call_local")
func _add_player(id: int) -> void:
	connected_peers.append(id)


@rpc("any_peer", "reliable", "call_local")
func _remove_player(id: int) -> void:
	if not connected_peers.has(id):
		KLog.warning("Cant' disconnect " + str(id) + ", not found")
	connected_peers.erase(id)


func _clear_players() -> void:
	connected_peers.clear()
