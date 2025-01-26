extends Node

const PORT: int = 1221
const IPADDR: String = "localhost"  # "100.93.129.57"

@export var good_guys_spawn_points: Array[Node3D]
@export var bad_guys_spawn_points: Array[Node3D]
@export var good_guys_stands: Array[Node3D]
@export var bad_guys_stands: Array[Node3D]

var multiplayer_peer: ENetMultiplayerPeer = ENetMultiplayerPeer.new()
var instantiated_characters: Array[CharacterBody3D] = []
var connected_peer_ids: Array[int] = []

var good_guys: Array[int] = []
var good_balls: int = 0
var good_ball_list: Array[Node3D] = []

var bad_guys: Array[int] = []
var bad_balls: int = 0
var bad_ball_list: Array[Node3D] = []

var _started: bool = false

@onready var start_game_button: Button = $Control/StartGame
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


func _handle_place_bad_boss() -> void:
	bad_balls += 1


func _handle_burst_good_boss() -> void:
	good_balls -= 1
	if good_balls == 0:
		await get_tree().create_timer(3.0).timeout
		rpc("_end_game")


func _handle_burst_bad_boss() -> void:
	bad_balls -= 1
	if bad_balls == 0:
		await get_tree().create_timer(3.0).timeout
		rpc("_end_game")


@rpc("authority", "call_local", "reliable")
func _end_game() -> void:
	$RespawnCamera.make_current()
	join_team_container.visible = true
	_started = false

	for c in instantiated_characters:
		c.queue_free()
	instantiated_characters.clear()
	good_guys.clear()
	bad_guys.clear()

	for b in good_ball_list:
		b.queue_free()
	good_ball_list.clear()

	for b in bad_ball_list:
		b.queue_free()
	good_ball_list.clear()


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

@rpc("authority", "call_local", "reliable")
func start_game() -> void:
	_started = true
	start_game_button.visible = false
	for st in good_guys_stands:
		var boss: Node3D = preload("res://Testing/goal_bubble_purple.tscn").instantiate()
		boss.set_multiplayer_authority(get_multiplayer_authority())
		add_child(boss)
		boss.position = st.position + Vector3.UP * 5
	for st in bad_guys_stands:
		var boss: Node3D = preload("res://Testing/goal_bubble_pink.tscn").instantiate()
		boss.set_multiplayer_authority(get_multiplayer_authority())
		add_child(boss)
		boss.position = st.position + Vector3.UP * 5
	for c in instantiated_characters:
		_respawn_player(c)

@rpc("any_peer", "call_local", "reliable")
func change_team(id: int) -> void:
	var player: Node3D = instantiated_characters.filter(func(c: Node3D) -> bool: return c.name.to_int() == id).front()
	if player.is_good:
		good_guys.erase(id)
	else:
		bad_guys.erase(id)
	instantiated_characters.erase(player)
	player.queue_free()
	if id == multiplayer.get_unique_id():
		$RespawnCamera.make_current()
		show_join_team()
	if good_guys.size() >= 1 and bad_guys.size() >= 1 and not _started:
		start_game_button.show()
	else:
		start_game_button.hide()
	

@rpc("any_peer", "call_local", "reliable")
func add_new_connections(id: int, is_good: bool) -> void:
	connected_peer_ids.append(id)
	add_player_character(id, is_good)


@rpc("any_peer", "reliable")
func add_previous_characters(good_ids: Array[int], bad_ids: Array[int]) -> void:
	for peer_id in good_ids:
		good_guys.append(peer_id)
		add_player_character(peer_id, true)
	for peer_id in bad_ids:
		bad_guys.append(peer_id)
		add_player_character(peer_id, false)


@rpc("any_peer", "reliable")
func show_join_team() -> void:
	join_team_container.visible = true


@rpc("any_peer", "call_local", "reliable")
func handle_join_team(id: int, is_good: bool) -> void:
	if is_good:
		good_guys.append(id)
	else:
		bad_guys.append(id)

	if good_guys.size() >= 1 and bad_guys.size() >= 1 and not _started:
		start_game_button.show()
	else:
		start_game_button.hide()

	rpc("add_new_connections", id, is_good)


func _handle_start_button() -> void:
	for c: Node in get_children():
		if c.is_in_group("Bubble"):
			c.rpc("burst")
	rpc("start_game")


func _ready() -> void:
	multiplayer.allow_object_decoding = true
	join_good_btn.connect("pressed", join_good_team)
	join_bad_btn.connect("pressed", join_bad_team)
	start_game_button.connect("pressed", _handle_start_button)
	SignalBus.place_good_boss.connect(_handle_place_good_boss)
	SignalBus.place_bad_boss.connect(_handle_place_bad_boss)
	SignalBus.burst_good_boss.connect(_handle_burst_good_boss)
	SignalBus.burst_bad_boss.connect(_handle_burst_bad_boss)
	SignalBus.player_defeat.connect(_handle_player_defeat)
	SignalBus.player_change_team.connect(_handle_player_change_team)


