extends CharacterBody3D

signal username_change(new_username: String)

const DEBUG := true
const CAM_MAX_UP := 1.3
const CAM_MAX_DOWN := -1.3

const CAMERA_SENSITIVITY := 0.003

var username: String = "":
	get(): return username
	set(val):
		username = val
		username_change.emit(username)


var anim_state_machine: AnimationNodeStateMachinePlayback

@onready var state_machine: StateMachine = $StateMachine
@onready var _interaction_area: Area3D = $InteractionArea
@onready var _cam: Camera3D = $CameraStick/Camera

func _on_username_change(new_name: String) -> void:
	username = new_name

func _ready() -> void:
	if not is_multiplayer_authority():
		return
	
	SignalBus.username_change.connect(_on_username_change)
	username = Userdata.config.get_value("Userdata", "username")
	
	assert(state_machine, "State Machine not set for player")
	assert(_interaction_area, "InteractionArea not set for player")
	
	_cam.make_current()
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED


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
		$CameraStick.rotation.x -= event.relative.y * CAMERA_SENSITIVITY
		$CameraStick.rotation.x = clamp($CameraStick.rotation.x, CAM_MAX_DOWN, CAM_MAX_UP)


@rpc("any_peer", "unreliable", "call_remote")
func _net_update_position(real_position: Vector3) -> void:
	global_position = real_position


@rpc("any_peer", "reliable",  "call_remote")
func _sync_username(real_username: String) -> void:
	username = real_username
