extends Node

const PLAYER_SCENE := preload("uid://bi0j2wmww54ji")
const CAPTURE_BUBBLE_SCENE := preload("uid://dx1vrwujsdjan")

const BUBBLE_RESPAWN_TIME := 1.0

@export_category("Game")
@export var bubble_spawns: Array[Node3D] = []

@export_category("Good Guys")
@export var good_spawns: Array[Node3D] = []

@export_category("Bad Guys")
@export var bad_spawns: Array[Node3D] = []

var _spawn_bubble_timer: SceneTreeTimer = null
var _player_instance_list: Dictionary = {}
var _player_instance: Player = null
var _active_capture_bubble: Node3D

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

func _team_add_point(team: int) -> void:
	_team_information[str(team)]["points"] += 1
	
	if not is_multiplayer_authority():
		return
	
	if _team_information[str(team)]["points"] == 3:
		KLog.info("Team: " + str(team) + " wins!")
		_spawn_bubble_timer.timeout.disconnect(_spawn_bubble_timer_timeout)
		_spawn_bubble_timer.time_left = 0


func _team_append_player_instance(team: int, inst: Player) -> void:
	_get_team_player_instances(team).append(inst)

func _get_team_player_instances(team: int) -> Array:
	return _team_information[str(team)]["player_instances"]

func _instantiate_player(multiplayer_id: int) -> Player:
	var player_instance := PLAYER_SCENE.instantiate()
	player_instance.set_multiplayer_authority(multiplayer_id)
	player_instance.name = str(multiplayer_id)
	_player_instance_list[multiplayer_id] = player_instance
	add_child(player_instance)
	if multiplayer_id == multiplayer.get_unique_id():
		_player_instance = player_instance
	return player_instance


@rpc("any_peer", "reliable", "call_local")
func net_start_game() -> void:
	pass


@rpc("any_peer", "reliable", "call_local")
func net_spawn_bubble(new_position: Vector3) -> void:
	var instance := CAPTURE_BUBBLE_SCENE.instantiate()
	add_child(instance)
	instance.global_position = new_position


func _start_game() -> void:
	for p: Player in _get_team_player_instances(0):
		KLog.debug("Spawning " + str(p) + " good")
		p.rpc("net_move", good_spawns.pick_random().global_position)
	for p: Player in _get_team_player_instances(1):
		KLog.debug("Spawning " + str(p) + " bad")
		p.rpc("net_move", bad_spawns.pick_random().global_position)
	
	# Spawn a target bubble in the map
	rpc("net_spawn_bubble", bubble_spawns.pick_random().global_position)
	
	net_start_game() # Notify clients that game started


@rpc("authority", "reliable", "call_local")
func _spawn_player_good(multiplayer_id: int) -> void:
	var player := _instantiate_player(multiplayer_id)
	_team_append_player_instance(0, player)
	player.set_team_id(0)
	player.set_team_color(Color.BLUE)
	KLog.debug("Player " + str(player.get_team_id()) + " joined team good with color " + str(player.get_team_color()))


@rpc("authority", "reliable", "call_local")
func _spawn_player_bad(multiplayer_id: int) -> void:
	var player := _instantiate_player(multiplayer_id)
	_team_append_player_instance(1, player)
	player.set_team_id(1)
	player.set_team_color(Color.RED)
	KLog.debug("Player " + str(player.get_team_id()) + " joined team bad with color " + str(player.get_team_color()))


@rpc("any_peer", "reliable", "call_local")
func _request_join_good(who: int) -> void:
	# TODO: Here you would do the checks if he could actually spawn
	# If yes spawn, send this shit to everyone
	rpc("_spawn_player_good", who)


@rpc("any_peer", "reliable", "call_local")
func _request_join_bad(who: int) -> void:
	# TODO: Here you would do the checks if he could actually spawn
	# If yes spawn, send this shit to everyone
	rpc("_spawn_player_bad", who)


func _spawn_bubble_timer_timeout() -> void:
	rpc("net_spawn_bubble", bubble_spawns.pick_random().global_position)


func _on_capture_bubble_burst() -> void:
	if not is_multiplayer_authority():
		return
	
	_spawn_bubble_timer = get_tree().create_timer(BUBBLE_RESPAWN_TIME)
	_spawn_bubble_timer.timeout.connect(_spawn_bubble_timer_timeout)


func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	SignalBus.change_team_good.connect(func(id: int) -> void: rpc_id(1, "_request_join_good", id))
	SignalBus.change_team_bad.connect(func(id: int) -> void: rpc_id(1, "_request_join_bad", id))
	SignalBus.point_for_team.connect(_team_add_point)
	SignalBus.capture_bubble_burst.connect(_on_capture_bubble_burst)

func _input(event: InputEvent) -> void:
	if is_multiplayer_authority() and event is InputEventKey and event.pressed and event.keycode == KEY_P:
		_start_game()