func _respawn_player(player: CharacterBody3D) -> void:
	var spawn_pool: Array[Node3D] = (
		good_guys_spawn_points if player.is_good else bad_guys_spawn_points
	)
	player.position = spawn_pool[0].position
	player.position.y = spawn_pool[0].position.y + 3
	spawn_pool.push_back(spawn_pool.pop_front())

	if player.get_multiplayer_authority() == multiplayer.get_unique_id():
		player.p_cam.make_current()

	player.health = 100
	player.rpc("trigger_respawn")


func _handle_player_defeat(player: CharacterBody3D) -> void:
	print("A player has been defeated!")
	if player.get_multiplayer_authority() == multiplayer.get_unique_id():
		$RespawnCamera.make_current()
	# TODO: Show in UI
	var timer: SceneTreeTimer = get_tree().create_timer(3)
	timer.connect("timeout", _respawn_player.bind(player))

func _handle_player_change_team(id: int) -> void:
	rpc("change_team", id)


func join_good_team() -> void:
	join_team_container.visible = false
	rpc_id(1, "handle_join_team", multiplayer.get_unique_id(), true)


func join_bad_team() -> void:
	join_team_container.visible = false
	rpc_id(1, "handle_join_team", multiplayer.get_unique_id(), false)

@rpc("authority", "reliable")
func sync_bubble(b: Node3D) -> void:
	var new_bubble: Node3D
	if b.is_in_group("BossBubble"):
		new_bubble = preload("res://Testing/goal_bubble_purple.tscn").instantiate() if b.is_good else preload("res://Testing/goal_bubble_pink.tscn").instantiate()
	else:
		new_bubble = preload("res://Testing/bubble_purple.tscn").instantiate() if b.is_good else preload("res://Testing/bubble_pink.tscn").instantiate()

	for g in b.get_groups():
		new_bubble.add_to_group(g)
	add_child(new_bubble)



func _on_host_pressed() -> void:
	multiplayer_peer.create_server(1221)
	multiplayer.multiplayer_peer = multiplayer_peer

	join_lobby_cont.visible = false
	status_label.text = "Server"
	id_label.text = str(multiplayer.get_unique_id())

	show_join_team()

	multiplayer.peer_disconnected.connect(
		func(id: int) -> void:
			print("Disconnection...")
			var players: Array[CharacterBody3D] = instantiated_characters.filter(func(c: Node3D) -> bool: return c.name.to_int() == id)
			if players.size() == 0:
				return
			players.front().queue_free()
	)

	multiplayer.peer_connected.connect(
		# This function runs IN THE HOST when someone joins
		# Send them instructions with the rpc_id() function
		func(id: int) -> void:
			print("Connection...")
			rpc_id(id, "show_join_team")
			rpc_id(id, "add_previous_characters", good_guys, bad_guys)
			for c in get_children():
				if not c.is_in_group("Bubble"): continue
				rpc_id(id, "sync_bubble", c)
				
	)


func _on_join_pressed() -> void:
	multiplayer_peer.create_client(IPADDR, PORT)
	multiplayer.multiplayer_peer = multiplayer_peer

	join_lobby_cont.visible = false
	status_label.text = "Client"
	id_label.text = str(multiplayer.get_unique_id())

	multiplayer.peer_disconnected.connect(
		func(id: int) -> void:
			if id != 1: return
			_end_game()
			for c in get_children():
				if not c.is_in_group("Bubble"): continue
				c.queue_free()
			join_team_container.hide()
			join_lobby_cont.show()
	)


func add_player_character(id: int, is_good: bool) -> void:
	var p_instance: CharacterBody3D = preload("res://Networking/test_character.tscn").instantiate()
	p_instance.set_multiplayer_authority(id)

	p_instance.is_good = is_good
	var spawn: Node3D = (
		good_guys_spawn_points.pick_random() if is_good else bad_guys_spawn_points.pick_random()
	)
	p_instance.position = spawn.position
	p_instance.position.y = spawn.position.y + 3

	add_child(p_instance)

	instantiated_characters.append(p_instance)


func _input(event: InputEvent) -> void:
	if (
		event is InputEventKey
		and event.pressed
		and event.keycode == KEY_P
		and start_game_button.visible
	):
		rpc("start_game")
	if event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
		toggle_mouse_capture()


func toggle_mouse_capture() -> void:
	if Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	else:
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
