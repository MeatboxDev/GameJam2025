class_name Player extends CharacterBody3D

signal username_change(new_username: String)

const CAM_MAX_UP := 1.3

const CAM_MAX_DOWN := -1.3

const CAMERA_SENSITIVITY := 0.003

@export var bubble_speed := 0.5

@export var bubble_decceleration := 0.005

@export var acceleration := 3.0

@export var deceleration := 4.0

@export var gravity := 3.0

@export var jump_duration := 0.2

@export var jump_force := 40.0

@export var max_speed := 30.0

@export var pushback_time := 0.35

var username: String = "":
	get():
		return username
	set(val):
		username = val
		username_change.emit(username)

var team_id: int:
	get():
		return _team_info["id"]
	set(val):
		_team_info["id"] = val

var team_color: Color:
	get():
		return _team_info["color"]
	set(val):
		_team_info["color"] = val

var anim_state_machine: AnimationNodeStateMachinePlayback

var _team_info := {"id": -1, "color": null}

@onready var _state_machine: StateMachine = $StateMachine

@onready var _interaction_area: Area3D = $InteractionArea

@onready var _cam: Camera3D = $CameraStick/Camera

func _on_username_change(new_name: String) -> void:
	username = new_name


func _ready() -> void:
	safe_margin = 0.1
	if not is_multiplayer_authority():
		return

	SignalBus.username_change.connect(_on_username_change)
	username = Userdata.config.get_value("Userdata", "username")

	assert(_state_machine, "State Machine not set for player")
	assert(_interaction_area, "InteractionArea not set for player")

	_cam.make_current()
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	SignalBus.respawn_player.emit(self)


func _process(_delta: float) -> void:
	if not is_multiplayer_authority(): return
	
	rpc("net_move", position)
	if position.y < -1:
		SignalBus.respawn_player.emit(self)


func _input(event: InputEvent) -> void:
	if not is_multiplayer_authority():
		return
	if (
		event is InputEventKey
		and event.keycode == KEY_E
		and event.pressed
		and _state_machine.current_state.name != "Interface"
	):
		_interaction_area.interact()
	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		$CameraStick.rotation.y -= event.relative.x * CAMERA_SENSITIVITY
		$CameraStick.rotation.x -= event.relative.y * CAMERA_SENSITIVITY
		$CameraStick.rotation.x = clamp($CameraStick.rotation.x, CAM_MAX_DOWN, CAM_MAX_UP)


func handle_collisions() -> void:
	var col := get_last_slide_collision()
	if not col:
		return
	for i: int in col.get_collision_count():
		var collider := col.get_collider(i)
		if collider.is_in_group("Bubble"):
			_handle_bubble_collision(collider, col.get_normal(i))


func _handle_bubble_collision(collider: Node3D, normal: Vector3) -> void:
	var state: State = _state_machine.current_state
	if normal.y > 0.5:
		state.transition.emit(state, "Jumping")
		collider.rpc("burst")
	else:
		var collider_xz := Vector2(collider.global_position.x, collider.global_position.z)
		var body_xz := Vector2(global_position.x, global_position.z)
		var dir := collider_xz - collider_xz.move_toward(body_xz, 1.0)
		velocity = -Vector3(dir.x * 30.0, velocity.y, dir.y * 30.0)
		state.transition.emit(state, "pushback")
		collider.rpc("burst")


@rpc("any_peer", "reliable", "call_local")
func net_move(new_position: Vector3) -> void:
	position = new_position


@rpc("any_peer", "reliable", "call_remote")
func _sync_username(real_username: String) -> void:
	username = real_username
