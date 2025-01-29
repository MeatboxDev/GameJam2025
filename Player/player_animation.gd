extends CharacterBody3D

const DEBUG := true

const CAMERA_SENSITIVITY := 0.003

var anim_state_machine: AnimationNodeStateMachinePlayback
var _currently_focused_interactable: Node3D:
	get():
		return _currently_focused_interactable
	set(val):
		if _currently_focused_interactable:
			_currently_focused_interactable.is_focused = false
		if val:
			val.is_focused = true
		_currently_focused_interactable = val

@onready var _anim_tree: AnimationTree = $AnimationTree
@onready var _cam: Camera3D = $CameraStick/Camera


func _ready() -> void:
	if not is_multiplayer_authority():
		return
	anim_state_machine = _anim_tree["parameters/playback"]
	_cam.make_current()
	$Debug.visible = DEBUG
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED


func _process(_delta: float) -> void:
	$Playerid/IdViewport/IdLabel.text = name
	$Debug/Information/CurrentSpeed.text = (
		"SPEED: " + str(velocity) + " | LENGTH: " + str(Vector2(velocity.x, velocity.z).length())
	)

	rpc("_net_update_position", global_position)


func _input(event: InputEvent) -> void:
	if (
		event is InputEventKey
		and event.keycode == KEY_E
		and event.pressed
		and _currently_focused_interactable
	):
		_currently_focused_interactable.interact()
	if event is InputEventMouseMotion:
		$CameraStick.rotation.y -= event.relative.x * CAMERA_SENSITIVITY


@rpc("any_peer", "unreliable", "call_remote")
func _net_update_position(real_position: Vector3) -> void:
	global_position = real_position
