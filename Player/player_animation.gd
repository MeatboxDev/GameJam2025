extends CharacterBody3D

const SPEED = 25.0
const JUMP_VELOCITY = 30

var state_machine: AnimationNodeStateMachinePlayback

@onready var _anim_tree: AnimationTree = $AnimationTree


func _ready() -> void:
	state_machine = _anim_tree["parameters/playback"]


func _physics_process(delta: float) -> void:
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
