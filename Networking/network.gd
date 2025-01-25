extends Node

const PORT: int = 1221
const IPADDR: String = "localhost"  # "100.93.129.57"

var multiplayer_peer: ENetMultiplayerPeer = ENetMultiplayerPeer.new()

var good_balls: int = 0
var bad_balls: int = 0
var connected_peer_ids: Array[int] = []
var good_guys: Array[int] = []
var bad_guys: Array[int] = []

@onready var good_guys_spawn: Node3D = $World/GoodGuysSpawn
@onready var bad_guys_spawn: Node3D = $World/BadGuysSpawn
@onready var join_lobby_cont: VBoxContainer = $Control/JoinLobby
@onready var join_btn: Button = $Control/JoinLobby/join
@onready var host_btn: Button = $Control/JoinLobby/host
@onready var status_container: VBoxContainer = $Control/Status
@onready var status_label: Label = $Control/Status/Status
@onready var id_label: Label = $Control/Status/Id
@onready var join_team_container: VBoxContainer = $Control/JoinTeam
@onready var join_good_btn: Button = $Control/JoinTeam/JoinGood
@onready var join_bad_btn: Button = $Control/JoinTeam/JoinBad


func _handle_place_good_boss() -> void:
	good_balls += 1
	print("GOOD: ", good_balls)
	print("BAD: ", bad_balls)


func _handle_place_bad_boss() -> void:
	bad_balls += 1
	print("GOOD: ", good_balls)
	print("BAD: ", bad_balls)


func _handle_burst_good_boss() -> void:
	good_balls += 1
	print("GOOD: ", good_balls)
	print("BAD: ", bad_balls)
	if good_balls == 0:
		print("Good loses :(")
		return
	if bad_balls == 0:
		print("Bad loses :(")
		return


func _handle_burst_bad_boss() -> void:
	bad_balls += 1
	print("GOOD: ", good_balls)
	print("BAD: ", bad_balls)
	if good_balls == 0:
		print("Good loses :(")
		return
	if bad_balls == 0:
		print("Bad loses :(")
		return


# # Called when the node enters the scene tree for the first time.
# func _ready() -> void:
# 	var upnp = UPNP.new()
# 	var discover_result = upnp.discover()

# 	if discover_result == UPNP.UPNP_RESULT_SUCCESS:
# 		if upnp.get_gateway() and upnp.get_gateway().is_valid_gateway():
# 			var map_result_tcp = upnp.add_port_mapping(1221, 1221, "godot_tcp", "TCP", 0)
# 			var map_result_udp = upnp.add_port_mapping(1221, 1221, "godot_udp", "UDP", 0)
# 			if not map_result_tcp == UPNP.UPNP_RESULT_SUCCESS:
# 				upnp.add_port_mapping(1221, 1221, "", "TCP")
# 			if not map_result_udp == UPNP.UPNP_RESULT_SUCCESS:
# 				upnp.add_port_mapping(1221, 1221, "", "UDP")

# 	var external_ip = upnp.query_external_address()

# 	print(external_ip)

# 	upnp.delete_port_mapping(1221, "TCP")
# 	upnp.delete_port_mapping(1221, "UDP")

@rpc("any_peer", "call_local", "reliable")
func add_new_connections(id: int) -> void:
	connected_peer_ids.append(id)
	add_player_character(id)


@rpc("any_peer", "reliable")
func add_previous_characters(good_ids: Array[int], bad_ids: Array[int]) -> void:
	for peer_id in good_ids:
		good_guys.append(peer_id)
		add_player_character(peer_id)
	for peer_id in bad_ids:
		bad_guys.append(peer_id)
		add_player_character(peer_id)


@rpc("any_peer", "reliable")
func show_join_team() -> void:
	join_team_container.visible = true


@rpc("any_peer", "reliable")
func handle_team_join(id: int, is_good: bool) -> void:
	# Host registers if someone is good or bad
	if is_good:
		good_guys.append(id)
	else:
		bad_guys.append(id)

	# Host tells everyone, this guy joined
	print("SENDING ADD NEW TO ALL PLAYERS")
	rpc("add_new_connections", id)


func _ready() -> void:
	join_good_btn.connect("pressed", join_good_team)
	join_bad_btn.connect("pressed", join_bad_team)
	SignalBus.place_good_boss.connect(_handle_place_good_boss)
	SignalBus.place_bad_boss.connect(_handle_place_bad_boss)
	SignalBus.burst_good_boss.connect(_handle_burst_good_boss)
	SignalBus.burst_bad_boss.connect(_handle_burst_bad_boss)
	SignalBus.player_defeat.connect(_handle_player_defeat)


func _respawn_player(player: CharacterBody3D) -> void:
	var is_good: bool = good_guys.has(player.get_multiplayer_authority())
	player.is_good = is_good
	var spawn: Node3D = good_guys_spawn if is_good else bad_guys_spawn
	player.position = spawn.position
	player.position.y = spawn.position.y + 3

	if (player.get_multiplayer_authority() == multiplayer.get_unique_id()):
		player.p_cam.make_current()

	player.rpc("trigger_respawn")


func _handle_player_defeat(player: CharacterBody3D) -> void:
	print("A player has been defeated!")
	if (player.get_multiplayer_authority() == multiplayer.get_unique_id()):
		$RespawnCamera.make_current()
	# TODO: Show in UI
	var timer: SceneTreeTimer = get_tree().create_timer(3)
	timer.connect("timeout", _respawn_player.bind(player))


func join_good_team() -> void:
	var id: int = multiplayer.get_unique_id()
	good_guys.append(id)
	join_team_container.visible = false

	if id == 1:
		add_player_character(1)
	else:
		rpc_id(1, "handle_team_join", id, true)
	connected_peer_ids.append(id)


func join_bad_team() -> void:
	var id: int = multiplayer.get_unique_id()
	bad_guys.append(id)
	join_team_container.visible = false

	if id == 1:
		add_player_character(1)
	else:
		rpc_id(1, "handle_team_join", id, false)
	connected_peer_ids.append(id)


func _on_host_pressed() -> void:
	multiplayer_peer.create_server(1221)
	multiplayer.multiplayer_peer = multiplayer_peer

	join_lobby_cont.visible = false
	status_label.text = "Server"
	id_label.text = str(multiplayer.get_unique_id())

	show_join_team()

	multiplayer.peer_connected.connect(
		# This function runs IN THE HOST when someone joins
		# Send them instructions with the rpc_id() function
		func(id: int) -> void:
			print("Connection...")
			rpc_id(id, "show_join_team")
			rpc_id(id, "add_previous_characters", good_guys, bad_guys)
	)


func _on_join_pressed() -> void:
	multiplayer_peer.create_client(IPADDR, PORT)
	multiplayer.multiplayer_peer = multiplayer_peer

	join_lobby_cont.visible = false
	status_label.text = "Client"
	id_label.text = str(multiplayer.get_unique_id())


func add_player_character(id: int) -> void:
	var p_instance: CharacterBody3D = preload("res://Networking/test_character.tscn").instantiate()
	p_instance.set_multiplayer_authority(id)

	var is_good: bool = good_guys.has(id)
	p_instance.is_good = is_good
	var spawn: Node3D = good_guys_spawn if is_good else bad_guys_spawn
	p_instance.position = spawn.position
	p_instance.position.y = spawn.position.y + 3

	add_child(p_instance)


func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
		toggle_mouse_capture()


func toggle_mouse_capture() -> void:
	if Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	else:
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
