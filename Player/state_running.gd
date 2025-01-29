extends State

const DECELERATION := 0.5

@export var body: CharacterBody3D = null

var _up := false
var _down := false
var _left := false
var _right := false


func on_set() -> void:
	assert(body)


func on_leave() -> void:
	pass


func update() -> void:
	pass


func physics_update() -> void:
	if not is_multiplayer_authority():
		return

	_up = Input.is_key_pressed(KEY_W)
	_down = Input.is_key_pressed(KEY_S)
	_left = Input.is_key_pressed(KEY_A)
	_right = Input.is_key_pressed(KEY_D)
	var movement := Vector2(int(_left) - int(_right), int(_up) - int(_down))

	if movement:
		body.velocity += Vector3(movement.x, body.velocity.y, movement.y)
	else:
		body.velocity = Vector3(
			move_toward(body.velocity.x, 0, DECELERATION),
			body.velocity.y,
			move_toward(body.velocity.z, 0, DECELERATION),
		)
	body.move_and_slide()

	rpc("_net_update_position", body.global_position)
	if body.velocity == Vector3.ZERO:
		transition.emit(self, "idle")


func input(_event: InputEvent) -> void:
	pass


@rpc("any_peer", "unreliable", "call_remote")
func _net_update_position(real_position: Vector3) -> void:
	body.global_position = real_position
