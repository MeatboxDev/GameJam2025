extends CharacterBody3D

@onready var head: Node = $Head
@onready var p_cam: Camera3D = $Head/PlayerCamera

func _ready() -> void:
	name = str(get_multiplayer_authority())
	p_cam.current = is_multiplayer_authority()
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

const DEG_45: float = PI/4.0
const DEG_N45: float = -DEG_45

const SPEED: float = 1.0
const DECEL_SPEED: float = 2.0
const MAX_SPEED: float = 10.0

var _up: bool = Input.is_key_pressed(KEY_UP) or Input.is_key_pressed(KEY_W)
var _down: bool = Input.is_key_pressed(KEY_DOWN) or Input.is_key_pressed(KEY_S)
var _right: bool = Input.is_key_pressed(KEY_RIGHT) or Input.is_key_pressed(KEY_D)
var _left: bool = Input.is_key_pressed(KEY_LEFT) or Input.is_key_pressed(KEY_A)
var _movement: Vector3 = Vector3.ZERO

func xyz_to_xz(vec: Vector3) -> Vector2:
	return Vector2(vec.x, vec.z)
func normalize_xz(vec: Vector3, magnitude: float = 1.0) -> Vector3:
	return Vector3(vec.normalized().x * magnitude, vec.y, vec.normalized().z * magnitude)
func move_toward_xz(vec: Vector3, to: Vector3, speed: float) -> Vector3:
	return vec.move_toward(Vector3(to.x, vec.y, to.z), speed)

func calculate_horizontal_movement() -> void:
	_movement = Vector3.ZERO

	if _up and not _down: _movement += Vector3.FORWARD * SPEED
	if _down and not _up: _movement += Vector3.BACK * SPEED
	if _right and not _left: _movement += Vector3.RIGHT * SPEED
	if _left and not _right: _movement += Vector3.LEFT * SPEED
	velocity += _movement.rotated(Vector3.UP, head.rotation.y)

	if xyz_to_xz(self.velocity).length() > MAX_SPEED:
		velocity = normalize_xz(velocity, MAX_SPEED)
	if (not (_up or _down or _left or _right)) or ((_up and _down) or (_right and _left)):
		velocity = move_toward_xz(velocity, Vector3.ZERO, DECEL_SPEED)

func _process(_delta: float) -> void:
	if not is_multiplayer_authority():
		process_mode = ProcessMode.PROCESS_MODE_DISABLED

	if (is_on_floor()): velocity.y = 0
	else: velocity.y -= 1

	calculate_horizontal_movement()
	move_and_slide()
	rpc("remote_set_position", global_position)

@rpc("unreliable")
func remote_set_position(real_pos):
	global_position = real_pos

var mouse_sens = 0.3
var camera_anglev=0

const SENSITIVITY = 0.01

func _process_keyboard(ev: InputEventKey) -> void:
	if ev.keycode == KEY_ESCAPE and ev.pressed:
		if (Input.mouse_mode == Input.MOUSE_MODE_CAPTURED):
			Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		else: Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

	match (ev.keycode):
		KEY_W, KEY_UP: _up = ev.pressed
		KEY_A, KEY_LEFT: _left = ev.pressed
		KEY_S, KEY_DOWN: _down = ev.pressed
		KEY_D, KEY_RIGHT: _right = ev.pressed


func _input(event):
	if event is InputEventKey:
		_process_keyboard(event); return
	if event is InputEventMouseMotion:
		head.rotate_y(-event.relative.x * SENSITIVITY)
		p_cam.rotate_x(-event.relative.y * SENSITIVITY)

