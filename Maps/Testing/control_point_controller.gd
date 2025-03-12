class_name ControlPointController extends Node

const PLAYER_SCENE := preload("uid://bi0j2wmww54ji")

const CAPTURE_BUBBLE_SCENE := preload("uid://dx1vrwujsdjan")

const WIN_THRESHOLD := 1

const BUBBLE_RESPAWN_TIME := 1.0

@export_category("Game")
@export var _bubble_spawns: Array[Node3D] = []

@export_category("Good Guys")
@export var _good_spawns: Array[Node3D] = []

@export_category("Bad Guys")
@export var _bad_spawns: Array[Node3D] = []

@export_category("Necessary to set")
@export var _interface_manager: InterfaceManager

var _spawn_bubble_timer: SceneTreeTimer = null

var _player_instance_list: Dictionary[int, Player] = {}

var _player_instance: Player = null

var _team_information: Dictionary = {
	"0": {
		"points": 0,
		"player_instances": []
	},
	"1": {
		"points": 0,
		"player_instances": []
	},
}


#--- 8888888888 888b    888  .d8888b.  8888888 888b    888 8888888888 ---#
#--- 888        8888b   888 d88P  Y88b   888   8888b   888 888        ---#
#--- 888        88888b  888 888    888   888   88888b  888 888        ---#
#--- 8888888    888Y88b 888 888          888   888Y88b 888 8888888    ---#
#--- 888        888 Y88b888 888  88888   888   888 Y88b888 888        ---#
#--- 888        888  Y88888 888    888   888   888  Y88888 888        ---#
#--- 888        888   Y8888 Y88b  d88P   888   888   Y8888 888        ---#
#--- 8888888888 888    Y888  "Y8888P88 8888888 888    Y888 8888888888 ---#


func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	
	SignalBus.change_team_good.connect(func(id: int) -> void: rpc_id(1, "_request_join_good", id))
	
	SignalBus.change_team_bad.connect(func(id: int) -> void: rpc_id(1, "_request_join_bad", id))
	
	SignalBus.point_for_team.connect(_team_add_point)
	
	SignalBus.capture_bubble_burst.connect(_on_capture_bubble_burst)
	
	SignalBus.print_player_instances.connect(print.bind(_player_instance_list))
	
	#--- Server Events ---#
	Server.server_player_connected.connect(_sync_players)
	
	Server.server_player_disconnected.connect(_any_eliminate_player)
	
	Server.client_player_disconnected.connect(_any_eliminate_player)
	
	Server.client_connected_to_server.connect(_handle_server_connect)
	
	Server.client_disconnected_from_server.connect(_handle_server_disconnect)


func _input(event: InputEvent) -> void:
	if (
		Server.is_server()
		and event is InputEventKey
		and event.pressed
		and event.keycode == KEY_P
	):
		_start_game()


#--- 8888888b.  8888888b.   .d8888b.  ---#
#--- 888   Y88b 888   Y88b d88P  Y88b ---#
#--- 888    888 888    888 888    888 ---#
#--- 888   d88P 888   d88P 888        ---#
#--- 8888888P"  8888888P"  888        ---#
#--- 888 T88b   888        888    888 ---#
#--- 888  T88b  888        Y88b  d88P ---#
#--- 888   T88b 888         "Y8888P"  ---#


## [b][color=orange]RPC Function[/color][/b][br]
## [b]* Mode[/b]: authority[br]
## [b]* Sync[/b]: call_local[br]
## [b]* Transfer Mode[/b]: reliable[br]
@rpc("authority", "call_local", "reliable")
func _end_game() -> void:
	_clear_teams()


## [b][color=orange]RPC Function[/color][/b][br]
## [b]* Mode[/b]: authority[br]
## [b]* Sync[/b]: call_local[br]
## [b]* Transfer Mode[/b]: reliable[br]
## Spawns a player in the "good team"
@rpc("authority", "reliable", "call_local")
func _spawn_player_good(multiplayer_id: int) -> void:
	var player := _instantiate_player(multiplayer_id)
	_team_append_player_instance(0, player)
	player.team_id = 0
	player.team_color = Color.BLUE
	KLog.debug("Player " + str(player.team_id) + " joined team good with color " + str(player.team_color))


