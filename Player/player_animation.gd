extends CharacterBody3D

const DEBUG := true

const CAMERA_SENSITIVITY := 0.003

var username: String = "":
	get(): return username
	set(val):
		username = val
		$Playerid/IdViewport/IdLabel.text = name if username == "" else username


var anim_state_machine: AnimationNodeStateMachinePlayback

@onready var _interface_manager: InterfaceManager = get_tree().current_scene.find_child("InterfaceManager")
@onready var _interaction_area: Area3D = $InteractionArea
@onready var state_machine: StateMachine = $StateMachine
@onready var _anim_tree: AnimationTree = $AnimationTree
@onready var _cam: Camera3D = $CameraStick/Camera

func _ready() -> void:
	if not is_multiplayer_authority():
		return
		
	assert(state_machine, "State Machine not set for player")
	assert(_interaction_area, "InteractionArea not set for player")
	assert(_interface_manager, "InterfaceManager not found in scene")
	
	
	anim_state_machine = _anim_tree["parameters/playback"]
	_cam.make_current()
	$Debug.visible = DEBUG
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	
	var config := ConfigFile.new()
	var err := config.load("user://userdata.cfg")
	if err == OK:
		username = config.get_value("Userdata", "username")


func _process(_delta: float) -> void:
	if not is_multiplayer_authority():
		return
	$Debug/Information/CurrentSpeed.text = (
		"SPEED: " + str(velocity.x) + " | LENGTH: " + str(Vector2(velocity.x, velocity.z).length())
	)
	rpc("_net_update_position", global_position)
	username = username


func _input(event: InputEvent) -> void:
	if not is_multiplayer_authority():
		return
	if event is InputEventKey and event.keycode == KEY_E and event.pressed and state_machine.current_state.name != "Interface":
		_interaction_area.interact()
	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		$CameraStick.rotation.y -= event.relative.x * CAMERA_SENSITIVITY


@rpc("any_peer", "unreliable", "call_remote")
func _net_update_position(real_position: Vector3) -> void:
	global_position = real_position

@rpc("any_peer", "reliable",  "call_remote")
func _sync_username(real_username: String) -> void:
	username = real_username
	$Playerid/IdViewport/IdLabel.text = name if username == "" else username
