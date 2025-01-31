extends State

const ACCELERATION := 3.0
const DECELERATION := 4.0
const MAX_SPEED := 30.0

@export var body: CharacterBody3D
@export var cam_stick: SpringArm3D

var _up := false
var _down := false
var _left := false
var _right := false


func on_set() -> void:
	assert(body)
	assert(cam_stick)


func on_leave() -> void:
	pass


func update() -> void:
	pass


func physics_update() -> void:
	if not is_multiplayer_authority():
		return

	if Input.is_key_pressed(KEY_SPACE):
		transition.emit(self, "jumping")

	_up = Input.is_key_pressed(KEY_W)
	_down = Input.is_key_pressed(KEY_S)
	_left = Input.is_key_pressed(KEY_A)
	_right = Input.is_key_pressed(KEY_D)
	var movement := Vector2(int(_right) - int(_left), int(_down) - int(_up))
	movement = movement.rotated(-cam_stick.rotation.y)

	if movement:
		body.velocity += Vector3(
			(
				movement.x * ACCELERATION
			),
			0,
			(
				movement.y * ACCELERATION
			),
		)

		var xz_velocity := Vector2(body.velocity.x, body.velocity.z)
		if xz_velocity.length() > MAX_SPEED:
			body.velocity = Vector3(
				xz_velocity.normalized().x * MAX_SPEED,
				body.velocity.y,
				xz_velocity.normalized().y * MAX_SPEED
			)

	else:
		transition.emit(self, "idle")
	body.move_and_slide()
	if round(body.velocity.x) or round(body.velocity.z):
		body.find_child("gj-player").look_at(body.position + Vector3(body.velocity.x, 0, body.velocity.z), Vector3.UP, true)

func input(_event: InputEvent) -> void:
	pass
