extends CharacterBody3D

const DEG_45: float = PI/4.0
const DEG_N45: float = -DEG_45

@onready var body: Node = $Body
@onready var head: Node = $Head
@onready var head_mesh: Node = $Head/HeadMesh
@onready var spring_arm: SpringArm3D = $Head/SpringArm3D
@onready var p_cam: Camera3D = $Head/SpringArm3D/PlayerCamera

@export var SPEED: float = 1.5
@export var DECEL_SPEED: float = 3.0
@export var MAX_SPEED: float = 20.0

@export var JUMP_FORCE: float = 50.0

@export var SENSITIVITY = 0.01

## Lower is stronger
@export var BODY_ROTATION_STRENGTH = 10.0

func _ready() -> void:
	name = str(get_multiplayer_authority())
	p_cam.current = is_multiplayer_authority()
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

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

	if _movement.z < 0:
		body.rotate_y(angle_difference(body.rotation.y, head.rotation.y)/10.0)
	if _movement.x:
		body.rotate_y(angle_difference(body.rotation.y + sign(_movement.x) * DEG_45, head.rotation.y)/10.0)

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

	if (is_on_floor() and Input.is_key_pressed(KEY_SPACE)):
		velocity.y += JUMP_FORCE

	calculate_horizontal_movement()
	move_and_slide()
	rpc("remote_set_position", global_position)

@rpc("unreliable")
func remote_set_position(real_pos):
	global_position = real_pos

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
		spring_arm.rotate_x(-event.relative.y * SENSITIVITY)
		spring_arm.rotation.x = clamp(spring_arm.rotation.x, -.8, .8)

		head_mesh.rotation.x = spring_arm.rotation.x

		var head_body_diff = angle_difference(head.rotation.y, body.rotation.y)
		if (abs(head_body_diff) > .7):
			body.rotate_y(sign(head_body_diff) * (-abs(head_body_diff) + .7))
			
