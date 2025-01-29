extends CharacterBody3D

const SPEED = 25.0
const JUMP_VELOCITY = 30

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

@onready var _state_machine: StateMachine = $StateMachine
@onready var _anim_tree: AnimationTree = $AnimationTree
@onready var _cam: Camera3D = $Camera


func _ready() -> void:
	if not is_multiplayer_authority():
		return
	anim_state_machine = _anim_tree["parameters/playback"]
	_cam.make_current()


func _process(_delta: float) -> void:
	$Playerid/IdViewport/IdLabel.text = name


func _input(event: InputEvent) -> void:
	if (
		event is InputEventKey
		and event.keycode == KEY_E
		and event.pressed
		and _currently_focused_interactable
	):
		_currently_focused_interactable.interact()
