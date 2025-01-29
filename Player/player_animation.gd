extends CharacterBody3D

const SPEED = 25.0
const JUMP_VELOCITY = 30

var state_machine: AnimationNodeStateMachinePlayback
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
@onready var _interaction_area: Area3D = $InteractionArea
@onready var _cam: Camera3D = $Camera

func _handle_area_entered(area: Node3D) -> void:
	if area.is_in_group("Interactable"):
		_currently_focused_interactable = area.get_parent()


func _handle_area_exited(area: Node3D) -> void:
	if area.is_in_group("Interactable"):
		_currently_focused_interactable = null


func _ready() -> void:
	if not is_multiplayer_authority():
		return
	state_machine = _anim_tree["parameters/playback"]
	_interaction_area.area_entered.connect(_handle_area_entered)
	_interaction_area.area_exited.connect(_handle_area_exited)
	_cam.make_current()


func _process(delta: float) -> void:
	$Playerid/IdViewport/IdLabel.text = name


func _physics_process(_delta: float) -> void:
	if not is_multiplayer_authority():
		return
	# Add the gravity.
	if not is_on_floor():
		velocity += Vector3.DOWN * 1

	# Handle jump.
	if Input.is_key_pressed(KEY_SPACE) and is_on_floor():
		state_machine.travel("falling-loop")
		velocity.y = JUMP_VELOCITY

	# Get the input direction and handle the movement/deceleration.
	# As good practice, you should replace UI actions with custom gameplay actions.
	var input_dir := Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	var direction := (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	if direction:
		velocity.x = direction.x * SPEED
		velocity.z = direction.z * SPEED
		if state_machine.get_current_node() != "run-loop-animation" and is_on_floor():
			state_machine.travel("run-loop-animation")
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)
		velocity.z = move_toward(velocity.z, 0, SPEED)
		if state_machine.get_current_node() != "idle" and is_on_floor():
			state_machine.travel("idle")

	move_and_slide()
	rpc("_net_update_transform", transform)

@rpc("unreliable", "any_peer", "call_remote")
func _net_update_transform(real_transform: Transform3D) -> void:
	transform = real_transform

func _input(event: InputEvent) -> void:
	if event is InputEventKey:
		if event.keycode == KEY_E and event.pressed and _currently_focused_interactable:
			_currently_focused_interactable.interact()