## [b][color=orange]RPC Function[/color][/b][br]
## [b]* Mode[/b]: authority[br]
## [b]* Sync[/b]: call_local[br]
## [b]* Transfer Mode[/b]: reliable[br]
## Spawns a player in the "bad team"
@rpc("authority", "reliable", "call_local")
func _spawn_player_bad(multiplayer_id: int) -> void:
	var player := _instantiate_player(multiplayer_id)
	_team_append_player_instance(1, player)
	player.team_id = 1
	player.team_color = Color.RED
	KLog.debug("Player " + str(player.team_id) + " joined team bad with color " + str(player.team_color))


## [b][color=orange]RPC Function[/color][/b][br]
## [b]* Mode[/b]: authority[br]
## [b]* Sync[/b]: call_local[br]
## [b]* Transfer Mode[/b]: reliable[br]
## Instantiates a [CaptureBubble] in the [param position] given by the Server
@rpc("authority", "reliable", "call_local")
func _spawn_capture_bubble(position: Vector3) -> void:
	var instance := CAPTURE_BUBBLE_SCENE.instantiate()
	add_child(instance)
	instance.global_position = position


#---  .d8888b.  888      8888888 8888888888 888b    888 88888888888 ---#
#--- d88P  Y88b 888        888   888        8888b   888     888     ---#
#--- 888    888 888        888   888        88888b  888     888     ---#
#--- 888        888        888   8888888    888Y88b 888     888     ---#
#--- 888        888        888   888        888 Y88b888     888     ---#
#--- 888    888 888        888   888        888  Y88888     888     ---#
#--- Y88b  d88P 888        888   888        888   Y8888     888     ---#
#---  "Y8888P"  88888888 8888888 8888888888 888    Y888     888     ---#

## [b][color=lime]Client Function[/color][/b]
func _handle_server_connect() -> void:
	_clear_teams()


## [b][color=lime]Client Function[/color][/b]
## Removes all players from the teams
## [b][color=red]WARNING:[/color][/b] If function is called only client-side
## it may result in a desync error
func _clear_teams() -> void:
	for t: String in _team_information:
		_team_information[t]["points"] = 0
		for p: Player in _team_information[t]["player_instances"]:
			p.queue_free()
		_team_information[t]["player_instances"].clear()
	_interface_manager.open("PickTeamInterface") # TODO: This shouldn't happen here


## [b][color=lime]Client Function[/color][/b]
## Callback function for when disconnects from server
## Cleans players
func _handle_server_disconnect() -> void:
	_clear_teams()


## [b][color=lime]Client Function[/color][/b]
## Spawns a player client sides
## setting its multiplayer authority and name to [param multiplayer_id],
## adding it to [ControlPointController._player_instance_list]
## and setting [ControlPointController._player_instance] to it
## if the player spawning is the client's
func _instantiate_player(multiplayer_id: int) -> Player:
	var player_instance := PLAYER_SCENE.instantiate()
	player_instance.set_multiplayer_authority(multiplayer_id)
	player_instance.name = str(multiplayer_id)
	_player_instance_list[multiplayer_id] = player_instance
	add_child(player_instance)
	if multiplayer_id == multiplayer.get_unique_id():
		_player_instance = player_instance
	return player_instance


## [b][color=lime]Client Function[/color][/b]
## Eliminates a player from the world by their multiplayer id
## and removes them from every listing that has them
func _any_eliminate_player(id: int) -> void:
	assert(_player_instance_list.has(id), "_player_instance_list doesn't have id of player disconnecting")
	var p: Player = _player_instance_list[id]
	_team_information[str(p.team_id)]["player_instances"].erase(p)
	_player_instance_list.erase(id)
	p.queue_free()


## [b][color=lime]Client Function[/color][/b]
## Appends a player instance to the list of players of a team
func _team_append_player_instance(team: int, inst: Player) -> void:
	_get_team_player_instances(team).append(inst)


## [b][color=lime]Client Function[/color][/b]
## Gets the list of player instances of a team
func _get_team_player_instances(team: int) -> Array:
	return _team_information[str(team)]["player_instances"]


#---  .d8888b.  8888888888 8888888b.  888     888 8888888888 8888888b.  ---#
#--- d88P  Y88b 888        888   Y88b 888     888 888        888   Y88b ---#
#--- Y88b.      888        888    888 888     888 888        888    888 ---#
#---  "Y888ba   8888888    888   d88P Y88b   d88P 8888888    888   d88P ---#
#---     "Y88b. 888        8888888P"   Y88b d88P  888        8888888P"  ---#
#---       "888 888        888 T88b     Y88o88P   888        888 T88b   ---#
#--- Y88b  d88P 888        888  T88b     Y888P    888        888  T88b  ---#
#---  "Y8888P"  8888888888 888   T88b     Y8P     8888888888 888   T88b ---#


