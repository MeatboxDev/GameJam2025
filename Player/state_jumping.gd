extends State

const ACCELERATION := 3.0
const DECELERATION := 4.0
const GRAVITY := 3.0
const JUMP_DURATION := 0.2
const JUMP_FORCE := 40.0
const MAX_SPEED := 30.0

@export var body: CharacterBody3D
@export var cam_stick: SpringArm3D

var _getting_elevation := true
var _up := false
var _down := false
var _left := false
var _right := false


func on_set() -> void:
	assert(body)
	assert(cam_stick)
	_getting_elevation = true
	get_tree().create_timer(JUMP_DURATION).timeout.connect(
		func() -> void: _getting_elevation = false
	)

	body.velocity.y = JUMP_FORCE


func on_leave() -> void:
	pass


func update() -> void:
	pass


func physics_update() -> void:
	if body.is_on_floor():
		if (
			Input.is_key_pressed(KEY_W)
			or Input.is_key_pressed(KEY_A)
			or Input.is_key_pressed(KEY_S)
			or Input.is_key_pressed(KEY_D)
		):
			transition.emit(self, "running")
		else:
			transition.emit(self, "idle")

	_up = Input.is_key_pressed(KEY_W)
	_down = Input.is_key_pressed(KEY_S)
	_left = Input.is_key_pressed(KEY_A)
	_right = Input.is_key_pressed(KEY_D)
	var movement := Vector2(int(_right) - int(_left), int(_down) - int(_up))
	movement = movement.rotated(-cam_stick.rotation.y)

	body.velocity.x += movement.x * 3
	body.velocity.z += movement.y * 3
	var xz_velocity := Vector2(body.velocity.x, body.velocity.z)
	if xz_velocity.length() > MAX_SPEED:
		body.velocity = Vector3(
			xz_velocity.normalized().x * MAX_SPEED,
			body.velocity.y,
			xz_velocity.normalized().y * MAX_SPEED
		)

	if _getting_elevation:
		body.velocity.y -= GRAVITY / 5
	else:
		body.velocity.y -= GRAVITY

	body.move_and_slide()
	if body.velocity.x and body.velocity.z:
		body.find_child("gj-player").look_at(body.position + Vector3(body.velocity.x, 0, body.velocity.z), Vector3.UP, true)


func input(_event: InputEvent) -> void:
	if _event is InputEventKey and _event.keycode == KEY_SPACE and _event.is_released():
		_getting_elevation = false
