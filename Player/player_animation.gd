extends CharacterBody3D

signal username_change(new_username: String)

const DEBUG := true

const CAMERA_SENSITIVITY := 0.003

var username: String = "":
	get(): return username
	set(val):
		username = val
		username_change.emit(username)


var anim_state_machine: AnimationNodeStateMachinePlayback

@onready var state_machine: StateMachine = $StateMachine
@onready var _interaction_area: Area3D = $InteractionArea
@onready var _anim_tree: AnimationTree = $Model/AnimationTree
@onready var _cam: Camera3D = $CameraStick/Camera

func _on_username_change(new_name: String) -> void:
	username = new_name


func _ready() -> void:
	if not is_multiplayer_authority():
		return
	
	SignalBus.username_change.connect(_on_username_change)
	
	assert(state_machine, "State Machine not set for player")
	assert(_interaction_area, "InteractionArea not set for player")
	
	
	anim_state_machine = _anim_tree["parameters/playback"]
	_cam.make_current()
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	
	if multiplayer.multiplayer_peer is OfflineMultiplayerPeer:
		load_username()


func _process(_delta: float) -> void:
	if not is_multiplayer_authority():
		return
	rpc("_net_update_position", global_position)


func _input(event: InputEvent) -> void:
	if not is_multiplayer_authority():
		return
	if event is InputEventKey and event.keycode == KEY_E and event.pressed and state_machine.current_state.name != "Interface":
		_interaction_area.interact()
	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		$CameraStick.rotation.y -= event.relative.x * CAMERA_SENSITIVITY


func load_username() -> void:
	var config := ConfigFile.new()
	var err := config.load("user://userdata.cfg")
	if err == OK:
		username = config.get_value("Userdata", "username")
		rpc("_sync_username", username)


@rpc("any_peer", "unreliable", "call_remote")
func _net_update_position(real_position: Vector3) -> void:
	global_position = real_position

@rpc("any_peer", "reliable",  "call_remote")
func _sync_username(real_username: String) -> void:
	username = real_username