## [b][color=red]Server Function[/color][/b]
## Adds a point to the respective team
## If team surpasses the [ControlPointController.WIN_THRESHOLD]
## run [ControlPointController._trigger_win]
func _team_add_point(team: int) -> void:
	assert(Server.is_server(), "_team_add_point running on client not allowed")
	_team_information[str(team)]["points"] += 1
	if _team_information[str(team)]["points"] >= WIN_THRESHOLD:
		_trigger_win(team)


## [b][color=red]Server Function[/color][/b]
## Resets [ControlPointController._spawn_bubble_timer]
## Runs [ControlPointController._end_game] client-side
func _trigger_win(team: int) -> void:
	assert(Server.is_server(), "_team_add_point running on client not allowed")
	KLog.info("Team: " + str(team) + " wins!")
	if _spawn_bubble_timer:
		_spawn_bubble_timer.timeout.disconnect(_spawn_bubble_timer_timeout)
		_spawn_bubble_timer.time_left = 0
	rpc("_end_game")


## [b][color=red]Server Function[/color][/b]
## Syncs the game's player's for the player with [param id]
func _sync_players(id: int) -> void:
	assert(Server.is_server(), "_server_sync_players running on client not allowed")
	for p_id: int in _player_instance_list:
		var p: Player = _player_instance_list.get(p_id)
		match (p.team_id):
			0: rpc_id(id, "_spawn_player_good", p_id)
			1: rpc_id(id, "_spawn_player_bad", p_id)
			_: assert(false, "Team with id of " + str(id) + " not found")


## [b][color=red]Server Function[/color][/b]
## Creates [ControlPointController._spawn_bubble_timer] and
## connects it to [ControlPointController._spawn_bubble_timer_timeout]
func _on_capture_bubble_burst() -> void:
	assert(Server.is_server(), "_on_capture_bubble_burst running on client not allowed")
	_spawn_bubble_timer = get_tree().create_timer(BUBBLE_RESPAWN_TIME)
	_spawn_bubble_timer.timeout.connect(_spawn_bubble_timer_timeout)


## [b][color=red]Server Function[/color][/b]
## Chooses a location from the [ControlPointController._bubble_spawns] locations and
## notifies clients that they should spawn a [Bubble] in the location chosen
func _spawn_bubble_timer_timeout() -> void:
	var pos: Vector3 = _bubble_spawns.pick_random().global_position
	rpc("_spawn_capture_bubble", pos)


## [b][color=red]Server Function[/color][/b]
## Moves player to their spawn positions
## and spawns the big bad bubble
func _start_game() -> void:
	for p: Player in _get_team_player_instances(0):
		p.rpc("net_move", _good_spawns.pick_random().global_position)
	for p: Player in _get_team_player_instances(1):
		p.rpc("net_move", _bad_spawns.pick_random().global_position)
	
	# Spawn a target bubble in the map
	var pos: Vector3 = _bubble_spawns.pick_random().global_position
	rpc("_spawn_capture_bubble", pos)


## [b][color=red]Server RPC Function[/color][/b]
## [b]* Mode[/b]: any_peer[br]
## [b]* Sync[/b]: call_local[br]
## [b]* Transfer Mode[/b]: reliable[br]
## Called when a client requests the server to join the "good team"
@rpc("any_peer", "call_local", "reliable")
func _request_join_good(who: int) -> void:
	assert(Server.is_server(), "_server_sync_players running on client not allowed")
	# TODO: Here you would do the checks if he could actually spawn
	# If yes spawn, send this shit to everyone
	rpc("_spawn_player_good", who)


## [b][color=red]Server RPC Function[/color][/b]
## [b]* Mode[/b]: any_peer[br]
## [b]* Sync[/b]: call_local[br]
## [b]* Transfer Mode[/b]: reliable[br]
## Called when a client requests the server to join the "bad team"
@rpc("any_peer", "reliable", "call_local")
func _request_join_bad(who: int) -> void:
	assert(Server.is_server(), "_server_sync_players running on client not allowed")
	# TODO: Here you would do the checks if he could actually spawn
	# If yes spawn, send this shit to everyone
	rpc("_spawn_player_bad", who)
